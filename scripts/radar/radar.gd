extends Control

@export var update_interval: float = 0.1;
@export var rr_spacing: float = 100.0;
@export var rr_count: int = 30;

var radar_pass: Timer;
@onready var range_rings = $RangeRings;
@onready var video_maps = $VideoMaps;

@onready var dcb = %DisplayControlBoard

var center_coordinates := [-74.12753592427075, 40.68075933728596]; # Will be defined based on scenario

func _ready() -> void:
  Input.set_default_cursor_shape(Input.CURSOR_CROSS);
  radar_pass = Timer.new();
  radar_pass.wait_time = update_interval;
  radar_pass.autostart = true;
  radar_pass.connect("timeout", Callable(self, "_update_radar"));
  add_child(radar_pass);

  MapManager.loadVideoMap(video_maps, "ZNY/01G66ETNBBVPD0812MB31HJCBZ", center_coordinates);
  MapManager.loadVideoMap(video_maps, "ZNY/01G90NPTFQ2DK0CXJB8Q3GBPE4", center_coordinates);
  MapManager.loadVideoMap(video_maps, "ZNY/01G90QP1RZH8T82E79EXHPZG0B", center_coordinates);
  
  _redraw_range_rings();
  dcb.connect("dcb_rr", Callable(self, "_redraw_range_rings"));

  # await get_tree().create_timer(10).timeout;
  # rr_spacing = 50.0;
  # _redraw_range_rings()

func _update_radar() -> void:
  var tracks = get_tree().get_nodes_in_group("track");

  for track in tracks:
    if track.has_method("update_position"): track.update_position();
    if track.has_method("update_datablock"): track.update_datablock();

# Todo fix the arc on the right side; its incomplete
func _redraw_range_rings() -> void:
  print('redrawing')
  for c in range_rings.get_children():
    c.queue_free();

  for i in range(1, rr_count + 1):
    var radius = i * rr_spacing;
    var ring = Line2D.new();
    ring.width = 1.0;
    ring.default_color = Color.from_ok_hsl(0, 0, 0.35, 0.5);
    # ring.antialiased = true;

    var points = PackedVector2Array();
    for angle in range(0, 360, 5):
      var rad = deg_to_rad(angle);
      points.append(Vector2(cos(rad) * radius, sin(rad) * radius));

    ring.points = points;
    range_rings.add_child(ring);
