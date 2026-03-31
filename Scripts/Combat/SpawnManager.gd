extends Node2D
class_name SpawnManager

const PLAYER_SCENE := preload("res://Scenes/Combat/IdleKingPlayer.tscn")
const ENEMY_SCENE := preload("res://Scenes/Combat/IdleKingEnemy.tscn")

@export var floor_y: float = 940.0
@export var player_spawn_position: Vector2 = Vector2(300.0, 940.0)
@export var enemy_spawn_min_x: float = 760.0
@export var enemy_spawn_max_x: float = 980.0
@export var base_enemy_count: int = 2
@export var max_enemies_per_wave: int = 6

var current_wave: int = 1
var player_character: IdleKingCharacter
var _alive_enemies: int = 0
var _random: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var wave_label: Label = $"../CanvasLayer/Hud/WaveLabel" if has_node("../CanvasLayer/Hud/WaveLabel") else null


func _ready() -> void:
	_random.randomize()
	_spawn_player_if_needed()
	_spawn_wave(current_wave)


func _spawn_player_if_needed() -> void:
	var existing_players := get_tree().get_nodes_in_group("players")
	if not existing_players.is_empty():
		player_character = existing_players[0] as IdleKingCharacter
		if player_character != null and not player_character.defeated.is_connected(_on_player_defeated):
			player_character.defeated.connect(_on_player_defeated)
		return

	player_character = PLAYER_SCENE.instantiate() as IdleKingCharacter
	player_character.name = "IdleKingPlayer"
	player_character.global_position = player_spawn_position
	player_character.defeated.connect(_on_player_defeated)
	add_child(player_character)


func _spawn_wave(wave_number: int) -> void:
	current_wave = wave_number
	_alive_enemies = 0
	_update_wave_label()

	var enemy_count: int = mini(max_enemies_per_wave, base_enemy_count + int(wave_number / 3))
	for enemy_index in enemy_count:
		var enemy: Node = ENEMY_SCENE.instantiate()
		enemy.name = "Enemy_%d_%d" % [wave_number, enemy_index]
		enemy.global_position = Vector2(_random.randf_range(enemy_spawn_min_x, enemy_spawn_max_x), floor_y)
		enemy.configure_for_wave(wave_number, enemy_index)
		enemy.defeated.connect(_on_enemy_defeated)
		add_child(enemy)
		_alive_enemies += 1


func _on_enemy_defeated(_enemy: IdleKingCharacter) -> void:
	_alive_enemies = max(0, _alive_enemies - 1)
	if _alive_enemies == 0:
		_spawn_wave(current_wave + 1)


func _on_player_defeated(_player: IdleKingCharacter) -> void:
	player_character = null
	var respawn_timer := get_tree().create_timer(1.0)
	respawn_timer.timeout.connect(func() -> void:
		_spawn_player_if_needed()
	)


func _update_wave_label() -> void:
	if wave_label != null:
		wave_label.text = "Wave %d" % current_wave
