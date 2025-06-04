extends PanelContainer

var page_index = 0;
var pages = ["ModeSelection", "FacilitySelection", "Weather&Time", "Traffic"];

@onready var next_button = $MC/HBC/RightColumn/NextButton;
@onready var page_container = $MC/HBC;
@onready var topbar = $"../../Topbar" #%Topbar;

func _ready() -> void:
  topbar.connect("current_menu_pressed", Callable(self, "_on_current_menu_pressed"));
  pass

func to_page(index: int) -> void:
  if (index < 0) or (index + 1 > pages.size()): return;

  var current_page = page_container.find_child(pages[page_index]) as Control;
  if current_page == null: return;

  Utils.fade_alpha(current_page, "out");

  var target_page = page_container.find_child(pages[index]) as Control;
  if target_page == null: return;

  target_page.show();
  current_page.hide();

  Utils.fade_alpha(target_page, "in");

  page_index = index;
  if page_index == 3:
    next_button.text = "Begin Duty";

func _on_next_button_pressed() -> void: 
  if page_index == 3:
    get_tree().change_scene_to_file("res://scenes/ui/radar/tcw.tscn");
  else:
    to_page(page_index + 1);

func _on_current_menu_pressed() -> void:
  if page_index == 0:
    get_tree().change_scene_to_file("res://scenes/ui/menu.tscn");
  else:
    to_page(page_index - 1);
