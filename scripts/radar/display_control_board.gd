extends Control

@onready var dcb_range = $PC/HBC/Range
@onready var range_ring = $PC/HBC/RangeRings
@onready var map_container = $PC/HBC/MapContainer;
@onready var camera = %Camera2D;
@onready var radar = %Radar;

@onready var dcb_container = $PC/HBC;
@onready var map_menu = $PC/HBC/MapMenu/Maps;
@onready var brite_menu = $PC/HBC/BriteMenu;

signal dcb_rr(spacing)

var rr_enabled = false;
var range_enabled = false;

func _ready() -> void:
  dcb_range.text = "RANGE\n%d" % camera.current_range;
  camera.connect("range_changed", Callable(self, "_on_range_changed"));

  var map_groups = Simulation.tracon["starsConfiguration"]["mapGroups"];
  # todo: figure out which map_group is supposed to be used where
  load_maps(map_groups[0]);

#region Init

func load_maps(map_group: Dictionary) -> void:
  for map_box in map_container.get_children():
    var i = map_box.get_index();
    var map_index = (i % 3) * 2 + int(float(i) / 3) # 3-column row-major to 2-row column-major grid

    var map_star_id = map_group["mapIds"][map_index];
    var video_map = Simulation.get_video_map(map_star_id);

    if video_map:
      map_box.text = "%d\n%s" % [map_star_id, video_map["shortName"]];
      map_box.connect("toggled", Callable(self, "toggle_video_map").bind(map_star_id))
    else:
      map_box.text = "";
  
  for map_box in map_menu.get_children():
    var i = map_box.get_index();
    var map_index = (i % 16) * 2 + int(float(i) / 16) # 16-column row-major to 2-row column-major grid

    var map_star_id = map_group["mapIds"][map_index + 6]; # offset the 6 provided in the map_container grid
    var video_map = Simulation.get_video_map(map_star_id);

    if video_map:
      map_box.text = "%d\n%s" % [map_star_id, video_map["shortName"]];
      map_box.connect("toggled", Callable(self, "toggle_video_map").bind(map_star_id))
    else:
      map_box.text = "";

#endregion

#region Util

func set_visibility_to_the_right(index: int, shouldHide: bool = true) -> void:
  for c in dcb_container.get_children():
    if c.get_index() > index and !c.name.ends_with("Menu"):
      c.visible = !shouldHide;

func toggle_video_map(toggle, stars_id) -> void:
  var video_map = Simulation.get_video_map(stars_id);
  
  if video_map != null:
    MapManager.toggle_video_map($"../../Radar/VideoMaps", video_map["id"]);

#endregion

#region Events

func _on_range_changed(new_range: int) -> void:
  dcb_range.text = "RANGE\n%d" % new_range

func _on_range_toggled(toggled_on: bool) -> void:
  range_enabled = toggled_on;

func _on_range_gui_input(event: InputEvent) -> void:
  pass # Replace with function body.

func _on_range_rings_toggled(toggled_on: bool) -> void:
  rr_enabled = toggled_on;

func _on_range_rings_gui_input(event: InputEvent) -> void:
  if !rr_enabled: return ;

  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
      radar.rr_spacing = clamp(radar.rr_spacing + 1, 1, 20);
      emit_signal("dcb_rr", radar.rr_spacing);
      
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
      radar.rr_spacing = clamp(radar.rr_spacing - 1, 1, 20);
      emit_signal("dcb_rr", radar.rr_spacing);

  # if event is InputEventMouseMotion:
  #   var rect = range_ring.get_global_rect();
  #   print(rect.position, rect.position +rect.size)
  #   var clamped_position = event.position.clamp(rect.position, rect.position + rect.size);
  #   Input.warp_mouse(clamped_position);

func _on_maps_pressed() -> void:
  var map_submenu = dcb_container.find_child("MapMenu");
  var maps = dcb_container.find_child("Maps");
  if !map_submenu or !maps: return;

  set_visibility_to_the_right(maps.get_index(), !map_submenu.visible);
  map_submenu.visible = !map_submenu.visible

#endregion
