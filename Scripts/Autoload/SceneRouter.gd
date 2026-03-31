# Centralizes scene changes so flow scripts stay small and readable.
extends Node


func go_to(scene_path: String) -> void:
	# Defers the change to avoid replacing the current scene mid-signal.
	call_deferred("_change_scene", scene_path)


func _change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

