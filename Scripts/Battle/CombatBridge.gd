extends Node
class_name CombatBridge

const KING_RESPAWN_DELAY := 0.4
const MOMENTUM_GAIN_PER_DAMAGE := 0.004
const MOMENTUM_DECAY_PER_SECOND := 1.8
const MOMENTUM_TARGET_BIAS := 0.10
const MOMENTUM_RECOIL_REDUCTION := 0.06
const MOMENTUM_EFFECT_CAP := 0.55
const HIT_VARIANCE_RANGE := 0.10
var _combat_manager: Node
var _game_world: Node
var _hero
var _enemy
var _momentum: float = 0.0


func setup(game_world: Node, combat_manager: Node) -> void:
	_game_world = game_world
	_combat_manager = combat_manager

	if _combat_manager == null:
		return

	if not _combat_manager.king_attack_performed.is_connected(_on_king_attack_requested):
		_combat_manager.king_attack_performed.connect(_on_king_attack_requested)
	if not _combat_manager.enemy_attack_performed.is_connected(_on_enemy_attack_requested):
		_combat_manager.enemy_attack_performed.connect(_on_enemy_attack_requested)
	if not _combat_manager.king_defeated.is_connected(_on_king_defeated):
		_combat_manager.king_defeated.connect(_on_king_defeated)
	if not _combat_manager.enemy_defeated.is_connected(_on_enemy_defeated):
		_combat_manager.enemy_defeated.connect(_on_enemy_defeated)


func set_combatants(hero, enemy) -> void:
	if _hero != null:
		if _hero.attack_hit.is_connected(_on_hero_attack_hit):
			_hero.attack_hit.disconnect(_on_hero_attack_hit)
		if _hero.died.is_connected(_on_hero_died):
			_hero.died.disconnect(_on_hero_died)

	if _enemy != null:
		if _enemy.attack_hit.is_connected(_on_enemy_attack_hit):
			_enemy.attack_hit.disconnect(_on_enemy_attack_hit)
		if _enemy.died.is_connected(_on_enemy_died):
			_enemy.died.disconnect(_on_enemy_died)

	_hero = hero
	_enemy = enemy

	if _hero != null:
		_hero.set_target(_enemy)
		if not _hero.attack_hit.is_connected(_on_hero_attack_hit):
			_hero.attack_hit.connect(_on_hero_attack_hit)
		if not _hero.died.is_connected(_on_hero_died):
			_hero.died.connect(_on_hero_died)
	if _enemy != null:
		_enemy.set_target(_hero)
		if not _enemy.attack_hit.is_connected(_on_enemy_attack_hit):
			_enemy.attack_hit.connect(_on_enemy_attack_hit)
		if not _enemy.died.is_connected(_on_enemy_died):
			_enemy.died.connect(_on_enemy_died)


func _physics_process(delta: float) -> void:
	_momentum = move_toward(_momentum, 0.0, MOMENTUM_DECAY_PER_SECOND * delta)
	if _combat_manager == null or _hero == null or _enemy == null:
		return
	if _hero.is_dead or _enemy.is_dead:
		_combat_manager.call("set_attack_windows", false, false)
		return

	_combat_manager.call(
		"set_attack_windows",
		_hero.is_target_in_range(_enemy),
		_enemy.is_target_in_range(_hero)
	)


func _on_king_attack_requested(_damage: int) -> void:
	if _hero != null:
		_hero.play_attack_animation()


func _on_enemy_attack_requested(_damage: int) -> void:
	if _enemy != null:
		if not _enemy.attack_hit.is_connected(_on_enemy_attack_hit):
			_enemy.attack_hit.connect(_on_enemy_attack_hit)
		if not _enemy.died.is_connected(_on_enemy_died):
			_enemy.died.connect(_on_enemy_died)
		_enemy.play_attack_animation()


func _on_hero_attack_hit(character) -> void:
	if character != _hero or _combat_manager == null or _enemy == null or _enemy.is_dead:
		return

	var applied_damage: int = int(_combat_manager.call("resolve_king_attack"))
	if applied_damage <= 0:
		return

	var hit_variance: float = _variance_from_positions(_hero.global_position, _enemy.global_position)
	_momentum = clampf(_momentum + (float(applied_damage) * MOMENTUM_GAIN_PER_DAMAGE), -1.0, 1.0)
	var positive_momentum: float = minf(maxf(0.0, _momentum), MOMENTUM_EFFECT_CAP)
	var target_bias: float = (0.96 + positive_momentum * MOMENTUM_TARGET_BIAS) * hit_variance
	var attacker_recoil_bias: float = (0.96 - positive_momentum * MOMENTUM_RECOIL_REDUCTION) * (2.0 - hit_variance)
	var impact_direction: float = sign(_enemy.global_position.x - _hero.global_position.x)
	if is_zero_approx(impact_direction):
		impact_direction = 1.0
	var impact_position: Vector2 = _get_impact_position(_hero, _enemy)
	var state: Dictionary = _combat_manager.call("get_state")
	_enemy.sync_health(int(state.get("enemy_current_hp", 0)), max(1, int(state.get("enemy_max_hp", 1))))
	_apply_hit_reactions_after_stop(_enemy, _hero, impact_direction, applied_damage, target_bias, attacker_recoil_bias)
	if _game_world != null and _game_world.has_method("apply_hit_feedback"):
		_game_world.call("apply_hit_feedback", applied_damage, impact_position)


func _on_enemy_attack_hit(character) -> void:
	if character != _enemy or _combat_manager == null or _hero == null or _hero.is_dead:
		return

	var applied_damage: int = int(_combat_manager.call("resolve_enemy_attack"))
	if applied_damage <= 0:
		return

	var hit_variance: float = _variance_from_positions(_enemy.global_position, _hero.global_position)
	_momentum = clampf(_momentum - (float(applied_damage) * MOMENTUM_GAIN_PER_DAMAGE), -1.0, 1.0)
	var negative_momentum: float = minf(maxf(0.0, -_momentum), MOMENTUM_EFFECT_CAP)
	var target_bias: float = (0.96 + negative_momentum * MOMENTUM_TARGET_BIAS) * hit_variance
	var attacker_recoil_bias: float = (0.96 - negative_momentum * MOMENTUM_RECOIL_REDUCTION) * (2.0 - hit_variance)
	var impact_direction: float = sign(_hero.global_position.x - _enemy.global_position.x)
	if is_zero_approx(impact_direction):
		impact_direction = -1.0
	var impact_position: Vector2 = _get_impact_position(_enemy, _hero)
	var state: Dictionary = _combat_manager.call("get_state")
	_hero.sync_health(int(state.get("king_current_hp", 0)), max(1, int(state.get("king_max_hp", 1))))
	_apply_hit_reactions_after_stop(_hero, _enemy, impact_direction, applied_damage, target_bias, attacker_recoil_bias)
	if _game_world != null and _game_world.has_method("apply_hit_feedback"):
		_game_world.call("apply_hit_feedback", applied_damage, impact_position)


func _on_hero_died(character) -> void:
	if character != _hero or _combat_manager == null or _game_world == null:
		return

	_combat_manager.call("set_attack_windows", false, false)
	await get_tree().create_timer(KING_RESPAWN_DELAY, true, false, true).timeout
	_combat_manager.call("recover_from_king_defeat")
	_game_world.call("refresh_from_combat_state", _combat_manager.call("get_state"))
	set_combatants(_game_world.hero, _game_world.enemy)


func _on_enemy_died(character) -> void:
	if character != _enemy or _combat_manager == null or _game_world == null:
		return
	_combat_manager.call("set_attack_windows", false, false)
	_combat_manager.call("spawn_pending_wave_enemy")
	_game_world.call("refresh_from_combat_state", _combat_manager.call("get_state"))


func _on_king_defeated() -> void:
	if _hero == null or _hero.is_dead:
		return
	# Manager owns HP=0; the bridge mirrors the matching visual death state.
	_hero.call("_die")


func _on_enemy_defeated(_reward_gold: int, _cleared_wave: int) -> void:
	if _enemy == null or _enemy.is_dead:
		return
	# Hold the pending wave spawn until the current enemy finishes its death animation.
	_enemy.call("_die")


func _variance_from_positions(source: Vector2, target: Vector2) -> float:
	var seed_value: float = float((int(source.x) * 13 + int(target.x) * 7 + int(source.y)) % 1000) / 1000.0
	return lerpf(1.0 - HIT_VARIANCE_RANGE, 1.0 + HIT_VARIANCE_RANGE, seed_value)


func _apply_hit_reactions_after_stop(defender, attacker, impact_direction: float, damage: int, target_bias: float, attacker_recoil_bias: float) -> void:
	if defender != null and is_instance_valid(defender) and not defender.is_dead:
		if defender.has_method("apply_hit"):
			defender.call("apply_hit", impact_direction, damage, target_bias)
		else:
			var attacker_pos: Vector2 = attacker.global_position if attacker != null and is_instance_valid(attacker) else defender.global_position
			defender.take_damage(damage, attacker_pos, target_bias)
	if attacker != null and is_instance_valid(attacker) and not attacker.is_dead:
		if attacker.has_method("apply_recoil"):
			attacker.call("apply_recoil", -impact_direction, damage, attacker_recoil_bias)
		elif attacker.has_method("apply_recoil_from_target") and defender != null and is_instance_valid(defender):
			attacker.call("apply_recoil_from_target", defender.global_position, damage, attacker_recoil_bias)


func _get_impact_position(attacker, defender) -> Vector2:
	if attacker == null or not is_instance_valid(attacker):
		return defender.global_position if defender != null and is_instance_valid(defender) else Vector2.ZERO
	if defender == null or not is_instance_valid(defender):
		return attacker.global_position
	var midpoint: Vector2 = attacker.global_position.lerp(defender.global_position, 0.5)
	midpoint.y -= 18.0
	return midpoint
