class_name AircraftManager
extends Node

static var aircraft_list: Array[Dictionary] = [];
static var airline_list: Array[Dictionary] = [];

static var aircraft_track := preload("res://scenes/ui/radar/aircraft_track.tscn");

func _ready() -> void:
  var json_aircraft = ResourceManager.load_json("res://data/game/aircraft.json");
  var json_airlines = ResourceManager.load_json("res://data/game/airlines.json");

  if json_aircraft == null:
    push_error("Failed to load aircraft list");
    return;

  if json_aircraft == null:
    push_error("Failed to load airlines list");
    return;

  aircraft_list = json_aircraft;
  airline_list = json_airlines;

"""
Randomnly spawn an aircraft based on its code.
"""
static func spawn_track(radar: Node, track: Dictionary, props: Dictionary) -> void:
  var instance = aircraft_track.instantiate();
  instance.aircraft_position = props["position"];
  instance.aircraft_altitude = props["altitude"];
  instance.aircraft_heading = props["heading"];
  instance.aircraft_airspeed = props["speed"];

  var wtc = instance.get_node("Datablock/HBC/WTC") as Label;
  var type = instance.get_node("Datablock/HBC/AircraftType") as Label;
  var acft_id = instance.get_node("Datablock/AircraftID") as Label;

  if wtc: wtc.text = track.WTC;
  if type: type.text = track.designator;
  if acft_id: acft_id.text = props["id"];

  radar.add_child(instance);


static func spawn_arrival(radar: Node, code: String = "LCXX") -> void:
  var tracks: Array[Dictionary] = filter_by_code(code);
  if tracks.size() == 0:
    push_error("No matching aircrafts for code: %s" % code);
    return;

  var props = {
    "position": Vector2(randi_range(-500, 500), randi_range(-500, 500)),
    "altitude": 0,
    "heading": 0,
    "speed": 0,
    "id": ""
  }

  # Iteration 2: Use a defined spawn pattern to describe an aircraft's course, position, altitude, navigation aids etc
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

"""
Returns a subset of aircraft_list filtered by a code. Use X as a wildcard.
A code is a 4 character string defined as [Aircraft Class, Aircraft Use Category, Engine Count, Engine Type]
Aircraft Class: LandPlane (L), Helicopter (H)
Aircraft Use Category: Commercial (C), Corporate (B), General Aviation (G), Military (M)
Engine Count: Number
Engine Type: Jet, Piston, Turboprop/Turboshaft
"""
static func filter_by_code(code: String) -> Array[Dictionary]:
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

"""
Generates flight numbers for commercial aviation to:
  Avoid aircraft type (eg: 737)
  Superstitions (eg: 13, 666)
  Avoid flight numbers associated with air incidents
"""
static func generate_flight_number() -> String:
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
      continue;

    for pattern in forbidden_patterns:
      if str(number).matchn(pattern):
        skip = true;
        break;

    if skip:
      continue;

  return airline["icao"] + str(number);

"""
Generates a random FAA registration number.
Rules:
  1 to 5 numbers (eg: N12345)
  1 to 4 numbers + 1 character (eg: N1234A)
  1 to 3 numbers + 2 characters (eg: N123AB)
  The total length, including the N, must not exceed 6 characters
  The letters "I" and "O" cannot be used in the suffix
  It cannot begin with a 0
  N1 to N99 is reserved by the FAA
"""
static func generate_registration_number() -> String:
  var characters = "ABCDEFGHJKLMNQRSTUVWXYZ";
  var number = randi_range(100, 99999);
  
  var str_number = str(number);
  var suffix = "";

  for i in range(5 - str_number.length()):
    suffix += characters[randi_range(0, characters.length() - 1)];

  return "N" + str_number + suffix;
