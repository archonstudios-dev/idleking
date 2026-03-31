# Shows the studio branding page before the title screen with a clean full-screen reveal.
extends Control

const GameThemeScript := preload("res://Scripts/UI/GameTheme.gd")
const TITLE_SCENE := "res://Scenes/Bootstrap/TitleScreen.tscn"
const BRANDING_IMAGE_PATH := "res://Assets/studioBranding/logo-orange-portrait.png"
const AUTO_ADVANCE_DELAY := 2.2
const FADE_DURATION := 0.35

@onready var branding_image: TextureRect = $BrandingImage
@onready var fade_overlay: ColorRect = $FadeOverlay

var _has_started_transition: bool = false


func _ready() -> void:
	# Displays the branding art full-screen in its native portrait composition.
	GameThemeScript.apply_to(self)
	branding_image.texture = _load_texture_from_image_file(BRANDING_IMAGE_PATH)
	branding_image.modulate.a = 0.0
	fade_overlay.color.a = 1.0
	AudioManager.play_branding()
	_play_intro()
	get_tree().create_timer(AUTO_ADVANCE_DELAY).timeout.connect(_go_to_title)


func _unhandled_input(event: InputEvent) -> void:
	# Lets the player skip the intro with a tap or confirm action.
	if event is InputEventScreenTouch and event.pressed:
		_go_to_title()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_go_to_title()


func _go_to_title() -> void:
	if _has_started_transition:
		return

	_has_started_transition = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(branding_image, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_property(fade_overlay, "color:a", 1.0, FADE_DURATION)
	tween.finished.connect(func() -> void:
		SceneRouter.go_to(TITLE_SCENE)
	)


func _play_intro() -> void:
	# Uses a simple fade so the splash feels polished without adding UI clutter.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.5)
	tween.tween_property(branding_image, "modulate:a", 1.0, 0.5)


func _load_texture_from_image_file(path: String) -> Texture2D:
	# Prefers imported textures for export safety and only falls back to raw image loading if needed.
	if ResourceLoader.exists(path):
		var imported := load(path) as Texture2D
		if imported != null:
			return imported

	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_warning("Unable to load branding image at %s." % path)
		return null

	return ImageTexture.create_from_image(image)
