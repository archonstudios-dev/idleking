# Persists lightweight profile data for the early game flow.
extends Node

const SAVE_PATH := "user://idle_king_save.json"
const SAVE_DEBOUNCE_SECONDS := 1.0
const DEFAULT_SAVE := {
	"king_name": "",
	"currencies": {
		"gold": 0,
		"gems": 100,
	},
	"combat": {
		"current_wave": 1,
	},
	"upgrades": {
		"damage_level": 0,
		"max_hp_level": 0,
		"speed_level": 0,
		"recovery_level": 0,
		"gold_level": 0,
	},
	"audio": {
		"muted": false,
	},
	"first_launch_complete": false,
}

var _save_data: Dictionary = DEFAULT_SAVE.duplicate(true)
var _save_debounce_timer: Timer
var _save_pending: bool = false


func _ready() -> void:
	# Load once at boot so other autoloads can read from memory.
	load_game()
	_setup_save_debounce()


func _setup_save_debounce() -> void:
	if _save_debounce_timer != null:
		return

	_save_debounce_timer = Timer.new()
	_save_debounce_timer.name = "SaveDebounceTimer"
	_save_debounce_timer.one_shot = true
	_save_debounce_timer.wait_time = SAVE_DEBOUNCE_SECONDS
	_save_debounce_timer.timeout.connect(_flush_pending_save)
	add_child(_save_debounce_timer)


func load_game() -> Dictionary:
	# Falls back to defaults if the save file does not exist or is invalid.
	if not FileAccess.file_exists(SAVE_PATH):
		_save_data = DEFAULT_SAVE.duplicate(true)
		return get_save_data()

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_save_data = DEFAULT_SAVE.duplicate(true)
		return get_save_data()

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_save_data = DEFAULT_SAVE.duplicate(true)
		_merge_dictionary(_save_data, parsed)
	else:
		_save_data = DEFAULT_SAVE.duplicate(true)

	return get_save_data()


func save_game() -> void:
	# Writes the in-memory dictionary to disk in one place.
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to open save file for writing.")
		return

	file.store_string(JSON.stringify(_save_data, "\t"))


func request_save() -> void:
	# Coalesces many rapid state changes into a single disk write.
	_save_pending = true
	if _save_debounce_timer == null:
		_setup_save_debounce()
	_save_debounce_timer.start(SAVE_DEBOUNCE_SECONDS)


func flush_save() -> void:
	_save_pending = false
	if _save_debounce_timer != null:
		_save_debounce_timer.stop()
	save_game()


func _flush_pending_save() -> void:
	if not _save_pending:
		return
	_save_pending = false
	save_game()


func get_save_data() -> Dictionary:
	# Returns a copy so callers cannot mutate the cache silently.
	return _save_data.duplicate(true)


func get_king_name() -> String:
	return String(_save_data.get("king_name", ""))


func set_king_name(value: String) -> void:
	_save_data["king_name"] = value
	_save_data["first_launch_complete"] = true
	request_save()


func get_currencies() -> Dictionary:
	return Dictionary(_save_data.get("currencies", {})).duplicate(true)


func set_currencies(values: Dictionary) -> void:
	_save_data["currencies"] = values.duplicate(true)
	request_save()


func get_combat_data() -> Dictionary:
	# Returns saved combat progression for wave-based gameplay.
	return Dictionary(_save_data.get("combat", {})).duplicate(true)


func set_combat_data(values: Dictionary) -> void:
	_save_data["combat"] = values.duplicate(true)
	request_save()


func get_upgrade_data() -> Dictionary:
	# Returns saved upgrade levels for Phase 3 progression.
	return Dictionary(_save_data.get("upgrades", {})).duplicate(true)


func set_upgrade_data(values: Dictionary) -> void:
	_save_data["upgrades"] = values.duplicate(true)
	request_save()


func get_audio_muted() -> bool:
	return bool(Dictionary(_save_data.get("audio", {})).get("muted", false))


func set_audio_muted(value: bool) -> void:
	_save_data["audio"] = {"muted": value}
	request_save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush_save()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		flush_save()


func _merge_dictionary(target: Dictionary, incoming: Dictionary) -> void:
	# Merges nested save data while preserving missing defaults.
	for key in incoming.keys():
		if target.get(key) is Dictionary and incoming[key] is Dictionary:
			_merge_dictionary(target[key], incoming[key])
		else:
			target[key] = incoming[key]
