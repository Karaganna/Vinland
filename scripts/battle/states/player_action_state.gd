# res://scripts/battle/states/player_action_state.gd
class_name PlayerActionState
extends BaseBattleState

## Выполнение действия активного бойца игрока (атака, навык, блок, ульта и QTE)
var _waiting_for_qte: bool = false

func get_state_id() -> StringName:
	return &"player_action"

func enter() -> void:
	if _context == null:
		return
	
	_waiting_for_qte = false
	var actor: Combatant = _context.get_active_player()
	if actor == null:
		_advance_after_action()
		return
	
	actor.clear_block_stance()
	
	if _context.pending_action_type == BattleTypes.ActionType.BLOCK:
		var gained_energy: int = actor.enter_block_stance()
		_refresh_ui()
		log_requested.emit("%s встает в защитный блок (+%d Энергии)." % [actor.display_name, gained_energy])
		_advance_after_action()
		return
	
	var skill: SkillData = _context.pending_skill
	if skill == null:
		_advance_after_action()
		return
	
	# Списание ресурсов (либо шкалы Напряжения для Ульты)
	if skill.is_ultimate:
		_context.pending_tension_tier = actor.resources.consume_tension_for_ultimate()
	elif skill.resource_cost > 0:
		if not actor.resources.spend_resource(skill.resource_type, skill.resource_cost):
			log_requested.emit("Недостаточно ресурса для «%s»!" % skill.skill_name)
			transition_requested.emit(&"player_select")
			return
	
	if skill.energy_restore_on_use > 0:
		actor.restore_resource(BattleTypes.ResourceType.ENERGY, skill.energy_restore_on_use)
	
	# Накладываем NO_GUARD на применяющего до конца хода
	if skill.is_no_guard():
		actor.apply_status(
			BattleTypes.StatusType.NO_GUARD,
			1,
			actor.runtime_id,
			skill.no_guard_incoming_multiplier,
			skill.no_guard_guaranteed_crit
		)
	
	# Навыки на себя (например, TAUNT или RAGE_TO_HEAL)
	if skill.target_side == BattleTypes.TargetSide.SELF:
		_resolve_self_skill(actor, skill)
		_advance_after_action()
		return
	
	# Атакующее QTE, если требуется навыком
	if skill.requires_qte and skill.qte_config != null:
		_waiting_for_qte = true
		qte_requested.emit(skill.qte_config, false)
		return
	
	_resolve_offensive_action(1.0, "")

func exit() -> void:
	_waiting_for_qte = false
	if _context != null:
		_context.clear_pending_player_action()

func on_qte_completed(accuracy: float, success_tier: String) -> void:
	if not _waiting_for_qte:
		return
	_waiting_for_qte = false
	
	var actor: Combatant = _context.get_active_player()
	var skill: SkillData = _context.pending_skill
	if actor == null or skill == null:
		_advance_after_action()
		return
	
	var eval_res: Dictionary = BattleCalculator.evaluate_qte_multiplier(
		accuracy,
		skill.qte_config,
		actor.equipment_modifiers
	)
	var mult: float = float(eval_res.get("multiplier", 1.0))
	var tier_label: String = str(eval_res.get("tier", success_tier))
	_resolve_offensive_action(mult, tier_label)

func _resolve_self_skill(actor: Combatant, skill: SkillData) -> void:
	var logs: PackedStringArray = PackedStringArray()
	logs.append("%s использует «%s»!" % [actor.display_name, skill.skill_name])
	
	if skill.is_rage_to_heal():
		var conv: Dictionary = actor.resources.convert_rage_to_heal(skill.rage_to_heal_ratio)
		var rage_spent: int = int(conv.get("rage_spent", 0))
		var total_heal: int = int(conv.get("heal_amount", 0)) + skill.base_heal_amount
		var healed: int = actor.heal_hp(total_heal, false)
		logs.append("Потрачено %d Ярости → восстановлено %d HP." % [rage_spent, healed])
	elif skill.base_heal_amount > 0:
		var healed: int = actor.heal_hp(skill.base_heal_amount, false)
		logs.append("Восстановлено %d HP." % healed)
	
	if skill.applies_status:
		actor.apply_status(skill.status_to_apply, skill.status_duration_turns, actor.runtime_id)
		logs.append("Наложен эффект: %s." % BattleTypes.get_status_display_name(skill.status_to_apply))
	
	actor.restore_resource(BattleTypes.ResourceType.TENSION, 10)
	_refresh_ui()
	log_requested.emit(" ".join(logs))

func _resolve_offensive_action(qte_mult: float, qte_tier: String) -> void:
	var actor: Combatant = _context.get_active_player()
	var skill: SkillData = _context.pending_skill
	if actor == null or skill == null:
		_advance_after_action()
		return
	
	var targets: Array[Combatant] = []
	if skill.target_side == BattleTypes.TargetSide.ALL_ENEMIES:
		targets = _context.get_alive_enemies()
	else:
		var single_target: Combatant = _context.pending_target
		if single_target == null or not single_target.is_alive():
			var alive_enemies: Array[Combatant] = _context.get_alive_enemies()
			if not alive_enemies.is_empty():
				single_target = alive_enemies[0]
		if single_target != null:
			targets.append(single_target)
	
	var msg_parts: PackedStringArray = PackedStringArray()
	var qte_prefix: String = "[QTE: %s x%.1f] " % [qte_tier, qte_mult] if not qte_tier.is_empty() else ""
	
	var dealt_any_damage: bool = false
	for target: Combatant in targets:
		var part: EnemyPartState = _context.pending_target_part if targets.size() == 1 else null
		var calc: Dictionary = BattleCalculator.calculate_damage(
			actor,
			target,
			skill,
			part,
			qte_mult,
			1.0,
			_context.pending_tension_tier,
			false
		)
		var dmg: int = int(calc.get("final_damage", 0))
		var take_res: Dictionary = target.take_damage(dmg, part)
		var actual_dmg: int = int(take_res.get("damage_taken", 0))
		if actual_dmg > 0:
			dealt_any_damage = true
		
		var part_suffix: String = " (%s)" % part.data.part_name if part != null and part.data != null else ""
		var crit_tag: String = " КРИТ!" if bool(calc.get("is_crit", false)) else ""
		var break_tag: String = " ПРОБИТИЕ БЛОКА!" if bool(calc.get("guard_broken", false)) else ""
		msg_parts.append("%s%s применяет «%s» по %s%s: %d урона.%s%s" % [
			qte_prefix,
			actor.display_name,
			skill.skill_name,
			target.display_name,
			part_suffix,
			actual_dmg,
			crit_tag,
			break_tag
		])
		
		if bool(take_res.get("part_broken", false)):
			if part != null and part.data != null and not part.data.break_message.is_empty():
				msg_parts.append(part.data.break_message)
			elif bool(take_res.get("triggered_stagger", false)):
				msg_parts.append("%s получает ОШЕЛОМЛЕНИЕ!" % target.display_name)
		
		if skill.applies_status and target.is_alive() and randf() <= skill.status_apply_chance:
			target.apply_status(skill.status_to_apply, skill.status_duration_turns, actor.runtime_id)
			msg_parts.append("Наложен статус %s." % BattleTypes.get_status_display_name(skill.status_to_apply))
	
	if dealt_any_damage:
		actor.resources.add_rage_on_damage_dealt()
		if not skill.is_ultimate:
			actor.restore_resource(BattleTypes.ResourceType.TENSION, 15)
	
	_refresh_ui()
	log_requested.emit(" ".join(msg_parts))
	_advance_after_action()

func _advance_after_action() -> void:
	if _context.is_enemy_party_defeated():
		_context.battle_victory = true
		_context.battle_by_vow = false
		_context.outcome_message = "Все противники повержены!"
		transition_requested.emit(&"battle_end")
		return
	
	if _context.is_enemy_party_pacified():
		_context.battle_victory = true
		_context.battle_by_vow = true
		_context.outcome_message = "Достигнуто примирение Заветом!"
		transition_requested.emit(&"battle_end")
		return
	
	if _context.is_player_party_defeated():
		_context.battle_victory = false
		_context.battle_by_vow = false
		_context.outcome_message = "Отряд игрока пал в бою..."
		transition_requested.emit(&"battle_end")
		return
	
	if _context.advance_to_next_alive_player():
		transition_requested.emit(&"player_select")
	else:
		_context.reset_enemy_turn_cursor()
		transition_requested.emit(&"enemy_turn")
