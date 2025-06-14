# Autoloaded
extends Node

@export var paused: bool = false;
@export var simulation_rate: float = 1.0; ## The speed of the simulation

var shift_start_time: int; ## The shift start time epoch (seconds)
var elapsed_time: float = 0.0;

var ARTCCs := {}; # An dict containing nav/[ARTCC].json files
var ARTCCData := []; # The game/ARTCCs.json helper file
var aircraft_commands := [];
var scope_commands := [];

var artcc: Dictionary;
var tracon: Dictionary;
var position: Dictionary;
var area: Dictionary;

var center_coordinates: Dictionary;

func _init() -> void:
  # Load Commands
  var commands = ResourceManager.load_json("res://data/game/commands.json") as Dictionary;
  if commands == null:
    push_error("Failed to load commands");
    return ;

  if commands.has("aircraft"):
    aircraft_commands = commands["aircraft"];

  if commands.has("scope"):
    scope_commands = commands["scope"];

  # Load ARTCCs
  var artccs = ResourceManager.load_json("res://data/game/ARTCCs.json") as Array;
  if artccs == null:
    push_error("Failed to load ARTCCs");
    return;

  if artccs.size() == 0:
    push_warning("No ARTCCs present in file");

  # Read ARTCCs folder
  var dir = DirAccess.open("res://data/nav/ARTCCs");
  if dir:
    dir.list_dir_begin();
    var file_name = dir.get_next();
    
    while file_name != "":
      if not dir.current_is_dir() and file_name.ends_with(".json"):
        var artcc_data = ResourceManager.load_json("res://data/nav/ARTCCs/" + file_name);
        if !artcc_data: continue;

        ARTCCs[artcc_data["id"]] = artcc_data;
      file_name = dir.get_next();

    dir.list_dir_end();
  else:
    push_error("Failed to open ARTCCs directory");

  ARTCCData = artccs;

func load_scenario(scenario: Dictionary) -> void:
  if !scenario.has("system_time") or !scenario.has("artcc") or !scenario.has("tracon") or !scenario.has("position"):
    push_error("Could not load scenario");
    return;

  shift_start_time = scenario["system_time"];

  artcc = Simulation.ARTCCs[scenario["artcc"]];
  tracon = artcc["facility"]["childFacilities"][scenario["tracon"]];
  position = tracon["positions"][scenario["position"]];

  var area_index = tracon["starsConfiguration"]["areas"].find_custom(func (ar): return ar["id"] == position["starsConfiguration"]["areaId"]);
  area = tracon["starsConfiguration"]["areas"][area_index];
  center_coordinates = area["visibilityCenter"];

  get_tree().change_scene_to_file("res://scenes/radar/tcw.tscn");

func _process(delta: float) -> void:
  if not paused:
    elapsed_time += delta * simulation_rate;

## Pause or resume the simulation
func set_running_state(running: bool) -> void:
  paused = !running;

func set_simulation_speed(speed: float) -> float:
  simulation_rate = clampf(speed, 0.2, 5.0);
  return simulation_rate;

func get_system_time() -> int:
  return shift_start_time + int(elapsed_time);

#region Commands
func find_command(arg: String, type: String) -> Variant:
  var cmds = null;

  if type == "scope":
    cmds = scope_commands;
  elif type == "aircraft":
    cmds = aircraft_commands;
  else:
    return null;

  for cmd in cmds:
    if matches_command(cmd, arg):
      return cmd;

  return null;

func matches_command(command: Dictionary, arg: String) -> bool:
  if command.has("command"):
    if command["command"] == arg:
      return true;

  if command.has("aliases"):
    for alias in command["aliases"]:
      if alias == arg:
        return true;

  return false;

func validate_params(command: Dictionary, args: Array) -> Variant:
  if !command.has("params") && !command.has("subcommands"): return;
  var params = command["params"] if command.has("params") else null;
  var subcommands = command["subcommands"] if command.has("subcommands") else null;
  var sanitized = [];

  # Checks if the first argument could be a subcommand, then parses that instead
  if subcommands:
    for subcmd in subcommands:
      if args.size() > 0:
        if matches_command(subcmd, args[0]):
          return validate_params(subcmd, args.slice(1));

  for i in range(params.size()):
    var param = params[i] as Dictionary;
    var param_name = str(i + 1); #param["name"].to_upper() if param.has("name") else str(i);
    var arg = null;

    if args.size() > i:
      arg = args[i];

    if !param.has("value"): continue;
    var value = param["value"];

    if !param.has("required"): continue;
    var required = param["required"];

    if (not arg) && required:
      return "MISSING PARAM %s" % param_name

    match value:
      "float":
        if arg.is_valid_float():
          sanitized.push_back(float(arg));
        else:
          return "PARAM %s: EXPECTED FLOAT" % param_name
      "bearing":
        if arg.is_valid_int() && arg.length() == 3:
          sanitized.push_back(int(arg));
        else:
          return "PARAM %s: EXPECTED 3-DIGIT BEARING" % param_name
      "flightlevel":
        if arg.begins_with("FL"):
          var fl = arg.substr(2);
          
          if fl.is_valid_int():
            var int_fl = int(fl);
            if int_fl > 0 && int_fl < 500:
              sanitized.push_back(int_fl);
            else:
              # todo fix this mess
              return "PARAM %s: EXPECTED FLIGHT LEVEL" % param_name
          else:
            return "PARAM %s: EXPECTED FLIGHT LEVEL" % param_name
        else:
          return "PARAM %s: EXPECTED FLIGHT LEVEL" % param_name
      _:
        sanitized.push_back(arg);

  return {
    "cmd": command,
    "args": sanitized
  }

func aircraft_command(track: Dictionary, command: Dictionary, args: Array) -> Array:
  if !command.has("name"):
    print_debug("Command has no 'name' prop");
    return [false, "ERR"];

  var params = validate_params(command, args);
  if params is String:
    return [false, params];

  var cmd = [params["cmd"]["command"], params["args"][0]];

  match command["name"]:
    "Heading":
      var res = AircraftManager.execute_command(track, cmd);
      return [true, "HEADING %d" % res];

    "Altitude":
      # Todo determine v/s
      var res = AircraftManager.execute_command(track, cmd);
      return [true, "ALTITUDE %d" % res];

  return [true];


func scope_command(command: Dictionary, args: Array) -> Array:
  if !command.has("name"):
    print_debug("Command has no 'name' prop");
    return [false, "ERR"];

  match command["name"]:
    "Pause":
      set_running_state(false);
      return [true, "PAUSE"];

    "Resume":
      set_running_state(true);
      return [true, "RESUME"];

    "Notepad":
      var params = validate_params(command, [" ".join(args)]);
      if params is String:
        return [false, params];

      return [true, params["args"][0]]

    "Speed":
      var params = validate_params(command, args);
      if params is String:
        return [false, params];

      var new_rate = set_simulation_speed(params["args"][0]);
      return [true, "SPEED %fx" % new_rate];

    "Clear":
      pass
    _:
      return [false, "ILLEGAL SCOPE CMD"]

  return [true];
#endregion
