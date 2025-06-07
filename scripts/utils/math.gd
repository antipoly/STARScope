class_name Math
extends Node

static func normalize_bearing(deg: float) -> float:
  var bearing = (90 - int(deg)) % 360;
  return deg_to_rad(bearing);

static func vectorize(rad: float, length: float) -> Vector2:
  var x = length * cos(rad);
  var y = -length * sin(rad);

  return Vector2(x, y);