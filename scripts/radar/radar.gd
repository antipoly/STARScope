extends Panel

@export var UPDATE_INTERVAL: float = 1.0;

var radar_pass: Timer;

func _ready() -> void:
  mouse_default_cursor_shape = Control.CURSOR_CROSS; # Todo: This doesnt change child controls cursors'
  radar_pass = Timer.new();
  radar_pass.wait_time = UPDATE_INTERVAL;
  radar_pass.autostart = true;
  radar_pass.connect("timeout", Callable(self, "_update_radar"));
  add_child(radar_pass);

func _update_radar() -> void:
  var tracks = get_tree().get_nodes_in_group("track");
  
  for track in tracks:
    if track.has_method("update_position"): track.update_position();
    if track.has_method("update_datablock"): track.update_datablock();
      
