extends CharacterBody2D
class_name Character

signal health_changed(current: int, max_value: int)
signal attack_hit(character: Character)
signal died(character: Character)

enum CombatState {
	IDLE,
	CHASE,
	ATTACK,
}

const ACCELERATION := 1200.0
const HIT_STUN_TIME := 0.16
const DEATH_HOLD_TIME := 0.8
const ATTACK_IMPACT_RATIO := 0.45
const ATTACK_IMPACT_VARIANCE := 0.10
const KNOCKBACK_SPEED := 40.0
const KNOCKBACK_BURST_DECAY := 120.0
const KNOCKBACK_RECOVERY_DECAY := 760.0
const KNOCKBACK_BURST_PHASE_RATIO := 0.34
const KNOCKBACK_OVERRIDE_TIME := 0.26
const KNOCKBACK_FRICTION := 900.0
const ATTACK_RANGE_FRICTION := 1800.0
const SOFT_TETHER_EXTRA_RANGE := 36.0
const SOFT_TETHER_PULL := 280.0
const SOFT_CENTER_PULL := 26.0
const CENTER_PULL_ACCELERATION := 140.0
const HITBOX_Y_TOLERANCE := 40.0
const HIT_FLASH_COLOR := Color(1.45, 1.2, 1.2, 1.0)
const HIT_FLASH_DURATION := 0.06
const BACKSTEP_SPEED_FACTOR := 0.34
const BACKSTEP_DISTANCE := 28.0
const DAMAGE_FORCE_SCALE := 0.95
const RECOIL_FORCE_FACTOR := 0.72
const MIN_IMPACT_FORCE := 26.0
const MAX_IMPACT_FORCE := 72.0
const IMPACT_VARIATION_MIN := 0.9
const IMPACT_VARIATION_MAX := 1.1
const EDGE_RESISTANCE_DISTANCE := 120.0
const EDGE_RESISTANCE_MIN_FACTOR := 0.4
const LOW_HP_KNOCKBACK_RESISTANCE := 0.72
const COMEBACK_HEALTH_THRESHOLD := 0.20
const COMEBACK_RESISTANCE_FACTOR := 0.65
const RECOVERY_FLOOR := 0.12
const RECOVERY_WINDOW := 0.26
const RECOIL_RECOVERY_WINDOW := 0.22
const LANE_CORRECTION_DELAY := 0.12
const REENGAGE_BOOST_TIME := 0.22
const REENGAGE_SPEED_MULTIPLIER := 1.16

const HERO_ANIMATIONS := {
	"idle": {"texture": preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Idle.png"), "frames": 8, "fps": 8.0},
	"run": {"texture": preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Run.png"), "frames": 8, "fps": 12.0},
	"jump": {"texture": preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Jump.png"), "frames": 2, "fps": 7.0},
	"attack": {"texture": preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Attack2.png"), "frames": 4, "fps": 12.0},
	"hit": {"texture": preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Take Hit.png"), "frames": 4, "fps": 12.0},
	"death": {"texture": preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Death.png"), "frames": 6, "fps": 9.0}
}

const ENEMY_ANIMATIONS := {
	"idle": {"texture": preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Idle.png"), "frames": 8, "fps": 8.0},
	"run": {"texture": preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Run.png"), "frames": 8, "fps": 12.0},
	"jump": {"texture": preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Jump.png"), "frames": 2, "fps": 7.0},
	"attack": {"texture": preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Attack1.png"), "frames": 8, "fps": 12.0},
	"hit": {"texture": preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Take hit.png"), "frames": 3, "fps": 12.0},
	"death": {"texture": preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Death.png"), "frames": 7, "fps": 9.0}
}

@export_enum("hero", "enemy") var profile: String = "hero"
@export var team_group: StringName = &"heroes"
@export var target_group: StringName = &"enemies"
@export var max_health: int = 100
@export var move_speed: float = 84.0
@export var attack_range: float = 46.0
@export var hitbox_range: float = 52.0
@export var sprite_faces_right: bool = true
@export var sprite_offset: Vector2 = Vector2(0.0, -32.0)
@export var feet_offset: float = 0.0
@export var detection_radius: float = 320.0

var current_health: int = 0
var is_dead: bool = false
var can_move: bool = true

var _world_bounds: Rect2 = Rect2(0.0, 0.0, 512.0, 256.0)
var _ground_y: float = 0.0
var _base_scale: Vector2 = Vector2.ONE
var _animations: Dictionary = {}
var _current_animation: String = "idle"
var _animation_time: float = 0.0
var _facing: float = 1.0
var _hit_time_remaining: float = 0.0
var _death_time_remaining: float = 0.0
var _attack_time: float = 0.0
var _attack_hit_emitted: bool = false
var _is_attacking: bool = false
var _attack_requested: bool = false
var _queued_attack: bool = false
var _knockback_velocity_x: float = 0.0
var _knockback_time_remaining: float = 0.0
var _lane_correction_delay_remaining: float = 0.0
var _reengage_time_remaining: float = 0.0
var _recovery_time_remaining: float = 0.0
var _state: CombatState = CombatState.IDLE
var _nearby_targets: Array[Character] = []
var _target: Character
var _flash_token: int = 0
var _attack_impact_ratio_current: float = ATTACK_IMPACT_RATIO
var _attack_sequence: Array[String] = []
var _attack_sequence_index: int = 0
var _active_attack_animation: String = "attack"

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D


func _ready() -> void:
	add_to_group(team_group)
	scale = Vector2.ONE
	z_as_relative = false
	z_index = 0
	current_health = max_health
	_animations = HERO_ANIMATIONS if profile == "hero" else ENEMY_ANIMATIONS
	_attack_sequence = ["attack"]
	_base_scale = sprite.scale
	_ground_y = global_position.y
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	sprite.position = sprite_offset
	sprite.z_as_relative = false
	sprite.z_index = 0
	_configure_detection_area()
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	_set_animation("idle", true)
	_apply_facing()
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	_update_knockback(delta)
	_lane_correction_delay_remaining = maxf(0.0, _lane_correction_delay_remaining - delta)
	_reengage_time_remaining = maxf(0.0, _reengage_time_remaining - delta)
	_recovery_time_remaining = maxf(0.0, _recovery_time_remaining - delta)

	if is_dead:
		_process_death(delta)
		return

	_hit_time_remaining = maxf(0.0, _hit_time_remaining - delta)

	if not can_move:
		velocity.x = 0.0
		_state = CombatState.IDLE
	elif _knockback_time_remaining > 0.0:
		_process_knockback(delta)
	elif _is_attacking:
		_process_attack(delta)
	else:
		_process_state_machine(delta)

	_apply_grounded_motion()
	_resolve_animation()
	_update_animation(delta)


func set_world_bounds(bounds: Rect2) -> void:
	_world_bounds = bounds


func set_ground_y(value: float) -> void:
	_ground_y = value
	_lock_to_ground()


func set_can_move(value: bool) -> void:
	can_move = value
	if not can_move:
		velocity.x = 0.0


func sync_health(current: int, max_value: int) -> void:
	max_health = max(1, max_value)
	current_health = clampi(current, 0, max_health)
	health_changed.emit(current_health, max_health)


func get_health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)


func request_attack() -> void:
	if not is_dead:
		_attack_requested = true


func clear_attack_request() -> void:
	_attack_requested = false
	_queued_attack = false


func set_target(value: Character) -> void:
	_target = value


func play_attack_animation() -> bool:
	if _is_attacking and _attack_time >= _get_attack_duration():
		_is_attacking = false
		_attack_time = 0.0
		_attack_hit_emitted = false

	if is_dead:
		return false
	if _hit_time_remaining > 0.0 or _recovery_time_remaining > 0.0 or _is_attacking:
		_queued_attack = true
		return false

	if _target != null and is_instance_valid(_target) and not _target.is_dead:
		var dx: float = _target.global_position.x - global_position.x
		if absf(dx) > 4.0:
			_facing = sign(dx)
			_apply_facing()

	_attack_requested = false
	_queued_attack = false
	_is_attacking = true
	_attack_time = 0.0
	_attack_hit_emitted = false
	_attack_impact_ratio_current = ATTACK_IMPACT_RATIO * _rand_variance(ATTACK_IMPACT_VARIANCE)
	_active_attack_animation = _attack_sequence[_attack_sequence_index % _attack_sequence.size()]
	_attack_sequence_index += 1
	_state = CombatState.ATTACK
	velocity.x = 0.0
	_set_animation(_active_attack_animation, true)
	return true


func is_target_in_range(target: Character) -> bool:
	if target == null or target.is_dead:
		return false
	var distance_x: float = absf(target.global_position.x - global_position.x)
	var distance_y: float = absf(target.global_position.y - global_position.y)
	return distance_x <= hitbox_range and distance_y <= HITBOX_Y_TOLERANCE


func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO, impact_bias: float = 1.0) -> void:
	if is_dead:
		return

	current_health = maxi(0, current_health - maxi(1, amount))
	health_changed.emit(current_health, max_health)

	var direction_from_attacker: float = sign(global_position.x - attacker_pos.x)
	if is_zero_approx(direction_from_attacker):
		direction_from_attacker = -_facing if not is_zero_approx(_facing) else 1.0
	_apply_directional_force(direction_from_attacker, amount, impact_bias)
	_play_hit_flash()
	_enter_recovery(RECOVERY_WINDOW)

	if current_health <= 0:
		_die()
		return

	if _is_attacking:
		return

	_hit_time_remaining = HIT_STUN_TIME
	velocity.x = 0.0
	_set_animation("hit", true)


func _process_state_machine(delta: float) -> void:
	if _hit_time_remaining > 0.0:
		_state = CombatState.IDLE
		velocity.x = move_toward(velocity.x, 0.0, ACCELERATION * delta)
		return
	if _recovery_time_remaining > 0.0:
		# Brief shared recovery keeps exchanges readable and prevents instant re-attacks.
		_state = CombatState.IDLE
		velocity.x = move_toward(velocity.x, 0.0, ACCELERATION * delta)
		return

	var target: Character = _get_closest_target()
	if target == null:
		_state = CombatState.IDLE
		velocity.x = move_toward(velocity.x, 0.0, ACCELERATION * delta)
		return

	var distance_x: float = target.global_position.x - global_position.x
	var abs_distance_x: float = absf(distance_x)
	var effective_move_speed: float = move_speed * (REENGAGE_SPEED_MULTIPLIER if _reengage_time_remaining > 0.0 else 1.0)

	_update_facing_to_target(target)

	var retreat_distance: float = maxf(BACKSTEP_DISTANCE, attack_range * 0.45)

	if _queued_attack and is_target_in_range(target):
		_state = CombatState.ATTACK
		velocity.x = move_toward(velocity.x, 0.0, ATTACK_RANGE_FRICTION * delta)
		play_attack_animation()
		return

	if _attack_requested:
		if is_target_in_range(target):
			_state = CombatState.ATTACK
			velocity.x = move_toward(velocity.x, 0.0, ATTACK_RANGE_FRICTION * delta)
			play_attack_animation()
			return

		if abs_distance_x < retreat_distance:
			_state = CombatState.CHASE
			var retreat_velocity_x: float = -sign(distance_x) * effective_move_speed * BACKSTEP_SPEED_FACTOR
			velocity.x = move_toward(velocity.x, retreat_velocity_x, ACCELERATION * delta)
			return

		_state = CombatState.CHASE
		var chase_velocity_x: float = sign(distance_x) * effective_move_speed
		velocity.x = move_toward(velocity.x, chase_velocity_x, ACCELERATION * delta)
		return

	if abs_distance_x < retreat_distance:
		_state = CombatState.CHASE
		var backstep_velocity_x: float = -sign(distance_x) * effective_move_speed * BACKSTEP_SPEED_FACTOR
		velocity.x = move_toward(velocity.x, backstep_velocity_x, ACCELERATION * delta)
		return

	if abs_distance_x <= attack_range:
		_state = CombatState.IDLE
		velocity.x = move_toward(velocity.x, 0.0, ATTACK_RANGE_FRICTION * delta)
		return

	_state = CombatState.CHASE
	var desired_velocity_x: float = sign(distance_x) * effective_move_speed
	velocity.x = move_toward(velocity.x, desired_velocity_x, ACCELERATION * delta)


func _process_attack(delta: float) -> void:
	_update_facing_to_target(_target)
	velocity.x = move_toward(velocity.x, 0.0, ATTACK_RANGE_FRICTION * delta)
	_attack_time += delta

	var duration: float = _get_attack_duration()
	var impact_time: float = duration * _attack_impact_ratio_current

	if not _attack_hit_emitted and _attack_time >= impact_time:
		_attack_hit_emitted = true
		attack_hit.emit(self)

	if _attack_time >= duration:
		_is_attacking = false
		_attack_requested = false
		_attack_time = 0.0
		if _queued_attack and _target != null and is_instance_valid(_target) and not _target.is_dead and can_move and _hit_time_remaining <= 0.0 and is_target_in_range(_target):
			play_attack_animation()
			return
		_state = CombatState.IDLE
		_set_animation("idle", true)


func _process_knockback(delta: float) -> void:
	_state = CombatState.IDLE
	velocity.x = move_toward(velocity.x, 0.0, KNOCKBACK_FRICTION * delta)
	_update_facing_to_target(_target)


func _get_attack_duration() -> float:
	var animation: Dictionary = _animations.get(_active_attack_animation, {})
	if animation.is_empty():
		return 0.0
	var frame_count: int = int(animation["frames"])
	var fps: float = maxf(0.001, float(animation["fps"]))
	return float(frame_count) / fps


func _process_death(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ACCELERATION * delta)
	_apply_grounded_motion()
	_update_animation(delta)
	_death_time_remaining = maxf(0.0, _death_time_remaining - delta)
	if _death_time_remaining == 0.0:
		died.emit(self)
		queue_free()


func _get_closest_target() -> Character:
	if _target != null and is_instance_valid(_target) and not _target.is_dead:
		return _target

	var nearest: Character = null
	var nearest_distance_squared: float = INF

	for index in range(_nearby_targets.size() - 1, -1, -1):
		var candidate: Character = _nearby_targets[index]
		if candidate == null or not is_instance_valid(candidate) or candidate.is_dead:
			_nearby_targets.remove_at(index)
			continue

		var distance_squared: float = global_position.distance_squared_to(candidate.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest = candidate

	return nearest


func _resolve_animation() -> void:
	if is_dead:
		_set_animation("death")
		return
	if _hit_time_remaining > 0.0:
		_set_animation("hit")
		return
	if _is_attacking:
		_set_animation(_active_attack_animation)
		return
	if absf(velocity.x) > 6.0:
		_set_animation("run")
		return
	_set_animation("idle")


func _update_animation(delta: float) -> void:
	var animation: Dictionary = _animations.get(_current_animation, {})
	if animation.is_empty():
		return

	_animation_time += delta
	var frame_count: int = int(animation["frames"])
	var fps: float = float(animation["fps"])
	var frame: int = mini(int(_animation_time * fps), frame_count - 1)

	if _current_animation == "idle" or _current_animation == "run":
		frame = int(_animation_time * fps) % frame_count

	sprite.frame = frame
	_apply_facing()

	if _current_animation == "hit" and frame == frame_count - 1 and _hit_time_remaining == 0.0:
		_set_animation("idle", true)
	elif _current_animation == "attack" and not _is_attacking:
		_set_animation("idle", true)


func _set_animation(animation_name: String, force: bool = false) -> void:
	if not force and _current_animation == animation_name:
		return
	if not _animations.has(animation_name):
		return

	_current_animation = animation_name
	_animation_time = 0.0

	var animation: Dictionary = _animations[animation_name]
	sprite.texture = animation["texture"] as Texture2D
	sprite.hframes = int(animation["frames"])
	sprite.vframes = 1
	sprite.frame = 0
	sprite.position = sprite_offset


func _apply_facing() -> void:
	sprite.scale = _base_scale
	sprite.flip_h = _facing < 0.0


func _update_facing_to_target(target: Character) -> void:
	if target == null or not is_instance_valid(target) or target.is_dead:
		return
	var dx: float = target.global_position.x - global_position.x
	if absf(dx) <= 4.0:
		return
	_facing = sign(dx)
	_apply_facing()


func _clamp_to_world() -> void:
	global_position.x = clampf(global_position.x, _world_bounds.position.x, _world_bounds.end.x)


func _apply_grounded_motion() -> void:
	var delta: float = get_physics_process_delta_time()
	var horizontal_velocity: float = velocity.x
	if _knockback_time_remaining <= 0.0 and _lane_correction_delay_remaining <= 0.0 and _target != null and is_instance_valid(_target) and not _target.is_dead:
		var separation_x: float = _target.global_position.x - global_position.x
		var abs_separation_x: float = absf(separation_x)
		if abs_separation_x <= attack_range:
			horizontal_velocity = move_toward(horizontal_velocity, 0.0, ATTACK_RANGE_FRICTION * delta)
			_knockback_velocity_x = move_toward(_knockback_velocity_x, 0.0, KNOCKBACK_RECOVERY_DECAY * delta * 0.35)
		elif abs_separation_x > hitbox_range + SOFT_TETHER_EXTRA_RANGE:
			var tether_pull: float = sign(separation_x) * minf(SOFT_TETHER_PULL, (abs_separation_x - hitbox_range) * 3.0)
			horizontal_velocity = move_toward(horizontal_velocity, tether_pull, ACCELERATION * delta)

		if abs_separation_x <= hitbox_range + SOFT_TETHER_EXTRA_RANGE:
			var world_center_x: float = _world_bounds.position.x + (_world_bounds.size.x * 0.5)
			var center_bias: float = clampf((world_center_x - global_position.x) * 0.16, -SOFT_CENTER_PULL, SOFT_CENTER_PULL)
			horizontal_velocity = move_toward(horizontal_velocity, center_bias, CENTER_PULL_ACCELERATION * delta)

	horizontal_velocity += _knockback_velocity_x
	velocity.x = horizontal_velocity
	velocity.y = 0.0
	move_and_slide()
	_clamp_to_world()
	_lock_to_ground()


func _lock_to_ground() -> void:
	global_position.y = _ground_y - feet_offset
	velocity.y = 0.0


func _die() -> void:
	is_dead = true
	_attack_requested = false
	_is_attacking = false
	_queued_attack = false
	_recovery_time_remaining = 0.0
	velocity = Vector2.ZERO
	_death_time_remaining = DEATH_HOLD_TIME
	_set_animation("death", true)


func _play_hit_flash() -> void:
	if sprite == null:
		return
	_flash_token += 1
	var flash_token: int = _flash_token
	sprite.modulate = HIT_FLASH_COLOR
	await get_tree().create_timer(HIT_FLASH_DURATION, true, false, true).timeout
	if sprite != null and flash_token == _flash_token:
		sprite.modulate = Color.WHITE


func apply_hit(direction: float, damage: int, impact_bias: float = 1.0) -> void:
	if is_dead:
		return
	_apply_directional_force(direction, damage, impact_bias)
	_play_hit_flash()
	_reengage_time_remaining = REENGAGE_BOOST_TIME
	_enter_recovery(RECOVERY_WINDOW)
	if _is_attacking:
		_queued_attack = true
		return
	_hit_time_remaining = maxf(_hit_time_remaining, RECOVERY_FLOOR)
	velocity.x = 0.0
	_set_animation("hit", true)


func apply_recoil(direction: float, damage: int, recoil_bias: float = 1.0) -> void:
	if is_dead:
		return
	_enter_recovery(RECOIL_RECOVERY_WINDOW)
	_apply_directional_force(direction, damage, RECOIL_FORCE_FACTOR * recoil_bias)

func apply_recoil_from_target(target_pos: Vector2, damage: int, recoil_bias: float = 1.0) -> void:
	if is_dead:
		return
	var direction_from_target: float = sign(global_position.x - target_pos.x)
	if is_zero_approx(direction_from_target):
		direction_from_target = _facing if not is_zero_approx(_facing) else -1.0
	apply_recoil(direction_from_target, damage, recoil_bias)


func _apply_directional_force(direction: float, damage: int, force_multiplier: float) -> void:
	if is_zero_approx(direction):
		return
	var scaled_max_force: float = maxf(MIN_IMPACT_FORCE, MAX_IMPACT_FORCE * force_multiplier)
	var force: float = clampf(
		MIN_IMPACT_FORCE + (float(maxi(1, damage)) * DAMAGE_FORCE_SCALE * force_multiplier),
		MIN_IMPACT_FORCE,
		scaled_max_force
	)
	var variation_seed: float = float((Time.get_ticks_usec() / 1000 + int(global_position.x) + damage * 17) % 1000) / 1000.0
	var variation: float = lerpf(IMPACT_VARIATION_MIN, IMPACT_VARIATION_MAX, variation_seed)
	force = clampf(force * variation, MIN_IMPACT_FORCE, scaled_max_force)
	var health_ratio: float = get_health_ratio()
	var resistance_factor: float = lerpf(LOW_HP_KNOCKBACK_RESISTANCE, 1.0, sqrt(clampf(health_ratio, 0.0, 1.0)))
	if health_ratio <= COMEBACK_HEALTH_THRESHOLD:
		resistance_factor *= COMEBACK_RESISTANCE_FACTOR
	force *= resistance_factor
	direction = sign(direction)
	var edge_distance: float = INF
	if direction < 0.0:
		edge_distance = global_position.x - _world_bounds.position.x
	else:
		edge_distance = _world_bounds.end.x - global_position.x
	if edge_distance < EDGE_RESISTANCE_DISTANCE:
		var edge_factor: float = lerpf(EDGE_RESISTANCE_MIN_FACTOR, 1.0, clampf(edge_distance / EDGE_RESISTANCE_DISTANCE, 0.0, 1.0))
		force *= edge_factor
	_facing = direction
	_knockback_velocity_x = direction * force
	_knockback_time_remaining = KNOCKBACK_OVERRIDE_TIME
	_lane_correction_delay_remaining = maxf(_lane_correction_delay_remaining, LANE_CORRECTION_DELAY)
	_apply_facing()


func _update_knockback(delta: float) -> void:
	if _knockback_time_remaining <= 0.0:
		_knockback_velocity_x = move_toward(_knockback_velocity_x, 0.0, KNOCKBACK_RECOVERY_DECAY * delta)
		return

	var decay_rate: float = KNOCKBACK_BURST_DECAY if _knockback_time_remaining > (KNOCKBACK_OVERRIDE_TIME * (1.0 - KNOCKBACK_BURST_PHASE_RATIO)) else KNOCKBACK_RECOVERY_DECAY
	_knockback_velocity_x = move_toward(_knockback_velocity_x, 0.0, decay_rate * delta)
	_knockback_time_remaining = maxf(0.0, _knockback_time_remaining - delta)


func _rand_variance(range_size: float) -> float:
	var seed_value: float = float((Time.get_ticks_usec() / 1000 + int(global_position.x) + int(global_position.y)) % 1000) / 1000.0
	return lerpf(1.0 - range_size, 1.0 + range_size, seed_value)


func _configure_detection_area() -> void:
	var circle := CircleShape2D.new()
	circle.radius = detection_radius
	detection_shape.shape = circle
	detection_area.collision_layer = 0
	detection_area.collision_mask = 1
	detection_area.monitoring = true
	detection_area.monitorable = false


func _on_detection_body_entered(body: Node) -> void:
	var character: Character = body as Character
	if character == null or character == self or not character.is_in_group(target_group):
		return
	if not _nearby_targets.has(character):
		_nearby_targets.append(character)


func _on_detection_body_exited(body: Node) -> void:
	var character: Character = body as Character
	if character == null:
		return
	_nearby_targets.erase(character)


func _enter_recovery(duration: float) -> void:
	_recovery_time_remaining = maxf(_recovery_time_remaining, duration)
