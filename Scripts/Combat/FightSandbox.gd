extends Node2D

const FIGHTER_SCENE := preload("res://Scenes/Combat/Fighter.tscn")

@onready var fighter_p1: Node = $FighterP1
@onready var fighter_p2: Node = $FighterP2


func _ready() -> void:
	# Wire hit detection.
	if fighter_p1 != null and fighter_p2 != null:
		fighter_p1.set_opponent(fighter_p2)
		fighter_p2.set_opponent(fighter_p1)

	if fighter_p2 != null and fighter_p2.defeated.is_connected(_on_fighter_defeated) == false:
		fighter_p2.defeated.connect(_on_fighter_defeated.bind(fighter_p2))
	if fighter_p1 != null and fighter_p1.defeated.is_connected(_on_fighter_defeated) == false:
		fighter_p1.defeated.connect(_on_fighter_defeated.bind(fighter_p1))


func _on_fighter_defeated(_fighter: Node) -> void:
	# Quick reset for iteration.
	get_tree().reload_current_scene()

