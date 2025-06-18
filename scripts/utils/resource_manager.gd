# Autoloaded
extends Node

var player: Player = null;
var specialisations: Array;

const MAX_CONCURRENT = 8;
var request_queue = [];
var active_requests = 0;

#region Loading

func load_json(path: String) -> Variant:
  if !FileAccess.file_exists(path):
    push_error("File does not exist: %s" % path);
    return null;

  var file = FileAccess.open(path, FileAccess.READ);
  if not file:
    push_error("Failed to open file: %s" % path);
    return null;

  var data = JSON.parse_string(file.get_as_text());
  file.close();

  print_debug("Loaded %s" % path);
  return data;

func queue_download(url, local):
  var req_data = {
    "url": url,
    "local": local
  };

  request_queue.append(req_data);
  _process_request_queue();

func _process_request_queue():
  while active_requests < MAX_CONCURRENT and request_queue.size() > 0:
    var req = request_queue.pop_front();
    var http = HTTPRequest.new();
    add_child(http);

    active_requests += 1;
    http.connect("request_completed", Callable(self, "_on_request_completed").bind(req["local"], req["url"], http));
    var err = http.request(req["url"]);

    if err != OK:
      push_error("HTTP Request failed: %s" % err);
      http.queue_free();
      active_requests -= 1;

func _on_request_completed(_result, code, _headers, body, local, url, http_req):
  http_req.queue_free();

  if code != 200:
    push_error("HTTP %d: %s" % [code, url])
    return;

  var file = FileAccess.open(local, FileAccess.WRITE);
  if not file:
    push_error("Failed to open local file for writing: %s" % local);
    return;

  file.store_buffer(body);
  file.close();

  print("Downloaded %s" % url);
  active_requests -= 1;
  _process_request_queue();

func download_maps(artcc: String):
  var artcc_path = "user://nav/ARTCCs/%s.json" % artcc;
  var artcc_json = load_json(artcc_path);

  if not artcc_json:
    push_error("Could not fetch map list from %s ARTCC file" % artcc);
    return null;

  var map_dir = "user://nav/VideoMaps/%s" % artcc;

  if not DirAccess.dir_exists_absolute(map_dir):
    DirAccess.make_dir_recursive_absolute(map_dir);

  var maps = artcc_json["videoMaps"];
  for map in maps:
    var map_id = map["id"];
    var remote_url = "https://data-api.vnas.vatsim.net/Files/VideoMaps/%s/%s.geojson" % [artcc, map_id];
    var local_url = "user://nav/VideoMaps/%s/%s.geojson" % [artcc, map_id];

    queue_download(remote_url, local_url);

func download_artcc(artcc):
  var local_url = "user://nav/ARTCCs/%s.json" % artcc;
  var remote_url = "https://data-api.vnas.vatsim.net/api/artccs/%s" % artcc;

  if not DirAccess.dir_exists_absolute("user://nav/ARTCCs"):
    DirAccess.make_dir_recursive_absolute("user://nav/ARTCCs");

  queue_download(remote_url, local_url);

#endregion

#region Player Resources

## Returns a Player resource, or null
## @param force - Forces returning a Player resource no matter if it didn't exist
func get_player(force = true) -> Player:
  if player == null:
    if FileAccess.file_exists("user://player.tres"):
      player = ResourceLoader.load("user://player.tres");
    else:
      if force == true:
        player = Player.new();

  return player;

func save_player():
  return ResourceSaver.save(player, "user://player.tres");

func get_player_level() -> Dictionary:
  var matchedRatings = player.ratings.filter(func(rating): return rating.specialisation == player.active_specialisation);
  if matchedRatings.is_empty():
    return {"name": "N/A", "threshold": 0};

  var spec = matchedRatings[0];
  if not specialisations:
    specialisations = ResourceManager.load_json("res://data/game/specialisations.json");

  var specLevels = specialisations[player.active_specialisation].levels as Array;
  var currentLevel = specLevels[0];

  for level in specLevels:
    if level.threshold <= spec.experience:
      if level.threshold > currentLevel.threshold:
        currentLevel = level;

  return currentLevel;

func get_specialisation() -> Dictionary:
  var spec = { "id": 0, "name": "N/A", "acr": "N/A", "levels": [] };

  if not specialisations:
    specialisations = ResourceManager.load_json("res://data/game/specialisations.json");

  for specialisation in specialisations:
    if player.active_specialisation == specialisation.id:
      spec = specialisation;

  return spec;

# Todo: optimize to not load from json each time (?)

#endregion
