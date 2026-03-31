# Manages the starter economy for Phase 1 and broadcasts UI updates.
extends Node

signal currencies_changed(gold: int, gems: int)

const STARTING_GOLD := 0
const STARTING_GEMS := 100

var gold: int = STARTING_GOLD
var gems: int = STARTING_GEMS


func _ready() -> void:
	# Loads saved currency values so the main screen can refresh instantly.
	var saved := SaveManager.get_currencies()
	gold = int(saved.get("gold", STARTING_GOLD))
	gems = int(saved.get("gems", STARTING_GEMS))


func initialize_new_profile() -> void:
	# Seeds a new kingdom with predictable starter values.
	gold = STARTING_GOLD
	gems = STARTING_GEMS
	_persist_and_emit()


func add_gold(amount: int) -> void:
	# Gold is the first active currency, so tapping routes through here.
	gold = max(0, gold + amount)
	_persist_and_emit()


func spend_gold(amount: int) -> bool:
	# Returns whether the purchase succeeded so upgrade calls can stay simple.
	if amount > gold:
		return false

	gold -= amount
	_persist_and_emit()
	return true


func can_afford_gold(amount: int) -> bool:
	# Helps UI decide when upgrade buttons should be enabled.
	return gold >= amount


func set_gems(amount: int) -> void:
	# Keeps the premium currency path available for later phases.
	gems = max(0, amount)
	_persist_and_emit()


func get_currencies() -> Dictionary:
	return {
		"gold": gold,
		"gems": gems,
	}


func _persist_and_emit() -> void:
	# Saves and then notifies listeners with the latest values.
	SaveManager.set_currencies(get_currencies())
	currencies_changed.emit(gold, gems)
