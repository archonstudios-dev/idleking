# Manages upgrade levels, costs, and derived stat outputs for combat and economy.
extends Node

signal upgrades_changed(state: Dictionary)
signal stats_changed(damage: int, attack_interval: float, gold_multiplier: float)

const UPGRADE_ORDER := ["damage", "max_hp", "attack_speed", "recovery", "gold_gain"]

const DAMAGE_BASE_COST := 15
const MAX_HP_BASE_COST := 24
const ATTACK_SPEED_BASE_COST := 20
const RECOVERY_BASE_COST := 30
const GOLD_GAIN_BASE_COST := 18

var damage_level: int = 0
var max_hp_level: int = 0
var speed_level: int = 0
var recovery_level: int = 0
var gold_level: int = 0


func _ready() -> void:
	# Restores upgrade progression from save and broadcasts initial stat values.
	var saved := SaveManager.get_upgrade_data()
	damage_level = int(saved.get("damage_level", 0))
	max_hp_level = int(saved.get("max_hp_level", 0))
	speed_level = int(saved.get("speed_level", 0))
	recovery_level = int(saved.get("recovery_level", 0))
	gold_level = int(saved.get("gold_level", 0))
	_emit_all()


func reset_progress() -> void:
	# Resets upgrade levels for a fresh kingdom profile.
	damage_level = 0
	max_hp_level = 0
	speed_level = 0
	recovery_level = 0
	gold_level = 0
	_emit_all()


func get_upgrade_state() -> Dictionary:
	# Exposes levels, costs, and derived values for the upgrade panel.
	var upgrades: Dictionary = {}
	for upgrade_id in UPGRADE_ORDER:
		upgrades[upgrade_id] = get_upgrade_ui_data(upgrade_id)

	return {
		"damage_level": damage_level,
		"max_hp_level": max_hp_level,
		"speed_level": speed_level,
		"recovery_level": recovery_level,
		"gold_level": gold_level,
		"damage_cost": get_damage_cost(),
		"max_hp_cost": get_max_hp_cost(),
		"speed_cost": get_speed_cost(),
		"recovery_cost": get_recovery_cost(),
		"gold_cost": get_gold_cost(),
		"damage_value": get_combat_damage(),
		"max_hp_value": get_effective_max_hp(),
		"attack_interval": get_attack_interval(),
		"recovery_value": get_effective_recovery_bonus(),
		"gold_multiplier": get_gold_multiplier(),
		"upgrades": upgrades,
	}


func get_upgrade_ui_data(upgrade_id: String) -> Dictionary:
	var level := get_upgrade_level(upgrade_id)
	var cost := get_upgrade_cost(upgrade_id)
	return {
		"id": upgrade_id,
		"name": get_upgrade_label(upgrade_id),
		"level": level,
		"cost": cost,
		"affordable": CurrencyManager.can_afford_gold(cost),
		"current_value_text": get_upgrade_current_value_text(upgrade_id),
		"next_value_text": get_upgrade_next_value_text(upgrade_id),
		"effect_text": get_upgrade_effect_text(upgrade_id),
	}


func get_upgrade_level(upgrade_id: String) -> int:
	match upgrade_id:
		"damage":
			return damage_level
		"max_hp":
			return max_hp_level
		"attack_speed":
			return speed_level
		"recovery":
			return recovery_level
		"gold_gain":
			return gold_level
		_:
			return 0


func get_upgrade_label(upgrade_id: String) -> String:
	match upgrade_id:
		"damage":
			return "Damage"
		"max_hp":
			return "Max HP"
		"attack_speed":
			return "Attack Speed"
		"recovery":
			return "Recovery"
		"gold_gain":
			return "Gold Gain"
		_:
			return "Upgrade"


func get_upgrade_cost(upgrade_id: String) -> int:
	match upgrade_id:
		"damage":
			return get_damage_cost()
		"max_hp":
			return get_max_hp_cost()
		"attack_speed":
			return get_speed_cost()
		"recovery":
			return get_recovery_cost()
		"gold_gain":
			return get_gold_cost()
		_:
			return 0


func get_damage_cost() -> int:
	return int(round(DAMAGE_BASE_COST * pow(1.45, damage_level)))


func get_max_hp_cost() -> int:
	return int(round(MAX_HP_BASE_COST * pow(1.35, max_hp_level)))


func get_speed_cost() -> int:
	return int(round(ATTACK_SPEED_BASE_COST * pow(1.55, speed_level)))


func get_recovery_cost() -> int:
	return int(round(RECOVERY_BASE_COST * pow(1.4, recovery_level)))


func get_gold_cost() -> int:
	return int(round(GOLD_GAIN_BASE_COST * pow(1.5, gold_level)))


func get_combat_damage() -> int:
	return 1 + damage_level


func get_effective_max_hp() -> int:
	return 180 + max_hp_level * 12


func get_attack_interval() -> float:
	return max(0.35, 1.0 - speed_level * 0.08)


func get_effective_recovery_bonus() -> float:
	return min(recovery_level * 0.015, 0.18)


func get_gold_multiplier() -> float:
	return 1.0 + gold_level * 0.25


func get_modified_gold(base_amount: int) -> int:
	# Applies the gold multiplier and rounds up to keep rewards feeling good.
	return int(ceil(base_amount * get_gold_multiplier()))


func purchase_damage_upgrade() -> bool:
	return try_purchase_upgrade("damage")


func purchase_speed_upgrade() -> bool:
	return try_purchase_upgrade("attack_speed")


func purchase_gold_upgrade() -> bool:
	return try_purchase_upgrade("gold_gain")


func try_purchase_upgrade(upgrade_id: String) -> bool:
	# Handles gold checks, level ups, and save updates for each upgrade track.
	var cost := get_upgrade_cost(upgrade_id)
	if cost <= 0:
		return false
	if not CurrencyManager.spend_gold(cost):
		return false

	match upgrade_id:
		"damage":
			damage_level += 1
		"max_hp":
			max_hp_level += 1
		"attack_speed":
			speed_level += 1
		"recovery":
			recovery_level += 1
		"gold_gain":
			gold_level += 1
		_:
			return false

	_emit_all()
	return true


func get_upgrade_effect_text(upgrade_id: String) -> String:
	match upgrade_id:
		"damage":
			return "+1 king damage per level"
		"max_hp":
			return "+12 max HP per level"
		"attack_speed":
			return "-0.08s attack interval per level"
		"recovery":
			return "-0.015s recovery pressure per level"
		"gold_gain":
			return "+25%% gold multiplier per level"
		_:
			return ""


func get_upgrade_current_value_text(upgrade_id: String) -> String:
	match upgrade_id:
		"damage":
			return "Current: %d damage" % get_combat_damage()
		"max_hp":
			return "Current: %d max HP" % get_effective_max_hp()
		"attack_speed":
			return "Current: %.2fs interval" % get_attack_interval()
		"recovery":
			return "Current: %.3fs bonus" % get_effective_recovery_bonus()
		"gold_gain":
			return "Current: x%.2f gold" % get_gold_multiplier()
		_:
			return "Current: -"


func get_upgrade_next_value_text(upgrade_id: String) -> String:
	match upgrade_id:
		"damage":
			return "Next: %d damage" % (get_combat_damage() + 1)
		"max_hp":
			return "Next: %d max HP" % (get_effective_max_hp() + 12)
		"attack_speed":
			return "Next: %.2fs interval" % max(0.35, get_attack_interval() - 0.08)
		"recovery":
			return "Next: %.3fs bonus" % min(get_effective_recovery_bonus() + 0.015, 0.18)
		"gold_gain":
			return "Next: x%.2f gold" % (get_gold_multiplier() + 0.25)
		_:
			return "Next: -"


func _emit_all() -> void:
	# Saves progression and updates both combat and UI listeners.
	SaveManager.set_upgrade_data({
		"damage_level": damage_level,
		"max_hp_level": max_hp_level,
		"speed_level": speed_level,
		"recovery_level": recovery_level,
		"gold_level": gold_level,
	})
	upgrades_changed.emit(get_upgrade_state())
	stats_changed.emit(get_combat_damage(), get_attack_interval(), get_gold_multiplier())
