extends Control

@export var update_interval: float = 1.0
  # set(new_interval):
  #   update_interval = new_interval;
  #   _on_interval_changed()

@export var rr_spacing: float = 100.0;
@export var rr_count: int = 30;

var radar_pass: Timer;
@onready var range_rings = $RangeRings;
@onready var video_maps = %VideoMaps;
@onready var tracks = $Tracks;

@onready var dcb = %DisplayControlBoard

func _ready() -> void:
  Input.set_default_cursor_shape(Input.CURSOR_CROSS);

  # Hardcoded Aircraft Spawns
  AircraftManager.spawn_arrival(tracks, "LCXX");
  AircraftManager.spawn_arrival(tracks, "LCXX");
  AircraftManager.spawn_arrival(tracks, "LCXX");
  AircraftManager.spawn_arrival(tracks, "LCXX");
  AircraftManager.spawn_arrival(tracks, "LCXX");
  
  _on_interval_changed();
  _redraw_range_rings();
  dcb.connect("dcb_rr", Callable(self, "_redraw_range_rings"));

  # await get_tree().create_timer(10).timeout;
  # rr_spacing = 50.0;
  # _redraw_range_rings()

func _on_interval_changed():
  # var old_timer = get_node_or_null("RadarInterval");
  # if old_timer:
  #   old_timer.free();
  # print(update_interval, Simulation.simulation_rate, update_interval / Simulation.simulation_rate)

  radar_pass = Timer.new();
  radar_pass.name = "RadarInterval";
  radar_pass.wait_time = update_interval / Simulation.simulation_rate;
  radar_pass.autostart = true;

  radar_pass.connect("timeout", Callable(self, "_update_radar"));
  add_child(radar_pass);

func _input(event: InputEvent) -> void:
  if event.is_action_pressed("tcw_back"):
    get_tree().change_scene_to_file("res://scenes/menu.tscn");

func _update_radar() -> void:
  if Simulation.paused:
    return;

  for track in tracks.get_children():
    if track.has_method("update_position"): track.update_position();
    if track.has_method("update_datablock"): track.update_datablock();

# Todo fix the arc on the right side; its incomplete
func _redraw_range_rings() -> void:
  for c in range_rings.get_children():
    c.queue_free();

  for i in range(1, rr_count + 1):
    var radius = i * rr_spacing;
    var ring = Line2D.new();
    ring.width = 1.0;
    ring.default_color = Color.from_ok_hsl(0, 0, 0.35, 0.5);

    var points = PackedVector2Array();
    for angle in range(0, 360, 5):
      var rad = deg_to_rad(angle);
      points.append(Vector2(cos(rad) * radius, sin(rad) * radius));

    ring.points = points;
    range_rings.add_child(ring);
