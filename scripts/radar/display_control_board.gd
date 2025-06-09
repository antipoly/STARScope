extends Control

@onready var dcb_range = $PanelContainer/HBoxContainer/Range
@onready var range_ring = $PanelContainer/HBoxContainer/RangeRings
@onready var camera = %Camera2D;
@onready var radar = %Radar;

signal dcb_rr(spacing)

var rr_enabled = false;
var range_enabled = false;

func _ready() -> void:
  dcb_range.text = "RANGE\n%d" % camera.current_range;
  camera.connect("range_changed", Callable(self, "_on_range_changed"));

func _on_range_changed(new_range: int) -> void:
  dcb_range.text = "RANGE\n%d" % new_range

func _on_range_toggled(toggled_on: bool) -> void:
  range_enabled = toggled_on;

func _on_range_gui_input(event: InputEvent) -> void:
  pass # Replace with function body.

func _on_range_rings_toggled(toggled_on: bool) -> void:
  rr_enabled = toggled_on;


func _on_range_rings_gui_input(event: InputEvent) -> void:
  if !rr_enabled: return;

  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
      radar.rr_spacing = clamp(radar.rr_spacing + 1, 1, 20);
      emit_signal("dcb_rr", radar.rr_spacing);
      
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
      radar.rr_spacing = clamp(radar.rr_spacing - 1, 1, 20);
      emit_signal("dcb_rr", radar.rr_spacing);

  # if event is InputEventMouseMotion:
  #   var rect = range_ring.get_global_rect();
  #   print(rect.position, rect.position +rect.size)
  #   var clamped_position = event.position.clamp(rect.position, rect.position + rect.size);
  #   Input.warp_mouse(clamped_position);
