# res://scripts/battle/states/player_select_state.gd
class_name PlayerSelectState
extends BaseBattleState

## Выбор действия, умения, расходника и цели (врага, части тела или союзника) активным бойцом
enum SubMenuMode {
	NONE,
	SKILL_LIST,
	ITEM_LIST,
	TARGET_SELECT
}

var _sub_menu_mode: SubMenuMode = SubMenuMode.NONE
var _is_listening_ui: bool = false

func get_state_id() -> StringName:
	return &"player_select"

func enter() -> void:
	if _context == null:
		return
	
	_sub_menu_mode = SubMenuMode.NONE
	_context.clear_pending_player_action()
	
	var actor: Combatant = _context.get_active_player()
	if actor == null:
		if _context.is_player_party_defeated():
			_context.battle_victory = false
			_context.battle_by_vow = false
			_context.outcome_message = "Все герои пали в бою..."
			_emit_transition(&"battle_end")
			return
		_context.reset_enemy_turn_cursor()
		_emit_transition(&"enemy_turn")
		return
	
	# Проверка статусов потери хода (SLEEP, FREEZE, STUN, KNOCKED_DOWN, STAGGER)
	if actor.is_incapacitated():
		actor.resources.decay_rage_on_idle_or_block()
		var status_text: String = actor.get_incapacitation_reason()
		_emit_log("%s %s и пропускает ход!" % [actor.display_name, status_text])
		_refresh_ui()
		_advance_player_or_go_enemy_turn()
		return
	
	# Проверка статуса HYPNOSIS (случайная цель среди всех живых бойцов)
	if actor.is_hypnotized():
		var all_alive: Array[Combatant] = _context.get_all_alive_combatants()
		if not all_alive.is_empty():
			var random_target: Combatant = all_alive.pick_random()
			_context.pending_action_type = BattleTypes.ActionType.ATTACK
			_context.pending_skill = actor.basic_attack
			_context.pending_target = random_target
			_context.pending_target_part = null
			_emit_log("%s под гипнозом атакует случайную цель (%s)!" % [actor.display_name, random_target.display_name])
			_emit_transition(&"player_action")
			return
	
	_connect_ui()
	_refresh_ui()
	if _context.ui != null:
		_context.ui.hide_sub_menu()
		_context.ui.set_action_menu_visible(true, actor)
	_emit_log("[Ход %d] Выберите действие для: %s" % [_context.turn_number, actor.display_name])

func exit() -> void:
	_disconnect_ui()
	_sub_menu_mode = SubMenuMode.NONE
	if _context != null and _context.ui != null:
		_context.ui.hide_sub_menu()
		_context.ui.set_action_menu_visible(false)

func _connect_ui() -> void:
	if _context == null or _context.ui == null or _is_listening_ui:
		return
	var ui: BattleUIPresenter = _context.ui
	ui.action_selected.connect(_on_action_selected)
	ui.skill_selected.connect(_on_skill_selected)
	ui.item_selected.connect(_on_item_selected)
	ui.target_selected.connect(_on_target_selected)
	ui.cancel_requested.connect(_on_cancel_requested)
	_is_listening_ui = true

func _disconnect_ui() -> void:
	if _context == null or _context.ui == null or not _is_listening_ui:
		return
	var ui: BattleUIPresenter = _context.ui
	if ui.action_selected.is_connected(_on_action_selected):
		ui.action_selected.disconnect(_on_action_selected)
	if ui.skill_selected.is_connected(_on_skill_selected):
		ui.skill_selected.disconnect(_on_skill_selected)
	if ui.item_selected.is_connected(_on_item_selected):
		ui.item_selected.disconnect(_on_item_selected)
	if ui.target_selected.is_connected(_on_target_selected):
		ui.target_selected.disconnect(_on_target_selected)
	if ui.cancel_requested.is_connected(_on_cancel_requested):
		ui.cancel_requested.disconnect(_on_cancel_requested)
	_is_listening_ui = false

func _on_action_selected(action_type: BattleTypes.ActionType) -> void:
	var actor: Combatant = _context.get_active_player()
	if actor == null:
		return
	
	match action_type:
		BattleTypes.ActionType.ATTACK:
			_context.pending_action_type = BattleTypes.ActionType.ATTACK
			_context.pending_skill = actor.basic_attack
			if actor.has_status(BattleTypes.StatusType.RELOAD_REQUIRED):
				_context.pending_target = actor
				_context.pending_target_part = null
				_emit_transition(&"player_action")
				return
			_open_target_selection_or_execute(actor.basic_attack)
		BattleTypes.ActionType.SKILL:
			_context.pending_action_type = BattleTypes.ActionType.SKILL
			_sub_menu_mode = SubMenuMode.SKILL_LIST
			if _context.ui != null:
				_context.ui.show_skill_list(actor)
		BattleTypes.ActionType.BLOCK:
			_context.pending_action_type = BattleTypes.ActionType.BLOCK
			_context.pending_skill = null
			_emit_transition(&"player_action")
		BattleTypes.ActionType.ITEM:
			if GameManager == null:
				_emit_log("Инвентарь недоступен.")
				return
			GameManager.ensure_inventory_initialized()
			var entries: Array[Dictionary] = GameManager.inventory.get_consumables(true, false)
			if entries.is_empty():
				_emit_log("В инвентаре нет доступных расходников.")
				return
			_context.pending_action_type = BattleTypes.ActionType.ITEM
			_sub_menu_mode = SubMenuMode.ITEM_LIST
			if _context.ui != null:
				_context.ui.show_item_list(entries)
		BattleTypes.ActionType.ULTIMATE:
			if actor.ultimate_skill == null or not actor.resources.can_use_ultimate(actor.ultimate_skill.min_tension_tier):
				_emit_log("Шкала Напряжения еще не заполнена для Ульты!")
				return
			_context.pending_action_type = BattleTypes.ActionType.ULTIMATE
			_context.pending_skill = actor.ultimate_skill
			_open_target_selection_or_execute(actor.ultimate_skill)

func _on_skill_selected(skill: SkillData) -> void:
	if skill == null:
		return
	var actor: Combatant = _context.get_active_player()
	if actor != null and actor.has_status(BattleTypes.StatusType.RELOAD_REQUIRED) and skill.has_tag(BattleTypes.SkillTag.RANGED_ATTACK):
		_emit_log("Оружие разряжено! Используйте базовое действие для перезарядки.")
		return
	_context.pending_skill = skill
	_open_target_selection_or_execute(skill)

func _on_item_selected(item: ConsumableItemData) -> void:
	if item == null:
		return
	var actor: Combatant = _context.get_active_player()
	_context.pending_action_type = BattleTypes.ActionType.ITEM
	_context.pending_consumable = item
	_context.pending_skill = null
	var alive_allies: Array[Combatant] = _context.get_alive_players()
	if alive_allies.size() > 1 and _context.ui != null:
		_sub_menu_mode = SubMenuMode.TARGET_SELECT
		_context.ui.show_ally_selection(alive_allies)
		return
	_context.pending_target = actor
	_context.pending_target_part = null
	_emit_transition(&"player_action")

func _on_target_selected(target: Combatant, part: EnemyPartState) -> void:
	_context.pending_target = target
	_context.pending_target_part = part
	_emit_transition(&"player_action")

func _on_cancel_requested() -> void:
	var actor: Combatant = _context.get_active_player()
	if _sub_menu_mode == SubMenuMode.TARGET_SELECT and _context.pending_action_type == BattleTypes.ActionType.SKILL and actor != null:
		_sub_menu_mode = SubMenuMode.SKILL_LIST
		if _context.ui != null:
			_context.ui.show_skill_list(actor)
		return
	if _sub_menu_mode == SubMenuMode.TARGET_SELECT and _context.pending_action_type == BattleTypes.ActionType.ITEM and GameManager != null and GameManager.inventory != null:
		_sub_menu_mode = SubMenuMode.ITEM_LIST
		if _context.ui != null:
			_context.ui.show_item_list(GameManager.inventory.get_consumables(true, false))
		return
	
	_sub_menu_mode = SubMenuMode.NONE
	if _context.ui != null:
		_context.ui.hide_sub_menu()
		_context.ui.set_action_menu_visible(true, actor)

func _open_target_selection_or_execute(skill: SkillData) -> void:
	var actor: Combatant = _context.get_active_player()
	if skill == null:
		_emit_transition(&"player_action")
		return
	
	if skill.target_side == BattleTypes.TargetSide.SELF:
		_context.pending_target = actor
		_context.pending_target_part = null
		_emit_transition(&"player_action")
		return
	
	if skill.target_side == BattleTypes.TargetSide.ALL_ENEMIES or skill.target_side == BattleTypes.TargetSide.ALL_ALLIES:
		_context.pending_target = null
		_context.pending_target_part = null
		_emit_transition(&"player_action")
		return
	
	if skill.target_side == BattleTypes.TargetSide.ALLY:
		var candidates: Array[Combatant] = []
		if skill.revives_fallen_ally:
			candidates = _context.get_fallen_players()
			if candidates.is_empty():
				_emit_log("В отряде нет павших бойцов для «%s»." % skill.skill_name)
				return
		elif skill.can_target_fallen_ally:
			for m: Combatant in _context.player_party:
				if m != null:
					candidates.append(m)
		else:
			var alive_allies: Array[Combatant] = _context.get_alive_players()
			var exclude_self: bool = skill.enters_stance and skill.stance_status == BattleTypes.StatusType.COVER_ALLY
			for ally: Combatant in alive_allies:
				if exclude_self and ally == actor:
					continue
				candidates.append(ally)
			if candidates.is_empty():
				candidates = alive_allies
		if candidates.size() == 1:
			_context.pending_target = candidates[0]
			_context.pending_target_part = null
			_emit_transition(&"player_action")
			return
		_sub_menu_mode = SubMenuMode.TARGET_SELECT
		if _context.ui != null:
			_context.ui.show_ally_selection(candidates)
		return
	
	var alive_enemies: Array[Combatant] = _context.get_alive_enemies()
	if alive_enemies.is_empty():
		_emit_transition(&"battle_end")
		return
	
	if alive_enemies.size() == 1 and alive_enemies[0].get_targetable_parts().is_empty():
		_context.pending_target = alive_enemies[0]
		_context.pending_target_part = null
		_emit_transition(&"player_action")
		return
	
	_sub_menu_mode = SubMenuMode.TARGET_SELECT
	if _context.ui != null:
		_context.ui.show_target_and_part_selection(alive_enemies)

func _advance_player_or_go_enemy_turn() -> void:
	if _context.advance_to_next_alive_player():
		_emit_transition(&"player_select")
	else:
		_context.reset_enemy_turn_cursor()
		_emit_transition(&"enemy_turn")
