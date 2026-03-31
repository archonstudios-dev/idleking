extends CharacterBody2D
class_name IdleKingCharacter

signal health_changed(current: int, max_value: int)
signal defeated(character: IdleKingCharacter)
signal attack_started(character: IdleKingCharacter, animation_name: String)
signal attack_landed(character: IdleKingCharacter, damage: int, victim: IdleKingCharacter)

const SPEED := 200.0
const GRAVITY := 1600.0
const ACCELERATION := 1800.0
const ATTACK_WINDUP_RATIO := 0.42
const ATTACK_RECOVERY_RATIO := 0.82

@export var max_health: int = 120
@export var move_speed: float = SPEED
@export var gravity: float = GRAVITY
@export var acceleration: float = ACCELERATION
@export var attack_range: float = 76.0
@export var attack_damage: int = 14
@export var attack_cooldown: float = 0.95
@export var sprite_faces_right: bool = true
@export var attack_area_distance: float = 54.0
@export var attack_area_size: Vector2 = Vector2(84.0, 46.0)
@export var attack_area_y: float = -34.0
@export var sprite_offset: Vector2 = Vector2(0.0, -56.0)
@export var sprite_base_scale: Vector2 = Vector2(2.2, 2.2)
@export var hit_stun_duration: float = 0.18
@export var corpse_lifetime: float = 0.9
@export var patrol_radius: float = 96.0
@export var aggro_range: float = 340.0

var health: int = 0
var facing: float = 1.0
var current_animation: String = "idle"
var animation_time: float = 0.0
var current_attack_animation: String = "attack"
var is_dead: bool = false

var _desired_velocity_x: float = 0.0
var _attack_cooldown_remaining: float = 0.0
var _attack_state_time: float = 0.0
var _attack_has_landed: bool = false
var _hit_stun_remaining: float = 0.0
var _death_timer: float = -1.0
var _patrol_center: Vector2 = Vector2.ZERO
var _patrol_target: Vector2 = Vector2.ZERO
var _patrol_wait_remaining: float = 0.0
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _animations: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D


func _ready() -> void:
	_random.randomize()
	health = max_health
	health_changed.emit(health, max_health)
	_patrol_center = global_position
	_patrol_target = global_position
	_configure_attack_shape()
	_animations = _build_animations()
	_set_animation("idle", true)
	_apply_visual_direction()
	_update_attack_area_position()


func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		_update_animation(delta)
		return

	_desired_velocity_x = 0.0
	_process_behavior(delta)
	_apply_horizontal_motion(delta)
	_apply_vertical_motion(delta)
	move_and_slide()
	_post_move_update()
	_update_animation(delta)


func _process_behavior(_delta: float) -> void:
	pass


func _build_animations() -> Dictionary:
	return {}


func get_target_groups() -> Array[StringName]:
	return []


func get_team_group() -> StringName:
	return &""


func take_damage(amount: int, attacker: IdleKingCharacter = null) -> void:
	if is_dead:
		return

	health = max(0, health - max(1, amount))
	health_changed.emit(health, max_health)
	if attacker != null:
		var delta_x: float = global_position.x - attacker.global_position.x
		if absf(delta_x) > 0.01:
			facing = 1.0 if delta_x >= 0.0 else -1.0
			_apply_visual_direction()

	if health <= 0:
		_die()
		return

	_attack_state_time = 0.0
	_attack_has_landed = true
	_hit_stun_remaining = hit_stun_duration
	_set_animation("hit", true)


func request_attack() -> bool:
	if is_dead or _attack_cooldown_remaining > 0.0 or _hit_stun_remaining > 0.0:
		return false

	current_attack_animation = _get_next_attack_animation()
	_attack_state_time = 0.0
	_attack_has_landed = false
	_attack_cooldown_remaining = attack_cooldown
	velocity.x = 0.0
	_set_animation(current_attack_animation, true)
	attack_started.emit(self, current_attack_animation)
	return true


func get_primary_target() -> IdleKingCharacter:
	var target_groups: Array[StringName] = get_target_groups()
	var best_target: IdleKingCharacter = null
	var best_distance: float = INF

	for group_name in target_groups:
		for node in get_tree().get_nodes_in_group(group_name):
			var candidate: IdleKingCharacter = node as IdleKingCharacter
			if candidate == null or candidate == self or candidate.is_dead:
				continue
			var distance_to_candidate: float = global_position.distance_to(candidate.global_position)
			if distance_to_candidate < best_distance:
				best_distance = distance_to_candidate
				best_target = candidate

	return best_target


func get_neighbor_push(radius: float) -> float:
	var push: float = 0.0
	var team_group: StringName = get_team_group()
	if team_group == StringName():
		return 0.0

	for node in get_tree().get_nodes_in_group(team_group):
		var ally: IdleKingCharacter = node as IdleKingCharacter
		if ally == null or ally == self or ally.is_dead:
			continue
		var delta_x: float = global_position.x - ally.global_position.x
		var distance_x: float = absf(delta_x)
		if distance_x <= 0.01 or distance_x > radius:
			continue
		push += sign(delta_x) * ((radius - distance_x) / radius)

	return clampf(push, -1.0, 1.0)


func begin_patrol_wait(duration: float) -> void:
	_patrol_wait_remaining = maxf(duration, 0.0)


func choose_patrol_target(center: Vector2 = Vector2.ZERO) -> void:
	var patrol_center: Vector2 = _patrol_center if center == Vector2.ZERO else center
	_patrol_target = patrol_center + Vector2(_random.randf_range(-patrol_radius, patrol_radius), 0.0)


func get_patrol_target() -> Vector2:
	return _patrol_target


func can_attack_target(target: IdleKingCharacter) -> bool:
	if target == null or target.is_dead:
		return false
	return absf(target.global_position.x - global_position.x) <= attack_range


func face_target(target: IdleKingCharacter) -> void:
	if target == null:
		return
	var delta_x: float = target.global_position.x - global_position.x
	if absf(delta_x) <= 0.01:
		return
	facing = 1.0 if delta_x >= 0.0 else -1.0
	_apply_visual_direction()


func _get_next_attack_animation() -> String:
	return "attack"


func _tick_timers(delta: float) -> void:
	_attack_cooldown_remaining = maxf(0.0, _attack_cooldown_remaining - delta)
	_patrol_wait_remaining = maxf(0.0, _patrol_wait_remaining - delta)

	if _hit_stun_remaining > 0.0:
		_hit_stun_remaining = maxf(0.0, _hit_stun_remaining - delta)
		if _hit_stun_remaining == 0.0 and not is_dead:
			_set_animation("idle", true)

	if is_dead and _death_timer >= 0.0:
		_death_timer = maxf(0.0, _death_timer - delta)
		if _death_timer == 0.0:
			queue_free()

	if _is_attack_animation(current_animation):
		_attack_state_time += delta
		_process_attack_timing()


func _process_attack_timing() -> void:
	var anim: Dictionary = _animations.get(current_attack_animation, {})
	if anim.is_empty():
		return

	var frames: int = int(anim.get("frames", 1))
	var fps: float = float(anim.get("fps", 8.0))
	if frames <= 0 or fps <= 0.0:
		return

	var duration: float = float(frames) / fps
	var impact_time: float = duration * ATTACK_WINDUP_RATIO
	if not _attack_has_landed and _attack_state_time >= impact_time:
		_attack_has_landed = true
		_land_attack()
	if _attack_state_time >= duration:
		_attack_state_time = 0.0
		_attack_has_landed = true


func _land_attack() -> void:
	_update_attack_area_position()
	for body in attack_area.get_overlapping_bodies():
		var target: IdleKingCharacter = body as IdleKingCharacter
		if target == null or target == self or target.is_dead:
			continue
		if not _is_valid_attack_target(target):
			continue
		target.take_damage(attack_damage, self)
		attack_landed.emit(self, attack_damage, target)
		break


func _is_valid_attack_target(target: IdleKingCharacter) -> bool:
	for group_name in get_target_groups():
		if target.is_in_group(group_name):
			return true
	return false


func _apply_horizontal_motion(delta: float) -> void:
	velocity.x = move_toward(velocity.x, _desired_velocity_x, acceleration * delta)


func _apply_vertical_motion(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)


func _post_move_update() -> void:
	if absf(velocity.x) > 0.01:
		facing = 1.0 if velocity.x >= 0.0 else -1.0
	_apply_visual_direction()
	_update_attack_area_position()


func _update_animation(delta: float) -> void:
	if _animations.is_empty():
		return

	var next_animation: String = _resolve_animation_state()
	if current_animation != next_animation:
		_set_animation(next_animation)

	var anim: Dictionary = _animations.get(current_animation, {})
	if anim.is_empty():
		return

	var frame_count: int = int(anim.get("frames", 1))
	var fps: float = float(anim.get("fps", 8.0))
	var looping: bool = bool(anim.get("loop", true))
	if frame_count <= 0 or fps <= 0.0:
		return

	animation_time += delta
	var frame: int = mini(int(animation_time * fps), frame_count - 1)
	if looping:
		frame = int(animation_time * fps) % frame_count

	sprite.frame = frame


func _resolve_animation_state() -> String:
	if is_dead:
		return "death"
	if _hit_stun_remaining > 0.0 and _animations.has("hit"):
		return "hit"
	if _is_attack_animation(current_attack_animation) and _attack_state_time > 0.0:
		return current_attack_animation
	if not is_on_floor():
		if velocity.y < 0.0 and _animations.has("jump"):
			return "jump"
		if _animations.has("fall"):
			return "fall"
	if absf(velocity.x) > 20.0 and _animations.has("run"):
		return "run"
	return "idle"


func _set_animation(name: String, force: bool = false) -> void:
	if not force and current_animation == name:
		return
	if not _animations.has(name):
		return

	current_animation = name
	animation_time = 0.0
	var anim: Dictionary = _animations[name]
	var texture: Texture2D = anim.get("texture") as Texture2D
	var frames: int = int(anim.get("frames", 1))
	if texture == null:
		return

	sprite.texture = texture
	sprite.hframes = max(1, frames)
	sprite.vframes = 1
	sprite.frame = 0
	sprite.position = sprite_offset
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_visual_direction()


func _apply_visual_direction() -> void:
	if sprite == null:
		return
	var visual_direction: float = facing if sprite_faces_right else -facing
	sprite.scale.x = absf(sprite_base_scale.x) * visual_direction
	sprite.scale.y = sprite_base_scale.y


func _update_attack_area_position() -> void:
	if attack_area == null:
		return
	attack_area.position = Vector2(attack_area_distance * facing, attack_area_y)


func _configure_attack_shape() -> void:
	if attack_shape == null:
		return
	var shape: RectangleShape2D = attack_shape.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		attack_shape.shape = shape
	shape.size = attack_area_size


func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	_hit_stun_remaining = 0.0
	_attack_state_time = 0.0
	_attack_has_landed = true
	_death_timer = corpse_lifetime
	_set_animation("death", true)
	health_changed.emit(0, max_health)
	defeated.emit(self)


func _is_attack_animation(name: String) -> bool:
	return name.begins_with("attack")
