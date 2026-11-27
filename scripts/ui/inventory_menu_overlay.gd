# res://scripts/ui/inventory_menu_overlay.gd
class_name InventoryMenuOverlay
extends CanvasLayer

## Сигналы окна инвентаря, экипировки, отряда, Старшего футарка и Богов (строго снизу вверх)
signal inventory_opened()
signal inventory_closed()
signal equipment_changed(slot_id: StringName)
signal consumable_used(item_id: String)

enum ActiveTab {
	EQUIPMENT,
	CONSUMABLES,
	SHIP_ROSTER,
	RUNES,
	GODS
}

const TOGGLE_ACTION_NAME: StringName = &"inventory_toggle"
const GRID_COLUMNS: int = 5
const MIN_GRID_CELLS: int = 15

var _bound_player: Player = null
var _is_open: bool = false
var _active_tab: ActiveTab = ActiveTab.EQUIPMENT
var _selected_party_index: int = 0
var _selected_equip_index: int = 0
var _selected_cons_index: int = 0
var _show_rune_recipes: bool = false

var _is_listening_inventory: bool = false
var _is_listening_party: bool = false
var _is_listening_progression: bool = false

var _hud_toggle_btn: Button = null
var _overlay_root: Control = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _close_btn: Button = null
var _member_selector_hbox: HBoxContainer = null

var _member_profile_label: Label = null
var _doll_fullbody_sprite: TextureRect = null
var _left_slots_col: VBoxContainer = null
var _right_slots_col: VBoxContainer = null
var _hp_bar: ProgressBar = null
var _hp_bar_label: Label = null
var _res_bar: ProgressBar = null
var _res_bar_label: Label = null
var _res_bar_icon: TextureRect = null
var _atk_val_lbl: Label = null
var _mag_val_lbl: Label = null
var _def_val_lbl: Label = null
var _spd_val_lbl: Label = null
var _crit_val_lbl: Label = null
var _synergy_label: Label = null

var _tab_eq_btn: Button = null
var _tab_eq_lbl: Label = null
var _tab_cons_btn: Button = null
var _tab_cons_lbl: Label = null
var _tab_ship_btn: Button = null
var _tab_ship_lbl: Label = null
var _tab_runes_btn: Button = null
var _tab_runes_lbl: Label = null
var _tab_gods_btn: Button = null
var _tab_gods_lbl: Label = null

var _item_list_scroll: ScrollContainer = null
var _item_list_container: VBoxContainer = null
var _inspector_panel: PanelContainer = null
var _inspector_icon_frame: PanelContainer = null
var _inspector_icon_rect: TextureRect = null
var _inspector_title_lbl: Label = null
var _inspector_stats_hbox: HBoxContainer = null
var _inspector_desc_lbl: Label = null
var _inspector_actions_vbox: VBoxContainer = null
var _feedback_label: Label = null

func _ready() -> void:
	layer = 20
	if GameManager != null:
		GameManager.ensure_party_initialized()
	
	var built: Dictionary = InventoryMenuBuilder.build_overlay_ui(self)
	_hud_toggle_btn = built.get("hud_toggle_button") as Button
	_overlay_root = built.get("overlay_root") as Control
	_title_label = built.get("title_label") as Label
	_subtitle_label = built.get("subtitle_label") as Label
	_close_btn = built.get("close_button") as Button
	_member_selector_hbox = built.get("member_selector_hbox") as HBoxContainer
	
	_member_profile_label = built.get("member_profile_label") as Label
	_doll_fullbody_sprite = built.get("doll_fullbody_sprite") as TextureRect
	_left_slots_col = built.get("left_slots_column") as VBoxContainer
	_right_slots_col = built.get("right_slots_column") as VBoxContainer
	_hp_bar = built.get("hp_bar") as ProgressBar
	_hp_bar_label = built.get("hp_bar_label") as Label
	_res_bar = built.get("res_bar") as ProgressBar
	_res_bar_label = built.get("res_bar_label") as Label
	_res_bar_icon = built.get("res_bar_icon") as TextureRect
	_atk_val_lbl = built.get("atk_value_label") as Label
	_mag_val_lbl = built.get("mag_value_label") as Label
	_def_val_lbl = built.get("def_value_label") as Label
	_spd_val_lbl = built.get("spd_value_label") as Label
	_crit_val_lbl = built.get("crit_value_label") as Label
	_synergy_label = built.get("synergy_label") as Label
	
	_tab_eq_btn = built.get("tab_equipment_button") as Button
	_tab_eq_lbl = built.get("tab_equipment_label") as Label
	_tab_cons_btn = built.get("tab_consumables_button") as Button
	_tab_cons_lbl = built.get("tab_consumables_label") as Label
	_tab_ship_btn = built.get("tab_ship_button") as Button
	_tab_ship_lbl = built.get("tab_ship_label") as Label
	_tab_runes_btn = built.get("tab_runes_button") as Button
	_tab_runes_lbl = built.get("tab_runes_label") as Label
	_tab_gods_btn = built.get("tab_gods_button") as Button
	_tab_gods_lbl = built.get("tab_gods_label") as Label
	
	_item_list_scroll = built.get("item_list_scroll") as ScrollContainer
	_item_list_container = built.get("item_list_container") as VBoxContainer
	_inspector_panel = built.get("inspector_panel") as PanelContainer
	_inspector_icon_frame = built.get("inspector_icon_frame") as PanelContainer
	_inspector_icon_rect = built.get("inspector_icon_rect") as TextureRect
	_inspector_title_lbl = built.get("inspector_title_label") as Label
	_inspector_stats_hbox = built.get("inspector_stats_hbox") as HBoxContainer
	_inspector_desc_lbl = built.get("inspector_desc_label") as Label
	_inspector_actions_vbox = built.get("inspector_actions_vbox") as VBoxContainer
	_feedback_label = built.get("feedback_label") as Label
	
	_connect_ui_signals()
	_connect_inventory_signal()
	_connect_party_signal()
	_connect_progression_signals()
	_update_visibility()

func _exit_tree() -> void:
	_disconnect_inventory_signal()
	_disconnect_party_signal()
	_disconnect_progression_signals()
	if _is_open and _bound_player != null:
		_bound_player.is_locked = false
	_is_open = false

## Связывает оверлей с узлом Player текущей локации без использования get_parent()
func bind_player(p_player: Player) -> void:
	_bound_player = p_player

func is_menu_open() -> bool:
	return _is_open

func open_menu() -> void:
	if _is_open or not _can_open():
		return
	if GameManager != null:
		GameManager.ensure_party_initialized()
	_connect_progression_signals()
	
	_clamp_selected_party_index()
	_is_open = true
	if _bound_player != null:
		_bound_player.is_locked = true
	
	_set_feedback("Выберите слот куклы слева или предмет в сетке справа (двойной клик — быстрое действие).", false)
	_update_visibility()
	_refresh_all()
	inventory_opened.emit()

func close_menu() -> void:
	if not _is_open:
		return
	_is_open = false
	_update_visibility()
	if _bound_player != null:
		_bound_player.is_locked = false
	inventory_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action(TOGGLE_ACTION_NAME) and event.is_action_pressed(TOGGLE_ACTION_NAME):
		if _is_open:
			get_viewport().set_input_as_handled()
			close_menu()
			return
		if _can_open():
			get_viewport().set_input_as_handled()
			open_menu()
			return
	
	if _is_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_menu()

func _can_open() -> bool:
	if GameManager != null and GameManager.is_in_battle:
		return false
	if _bound_player != null and _bound_player.is_locked:
		return false
	return true

func _connect_ui_signals() -> void:
	if _hud_toggle_btn != null and not _hud_toggle_btn.pressed.is_connected(_on_hud_toggle_pressed):
		_hud_toggle_btn.pressed.connect(_on_hud_toggle_pressed)
	if _close_btn != null and not _close_btn.pressed.is_connected(close_menu):
		_close_btn.pressed.connect(close_menu)
	if _tab_eq_btn != null and not _tab_eq_btn.pressed.is_connected(_on_tab_equipment_pressed):
		_tab_eq_btn.pressed.connect(_on_tab_equipment_pressed)
	if _tab_cons_btn != null and not _tab_cons_btn.pressed.is_connected(_on_tab_consumables_pressed):
		_tab_cons_btn.pressed.connect(_on_tab_consumables_pressed)
	if _tab_ship_btn != null and not _tab_ship_btn.pressed.is_connected(_on_tab_ship_pressed):
		_tab_ship_btn.pressed.connect(_on_tab_ship_pressed)
	if _tab_runes_btn != null and not _tab_runes_btn.pressed.is_connected(_on_tab_runes_pressed):
		_tab_runes_btn.pressed.connect(_on_tab_runes_pressed)
	if _tab_gods_btn != null and not _tab_gods_btn.pressed.is_connected(_on_tab_gods_pressed):
		_tab_gods_btn.pressed.connect(_on_tab_gods_pressed)

func _connect_inventory_signal() -> void:
	if _is_listening_inventory or GameManager == null or GameManager.inventory == null:
		return
	if not GameManager.inventory.inventory_changed.is_connected(_on_inventory_changed):
		GameManager.inventory.inventory_changed.connect(_on_inventory_changed)
	_is_listening_inventory = true

func _disconnect_inventory_signal() -> void:
	if not _is_listening_inventory or GameManager == null or GameManager.inventory == null:
		return
	if GameManager.inventory.inventory_changed.is_connected(_on_inventory_changed):
		GameManager.inventory.inventory_changed.disconnect(_on_inventory_changed)
	_is_listening_inventory = false

func _connect_party_signal() -> void:
	if _is_listening_party or GameManager == null:
		return
	if not GameManager.party_changed.is_connected(_on_party_changed):
		GameManager.party_changed.connect(_on_party_changed)
	_is_listening_party = true

func _disconnect_party_signal() -> void:
	if not _is_listening_party or GameManager == null:
		return
	if GameManager.party_changed.is_connected(_on_party_changed):
		GameManager.party_changed.disconnect(_on_party_changed)
	_is_listening_party = false

func _connect_progression_signals() -> void:
	if _is_listening_progression or GameManager == null:
		return
	if GameManager.rune_state != null and not GameManager.rune_state.runes_changed.is_connected(_on_progression_changed):
		GameManager.rune_state.runes_changed.connect(_on_progression_changed)
	if GameManager.god_state != null and not GameManager.god_state.gods_changed.is_connected(_on_progression_changed):
		GameManager.god_state.gods_changed.connect(_on_progression_changed)
	_is_listening_progression = true

func _disconnect_progression_signals() -> void:
	if not _is_listening_progression or GameManager == null:
		return
	if GameManager.rune_state != null and GameManager.rune_state.runes_changed.is_connected(_on_progression_changed):
		GameManager.rune_state.runes_changed.disconnect(_on_progression_changed)
	if GameManager.god_state != null and GameManager.god_state.gods_changed.is_connected(_on_progression_changed):
		GameManager.god_state.gods_changed.disconnect(_on_progression_changed)
	_is_listening_progression = false

func _on_hud_toggle_pressed() -> void:
	if _is_open:
		close_menu()
	elif _can_open():
		open_menu()

func _on_tab_equipment_pressed() -> void:
	_active_tab = ActiveTab.EQUIPMENT
	_reset_right_scroll()
	_refresh_right_column()

func _on_tab_consumables_pressed() -> void:
	_active_tab = ActiveTab.CONSUMABLES
	_reset_right_scroll()
	_refresh_right_column()

func _on_tab_ship_pressed() -> void:
	_active_tab = ActiveTab.SHIP_ROSTER
	_reset_right_scroll()
	_refresh_right_column()

func _on_tab_runes_pressed() -> void:
	_active_tab = ActiveTab.RUNES
	_reset_right_scroll()
	_refresh_right_column()

func _on_tab_gods_pressed() -> void:
	_active_tab = ActiveTab.GODS
	_reset_right_scroll()
	_refresh_right_column()

func _reset_right_scroll() -> void:
	if _item_list_scroll != null:
		_item_list_scroll.scroll_vertical = 0

func _on_inventory_changed() -> void:
	if _is_open:
		_refresh_all()

func _on_party_changed() -> void:
	_clamp_selected_party_index()
	if _is_open:
		_refresh_all()

func _on_progression_changed() -> void:
	if _is_open:
		_refresh_all()

func _update_visibility() -> void:
	if _overlay_root != null:
		_overlay_root.visible = _is_open
	if _hud_toggle_btn != null:
		_hud_toggle_btn.visible = not _is_open

func _clamp_selected_party_index() -> void:
	if GameManager == null or GameManager.active_party.is_empty():
		_selected_party_index = 0
		return
	_selected_party_index = clampi(_selected_party_index, 0, GameManager.active_party.size() - 1)

func _get_selected_member_data() -> CombatantData:
	if GameManager == null:
		return null
	GameManager.ensure_party_initialized()
	if GameManager.active_party.is_empty():
		return null
	_clamp_selected_party_index()
	return GameManager.active_party[_selected_party_index]

func _on_party_member_button_pressed(idx: int) -> void:
	_selected_party_index = idx
	_clamp_selected_party_index()
	var selected: CombatantData = _get_selected_member_data()
	if selected != null:
		_set_feedback("Активный боец: %s (%s)." % [
			selected.display_name,
			selected.role_title if not selected.role_title.is_empty() else "Боец"
		], false)
	_refresh_all()

# =========================================================================
# ПОЛНОЕ ОБНОВЛЕНИЕ ШАПКИ, КУКЛЫ СЛЕВА И ВКЛАДОК СПРАВА
# =========================================================================

func _refresh_all() -> void:
	_clamp_selected_party_index()
	var member_data: CombatantData = _get_selected_member_data()
	var status: Dictionary = GameManager.get_party_member_status(member_data) if (GameManager != null and member_data != null) else {}
	_rebuild_portrait_selector()
	_refresh_header_and_doll(member_data, status)
	_rebuild_doll_slots_and_crest(member_data, status)
	_refresh_bars_stats_and_traits(member_data, status)
	_refresh_right_column()

func _rebuild_portrait_selector() -> void:
	if _member_selector_hbox == null:
		return
	for child: Node in _member_selector_hbox.get_children():
		child.queue_free()
	if GameManager == null:
		return
	
	for i: int in range(GameManager.active_party.size()):
		var m: CombatantData = GameManager.active_party[i]
		if m == null:
			continue
		var is_sel: bool = (i == _selected_party_index)
		var has_res: bool = (
			not m.is_hero
			and GameManager.rune_state != null
			and GameManager.rune_state.is_rune_in_bind(m.ancestral_rune_id)
		)
		var btn: Button = Button.new()
		btn.text = ""
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(36.0, 36.0)
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var st_normal: StyleBoxTexture = InventoryVisualFactory.get_slot_style("selected" if is_sel else "normal")
		var st_hover: StyleBoxTexture = InventoryVisualFactory.get_slot_style("selected" if is_sel else "hover")
		btn.add_theme_stylebox_override("normal", st_normal)
		btn.add_theme_stylebox_override("hover", st_hover)
		btn.add_theme_stylebox_override("pressed", InventoryVisualFactory.get_slot_style("selected"))
		btn.tooltip_text = "%d. %s (%s)%s" % [
			i + 1,
			m.display_name,
			"Поток" if m.is_hero else BattleTypes.get_resource_display_name(m.primary_resource),
			" · ✦ Резонанс руны активен!" if has_res else ""
		]
		
		var p_rect: TextureRect = TextureRect.new()
		p_rect.texture = InventoryVisualFactory.get_fighter_portrait(m)
		p_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		p_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_rect.position = Vector2(4.0, 4.0)
		p_rect.size = Vector2(28.0, 28.0)
		p_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(p_rect)
		
		var num_lbl: Label = Label.new()
		num_lbl.text = str(i + 1)
		num_lbl.position = Vector2(3.0, 1.0)
		num_lbl.add_theme_font_size_override("font_size", 7)
		num_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD if is_sel else InventoryVisualFactory.TEXT_SECONDARY)
		num_lbl.add_theme_color_override("font_outline_color", InventoryVisualFactory.OUTLINE_DARK)
		num_lbl.add_theme_constant_override("outline_size", 2)
		num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(num_lbl)
		
		if has_res:
			var res_star: Label = Label.new()
			res_star.text = "✦"
			res_star.position = Vector2(25.0, 0.0)
			res_star.add_theme_font_size_override("font_size", 8)
			res_star.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_RUNE_CYAN)
			res_star.add_theme_color_override("font_outline_color", InventoryVisualFactory.OUTLINE_DARK)
			res_star.add_theme_constant_override("outline_size", 2)
			res_star.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(res_star)
		
		var captured_idx: int = i
		btn.pressed.connect(func() -> void:
			_on_party_member_button_pressed(captured_idx)
		)
		_member_selector_hbox.add_child(btn)

func _refresh_header_and_doll(member_data: CombatantData, _status: Dictionary) -> void:
	if _title_label != null:
		_title_label.text = "ИНВЕНТАРЬ"
	if member_data == null:
		if _subtitle_label != null:
			_subtitle_label.text = ""
		if _member_profile_label != null:
			_member_profile_label.text = ""
		if _doll_fullbody_sprite != null:
			_doll_fullbody_sprite.texture = null
		return
	
	var role_str: String = member_data.role_title if not member_data.role_title.is_empty() else ("Лидер" if member_data.is_hero else "Рекрут")
	if _subtitle_label != null:
		_subtitle_label.text = "%s · %s" % [member_data.display_name, role_str]
	if _member_profile_label != null:
		var cat_short: String = "Фирм. ГГ" if member_data.is_hero else InventoryTypes.get_weapon_category_display_name(member_data.weapon_category)
		var hands_cnt: int = member_data.equipment_loadout.available_hands if member_data.equipment_loadout != null else 2
		_member_profile_label.text = "%s · %s" % [cat_short, "1 рука" if hands_cnt == 1 else "2 руки"]
	if _doll_fullbody_sprite != null:
		_doll_fullbody_sprite.texture = InventoryVisualFactory.get_fighter_fullbody(member_data)

func _rebuild_doll_slots_and_crest(member_data: CombatantData, status: Dictionary) -> void:
	if _left_slots_col == null or _right_slots_col == null:
		return
	for child: Node in _left_slots_col.get_children():
		child.queue_free()
	for child: Node in _right_slots_col.get_children():
		child.queue_free()
	if member_data == null or member_data.equipment_loadout == null:
		return
	
	var loadout: EquipmentLoadout = member_data.equipment_loadout
	# Левый столбец (3 слота): Левая рука, Тело, Аксессуар 1
	_left_slots_col.add_child(_create_doll_equip_slot(loadout, InventoryTypes.SLOT_LEFT_HAND, "ЛР"))
	_left_slots_col.add_child(_create_doll_equip_slot(loadout, InventoryTypes.SLOT_BODY, "ТЕЛО"))
	_left_slots_col.add_child(_create_doll_equip_slot(loadout, InventoryTypes.SLOT_ACCESSORY_1, "АКС1"))
	
	# Правый столбец: Правая рука, Аксессуар 2 + ячейка-герб (только чтение)
	_right_slots_col.add_child(_create_doll_equip_slot(loadout, InventoryTypes.SLOT_RIGHT_HAND, "ПР"))
	_right_slots_col.add_child(_create_doll_equip_slot(loadout, InventoryTypes.SLOT_ACCESSORY_2, "АКС2"))
	_right_slots_col.add_child(_create_doll_crest_cell(member_data, status))

func _create_doll_equip_slot(loadout: EquipmentLoadout, slot_id: StringName, tag_short: String) -> Button:
	var btn: Button = Button.new()
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(40.0, 40.0)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var two_handed: bool = loadout.is_two_handed_equipped()
	var item: EquipmentItemData = loadout.get_slot_item(slot_id)
	var is_locked_1h: bool = (slot_id == InventoryTypes.SLOT_RIGHT_HAND and loadout.available_hands < 2)
	var is_2h_mirror: bool = (slot_id == InventoryTypes.SLOT_RIGHT_HAND and two_handed and loadout.left_hand != null)
	
	if is_locked_1h:
		btn.add_theme_stylebox_override("normal", InventoryVisualFactory.get_slot_style("locked"))
		btn.add_theme_stylebox_override("hover", InventoryVisualFactory.get_slot_style("locked"))
		btn.add_theme_stylebox_override("pressed", InventoryVisualFactory.get_slot_style("locked"))
		var lock_lbl: Label = Label.new()
		lock_lbl.text = "1Р"
		lock_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 9)
		lock_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD)
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_lbl)
		var msg_1h: String = "Однорукий боец: вторая рука всегда считается свободной (активирует синергии одной руки)."
		btn.tooltip_text = msg_1h
		btn.pressed.connect(func() -> void:
			_set_feedback(msg_1h, false)
		)
		return btn
	
	var display_item: EquipmentItemData = loadout.left_hand if is_2h_mirror else item
	if display_item != null:
		btn.add_theme_stylebox_override("normal", InventoryVisualFactory.get_slot_style("normal"))
		btn.add_theme_stylebox_override("hover", InventoryVisualFactory.get_slot_style("hover"))
		btn.add_theme_stylebox_override("pressed", InventoryVisualFactory.get_slot_style("selected"))
		
		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.texture = InventoryVisualFactory.get_item_icon(display_item)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.position = Vector2(7.0, 6.0)
		icon_rect.size = Vector2(26.0, 26.0)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_2h_mirror:
			icon_rect.modulate = Color(0.75, 0.80, 0.90, 0.45)
		btn.add_child(icon_rect)
		
		var corner_txt: String = "2Р" if (is_2h_mirror or display_item.occupies_both_hands()) else tag_short
		_add_slot_corner_tag(btn, corner_txt, InventoryVisualFactory.TEXT_GOLD if is_2h_mirror else InventoryVisualFactory.TEXT_SECONDARY)
		
		var slot_name: String = InventoryTypes.get_slot_display_name(slot_id)
		var hover_info: String = "%s: %s (%s) — клик: снять в сумку." % [slot_name, display_item.display_name, display_item.get_stat_summary()]
		btn.tooltip_text = hover_info
		btn.mouse_entered.connect(func() -> void:
			_set_feedback(hover_info, false)
		)
		var captured_slot: StringName = slot_id
		btn.pressed.connect(func() -> void:
			_on_slot_unequip_pressed(captured_slot)
		)
	else:
		btn.add_theme_stylebox_override("normal", InventoryVisualFactory.get_slot_style("disabled"))
		btn.add_theme_stylebox_override("hover", InventoryVisualFactory.get_slot_style("normal"))
		btn.add_theme_stylebox_override("pressed", InventoryVisualFactory.get_slot_style("normal"))
		
		var ghost_rect: TextureRect = TextureRect.new()
		ghost_rect.texture = InventoryVisualFactory.get_empty_slot_icon(slot_id)
		ghost_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ghost_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost_rect.position = Vector2(12.0, 10.0)
		ghost_rect.size = Vector2(16.0, 16.0)
		ghost_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(ghost_rect)
		
		_add_slot_corner_tag(btn, tag_short, InventoryVisualFactory.TEXT_DISABLED)
		var empty_tip: String = "%s: пусто (выберите предмет в сетке «ЭКИП» справа)." % InventoryTypes.get_slot_display_name(slot_id)
		btn.tooltip_text = empty_tip
		btn.pressed.connect(func() -> void:
			_set_feedback(empty_tip, false)
		)
	
	return btn

func _create_doll_crest_cell(member_data: CombatantData, status: Dictionary) -> Button:
	var btn: Button = Button.new()
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(40.0, 40.0)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var eff_god: BattleTypes.GodId = member_data.patron_god
	if member_data.is_hero and GameManager != null and GameManager.god_state != null:
		eff_god = GameManager.god_state.active_patron
	var syn_arr_v: Variant = status.get("active_synergies", [])
	var has_syn: bool = (syn_arr_v is Array) and not (syn_arr_v as Array).is_empty()
	var bl_arr_v: Variant = status.get("active_blessings", [])
	var has_bl: bool = (bl_arr_v is Array) and not (bl_arr_v as Array).is_empty()
	var has_god: bool = (eff_god != BattleTypes.GodId.NONE) or has_bl
	
	var st_key: String = "selected" if (has_bl or has_syn) else "card"
	btn.add_theme_stylebox_override("normal", InventoryVisualFactory.get_slot_style(st_key))
	btn.add_theme_stylebox_override("hover", InventoryVisualFactory.get_slot_style("hover"))
	btn.add_theme_stylebox_override("pressed", InventoryVisualFactory.get_slot_style("selected"))
	
	var ic: TextureRect = TextureRect.new()
	ic.texture = InventoryVisualFactory.get_crest_icon(has_god, has_syn)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = Vector2(9.0, 7.0)
	ic.size = Vector2(22.0, 22.0)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(ic)
	
	_add_slot_corner_tag(btn, "ГЕРБ", InventoryVisualFactory.TEXT_GOLD if (has_bl or has_syn) else InventoryVisualFactory.TEXT_SECONDARY)
	
	var summary_parts: PackedStringArray = PackedStringArray()
	if eff_god != BattleTypes.GodId.NONE:
		summary_parts.append("Покровитель: %s" % BattleTypes.get_god_display_name(eff_god))
	if has_bl and bl_arr_v is Array:
		var b_list: PackedStringArray = PackedStringArray()
		for b_item: Variant in bl_arr_v:
			b_list.append(str(b_item))
		summary_parts.append("Дар отряда: %s" % ", ".join(b_list))
	if has_syn and syn_arr_v is Array:
		var s_list: PackedStringArray = PackedStringArray()
		for s_item: Variant in syn_arr_v:
			if s_item is WeaponSynergyData:
				s_list.append((s_item as WeaponSynergyData).display_name)
		summary_parts.append("Синергия рук: %s" % ", ".join(s_list))
	if summary_parts.is_empty():
		summary_parts.append("Герб бойца: нет активной парной синергии или дара бога.")
	var crest_msg: String = " · ".join(summary_parts)
	btn.tooltip_text = crest_msg
	btn.mouse_entered.connect(func() -> void:
		_set_feedback(crest_msg, false)
	)
	btn.pressed.connect(func() -> void:
		_set_feedback(crest_msg, false)
	)
	return btn

func _add_slot_corner_tag(btn: Button, txt: String, col: Color) -> void:
	var lbl: Label = Label.new()
	lbl.text = txt
	lbl.position = Vector2(3.0, 28.0)
	lbl.size = Vector2(34.0, 10.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", InventoryVisualFactory.OUTLINE_DARK)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

func _refresh_bars_stats_and_traits(member_data: CombatantData, status: Dictionary) -> void:
	if member_data == null or status.is_empty():
		return
	
	# 1. Шкала HP
	var cur_hp: int = int(status.get("current_hp", 100))
	var max_hp_v: int = maxi(1, int(status.get("max_hp", 100)))
	if _hp_bar != null:
		_hp_bar.max_value = float(max_hp_v)
		_hp_bar.value = float(cur_hp)
	if _hp_bar_label != null:
		_hp_bar_label.text = "HP %d/%d" % [cur_hp, max_hp_v]
	
	# 2. Шкала Потока / единственного бака рекрута
	var work_type: BattleTypes.ResourceType = member_data.primary_resource
	if member_data.is_hero and member_data.equipment_loadout != null:
		work_type = member_data.equipment_loadout.resolve_hero_flow_mode(member_data.default_flow_mode)
	elif not member_data.is_hero:
		work_type = member_data.get_validated_primary_resource()
	
	var res_cur: int = 100
	var res_max: int = 100
	if bool(status.get("has_mana", false)) and work_type == BattleTypes.ResourceType.MANA:
		res_cur = int(status.get("current_mana", 100))
		res_max = maxi(1, int(status.get("max_mana", 100)))
	else:
		match work_type:
			BattleTypes.ResourceType.RAGE:
				res_cur = member_data.initial_rage
				res_max = maxi(1, member_data.max_rage)
			BattleTypes.ResourceType.HAMINGJA:
				res_cur = member_data.initial_hamingja
				res_max = maxi(1, member_data.max_hamingja)
			_:
				res_cur = member_data.initial_energy
				res_max = maxi(1, member_data.max_energy)
	
	if _res_bar != null:
		_res_bar.max_value = float(res_max)
		_res_bar.value = float(res_cur)
		_res_bar.add_theme_stylebox_override("fill", InventoryVisualFactory.get_bar_fill_style(InventoryVisualFactory.get_resource_bar_color(work_type)))
	if _res_bar_icon != null:
		_res_bar_icon.texture = InventoryVisualFactory.get_resource_icon(work_type)
	if _res_bar_label != null:
		var tag_str: String = "Поток(%s)" % BattleTypes.get_resource_short_tag(work_type) if member_data.is_hero else BattleTypes.get_resource_short_tag(work_type)
		_res_bar_label.text = "%s %d/%d" % [tag_str, res_cur, res_max]
	
	# 3. Иконочная полоса статов
	if _atk_val_lbl != null:
		_atk_val_lbl.text = str(int(status.get("attack", 10)))
	if _mag_val_lbl != null:
		_mag_val_lbl.text = str(int(status.get("magic_power", 10)))
	if _def_val_lbl != null:
		_def_val_lbl.text = str(int(status.get("defense", 5)))
	if _spd_val_lbl != null:
		_spd_val_lbl.text = str(int(status.get("speed", 10)))
	if _crit_val_lbl != null:
		_crit_val_lbl.text = "%d%%" % roundi(float(status.get("crit_chance", 0.05)) * 100.0)
	
	# 4. Компактная сводка синергии, Резонанса, Дара бога и ограничений
	if _synergy_label != null:
		var lines: PackedStringArray = PackedStringArray()
		var line1_parts: PackedStringArray = PackedStringArray()
		var syn_v: Variant = status.get("active_synergies", [])
		if syn_v is Array and not (syn_v as Array).is_empty():
			for entry: Variant in syn_v:
				if entry is WeaponSynergyData:
					line1_parts.append("✦ %s" % (entry as WeaponSynergyData).display_name)
		elif member_data.equipment_loadout != null and member_data.equipment_loadout.has_shield_equipped():
			line1_parts.append("✦ Щит (блок)")
		
		if bool(status.get("has_resonance", false)):
			line1_parts.append("✦ Резонанс %s" % str(status.get("resonance_label", "")))
		var bl_v: Variant = status.get("active_blessings", [])
		if bl_v is Array and not (bl_v as Array).is_empty():
			line1_parts.append("✦ Дар бога")
		if bool(status.get("has_flow_passive", false)):
			line1_parts.append("🔥 ≥90%→Ожог")
		
		if not line1_parts.is_empty():
			lines.append(" · ".join(line1_parts))
		
		var rules_parts: PackedStringArray = PackedStringArray()
		rules_parts.append("Тяж: %s" % ("да" if (member_data.is_hero or member_data.can_wear_heavy) else "НЕТ"))
		if not member_data.gifts.is_empty():
			var g_names: PackedStringArray = PackedStringArray()
			for g: InventoryTypes.RelicGift in member_data.gifts:
				g_names.append(InventoryTypes.get_relic_gift_display_name(g))
			rules_parts.append("Дары: %s" % ",".join(g_names))
		var ult_name: String = str(status.get("ultimate_skill_name", ""))
		if not ult_name.is_empty():
			rules_parts.append("★ %s" % ult_name)
		lines.append(" · ".join(rules_parts))
		_synergy_label.text = "\n".join(lines)

# =========================================================================
# ПЕРЕКЛЮЧЕНИЕ 5 ВКЛАДОК ПРАВОЙ ПАНЕЛИ
# =========================================================================

func _refresh_right_column() -> void:
	_apply_tab_visual(_tab_eq_btn, _tab_eq_lbl, _active_tab == ActiveTab.EQUIPMENT, "ЭКИП")
	_apply_tab_visual(_tab_cons_btn, _tab_cons_lbl, _active_tab == ActiveTab.CONSUMABLES, "ВЕЩИ")
	
	var ship_cnt: int = GameManager.ship_roster.size() if GameManager != null else 0
	var ship_cap: String = "ОТРЯД(%d)" % ship_cnt if ship_cnt > 0 else "ОТРЯД"
	_apply_tab_visual(_tab_ship_btn, _tab_ship_lbl, _active_tab == ActiveTab.SHIP_ROSTER, ship_cap)
	
	var signs_cnt: int = GameManager.rune_state.signs_available if (GameManager != null and GameManager.rune_state != null) else 0
	var runes_cap: String = "РУНЫ(%d)" % signs_cnt if signs_cnt > 0 else "РУНЫ"
	_apply_tab_visual(_tab_runes_btn, _tab_runes_lbl, _active_tab == ActiveTab.RUNES, runes_cap)
	
	_apply_tab_visual(_tab_gods_btn, _tab_gods_lbl, _active_tab == ActiveTab.GODS, "БОГИ")
	
	var show_inspector: bool = (_active_tab == ActiveTab.EQUIPMENT or _active_tab == ActiveTab.CONSUMABLES)
	if _inspector_panel != null:
		_inspector_panel.visible = show_inspector
	
	var member_data: CombatantData = _get_selected_member_data()
	match _active_tab:
		ActiveTab.EQUIPMENT:
			_rebuild_equipment_grid(member_data)
		ActiveTab.CONSUMABLES:
			_rebuild_consumables_grid(member_data)
		ActiveTab.SHIP_ROSTER:
			_rebuild_ship_roster_list()
		ActiveTab.RUNES:
			_rebuild_runes_tab()
		ActiveTab.GODS:
			_rebuild_gods_tab()

func _apply_tab_visual(btn: Button, lbl: Label, is_active: bool, caption: String) -> void:
	if btn == null:
		return
	var st_norm: StyleBoxTexture = InventoryVisualFactory.get_tab_style(is_active, false)
	var st_hov: StyleBoxTexture = InventoryVisualFactory.get_tab_style(is_active, true)
	btn.add_theme_stylebox_override("normal", st_norm)
	btn.add_theme_stylebox_override("hover", st_hov)
	btn.add_theme_stylebox_override("pressed", InventoryVisualFactory.get_tab_style(true, false))
	if lbl != null:
		lbl.text = caption
		lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD if is_active else InventoryVisualFactory.TEXT_PRIMARY)

# =========================================================================
# ВКЛАДКА 1: ЭКИП (СЕТКА 5 КОЛОНОК + НИЖНИЙ ИНСПЕКТОР)
# =========================================================================

func _rebuild_equipment_grid(member_data: CombatantData) -> void:
	if _item_list_container == null:
		return
	_clear_right_list()
	if GameManager == null or GameManager.inventory == null:
		_populate_empty_inspector("Инвентарь недоступен")
		return
	
	var items: Array[EquipmentItemData] = GameManager.inventory.get_all_equipment()
	if items.is_empty():
		_selected_equip_index = -1
	else:
		_selected_equip_index = clampi(_selected_equip_index, 0, items.size() - 1)
	
	var grid: GridContainer = GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	_item_list_container.add_child(grid)
	
	var total_cells: int = maxi(MIN_GRID_CELLS, int(ceil(float(items.size()) / float(GRID_COLUMNS))) * GRID_COLUMNS)
	for idx: int in range(total_cells):
		if idx < items.size() and items[idx] != null:
			grid.add_child(_create_equip_grid_cell(items[idx], idx, member_data))
		else:
			grid.add_child(_create_empty_grid_cell())
	
	if _selected_equip_index >= 0 and _selected_equip_index < items.size():
		_populate_equipment_inspector(items[_selected_equip_index], member_data)
	else:
		_populate_empty_inspector("В сумке нет свободного снаряжения.")

func _create_equip_grid_cell(eq: EquipmentItemData, idx: int, member_data: CombatantData) -> Button:
	var is_sel: bool = (idx == _selected_equip_index)
	var compat: Dictionary = _evaluate_equipment_compatibility(member_data, eq)
	var allowed_any: bool = bool(compat.get("allowed", false))
	var pref_slot: StringName = compat.get("preferred_slot", InventoryTypes.SLOT_LEFT_HAND) as StringName
	
	var btn: Button = Button.new()
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(62.0, 44.0)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_stylebox_override("normal", InventoryVisualFactory.get_slot_style("selected" if is_sel else "normal"))
	btn.add_theme_stylebox_override("hover", InventoryVisualFactory.get_slot_style("selected" if is_sel else "hover"))
	btn.add_theme_stylebox_override("pressed", InventoryVisualFactory.get_slot_style("selected"))
	btn.tooltip_text = "%s\n(клик — осмотр, двойной клик — надеть)" % eq.display_name
	
	var ic: TextureRect = TextureRect.new()
	ic.texture = InventoryVisualFactory.get_item_icon(eq)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = Vector2(17.0, 8.0)
	ic.size = Vector2(28.0, 28.0)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not allowed_any:
		ic.modulate = Color(0.46, 0.50, 0.58, 0.72)
	btn.add_child(ic)
	
	if eq.is_legendary or eq.is_hero_signature:
		var badge: Label = Label.new()
		badge.text = "★" if eq.is_legendary else "✦"
		badge.position = Vector2(4.0, 1.0)
		badge.add_theme_font_size_override("font_size", 8)
		badge.add_theme_color_override("font_color", InventoryVisualFactory.GOLD_BRIGHT if eq.is_legendary else InventoryVisualFactory.TEXT_RUNE_CYAN)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(badge)
	
	if not allowed_any:
		var lock_mark: Label = Label.new()
		lock_mark.text = "✕"
		lock_mark.position = Vector2(49.0, 1.0)
		lock_mark.add_theme_font_size_override("font_size", 8)
		lock_mark.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_DANGER)
		lock_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_mark)
	elif eq.occupies_both_hands():
		var h2_lbl: Label = Label.new()
		h2_lbl.text = "2Р"
		h2_lbl.position = Vector2(45.0, 29.0)
		h2_lbl.add_theme_font_size_override("font_size", 7)
		h2_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_SECONDARY)
		h2_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(h2_lbl)
	
	var captured_idx: int = idx
	var captured_eq: EquipmentItemData = eq
	var captured_slot: StringName = pref_slot
	btn.pressed.connect(func() -> void:
		_selected_equip_index = captured_idx
		_refresh_right_column()
	)
	btn.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb: InputEventMouseButton = ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and mb.double_click:
				btn.accept_event()
				_on_equip_clicked(captured_eq, captured_slot)
	)
	return btn

func _evaluate_equipment_compatibility(member_data: CombatantData, eq: EquipmentItemData) -> Dictionary:
	if member_data == null or member_data.equipment_loadout == null or eq == null:
		return {"allowed": false, "reason": "Боец не выбран.", "preferred_slot": InventoryTypes.SLOT_LEFT_HAND}
	var loadout: EquipmentLoadout = member_data.equipment_loadout
	var candidate_slots: Array[StringName] = []
	if eq.occupies_both_hands():
		candidate_slots = [InventoryTypes.SLOT_LEFT_HAND]
	elif eq.slot_type == InventoryTypes.EquipmentSlotType.ONE_HAND:
		if eq.is_shield_item():
			candidate_slots = [InventoryTypes.SLOT_RIGHT_HAND, InventoryTypes.SLOT_LEFT_HAND]
		else:
			candidate_slots = [InventoryTypes.SLOT_LEFT_HAND, InventoryTypes.SLOT_RIGHT_HAND]
	elif eq.is_shield_item():
		candidate_slots = [InventoryTypes.SLOT_RIGHT_HAND, InventoryTypes.SLOT_LEFT_HAND]
	elif eq.slot_type == InventoryTypes.EquipmentSlotType.BODY:
		candidate_slots = [InventoryTypes.SLOT_BODY]
	else:
		var first_acc: StringName = InventoryTypes.SLOT_ACCESSORY_2 if (loadout.accessory_1 != null and loadout.accessory_2 == null) else InventoryTypes.SLOT_ACCESSORY_1
		candidate_slots = [first_acc, InventoryTypes.SLOT_ACCESSORY_1, InventoryTypes.SLOT_ACCESSORY_2]
	
	var first_reason: String = ""
	for sl: StringName in candidate_slots:
		var chk: Dictionary = loadout.can_equip_for_combatant(member_data, sl, eq)
		if bool(chk.get("ok", false)):
			return {"allowed": true, "reason": "", "preferred_slot": sl}
		if first_reason.is_empty():
			first_reason = str(chk.get("reason", ""))
	return {"allowed": false, "reason": first_reason, "preferred_slot": candidate_slots[0]}

func _populate_equipment_inspector(eq: EquipmentItemData, member_data: CombatantData) -> void:
	_clear_inspector_children()
	if eq == null:
		_populate_empty_inspector("Предмет не выбран.")
		return
	
	if _inspector_icon_frame != null:
		_inspector_icon_frame.add_theme_stylebox_override("panel", InventoryVisualFactory.get_slot_style("selected"))
	if _inspector_icon_rect != null:
		_inspector_icon_rect.texture = InventoryVisualFactory.get_item_icon(eq)
	
	if _inspector_title_lbl != null:
		_inspector_title_lbl.text = "%s%s" % [eq.display_name, _format_item_badges(eq)]
		var title_col: Color = InventoryVisualFactory.TEXT_PRIMARY
		if eq.is_legendary:
			title_col = Color("#ff9e3d")
		elif eq.is_hero_signature:
			title_col = InventoryVisualFactory.TEXT_RUNE_CYAN
		elif eq.is_unique:
			title_col = InventoryVisualFactory.TEXT_GOLD
		_inspector_title_lbl.add_theme_color_override("font_color", title_col)
	
	# Строка иконочных статов предмета
	if _inspector_stats_hbox != null:
		if eq.bonus_attack != 0:
			_add_inspector_stat_badge("atk", "%+d" % eq.bonus_attack)
		if eq.bonus_magic_power != 0:
			_add_inspector_stat_badge("mag", "%+d" % eq.bonus_magic_power)
		if eq.bonus_defense != 0:
			_add_inspector_stat_badge("def", "%+d" % eq.bonus_defense)
		if eq.bonus_speed != 0:
			_add_inspector_stat_badge("spd", "%+d" % eq.bonus_speed)
		if not is_zero_approx(eq.bonus_crit_chance):
			_add_inspector_stat_badge("crit", "%+d%%" % roundi(eq.bonus_crit_chance * 100.0))
		if eq.bonus_max_hp != 0:
			_add_inspector_text_badge("%+d HP" % eq.bonus_max_hp, InventoryVisualFactory.BAR_HP.lightened(0.3))
	
	var compat: Dictionary = _evaluate_equipment_compatibility(member_data, eq)
	var allowed_any: bool = bool(compat.get("allowed", false))
	if _inspector_desc_lbl != null:
		if not allowed_any:
			_inspector_desc_lbl.text = "Недоступно: %s" % str(compat.get("reason", ""))
			_inspector_desc_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_DANGER)
		else:
			var sk_names: PackedStringArray = PackedStringArray()
			for sk: SkillData in eq.granted_skills:
				if sk != null:
					sk_names.append(sk.skill_name)
			if eq.is_legendary:
				for l_sk: SkillData in eq.legendary_skills:
					if l_sk != null:
						sk_names.append("★%s" % l_sk.skill_name)
			var cat_txt: String = InventoryTypes.get_slot_type_display_name(eq.slot_type)
			if eq.weapon_type != InventoryTypes.WeaponType.NONE:
				cat_txt = InventoryTypes.get_weapon_type_display_name(eq.weapon_type)
			var sk_part: String = " · Навыки: %s" % ", ".join(sk_names) if not sk_names.is_empty() else ""
			if eq.is_shield_item():
				sk_part = " · Блок 100%%: %d%%" % roundi(eq.shield_full_block_chance * 100.0)
			_inspector_desc_lbl.text = "%s%s" % [cat_txt, sk_part]
			_inspector_desc_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_SECONDARY)
	
	# Кнопки надевания справа в инспекторе
	var loadout: EquipmentLoadout = member_data.equipment_loadout if member_data != null else null
	if _inspector_actions_vbox != null:
		if eq.occupies_both_hands():
			_add_inspector_equip_btn(member_data, loadout, eq, InventoryTypes.SLOT_LEFT_HAND, "Надеть")
		elif eq.slot_type == InventoryTypes.EquipmentSlotType.ONE_HAND or eq.is_shield_item():
			_add_inspector_equip_btn(member_data, loadout, eq, InventoryTypes.SLOT_LEFT_HAND, "В лев.")
			_add_inspector_equip_btn(member_data, loadout, eq, InventoryTypes.SLOT_RIGHT_HAND, "В прав.")
		elif eq.slot_type == InventoryTypes.EquipmentSlotType.BODY:
			_add_inspector_equip_btn(member_data, loadout, eq, InventoryTypes.SLOT_BODY, "Надеть")
		elif eq.slot_type == InventoryTypes.EquipmentSlotType.ACCESSORY:
			_add_inspector_equip_btn(member_data, loadout, eq, InventoryTypes.SLOT_ACCESSORY_1, "Акс. 1")
			_add_inspector_equip_btn(member_data, loadout, eq, InventoryTypes.SLOT_ACCESSORY_2, "Акс. 2")

func _add_inspector_equip_btn(
	member_data: CombatantData,
	loadout: EquipmentLoadout,
	eq: EquipmentItemData,
	slot_id: StringName,
	caption: String
) -> void:
	if _inspector_actions_vbox == null:
		return
	var chk: Dictionary = loadout.can_equip_for_combatant(member_data, slot_id, eq) if loadout != null else {"ok": false, "reason": ""}
	var ok: bool = bool(chk.get("ok", false))
	var btn: Button = _create_compact_action_btn(caption, str(chk.get("reason", caption)), ok)
	btn.custom_minimum_size = Vector2(58.0, 21.0)
	btn.disabled = not ok
	btn.pressed.connect(func() -> void:
		_on_equip_clicked(eq, slot_id)
	)
	_inspector_actions_vbox.add_child(btn)

# =========================================================================
# ВКЛАДКА 2: ВЕЩИ / РАСХОДНИКИ (СЕТКА 5 КОЛОНОК + НИЖНИЙ ИНСПЕКТОР)
# =========================================================================

func _rebuild_consumables_grid(member_data: CombatantData) -> void:
	if _item_list_container == null:
		return
	_clear_right_list()
	if GameManager == null or GameManager.inventory == null:
		_populate_empty_inspector("Инвентарь недоступен")
		return
	
	var raw_entries: Array[Dictionary] = GameManager.inventory.get_consumables(false, false)
	var valid_entries: Array[Dictionary] = []
	for e: Dictionary in raw_entries:
		var c_item: ConsumableItemData = e.get("item", null) as ConsumableItemData
		var cnt: int = int(e.get("count", 0))
		if c_item != null and cnt > 0:
			valid_entries.append(e)
	
	if valid_entries.is_empty():
		_selected_cons_index = -1
	else:
		_selected_cons_index = clampi(_selected_cons_index, 0, valid_entries.size() - 1)
	
	var grid: GridContainer = GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	_item_list_container.add_child(grid)
	
	var total_cells: int = maxi(MIN_GRID_CELLS, int(ceil(float(valid_entries.size()) / float(GRID_COLUMNS))) * GRID_COLUMNS)
	for idx: int in range(total_cells):
		if idx < valid_entries.size():
			grid.add_child(_create_consumable_grid_cell(valid_entries[idx], idx))
		else:
			grid.add_child(_create_empty_grid_cell())
	
	if _selected_cons_index >= 0 and _selected_cons_index < valid_entries.size():
		_populate_consumable_inspector(valid_entries[_selected_cons_index], member_data)
	else:
		_populate_empty_inspector("Расходники закончились.")

func _create_consumable_grid_cell(entry: Dictionary, idx: int) -> Button:
	var cons: ConsumableItemData = entry.get("item", null) as ConsumableItemData
	var cnt: int = int(entry.get("count", 0))
	var is_sel: bool = (idx == _selected_cons_index)
	
	var btn: Button = Button.new()
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(62.0, 44.0)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_stylebox_override("normal", InventoryVisualFactory.get_slot_style("selected" if is_sel else "normal"))
	btn.add_theme_stylebox_override("hover", InventoryVisualFactory.get_slot_style("selected" if is_sel else "hover"))
	btn.add_theme_stylebox_override("pressed", InventoryVisualFactory.get_slot_style("selected"))
	btn.tooltip_text = "%s x%d\n(клик — осмотр, двойной клик — применить)" % [cons.display_name, cnt]
	
	var ic: TextureRect = TextureRect.new()
	ic.texture = InventoryVisualFactory.get_item_icon(cons)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = Vector2(17.0, 7.0)
	ic.size = Vector2(28.0, 28.0)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not cons.usable_in_overworld:
		ic.modulate = Color(0.58, 0.62, 0.70, 0.80)
	btn.add_child(ic)
	
	var cnt_lbl: Label = Label.new()
	cnt_lbl.text = "x%d" % cnt
	cnt_lbl.position = Vector2(26.0, 29.0)
	cnt_lbl.size = Vector2(32.0, 12.0)
	cnt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cnt_lbl.add_theme_font_size_override("font_size", 8)
	cnt_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_PRIMARY)
	cnt_lbl.add_theme_color_override("font_outline_color", InventoryVisualFactory.OUTLINE_DARK)
	cnt_lbl.add_theme_constant_override("outline_size", 2)
	cnt_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(cnt_lbl)
	
	var captured_idx: int = idx
	var captured_cons: ConsumableItemData = cons
	btn.pressed.connect(func() -> void:
		_selected_cons_index = captured_idx
		_refresh_right_column()
	)
	btn.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb: InputEventMouseButton = ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and mb.double_click and captured_cons.usable_in_overworld:
				btn.accept_event()
				_on_consumable_use_clicked(captured_cons)
	)
	return btn

func _populate_consumable_inspector(entry: Dictionary, member_data: CombatantData) -> void:
	_clear_inspector_children()
	var cons: ConsumableItemData = entry.get("item", null) as ConsumableItemData
	var cnt: int = int(entry.get("count", 0))
	if cons == null:
		_populate_empty_inspector("Расходник не выбран.")
		return
	
	if _inspector_icon_frame != null:
		_inspector_icon_frame.add_theme_stylebox_override("panel", InventoryVisualFactory.get_slot_style("selected"))
	if _inspector_icon_rect != null:
		_inspector_icon_rect.texture = InventoryVisualFactory.get_item_icon(cons)
	
	if _inspector_title_lbl != null:
		_inspector_title_lbl.text = "%s  (в сумке: x%d)" % [cons.display_name, cnt]
		_inspector_title_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD if cons.is_rune_reset_item else InventoryVisualFactory.TEXT_PRIMARY)
	
	var target_name: String = member_data.display_name if member_data != null else "Боец"
	var eff_text: String = cons.get_effect_summary()
	if not cons.is_rune_reset_item and cons.usable_in_overworld:
		eff_text += " → %s" % target_name
	_add_inspector_text_badge(eff_text, InventoryVisualFactory.TEXT_RUNE_CYAN if cons.is_rune_reset_item else InventoryVisualFactory.TEXT_GOLD)
	
	if _inspector_desc_lbl != null:
		_inspector_desc_lbl.text = cons.description
		_inspector_desc_lbl.add_theme_color_override(
			"font_color",
			InventoryVisualFactory.TEXT_SECONDARY if cons.usable_in_overworld else InventoryVisualFactory.TEXT_DANGER
		)
	
	if _inspector_actions_vbox != null:
		var btn_txt: String = "Обряд" if cons.is_rune_reset_item else ("Выпить" if cons.usable_in_overworld else "В бою")
		var use_btn: Button = _create_compact_action_btn(btn_txt, cons.description, cons.usable_in_overworld)
		use_btn.custom_minimum_size = Vector2(58.0, 24.0)
		use_btn.disabled = not cons.usable_in_overworld or member_data == null
		var captured_cons: ConsumableItemData = cons
		use_btn.pressed.connect(func() -> void:
			_on_consumable_use_clicked(captured_cons)
		)
		_inspector_actions_vbox.add_child(use_btn)

func _create_empty_grid_cell() -> Panel:
	var p: Panel = Panel.new()
	p.custom_minimum_size = Vector2(62.0, 44.0)
	p.add_theme_stylebox_override("panel", InventoryVisualFactory.get_slot_style("normal"))
	return p

func _clear_inspector_children() -> void:
	if _inspector_stats_hbox != null:
		for ch: Node in _inspector_stats_hbox.get_children():
			ch.queue_free()
	if _inspector_actions_vbox != null:
		for ch: Node in _inspector_actions_vbox.get_children():
			ch.queue_free()

func _populate_empty_inspector(msg: String) -> void:
	_clear_inspector_children()
	if _inspector_icon_frame != null:
		_inspector_icon_frame.add_theme_stylebox_override("panel", InventoryVisualFactory.get_slot_style("disabled"))
	if _inspector_icon_rect != null:
		_inspector_icon_rect.texture = null
	if _inspector_title_lbl != null:
		_inspector_title_lbl.text = "Пусто"
		_inspector_title_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_DISABLED)
	if _inspector_desc_lbl != null:
		_inspector_desc_lbl.text = msg
		_inspector_desc_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_DISABLED)

func _add_inspector_stat_badge(stat_key: String, val_text: String) -> void:
	if _inspector_stats_hbox == null:
		return
	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 2)
	var ic: TextureRect = TextureRect.new()
	ic.texture = InventoryVisualFactory.get_stat_icon(stat_key)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(11.0, 11.0)
	hb.add_child(ic)
	var lbl: Label = Label.new()
	lbl.text = val_text
	lbl.add_theme_font_size_override("font_size", 8)
	var is_neg: bool = val_text.begins_with("-")
	lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_DANGER if is_neg else InventoryVisualFactory.TEXT_PRIMARY)
	hb.add_child(lbl)
	_inspector_stats_hbox.add_child(hb)

func _add_inspector_text_badge(txt: String, col: Color) -> void:
	if _inspector_stats_hbox == null:
		return
	var lbl: Label = Label.new()
	lbl.text = txt
	lbl.clip_text = true
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", col)
	_inspector_stats_hbox.add_child(lbl)

func _format_item_badges(eq: EquipmentItemData) -> String:
	var tags: PackedStringArray = PackedStringArray()
	if eq.is_hero_signature:
		tags.append("ГГ")
	if eq.is_legendary:
		tags.append("Легенд.")
	elif eq.is_unique and not eq.is_hero_signature:
		tags.append("Уник.")
	if eq.is_set_bundle:
		tags.append("Компл.")
	if eq.is_heavy:
		tags.append("Тяж.")
	return " [%s]" % ", ".join(tags) if not tags.is_empty() else ""

# =========================================================================
# ВКЛАДКА 3: ОТРЯД И ДРАККАР (ship_roster)
# =========================================================================

func _rebuild_ship_roster_list() -> void:
	if _item_list_container == null:
		return
	_clear_right_list()
	if GameManager == null:
		return
	
	_add_section_header("АКТИВНЫЙ СТРОЙ (%d/%d) — слот 1 за ГГ:" % [
		GameManager.active_party.size(),
		BattleContext.MAX_PLAYER_PARTY_SIZE
	], InventoryVisualFactory.TEXT_GOLD)
	
	for i: int in range(GameManager.active_party.size()):
		var p_member: CombatantData = GameManager.active_party[i]
		if p_member == null:
			continue
		var is_sel: bool = (i == _selected_party_index)
		var st: Dictionary = GameManager.get_party_member_status(p_member)
		var card: PanelContainer = _create_item_card_panel(is_sel)
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 5)
		card.add_child(hbox)
		
		var p_icon: TextureRect = TextureRect.new()
		p_icon.texture = InventoryVisualFactory.get_fighter_portrait(p_member)
		p_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		p_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_icon.custom_minimum_size = Vector2(26.0, 26.0)
		hbox.add_child(p_icon)
		
		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 1)
		hbox.add_child(info_vbox)
		
		var role_txt: String = p_member.role_title if not p_member.role_title.is_empty() else ("Лидер" if p_member.is_hero else "Рекрут")
		var res_badge: String = " ✦" if bool(st.get("has_resonance", false)) else ""
		var name_lbl: Label = Label.new()
		name_lbl.text = "%d. %s — %s%s" % [i + 1, p_member.display_name, role_txt, res_badge]
		name_lbl.clip_text = true
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD if is_sel else InventoryVisualFactory.TEXT_PRIMARY)
		info_vbox.add_child(name_lbl)
		
		var sub_lbl: Label = Label.new()
		sub_lbl.text = "HP %d/%d · %s · %s" % [
			int(st.get("current_hp", 100)),
			int(st.get("max_hp", 100)),
			str(st.get("working_resource_name", "Энергия")),
			_format_member_profile_line(p_member)
		]
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_font_size_override("font_size", 8)
		sub_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_SECONDARY)
		info_vbox.add_child(sub_lbl)
		
		var act_vbox: VBoxContainer = VBoxContainer.new()
		act_vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(act_vbox)
		
		var sel_btn: Button = _create_compact_action_btn("Кукла", "Показать бойца на панели куклы слева", false)
		sel_btn.custom_minimum_size = Vector2(56.0, 19.0)
		sel_btn.disabled = is_sel
		var captured_i: int = i
		sel_btn.pressed.connect(func() -> void:
			_on_party_member_button_pressed(captured_i)
		)
		act_vbox.add_child(sel_btn)
		
		if i > 0 and not p_member.is_hero:
			var send_btn: Button = _create_compact_action_btn("В резерв", "Отправить рекрута на драккар", false)
			send_btn.custom_minimum_size = Vector2(56.0, 19.0)
			send_btn.pressed.connect(func() -> void:
				_on_send_to_ship_clicked(captured_i)
			)
			act_vbox.add_child(send_btn)
		
		_item_list_container.add_child(card)
	
	_add_section_header("РЕЗЕРВ ДРАККАРА (%d) — усиливает ᛟ Оталу:" % GameManager.ship_roster.size(), InventoryVisualFactory.TEXT_RUNE_CYAN)
	
	if GameManager.ship_roster.is_empty():
		_add_empty_list_label("На драккаре нет свободных рекрутов.")
		return
	
	for s_idx: int in range(GameManager.ship_roster.size()):
		var s_member: CombatantData = GameManager.ship_roster[s_idx]
		if s_member == null:
			continue
		var s_st: Dictionary = GameManager.get_party_member_status(s_member)
		var card: PanelContainer = _create_item_card_panel(false)
		var vbox_card: VBoxContainer = VBoxContainer.new()
		vbox_card.add_theme_constant_override("separation", 3)
		card.add_child(vbox_card)
		
		var top_hb: HBoxContainer = HBoxContainer.new()
		top_hb.add_theme_constant_override("separation", 5)
		vbox_card.add_child(top_hb)
		
		var sp_icon: TextureRect = TextureRect.new()
		sp_icon.texture = InventoryVisualFactory.get_fighter_portrait(s_member)
		sp_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sp_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sp_icon.custom_minimum_size = Vector2(24.0, 24.0)
		top_hb.add_child(sp_icon)
		
		var txt_vb: VBoxContainer = VBoxContainer.new()
		txt_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		txt_vb.add_theme_constant_override("separation", 1)
		top_hb.add_child(txt_vb)
		
		var name_lbl: Label = Label.new()
		var s_role: String = s_member.role_title if not s_member.role_title.is_empty() else "Рекрут"
		name_lbl.text = "%s — %s (%s)" % [s_member.display_name, s_role, str(s_st.get("working_resource_name", "Ресурс"))]
		name_lbl.clip_text = true
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_PRIMARY)
		txt_vb.add_child(name_lbl)
		
		var sub_lbl: Label = Label.new()
		sub_lbl.text = "HP %d/%d · %s" % [
			int(s_st.get("current_hp", 100)),
			int(s_st.get("max_hp", 100)),
			_format_member_profile_line(s_member)
		]
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_font_size_override("font_size", 8)
		sub_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_SECONDARY)
		txt_vb.add_child(sub_lbl)
		
		var swap_row: HBoxContainer = HBoxContainer.new()
		swap_row.add_theme_constant_override("separation", 3)
		vbox_card.add_child(swap_row)
		
		var captured_ship_idx: int = s_idx
		if GameManager.active_party.size() < BattleContext.MAX_PLAYER_PARTY_SIZE:
			var add_btn: Button = _create_compact_action_btn("В строй (+)", "Добавить рекрута в свободный слот", true)
			add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			add_btn.pressed.connect(func() -> void:
				_on_add_from_ship_clicked(captured_ship_idx)
			)
			swap_row.add_child(add_btn)
		
		for p_idx: int in range(1, GameManager.active_party.size()):
			var target_ally: CombatantData = GameManager.active_party[p_idx]
			if target_ally == null or target_ally.is_hero:
				continue
			var swap_btn: Button = _create_compact_action_btn(
				"↔ %s" % target_ally.display_name,
				"Поменять местами с %s (слот %d)" % [target_ally.display_name, p_idx + 1],
				false
			)
			swap_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var captured_party_idx: int = p_idx
			swap_btn.pressed.connect(func() -> void:
				_on_swap_party_ship_clicked(captured_party_idx, captured_ship_idx)
			)
			swap_row.add_child(swap_btn)
		
		_item_list_container.add_child(card)

func _format_member_profile_line(member_data: CombatantData) -> String:
	if member_data == null:
		return ""
	var parts: PackedStringArray = PackedStringArray()
	parts.append("Фирм. ГГ" if member_data.is_hero else InventoryTypes.get_weapon_category_display_name(member_data.weapon_category))
	var eff_god: BattleTypes.GodId = member_data.patron_god
	if member_data.is_hero and GameManager != null and GameManager.god_state != null:
		eff_god = GameManager.god_state.active_patron
	if eff_god != BattleTypes.GodId.NONE:
		parts.append("Бог: %s" % BattleTypes.get_god_display_name(eff_god))
	if not member_data.is_hero and member_data.ancestral_rune_id != &"" and GameManager != null and GameManager.rune_state != null:
		var r_obj: RuneData = GameManager.rune_state.get_rune_data(member_data.ancestral_rune_id)
		if r_obj != null:
			parts.append("Руна: %s" % r_obj.get_titled_name())
	return " · ".join(parts)

# =========================================================================
# ВКЛАДКА 4: СТАРШИЙ ФУТАРК (24 РУНЫ, 10 БАНДРУН, 6 ВЕЛИКИХ ВЯЗЕЙ, СБРОС)
# =========================================================================

func _rebuild_runes_tab() -> void:
	if _item_list_container == null:
		return
	_clear_right_list()
	if GameManager == null or GameManager.rune_state == null:
		return
	
	var rs: RuneSystemState = GameManager.rune_state
	var summary_card: PanelContainer = _create_item_card_panel(true)
	var sum_vbox: VBoxContainer = VBoxContainer.new()
	sum_vbox.add_theme_constant_override("separation", 3)
	summary_card.add_child(sum_vbox)
	
	var top_lbl: Label = Label.new()
	top_lbl.text = "ЗНАКИ: %d своб. (вложено: %d) · ВЯЗЬ: %d/%d слотов" % [
		rs.signs_available,
		rs.signs_spent_total,
		rs.active_runes.size(),
		rs.max_bind_slots
	]
	top_lbl.add_theme_font_size_override("font_size", 9)
	top_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD)
	sum_vbox.add_child(top_lbl)
	
	var bind_tokens: PackedStringArray = PackedStringArray()
	for r_id: StringName in rs.active_runes:
		var r_d: RuneData = rs.get_rune_data(r_id)
		if r_d != null:
			bind_tokens.append("%s%s(%d)" % [r_d.symbol, r_d.display_name, rs.get_rune_rank(r_id)])
	
	var active_br_names: PackedStringArray = PackedStringArray()
	for br: BindruneData in rs.get_active_bindrunes():
		active_br_names.append(br.display_name)
	
	var active_gb: GreatBindData = rs.get_active_great_bind()
	var pct_ult: int = roundi(rs.get_great_bind_progression_ratio() * 100.0)
	var gb_line: String = (
		"★ Ульта: %s [%d%%]" % [active_gb.display_name, pct_ult]
		if active_gb != null
		else "Ульта Великой вязи: 3 руны Печати (5/5) в Вязи"
	)
	
	var oth_info: Dictionary = rs.get_othala_ship_bonus(GameManager.ship_roster.size())
	var oth_line: String = ""
	if bool(oth_info.get("active", false)):
		oth_line = "\nᛟ Отала (драккар x%d): +%d HP, +%d АТК, +%d ЗАЩ" % [
			int(oth_info.get("ship_count", 0)),
			int(oth_info.get("max_hp", 0)),
			int(oth_info.get("attack", 0)),
			int(oth_info.get("defense", 0))
		]
	
	var details_lbl: Label = Label.new()
	details_lbl.text = "Вязь: %s\nБандруны: %s · %s%s" % [
		", ".join(bind_tokens) if not bind_tokens.is_empty() else "пусто",
		", ".join(active_br_names) if not active_br_names.is_empty() else "нет",
		gb_line,
		oth_line
	]
	details_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_lbl.add_theme_font_size_override("font_size", 8)
	details_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_PRIMARY)
	sum_vbox.add_child(details_lbl)
	
	var avail_gbs: Array[GreatBindData] = rs.get_available_great_binds()
	if avail_gbs.size() > 1:
		var gb_row: HBoxContainer = HBoxContainer.new()
		gb_row.add_theme_constant_override("separation", 3)
		for gb_opt: GreatBindData in avail_gbs:
			var is_curr_gb: bool = (active_gb != null and active_gb.great_bind_id == gb_opt.great_bind_id)
			var gb_btn: Button = _create_compact_action_btn("Ульта: %s" % gb_opt.display_name, gb_opt.description, is_curr_gb)
			gb_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			gb_btn.disabled = is_curr_gb
			var captured_gb_id: StringName = gb_opt.great_bind_id
			gb_btn.pressed.connect(func() -> void:
				var sel_res: Dictionary = rs.select_great_bind(captured_gb_id)
				_set_feedback(str(sel_res.get("reason", "")), false)
			)
			gb_row.add_child(gb_btn)
		sum_vbox.add_child(gb_row)
	
	var tools_row: HBoxContainer = HBoxContainer.new()
	tools_row.add_theme_constant_override("separation", 3)
	sum_vbox.add_child(tools_row)
	
	var ash_cnt: int = GameManager.inventory.get_item_count(InventorySandboxFactory.RITUAL_ASH_ITEM_ID) if GameManager.inventory != null else 0
	var reset_btn: Button = _create_compact_action_btn(
		"Сброс (x%d)" % ash_cnt,
		"Потратить 1 «Золу обряда» и вернуть 100% вложенных Знаков",
		false
	)
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.disabled = (ash_cnt <= 0 or rs.signs_spent_total <= 0)
	reset_btn.pressed.connect(_on_reset_runes_clicked)
	tools_row.add_child(reset_btn)
	
	var slots_btn: Button = _create_compact_action_btn(
		"Слоты: %d" % rs.max_bind_slots,
		"Переключить лимит слотов Вязи (2 -> 4 -> 6)",
		false
	)
	slots_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_btn.pressed.connect(func() -> void:
		var next_s: int = 2 if rs.max_bind_slots >= 6 else (rs.max_bind_slots + 2)
		rs.set_max_bind_slots(next_s)
		_set_feedback("Лимит слотов активной Вязи: %d." % rs.max_bind_slots, false)
	)
	tools_row.add_child(slots_btn)
	
	var recipes_btn: Button = _create_compact_action_btn(
		"Рецепты",
		"Показать/скрыть список всех 10 Бандрун и 6 Великих вязей",
		_show_rune_recipes
	)
	recipes_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipes_btn.pressed.connect(func() -> void:
		_show_rune_recipes = not _show_rune_recipes
		_refresh_right_column()
	)
	tools_row.add_child(recipes_btn)
	
	var test_btn: Button = _create_compact_action_btn(
		"+Тест",
		"Открыть все 24 руны и добавить +10 Знаков для проверки любых комбинаций",
		true
	)
	test_btn.custom_minimum_size = Vector2(52.0, 20.0)
	test_btn.pressed.connect(func() -> void:
		rs.signs_available += 10
		rs.unlock_all_runes_for_testing()
		_set_feedback("Тест: открыты все 24 руны и начислено +10 Знаков.", false)
	)
	tools_row.add_child(test_btn)
	
	_item_list_container.add_child(summary_card)
	
	if _show_rune_recipes:
		_append_rune_recipes_card(rs)
	
	var ancestral_owners: Dictionary = _collect_ancestral_rune_owners()
	for aett_val: RuneTypes.RuneAett in [RuneTypes.RuneAett.FREYR, RuneTypes.RuneAett.HAGAL, RuneTypes.RuneAett.TYR]:
		_add_section_header("— %s —" % RuneTypes.get_aett_display_name(aett_val), InventoryVisualFactory.TEXT_GOLD)
		for rune: RuneData in rs.all_runes:
			if rune != null and rune.aett == aett_val:
				_item_list_container.add_child(_build_single_rune_card(rs, rune, ancestral_owners))

func _append_rune_recipes_card(rs: RuneSystemState) -> void:
	var rec_card: PanelContainer = _create_item_card_panel(false)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("6 ВЕЛИКИХ ВЯЗЕЙ (3 руны ур. 5 в Вязи → Ульта ГГ):")
	for gb: GreatBindData in rs.all_great_binds:
		var ok_tag: String = " [СОБРАНА]" if gb.is_satisfied(rs.active_runes, rs.rune_ranks) else ""
		lines.append("• %s%s — %s" % [gb.display_name, ok_tag, gb.description])
	lines.append("10 БАНДРУН (2 руны ур. ≥ 3 в Вязи → рунный навык):")
	for br: BindruneData in rs.all_bindrunes:
		var ok_br: String = " [АКТИВНА]" if br.is_satisfied(rs.active_runes, rs.rune_ranks) else ""
		lines.append("• %s%s — %s" % [br.display_name, ok_br, br.description])
	var lbl: Label = Label.new()
	lbl.text = "\n".join(lines)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_RUNE_CYAN)
	rec_card.add_child(lbl)
	_item_list_container.add_child(rec_card)

func _build_single_rune_card(rs: RuneSystemState, rune: RuneData, ancestral_owners: Dictionary) -> PanelContainer:
	var unlocked: bool = rs.is_rune_unlocked(rune.rune_id)
	var rank: int = rs.get_rune_rank(rune.rune_id)
	var in_bind: bool = rs.is_rune_in_bind(rune.rune_id)
	
	var card: PanelContainer = _create_item_card_panel(in_bind)
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 5)
	card.add_child(hbox)
	
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 1)
	hbox.add_child(info_vbox)
	
	var state_badge: String = " [Закр. эп.%d]" % rune.unlock_episode if not unlocked else (
		" [ПЕЧАТЬ 5/5]" if rank >= RuneTypes.SEAL_RANK else " [Ст. %d/5]" % rank
	)
	if in_bind:
		state_badge += " [В ВЯЗИ]"
	
	var name_lbl: Label = Label.new()
	name_lbl.text = "%d. %s%s" % [rune.order_index, rune.get_titled_name(), state_badge]
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 9)
	var n_col: Color = InventoryVisualFactory.TEXT_PRIMARY
	if in_bind:
		n_col = InventoryVisualFactory.TEXT_GOLD
	elif rank >= RuneTypes.SEAL_RANK:
		n_col = InventoryVisualFactory.TEXT_RUNE_CYAN
	elif not unlocked:
		n_col = InventoryVisualFactory.TEXT_DISABLED
	name_lbl.add_theme_color_override("font_color", n_col)
	info_vbox.add_child(name_lbl)
	
	var owner_note: String = " · Род: %s" % str(ancestral_owners[rune.rune_id]) if ancestral_owners.has(rune.rune_id) else ""
	var sub_lbl: Label = Label.new()
	sub_lbl.text = "%s · Печать: %s%s" % [rune.passive_summary, rune.seal_description, owner_note]
	sub_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_lbl.add_theme_font_size_override("font_size", 8)
	sub_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_SECONDARY)
	info_vbox.add_child(sub_lbl)
	
	var act_vbox: VBoxContainer = VBoxContainer.new()
	act_vbox.custom_minimum_size = Vector2(58.0, 0.0)
	act_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(act_vbox)
	
	var captured_id: StringName = rune.rune_id
	var can_invest: bool = unlocked and rank < RuneTypes.MAX_RUNE_RANK and rs.signs_available > 0
	var invest_btn: Button = _create_compact_action_btn("+Знак", "Вложить 1 Знак в %s" % rune.get_titled_name(), can_invest)
	invest_btn.custom_minimum_size = Vector2(58.0, 19.0)
	invest_btn.disabled = not can_invest
	invest_btn.pressed.connect(func() -> void:
		var res: Dictionary = rs.invest_sign(captured_id)
		_set_feedback(str(res.get("reason", "")), not bool(res.get("ok", false)))
	)
	act_vbox.add_child(invest_btn)
	
	var can_bind: bool = in_bind or (unlocked and rank > 0 and rs.active_runes.size() < rs.max_bind_slots)
	var bind_btn: Button = _create_compact_action_btn("Снять" if in_bind else "В вязь", "Бесплатная смена активной Вязи", in_bind)
	bind_btn.custom_minimum_size = Vector2(58.0, 19.0)
	bind_btn.disabled = not can_bind
	bind_btn.pressed.connect(func() -> void:
		var res: Dictionary = rs.toggle_rune_in_bind(captured_id)
		_set_feedback(str(res.get("reason", "")), not bool(res.get("ok", false)))
	)
	act_vbox.add_child(bind_btn)
	
	return card

func _collect_ancestral_rune_owners() -> Dictionary:
	var owners: Dictionary = {}
	if GameManager == null:
		return owners
	for m: CombatantData in GameManager.active_party:
		if m != null and not m.is_hero and m.ancestral_rune_id != &"":
			owners[m.ancestral_rune_id] = m.display_name
	for s: CombatantData in GameManager.ship_roster:
		if s != null and s.ancestral_rune_id != &"":
			owners[s.ancestral_rune_id] = "%s (корабль)" % s.display_name
	return owners

func _on_reset_runes_clicked() -> void:
	if GameManager == null:
		return
	var res: Dictionary = GameManager.reset_runes_with_ritual_ash()
	_set_feedback(str(res.get("reason", "")), not bool(res.get("ok", false)))
	_refresh_all()

# =========================================================================
# ВКЛАДКА 5: БОГИ (4 ПАРЫ АНТАГОНИСТОВ БЕЗ СБРОСА, БЛАГОСЛОВЕНИЕ, ВЕРБОВКА)
# =========================================================================

func _rebuild_gods_tab() -> void:
	if _item_list_container == null:
		return
	_clear_right_list()
	if GameManager == null or GameManager.god_state == null:
		return
	
	var gs: GodAffinityState = GameManager.god_state
	var top_card: PanelContainer = _create_item_card_panel(gs.active_patron != BattleTypes.GodId.NONE)
	var top_vbox: VBoxContainer = VBoxContainer.new()
	top_vbox.add_theme_constant_override("separation", 3)
	top_card.add_child(top_vbox)
	
	var head_row: HBoxContainer = HBoxContainer.new()
	head_row.alignment = BoxContainer.ALIGNMENT_CENTER
	head_row.add_theme_constant_override("separation", 4)
	top_vbox.add_child(head_row)
	
	var patron_str: String = BattleTypes.get_god_display_name(gs.active_patron) if gs.active_patron != BattleTypes.GodId.NONE else "не избран"
	var head_lbl: Label = Label.new()
	head_lbl.text = "ПОКРОВИТЕЛЬ ГГ: %s (без сброса)" % patron_str
	head_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_lbl.clip_text = true
	head_lbl.add_theme_font_size_override("font_size", 9)
	head_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD)
	head_row.add_child(head_lbl)
	
	var dbg_btn: Button = _create_compact_action_btn(
		"Числа: %s" % ("ВКЛ" if gs.show_god_affinity_numbers else "ВЫКЛ"),
		"Переключить debug-флаг show_god_affinity_numbers",
		gs.show_god_affinity_numbers
	)
	dbg_btn.custom_minimum_size = Vector2(74.0, 19.0)
	dbg_btn.pressed.connect(func() -> void:
		gs.set_show_affinity_numbers(not gs.show_god_affinity_numbers)
	)
	head_row.add_child(dbg_btn)
	
	var blessings: Array[GodData] = gs.compute_party_blessings(GameManager.active_party)
	var bl_text: String = "Дар отряда: нет (нужно ≥2 бойцов одного бога в активном строю)."
	if not blessings.is_empty():
		var bl_parts: PackedStringArray = PackedStringArray()
		for b_god: GodData in blessings:
			bl_parts.append("✦ %s (%s)" % [b_god.blessing_name, b_god.blessing_description])
		bl_text = "\n".join(bl_parts)
	
	var bl_lbl: Label = Label.new()
	bl_lbl.text = bl_text
	bl_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl_lbl.add_theme_font_size_override("font_size", 8)
	bl_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_RUNE_CYAN if not blessings.is_empty() else InventoryVisualFactory.TEXT_SECONDARY)
	top_vbox.add_child(bl_lbl)
	_item_list_container.add_child(top_card)
	
	_add_section_header("ТЕСТ ПОСТУПКОВ (необратимая склонность):", InventoryVisualFactory.TEXT_GOLD)
	var deeds_card: PanelContainer = _create_item_card_panel(false)
	var deeds_vbox: VBoxContainer = VBoxContainer.new()
	deeds_vbox.add_theme_constant_override("separation", 3)
	deeds_card.add_child(deeds_vbox)
	
	for deed: Dictionary in GodCatalogFactory.create_test_deeds():
		var d_row: HBoxContainer = HBoxContainer.new()
		d_row.add_theme_constant_override("separation", 3)
		var l_god: BattleTypes.GodId = int(deed.get("left_god", BattleTypes.GodId.NONE)) as BattleTypes.GodId
		var r_god: BattleTypes.GodId = int(deed.get("right_god", BattleTypes.GodId.NONE)) as BattleTypes.GodId
		var d_val: int = int(deed.get("delta", 15))
		
		var l_btn: Button = _create_compact_action_btn(str(deed.get("left_label", "")), str(deed.get("pair_title", "")), false)
		l_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l_btn.clip_text = true
		l_btn.pressed.connect(func() -> void:
			var res: Dictionary = gs.add_affinity(l_god, d_val)
			_set_feedback(str(res.get("reason", "")), false)
		)
		d_row.add_child(l_btn)
		
		var r_btn: Button = _create_compact_action_btn(str(deed.get("right_label", "")), str(deed.get("pair_title", "")), false)
		r_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r_btn.clip_text = true
		r_btn.pressed.connect(func() -> void:
			var res: Dictionary = gs.add_affinity(r_god, d_val)
			_set_feedback(str(res.get("reason", "")), false)
		)
		d_row.add_child(r_btn)
		deeds_vbox.add_child(d_row)
	_item_list_container.add_child(deeds_card)
	
	_add_section_header("ПАНТЕОН И СТУПЕНИ ВЕРБОВКИ:", InventoryVisualFactory.TEXT_RUNE_CYAN)
	for god: GodData in gs.all_gods:
		if god != null:
			_item_list_container.add_child(_build_single_god_card(gs, god))

func _build_single_god_card(gs: GodAffinityState, god: GodData) -> PanelContainer:
	var is_patron: bool = (gs.active_patron == god.god_id)
	var aff_val: int = gs.get_affinity(god.god_id)
	var verbal: String = gs.get_verbal_affinity(god.god_id)
	var rec_tier: GodTypes.RecruitmentTier = gs.get_recruitment_tier(god.god_id)
	
	var card: PanelContainer = _create_item_card_panel(is_patron)
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 5)
	card.add_child(hbox)
	
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 1)
	hbox.add_child(info_vbox)
	
	var name_lbl: Label = Label.new()
	name_lbl.text = "%s (↔ %s) — %s%s" % [
		god.display_name,
		BattleTypes.get_god_display_name(god.antagonist_id),
		verbal,
		" [АКТИВЕН]" if is_patron else ""
	]
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 9)
	var g_col: Color = InventoryVisualFactory.TEXT_PRIMARY
	if is_patron:
		g_col = InventoryVisualFactory.TEXT_GOLD
	elif aff_val >= GodTypes.PATRON_THRESHOLD:
		g_col = InventoryVisualFactory.TEXT_RUNE_CYAN
	name_lbl.add_theme_color_override("font_color", g_col)
	info_vbox.add_child(name_lbl)
	
	var unlocked_skills: PackedStringArray = PackedStringArray()
	if aff_val >= GodTypes.PATRON_THRESHOLD and god.tier_1_skill != null:
		unlocked_skills.append("I:%s" % god.tier_1_skill.skill_name)
	if aff_val >= GodTypes.TIER_2_SKILL_THRESHOLD and god.tier_2_skill != null:
		unlocked_skills.append("II:%s" % god.tier_2_skill.skill_name)
	var sk_str: String = ", ".join(unlocked_skills) if not unlocked_skills.is_empty() else "закрыты"
	
	var sub_lbl: Label = Label.new()
	sub_lbl.text = "ГГ: %s · Путь: %s\nОтряд (2+): %s\nВербовка: %s" % [
		god.patron_summary,
		sk_str,
		god.blessing_description,
		GodTypes.get_recruitment_tier_description(rec_tier)
	]
	sub_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_lbl.add_theme_font_size_override("font_size", 8)
	sub_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_SECONDARY)
	info_vbox.add_child(sub_lbl)
	
	var can_choose: bool = gs.can_choose_as_patron(god.god_id) and not is_patron
	var pat_btn: Button = _create_compact_action_btn(
		"Избран" if is_patron else "Избрать",
		"Сделать %s активным покровителем ГГ" % god.display_name,
		can_choose
	)
	pat_btn.custom_minimum_size = Vector2(58.0, 22.0)
	pat_btn.disabled = not can_choose
	var captured_god_id: BattleTypes.GodId = god.god_id
	pat_btn.pressed.connect(func() -> void:
		var res: Dictionary = gs.set_active_patron(captured_god_id)
		_set_feedback(str(res.get("reason", "")), not bool(res.get("ok", false)))
	)
	hbox.add_child(pat_btn)
	return card

# =========================================================================
# ДЕЙСТВИЯ ЭКИПИРОВКИ, РОТАЦИИ И ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
# =========================================================================

func _on_swap_party_ship_clicked(party_idx: int, ship_idx: int) -> void:
	if GameManager == null:
		return
	var res: Dictionary = GameManager.swap_party_and_ship_member(party_idx, ship_idx)
	_set_feedback(str(res.get("reason", "")), not bool(res.get("ok", false)))
	if bool(res.get("ok", false)):
		_selected_party_index = party_idx
		_refresh_all()

func _on_send_to_ship_clicked(party_idx: int) -> void:
	if GameManager == null:
		return
	var res: Dictionary = GameManager.send_party_member_to_ship(party_idx)
	_set_feedback(str(res.get("reason", "")), not bool(res.get("ok", false)))
	if bool(res.get("ok", false)):
		_clamp_selected_party_index()
		_refresh_all()

func _on_add_from_ship_clicked(ship_idx: int) -> void:
	if GameManager == null:
		return
	var res: Dictionary = GameManager.add_ship_member_to_party(ship_idx)
	_set_feedback(str(res.get("reason", "")), not bool(res.get("ok", false)))
	if bool(res.get("ok", false)):
		_selected_party_index = maxi(0, GameManager.active_party.size() - 1)
		_refresh_all()

func _on_slot_unequip_pressed(slot_id: StringName) -> void:
	var member_data: CombatantData = _get_selected_member_data()
	if member_data == null or GameManager == null or GameManager.inventory == null:
		return
	var removed: Array[EquipmentItemData] = GameManager.inventory.unequip_slot(member_data, slot_id)
	if not removed.is_empty():
		var names: PackedStringArray = PackedStringArray()
		for item: EquipmentItemData in removed:
			if item != null:
				names.append(item.display_name)
		_set_feedback("%s снимает в сумку: %s." % [member_data.display_name, ", ".join(names)], false)
		equipment_changed.emit(slot_id)
		_refresh_all()

func _on_equip_clicked(item: EquipmentItemData, slot_id: StringName) -> void:
	var member_data: CombatantData = _get_selected_member_data()
	if member_data == null or GameManager == null or GameManager.inventory == null or item == null:
		return
	var res: Dictionary = GameManager.inventory.equip_item(member_data, slot_id, item)
	if bool(res.get("ok", false)):
		_set_feedback("%s экипирует «%s» (%s)." % [
			member_data.display_name,
			item.display_name,
			InventoryTypes.get_slot_display_name(slot_id)
		], false)
		equipment_changed.emit(slot_id)
		_refresh_all()
	else:
		_set_feedback(str(res.get("reason", "Не удалось экипировать предмет.")), true)

func _on_consumable_use_clicked(item: ConsumableItemData) -> void:
	var member_data: CombatantData = _get_selected_member_data()
	if member_data == null or GameManager == null or item == null:
		return
	var res: Dictionary = GameManager.use_overworld_consumable(member_data, item)
	var ok: bool = bool(res.get("ok", false))
	_set_feedback(str(res.get("message", "")), not ok)
	if ok:
		consumable_used.emit(item.item_id)
		_refresh_all()

func _clear_right_list() -> void:
	if _item_list_container == null:
		return
	for child: Node in _item_list_container.get_children():
		child.queue_free()

func _set_feedback(text: String, is_error: bool = false) -> void:
	if _feedback_label == null:
		return
	_feedback_label.text = text
	_feedback_label.add_theme_color_override(
		"font_color",
		InventoryVisualFactory.TEXT_DANGER if is_error else InventoryVisualFactory.TEXT_GOLD
	)

func _add_section_header(text: String, col: Color) -> void:
	if _item_list_container == null:
		return
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.clip_text = true
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", col)
	_item_list_container.add_child(lbl)

func _add_empty_list_label(text: String) -> void:
	if _item_list_container == null:
		return
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_SECONDARY)
	_item_list_container.add_child(lbl)

func _create_item_card_panel(highlighted: bool = false) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", InventoryVisualFactory.get_card_style(highlighted))
	return card

func _create_compact_action_btn(p_text: String, p_tooltip: String, gold_accent: bool = false) -> Button:
	var btn: Button = Button.new()
	btn.text = p_text
	btn.tooltip_text = p_tooltip
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(48.0, 20.0)
	btn.add_theme_font_size_override("font_size", 8)
	InventoryVisualFactory.style_iron_button(btn, gold_accent)
	return btn
