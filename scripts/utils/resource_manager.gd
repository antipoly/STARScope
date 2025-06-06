# Autoloaded
extends Node

var player: Player = null;

func load_json(path: String) -> Variant:
  if !FileAccess.file_exists(path):
    push_error("File does not exist: %s" % path);
    return null;

  var file = FileAccess.open(path, FileAccess.READ);
  if file:
    var data = JSON.parse_string(file.get_as_text());
    file.close();
    return data;
  else:
    push_error("Failed to open file: %s" % path);
    return null;

"""
Returns a Player resource, or null
@param force - Forces returning a Player resource no matter if it didn't exist
"""
func get_player(force = true) -> Player:
  if player == null:
    if FileAccess.file_exists("user://player.tres"):
      player = ResourceLoader.load("user://player.tres");
    else:
      if force == true:
        player = Player.new();

  return player;

func save_player():
  return ResourceSaver.save(player, "user://player.tres");

func get_player_level() -> Dictionary:
  var matchedRatings = player.ratings.filter(func(rating): return rating.specialisation == player.active_specialisation);
  if matchedRatings.is_empty():
    return {"name": "N/A", "threshold": 0};

  var spec = matchedRatings[0];
  var specialisations = ResourceManager.load_json("res://data/game/specialisations.json");

  var specLevels = specialisations[player.active_specialisation].levels as Array;
  var currentLevel = specLevels[0];

  for level in specLevels:
    if level.threshold <= spec.experience:
      if level.threshold > currentLevel.threshold:
        currentLevel = level;

  return currentLevel;

func get_specialisation() -> Dictionary:
  var spec = { "id": 0, "name": "N/A", "acr": "N/A", "levels": [] };

  var specialisations = load_json("res://data/game/specialisations.json");
  if !specialisations:
    return spec;


  for specialisation in specialisations:
    if player.active_specialisation == specialisation.id:
      spec = specialisation;

  return spec;

# Todo: optimize to not load from json each time (?)
