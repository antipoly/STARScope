extends Camera2D

signal range_changed(range: int)
@export var current_range := 100; # Todo fix scaling

const min_zoom: float = 0.05;
const max_zoom: float = 2;
const min_range: float = 1;
const max_range: float = 256;

var is_panning: bool = false;
var last_mouse_position: Vector2;

func _ready() -> void:
  zoom = Vector2(range_to_zoom(current_range), range_to_zoom(current_range));

# Zooming should be even
# Video maps, range rings should always be 1px
# Aircraft tracks should always be the same size

func _input(event: InputEvent) -> void:
  var min_zoom_vec = Vector2(min_zoom, min_zoom);
  var max_zoom_vec = Vector2(max_zoom, max_zoom);

  # Todo fix - very broken bad
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP:
      var zoom_increment = (max_zoom - min_zoom) / (max_range - min_range);
      if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom_increment *= -1;
      # print(zoom_increment)

      zoom = (zoom + Vector2(zoom_increment, zoom_increment)).clamp(min_zoom_vec, max_zoom_vec);
      current_range = zoom_to_range(zoom.x);
      emit_signal("range_changed", current_range);

    elif event.button_index == MOUSE_BUTTON_RIGHT:
      if event.pressed:
        is_panning = true;
        last_mouse_position = event.position;
      else:
        is_panning = false;
  
  if event is InputEventMouseMotion && is_panning:
    global_position -= (event.position - last_mouse_position) / zoom;
    last_mouse_position = event.position;

func range_to_zoom(dcb_range: float) -> float:
  return max_zoom - ((dcb_range - min_range) / (max_range - min_range)) * (max_zoom - min_zoom);

func zoom_to_range(cam_zoom: float) -> int:
  return roundi(min_range + ((max_zoom - cam_zoom) / (max_zoom - min_zoom)) * (max_range - min_range))
