# res://scripts/battle/states/turn_resolution_state.gd
class_name TurnResolutionState
extends BaseBattleState

## Конец раунда: периодический урон (BURN/BLEED/POISON), тики статусов, рост Напряжения, проверка конца боя
func get_state_id() -> StringName:
	return &"turn_resolution"

func enter() -> void:
	if _context == null:
		return
	
	var dot_logs: PackedStringArray = PackedStringArray()
	for c: Combatant in _context.get_all_alive_combatants():
		var dot_events: Array[Dictionary] = c.process_end_of_round_dots()
		for ev: Dictionary in dot_events:
			var st_type: BattleTypes.StatusType = ev.get("status_type", BattleTypes.StatusType.BURN) as BattleTypes.StatusType
			var dmg: int = int(ev.get("damage", 0))
			var stacks: int = int(ev.get("stacks", 1))
			var stack_suffix: String = " x%d" % stacks if stacks > 1 else ""
			dot_logs.append("%s (%s%s): -%d HP." % [
				c.display_name,
				BattleTypes.get_status_display_name(st_type),
				stack_suffix,
				dmg
			])
		if c.is_alive():
			c.tick_statuses()
			c.clear_block_stance()
	
	if not dot_logs.is_empty():
		log_requested.emit(" ".join(dot_logs))
	
	for hero: Combatant in _context.get_alive_players():
		hero.restore_resource(BattleTypes.ResourceType.TENSION, 10)
		if hero.has_rune_seal(&"seal_jera"):
			var jera_hp: int = hero.heal_hp(maxi(4, roundi(float(hero.max_hp) * 0.08)), true, false)
			var jera_flow: int = hero.restore_resource(hero.resources.get_working_resource_type(), 8)
			if jera_hp > 0 or jera_flow > 0:
				dot_logs.append("[ᛃ Печать Йеры] %s: +%d HP, +%d Потока." % [hero.display_name, jera_hp, jera_flow])
	
	_context.turn_number += 1
	_refresh_ui()
	
	if _context.is_enemy_party_defeated():
		_context.battle_victory = true
		_context.battle_by_vow = false
		_context.outcome_message = "Победа в бою!"
		transition_requested.emit(&"battle_end")
		return
	
	if _context.is_player_party_defeated():
		_context.battle_victory = false
		_context.battle_by_vow = false
		_context.outcome_message = "Поражение..."
		transition_requested.emit(&"battle_end")
		return
	
	_context.reset_player_turn_cursor()
	transition_requested.emit(&"player_select")
