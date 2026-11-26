# res://scripts/battle/states/defense_qte_state.gd
class_name DefenseQTEState
extends BaseBattleState

## Обработка защитного QTE, перехватов стоек (COVER_ALLY, INTERCEPT_MELEE, PARRY_STANCE) и блока
var _waiting_for_qte: bool = false
var _has_defense_qte: bool = false
var _is_parry_stance_qte: bool = false
var _active_qte_config: QTEConfigData = null
var _cover_damage_scale: float = 1.0
var _pre_logs: PackedStringArray = PackedStringArray()

func get_state_id() -> StringName:
	return &"defense_qte"

func enter() -> void:
	if _context == null:
		return
	
	_waiting_for_qte = false
	_has_defense_qte = false
	_is_parry_stance_qte = false
	_active_qte_config = null
	_cover_damage_scale = 1.0
	_pre_logs = PackedStringArray()
	
	var attacker: Combatant = _context.enemy_pending_actor
	var skill: SkillData = _context.enemy_pending_skill
	var target: Combatant = _context.enemy_pending_target
	
	if attacker == null or skill == null or target == null:
		_advance_after_enemy_attack()
		return
	
	# 1. Перехват удара союзником в стойке «Начеку» (COVER_ALLY)
	var protector: Combatant = _context.find_cover_protector_for(target)
	if protector != null:
		_pre_logs.append("🛡 %s прикрывает %s («Начеку»)!" % [protector.display_name, target.display_name])
		_context.enemy_pending_target = protector
		target = protector
		_cover_damage_scale = 0.70
	
	# 2. Стойка копья «Держать дистанцию» (INTERCEPT_MELEE) встречает контактную атаку врага контрударом
	if target.has_status(BattleTypes.StatusType.INTERCEPT_MELEE) and skill.is_melee_attack() and not target.is_incapacitated():
		var counter_power: int = maxi(4, roundi(float(target.get_effective_attack()) * 0.75))
		var counter_res: Dictionary = attacker.take_damage(counter_power)
		var dealt_counter: int = int(counter_res.get("damage_taken", 0))
		if attacker.is_alive():
			attacker.apply_status(BattleTypes.StatusType.UNBALANCED, 1, target.runtime_id)
		_cover_damage_scale *= 0.65
		_pre_logs.append("⚡ %s встречает выпад на дистанции: %d урона врагу!" % [target.display_name, dealt_counter])
		if not attacker.is_alive():
			_refresh_ui()
			log_requested.emit(" ".join(_pre_logs))
			_advance_after_enemy_attack()
			return
	
	# 3. Стойка хольмсверда «Вызов» (PARRY_STANCE) требует QTE «Круг» на каждую вражескую атаку
	if (
		target.is_player_controlled
		and target.has_status(BattleTypes.StatusType.PARRY_STANCE)
		and not target.is_incapacitated()
		and not skill.has_tag(BattleTypes.SkillTag.UNBLOCKABLE)
	):
		_waiting_for_qte = true
		_has_defense_qte = true
		_is_parry_stance_qte = true
		_active_qte_config = _create_parry_circle_qte_config()
		log_requested.emit("%s атакует («%s»)! Парируйте в стойке «Вызов» (Круг)!" % [attacker.display_name, skill.skill_name])
		qte_requested.emit(_active_qte_config, true)
		return
	
	if skill.requires_qte and skill.qte_config != null and target.is_player_controlled:
		_waiting_for_qte = true
		_has_defense_qte = true
		_active_qte_config = skill.qte_config
		log_requested.emit("%s применяет «%s»! Защититесь в QTE!" % [attacker.display_name, skill.skill_name])
		qte_requested.emit(_active_qte_config, true)
		return
	
	_resolve_enemy_attack(1.0, "", 0)

func exit() -> void:
	_waiting_for_qte = false
	_has_defense_qte = false
	_is_parry_stance_qte = false
	_active_qte_config = null
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
	
	var cfg: QTEConfigData = _active_qte_config if _active_qte_config != null else skill.qte_config
	var eval_res: Dictionary = BattleCalculator.evaluate_qte_multiplier(
		accuracy,
		cfg,
		target.equipment_modifiers,
		target.get_effective_qte_override()
	)
	var def_mult: float = float(eval_res.get("multiplier", 1.0))
	var tier_label: String = str(eval_res.get("tier", success_tier))
	var miss_t: float = float(eval_res.get("miss_threshold", 0.30))
	var ham_delta: int = target.resources.apply_hamingja_qte_result(accuracy, miss_t)
	_resolve_enemy_attack(def_mult, tier_label, ham_delta)

func _create_parry_circle_qte_config() -> QTEConfigData:
	var cfg: QTEConfigData = QTEConfigData.new()
	cfg.qte_type = BattleTypes.QTEType.CIRCULAR_SKILL_CHECK
	cfg.duration_seconds = 2.2
	cfg.cursor_speed = 1.55
	cfg.success_zone_width = 0.24
	cfg.perfect_zone_width = 0.09
	return cfg

func _resolve_enemy_attack(def_mult: float, qte_tier: String, ham_delta: int) -> void:
	var attacker: Combatant = _context.enemy_pending_actor
	var skill: SkillData = _context.enemy_pending_skill
	var target: Combatant = _context.enemy_pending_target
	if attacker == null or skill == null or target == null:
		_advance_after_enemy_attack()
		return
	
	var logs: PackedStringArray = PackedStringArray()
	for pre_msg: String in _pre_logs:
		logs.append(pre_msg)
	if ham_delta != 0:
		logs.append("[Хамингья %+d]" % ham_delta)
	
	# Успешное парирование в стойке «Вызов» (PARRY_STANCE) гасит удар и возвращает контратаку
	if _is_parry_stance_qte and def_mult >= 1.0:
		var parry_ratio: float = 1.0 if def_mult >= 1.4 else 0.80
		var raw_calc: Dictionary = BattleCalculator.calculate_damage(attacker, target, skill, null, 1.0, 1.0, BattleTypes.TensionTier.LOCKED, false)
		var reduced_dmg: int = roundi(float(int(raw_calc.get("final_damage", 0))) * (1.0 - parry_ratio) * _cover_damage_scale)
		var take_parry: Dictionary = target.take_damage(reduced_dmg)
		var taken_parry: int = int(take_parry.get("damage_taken", 0))
		
		var riposte_power: int = maxi(5, roundi(float(target.get_effective_attack()) * (1.25 if def_mult >= 1.4 else 0.95)))
		var riposte_res: Dictionary = attacker.take_damage(riposte_power)
		var riposte_dmg: int = int(riposte_res.get("damage_taken", 0))
		target.restore_resource(BattleTypes.ResourceType.TENSION, 15)
		logs.append("[Парирование: %s] %s отражает «%s» (вх. урон: %d) и контратакует %s на %d урона!" % [
			qte_tier,
			target.display_name,
			skill.skill_name,
			taken_parry,
			attacker.display_name,
			riposte_dmg
		])
		_refresh_ui()
		log_requested.emit(" ".join(logs))
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
	
	if bool(calc.get("missed_by_blind", false)):
		logs.append("%s промахивается по %s из-за ослепления!" % [attacker.display_name, target.display_name])
		_refresh_ui()
		log_requested.emit(" ".join(logs))
		_advance_after_enemy_attack()
		return
	
	var dmg: int = roundi(float(int(calc.get("final_damage", 0))) * _cover_damage_scale)
	var take_res: Dictionary = target.take_damage(dmg)
	var actual_dmg: int = int(take_res.get("damage_taken", 0))
	var absorbed_barrier: int = int(take_res.get("absorbed_by_barrier", 0))
	
	if skill.has_tag(BattleTypes.SkillTag.CAUSES_CALM):
		target.resources.decay_rage_on_control_status()
	
	if actual_dmg > 0:
		attacker.resources.add_rage_on_damage_dealt()
		if target.is_player_controlled:
			target.restore_resource(BattleTypes.ResourceType.TENSION, 15)
	elif bool(calc.get("was_blocked", false)) and target.is_player_controlled:
		target.restore_resource(BattleTypes.ResourceType.TENSION, 10)
	
	var qte_info: String = "[Защита QTE: %s] " % qte_tier if _has_defense_qte else ""
	var block_pct: int = roundi(float(calc.get("block_ratio", 0.0)) * 100.0)
	var block_tag: String = ""
	if bool(calc.get("shield_nullified_breath", false)):
		block_tag = " [ЩИТ ПОЛНОСТЬЮ ГАСИТ ДЫХАНИЕ!]"
	elif bool(calc.get("guard_broken", false)):
		block_tag = " [ПРОБИТИЕ БЛОКА!]"
	elif bool(calc.get("shield_full_proc", false)):
		block_tag = " [ПОЛНЫЙ БЛОК ЩИТОМ!]"
	elif bool(calc.get("shield_enhanced_proc", false)):
		block_tag = " [УСИЛЕННЫЙ БЛОК ЩИТОМ %d%%]" % block_pct
	elif bool(calc.get("was_blocked", false)):
		block_tag = " [БЛОК %d%%]" % block_pct
	var no_guard_tag: String = " [ОТКРЫТАЯ СТОЙКА!]" if bool(calc.get("no_guard_triggered", false)) else ""
	var barrier_tag: String = " [Барьер: -%d]" % absorbed_barrier if absorbed_barrier > 0 else ""
	
	logs.append("%s%s использует «%s» против %s: %d урона.%s%s%s" % [
		qte_info,
		attacker.display_name,
		skill.skill_name,
		target.display_name,
		actual_dmg,
		block_tag,
		no_guard_tag,
		barrier_tag
	])
	
	if _has_defense_qte and skill.qte_config != null and skill.qte_config.apply_status_on_fail and def_mult <= 0.5 and target.is_alive():
		target.apply_status(
			skill.qte_config.fail_status_to_apply,
			skill.qte_config.fail_status_duration,
			attacker.runtime_id
		)
		logs.append("%s получает статус %s!" % [target.display_name, BattleTypes.get_status_display_name(skill.qte_config.fail_status_to_apply)])
	elif skill.applies_status and actual_dmg > 0 and target.is_alive() and randf() <= skill.status_apply_chance:
		target.apply_status(
			skill.status_to_apply,
			skill.status_duration_turns,
			attacker.runtime_id,
			skill.status_magnitude,
			false,
			skill.status_stacks_to_apply,
			skill.status_is_permanent
		)
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
