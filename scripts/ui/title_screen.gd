extends PanelContainer

@onready var player_name: Label = $MC/HBC/PlayerPanel/MC/VBC/VBC/PlayerName
@onready var specialisation_level: Label = $MC/HBC/PlayerPanel/MC/VBC/VBC/VBC/SpecialisationLevel
@onready var facility_level: Label = $MC/HBC/PlayerPanel/MC/VBC/VBC/VBC/FacilityLevel

@onready var menu_content = $"../";

# Signals
signal menu_changed(menu_name: String);

# Scenes
var duty_desk := preload("res://scenes/ui/menu/duty_desk.tscn");

func _ready() -> void:
  var player = ResourceManager.get_player(false);
  if !player:
    return ;

  player_name.text = player.player_name.strip_edges();
  facility_level.text = "Facility Level %d" % player.facility_level;

  var spec = ResourceManager.get_specialisation();
  var level = ResourceManager.get_player_level();

  specialisation_level.text = "%s %s" % [spec.acr, level.name];

func _on_duty_desk_pressed() -> void:
  emit_signal("menu_changed", "Duty Desk");
  change_menu_screen(duty_desk);

func _on_multiplayer_pressed() -> void:
  pass # Replace with function body.


func _on_settings_pressed() -> void:
  pass # Replace with function body.


func _on_stats_pressed() -> void:
  pass # Replace with function body.


func _on_help_pressed() -> void:
  pass # Replace with function body.

func change_menu_screen(scene: PackedScene) -> void:
  # Removes any other loaded scene
  for child in menu_content.get_children():
    if child is Control and child.scene_file_path != "":
      child.queue_free()

  
  var instance = scene.instantiate();
  menu_content.add_child(instance);

  # Todo: Fire signal to update and animate the topbar
