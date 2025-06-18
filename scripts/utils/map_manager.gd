class_name MapManager
extends Object

const EARTH_RADIUS = 6378137;
const SCALE_FACTOR = 120;

static func load_video_map(node: Control, video_map: String) -> Variant:
  var map_path = "user://nav/VideoMaps/%s/%s.geojson" % [Simulation.artcc["id"], video_map]
  var geojson = ResourceManager.load_json(map_path);

  if geojson == null: return null;
  var features = geojson["features"];

  if node.find_child(video_map, false, false):
    push_warning("Video map %s already loaded" % video_map);
    return;

  if !features:
    push_error("Invalid .geojson file: %s" % map_path);
    return null;

  var map_parent = Control.new();
  map_parent.name = video_map;
  node.add_child(map_parent);

  for feature in features:
    var geometry = feature["geometry"];
    var coordinates = geometry["coordinates"];
    var type = geometry["type"];

    match type:
      "LineString":
        var points: PackedVector2Array = PackedVector2Array();
        for coord in coordinates:
          var rel = to_relative(coord[0], coord[1], Simulation.center_coordinates);
          var scaled = scale_coordinates(rel[0], rel[1]);

          points.append(Vector2(scaled[0], scaled[1]));

        draw_line(map_parent, points);
      # Todo: impl Point, Polygon

  return true;

static func toggle_video_map(node: Control, video_map: String) -> void:
  var existing = node.find_child(video_map, false, false);

  if existing:
    existing.queue_free();
  else:
    load_video_map(node, video_map);

static func load_map_group(node: Control, id: String) -> Variant:
  var map_groups = Simulation.tracon["starsConfiguration"]["mapGroups"];
  var map_group_i = map_groups.find_custom(func(g): return g["id"] == id);

  if map_group_i == -1:
    push_error("Could not load map group: %s" % id);
    return;

  var map_group = map_groups[map_group_i];

  for stars_id in map_group["mapIds"]:
    if stars_id != null:
      var video_map = Simulation.get_video_map(stars_id);

      if video_map != null:
        load_video_map(node, video_map["id"]);

  return true;

static func draw_line(node: Control, points: PackedVector2Array) -> void:
  var line = Line2D.new();
  line.points = points;
  line.width = 1;
  line.antialiased = true;
  line.default_color = Color.from_ok_hsl(0, 0, 0.7, 0.3)
  node.add_child(line);


static func scale_coordinates(x, y) -> Array:
  return [x / SCALE_FACTOR, -y / SCALE_FACTOR];

static func to_relative(lng, lat, center_coordinates) -> Array[float]:
  var center_projected = to_mercator(center_coordinates["lon"], center_coordinates["lat"]);
  var target_projected = to_mercator(lng, lat);

  return [
    target_projected[0] - center_projected[0],
    target_projected[1] - center_projected[1]
  ];

static func to_mercator(lng, lat) -> Array[float]:
  var x = EARTH_RADIUS * (lng * PI / 180);
  var y = EARTH_RADIUS * log(tan((PI / 4) + (lat * PI / 360)));

  return [x, y];
