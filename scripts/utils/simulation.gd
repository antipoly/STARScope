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
    return ;

  if artccs.size() == 0:
    push_warning("No ARTCCs present in file");

  # Read ARTCCs folder
  var dir = DirAccess.open("user://nav/ARTCCs");
  if dir:
    dir.list_dir_begin();
    var file_name = dir.get_next();
    
    while file_name != "":
      if not dir.current_is_dir() and file_name.ends_with(".json"):
        var artcc_data = ResourceManager.load_json("user://nav/ARTCCs/" + file_name);
        if !artcc_data: continue ;

        ARTCCs[artcc_data["id"]] = artcc_data;
      file_name = dir.get_next();

    dir.list_dir_end();
  else:
    push_error("Failed to open ARTCCs directory");

  ARTCCData = artccs;

func load_scenario(scenario: Dictionary) -> void:
  if !scenario.has("system_time") or !scenario.has("artcc") or !scenario.has("tracon") or !scenario.has("position"):
    push_error("Could not load scenario");
    return ;

  shift_start_time = scenario["system_time"];

  artcc = Simulation.ARTCCs[scenario["artcc"]];
  tracon = artcc["facility"]["childFacilities"][scenario["tracon"]];
  position = tracon["positions"][scenario["position"]];

  var area_index = tracon["starsConfiguration"]["areas"].find_custom(func(ar): return ar["id"] == position["starsConfiguration"]["areaId"]);
  area = tracon["starsConfiguration"]["areas"][area_index];
  center_coordinates = area["visibilityCenter"];

  get_tree().change_scene_to_file("res://scenes/radar/tcw.tscn");

func get_video_map(stars_id) -> Variant:
  if stars_id == null:
    return ;

  var video_maps = Simulation.artcc["videoMaps"];
  var video_map_i = video_maps.find_custom(func(m):
    if not m.has("starsId"): return false
    else: return m["starsId"] == stars_id
  );

  if video_map_i == -1:
    push_warning("Could not find video map: %d" % stars_id);
    return null;

  return video_maps[video_map_i];

func _process(delta: float) -> void:
  if not paused:
    elapsed_time += delta * simulation_rate;

## Pause or resume the simulation
func set_running_state(running: bool) -> void:
  paused = !running;

func set_simulation_rate(speed: float) -> float:
  # var radar = get_node("../TerminalControlWorkstation/Radar");
  # if radar:
  #   radar.update_interval /= Simulation.simulation_rate;
  simulation_rate = clampf(speed, 0.2, 5.0);
  return simulation_rate;

func get_system_time() -> int:
  return shift_start_time + int(elapsed_time);

#region Commands

## Returns the [Command] that matches the string provided under the specified type [br]
## Returns [Command] [br]
## Returns [null] - When no command was found
func find_command(arg: String, type: String) -> Variant:
  var cmds = null;

  if type == "scope":
    cmds = scope_commands;
  elif type == "aircraft":
    cmds = aircraft_commands;
  else:
    return null;

  for cmd in cmds:
    if !arg: continue ;
    if matches_command(cmd, arg):
      return cmd;

  return null;

## Checks if a string matches the name or any of the aliases of a command [br]
## Returns [bool]
func matches_command(command: Dictionary, arg: String) -> bool:
  if command.has("command"):
    if command["command"] == arg:
      return true;

  if command.has("aliases"):
    for alias in command["aliases"]:
      if alias == arg:
        return true;

  return false;

## Takes an array of command arguments and splits them into multiple commands to execute. [br]
## If [track] is not null, the commands are assumed to be aircraft_commands, if not: scope_commands [br]
##
## [codeblock]
## return [
##   true,                      # success
##   "ALTITUDE 3000; SPEED 250" # message
## ]
## [/codeblock]
func multicommand(args: Array, track: Variant):
  var command_type = "aircraft" if track else "scope";
  var param_count = 0;
  var commands = [];
  var messages: PackedStringArray = [];

  for arg in args:
    var cmd = commands.back() if commands.size() > 0 else null;

    if param_count > 0:
      cmd["args"].push_back(arg);

      param_count -= 1;

      # All arguments for the command collected at this point
      if param_count == 0:
        var result = validate_params(cmd.get("command"), cmd.get("args"));

        if result is String:
          return [false, result];

      continue ;

    var command = find_command(arg, command_type);
    if !command:
      return [false, "ILLEGAL ACFT CMD"];

    cmd = {
      "command": command,
      "args": []
    };

    commands.push_back(cmd);
    param_count = command["params"].size();

  if commands.size() == 0:
    return [false, "NO COMMANDS FOUND"];

  # Edge case validation check: if the last command has a parameter that wasn't provided
  if param_count != 0:
    var cmd = commands.back();
    var result = validate_params(cmd.get("command"), cmd.get("args"));

    if result is String:
      return [false, result];

  # Execute all the parsed commands
  for cmd in commands:
    var result = aircraft_command(track, cmd.get("command"), cmd.get("args"));
    if !result.get(0):
      return [false, result.get(1)];

    messages.push_back(result.get(1));

  return [true, "; ".join(messages)];

## Parses and validates the arguments provided to a command and sanitizes the arguments
## to conform to the expected type structure [br]
##
## Returns [Dictionary { cmd: Dictionary, sanitized: Array }] [br]
## Returns [String] - The error message
func validate_params(command: Dictionary, args: Array) -> Variant:
  if !command.has("params") && !command.has("subcommands"): return ;
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
    var param_name = str(i + 1); # param["name"].to_upper() if param.has("name") else str(i);
    var arg = null;

    if args.size() > i:
      arg = args[i];

    if !param.has("value"): continue ;
    var value = param["value"];

    if !param.has("required"): continue ;
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
      "knots":
        if arg.is_valid_int():
          var val = int(arg);
          if val > 350 or val < 60:
            return "PARAM %s: OUTSIDE ACCEPTED RANGE" % param_name
          
          sanitized.push_back(val);
        else:
          return "PARAM %s: EXPECTED INT" % param_name
      _:
        sanitized.push_back(arg);

  return {
    "cmd": command,
    "args": sanitized
  }


## Executes an aircraft command on the provided track with the args passed, and returns the status [br]
## Returns [Array(success: bool, message: String)]
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

    "Speed":
      var res = AircraftManager.execute_command(track, cmd);
      return [true, "SPEED %d" % res];

  return [true];

## Executes a scope command with the args passed, and returns the status [br]
## Returns [Array(success: bool, message: String)]
func scope_command(command: Dictionary, args: Array) -> Array:
  match command.get("name"):
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

    "Rate":
      var params = validate_params(command, args);
      if params is String:
        return [false, params];

      var new_rate = set_simulation_rate(params["args"][0]);
      return [true, "RATE %fx" % new_rate];

    "Clear":
      pass
    _:
      return [false, "ILLEGAL SCOPE CMD"]

  return [true];
#endregion
