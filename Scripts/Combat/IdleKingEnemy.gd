extends "res://Scripts/Combat/IdleKingCharacter.gd"

const IDLE_TEXTURE := preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Idle.png")
const RUN_TEXTURE := preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Run.png")
const ATTACK_ONE_TEXTURE := preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Attack1.png")
const ATTACK_TWO_TEXTURE := preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Attack2.png")
const HIT_TEXTURE := preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Take hit.png")
const DEATH_TEXTURE := preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Death.png")
const JUMP_TEXTURE := preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Jump.png")
const FALL_TEXTURE := preload("res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Fall.png")

@export var separation_radius: float = 72.0
@export var separation_strength: float = 0.65

var wave_number: int = 1
var enemy_index: int = 0
var _attack_index: int = 0


func _ready() -> void:
	add_to_group("enemies")
	super._ready()


func get_target_groups() -> Array[StringName]:
	return [&"players"]


func get_team_group() -> StringName:
	return &"enemies"


func _build_animations() -> Dictionary:
	return {
		"idle": {"texture": IDLE_TEXTURE, "frames": 8, "fps": 8.0, "loop": true},
		"run": {"texture": RUN_TEXTURE, "frames": 8, "fps": 10.0, "loop": true},
		"attack_1": {"texture": ATTACK_ONE_TEXTURE, "frames": 8, "fps": 12.0, "loop": false},
		"attack_2": {"texture": ATTACK_TWO_TEXTURE, "frames": 8, "fps": 12.0, "loop": false},
		"hit": {"texture": HIT_TEXTURE, "frames": 3, "fps": 10.0, "loop": false},
		"death": {"texture": DEATH_TEXTURE, "frames": 7, "fps": 9.0, "loop": false},
		"jump": {"texture": JUMP_TEXTURE, "frames": 2, "fps": 8.0, "loop": false},
		"fall": {"texture": FALL_TEXTURE, "frames": 2, "fps": 8.0, "loop": false},
	}


func configure_for_wave(new_wave: int, new_index: int) -> void:
	wave_number = max(1, new_wave)
	enemy_index = new_index
	max_health = 55 + wave_number * 10
	health = max_health
	move_speed = SPEED + minf(90.0, wave_number * 2.8)
	attack_damage = 8 + int(wave_number * 1.4)
	attack_cooldown = maxf(0.48, 1.1 - float(wave_number) * 0.012)
	attack_range = 76.0 + minf(22.0, float(wave_number) * 0.18)
	patrol_radius = 68.0
	aggro_range = 560.0
	health_changed.emit(health, max_health)


func _process_behavior(_delta: float) -> void:
	if _hit_stun_remaining > 0.0 or is_dead:
		return

	var target: IdleKingCharacter = get_primary_target()
	if target == null:
		_process_patrol()
		return

	var distance_x: float = target.global_position.x - global_position.x
	var separation_push: float = get_neighbor_push(separation_radius) * separation_strength
	face_target(target)

	if absf(distance_x) <= attack_range:
		_desired_velocity_x = 0.0
		request_attack()
		return

	if absf(distance_x) <= aggro_range:
		var seek_velocity: float = sign(distance_x) * move_speed
		_desired_velocity_x = seek_velocity + separation_push * move_speed
		return

	_process_patrol()


func _get_next_attack_animation() -> String:
	var names: Array[String] = ["attack_1", "attack_2"]
	if wave_number >= 10:
		# Boss-pattern enemies lean harder on attack_2 for variety.
		names = ["attack_2", "attack_1", "attack_2"]
	var selected: String = names[_attack_index % names.size()]
	_attack_index += 1
	return selected


func _process_patrol() -> void:
	if _patrol_wait_remaining > 0.0:
		_desired_velocity_x = 0.0
		return

	if absf(_patrol_target.x - global_position.x) < 14.0:
		begin_patrol_wait(_random.randf_range(0.25, 0.75))
		choose_patrol_target(_patrol_center)
		_desired_velocity_x = 0.0
		return

	_desired_velocity_x = sign(_patrol_target.x - global_position.x) * (move_speed * 0.45)
