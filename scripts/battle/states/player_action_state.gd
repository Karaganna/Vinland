# res://scripts/battle/states/player_action_state.gd
class_name PlayerActionState
extends BaseBattleState

## Выполнение действия активного бойца игрока (атака, навык, стойка, блок, предмет, ульта и QTE)
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
		actor.clear_weapon_stances()
		var gained_energy: int = actor.enter_block_stance()
		_refresh_ui()
		if gained_energy > 0:
			_emit_log("%s встаёт в защитный блок (+%d %s)." % [
				actor.display_name,
				gained_energy,
				actor.resources.get_working_display_name()
			])
		else:
			_emit_log("%s встаёт в защитный блок." % actor.display_name)
		_advance_after_action()
		return
	
	if _context.pending_action_type == BattleTypes.ActionType.ITEM:
		_resolve_consumable_action(actor, _context.pending_consumable)
		return
	
	# Если требуется перезарядка (например, после залпа парных самострелов), базовое действие перезаряжает оружие
	if _context.pending_action_type == BattleTypes.ActionType.ATTACK and actor.has_status(BattleTypes.StatusType.RELOAD_REQUIRED):
		actor.remove_status(BattleTypes.StatusType.RELOAD_REQUIRED)
		actor.restore_resource(BattleTypes.ResourceType.ENERGY, 15)
		_refresh_ui()
		_emit_log("%s перезаряжает оружие и готов к бою." % actor.display_name)
		_advance_after_action()
		return
	
	var skill: SkillData = _context.pending_skill
	if skill == null:
		_advance_after_action()
		return
	
	# Списание ресурса (маршрутизируется через единый «Поток» у ГГ или основной бак у рекрута)
	if skill.is_ultimate:
		_context.pending_tension_tier = actor.resources.consume_tension_for_ultimate()
	elif skill.resource_cost > 0:
		if not actor.resources.spend_resource(skill.resource_type, skill.resource_cost):
			_emit_log("Недостаточно ресурса (%s) для «%s»!" % [
				actor.resources.get_working_display_name(),
				skill.skill_name
			])
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
	
	# Запуск QTE, если требуется умением (как для атакующих, так и для защитных/стоечных умений вроде Скьяльдборга)
	if skill.requires_qte and skill.qte_config != null:
		_waiting_for_qte = true
		_emit_qte(skill.qte_config, false)
		return
	
	if _is_ally_or_self_skill(skill):
		_resolve_support_or_self_skill(actor, skill, 1.0, "")
		_advance_after_action()
		return
	
	_resolve_offensive_action(1.0, "", false, 0)

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
	var miss_t: float = float(eval_res.get("miss_threshold", 0.30))
	
	# Обновление Хамингьи от точности QTE (+при 90-100%, -при промахе)
	var ham_delta: int = actor.resources.apply_hamingja_qte_result(accuracy, miss_t)
	
	if _is_ally_or_self_skill(skill):
		_resolve_support_or_self_skill(actor, skill, mult, tier_label, ham_delta)
		_advance_after_action()
		return
	
	_resolve_offensive_action(mult, tier_label, force_crit, ham_delta)

func _is_ally_or_self_skill(skill: SkillData) -> bool:
	if skill == null:
		return false
	return (
		skill.target_side == BattleTypes.TargetSide.SELF
		or skill.target_side == BattleTypes.TargetSide.ALLY
		or skill.target_side == BattleTypes.TargetSide.ALL_ALLIES
	)

func _resolve_consumable_action(actor: Combatant, item: ConsumableItemData) -> void:
	if item == null or GameManager == null or GameManager.inventory == null:
		_emit_log("Не выбран расходник для применения.")
		_emit_transition(&"player_select")
		return
	
	if not GameManager.inventory.remove_item(item.item_id, 1):
		_emit_log("Расходник «%s» закончился!" % item.display_name)
		_emit_transition(&"player_select")
		return
	
	var target: Combatant = _context.pending_target if _context.pending_target != null and _context.pending_target.is_alive() else actor
	var logs: PackedStringArray = PackedStringArray()
	if target == actor:
		logs.append("%s использует «%s»." % [actor.display_name, item.display_name])
	else:
		logs.append("%s применяет «%s» на %s." % [actor.display_name, item.display_name, target.display_name])
	
	if item.heal_hp > 0:
		var healed: int = target.heal_hp(item.heal_hp, true)
		logs.append("+%d HP." % healed)
	
	if item.restore_resource_amount > 0:
		var restored: int = target.restore_resource(item.restore_resource_type, item.restore_resource_amount)
		logs.append("+%d %s." % [restored, BattleTypes.get_resource_display_name(item.restore_resource_type)])
	
	if not item.cure_statuses.is_empty():
		var cured_names: PackedStringArray = PackedStringArray()
		for st: BattleTypes.StatusType in item.cure_statuses:
			if target.has_status(st):
				target.remove_status(st)
				cured_names.append(BattleTypes.get_status_display_name(st))
		if not cured_names.is_empty():
			logs.append("Сняты эффекты: %s." % ", ".join(cured_names))
	
	_refresh_ui()
	_emit_log(" ".join(logs))
	_advance_after_action()

func _resolve_support_or_self_skill(
	actor: Combatant,
	skill: SkillData,
	qte_mult: float,
	qte_tier: String,
	ham_delta: int = 0
) -> void:
	var logs: PackedStringArray = PackedStringArray()
	var qte_prefix: String = "[QTE: %s] " % qte_tier if not qte_tier.is_empty() else ""
	logs.append("%s%s использует «%s»!" % [qte_prefix, actor.display_name, skill.skill_name])
	if ham_delta != 0:
		logs.append("[Хамингья %+d]" % ham_delta)
	
	var qte_scale: float = clampf(qte_mult, 0.4, 1.5) if skill.requires_qte else 1.0
	var ham_scale: float = actor.resources.get_hamingja_power_multiplier()
	
	var recipients: Array[Combatant] = []
	if skill.target_side == BattleTypes.TargetSide.ALL_ALLIES:
		recipients = _context.get_alive_players()
	elif skill.target_side == BattleTypes.TargetSide.ALLY:
		var chosen: Combatant = _context.pending_target
		if chosen != null and (chosen.is_alive() or skill.revives_fallen_ally or skill.can_target_fallen_ally):
			recipients.append(chosen)
		else:
			recipients.append(actor)
	else:
		recipients.append(actor)
	
	# Оружейные стойки (COVER_ALLY, PARRY_STANCE, INTERCEPT_MELEE) без активации базового Блока
	if skill.enters_stance:
		var protected_id: String = ""
		if skill.stance_status == BattleTypes.StatusType.COVER_ALLY and _context.pending_target != null and _context.pending_target != actor:
			protected_id = _context.pending_target.runtime_id
		actor.apply_status(
			skill.stance_status,
			skill.stance_duration_turns,
			actor.runtime_id,
			qte_scale,
			false,
			1,
			false,
			0,
			protected_id
		)
		if not protected_id.is_empty() and _context.pending_target != null:
			logs.append("Прикрывает союзника: %s." % _context.pending_target.display_name)
		else:
			logs.append("Активна стойка: %s." % BattleTypes.get_status_display_name(skill.stance_status))
	
	# Снижение входящего урона по отряду (например, от «Скьяльдборга») без базового Блока
	if skill.applies_ally_ward and qte_mult > 0.0:
		var ward_mag: float = clampf(skill.ally_ward_damage_reduction * qte_scale, 0.10, 0.65)
		for ally: Combatant in _context.get_alive_players():
			ally.apply_status(
				BattleTypes.StatusType.WARD_AURA,
				skill.ally_ward_duration_turns,
				actor.runtime_id,
				ward_mag
			)
		logs.append("Защита отряда -%d%% вх. урона (%d х.)." % [roundi(ward_mag * 100.0), skill.ally_ward_duration_turns])
	
	# Исцеление, воскрешение павшего и поглощающий барьер
	if skill.revives_fallen_ally and qte_mult > 0.0:
		var revive_amt: int = maxi(1, roundi(float(skill.base_heal_amount) * qte_scale * ham_scale))
		for rec: Combatant in recipients:
			var revived_val: int = rec.revive_hp(revive_amt)
			logs.append("%s возвращается в строй (+%d HP)!" % [rec.display_name, revived_val])
	elif skill.is_rage_to_heal():
		var conv: Dictionary = actor.resources.convert_rage_to_heal(skill.rage_to_heal_ratio)
		var rage_spent: int = int(conv.get("rage_spent", 0))
		var total_heal: int = roundi(float(int(conv.get("heal_amount", 0)) + skill.base_heal_amount) * qte_scale)
		var healed: int = actor.heal_hp(total_heal, false, false)
		logs.append("Сожжено %d Ярости → +%d HP." % [rage_spent, healed])
	elif skill.base_heal_amount > 0 and qte_mult > 0.0:
		var scaled_heal: int = maxi(1, roundi(float(skill.base_heal_amount) * qte_scale * ham_scale))
		for rec: Combatant in recipients:
			var is_ext: bool = rec != actor
			var healed: int = rec.heal_hp(scaled_heal, is_ext, true)
			logs.append("%s: +%d HP." % [rec.display_name, healed])
	
	if skill.shield_barrier_amount > 0 and qte_mult > 0.0:
		var barrier_val: int = maxi(1, roundi(float(skill.shield_barrier_amount) * qte_scale * ham_scale))
		for rec: Combatant in recipients:
			rec.apply_status(
				BattleTypes.StatusType.SHIELD_BARRIER,
				maxi(1, skill.status_duration_turns),
				actor.runtime_id,
				1.0,
				false,
				1,
				false,
				barrier_val
			)
		logs.append("Барьер +%d прочности." % barrier_val)
	
	if skill.applies_status and qte_mult > 0.0:
		if skill.status_to_apply == BattleTypes.StatusType.TAUNT:
			actor.apply_status(BattleTypes.StatusType.TAUNT, skill.status_duration_turns, actor.runtime_id)
			logs.append("Наложен эффект: Провокация.")
		else:
			for rec: Combatant in recipients:
				rec.apply_status(
					skill.status_to_apply,
					skill.status_duration_turns,
					actor.runtime_id,
					skill.status_magnitude,
					false,
					skill.status_stacks_to_apply,
					skill.status_is_permanent
				)
			logs.append("Наложен эффект: %s." % BattleTypes.get_status_display_name(skill.status_to_apply))
	
	actor.restore_resource(BattleTypes.ResourceType.TENSION, 10)
	_refresh_ui()
	_emit_log(" ".join(logs))

func _resolve_offensive_action(
	qte_mult: float,
	qte_tier: String,
	force_crit: bool = false,
	ham_delta: int = 0
) -> void:
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
	
	# Снимаем пороговые пассивки оружия ГГ ДО/ВО ВРЕМЯ удара (например, Меч из крови дракона при Потоке >= 90%)
	var flow_passive_items: Array[EquipmentItemData] = actor.get_triggered_flow_threshold_items()
	
	var msg_parts: PackedStringArray = PackedStringArray()
	var qte_prefix: String = "[QTE: %s x%.1f] " % [qte_tier, qte_mult] if not qte_tier.is_empty() else ""
	var hits: int = maxi(1, skill.hit_count)
	
	# Точный учет числа попаданий из QTE «Серия» (SERIES_CHAIN) и суммы граней «Броска» (DICE_ROLL)
	if bool(_context.last_qte_metadata.get("is_series", false)):
		var series_hits: int = int(_context.last_qte_metadata.get("series_hits", 0))
		var series_max: int = int(_context.last_qte_metadata.get("series_max", hits))
		if series_hits <= 0:
			var fail_ham: String = " [Хамингья %+d]" % ham_delta if ham_delta != 0 else ""
			_refresh_ui()
			_emit_log("%s срывает серию «%s» на первом ударе (0/%d)!%s" % [
				actor.display_name,
				skill.skill_name,
				series_max,
				fail_ham
			])
			_advance_after_action()
			return
		hits = series_hits
		qte_prefix = "[Серия %d/%d · %s] " % [series_hits, series_max, qte_tier]
	elif _context.last_qte_metadata.has("dice_sum"):
		qte_prefix = "[Бросок %d/%d · %s x%.1f] " % [
			int(_context.last_qte_metadata.get("dice_sum", 0)),
			int(_context.last_qte_metadata.get("dice_max", 18)),
			qte_tier,
			qte_mult
		]
	
	if ham_delta != 0:
		qte_prefix += "[Хамингья %+d] " % ham_delta
	
	var dealt_any_damage: bool = false
	for target: Combatant in targets:
		var part: EnemyPartState = _context.pending_target_part if targets.size() == 1 else null
		var total_actual_dmg: int = 0
		var total_absorbed: int = 0
		var any_crit: bool = false
		var any_guard_broken: bool = false
		var any_blind_miss: bool = false
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
			if bool(calc.get("missed_by_blind", false)):
				any_blind_miss = true
				continue
			var dmg: int = int(calc.get("final_damage", 0))
			var take_res: Dictionary = target.take_damage(dmg, part)
			var actual_dmg: int = int(take_res.get("damage_taken", 0))
			total_absorbed += int(take_res.get("absorbed_by_barrier", 0))
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
		
		if hits_executed == 0 and any_blind_miss:
			msg_parts.append("%s%s промахивается по %s из-за ослепления!" % [qte_prefix, actor.display_name, target.display_name])
			continue
		
		var part_suffix: String = " (%s)" % part.data.part_name if part != null and part.data != null else ""
		var hits_suffix: String = " (%d уд.)" % hits_executed if hits_executed > 1 else ""
		var crit_tag: String = " КРИТ!" if any_crit else ""
		var break_tag: String = " ПРОБИТИЕ БЛОКА!" if any_guard_broken else ""
		var absorb_tag: String = " [Барьер: -%d]" % total_absorbed if total_absorbed > 0 else ""
		msg_parts.append("%s%s применяет «%s»%s по %s%s: %d урона.%s%s%s" % [
			qte_prefix,
			actor.display_name,
			skill.skill_name,
			hits_suffix,
			target.display_name,
			part_suffix,
			total_actual_dmg,
			crit_tag,
			break_tag,
			absorb_tag
		])
		
		if broke_part_now:
			if part != null and part.data != null and not part.data.break_message.is_empty():
				msg_parts.append(part.data.break_message)
			elif triggered_stagger_now:
				msg_parts.append("%s получает ОШЕЛОМЛЕНИЕ!" % target.display_name)
		
		# Добивание выведенной из равновесия цели переводит UNBALANCED в KNOCKED_DOWN
		if skill.has_tag(BattleTypes.SkillTag.FINISH_UNBALANCED) and target.is_alive() and target.has_status(BattleTypes.StatusType.UNBALANCED):
			target.remove_status(BattleTypes.StatusType.UNBALANCED)
			target.apply_status(BattleTypes.StatusType.KNOCKED_DOWN, 1, actor.runtime_id)
			msg_parts.append("%s сбит с ног!" % target.display_name)
		
		if skill.applies_status and qte_mult > 0.0 and target.is_alive() and randf() <= skill.status_apply_chance:
			target.apply_status(
				skill.status_to_apply,
				skill.status_duration_turns,
				actor.runtime_id,
				skill.status_magnitude,
				false,
				skill.status_stacks_to_apply,
				skill.status_is_permanent
			)
			msg_parts.append("Наложен статус %s." % BattleTypes.get_status_display_name(skill.status_to_apply))
		
		# Пороговые пассивки Потока оружия ГГ (например, Ожог при Потоке >= 90%)
		if qte_mult > 0.0 and target.is_alive():
			for eq_passive: EquipmentItemData in flow_passive_items:
				target.apply_status(
					eq_passive.flow_threshold_status,
					eq_passive.flow_threshold_status_turns,
					actor.runtime_id,
					eq_passive.flow_threshold_status_magnitude
				)
				msg_parts.append("🔥 Поток пылает (%s) — наложен %s!" % [
					eq_passive.display_name,
					BattleTypes.get_status_display_name(eq_passive.flow_threshold_status)
				])
	
	if dealt_any_damage:
		actor.resources.add_rage_on_damage_dealt()
		# Повторно проверяем порог Потока, если Ярость достигла >= 90% прямо от этого удара
		if flow_passive_items.is_empty():
			var post_hit_passives: Array[EquipmentItemData] = actor.get_triggered_flow_threshold_items()
			if not post_hit_passives.is_empty():
				msg_parts.append("🔥 %s вспыхивает пламенем Потока!" % post_hit_passives[0].display_name)
		if not skill.is_ultimate:
			actor.restore_resource(BattleTypes.ResourceType.TENSION, 15)
	
	# Парные самострелы после двойного залпа требуют перезарядки в следующем действии
	if skill.skill_id == "synergy_twin_crossbows":
		actor.apply_status(BattleTypes.StatusType.RELOAD_REQUIRED, 2, actor.runtime_id, 1.0, false, 1, true)
		msg_parts.append("Требуется перезарядка самострелов.")
	
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
