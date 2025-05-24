extends Node

var player: Player = null;

func get_player(force = true) -> Player:
  if player == null:
    if FileAccess.file_exists("user://data/player.tres"):
      player = ResourceLoader.load("user://data/player.tres");
    else:
      if force == true:
        player = Player.new();

  return player;

func save_player():
  ResourceSaver.save(player, "user://data/player.tres");