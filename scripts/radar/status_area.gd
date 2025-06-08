extends Control

@onready var camera = %Camera2D;
@export var date = Time.get_date_dict_from_system();

# Nodes
@onready var time = $PC/MC/HBC/VBC/VBC/HBC/Time;
@onready var altimeter = $PC/MC/HBC/VBC/VBC/HBC/Altimeter;
@onready var dcb_range = $PC/MC/HBC/VBC/VBC/HBC2/Range;
@onready var ptl = $PC/MC/HBC/VBC/VBC/HBC2/PTL;
@onready var altitude_filters = $PC/MC/HBC/VBC/VBC/AltitudeFilters;
@onready var facilities_info = $PC/MC/HBC/VBC/VBC/FacilitiesInfo;

@onready var response_area = $PC/MC/HBC/VBC/Commands/Response;
@onready var preview_area = $PC/MC/HBC/VBC/Commands/Preview;

var preview_text = "";

func _ready() -> void:
  camera.connect("range_changed", Callable(func(new_range):
    dcb_range.text = "%dNM" % new_range
  ));

func _process(delta: float) -> void:
  var system_time = Time.get_datetime_dict_from_unix_time(Simulation.get_system_time());
  var hours = (str(system_time["hour"])).pad_zeros(2);
  var minutes = (str(system_time["minute"])).pad_zeros(2);
  var seconds = (str(system_time["second"])).pad_zeros(2);

  time.text = "%s%s/%s" % [hours, minutes, seconds];

func _input(event: InputEvent) -> void:
  if event is InputEventKey and event.is_pressed():
    var character = OS.get_keycode_string(event.keycode);

    if character.length() == 1: # Printable characters only
      preview_text += character;
    elif event.keycode == KEY_BACKSPACE and preview_text.length() > 0:
      preview_text = preview_text.left(preview_text.length() - 1);
    elif event.keycode == KEY_SPACE and preview_text.length() > 0 and preview_text[preview_text.length() - 1] != " ": # Todo allow echo for backspace and maybe ctrl backspace
      preview_text += " ";
    elif event.keycode == KEY_PERIOD and preview_text.length() > 0 and preview_text[preview_text.length() - 1] != ".": # Todo check if last word contains periods 
      preview_text += ".";
    elif event.keycode == KEY_ENTER and preview_text.length() > 0:
      parse_command(preview_text);
      preview_text = "";

    preview_area.text = preview_text;

## Aircraft Commands: Must start with a valid aircraft identifier.
func parse_command(cmd: String) -> void:
  var args = cmd.split(" ");
  var acft_id = args[0];

  var track = AircraftManager.get_track(acft_id);
  var scope_cmd = Simulation.find_command(args[0], "scope");

  if track == null and scope_cmd == null:
    response_area.text = "Invalid aircraft id";
    return ;

  if scope_cmd:
    if !scope_cmd.has("name"):
      response_area.text = "Invalid command";
      return;

    if scope_cmd["name"] == "Clear":
      response_area.text = "";

    var result = Simulation.scope_command(scope_cmd, args.slice(1)) as Array;
    if result.size() > 1:
      response_area.text = result[1];

  else:
    response_area.text = "%s %s" % [track["id"], track["track"]["model_name"]];
    Simulation.aircraft_command(track, args.slice(1));
