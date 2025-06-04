class_name Utils
extends Object

static func fade_opaque(node: Node, direction: String, duration = 0.5) -> Tween:
  var from_color: Color
  var to_color: Color

  if direction == "in":
    from_color = Color(0, 0, 0, 1);
    to_color = node.modulate;
  else:
    from_color = node.modulate;
    to_color = Color(0, 0, 0, 1);

  var tween = node.create_tween()
  tween.tween_property(node, "modulate", to_color, duration).from(from_color)

  return tween;

static func fade_alpha(node: Node, direction: String, duration = 0.5) -> Tween:
  var from_alpha := 0.0 if direction == "in" else 1.0;
  var to_alpha := 1.0 if direction == "in" else 0.0;

  var tween = node.create_tween();
  tween.tween_property(node, "modulate:a", to_alpha, duration).from(from_alpha);

  return tween;
