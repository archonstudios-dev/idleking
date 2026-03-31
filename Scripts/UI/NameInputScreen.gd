# Collects and validates the player's king name before gameplay starts.
extends Control

const GameThemeScript := preload("res://Scripts/UI/GameTheme.gd")
const UiAtlasScript := preload("res://Scripts/UI/UiAtlas.gd")
const TITLE_SCENE := "res://Scenes/Bootstrap/TitleScreen.tscn"
const MAIN_GAME_SCENE := "res://Scenes/Main/MainGameScreen.tscn"

@onready var name_input: LineEdit = $MarginContainer/Content/NameInput
@onready var error_label: Label = $MarginContainer/Content/ErrorLabel
@onready var confirm_button: Button = $MarginContainer/Content/ConfirmButton
@onready var back_button: Button = $MarginContainer/Content/BackButton
@onready var header_label: Label = $MarginContainer/Content/HeaderLabel


func _ready() -> void:
	# Restores existing data when renaming and wires the input flow.
	GameThemeScript.apply_to(self)
	AudioManager.play_main_music()
	GameThemeScript.apply_display_font(header_label, 44)
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	name_input.text = GameState.king_name
	_style_buttons()
	name_input.grab_focus()


func _on_name_submitted(_submitted_text: String) -> void:
	# Enter key should behave the same as tapping confirm.
	_commit_name()


func _on_confirm_pressed() -> void:
	_commit_name()


func _on_back_pressed() -> void:
	SceneRouter.go_to(TITLE_SCENE)


func _commit_name() -> void:
	# Enforces a minimal valid name and creates the starter profile.
	var candidate := name_input.text.strip_edges()
	if candidate.length() < 2:
		error_label.text = "Use at least 2 characters for the King's name."
		return

	var is_first_profile := not GameState.has_king_name()
	if is_first_profile:
		CurrencyManager.initialize_new_profile()
		UpgradeManager.reset_progress()
		CombatManager.reset_progress()

	GameState.set_king_name(candidate)
	error_label.text = ""
	SceneRouter.go_to(MAIN_GAME_SCENE)


func _style_buttons() -> void:
	# Reuses the packaged UI button textures so Phase 0 already matches the game tone.
	var normal_style := UiAtlasScript.stylebox_from_ui(1, 0, 2, 2, 8, Color("6c3d13"), Vector4(18, 12, 18, 12))
	var pressed_style := UiAtlasScript.stylebox_from_ui(1, 0, 2, 2, 8, Color("91531b"), Vector4(18, 12, 18, 12))

	for button in [confirm_button, back_button]:
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", normal_style)
		button.add_theme_stylebox_override("pressed", pressed_style)
