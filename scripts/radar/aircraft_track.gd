extends Control

@export var aircraft_position: Vector2;
@export var aircraft_groundspeed: float;
@export var aircraft_airspeed: float;
@export var aircraft_direction: int;
@export var aircraft_altitude_msl: int;

@export var wind_speed: float = 3.0;
@export var wind_direction: int = 270; # Defines the direction the winds are coming from

# How many nautical miles = 1 pixel
@export var distance_scale: float = 90.0;

# Datablock Nodes
@onready var db_spc = $Datablock/SPC;
@onready var db_aircraft_id = $Datablock/AircraftID;
@onready var db_altitude = $Datablock/PrimaryGroup/Altitude;
@onready var db_speed = $Datablock/PrimaryGroup/Speed;
@onready var db_wtc = $Datablock/PrimaryGroup/WTC;
@onready var db_dest = $Datablock/SecondaryGroup/DestinationIATA;
@onready var db_aircraft_type = $Datablock/SecondaryGroup/AircraftType;

@onready var db_primary_group = $Datablock/PrimaryGroup;
@onready var db_secondary_group = $Datablock/SecondaryGroup;

var datablock_phase := 1;

func _ready() -> void:
  aircraft_position = position;
  aircraft_groundspeed = randf_range(220, 280);
  aircraft_direction = randi_range(1, 360);

func _process(delta: float) -> void:
  var wind = get_wind();

  # Normalize the unit circle coordinate to a real-life bearing
  var direction_bearing = (90 - aircraft_direction) % 360;
  var direction_rad = deg_to_rad(direction_bearing);

  # Calculate the velocity components using the unit circle
  var speed_x = aircraft_groundspeed * cos(direction_rad);
  var speed_y = -aircraft_groundspeed * sin(direction_rad); # Godot's y-axis increases downward

  var speed = Vector2(speed_x, speed_y) / distance_scale;
  var total_velocity = speed + wind;
  
  aircraft_position += total_velocity * delta;

func get_wind() -> Vector2:
  var wind_bearing = (90 - wind_direction) % 360;
  var wind_direction_rad = deg_to_rad(wind_bearing);

  var wind_x = wind_speed * cos(wind_direction_rad);
  var wind_y = -wind_speed * sin(wind_direction_rad);

  return Vector2(wind_x, wind_y) / distance_scale;

func update_position() -> void:
  position = aircraft_position;
  pass

func update_datablock() -> void:
  if datablock_phase == 1:
    db_primary_group.show();
    db_secondary_group.hide();
  elif datablock_phase == 4:
    db_primary_group.hide();
    db_secondary_group.show();

  if datablock_phase >= 4: datablock_phase = 0;
  datablock_phase += 1;

func turn_left(deg: int) -> void:
  pass
