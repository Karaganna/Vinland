# res://scripts/battle/states/player_action_state.gd
class_name PlayerActionState
extends BaseBattleState

## Выполнение действия активного бойца игрока (атака, навык, блок, предмет, ульта и QTE)
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
		_emit_log("%s встает в защитный блок (+%d Энергии)." % [actor.display_name, gained_energy])
		_advance_after_action()
		return
	
	if _context.pending_action_type == BattleTypes.ActionType.ITEM:
		_resolve_consumable_action(actor, _context.pending_consumable)
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
			_emit_log("Недостаточно ресурса для «%s»!" % skill.skill_name)
			_emit_transition(&"player_select")
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
	
	# Навыки на себя (например, TAUNT, RAGE_TO_HEAL или «Стена щитов»)
	if skill.target_side == BattleTypes.TargetSide.SELF:
		_resolve_self_skill(actor, skill)
		_advance_after_action()
		return
	
	# Атакующее QTE, если требуется навыком
	if skill.requires_qte and skill.qte_config != null:
		_waiting_for_qte = true
		_emit_qte(skill.qte_config, false)
		return
	
	_resolve_offensive_action(1.0, "", false)

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
		actor.equipment_modifiers,
		actor.get_effective_qte_override()
	)
	var mult: float = float(eval_res.get("multiplier", 1.0))
	var tier_label: String = str(eval_res.get("tier", success_tier))
	var force_crit: bool = bool(eval_res.get("guaranteed_crit", false))
	_resolve_offensive_action(mult, tier_label, force_crit)

func _resolve_consumable_action(actor: Combatant, item: ConsumableItemData) -> void:
	if item == null or GameManager == null or GameManager.inventory == null:
		_emit_log("Не выбран расходник для применения.")
		_emit_transition(&"player_select")
		return
	
	if not GameManager.inventory.remove_item(item.item_id, 1):
		_emit_log("Расходник «%s» закончился!" % item.display_name)
		_emit_transition(&"player_select")
		return
	
	var logs: PackedStringArray = PackedStringArray()
	logs.append("%s использует «%s»." % [actor.display_name, item.display_name])
	
	if item.heal_hp > 0:
		var healed: int = actor.heal_hp(item.heal_hp, true)
		logs.append("+%d HP." % healed)
	
	if item.restore_resource_amount > 0:
		var restored: int = actor.restore_resource(item.restore_resource_type, item.restore_resource_amount)
		logs.append("+%d %s." % [restored, BattleTypes.get_resource_display_name(item.restore_resource_type)])
	
	if not item.cure_statuses.is_empty():
		var cured_names: PackedStringArray = PackedStringArray()
		for st: BattleTypes.StatusType in item.cure_statuses:
			if actor.has_status(st):
				actor.remove_status(st)
				cured_names.append(BattleTypes.get_status_display_name(st))
		if not cured_names.is_empty():
			logs.append("Сняты эффекты: %s." % ", ".join(cured_names))
	
	_refresh_ui()
	_emit_log(" ".join(logs))
	_advance_after_action()

func _resolve_self_skill(actor: Combatant, skill: SkillData) -> void:
	var logs: PackedStringArray = PackedStringArray()
	logs.append("%s использует «%s»!" % [actor.display_name, skill.skill_name])
	
	if skill.grants_block_stance:
		var block_energy: int = actor.enter_block_stance(15)
		logs.append("Встаёт в защитную стойку (+%d Энергии)." % block_energy)
	
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
	_emit_log(" ".join(logs))

func _resolve_offensive_action(qte_mult: float, qte_tier: String, force_crit: bool = false) -> void:
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
	var hits: int = maxi(1, skill.hit_count)
	
	var dealt_any_damage: bool = false
	for target: Combatant in targets:
		var part: EnemyPartState = _context.pending_target_part if targets.size() == 1 else null
		var total_actual_dmg: int = 0
		var any_crit: bool = false
		var any_guard_broken: bool = false
		var broke_part_now: bool = false
		var triggered_stagger_now: bool = false
		var hits_executed: int = 0
		
		for _hit_idx: int in range(hits):
			if not target.is_alive():
				break
			var calc: Dictionary = BattleCalculator.calculate_damage(
				actor,
				target,
				skill,
				part,
				qte_mult,
				1.0,
				_context.pending_tension_tier,
				false,
				force_crit
			)
			var dmg: int = int(calc.get("final_damage", 0))
			var take_res: Dictionary = target.take_damage(dmg, part)
			var actual_dmg: int = int(take_res.get("damage_taken", 0))
			hits_executed += 1
			total_actual_dmg += actual_dmg
			if actual_dmg > 0:
				dealt_any_damage = true
			if bool(calc.get("is_crit", false)):
				any_crit = true
			if bool(calc.get("guard_broken", false)):
				any_guard_broken = true
			if bool(take_res.get("part_broken", false)):
				broke_part_now = true
			if bool(take_res.get("triggered_stagger", false)):
				triggered_stagger_now = true
		
		var part_suffix: String = " (%s)" % part.data.part_name if part != null and part.data != null else ""
		var hits_suffix: String = " (%d уд.)" % hits_executed if hits_executed > 1 else ""
		var crit_tag: String = " КРИТ!" if any_crit else ""
		var break_tag: String = " ПРОБИТИЕ БЛОКА!" if any_guard_broken else ""
		msg_parts.append("%s%s применяет «%s»%s по %s%s: %d урона.%s%s" % [
			qte_prefix,
			actor.display_name,
			skill.skill_name,
			hits_suffix,
			target.display_name,
			part_suffix,
			total_actual_dmg,
			crit_tag,
			break_tag
		])
		
		if broke_part_now:
			if part != null and part.data != null and not part.data.break_message.is_empty():
				msg_parts.append(part.data.break_message)
			elif triggered_stagger_now:
				msg_parts.append("%s получает ОШЕЛОМЛЕНИЕ!" % target.display_name)
		
		if skill.applies_status and target.is_alive() and randf() <= skill.status_apply_chance:
			target.apply_status(skill.status_to_apply, skill.status_duration_turns, actor.runtime_id)
			msg_parts.append("Наложен статус %s." % BattleTypes.get_status_display_name(skill.status_to_apply))
	
	if dealt_any_damage:
		actor.resources.add_rage_on_damage_dealt()
		if not skill.is_ultimate:
			actor.restore_resource(BattleTypes.ResourceType.TENSION, 15)
	
	_refresh_ui()
	_emit_log(" ".join(msg_parts))
	_advance_after_action()

func _advance_after_action() -> void:
	if _context.is_enemy_party_defeated():
		_context.battle_victory = true
		_context.battle_by_vow = false
		_context.outcome_message = "Все противники повержены!"
		_emit_transition(&"battle_end")
		return
	
	if _context.is_enemy_party_pacified():
		_context.battle_victory = true
		_context.battle_by_vow = true
		_context.outcome_message = "Достигнуто примирение Заветом!"
		_emit_transition(&"battle_end")
		return
	
	if _context.is_player_party_defeated():
		_context.battle_victory = false
		_context.battle_by_vow = false
		_context.outcome_message = "Отряд игрока пал в бою..."
		_emit_transition(&"battle_end")
		return
	
	if _context.advance_to_next_alive_player():
		_emit_transition(&"player_select")
	else:
		_context.reset_enemy_turn_cursor()
		_emit_transition(&"enemy_turn")
