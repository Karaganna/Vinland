# res://scripts/battle/states/enemy_turn_state.gd
class_name EnemyTurnState
extends BaseBattleState

## Выбор действия врага с учетом TAUNT, HYPNOSIS, STAGGER/SLEEP и двухфазного телеграфа
var _turn_counter: int = 0

func get_state_id() -> StringName:
	return &"enemy_turn"

func enter() -> void:
	if _context == null:
		return
	
	_context.clear_pending_enemy_action()
	
	var enemy: Combatant = _context.get_active_enemy()
	if enemy == null:
		if _context.is_enemy_party_defeated():
			_context.battle_victory = true
			_context.battle_by_vow = false
			_context.outcome_message = "Победа!"
			transition_requested.emit(&"battle_end")
		else:
			transition_requested.emit(&"turn_resolution")
		return
	
	enemy.clear_block_stance()
	
	# Если враг спит или ошеломлен — пропуск хода и спад Ярости
	if enemy.is_incapacitated():
		enemy.resources.decay_rage_on_idle_or_block()
		var reason: String = "спит" if enemy.has_status(BattleTypes.StatusType.SLEEP) else "ошеломлён"
		log_requested.emit("%s %s и не может атаковать!" % [enemy.display_name, reason])
		_refresh_ui()
		_advance_enemy_or_resolve()
		return
	
	# Проверка активного телеграфа спецатаки
	if enemy.pending_telegraph_skill != null:
		var ready_skill: SkillData = enemy.advance_telegraph()
		if ready_skill != null:
			if _context.ui != null:
				_context.ui.clear_telegraph_banner()
			_dispatch_enemy_attack(enemy, ready_skill)
			return
		_refresh_ui()
		_advance_enemy_or_resolve()
		return
	
	# Выбор навыка противника
	var chosen_skill: SkillData = _pick_enemy_skill(enemy)
	if chosen_skill == null:
		log_requested.emit("%s выжидает." % enemy.display_name)
		_advance_enemy_or_resolve()
		return
	
	# Если навык требует телеграфа — начинаем подготовку (открывается уязвимая зона)
	if chosen_skill.is_telegraphed:
		enemy.start_telegraph(chosen_skill)
		var warning: String = chosen_skill.telegraph_warning_text
		if warning.is_empty():
			warning = "%s готовит атаку «%s»!" % [enemy.display_name, chosen_skill.skill_name]
		_refresh_ui()
		log_requested.emit("⚠ " + warning)
		_advance_enemy_or_resolve()
		return
	
	_dispatch_enemy_attack(enemy, chosen_skill)

func _dispatch_enemy_attack(enemy: Combatant, skill: SkillData) -> void:
	var target: Combatant = _select_target_for_enemy(enemy)
	if target == null:
		_advance_enemy_or_resolve()
		return
	
	_context.enemy_pending_actor = enemy
	_context.enemy_pending_skill = skill
	_context.enemy_pending_target = target
	transition_requested.emit(&"defense_qte")

func _select_target_for_enemy(enemy: Combatant) -> Combatant:
	# 1. При HYPNOSIS бьет случайную живую цель (включая союзников)
	if enemy.is_hypnotized():
		var all_alive: Array[Combatant] = _context.get_all_alive_combatants()
		if not all_alive.is_empty():
			return all_alive.pick_random()
	
	# 2. При TAUNT принудительно атакует спровоцировавшего бойца
	var taunt_source_id: String = enemy.get_taunt_source_id()
	if not taunt_source_id.is_empty():
		var forced_by_id: Combatant = _context.find_alive_combatant_by_id(taunt_source_id)
		if forced_by_id != null:
			return forced_by_id
	
	var taunting_player: Combatant = _context.get_taunting_player()
	if taunting_player != null:
		return taunting_player
	
	# 3. Обычный выбор случайного живого бойца отряда игрока
	var alive_players: Array[Combatant] = _context.get_alive_players()
	if alive_players.is_empty():
		return null
	return alive_players.pick_random()

func _pick_enemy_skill(enemy: Combatant) -> SkillData:
	var candidates: Array[SkillData] = []
	if enemy.basic_attack != null:
		candidates.append(enemy.basic_attack)
	for sk: SkillData in enemy.skills:
		if sk != null and enemy.resources.can_afford(sk.resource_type, sk.resource_cost):
			candidates.append(sk)
	if candidates.is_empty():
		return null
	
	var idx: int = _turn_counter % candidates.size()
	_turn_counter += 1
	return candidates[idx]

func _advance_enemy_or_resolve() -> void:
	if _context.advance_to_next_alive_enemy():
		transition_requested.emit(&"enemy_turn")
	else:
		transition_requested.emit(&"turn_resolution")
