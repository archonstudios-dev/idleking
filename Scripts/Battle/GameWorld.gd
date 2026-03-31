extends Node2D
class_name GameWorld

signal hero_health_changed(ratio: float)
signal enemy_health_changed(ratio: float)
signal wave_changed(wave: int, enemy_name: String)

const CharacterScene := preload("res://Scenes/Battle/Character.tscn")

const VIEW_SIZE := Vector2(896.0, 448.0)
const WORLD_BOUNDS := Rect2(72.0, 0.0, 752.0, 448.0)
const HERO_SPAWN_X := 124.0
const ENEMY_SPAWN_X := 772.0
const GROUND_RATIO := 1350.0 / 1920.0
const GROUND_Y_NUDGE := -14.0
const HERO_FEET_OFFSET := -6.0
const ENEMY_FEET_OFFSET := -34.0

@onready var heroes: Node2D = $Heroes
@onready var enemies: Node2D = $Enemies
@onready var camera: Camera2D = $Camera2D
@onready var combat_bridge: Node = $CombatBridge

var hero
var enemy
var ground_y: float = 0.0
var _combat_manager: Node
var _active_enemy_wave: int = -1
var _feedback_layer: CanvasLayer
var _damage_container: Control
var _hit_audio_player: AudioStreamPlayer
var _camera_shake_token: int = 0
var _hit_stop_active: bool = false


func _ready() -> void:
	ground_y = (VIEW_SIZE.y * GROUND_RATIO) + GROUND_Y_NUDGE
	_combat_manager = get_node_or_null("/root/CombatManager")
	_setup_world()
	_spawn_hero_visual()

	if _combat_manager != null:
		combat_bridge.setup(self, _combat_manager)
		if not _combat_manager.is_connected("combat_state_changed", Callable(self, "_on_combat_state_changed")):
			_combat_manager.connect("combat_state_changed", Callable(self, "_on_combat_state_changed"))
		if not _combat_manager.is_connected("combat_entry_delay_changed", Callable(self, "_on_combat_entry_delay_changed")):
			_combat_manager.connect("combat_entry_delay_changed", Callable(self, "_on_combat_entry_delay_changed"))
		var initial_state: Dictionary = _combat_manager.call("get_state")
		refresh_from_combat_state(initial_state)
		_on_combat_entry_delay_changed(bool(_combat_manager.call("is_combat_entry_delay_active")))


func refresh_from_combat_state(state: Dictionary) -> void:
	if hero == null or not is_instance_valid(hero) or bool(hero.is_dead):
		if hero != null and is_instance_valid(hero):
			hero.queue_free()
			hero = null
		_spawn_hero_visual()

	if _combat_manager == null:
		return

	_sync_hero_from_state(state)
	_sync_enemy_from_state(state)
	_emit_state(state)
	combat_bridge.set_combatants(hero, enemy)


func _setup_world() -> void:
	camera.position = VIEW_SIZE * 0.5
	_feedback_layer = CanvasLayer.new()
	_feedback_layer.name = "FeedbackLayer"
	add_child(_feedback_layer)

	_damage_container = Control.new()
	_damage_container.name = "DamageContainer"
	_damage_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback_layer.add_child(_damage_container)

	_hit_audio_player = AudioStreamPlayer.new()
	_hit_audio_player.name = "HitAudioPlayer"
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("get_hit_stream"):
		_hit_audio_player.stream = audio_manager.call("get_hit_stream")
	add_child(_hit_audio_player)


func _spawn_hero_visual() -> void:
	if hero != null and is_instance_valid(hero):
		hero.queue_free()
		hero = null

	var instance = CharacterScene.instantiate()
	instance.name = "Hero"
	instance.profile = "hero"
	instance.team_group = &"heroes"
	instance.target_group = &"enemies"
	instance.max_health = 100
	instance.move_speed = 88.0
	instance.attack_range = 148.0
	instance.hitbox_range = 154.0
	instance.sprite_faces_right = true
	instance.sprite_offset = Vector2(0.0, -61.0)
	instance.scale = Vector2.ONE
	heroes.add_child(instance)
	instance.global_position = Vector2(HERO_SPAWN_X, ground_y - HERO_FEET_OFFSET)
	instance.z_as_relative = false

	instance.set_world_bounds(WORLD_BOUNDS)
	instance.set_ground_y(ground_y - HERO_FEET_OFFSET)
	instance.set_can_move(false)
	hero = instance


func _spawn_enemy_visual(state: Dictionary) -> void:
	if enemy != null and is_instance_valid(enemy):
		enemy.queue_free()
		enemy = null

	if int(state.get("enemy_current_hp", 0)) <= 0:
		_active_enemy_wave = -1
		return

	var instance = CharacterScene.instantiate()
	instance.name = "Enemy"
	instance.profile = "enemy"
	instance.team_group = &"enemies"
	instance.target_group = &"heroes"
	instance.max_health = max(1, int(state.get("enemy_max_hp", 1)))
	instance.move_speed = 84.0 if not bool(state.get("enemy_is_boss", false)) else 72.0
	instance.attack_range = 148.0
	instance.hitbox_range = 154.0
	instance.sprite_faces_right = true
	instance.sprite_offset = Vector2(0.0, -63.0)
	instance.scale = Vector2.ONE
	enemies.add_child(instance)
	instance.global_position = Vector2(ENEMY_SPAWN_X, ground_y - ENEMY_FEET_OFFSET)
	instance.z_as_relative = false

	instance.set_world_bounds(WORLD_BOUNDS)
	instance.set_ground_y(ground_y - ENEMY_FEET_OFFSET)
	instance.set_can_move(false)
	instance.sync_health(int(state.get("enemy_current_hp", 0)), int(state.get("enemy_max_hp", 1)))
	enemy = instance
	_active_enemy_wave = int(state.get("wave", -1))


func _sync_hero_from_state(state: Dictionary) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	hero.sync_health(int(state.get("king_current_hp", 0)), int(state.get("king_max_hp", 1)))


func _sync_enemy_from_state(state: Dictionary) -> void:
	var state_wave: int = int(state.get("wave", -1))
	var enemy_hp: int = int(state.get("enemy_current_hp", 0))

	if enemy_hp <= 0:
		return

	if enemy == null or not is_instance_valid(enemy) or state_wave != _active_enemy_wave:
		_spawn_enemy_visual(state)
		return

	enemy.sync_health(enemy_hp, int(state.get("enemy_max_hp", 1)))


func _emit_state(state: Dictionary) -> void:
	var king_max_hp: int = max(1, int(state.get("king_max_hp", 1)))
	var enemy_max_hp: int = max(1, int(state.get("enemy_max_hp", 1)))
	hero_health_changed.emit(float(int(state.get("king_current_hp", 0))) / float(king_max_hp))
	enemy_health_changed.emit(float(int(state.get("enemy_current_hp", 0))) / float(enemy_max_hp))
	wave_changed.emit(int(state.get("wave", 1)), String(state.get("enemy_name", "Enemy")))


func _on_combat_state_changed(state: Dictionary) -> void:
	refresh_from_combat_state(state)


func _on_combat_entry_delay_changed(active: bool) -> void:
	var can_move_now: bool = not active
	if hero != null and is_instance_valid(hero):
		hero.set_can_move(can_move_now)
	if enemy != null and is_instance_valid(enemy):
		enemy.set_can_move(can_move_now)


func apply_hit_feedback(amount: int, world_position: Vector2) -> void:
	spawn_damage_number(amount, world_position)
	apply_camera_shake()
	_apply_hit_stop()
	_play_hit_sound()


func spawn_damage_number(amount: int, world_position: Vector2) -> void:
	if _damage_container == null:
		return

	var label := Label.new()
	label.text = str(amount)
	label.position = world_position + Vector2(-10.0, -46.0)
	label.top_level = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.28))
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.02, 0.02))
	label.add_theme_constant_override("outline_size", 2)
	_damage_container.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	await tween.finished
	label.queue_free()


func apply_camera_shake() -> void:
	if camera == null:
		return

	_camera_shake_token += 1
	var shake_token: int = _camera_shake_token
	camera.offset = Vector2(randf_range(-10.0, 10.0), randf_range(-7.0, 7.0))
	await _wait_unscaled(0.14)
	if camera != null and shake_token == _camera_shake_token:
		camera.offset = Vector2.ZERO


func _apply_hit_stop() -> void:
	if _hit_stop_active:
		return

	_hit_stop_active = true
	var previous_time_scale: float = Engine.time_scale
	Engine.time_scale = 0.05
	await _wait_unscaled(0.05)
	Engine.time_scale = previous_time_scale
	_hit_stop_active = false


func _play_hit_sound() -> void:
	if _hit_audio_player == null or _hit_audio_player.stream == null:
		return
	_hit_audio_player.stop()
	_hit_audio_player.play()


func _wait_unscaled(duration: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = duration
	timer.ignore_time_scale = true
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()
