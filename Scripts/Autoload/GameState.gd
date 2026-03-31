# Holds lightweight runtime state that multiple scenes need to read.
extends Node

signal king_name_changed(new_name: String)

var king_name: String = ""


func _ready() -> void:
	# Pulls saved identity data into the runtime cache on startup.
	king_name = SaveManager.get_king_name()


func set_king_name(value: String) -> void:
	# Trims input and keeps both runtime and persisted state aligned.
	king_name = value.strip_edges()
	SaveManager.set_king_name(king_name)
	king_name_changed.emit(king_name)


func has_king_name() -> bool:
	return not king_name.is_empty()

