extends Control

@export var aircraft_position: Vector2;
@export var aircraft_velocity: Vector2;
@export var aircraft_direction: int;

func _ready() -> void:
  print("hello from aircraft");

func update_position() -> void:
  print("..");
  pass

func update_datablock() -> void:
  print("...");
  pass
