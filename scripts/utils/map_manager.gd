class_name MapManager
extends Object

const EARTH_RADIUS = 6378137;
const SCALE_FACTOR = 120;

static func loadVideoMap(node: Control, video_map: String, center: Array) -> Variant:
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
          var rel = to_relative(coord[0], coord[1], center);
          var scaled = scale_coordinates(rel[0], rel[1]);

          points.append(Vector2(scaled[0], scaled[1]));

        draw_line(node, points);
      # "Point":
      #   draw_point(node, coordinates);
  
  return true;

static func draw_line(node: Control, points: PackedVector2Array) -> void:
  var line = Line2D.new();
  line.points = points;
  line.width = 1;
  line.antialiased = true;
  line.default_color = Color.from_ok_hsl(0, 0, 0.7, 0.8)
  node.add_child(line);

# static func draw_point(node: Control, coordinates: Array) -> void:
#   var circle = 

static func scale_coordinates(x, y) -> Array:
  return [x / SCALE_FACTOR, -y / SCALE_FACTOR];

static func to_relative(lng, lat, center_coordinates) -> Array[float]:
  var center_projected = to_mercator(center_coordinates[0], center_coordinates[1]);
  var target_projected = to_mercator(lng, lat);

  return [
    target_projected[0] - center_projected[0],
    target_projected[1] - center_projected[1]
  ];

static func to_mercator(lng, lat) -> Array[float]:
  var x = EARTH_RADIUS * (lng * PI / 180);
  var y = EARTH_RADIUS * log(tan((PI / 4) + (lat * PI / 360)));

  return [x, y];
