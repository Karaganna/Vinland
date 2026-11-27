# res://scripts/battle/states/battle_start_state.gd
class_name BattleStartState
extends BaseBattleState

## Инициализация отрядов (с применением Старшего футарка, Резонанса, Оталы и Благословений Богов) и старт боя
func get_state_id() -> StringName:
	return &"battle_start"

func enter() -> void:
	if _context == null:
		return
	
	if GameManager != null:
		GameManager.ensure_party_initialized()
	
	if _context.player_party.is_empty() and _context.enemy_party.is_empty():
		if GameManager != null and GameManager.has_pending_battle():
			var overworld_players: Array[Combatant] = GameManager.build_player_party_for_battle()
			var pending_list: Array[EnemyData] = GameManager.get_pending_enemies()
			var overworld_enemies: Array[Combatant] = []
			for i: int in range(pending_list.size()):
				var enemy_res: EnemyData = pending_list[i]
				if enemy_res == null:
					continue
				var enemy_id: String = enemy_res.enemy_id.strip_edges()
				if enemy_id.is_empty():
					enemy_id = "enemy_%d" % (i + 1)
				elif pending_list.size() > 1:
					enemy_id = "%s_%d" % [enemy_id, i + 1]
				overworld_enemies.append(Combatant.from_enemy_data(enemy_res, enemy_id))
			if overworld_enemies.is_empty():
				overworld_enemies = BattleSandboxFactory.create_sandbox_enemy_party()
			_context.is_overworld_battle = true
			_context.setup_parties(overworld_players, overworld_enemies)
		else:
			_context.is_overworld_battle = false
			var sandbox_players: Array[Combatant] = (
				GameManager.build_player_party_for_battle()
				if GameManager != null
				else BattleSandboxFactory.create_sandbox_player_party()
			)
			_context.setup_parties(sandbox_players, BattleSandboxFactory.create_sandbox_enemy_party())
	else:
		if _context.player_party.is_empty():
			var fallback_players: Array[Combatant] = (
				GameManager.build_player_party_for_battle()
				if GameManager != null
				else BattleSandboxFactory.create_sandbox_player_party()
			)
			_context.setup_parties(fallback_players, _context.enemy_party)
		if _context.enemy_party.is_empty():
			_context.setup_parties(_context.player_party, BattleSandboxFactory.create_sandbox_enemy_party())
	
	# Применяем стартовые барьеры Печатей (Альгиз) и Благословений отряда
	var prog_notes: PackedStringArray = PackedStringArray()
	var resonated_names: PackedStringArray = PackedStringArray()
	var blessing_logged: bool = false
	for p: Combatant in _context.player_party:
		if p == null or not p.is_alive():
			continue
		if p.start_battle_barrier > 0:
			p.apply_status(BattleTypes.StatusType.SHIELD_BARRIER, 3, p.runtime_id, 1.0, false, 1, false, p.start_battle_barrier)
		if p.is_hero and not p.active_great_bind_name.is_empty():
			prog_notes.append("Ульта: %s" % p.active_great_bind_name)
		if p.has_resonance_active:
			resonated_names.append("%s (%s)" % [p.display_name, p.resonance_label])
		if not blessing_logged and not p.active_blessing_names.is_empty():
			prog_notes.append("Дар богов: %s" % ", ".join(p.active_blessing_names))
			blessing_logged = true
	
	if not resonated_names.is_empty():
		prog_notes.append("Резонанс рун: %s" % ", ".join(resonated_names))
	
	_context.turn_number = 1
	_context.battle_victory = false
	_context.battle_by_vow = false
	_context.outcome_message = ""
	_context.clear_pending_player_action()
	_context.clear_pending_enemy_action()
	_context.reset_player_turn_cursor()
	_context.reset_enemy_turn_cursor()
	
	if _context.ui != null:
		_context.ui.hide_sub_menu()
		_context.ui.clear_telegraph_banner()
		_context.ui.set_action_menu_visible(false)
	
	_refresh_ui()
	
	var alive_enemies: Array[Combatant] = _context.get_alive_enemies()
	var intro_msg: String = ""
	if alive_enemies.size() == 1 and alive_enemies[0].source_enemy_data != null:
		intro_msg = alive_enemies[0].source_enemy_data.dialogue_intro.strip_edges()
	if intro_msg.is_empty():
		var enemy_names: PackedStringArray = PackedStringArray()
		for enemy: Combatant in alive_enemies:
			enemy_names.append(enemy.display_name)
		intro_msg = "Бой начался! Противник: %s." % ", ".join(enemy_names)
	if not prog_notes.is_empty():
		intro_msg = "%s [%s]" % [intro_msg, " · ".join(prog_notes)]
	
	_emit_log(intro_msg)
	_emit_transition(&"player_select")
