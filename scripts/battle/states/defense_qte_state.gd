# res://scripts/battle/states/defense_qte_state.gd
class_name DefenseQTEState
extends BaseBattleState

## Обработка защитного QTE (круговой скилл-чек / ритм) и применение градиентного блока
var _waiting_for_qte: bool = false
var _has_defense_qte: bool = false

func get_state_id() -> StringName:
	return &"defense_qte"

func enter() -> void:
	if _context == null:
		return
	
	_waiting_for_qte = false
	_has_defense_qte = false
	
	var attacker: Combatant = _context.enemy_pending_actor
	var skill: SkillData = _context.enemy_pending_skill
	var target: Combatant = _context.enemy_pending_target
	
	if attacker == null or skill == null or target == null:
		_advance_after_enemy_attack()
		return
	
	if skill.requires_qte and skill.qte_config != null and target.is_player_controlled:
		_waiting_for_qte = true
		_has_defense_qte = true
		log_requested.emit("%s применяет «%s»! Защититесь в QTE!" % [attacker.display_name, skill.skill_name])
		qte_requested.emit(skill.qte_config, true)
		return
	
	_resolve_enemy_attack(1.0, "")

func exit() -> void:
	_waiting_for_qte = false
	_has_defense_qte = false
	if _context != null:
		_context.clear_pending_enemy_action()

func on_qte_completed(accuracy: float, success_tier: String) -> void:
	if not _waiting_for_qte:
		return
	_waiting_for_qte = false
	
	var target: Combatant = _context.enemy_pending_target
	var skill: SkillData = _context.enemy_pending_skill
	if skill == null or target == null:
		_advance_after_enemy_attack()
		return
	
	var eval_res: Dictionary = BattleCalculator.evaluate_qte_multiplier(
		accuracy,
		skill.qte_config,
		target.equipment_modifiers
	)
	var def_mult: float = float(eval_res.get("multiplier", 1.0))
	var tier_label: String = str(eval_res.get("tier", success_tier))
	_resolve_enemy_attack(def_mult, tier_label)

func _resolve_enemy_attack(def_mult: float, qte_tier: String) -> void:
	var attacker: Combatant = _context.enemy_pending_actor
	var skill: SkillData = _context.enemy_pending_skill
	var target: Combatant = _context.enemy_pending_target
	if attacker == null or skill == null or target == null:
		_advance_after_enemy_attack()
		return
	
	var calc: Dictionary = BattleCalculator.calculate_damage(
		attacker,
		target,
		skill,
		null,
		1.0,
		def_mult,
		BattleTypes.TensionTier.LOCKED,
		_has_defense_qte
	)
	var dmg: int = int(calc.get("final_damage", 0))
	var take_res: Dictionary = target.take_damage(dmg)
	var actual_dmg: int = int(take_res.get("damage_taken", 0))
	
	if actual_dmg > 0:
		attacker.resources.add_rage_on_damage_dealt()
		if target.is_player_controlled:
			target.restore_resource(BattleTypes.ResourceType.TENSION, 15)
	elif bool(calc.get("was_blocked", false)) and target.is_player_controlled:
		target.restore_resource(BattleTypes.ResourceType.TENSION, 10)
	
	var logs: PackedStringArray = PackedStringArray()
	var qte_info: String = "[Защита QTE: %s] " % qte_tier if _has_defense_qte else ""
	var block_pct: int = roundi(float(calc.get("block_ratio", 0.0)) * 100.0)
	var block_tag: String = ""
	if bool(calc.get("guard_broken", false)):
		block_tag = " [ПРОБИТИЕ БЛОКА!]"
	elif bool(calc.get("was_blocked", false)):
		block_tag = " [БЛОК %d%%]" % block_pct
	var no_guard_tag: String = " [ОТКРЫТАЯ СТОЙКА!]" if bool(calc.get("no_guard_triggered", false)) else ""
	
	logs.append("%s%s использует «%s» против %s: %d урона.%s%s" % [
		qte_info,
		attacker.display_name,
		skill.skill_name,
		target.display_name,
		actual_dmg,
		block_tag,
		no_guard_tag
	])
	
	# Провал ритм-QTE защиты (или схожих QTE) может наложить SLEEP / HYPNOSIS
	if _has_defense_qte and skill.qte_config != null and skill.qte_config.apply_status_on_fail and def_mult <= 0.5 and target.is_alive():
		target.apply_status(
			skill.qte_config.fail_status_to_apply,
			skill.qte_config.fail_status_duration,
			attacker.runtime_id
		)
		logs.append("%s получает статус %s!" % [target.display_name, BattleTypes.get_status_display_name(skill.qte_config.fail_status_to_apply)])
	elif skill.applies_status and target.is_alive() and randf() <= skill.status_apply_chance:
		target.apply_status(skill.status_to_apply, skill.status_duration_turns, attacker.runtime_id)
		logs.append("%s получает статус %s!" % [target.display_name, BattleTypes.get_status_display_name(skill.status_to_apply)])
	
	_refresh_ui()
	log_requested.emit(" ".join(logs))
	_advance_after_enemy_attack()

func _advance_after_enemy_attack() -> void:
	if _context.is_player_party_defeated():
		_context.battle_victory = false
		_context.battle_by_vow = false
		_context.outcome_message = "Все герои пали в бою..."
		transition_requested.emit(&"battle_end")
		return
	
	if _context.is_enemy_party_defeated():
		_context.battle_victory = true
		_context.battle_by_vow = false
		_context.outcome_message = "Все противники повержены!"
		transition_requested.emit(&"battle_end")
		return
	
	if _context.advance_to_next_alive_enemy():
		transition_requested.emit(&"enemy_turn")
	else:
		transition_requested.emit(&"turn_resolution")
