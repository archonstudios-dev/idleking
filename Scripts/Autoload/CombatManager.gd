# Runs the lightweight Phase 2 combat loop and persists wave progression.
extends Node

signal combat_state_changed(state: Dictionary)
signal enemy_defeated(reward_gold: int, cleared_wave: int)
signal wave_changed(new_wave: int, is_boss_wave: bool)
signal wave_started(new_wave: int, enemy_name: String, is_boss_wave: bool)
signal king_attack_performed(damage: int)
signal enemy_attack_performed(damage: int)
signal king_damaged(damage: int, current_hp: int, max_hp: int)
signal king_defeated()
signal combat_entry_delay_changed(active: bool)

const ATTACK_INTERVAL := 1.0
const KING_BASE_HP := 180
const KING_HP_PER_WAVE := 4
const KING_ATTACK_VISUAL_LOCK := 4.0 / 12.0
const ENEMY_ATTACK_VISUAL_LOCK := 8.0 / 12.0
const SHARED_MELEE_CONTACT_BUFFER := 0.18
const COMBAT_ENTRY_DELAY := 0.6
const POST_HIT_PACING_DELAY := 0.21

var current_wave: int = 1
var king_damage: int = 1
var king_attack_speed: float = ATTACK_INTERVAL
var king_current_hp: int = KING_BASE_HP
var king_max_hp: int = KING_BASE_HP

var enemy_name: String = ""
var enemy_current_hp: int = 0
var enemy_max_hp: int = 0
var enemy_reward_gold: int = 0
var enemy_is_boss: bool = false
var enemy_damage: int = 1
var enemy_attack_cooldown: float = 1.6
var enemy_attack_pattern: String = "measured"

var _attack_timer: Timer
var _enemy_attack_cooldown_timer: Timer
var _enemy_attack_ready: bool = true
var _king_attack_ready: bool = true
var _king_attack_pending: bool = false
var _enemy_attack_pending: bool = false
var _pending_wave_spawn: int = 0
var _king_attack_window_open: bool = false
var _enemy_attack_window_open: bool = false
var _king_attack_lock_remaining: float = 0.0
var _enemy_attack_lock_remaining: float = 0.0
var _shared_melee_contact_remaining: float = 0.0
var _engagement_delay_remaining: float = 0.0


func _ready() -> void:
	# Restores the saved wave and starts the passive attack loop.
	var saved := SaveManager.get_combat_data()
	current_wave = max(1, int(saved.get("current_wave", 1)))
	_refresh_king_health_pool(true)

	_attack_timer = Timer.new()
	_attack_timer.name = "KingAttackTimer"
	_attack_timer.wait_time = king_attack_speed
	_attack_timer.one_shot = false
	_attack_timer.autostart = true
	_attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(_attack_timer)

	_enemy_attack_cooldown_timer = Timer.new()
	_enemy_attack_cooldown_timer.name = "EnemyAttackCooldownTimer"
	_enemy_attack_cooldown_timer.one_shot = true
	_enemy_attack_cooldown_timer.timeout.connect(func() -> void:
		_enemy_attack_ready = true
	)
	add_child(_enemy_attack_cooldown_timer)

	if not UpgradeManager.stats_changed.is_connected(_apply_upgrade_stats):
		UpgradeManager.stats_changed.connect(_apply_upgrade_stats)
	_apply_upgrade_stats(UpgradeManager.get_combat_damage(), UpgradeManager.get_attack_interval(), UpgradeManager.get_gold_multiplier())

	_spawn_enemy_for_wave(current_wave)


func get_state() -> Dictionary:
	# Exposes the latest combat snapshot to UI scripts.
	return {
		"wave": current_wave,
		"king_current_hp": king_current_hp,
		"king_max_hp": king_max_hp,
		"enemy_name": enemy_name,
		"enemy_current_hp": enemy_current_hp,
		"enemy_max_hp": enemy_max_hp,
		"enemy_reward_gold": enemy_reward_gold,
		"enemy_is_boss": enemy_is_boss,
		"enemy_damage": enemy_damage,
		"enemy_attack_cooldown": enemy_attack_cooldown,
		"enemy_attack_pattern": enemy_attack_pattern,
	}


func reset_progress() -> void:
	# Allows future systems to restart combat progression cleanly.
	current_wave = 1
	_refresh_king_health_pool(true)
	_king_attack_pending = false
	_enemy_attack_pending = false
	_pending_wave_spawn = 0
	_save_progress()
	_spawn_enemy_for_wave(current_wave)


func apply_bonus_damage(amount: int) -> void:
	# Keeps the combat manager extensible for upgrades and hero bonuses.
	king_damage = max(1, amount)
	_emit_state()


func apply_attack_speed(interval: float) -> void:
	# Keeps the timer in sync with upgrade-driven attack speed changes.
	king_attack_speed = max(KING_ATTACK_VISUAL_LOCK, interval)
	if _attack_timer != null:
		_attack_timer.wait_time = king_attack_speed
	_emit_state()


func force_spawn_current_wave() -> void:
	# Rebuilds the current enemy without changing saved progression.
	_spawn_enemy_for_wave(current_wave)


func is_combat_entry_delay_active() -> bool:
	return _engagement_delay_remaining > 0.0


func can_enemy_attack() -> bool:
	return _engagement_delay_remaining <= 0.0 and _enemy_attack_ready and not _enemy_attack_pending and enemy_current_hp > 0 and king_current_hp > 0 and _enemy_attack_window_open and _enemy_attack_lock_remaining <= 0.0


func set_attack_windows(king_in_range: bool, enemy_in_range: bool) -> void:
	if _engagement_delay_remaining > 0.0:
		_king_attack_window_open = false
		_enemy_attack_window_open = false
		return

	var shared_melee_contact: bool = king_in_range or enemy_in_range
	if shared_melee_contact:
		_shared_melee_contact_remaining = SHARED_MELEE_CONTACT_BUFFER

	var keep_open: bool = shared_melee_contact or _shared_melee_contact_remaining > 0.0
	_king_attack_window_open = keep_open
	_enemy_attack_window_open = keep_open


func perform_enemy_attack() -> bool:
	# Requests an enemy attack; the bridge resolves the real hit at the animation impact frame.
	if not can_enemy_attack():
		return false

	_enemy_attack_ready = false
	_enemy_attack_pending = true
	_enemy_attack_lock_remaining = ENEMY_ATTACK_VISUAL_LOCK
	if _enemy_attack_cooldown_timer != null:
		_enemy_attack_cooldown_timer.start(enemy_attack_cooldown)

	enemy_attack_performed.emit(enemy_damage)
	return true


func resolve_king_attack() -> int:
	if not _king_attack_pending or enemy_current_hp <= 0:
		_king_attack_pending = false
		return 0

	_king_attack_pending = false
	_king_attack_lock_remaining = maxf(_king_attack_lock_remaining, POST_HIT_PACING_DELAY)
	var applied_damage: int = max(1, king_damage)
	enemy_current_hp = max(0, enemy_current_hp - applied_damage)
	if enemy_current_hp == 0:
		_handle_enemy_defeat()
	else:
		_emit_state()
	return applied_damage


func resolve_enemy_attack() -> int:
	if not _enemy_attack_pending or king_current_hp <= 0:
		_enemy_attack_pending = false
		return 0

	_enemy_attack_pending = false
	_enemy_attack_lock_remaining = maxf(_enemy_attack_lock_remaining, POST_HIT_PACING_DELAY)
	var applied_damage: int = max(1, enemy_damage)
	king_current_hp = max(0, king_current_hp - applied_damage)
	king_damaged.emit(applied_damage, king_current_hp, king_max_hp)
	_emit_state()

	if king_current_hp == 0:
		king_defeated.emit()

	return applied_damage


func spawn_pending_wave_enemy() -> void:
	if _pending_wave_spawn <= 0:
		return

	var pending_wave: int = _pending_wave_spawn
	_pending_wave_spawn = 0
	_spawn_enemy_for_wave(pending_wave)


func recover_from_king_defeat() -> void:
	# Restores only the king so the current enemy encounter persists across deaths.
	_refresh_king_health_pool(true)
	_king_attack_pending = false
	_enemy_attack_pending = false
	_king_attack_ready = true
	_enemy_attack_ready = true
	_king_attack_lock_remaining = 0.0
	_enemy_attack_lock_remaining = 0.0
	_king_attack_window_open = false
	_enemy_attack_window_open = false
	_shared_melee_contact_remaining = 0.0
	_engagement_delay_remaining = COMBAT_ENTRY_DELAY
	combat_entry_delay_changed.emit(true)
	if _enemy_attack_cooldown_timer != null:
		_enemy_attack_cooldown_timer.stop()
	_emit_state()


func _on_attack_timer_timeout() -> void:
	# King timer arms the next attack; the actual request fires once the king is in a valid attack window.
	_king_attack_ready = true


func _process(_delta: float) -> void:
	var was_entry_locked: bool = _engagement_delay_remaining > 0.0
	_king_attack_lock_remaining = maxf(0.0, _king_attack_lock_remaining - _delta)
	_enemy_attack_lock_remaining = maxf(0.0, _enemy_attack_lock_remaining - _delta)
	_shared_melee_contact_remaining = maxf(0.0, _shared_melee_contact_remaining - _delta)
	_engagement_delay_remaining = maxf(0.0, _engagement_delay_remaining - _delta)
	if was_entry_locked and _engagement_delay_remaining == 0.0:
		combat_entry_delay_changed.emit(false)

	if _engagement_delay_remaining <= 0.0 and _king_attack_ready and not _king_attack_pending and _king_attack_window_open and enemy_current_hp > 0 and king_current_hp > 0 and _king_attack_lock_remaining <= 0.0:
		_king_attack_ready = false
		_king_attack_pending = true
		_king_attack_lock_remaining = maxf(_king_attack_lock_remaining, KING_ATTACK_VISUAL_LOCK)
		king_attack_performed.emit(king_damage)

	if _enemy_attack_ready and not _enemy_attack_pending and _enemy_attack_window_open and enemy_current_hp > 0 and king_current_hp > 0 and _enemy_attack_lock_remaining <= 0.0:
		perform_enemy_attack()


func _handle_enemy_defeat() -> void:
	# Rewards gold immediately, then queues the next enemy so the bridge can wait for the death visual.
	var cleared_wave := current_wave
	var payout := UpgradeManager.get_modified_gold(enemy_reward_gold)
	CurrencyManager.add_gold(payout)
	enemy_defeated.emit(payout, cleared_wave)

	current_wave += 1
	_save_progress()
	_pending_wave_spawn = current_wave
	enemy_current_hp = 0
	enemy_max_hp = 0
	_emit_state()


func _spawn_enemy_for_wave(wave: int) -> void:
	# Builds enemy stats from the wave number and boss cadence.
	_refresh_king_health_pool(false)
	_engagement_delay_remaining = COMBAT_ENTRY_DELAY
	combat_entry_delay_changed.emit(true)
	var enemy_data := _create_enemy_data(wave)
	enemy_name = String(enemy_data.get("name", "Enemy"))
	enemy_max_hp = int(enemy_data.get("max_hp", 10))
	enemy_current_hp = enemy_max_hp
	enemy_reward_gold = int(enemy_data.get("reward_gold", 1))
	enemy_is_boss = bool(enemy_data.get("is_boss", false))
	enemy_damage = int(enemy_data.get("damage", 1))
	enemy_attack_cooldown = float(enemy_data.get("attack_cooldown", 1.6))
	enemy_attack_pattern = String(enemy_data.get("attack_pattern", "measured"))
	_enemy_attack_ready = true
	_king_attack_ready = true
	_king_attack_pending = false
	_king_attack_lock_remaining = 0.0
	_enemy_attack_lock_remaining = 0.0
	_shared_melee_contact_remaining = 0.0
	_enemy_attack_pending = false
	if _enemy_attack_cooldown_timer != null:
		_enemy_attack_cooldown_timer.stop()
	wave_changed.emit(current_wave, enemy_is_boss)
	wave_started.emit(current_wave, enemy_name, enemy_is_boss)
	_emit_state()


func _create_enemy_data(wave: int) -> Dictionary:
	# Produces a simple readable progression curve for early combat.
	var base_names := [
		"Goblin Raider",
		"Bone Scout",
		"Dark Acolyte",
		"Fire Worm",
		"Castle Marauder",
	]
	var boss_names := [
		"Crypt Warden",
		"Siege Warlock",
		"Grave Tyrant",
	]

	var is_boss := wave % 10 == 0
	if is_boss:
		var boss_index := int(float(wave) / 10.0 - 1.0) % boss_names.size()
		return {
			"name": "%s Boss" % boss_names[boss_index],
			"max_hp": 45 + wave * 12,
			"reward_gold": 25 + wave * 3,
			"damage": 8 + int(wave * 0.22),
			"attack_cooldown": 2.35,
			"attack_pattern": "boss",
			"is_boss": true,
		}

	var name_index := (wave - 1) % base_names.size()
	var pattern := "measured"
	if wave >= 40 and wave < 90:
		pattern = "aggressive"
	elif wave >= 90:
		pattern = "feint"
	return {
		"name": "%s" % base_names[name_index],
		"max_hp": 10 + wave * 6,
		"reward_gold": 4 + wave,
		"damage": 2 + int(wave * 0.08),
		"attack_cooldown": max(1.15, 1.95 - wave * 0.0035),
		"attack_pattern": pattern,
		"is_boss": false,
	}


func _refresh_king_health_pool(heal_to_full: bool) -> void:
	king_max_hp = KING_BASE_HP + max(0, current_wave - 1) * KING_HP_PER_WAVE
	if heal_to_full:
		king_current_hp = king_max_hp
	else:
		king_current_hp = clampi(king_current_hp, 1, king_max_hp)


func _save_progress() -> void:
	SaveManager.set_combat_data({
		"current_wave": current_wave,
	})


func _emit_state() -> void:
	combat_state_changed.emit(get_state())


func _apply_upgrade_stats(new_damage: int, new_attack_interval: float, _gold_multiplier: float) -> void:
	# Reacts to upgrade changes by refreshing the combat runtime values.
	apply_bonus_damage(new_damage)
	apply_attack_speed(new_attack_interval)
