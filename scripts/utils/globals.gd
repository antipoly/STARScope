extends Node

var player: Player

func _ready() -> void:
  if not FileAccess.file_exists("user://data/player.tres"):
    print('uh oh')
  else:
    player = load("user://data/player.tres")


# Loading
# var player = Player.new()
# Resou
