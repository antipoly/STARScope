extends HBoxContainer

@onready var contractContainer: Control = $EmploymentContract
@onready var continueText: Control = $ContinueText

# @onready var nameInput: Control = $EmploymentContract/MarginContainer/VBoxContainer/NameInput/LineEdit
# @onready var selectedDivision: Control = $EmploymentContract/MarginContainer/VBoxContainer/DivisionInput/OptionButton
# @onready var termsAgreement: Control = $EmploymentContract/MarginContainer/VBoxContainer/AgreeToTerms/CheckBox
@onready var signHereButton: Button = $EmploymentContract/MarginContainer/VBoxContainer/Button

var input_handled := false;

var nameInput = "";
var agreedToTerms = false;
var divisionId = -1;

func _ready() -> void:
  updateSignHereButtonState();
  pass

func _input(event):
  if !input_handled && event is InputEventKey:
    input_handled = true;
    var text_tween = continueText.create_tween().set_parallel();
    # text_tween.tween_property(continueText, "position:x", 50, 1.5).from_current(); # sigh
    text_tween.tween_property(continueText, "modulate:a", 0.0, 1.5).from(1.0);
    text_tween.tween_callback(Callable(continueText, "hide"));

    var container_tween = contractContainer.create_tween();
    container_tween.tween_property(contractContainer, "modulate:a", 1.0, 1.5).from(0);

    contractContainer.visible = true;

func updateSignHereButtonState() -> void:
  if !nameInput.is_empty() && agreedToTerms && divisionId >= 0:
    signHereButton.disabled = false;
  else:
    signHereButton.disabled = true;

func _on_terms_toggled(toggled_on: bool) -> void:
  agreedToTerms = toggled_on;
  updateSignHereButtonState();

func _on_division_selected(index: int) -> void:
  divisionId = index;
  updateSignHereButtonState();

func _on_name_submitted(new_text: String) -> void:
  nameInput = new_text;
  updateSignHereButtonState();

"""
Handles the event when the 'Sign Here' button is pressed in the intro screen
"""
func _on_contract_signed() -> void:
  pass
