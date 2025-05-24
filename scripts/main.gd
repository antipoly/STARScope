extends Node

func _ready() -> void:
  var player = ResourceManager.get_player(false);
  if player == null:
    call_deferred("change_scene", "res://scenes/ui/menu/intro.tscn");
  else:
    call_deferred("change_scene", "res://scenes/ui/menu.tscn");


func change_scene(scene_path: String) -> void:
  get_tree().change_scene_to_file(scene_path);
