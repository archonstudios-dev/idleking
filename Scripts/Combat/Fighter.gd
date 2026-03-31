extends CharacterBody2D

signal health_changed(current: int, max_value: int)
signal defeated()

const CombatSpriteLibraryScript := preload("res://Scripts/UI/CombatSpriteLibrary.gd")

@export var is_player: bool = true
@export var use_player2_inputs: bool = false
@export var is_king: bool = true

@export var max_health: int = 100
@export var move_speed: float = 360.0
@export var jump_velocity: float = -780.0
@export var gravity: float = 2200.0

@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.35
@export var hitbox_active_time: float = 0.12

var health: int
var _facing: int = 1
var _can_attack: bool = true
var _attack_timer: Timer
var _hitbox_timer: Timer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D


func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	_setup_visuals()
	_setup_timers()
	hitbox.monitoring = false
	hitbox_shape.disabled = true


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	if is_player:
		_handle_player_input()
	else:
		_handle_ai()

	move_and_slide()
	_update_animation()


func set_opponent(opponent: Node) -> void:
	if opponent == null:
		return
	if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered.bind(opponent))


func take_damage(amount: int) -> void:
	health = max(0, health - max(1, amount))
	health_changed.emit(health, max_health)
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("hit"):
		sprite.play(&"hit")
	if health == 0:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("death"):
			sprite.play(&"death")
		defeated.emit()


func _setup_visuals() -> void:
	sprite.sprite_frames = CombatSpriteLibraryScript.get_king_frames() if is_king else CombatSpriteLibraryScript.get_enemy_frames()
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play(&"idle")

	# Enemy visuals face left by default in the main game.
	if not is_king:
		sprite.flip_h = true


func _setup_timers() -> void:
	_attack_timer = Timer.new()
	_attack_timer.name = "AttackCooldownTimer"
	_attack_timer.one_shot = true
	_attack_timer.timeout.connect(func() -> void:
		_can_attack = true
	)
	add_child(_attack_timer)

	_hitbox_timer = Timer.new()
	_hitbox_timer.name = "HitboxDisableTimer"
	_hitbox_timer.one_shot = true
	_hitbox_timer.timeout.connect(_disable_hitbox)
	add_child(_hitbox_timer)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _handle_player_input() -> void:
	var left_action := "move_left_p2" if use_player2_inputs else "move_left"
	var right_action := "move_right_p2" if use_player2_inputs else "move_right"
	var jump_action := "jump_p2" if use_player2_inputs else "jump"
	var attack_action := "attack_p2" if use_player2_inputs else "attack"

	var input_axis := Input.get_action_strength(right_action) - Input.get_action_strength(left_action)
	velocity.x = input_axis * move_speed
	if abs(input_axis) > 0.01:
		_facing = 1 if input_axis > 0.0 else -1

	if Input.is_action_just_pressed(jump_action) and is_on_floor():
		velocity.y = jump_velocity

	if Input.is_action_just_pressed(attack_action):
		_try_attack()


func _handle_ai() -> void:
	# Very small training AI: walks toward the opponent if one exists in the scene.
	var opponent := get_parent().get_node_or_null("FighterP1")
	if opponent == null:
		velocity.x = 0.0
		return

	var direction_x: float = signf(opponent.global_position.x - global_position.x)
	velocity.x = direction_x * (move_speed * 0.85)
	_facing = int(direction_x) if direction_x != 0.0 else _facing

	var distance: float = absf(opponent.global_position.x - global_position.x)
	if distance < 120.0:
		velocity.x = 0.0
		_try_attack()


func _try_attack() -> void:
	if not _can_attack:
		return
	if health <= 0:
		return

	_can_attack = false
	_attack_timer.start(attack_cooldown)

	if sprite.sprite_frames != null:
		if is_king:
			if sprite.sprite_frames.has_animation("attack_1"):
				sprite.play(&"attack_1")
		else:
			if sprite.sprite_frames.has_animation("attack_1"):
				sprite.play(&"attack_1")

	_enable_hitbox()


func _enable_hitbox() -> void:
	# Position hitbox in front of the fighter.
	var offset_x := 54.0 * float(_facing)
	hitbox.position = Vector2(offset_x, -18.0)
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	_hitbox_timer.start(hitbox_active_time)


func _disable_hitbox() -> void:
	hitbox.monitoring = false
	hitbox_shape.disabled = true


func _on_hitbox_body_entered(body: Node, opponent: Node) -> void:
	if body != opponent:
		return
	if opponent.has_method("take_damage"):
		opponent.call("take_damage", attack_damage)


func _update_animation() -> void:
	if sprite.sprite_frames == null:
		return

	if health <= 0:
		return

	if not is_on_floor():
		if velocity.y < 0.0 and sprite.sprite_frames.has_animation("jump"):
			if sprite.animation != "jump":
				sprite.play(&"jump")
		elif sprite.sprite_frames.has_animation("fall"):
			if sprite.animation != "fall":
				sprite.play(&"fall")
		return

	if abs(velocity.x) > 10.0:
		if sprite.sprite_frames.has_animation("run") and sprite.animation != "run":
			sprite.play(&"run")
	else:
		if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
			sprite.play(&"idle")

	# Face direction (king faces right by default; enemy art is flipped in main game).
	var desired_flip := _facing < 0
	sprite.flip_h = desired_flip if is_king else not desired_flip
