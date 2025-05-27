extends Camera2D

@export var zoom_speed: float = 0.1;
@export var pan_speed: float = 300;
@export var min_range: float = 1;
@export var max_range: float = 256;

var is_panning: bool = false;
var last_mouse_position: Vector2;

# Zooming with mouse scroll
# Panning with right-click
func _input(event: InputEvent) -> void:
  var min_zoom = Vector2(normalize_range(min_range), normalize_range(min_range));
  var max_zoom = Vector2(normalize_range(max_range), normalize_range(max_range));

  # Todo fix
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_DOWN && !is_panning:
      zoom = (zoom - Vector2(zoom_speed, zoom_speed)).clamp(min_zoom, max_zoom);
    elif event.button_index == MOUSE_BUTTON_WHEEL_UP && !is_panning:
      zoom = (zoom + Vector2(zoom_speed, zoom_speed)).clamp(min_zoom, max_zoom);
    elif event.button_index == MOUSE_BUTTON_RIGHT:
      if event.pressed:
        is_panning = true;
        last_mouse_position = event.position;
      else:
        is_panning = false;
  
  if event is InputEventMouseMotion && is_panning:
    global_position -= (event.position - last_mouse_position) / zoom;
    last_mouse_position = event.position;

func normalize_range(dcb_range: float) -> float:
  return dcb_range / 12;
