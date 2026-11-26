# res://scripts/battle/battle_ui_presenter.gd
class_name BattleUIPresenter
extends Control

## Сигналы интерфейса боя (строго снизу вверх)
signal action_selected(action_type: BattleTypes.ActionType)
signal skill_selected(skill: SkillData)
signal item_selected(item: ConsumableItemData)
signal target_selected(target: Combatant, part: EnemyPartState)
signal cancel_requested()
signal battle_end_action_selected(action_id: String)

@export_group("Автосборка UI")
@export var auto_build_ui_if_missing: bool = true

@export_group("Кнопки меню (5 действий)")
@export var attack_button: Button = null
@export var skill_button: Button = null
@export var block_button: Button = null
@export var item_button: Button = null
@export var ultimate_button: Button = null

@export_group("Контейнеры подменю и QTE")
@export var action_menu_container: Control = null
@export var sub_menu_scroll: ScrollContainer = null
@export var sub_menu_container: VBoxContainer = null
@export var qte_slot_container: Control = null

@export_group("Статус активного бойца (единый Поток/бак + Напряжение)")
@export var player_name_label: Label = null
@export var player_hp_bar: ProgressBar = null
@export var player_hp_label: Label = null
@export var working_resource_tag_label: Label = null
@export var working_resource_bar: ProgressBar = null
@export var working_resource_value_label: Label = null
@export var tension_bar: ProgressBar = null
@export var tension_value_label: Label = null
@export var player_statuses_label: Label = null

@export_group("Legacy-поля (опционально)")
@export var energy_bar: ProgressBar = null
@export var mana_bar: ProgressBar = null
@export var rage_bar: ProgressBar = null
@export var energy_value_label: Label = null
@export var mana_value_label: Label = null
@export var rage_value_label: Label = null

@export_group("Статус врага и телеграф")
@export var enemy_name_label: Label = null
@export var enemy_hp_bar: ProgressBar = null
@export var enemy_hp_label: Label = null
@export var enemy_parts_label: Label = null
@export var enemy_statuses_label: Label = null
@export var enemy_visual_rect: ColorRect = null
@export var telegraph_banner_label: Label = null

@export_group("Боевой лог")
@export var combat_log_label: RichTextLabel = null
@export var typewriter_duration: float = 0.22
@export var max_log_lines: int = 8

var _log_tween: Tween = null
var _log_history: Array[String] = []
var _is_battle_end_menu_open: bool = false

func _ready() -> void:
	if auto_build_ui_if_missing and (attack_button == null or combat_log_label == null or qte_slot_container == null):
		_apply_built_ui(BattleUIBuilder.build_sandbox_ui(self))
	rebind_action_buttons()
	if combat_log_label != null:
		combat_log_label.bbcode_enabled = true
	clear_telegraph_banner()
	set_qte_active(false)
	hide_sub_menu()

func rebind_action_buttons() -> void:
	_bind_action_buttons()

## Переключает видимость слота QTE в нижней панели боя
func set_qte_active(is_active: bool) -> void:
	if is_active:
		hide_sub_menu()
		set_action_menu_visible(false)
	if qte_slot_container != null:
		qte_slot_container.visible = is_active

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _is_battle_end_menu_open:
			return
		if sub_menu_container != null and sub_menu_container.visible:
			get_viewport().set_input_as_handled()
			cancel_requested.emit()

func _bind_action_buttons() -> void:
	if attack_button != null and not attack_button.pressed.is_connected(_on_attack_pressed):
		attack_button.pressed.connect(_on_attack_pressed)
	if skill_button != null and not skill_button.pressed.is_connected(_on_skill_pressed):
		skill_button.pressed.connect(_on_skill_pressed)
	if block_button != null and not block_button.pressed.is_connected(_on_block_pressed):
		block_button.pressed.connect(_on_block_pressed)
	if item_button != null and not item_button.pressed.is_connected(_on_item_pressed):
		item_button.pressed.connect(_on_item_pressed)
	if ultimate_button != null and not ultimate_button.pressed.is_connected(_on_ultimate_pressed):
		ultimate_button.pressed.connect(_on_ultimate_pressed)

func _on_attack_pressed() -> void:
	action_selected.emit(BattleTypes.ActionType.ATTACK)

func _on_skill_pressed() -> void:
	action_selected.emit(BattleTypes.ActionType.SKILL)

func _on_block_pressed() -> void:
	action_selected.emit(BattleTypes.ActionType.BLOCK)

func _on_item_pressed() -> void:
	action_selected.emit(BattleTypes.ActionType.ITEM)

func _on_ultimate_pressed() -> void:
	action_selected.emit(BattleTypes.ActionType.ULTIMATE)

## Обновляет шкалы HP, единой рабочей шкалы («Поток» у ГГ / бак у рекрута), Напряжения и статусов
func refresh_combatants(
	player_party: Array[Combatant],
	enemy_party: Array[Combatant],
	active_player: Combatant
) -> void:
	var hero: Combatant = active_player
	if hero == null and not player_party.is_empty():
		hero = player_party[0]
	
	if hero != null:
		if player_name_label != null:
			player_name_label.text = hero.display_name
		_update_bar(player_hp_bar, hero.current_hp, hero.max_hp, true)
		if player_hp_label != null:
			var barrier_hp: int = hero.get_shield_barrier_hp()
			var barrier_str: String = " [+%d]" % barrier_hp if barrier_hp > 0 else ""
			player_hp_label.text = "HP: %d/%d%s" % [hero.current_hp, hero.max_hp, barrier_str]
		
		_update_working_resource_row(hero)
		_update_tension_row(hero.resources)
		
		# Поддержка опциональных legacy-баров, если привязаны вручную
		_update_resource_bar(energy_bar, energy_value_label, hero.resources, BattleTypes.ResourceType.ENERGY)
		_update_resource_bar(mana_bar, mana_value_label, hero.resources, BattleTypes.ResourceType.MANA)
		_update_resource_bar(rage_bar, rage_value_label, hero.resources, BattleTypes.ResourceType.RAGE)
		
		if player_statuses_label != null:
			player_statuses_label.text = _format_statuses(hero)
	
	var enemy: Combatant = _pick_display_enemy(enemy_party)
	if enemy != null:
		if enemy_name_label != null:
			enemy_name_label.text = enemy.display_name
		if enemy_visual_rect != null:
			enemy_visual_rect.color = enemy.sprite_color
		_update_bar(enemy_hp_bar, enemy.current_hp, enemy.max_hp, true)
		if enemy_hp_label != null:
			enemy_hp_label.text = "HP: %d/%d" % [enemy.current_hp, enemy.max_hp]
		if enemy_parts_label != null:
			enemy_parts_label.text = _format_enemy_parts(enemy)
		if enemy_statuses_label != null:
			enemy_statuses_label.text = _format_statuses(enemy)
		if enemy.is_telegraphing() and enemy.pending_telegraph_skill != null:
			var warn: String = enemy.pending_telegraph_skill.telegraph_warning_text
			if warn.is_empty():
				warn = "%s готовит: %s" % [enemy.display_name, enemy.pending_telegraph_skill.skill_name]
			show_telegraph_banner(warn)
		else:
			clear_telegraph_banner()

## Показывает или скрывает основное меню из 5 кнопок с учетом доступности Ульты и Перезарядки
func set_action_menu_visible(menu_visible: bool, active_hero: Combatant = null) -> void:
	if action_menu_container != null:
		action_menu_container.visible = menu_visible
	
	var buttons: Array[Button] = [attack_button, skill_button, block_button, item_button, ultimate_button]
	for btn: Button in buttons:
		if btn != null:
			btn.disabled = not menu_visible
	
	if menu_visible and active_hero != null:
		if attack_button != null:
			attack_button.text = "↻ Перезарядка" if active_hero.has_status(BattleTypes.StatusType.RELOAD_REQUIRED) else "⚔ Атака"
		if skill_button != null:
			skill_button.disabled = active_hero.skills.is_empty()
		if ultimate_button != null:
			var can_ult: bool = (
				active_hero.ultimate_skill != null
				and active_hero.resources.can_use_ultimate(active_hero.ultimate_skill.min_tension_tier)
			)
			ultimate_button.disabled = not can_ult
		if attack_button != null and attack_button.is_inside_tree():
			attack_button.grab_focus()

## Отображает список навыков активного бойца с ценой в его рабочей шкале (Поток / основной бак)
func show_skill_list(actor: Combatant) -> void:
	if sub_menu_container == null or actor == null:
		return
	_clear_sub_menu()
	if sub_menu_scroll != null:
		sub_menu_scroll.visible = true
	sub_menu_container.visible = true
	
	var res_label: String = BattleTypes.HERO_FLOW_DISPLAY_NAME if actor.resources.is_flow_mode else actor.resources.get_working_display_name()
	for skill: SkillData in actor.skills:
		if skill == null:
			continue
		var btn: Button = Button.new()
		var cost_text: String = ""
		if skill.resource_cost > 0:
			cost_text = " (%d %s)" % [skill.resource_cost, res_label]
		elif skill.is_rage_to_heal():
			cost_text = " (сжигает %s)" % res_label
		elif skill.has_tag(BattleTypes.SkillTag.SCALES_WITH_RAGE):
			cost_text = " (скейл от %s)" % res_label
		btn.text = "%s%s" % [skill.skill_name, cost_text]
		btn.tooltip_text = skill.description
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 10)
		var reload_blocked: bool = actor.has_status(BattleTypes.StatusType.RELOAD_REQUIRED) and skill.has_tag(BattleTypes.SkillTag.RANGED_ATTACK)
		btn.disabled = reload_blocked or not actor.resources.can_afford(skill.resource_type, skill.resource_cost)
		var captured_skill: SkillData = skill
		btn.pressed.connect(func() -> void:
			skill_selected.emit(captured_skill)
		)
		sub_menu_container.add_child(btn)
	
	_add_cancel_button()

## Отображает список доступных боевых расходников из инвентаря
func show_item_list(entries: Array[Dictionary]) -> void:
	if sub_menu_container == null:
		return
	_is_battle_end_menu_open = false
	_clear_sub_menu()
	if sub_menu_scroll != null:
		sub_menu_scroll.visible = true
	sub_menu_container.visible = true
	
	for entry: Dictionary in entries:
		var cons: ConsumableItemData = entry.get("item", null) as ConsumableItemData
		var cnt: int = int(entry.get("count", 0))
		if cons == null or cnt <= 0:
			continue
		var btn: Button = Button.new()
		btn.text = "%s x%d — %s" % [cons.display_name, cnt, cons.get_effect_summary()]
		btn.tooltip_text = cons.description
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 10)
		var captured_item: ConsumableItemData = cons
		btn.pressed.connect(func() -> void:
			item_selected.emit(captured_item)
		)
		sub_menu_container.add_child(btn)
	
	_add_cancel_button()

## Отображает выбор союзника как цели (для лечения, баффов, предметов или стойки «Начеку»)
func show_ally_selection(allies: Array[Combatant]) -> void:
	if sub_menu_container == null:
		return
	_clear_sub_menu()
	if sub_menu_scroll != null:
		sub_menu_scroll.visible = true
	sub_menu_container.visible = true
	
	for ally: Combatant in allies:
		if ally == null or not ally.is_alive():
			continue
		var btn: Button = Button.new()
		var work_type: BattleTypes.ResourceType = ally.resources.get_working_resource_type()
		btn.text = "%s (HP: %d/%d · %s: %d/%d)" % [
			ally.display_name,
			ally.current_hp,
			ally.max_hp,
			ally.resources.get_working_display_name(),
			ally.resources.get_current(work_type),
			ally.resources.get_max(work_type)
		]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 10)
		var captured_ally: Combatant = ally
		btn.pressed.connect(func() -> void:
			target_selected.emit(captured_ally, null)
		)
		sub_menu_container.add_child(btn)
	
	_add_cancel_button()

## Отображает доступные цели врагов и их открытые части тела (зоны атаки)
func show_target_and_part_selection(enemies: Array[Combatant]) -> void:
	if sub_menu_container == null:
		return
	_clear_sub_menu()
	if sub_menu_scroll != null:
		sub_menu_scroll.visible = true
	sub_menu_container.visible = true
	
	for enemy: Combatant in enemies:
		if enemy == null or not enemy.is_alive():
			continue
		var targetable_parts: Array[EnemyPartState] = enemy.get_targetable_parts()
		if targetable_parts.is_empty():
			var btn: Button = Button.new()
			btn.text = "%s (HP: %d/%d)" % [enemy.display_name, enemy.current_hp, enemy.max_hp]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 10)
			var captured_enemy: Combatant = enemy
			btn.pressed.connect(func() -> void:
				target_selected.emit(captured_enemy, null)
			)
			sub_menu_container.add_child(btn)
		else:
			for part: EnemyPartState in targetable_parts:
				if part == null or part.data == null:
					continue
				var btn: Button = Button.new()
				var weak_tag: String = " [УЯЗВИМА x%.1f]" % part.data.damage_multiplier if part.data.damage_multiplier > 1.0 else ""
				btn.text = "%s — %s (HP: %d/%d, Броня: %d)%s" % [
					enemy.display_name,
					part.data.part_name,
					part.current_hp,
					part.data.max_hp,
					part.data.armor,
					weak_tag
				]
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.add_theme_font_size_override("font_size", 10)
				var captured_enemy: Combatant = enemy
				var captured_part: EnemyPartState = part
				btn.pressed.connect(func() -> void:
					target_selected.emit(captured_enemy, captured_part)
				)
				sub_menu_container.add_child(btn)
	
	_add_cancel_button()

func hide_sub_menu() -> void:
	_is_battle_end_menu_open = false
	if sub_menu_container != null:
		_clear_sub_menu()
		sub_menu_container.visible = false
	if sub_menu_scroll != null:
		sub_menu_scroll.visible = false

## Показывает кнопку подтверждения выхода в оверворлд или перезапуска песочницы
func show_battle_end_options(is_overworld_battle: bool) -> void:
	set_qte_active(false)
	set_action_menu_visible(false)
	if sub_menu_container == null:
		return
	_clear_sub_menu()
	if sub_menu_scroll != null:
		sub_menu_scroll.visible = true
	sub_menu_container.visible = true
	_is_battle_end_menu_open = true
	
	var action_btn: Button = Button.new()
	var action_id: String = "return_to_world" if is_overworld_battle else "restart_sandbox"
	action_btn.text = "Вернуться в мир" if is_overworld_battle else "Повторить бой (Sandbox)"
	action_btn.custom_minimum_size = Vector2(220.0, 28.0)
	action_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_btn.add_theme_font_size_override("font_size", 11)
	action_btn.pressed.connect(func() -> void:
		battle_end_action_selected.emit(action_id)
	)
	sub_menu_container.add_child(action_btn)
	if action_btn.is_inside_tree():
		action_btn.call_deferred("grab_focus")

## Выводит текст боевого лога через RichTextLabel и visible_characters (безопасно для BBCode)
func set_log_text(message: String) -> void:
	if combat_log_label == null:
		return
	var trimmed: String = message.strip_edges()
	if trimmed.is_empty():
		return
	
	var prev_char_count: int = combat_log_label.get_total_character_count()
	if _log_history.size() >= maxi(1, max_log_lines):
		_log_history.remove_at(0)
		prev_char_count = 0
	_log_history.append(trimmed)
	
	combat_log_label.bbcode_enabled = true
	combat_log_label.text = "\n".join(_log_history)
	if _log_tween != null and _log_tween.is_valid():
		_log_tween.kill()
	
	var total_chars: int = combat_log_label.get_total_character_count()
	if not is_inside_tree() or typewriter_duration <= 0.0 or total_chars <= 0:
		combat_log_label.visible_characters = -1
		return
	
	var start_chars: int = clampi(prev_char_count, 0, total_chars)
	combat_log_label.visible_characters = start_chars
	_log_tween = create_tween()
	_log_tween.tween_property(combat_log_label, "visible_characters", total_chars, typewriter_duration)

func show_telegraph_banner(warning: String) -> void:
	if telegraph_banner_label == null:
		return
	telegraph_banner_label.text = "⚠ " + warning
	telegraph_banner_label.visible = true

func clear_telegraph_banner() -> void:
	if telegraph_banner_label == null:
		return
	telegraph_banner_label.text = ""
	telegraph_banner_label.visible = false

func get_qte_container() -> Control:
	return qte_slot_container if qte_slot_container != null else self

func _clear_sub_menu() -> void:
	if sub_menu_container == null:
		return
	for child: Node in sub_menu_container.get_children():
		child.queue_free()

func _add_cancel_button() -> void:
	if sub_menu_container == null:
		return
	var back_btn: Button = Button.new()
	back_btn.text = "← Назад"
	back_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back_btn.add_theme_font_size_override("font_size", 10)
	back_btn.pressed.connect(func() -> void:
		cancel_requested.emit()
	)
	sub_menu_container.add_child(back_btn)

func _update_working_resource_row(hero: Combatant) -> void:
	if hero == null or hero.resources == null:
		return
	var work_type: BattleTypes.ResourceType = hero.resources.get_working_resource_type()
	var cur_val: int = hero.resources.get_current(work_type)
	var max_val: int = hero.resources.get_max(work_type)
	if working_resource_tag_label != null:
		working_resource_tag_label.text = hero.resources.get_working_display_name()
	if working_resource_bar != null:
		_set_bar_fill_color(working_resource_bar, BattleTypes.get_resource_color(work_type))
		_update_bar(working_resource_bar, cur_val, max_val, true)
	if working_resource_value_label != null:
		var fire_mark: String = " 🔥" if not hero.get_triggered_flow_threshold_items().is_empty() else ""
		working_resource_value_label.text = "%d/%d%s" % [cur_val, max_val, fire_mark]

func _update_tension_row(pool: ResourcePool) -> void:
	if pool == null:
		return
	var cur_val: int = pool.get_current(BattleTypes.ResourceType.TENSION)
	var max_val: int = pool.get_max(BattleTypes.ResourceType.TENSION)
	var active: bool = pool.has_resource(BattleTypes.ResourceType.TENSION)
	_update_bar(tension_bar, cur_val, max_val, active)
	if tension_value_label != null:
		tension_value_label.visible = active
		var tier: BattleTypes.TensionTier = pool.get_available_tension_tier()
		var tier_mark: String = ""
		if tier == BattleTypes.TensionTier.FULL_100:
			tier_mark = " ★★"
		elif tier == BattleTypes.TensionTier.HALF_50:
			tier_mark = " ★"
		tension_value_label.text = "%d/%d%s" % [cur_val, max_val, tier_mark]

func _set_bar_fill_color(bar: ProgressBar, color: Color) -> void:
	if bar == null:
		return
	var st: StyleBoxFlat = bar.get_theme_stylebox("fill") as StyleBoxFlat
	if st != null:
		st.bg_color = color

func _update_bar(bar: ProgressBar, current_val: int, max_val: int, show_bar: bool) -> void:
	if bar == null:
		return
	bar.visible = show_bar
	bar.max_value = float(maxi(1, max_val))
	bar.value = float(clampi(current_val, 0, maxi(1, max_val)))

func _update_resource_bar(
	bar: ProgressBar,
	val_lbl: Label,
	pool: ResourcePool,
	res_type: BattleTypes.ResourceType
) -> void:
	if pool == null or bar == null:
		return
	var active: bool = pool.has_resource(res_type)
	var cur_val: int = pool.get_current(res_type)
	var max_val: int = pool.get_max(res_type)
	_update_bar(bar, cur_val, max_val, active)
	if val_lbl != null:
		val_lbl.visible = active
		val_lbl.text = "%d/%d" % [cur_val, max_val]

func _format_enemy_parts(enemy: Combatant) -> String:
	if enemy == null or enemy.parts.is_empty():
		return ""
	var lines: PackedStringArray = PackedStringArray()
	var staggered: bool = enemy.is_staggered() or enemy.has_status(BattleTypes.StatusType.KNOCKED_DOWN)
	var telegraphing: bool = enemy.is_telegraphing()
	for part: EnemyPartState in enemy.parts:
		if part == null or part.data == null:
			continue
		var can_hit: bool = part.is_targetable(staggered, telegraphing)
		if part.is_broken and not part.data.stay_targetable_when_broken:
			lines.append("%s: [СЛОМАНО]" % part.data.part_name)
		elif can_hit:
			var tag: String = " [x%.1f!]" % part.data.damage_multiplier if part.data.damage_multiplier > 1.0 else ""
			lines.append("%s: %d/%d%s" % [part.data.part_name, part.current_hp, part.data.max_hp, tag])
		else:
			lines.append("%s: [закрыта]" % part.data.part_name)
	return "\n".join(lines)

func _apply_built_ui(built: Dictionary) -> void:
	if built.is_empty():
		return
	if attack_button == null: attack_button = built.get("attack_button") as Button
	if skill_button == null: skill_button = built.get("skill_button") as Button
	if block_button == null: block_button = built.get("block_button") as Button
	if item_button == null: item_button = built.get("item_button") as Button
	if ultimate_button == null: ultimate_button = built.get("ultimate_button") as Button
	if action_menu_container == null: action_menu_container = built.get("action_menu_container") as Control
	if sub_menu_scroll == null: sub_menu_scroll = built.get("sub_menu_scroll") as ScrollContainer
	if sub_menu_container == null: sub_menu_container = built.get("sub_menu_container") as VBoxContainer
	if qte_slot_container == null: qte_slot_container = built.get("qte_slot_container") as Control
	if player_name_label == null: player_name_label = built.get("player_name_label") as Label
	if player_hp_bar == null: player_hp_bar = built.get("player_hp_bar") as ProgressBar
	if player_hp_label == null: player_hp_label = built.get("player_hp_label") as Label
	if working_resource_tag_label == null: working_resource_tag_label = built.get("working_resource_tag_label") as Label
	if working_resource_bar == null: working_resource_bar = built.get("working_resource_bar") as ProgressBar
	if working_resource_value_label == null: working_resource_value_label = built.get("working_resource_value_label") as Label
	if tension_bar == null: tension_bar = built.get("tension_bar") as ProgressBar
	if tension_value_label == null: tension_value_label = built.get("tension_value_label") as Label
	if player_statuses_label == null: player_statuses_label = built.get("player_statuses_label") as Label
	if enemy_name_label == null: enemy_name_label = built.get("enemy_name_label") as Label
	if enemy_hp_bar == null: enemy_hp_bar = built.get("enemy_hp_bar") as ProgressBar
	if enemy_hp_label == null: enemy_hp_label = built.get("enemy_hp_label") as Label
	if enemy_parts_label == null: enemy_parts_label = built.get("enemy_parts_label") as Label
	if enemy_statuses_label == null: enemy_statuses_label = built.get("enemy_statuses_label") as Label
	if enemy_visual_rect == null: enemy_visual_rect = built.get("enemy_visual_rect") as ColorRect
	if telegraph_banner_label == null: telegraph_banner_label = built.get("telegraph_banner_label") as Label
	if combat_log_label == null: combat_log_label = built.get("combat_log_label") as RichTextLabel

func _pick_display_enemy(enemies: Array[Combatant]) -> Combatant:
	for enemy: Combatant in enemies:
		if enemy != null and enemy.is_alive():
			return enemy
	return enemies[0] if not enemies.is_empty() else null

func _format_statuses(combatant: Combatant) -> String:
	if combatant == null:
		return ""
	var parts: PackedStringArray = PackedStringArray()
	if combatant.is_blocking:
		parts.append("БЛОК")
	for st: StatusEffectInstance in combatant.statuses:
		if st.status_type == BattleTypes.StatusType.SHIELD_BARRIER:
			parts.append("Барьер: %d" % st.barrier_hp)
			continue
		var stack_part: String = " x%d" % st.stacks if st.stacks > 1 else ""
		var turn_part: String = "∞" if st.is_permanent_in_battle else str(st.remaining_turns)
		parts.append("%s%s (%s)" % [BattleTypes.get_status_display_name(st.status_type), stack_part, turn_part])
	return ", ".join(parts)
