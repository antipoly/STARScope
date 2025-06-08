# Autoloaded
extends Node

# Going to manage the current scenario, time, weather, etc

@export var paused: bool = false;
@export var simulation_rate: float = 1.0; ## The speed of the simulation

var shift_start_time: int; ## The shift start time epoch (seconds)
var elapsed_time: float = 0.0;

var aircraft_commands := [];
var scope_commands := [];

func _init() -> void:
  var commands = ResourceManager.load_json("res://data/game/commands.json") as Dictionary;
  if commands == null:
    push_error("Failed to load commands");
    return ;

  if commands.has("aircraft"):
    aircraft_commands = commands["aircraft"];

  if commands.has("scope"):
    scope_commands = commands["scope"];

func load_scenario(scenario: Dictionary) -> void:
  if scenario.has("system_time"):
    shift_start_time = scenario["system_time"];

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
  var cmds = scope_commands if type == "scope" else aircraft_commands;

  for cmd in cmds:
    if cmd["command"] == arg:
      return cmd;

    if cmd.has("aliases"):
      for alias in cmd["aliases"]:
        if alias == arg:
          return cmd;

  return null;

func validate_params(command: Dictionary, args: Array) -> Variant:
  if !command.has("params"): return;
  var sanitized = [];
  
  for i in range(command["params"].size()):
    var param = command["params"][i] as Dictionary;
    var arg = null;
    if args.size() > i:
      arg = args[i];

    if !param.has("value"): continue;
    var value = param["value"];

    if !param.has("required"): continue;
    var required = param["required"];

    if (not arg) && required:
      return "Required param %d was missing" % i;

    match value:
      "float":
        if arg is String and arg.is_valid_float():
          sanitized.push_back(float(arg));
        else:
          return "Param %d, got string, expected float" % i
      _:
        sanitized.push_back(arg);

  return sanitized;

func aircraft_command(track, args: Array) -> void:
  pass

func scope_command(command: Dictionary, args: Array) -> Array:
  match command["name"]:
    "Pause":
      set_running_state(false);
      return [true, "Pause"];
    "Resume":
      set_running_state(true);
      return [true, "Resume"];
    "Notepad":
      var params = validate_params(command, [" ".join(args)]);
      if params is String:
        return [false, params];
      
      return [true, params[0]]
    "Speed":
      var params = validate_params(command, args);
      if params is String:
        return [false, params];

      var new_rate = set_simulation_speed(params[0]);
      return [true, "Speed %fx" % new_rate]
    "Clear":
      pass
    _:
      return [false, "Command '%s' not found" % command["name"]]

  return [true];
#endregion
