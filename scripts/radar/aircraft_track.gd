extends Control

@export var aircraft_position: Vector2;
@export var aircraft_airspeed: float;
@export var aircraft_heading: float;
@export var aircraft_altitude_msl: float;
@export var aircraft_groundspeed: float; # Derived from winds

# Constants
const G = 9.80665;
@export var aircraft_weight: float; # Technically weight decreases as fuel burns but whatev

# Controi Inputs
@export var pitch: float;
@export var thrust: float;

# Rates
@export var acceleration: float = 2;
@export var turn_rate: float = 500;
@export var vertical_speed: float = 2000;

# Data Block Nodes
@onready var db_spc = $Datablock/SPC as Label;
@onready var db_aircraft_id = $Datablock/AircraftID as Label;
@onready var db_altitude = $Datablock/HBC/Altitude as Label;
@onready var db_speed = $Datablock/HBC/Speed as Label;
@onready var db_wtc = $Datablock/HBC/WTC as Label;
@onready var db_aircraft_type = $Datablock/HBC/AircraftType as Label;
# @onready var db_dest = $Datablock/HBC/DestinationIATA;

# Track Nodes
@onready var ptl = $PTL as Panel;
@onready var track_target = $Target as Panel;
@onready var position_symbol = $Target/PositionSymbol as Label;
@onready var trail_parent = $HistoryTrails as Control;
var camera: Camera2D;

var trail_length = 5;
var trail_phase = 1;
var datablock_phase = 1;

var target_speed: float;
var target_heading: float;
var target_altitude: float;

func _ready() -> void:
  aircraft_position = position;
  aircraft_groundspeed = calc_groundspeed(aircraft_heading, aircraft_airspeed).length();
  pitch = 0;

  target_heading = aircraft_heading;
  target_altitude = aircraft_altitude_msl;
  target_speed = aircraft_airspeed;

  camera = get_viewport().get_camera_2d();
  update_datablock();

  # await get_tree().create_timer(1.0).timeout
  # altitude_to(5000, 2500);
  # turn_by(90);

# Todo: abstract the logic into functions
func _process(delta: float) -> void:
  delta *= Simulation.simulation_rate;
  if Simulation.paused:
    return;

  if camera:
    self.scale = Vector2(1.1, 1.1) / camera.zoom;

  # Todo: The farther the camera is zoomed, it should fade in transparency
  for c in trail_parent.get_children():
    c.scale = Vector2(1.1, 1.1) / camera.zoom;

  # Target Aircraft Heading
  if target_heading != aircraft_heading:
    var angle_diff = wrapf(target_heading - aircraft_heading, -180, 180);
    var max_turn = (turn_rate / aircraft_airspeed) * delta;
    var turn  = clamp(angle_diff, -max_turn, max_turn);

    aircraft_heading += turn;
    aircraft_heading = fmod(aircraft_heading + 360, 360);

  # Target Aircraft Altitude
  if target_altitude != aircraft_altitude_msl:
    var altitude_diff = target_altitude - aircraft_altitude_msl;
    var max_change: float = vertical_speed * (delta / 60);

    var altitude_change = clampf(altitude_diff, -max_change, max_change);
    aircraft_altitude_msl += altitude_change;
  else:
    vertical_speed = 0;

  # Target Aircraft Airspeed
  if target_speed != aircraft_airspeed:
    var speed_diff = target_speed - aircraft_airspeed;
    var max_accel = acceleration * delta;

    var speed_change = clampf(speed_diff, -max_accel, max_accel);
    aircraft_airspeed += speed_change;

  var groundspeed = calc_groundspeed(aircraft_heading, aircraft_airspeed);
  aircraft_groundspeed = groundspeed.length();

  aircraft_position += (groundspeed / AircraftManager.distance_scale) * delta;

func calc_groundspeed(heading: float, airspeed: float) -> Vector2:
  var direction_rad = Math.normalize_bearing(heading);
  var speed := Math.vectorize(direction_rad, airspeed);
  var wind := AircraftManager.get_wind();

  return speed + wind;

func update_position() -> void:
  position = aircraft_position;

  if trail_phase >= int(6 / Simulation.simulation_rate):
    var trail = Panel.new();
    trail.top_level = true;
    trail.position = global_position + (track_target.size / 2);
    trail.size = Vector2(8, 8);
    trail.pivot_offset = trail.size / 2;
    trail.z_index = -1;

    var style = StyleBoxFlat.new();
    style.bg_color = Color.from_rgba8(51, 51, 159, 180);
    style.corner_radius_top_left = 5;
    style.corner_radius_top_right = 5;
    style.corner_radius_bottom_left = 5;
    style.corner_radius_bottom_right = 5;
    style.anti_aliasing = false;

    trail.add_theme_stylebox_override("panel", style);

    trail_parent.add_child(trail);
    trail_phase = 0;

    if trail_parent.get_child_count() > trail_length:
      trail_parent.get_child(0).queue_free();

  trail_phase += 1;

func update_datablock() -> void:
  update_ptl();

  db_speed.text = str(int(aircraft_groundspeed) / 10).pad_zeros(2);
  db_altitude.text = str(int(aircraft_altitude_msl) / 100).pad_zeros(3);

  if datablock_phase >= int(2 / Simulation.simulation_rate):
    db_speed.visible = !db_speed.visible;
    db_wtc.visible = !db_wtc.visible;
    db_aircraft_type.visible = !db_aircraft_type.visible;
    datablock_phase = 0;

  datablock_phase += 1;

func update_ptl() -> void:
  ptl.rotation = deg_to_rad((180 + int(aircraft_heading)) % 360);
  var ptl_x = (cos(ptl.rotation)) + (track_target.size.x / 2.0);
  var ptl_y = -(sin(ptl.rotation)) + (track_target.size.y / 2.0);

  ptl.position = Vector2(ptl_x, ptl_y);

#region Commands

## Turns the track to a specified heating (+/-) the current heading
func turn_by(deg: int) -> int:
  target_heading = (int(aircraft_heading) + deg) % 360;
  if target_heading < 0: target_heading += 360;

  print("[HEADING CHANGE %s]: %f to %f" % [name, aircraft_heading, target_heading])
  return int(target_heading);

## Turns the track to the specified bearing
func turn_to(bearing: int) -> int:
  var delta = int((bearing - int(aircraft_heading) + 360) % 360)
  if delta > 180: delta -= 360
  
  return turn_by(delta)

func altitude_to(msl: int, vs: float) -> float:
  if vs <= 0: return target_altitude;
  if msl <= 100: return target_altitude;

  print("[ALTITUDE CHANGE %s]: %f to %f at %f ft/m" % [name, aircraft_altitude_msl, msl, vs]);
  target_altitude = msl;
  vertical_speed = vs;

  return target_altitude;

func speed_to(speed: int) -> int:
  # check within reasonable limits, such as aircraft maximum minimum operating speeds
  target_speed = speed;

  print("[SPEED CHANGE %s]: %d to %d" % [name, aircraft_airspeed, target_speed]);
  return int(target_speed);

# Iteration 2
# To increase altitude:
#   We increase the pitch, depending on the pitch (angle of elevation) and airspeed, that determines how much altitude to gain.
#   The pitch is inversely proportional to airspeed and altitude gain because of the gravitational force.

# func pitch_to(deg: int) -> void:
#   pass

# func roll_to(deg: int) -> void:
#   pass

#endregion
