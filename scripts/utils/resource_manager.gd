extends Node

var player: Player = null;

func json_file(path: String) -> Variant:
  if !FileAccess.file_exists(path):
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
