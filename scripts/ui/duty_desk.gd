extends PanelContainer

var page_index = 0;
var pages = ["ModeSelection", "FacilitySelection", "Weather&Time", "Traffic"];
@onready var next_button = $MC/HBC/RightColumn/NextButton;
@onready var page_container = $MC/HBC;

func _ready() -> void:
  pass

func to_page(index: int) -> void:
  if (index < 0) or (index + 1 > pages.size()): return;

  var current_page = page_container.find_child(pages[page_index]) as Control;
  if current_page == null: return;

  var current_page_tween = current_page.create_tween();
  current_page_tween.tween_property(current_page, "modulate:a", 0.0, 0.5).from(1.0);

  var target_page = page_container.find_child(pages[index]) as Control;
  if target_page == null: return;

  target_page.show();
  current_page.hide();

  var target_page_tween = target_page.create_tween();
  target_page_tween.tween_property(target_page, "modulate:a", 1.0, 0.5).from(0.0);

  page_index = index;
  if page_index == 3:
    next_button.text = "Begin Duty";

func _on_next_button_pressed() -> void: 
  if page_index == 3:
    get_tree().change_scene_to_file("res://scenes/ui/radar/tcw.tscn");
  else:
    to_page(page_index + 1);
