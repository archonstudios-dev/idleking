extends "res://Scripts/Combat/IdleKingCharacter.gd"

const IDLE_TEXTURE := preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Idle.png")
const RUN_TEXTURE := preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Run.png")
const ATTACK_ONE_TEXTURE := preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Attack1.png")
const ATTACK_TWO_TEXTURE := preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Attack2.png")
const ATTACK_THREE_TEXTURE := preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Attack3.png")
const HIT_TEXTURE := preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Take Hit.png")
const DEATH_TEXTURE := preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Death.png")
const JUMP_TEXTURE := preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Jump.png")
const FALL_TEXTURE := preload("res://Assets/Art/King/Medieval King Pack 2/Sprites/Fall.png")

var _attack_index: int = 0


func _ready() -> void:
	add_to_group("players")
	super._ready()


func get_target_groups() -> Array[StringName]:
	return [&"enemies"]


func get_team_group() -> StringName:
	return &"players"


func _build_animations() -> Dictionary:
	return {
		"idle": {"texture": IDLE_TEXTURE, "frames": 10, "fps": 8.0, "loop": true},
		"run": {"texture": RUN_TEXTURE, "frames": 10, "fps": 10.0, "loop": true},
		"attack_1": {"texture": ATTACK_ONE_TEXTURE, "frames": 5, "fps": 12.0, "loop": false},
		"attack_2": {"texture": ATTACK_TWO_TEXTURE, "frames": 5, "fps": 12.0, "loop": false},
		"attack_3": {"texture": ATTACK_THREE_TEXTURE, "frames": 5, "fps": 12.0, "loop": false},
		"hit": {"texture": HIT_TEXTURE, "frames": 5, "fps": 10.0, "loop": false},
		"death": {"texture": DEATH_TEXTURE, "frames": 6, "fps": 9.0, "loop": false},
		"jump": {"texture": JUMP_TEXTURE, "frames": 3, "fps": 8.0, "loop": false},
		"fall": {"texture": FALL_TEXTURE, "frames": 3, "fps": 8.0, "loop": false},
	}


func _process_behavior(_delta: float) -> void:
	if _hit_stun_remaining > 0.0 or is_dead:
		return

	var target: IdleKingCharacter = get_primary_target()
	var input_axis: float = _get_input_axis()
	var has_input: bool = absf(input_axis) > 0.01

	if has_input:
		_desired_velocity_x = input_axis * move_speed
		if Input.is_physical_key_pressed(KEY_SPACE):
			request_attack()
		return

	if target != null and global_position.distance_to(target.global_position) <= aggro_range:
		face_target(target)
		if can_attack_target(target):
			_desired_velocity_x = 0.0
			request_attack()
		else:
			_desired_velocity_x = sign(target.global_position.x - global_position.x) * (move_speed * 0.92)
		return

	_process_idle_roam()


func _get_next_attack_animation() -> String:
	var names: Array[String] = ["attack_1", "attack_2", "attack_3"]
	var selected: String = names[_attack_index % names.size()]
	_attack_index += 1
	return selected


func _get_input_axis() -> float:
	var axis: float = 0.0
	if Input.is_physical_key_pressed(KEY_A):
		axis -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		axis += 1.0

	# Support W/S as forward/back relative nudges.
	if Input.is_physical_key_pressed(KEY_W):
		axis += facing
	if Input.is_physical_key_pressed(KEY_S):
		axis -= facing

	return clampf(axis, -1.0, 1.0)


func _process_idle_roam() -> void:
	if _patrol_wait_remaining > 0.0:
		_desired_velocity_x = 0.0
		return

	if absf(_patrol_target.x - global_position.x) < 12.0:
		begin_patrol_wait(_random.randf_range(0.35, 0.9))
		choose_patrol_target()
		_desired_velocity_x = 0.0
		return

	_desired_velocity_x = sign(_patrol_target.x - global_position.x) * (move_speed * 0.45)
