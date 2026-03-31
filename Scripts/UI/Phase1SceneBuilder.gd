# Editor utility that regenerates the Phase 1 main scene scaffold with named nodes.
@tool
extends EditorScript

const MAIN_SCENE_PATH := "res://Scenes/Main/MainGameScreen.tscn"
const MAIN_SCRIPT_PATH := "res://Scripts/UI/MainGameScreen.gd"


func _run() -> void:
	# Creates or refreshes the main scene so the user does not need to wire it manually.
	var root := Control.new()
	root.name = "MainGameScreen"
	root.set_script(load(MAIN_SCRIPT_PATH))
	Phase1LayoutBuilder.build(root, root)

	var packed_scene := PackedScene.new()
	var pack_result := packed_scene.pack(root)
	if pack_result != OK:
		push_error("Failed to pack Phase 1 main scene.")
		root.free()
		return

	var save_result := ResourceSaver.save(packed_scene, MAIN_SCENE_PATH)
	if save_result != OK:
		push_error("Failed to save %s." % MAIN_SCENE_PATH)
	else:
		print("Phase 1 scene scaffold saved to %s" % MAIN_SCENE_PATH)

	root.free()

