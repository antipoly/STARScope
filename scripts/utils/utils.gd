class_name Utils
extends Object

static func fade(node: Node, direction: String, duration = 0.5) -> Tween:
  var black_overlay: ColorRect = node.find_child("FadeInOut") as ColorRect;

  if not black_overlay:
    black_overlay = ColorRect.new();
    black_overlay.name = "FadeInOut";
    black_overlay.color = Color.BLACK;
    node.add_child.call_deferred(black_overlay);

  var from_alpha := 0.0 if direction == "in" else 1.0;
  var to_alpha := 1.0 if direction == "in" else 0.0;

  var tween = black_overlay.create_tween();
  tween.tween_property(black_overlay, "modulate:a", from_alpha, duration).from(to_alpha);
  if direction == "in": tween.tween_callback(Callable(black_overlay, "queue_free"));

  return tween;

static func getPlayerLevel(player: Player) -> Variant:
  var matchedRatings = player.ratings.filter(func(rating): return rating.specialisation == player.active_specialisation);
  if matchedRatings.is_empty():
    return null;

  var spec = matchedRatings[0];
  var specialisations = ResourceManager.load_json("res://data/game/specialisations.json");

  var specLevels = specialisations[player.active_specialisation].levels as Array;
  var currentLevel = specLevels[0];

  for level in specLevels:
    if level.threshold <= spec.experience:
      if level.threshold > currentLevel.threshold:
        currentLevel = level;

  return currentLevel;
