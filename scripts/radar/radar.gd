extends Control

@export var update_interval: float = 1.0;
@export var rr_count: int = 15;
@export var rr_spacing: float = 100.0;

var radar_pass: Timer;

var center_coordinates;

func _ready() -> void:
  Input.set_default_cursor_shape(Input.CURSOR_CROSS);
  radar_pass = Timer.new();
  radar_pass.wait_time = update_interval;
  radar_pass.autostart = true;
  radar_pass.connect("timeout", Callable(self, "_update_radar"));
  add_child(radar_pass);

  MapManager.loadVideoMap(self, "ZNY/01G66ETNBBVPD0812MB31HJCBZ", [-74.12753592427075, 40.68075933728596]);

func _update_radar() -> void:
  var tracks = get_tree().get_nodes_in_group("track");

  for track in tracks:
    if track.has_method("update_position"): track.update_position();
    if track.has_method("update_datablock"): track.update_datablock();

func _draw() -> void:
  for i in range(1, rr_count + 1):
    var radius = i * rr_spacing;
    draw_arc(Vector2.ZERO, radius, 0, TAU, 100, Color(0.5, 0.5, 0.5, 0.3), 1.0);
