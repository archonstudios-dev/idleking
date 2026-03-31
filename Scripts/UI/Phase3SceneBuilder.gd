# Editor utility that regenerates the main scene scaffold with the Phase 3 upgrade panel included.
@tool
extends EditorScript

const MAIN_SCENE_PATH := "res://Scenes/Main/MainGameScreen.tscn"
const MAIN_SCRIPT_PATH := "res://Scripts/UI/MainGameScreen.gd"


func _run() -> void:
	# Rebuilds the main gameplay scene so upgrade UI wiring stays automated.
	var root := Control.new()
	root.name = "MainGameScreen"
	root.set_script(load(MAIN_SCRIPT_PATH))
	Phase1LayoutBuilder.build(root, root)

	var packed_scene := PackedScene.new()
	var pack_result := packed_scene.pack(root)
	if pack_result != OK:
		push_error("Failed to pack Phase 3 main scene.")
		root.free()
		return

	var save_result := ResourceSaver.save(packed_scene, MAIN_SCENE_PATH)
	if save_result != OK:
		push_error("Failed to save %s." % MAIN_SCENE_PATH)
	else:
		print("Phase 3 scene scaffold saved to %s" % MAIN_SCENE_PATH)

	root.free()
