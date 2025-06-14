class_name MapManager
extends Object

const EARTH_RADIUS = 6378137;
const SCALE_FACTOR = 120;

static func loadVideoMap(node: Control, video_map: String) -> Variant:
  var map_path = "res://data/nav/VideoMaps/%s.geojson" % video_map
  var geojson = ResourceManager.load_json(map_path);

  if geojson == null: return null;

  var features = geojson["features"];

  if !features:
    push_error("Invalid .geojson file: %s" % map_path);
    return null;
  
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

        draw_line(node, points);
      # Todo: impl Point, Polygon
  
  return true;

static func loadMapGroup(node: Control, id: String) -> Variant:
  var map_groups = Simulation.tracon["starsConfiguration"]["mapGroups"];
  var map_group_i = map_groups.find_custom(func(g): return g["id"] == id);

  if map_group_i == -1:
    push_error("Could not load map group: %s" % id);
    return;
  
  var map_group = map_groups[map_group_i];

  for map in map_group["mapIds"]:
    if map != null:
      var video_maps = Simulation.artcc["videoMaps"];
      var video_map_i = video_maps.find_custom(func(m):
        if not m.has("starsId"): return false
        else: return m["starsId"] == map
      );

      if video_map_i == -1:
        push_warning("Could not load video map: %s" % map);
        continue;

      var video_map = video_maps[video_map_i];
      loadVideoMap(node, "%s/%s" % [Simulation.artcc["id"], video_map["id"]]);

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
