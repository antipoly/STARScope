extends Control

@onready var dcb_range = $PanelContainer/HBoxContainer/Range
@onready var camera = %Camera2D;

func _ready() -> void:
  dcb_range.text = "Range\n%d" % camera.current_range;
  camera.connect("range_changed", Callable(self, "_on_range_changed"));

func _on_range_changed(new_range: int) -> void:
  dcb_range.text = "Range\n%d" % new_range
