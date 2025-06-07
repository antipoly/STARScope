# Autoloaded
extends Node

var aircraft_track := preload("res://scenes/radar/aircraft_track.tscn");
var aircraft_list := [];
var airline_list := [];

## Keeps track of all active aircraft track's node and aircraft info
var global_tracks := [];

var distance_scale := 85; ## How many nautical miles = 1 pixel
var wind_direction: int = 270; ## The direction the winds are coming from
var wind_speed: float = 3.0; ## The wind speed


func _init() -> void:
  var json_aircraft = ResourceManager.load_json("res://data/game/aircraft.json");
  var json_airlines = ResourceManager.load_json("res://data/game/airlines.json");

  if json_aircraft == null:
    push_error("Failed to load aircraft list");
    return ;

  if json_aircraft == null:
    push_error("Failed to load airlines list");
    return ;

  aircraft_list = json_aircraft;
  airline_list = json_airlines;

func get_track(aircraft_id: String) -> Variant:
  for track in global_tracks:
    if track["id"] == aircraft_id:
      return track;

  return null;

## Randomnly spawn an aircraft based on its code.
func spawn_track(radar: Node, track: Dictionary, props: Dictionary) -> void:
  var instance = aircraft_track.instantiate();
  instance.name = props["id"];
  instance.position = props["position"];
  instance.aircraft_altitude_msl = props["altitude"];
  instance.aircraft_heading = props["heading"];
  instance.aircraft_airspeed = props["speed"];

  var wtc = instance.get_node("Datablock/HBC/WTC") as Label;
  var type = instance.get_node("Datablock/HBC/AircraftType") as Label;
  var acft_id = instance.get_node("Datablock/AircraftID") as Label;

  if wtc: wtc.text = track.WTC;
  if type: type.text = track.designator;
  if acft_id: acft_id.text = props["id"];

  global_tracks.push_back({
    "id": props["id"],
    "node": instance,
    "track": track
  });

  radar.add_child(instance);

# Todo (next iter):
# func get_aircraft(fleet)
# This function takes an airline.json fleet and randomnly picks an aircraft from a weight distributed table and assigns a callsign

# func pattern_arrival(aircraft)
# This function will then take the aicraft type and flight number/registration and assign the altitude/heading/speed props
# Iteration 2: This function will then assign a STAR and other flight plan information
func spawn_arrival(radar: Node, code: String = "LCXX") -> void:
  var tracks: Array[Dictionary] = filter_by_code(code);
  if tracks.size() == 0:
    push_error("No matching aircrafts for code: %s" % code);
    return ;

  var props = {
    "position": Vector2(randf_range(-500, 500), randf_range(-500, 500)),
    "heading": randi_range(1, 360),
    "altitude": 0,
    "speed": 0,
    "id": ""
  }

  # Iteration 2: Use a defined spawn pattern to describe an aircraft's course, position, altitude, navigation aids etc
  # Todo: Make sure aircraft id's are unique
  var track := tracks[randi_range(0, tracks.size() - 1)];
  match track["code"][1]:
    # Commercial Aircraft
    "C":
      props["altitude"] = randi_range(9000, 12000);
      props["speed"] = randi_range(220, 280);
      props["id"] = generate_flight_number();
    _:
      props["altitude"] = randi_range(5000, 18000);
      props["speed"] = randi_range(150, 250);
      props["id"] = generate_registration_number();

  spawn_track(radar, track, props);

## Returns a subset of aircraft_list filtered by a code. Use X as a wildcard.
## A code is a 4 character string defined as [Aircraft Class, Aircraft Use Category, Engine Count, Engine Type]
## Aircraft Class: LandPlane (L), Helicopter (H)
## Aircraft Use Category: Commercial (C), Corporate (B), General Aviation (G), Military (M)
## Engine Count: Number
## Engine Type: Jet, Piston, Turboprop/Turboshaft
func filter_by_code(code: String) -> Array[Dictionary]:
  var filtered_aircraft: Array[Dictionary] = [];

  for aircraft in aircraft_list:
    if not aircraft.has("code"): continue ;
    var flag = true;

    for i in range(4):
      if code[i] != "X" && code[i] != aircraft["code"][i]:
        flag = false;

    if flag == true:
      filtered_aircraft.push_back(aircraft);

  return filtered_aircraft;

## Generates flight numbers for commercial aviation to:
## - Avoid aircraft type (eg: 737)
## - Superstitions (eg: 13, 666)
## - Avoid flight numbers associated with air incidents
func generate_flight_number() -> String:
  var airline = airline_list[randi_range(0, airline_list.size() - 1)];
  var number: int;

  var forbidden_numbers = [11, 13, 17, 77, 93, 666, 103, 911, 175, 191, 3407, 370, 447, 990, 587, 182, 123, 800, 522, 812, 9268, 148, 981, 604, 7425]
  var forbidden_patterns = [
    "^73[0-9]{1,2}$", # Boeing aircraft
  ];

  while true:
    number = randi_range(1, 9999);
    var skip = false;

    if number in forbidden_numbers:
      continue ;

    for pattern in forbidden_patterns:
      if str(number).matchn(pattern):
        skip = true;
        break; # Break the inner loop

    if skip:
      continue ;

    break;

  return airline["icao"] + str(number);

## Generates a random FAA registration number.
## Rules:
##   1 to 5 numbers (eg: N12345)
##   1 to 4 numbers + 1 character (eg: N1234A)
##   1 to 3 numbers + 2 characters (eg: N123AB)
##   The total length, including the N, must not exceed 6 characters
##   The letters "I" and "O" cannot be used in the suffix
##   It cannot begin with a 0
##   N1 to N99 is reserved by the FAA
func generate_registration_number() -> String:
  var characters = "ABCDEFGHJKLMNQRSTUVWXYZ";
  var number = randi_range(100, 99999);
  
  var str_number = str(number);
  var suffix = "";

  for i in range(5 - str_number.length()):
    suffix += characters[randi_range(0, characters.length() - 1)];

  return "N" + str_number + suffix;

func get_wind() -> Vector2:
  var wind_bearing = (90 - wind_direction) % 360;
  var wind_direction_rad = deg_to_rad(wind_bearing);

  var wind_x = wind_speed * cos(wind_direction_rad);
  var wind_y = -wind_speed * sin(wind_direction_rad);

  return Vector2(wind_x, wind_y) / distance_scale;

#region Cmd Parsing

# Going to parse commands from a JSON file, which will define aliases, description, parameters, etc
# We'll use this JSON file to handle autocomplete later
func parse_command_args(track, args: Array) -> void:
  pass

func execute_command(track, code) -> void:
  pass

#endregion