extends Control

@onready var camera = %Camera2D;
@export var date = Time.get_date_dict_from_system();

# Nodes
@onready var time = $PC/MC/HBC/VBC/VBC/HBC/Time;
@onready var altimeter = $PC/MC/HBC/VBC/VBC/HBC/Altimeter;
@onready var dcb_range = $PC/MC/HBC/VBC/VBC/HBC2/Range;
@onready var ptl = $PC/MC/HBC/VBC/VBC/HBC2/PTL;
@onready var altitude_filters = $PC/MC/HBC/VBC/VBC/AltitudeFilters;
@onready var facilities = $PC/MC/HBC/VBC/VBC/Facilities;
@onready var tower_lists = $PC/MC/HBC/VBC/TowerLists;
@onready var flight_plans = $PC/MC/HBC/MC/VBC2/FlightPlans/MC/List;

@onready var response_area = $PC/MC/HBC/VBC/Commands/Response;
@onready var preview_area = $PC/MC/HBC/VBC/Commands/Preview;

var preview_text = "";

func _ready() -> void:
  camera.connect("range_changed", Callable(func(new_range):
    dcb_range.text = "%dNM" % new_range
  ));

  # Clear children of ssa facilities list
  for c in facilities.get_children():
    c.queue_free();

  var ssaAirports = Simulation.area["ssaAirports"];
  for arpt in ssaAirports:
    # Fetch metar information from api if online
    # Calculate and or use random data if offline
    var barometric = "29.92";

    var label = Label.new();
    label.text = "%s %s" % [arpt, barometric];
    label.theme = load("res://assets/themes/menu.tres");
    label.theme_type_variation = "TCW";
    facilities.add_child(label);

  # Clear children of ssa tower list
  for c in tower_lists.get_children():
    c.queue_free();

  var towerListConfig = Simulation.area["towerListConfigurations"];
  for twr_list in towerListConfig:
    var list_vbc = VBoxContainer.new();
    list_vbc.add_theme_constant_override("separation", 8);

    var mc = MarginContainer.new();
    mc.add_theme_constant_override("margin_left", 15);
    mc.add_child(list_vbc);

    var label = Label.new();
    label.text = "%s TOWER" % twr_list["airportId"];
    label.theme = load("res://assets/themes/menu.tres");
    label.theme_type_variation = "TCW";
    tower_lists.add_child(label);

    var vbc = VBoxContainer.new();
    vbc.name = twr_list["id"];
    vbc.add_theme_constant_override("separation", 10);
    vbc.add_child(mc);

    tower_lists.add_child(vbc);
  
  for c in flight_plans.get_children():
    c.queue_free();

func _process(_delta: float) -> void:
  var system_time = Time.get_datetime_dict_from_unix_time(Simulation.get_system_time());
  var hours = (str(system_time["hour"])).pad_zeros(2);
  var minutes = (str(system_time["minute"])).pad_zeros(2);
  var seconds = (str(system_time["second"])).pad_zeros(2);

  time.text = "%s%s/%s" % [hours, minutes, seconds];

# Todo store a history buffer for up/down arrow navigation
func _input(event: InputEvent) -> void:
  if event is InputEventKey and event.is_pressed():
    var character = OS.get_keycode_string(event.keycode);

    if character.length() == 1: # Printable characters only
      preview_text += character;
    elif event.keycode == KEY_BACKSPACE and preview_text.length() > 0:
      preview_text = preview_text.left(preview_text.length() - 1);
    elif event.keycode == KEY_SPACE and preview_text.length() > 0 and preview_text[preview_text.length() - 1] != " ": # Todo allow ctrl backspace maybe
      preview_text += " ";
    elif event.keycode == KEY_PERIOD and preview_text.length() > 0 and preview_text[preview_text.length() - 1] != ".": # Todo check if last word contains periods
      preview_text += ".";
    elif event.keycode == KEY_ENTER and preview_text.length() > 0:
      var result = parse_command(preview_text);
      if result: preview_text = "";

    preview_area.text = preview_text;

## Parses the raw command string received from typing in the preview area.
## Aircraft Commands must start with a valid aircraft identifier, before the actual command.
## Scope Commands just begin with the name or alias of the command. [br]
## Returns [bool]
func parse_command(cmd: String) -> bool:
  var args = cmd.split(" ");
  var acft_id = args[0];

  var track = AircraftManager.get_track(acft_id);
  var scope_cmd = Simulation.find_command(args[0], "scope");
  var aircraft_cmd = Simulation.find_command(args[1] if args.size() > 1 else "", "aircraft");

  if track == null and scope_cmd == null:
    response_area.text = "ILLEGAL ACFT ID";
    return false;

  if scope_cmd:
    if !scope_cmd.has("name"):
      response_area.text = "ILLEGAL SCOPE CMD";
      return false;

    if scope_cmd["name"] == "Clear":
      response_area.text = "";

    var result = Simulation.scope_command(scope_cmd, args.slice(1)) as Array;
    if result.size() > 1:
      response_area.text = result[1];

    if !result[0]:
      return false;

  else:
    args = args.slice(1); # Remove the aircraft identifier

    if args.size() < 1:
      response_area.text = "EXPECTED ACFT CMD";
      return false;

    if !aircraft_cmd:
      response_area.text = "ILLEGAL ACFT CMD";
      return false;

    response_area.text = "%s %s" % [track["id"], track["track"]["model_name"]];
    var result = Simulation.aircraft_command(track, aircraft_cmd, args.slice(1));
    
    if result.size() > 1:
      response_area.text = result[1];

    if !result[0]:
      return false;

  return true;
