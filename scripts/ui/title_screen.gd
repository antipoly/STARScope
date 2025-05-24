extends HBoxContainer

@onready var PlayerName: Label = $PlayerPanel/MarginContainer/VBoxContainer/VBoxContainer/PlayerName
@onready var SpecialisationLevel: Label = $PlayerPanel/MarginContainer/VBoxContainer/VBoxContainer/VBoxContainer/SpecialisationLevel
@onready var FacilityLevel: Label = $PlayerPanel/MarginContainer/VBoxContainer/VBoxContainer/VBoxContainer/FacilityLevel

func _ready() -> void:
  var player = ResourceManager.get_player(false);
  if !player:
    return;

  PlayerName.text = player.player_name;
  FacilityLevel.text = "Facility Level %d" % player.facility_level;

  var specialisations = ResourceManager.json_file("res://data/game/specialisations.json");
  var spec = null;

  for specialisation in specialisations:
    if player.active_specialisation == specialisation.id:
      spec = specialisation;

  SpecialisationLevel.text = "%s %s" % [spec.acr, 'getLevelFromExperience()']

func _on_duty_desk_pressed() -> void:
  pass # Replace with function body.


func _on_multiplayer_pressed() -> void:
  pass # Replace with function body.


func _on_settings_pressed() -> void:
  pass # Replace with function body.


func _on_stats_pressed() -> void:
  pass # Replace with function body.


func _on_help_pressed() -> void:
  pass # Replace with function body.
