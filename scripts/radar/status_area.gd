extends Control

@onready var camera = %Camera2D;
@export var date = Time.get_date_dict_from_system();

# Nodes
@onready var range_ptl = $"PC/MC/HBC/VBC/VBC/Range-PTL"

@onready var preview_area = $PC/MC/HBC/VBC/Commands/Preview

var preview_text = "";

func _ready() -> void:
  camera.connect("range_changed", Callable(func(new_range): range_ptl.text = "%dNM  PTL: 3.0" % new_range));

func _input(event: InputEvent) -> void:
  if event is InputEventKey and event.is_pressed() and not event.is_echo():
    var char = OS.get_keycode_string(event.keycode);

    if char.length() == 1: # Printable characters only
      preview_text += char;
    elif event.keycode == KEY_BACKSPACE and preview_text.length() > 0:
      preview_text = preview_text.left(preview_text.length() - 1);
    elif event.keycode == KEY_SPACE and preview_text.length() > 0 and preview_text[preview_text.length() - 1] != " ":
      preview_text += " ";
    elif event.keycode == KEY_ENTER and preview_text.length() > 0:
      parse_command(preview_text);
      preview_text = "";

    preview_area.text = preview_text;

## Aircraft Commands: Must start with a valid aircraft identifier.
func parse_command(cmd: String) -> void:
  var args = cmd.split(" ");
  var acft_id = args[0];

  var track = AircraftManager.get_track(acft_id);
  if track == null:
    print("Invalid aircraft id");
    return;

  print(track)
