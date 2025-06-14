extends PanelContainer

var page_index = 0;
var pages = ["ModeSelection", "FacilitySelection", "Weather&Time", "Traffic"];

@onready var topbar = $"../../Topbar";
@onready var next_button = $MC/HBC/RightColumn/NextButton;
@onready var page_container = $MC/HBC;

@onready var artcc_option = $MC/HBC/FacilitySelection/SC/VBC/MC/VBC/ARTCC/OptionButton;
@onready var tracon_option = $MC/HBC/FacilitySelection/SC/VBC/MC/VBC/TRACON/OptionButton;
@onready var position_option = $MC/HBC/FacilitySelection/SC/VBC/MC/VBC/Position/OptionButton;

func _ready() -> void:
  topbar.connect("current_menu_pressed", Callable(self, "_on_current_menu_pressed"));
  pass

func to_page(index: int) -> void:
  if (index < 0) or (index + 1 > pages.size()): return ;

  var current_page = page_container.find_child(pages[page_index]) as Control;
  if current_page == null: return ;

  Utils.fade_alpha(current_page, "out");

  var target_page = page_container.find_child(pages[index]) as Control;
  if target_page == null: return ;

  target_page.show();
  current_page.hide();

  Utils.fade_alpha(target_page, "in");

  page_index = index;
  next_button.text = "Next";
  
  if page_index == 1:
    facility_selection();
  elif page_index == 2:
    pass
  elif page_index == 3:
    next_button.text = "Begin Duty";

func _on_next_button_pressed() -> void:
  if page_index == 3: # Last Page

    var scenario = {
      "system_time": Time.get_unix_time_from_system(),
      "artcc": artcc_option.get_selected_metadata(),
      "tracon": tracon_option.get_selected_id(),
      "position": position_option.get_selected_id(),
    };

    Simulation.load_scenario(scenario);
  else:
    to_page(page_index + 1);

func _on_current_menu_pressed() -> void:
  if page_index == 0:
    get_tree().change_scene_to_file("res://scenes/menu.tscn");
  else:
    to_page(page_index - 1);

#region Facility

func facility_selection() -> void:
  # Populate ARTCC Option Button
  artcc_option.clear();

  for key in Simulation.ARTCCs:
    var artcc = Simulation.ARTCCs[key];
    var id = artcc_option.item_count;

    artcc_option.add_item("[%s] %s" % [key, artcc["facility"]["name"]], id);
    artcc_option.set_item_metadata(id, key);

  _on_artcc_item_selected();

func _on_artcc_item_selected() -> void:
  var tracon_facilities = Simulation.ARTCCs[artcc_option.get_selected_metadata()]["facility"]["childFacilities"];
  tracon_option.clear();

  for tracon in tracon_facilities:
    var id = tracon_option.item_count;
    var facility_level = 9; # Placeholder

    tracon_option.add_item("[%s] %s (%d)" % [tracon["id"], tracon["name"], facility_level]);
    tracon_option.set_item_metadata(id, tracon["id"]);
  
  _on_tracon_item_selected(tracon_option.get_selected_id());

func _on_tracon_item_selected(index: int) -> void:
  var positions = Simulation.ARTCCs[artcc_option.get_selected_metadata()]["facility"]["childFacilities"][index]["positions"];
  position_option.clear();

  for pos in positions:
    var id = position_option.item_count;

    position_option.add_item("[%s] %s" % [pos["callsign"], pos["radioName"]]);
    position_option.set_item_metadata(id, pos["id"]);

#endregion
