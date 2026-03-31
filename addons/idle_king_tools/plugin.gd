@tool
extends EditorPlugin

const MAIN_SCENE_PATH := "res://Scenes/Main/MainGameScreen.tscn"
const MAIN_SCREEN_SCRIPT := preload("res://Scripts/UI/MainGameScreen.gd")
const Phase1LayoutBuilderScript := preload("res://Scripts/UI/Phase1LayoutBuilder.gd")


func _enter_tree() -> void:
	add_tool_menu_item("Idle King/Setup Combat", Callable(self, "_setup_combat"))


func _exit_tree() -> void:
	remove_tool_menu_item("Idle King/Setup Combat")


func _setup_combat() -> void:
	var root := Control.new()
	root.name = "MainGameScreen"
	root.layout_mode = 3
	root.anchors_preset = Control.PRESET_FULL_RECT
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.set_script(MAIN_SCREEN_SCRIPT)

	Phase1LayoutBuilderScript.build(root, root)

	var packed := PackedScene.new()
	var pack_result := packed.pack(root)
	if pack_result != OK:
		push_warning("Unable to pack %s (error %d)." % [MAIN_SCENE_PATH, pack_result])
		root.free()
		return

	var save_result := ResourceSaver.save(packed, MAIN_SCENE_PATH)
	root.free()
	if save_result != OK:
		push_warning("Unable to save %s (error %d)." % [MAIN_SCENE_PATH, save_result])
		return

	get_editor_interface().open_scene_from_path(MAIN_SCENE_PATH)
