class_name MapManager
extends Object

const EARTH_RADIUS = 6378137;
const SCALE_FACTOR = 120;

static func loadVideoMap(node: Control, video_map: String, center: Array[float]) -> void:
  var geojson = ResourceManager.load_json("res://data/nav/VideoMaps/%s.geojson" % video_map);
  if geojson == null:
    print("Could not open .geojson");
    return;

  var features = geojson["features"];

  if !features:
    print("Invalid .geojson");
    return;
  
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

static func draw_line(node: Control, points: Array) -> void:
  var line = Line2D.new();
  line.points = points;
  line.width = 1;
  line.antialiased = true;
  node.add_child(line);

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
