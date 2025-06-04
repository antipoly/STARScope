extends Control

@export var aircraft_position: Vector2;
@export var aircraft_groundspeed: float;
@export var aircraft_airspeed: float;
@export var aircraft_heading: float;
@export var aircraft_altitude_msl: int;

@export var wind_speed: float = 3.0;
@export var wind_direction: int = 270; # Defines the direction the winds are coming from

# Constants
const G = 9.80665;
@export var aircraft_weight: float; # Technically weight decreases as fuel burns but whatev

# Controi Inputs
@export var pitch: float;
@export var thrust: float;

@export var turn_rate: float;
@export var vertical_speed: float;

# How many nautical miles = 1 pixel
var distance_scale: float = 85.0;

# Data Block Nodes
@onready var db_spc = $Datablock/SPC;
@onready var db_aircraft_id = $Datablock/AircraftID;
@onready var db_altitude = $Datablock/PrimaryGroup/Altitude;
@onready var db_speed = $Datablock/PrimaryGroup/Speed;
@onready var db_wtc = $Datablock/PrimaryGroup/WTC;
@onready var db_dest = $Datablock/SecondaryGroup/DestinationIATA;
@onready var db_aircraft_type = $Datablock/SecondaryGroup/AircraftType;

@onready var db_primary_group = $Datablock/PrimaryGroup;
@onready var db_secondary_group = $Datablock/SecondaryGroup;

# Track Nodes
@onready var ptl = $PTL;
@onready var position_symbol = $Target/PositionSymbol
@onready var trail_parent = $HistoryTrails;

var trail_length = 5;
var trail_phase = 1;
var datablock_phase = 1;

var target_heading = aircraft_heading;
var target_altitude = aircraft_altitude_msl;

var turn_elapsed = 0.0;

func _ready() -> void:
  aircraft_position = position;
  aircraft_groundspeed = randf_range(220, 280);
  aircraft_heading = randi_range(1, 360);
  aircraft_altitude_msl = randi_range(5000, 18000);
  pitch = 0;

  update_datablock();
  await get_tree().create_timer(1.0).timeout;

  # altitude_to(5000, 2500);
  turn_by(90);


func _process(delta: float) -> void:
  var wind = get_wind();

  # Target Aircraft Heading
  if target_heading != aircraft_heading:
    # This does not work
    aircraft_heading = lerp_angle(deg_to_rad(aircraft_heading), deg_to_rad(target_heading), turn_elapsed);
    turn_elapsed += delta;

    if aircraft_heading == target_heading:
      turn_elapsed = 0;

  # Target Aircraft Altitude
  if target_altitude != aircraft_altitude_msl:
    var altitude_change = vertical_speed * (delta / 60);

    if abs(target_altitude - aircraft_altitude_msl) <= abs(altitude_change):
      aircraft_altitude_msl = target_altitude;
      vertical_speed = 0;
    else:
      aircraft_altitude_msl += sign(target_altitude - aircraft_altitude_msl) * altitude_change;
  else:
    vertical_speed = 0;

  # Normalize the unit circle coordinate to a real-life bearing
  var direction_bearing = (90 - int(aircraft_heading)) % 360;
  var direction_rad = deg_to_rad(direction_bearing);

  # Calculate the velocity components using the unit circle
  var speed_x = aircraft_groundspeed * cos(direction_rad);
  var speed_y = -aircraft_groundspeed * sin(direction_rad); # Godot's y-axis increases downward

  var speed = Vector2(speed_x, speed_y) / distance_scale;
  var total_velocity = speed + wind;
  
  ptl.rotation = deg_to_rad((180 + int(aircraft_heading)) % 360);
  aircraft_position += total_velocity * delta;

func get_wind() -> Vector2:
  var wind_bearing = (90 - wind_direction) % 360;
  var wind_direction_rad = deg_to_rad(wind_bearing);

  var wind_x = wind_speed * cos(wind_direction_rad);
  var wind_y = -wind_speed * sin(wind_direction_rad);

  return Vector2(wind_x, wind_y) / distance_scale;

func update_position() -> void:
  position = aircraft_position;

  if trail_phase >= 6:
    var trail = Panel.new();
    trail.position = position;
    trail.size = Vector2(5, 5);

    var style = StyleBoxFlat.new();
    style.bg_color = Color(1, 0, 0, 1);
    style.corner_radius_top_left = 5;
    style.corner_radius_top_right = 5;
    style.corner_radius_bottom_left = 5;
    style.corner_radius_bottom_right = 5;

    trail.add_theme_stylebox_override("panel", style);

    trail_parent.add_child(trail);
    trail_phase = 0;

    if trail_parent.get_child_count() > trail_length:
      trail_parent.get_child(0).queue_free();

  trail_phase += 1;

func update_datablock() -> void:
  db_speed.text = str(int(aircraft_groundspeed) / 10).pad_zeros(2);
  db_altitude.text = str(aircraft_altitude_msl / 100).pad_zeros(3);

  if datablock_phase == 1:
    db_primary_group.show();
    db_secondary_group.hide();

  elif datablock_phase >= 4:
    db_primary_group.hide();
    db_secondary_group.show();
    datablock_phase = 0;

  datablock_phase += 1;

"""
Turns the track to a specified heating (+/-) the current heading
"""
func turn_by(deg: int) -> void:
  target_heading = abs((int(aircraft_heading) + deg) % 360);
  print("[HEADING CHANGE]: %f to %f" % [aircraft_heading, target_heading])

func altitude_to(msl: int, vs: float) -> void:
  if vs <= 0: return;
  if msl <= 100: return;

  print("[ALTITUDE CHANGE]: %f to %f at %f ft/m" % [aircraft_altitude_msl, msl, vs]);
  target_altitude = msl;
  vertical_speed = vs;

# Iteration 2
# To increase altitude:
#   We increase the pitch, depending on the pitch (angle of elevation) and airspeed, that determines how much altitude to gain.
#   The pitch is inversely proportional to airspeed and altitude gain because of the gravitational force.

func pitch_to(deg: int) -> void:
  pass
