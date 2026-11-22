# res://scripts/ui/inventory_menu_overlay.gd
class_name InventoryMenuOverlay
extends CanvasLayer

## Сигналы окна инвентаря и экипировки (снизу вверх)
signal inventory_opened()
signal inventory_closed()
signal equipment_changed(slot_id: StringName)
signal consumable_used(item_id: String)

enum ActiveTab {
	EQUIPMENT,
	CONSUMABLES
}

const TOGGLE_ACTION_NAME: StringName = &"inventory_toggle"

var _bound_player: Player = null
var _is_open: bool = false
var _active_tab: ActiveTab = ActiveTab.EQUIPMENT
var _is_listening_inventory: bool = false

var _hud_toggle_btn: Button = null
var _overlay_root: Control = null
var _close_btn: Button = null
var _slots_container: VBoxContainer = null
var _stats_label: Label = null
var _synergy_label: Label = null
var _tab_eq_btn: Button = null
var _tab_cons_btn: Button = null
var _item_list_container: VBoxContainer = null
var _feedback_label: Label = null

func _ready() -> void:
	layer = 20
	if GameManager != null:
		GameManager.ensure_party_initialized()
	
	var built: Dictionary = InventoryMenuBuilder.build_overlay_ui(self)
	_hud_toggle_btn = built.get("hud_toggle_button") as Button
	_overlay_root = built.get("overlay_root") as Control
	_close_btn = built.get("close_button") as Button
	_slots_container = built.get("slots_container") as VBoxContainer
	_stats_label = built.get("stats_label") as Label
	_synergy_label = built.get("synergy_label") as Label
	_tab_eq_btn = built.get("tab_equipment_button") as Button
	_tab_cons_btn = built.get("tab_consumables_button") as Button
	_item_list_container = built.get("item_list_container") as VBoxContainer
	_feedback_label = built.get("feedback_label") as Label
	
	_connect_ui_signals()
	_connect_inventory_signal()
	_update_visibility()

func _exit_tree() -> void:
	_disconnect_inventory_signal()
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
	
	_is_open = true
	if _bound_player != null:
		_bound_player.is_locked = true
	
	_set_feedback("")
	_update_visibility()
	_refresh_all()
	inventory_opened.emit()
	if _close_btn != null and _close_btn.is_inside_tree():
		_close_btn.call_deferred("grab_focus")

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

func _on_hud_toggle_pressed() -> void:
	if _is_open:
		close_menu()
	elif _can_open():
		open_menu()

func _on_tab_equipment_pressed() -> void:
	_active_tab = ActiveTab.EQUIPMENT
	_refresh_right_column()

func _on_tab_consumables_pressed() -> void:
	_active_tab = ActiveTab.CONSUMABLES
	_refresh_right_column()

func _on_inventory_changed() -> void:
	if _is_open:
		_refresh_all()

func _update_visibility() -> void:
	if _overlay_root != null:
		_overlay_root.visible = _is_open
	if _hud_toggle_btn != null:
		_hud_toggle_btn.visible = not _is_open

func _get_hero_data() -> CombatantData:
	if GameManager == null:
		return null
	GameManager.ensure_party_initialized()
	if GameManager.party_roster.is_empty():
		return null
	return GameManager.party_roster[0]

func _refresh_all() -> void:
	var hero_data: CombatantData = _get_hero_data()
	_rebuild_slots(hero_data)
	_refresh_stats_and_synergy(hero_data)
	_refresh_right_column()

func _rebuild_slots(hero_data: CombatantData) -> void:
	if _slots_container == null:
		return
	for child: Node in _slots_container.get_children():
		child.queue_free()
	
	if hero_data == null or hero_data.equipment_loadout == null:
		return
	
	var loadout: EquipmentLoadout = hero_data.equipment_loadout
	var two_handed: bool = loadout.is_two_handed_equipped()
	
	for slot_id: StringName in InventoryTypes.get_all_slot_ids():
		var slot_title: String = InventoryTypes.get_slot_display_name(slot_id)
		var item: EquipmentItemData = loadout.get_slot_item(slot_id)
		var btn: Button = Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0.0, 20.0)
		btn.add_theme_font_size_override("font_size", 9)
		
		if slot_id == InventoryTypes.SLOT_RIGHT_HAND and two_handed and item != null:
			btn.text = "%s: [занята: %s]" % [slot_title, item.display_name]
			btn.tooltip_text = "Обе руки заняты двуручным оружием. Нажмите, чтобы снять."
			var captured_slot: StringName = slot_id
			btn.pressed.connect(func() -> void:
				_on_slot_unequip_pressed(captured_slot)
			)
		elif item != null:
			var tag_2h: String = " [2Р]" if item.slot_type == InventoryTypes.EquipmentSlotType.TWO_HAND else ""
			btn.text = "%s: %s%s" % [slot_title, item.display_name, tag_2h]
			btn.tooltip_text = "%s\nНажмите, чтобы снять в инвентарь" % item.get_stat_summary()
			var captured_slot: StringName = slot_id
			btn.pressed.connect(func() -> void:
				_on_slot_unequip_pressed(captured_slot)
			)
		else:
			if slot_id == InventoryTypes.SLOT_RIGHT_HAND and loadout.available_hands < 2:
				btn.text = "%s: [недоступна]" % slot_title
			else:
				btn.text = "%s: — пусто —" % slot_title
			btn.disabled = true
		
		_slots_container.add_child(btn)

func _refresh_stats_and_synergy(hero_data: CombatantData) -> void:
	if GameManager == null or hero_data == null:
		return
	var status: Dictionary = GameManager.get_party_member_status(hero_data)
	if status.is_empty():
		return
	
	if _stats_label != null:
		var mana_part: String = ""
		if bool(status.get("has_mana", false)):
			mana_part = "   Мана: %d/%d" % [int(status.get("current_mana", 0)), int(status.get("max_mana", 100))]
		var crit_pct: int = roundi(float(status.get("crit_chance", 0.05)) * 100.0)
		var crit_mult: float = float(status.get("crit_multiplier", 1.5))
		_stats_label.text = (
			"HP: %d/%d%s\nАТК: %d  МАГ: %d  ЗАЩ: %d  СКР: %d\nКрит: %d%% (x%.2f)" % [
				int(status.get("current_hp", 100)),
				int(status.get("max_hp", 100)),
				mana_part,
				int(status.get("attack", 10)),
				int(status.get("magic_power", 10)),
				int(status.get("defense", 5)),
				int(status.get("speed", 10)),
				crit_pct,
				crit_mult
			]
		)
	
	if _synergy_label != null:
		var lines: PackedStringArray = PackedStringArray()
		var syn_variant: Variant = status.get("active_synergies", [])
		var syn_count: int = 0
		if syn_variant is Array:
			for entry: Variant in syn_variant:
				if entry is WeaponSynergyData:
					var syn: WeaponSynergyData = entry as WeaponSynergyData
					syn_count += 1
					lines.append("✦ Синергия: %s\n%s" % [syn.display_name, syn.description])
		if syn_count == 0:
			lines.append("Синергия рук: нет активной связки")
		
		var qte_ov: Dictionary = status.get("qte_override", {}) as Dictionary
		if bool(qte_ov.get("has_override", false)):
			var base_miss: float = float(qte_ov.get("miss_threshold", 0.30)) if bool(qte_ov.get("use_absolute", false)) else 0.30
			var base_perf: float = float(qte_ov.get("perfect_threshold", 0.90)) if bool(qte_ov.get("use_absolute", false)) else 0.90
			var miss_pct: int = roundi(clampf(base_miss + float(qte_ov.get("miss_delta", 0.0)), 0.0, 0.95) * 100.0)
			var perf_pct: int = roundi(clampf(base_perf + float(qte_ov.get("perfect_delta", 0.0)), 0.05, 1.0) * 100.0)
			perf_pct = maxi(miss_pct, perf_pct)
			var crit_note: String = ", крит" if bool(qte_ov.get("guaranteed_crit_on_perfect", false)) else ""
			lines.append("QTE: промах <%d%%, идеал ≥%d%%%s" % [miss_pct, perf_pct, crit_note])
		
		_synergy_label.text = "\n".join(lines)

func _refresh_right_column() -> void:
	if _tab_eq_btn != null:
		_tab_eq_btn.disabled = (_active_tab == ActiveTab.EQUIPMENT)
	if _tab_cons_btn != null:
		_tab_cons_btn.disabled = (_active_tab == ActiveTab.CONSUMABLES)
	
	var hero_data: CombatantData = _get_hero_data()
	if _active_tab == ActiveTab.EQUIPMENT:
		_rebuild_equipment_list(hero_data)
	else:
		_rebuild_consumables_list(hero_data)

func _rebuild_equipment_list(hero_data: CombatantData) -> void:
	if _item_list_container == null:
		return
	for child: Node in _item_list_container.get_children():
		child.queue_free()
	
	if GameManager == null or GameManager.inventory == null:
		return
	
	var items: Array[EquipmentItemData] = GameManager.inventory.get_all_equipment()
	if items.is_empty():
		_add_empty_list_label("В инвентаре нет свободной экипировки.")
		return
	
	var available_hands: int = 2
	if hero_data != null and hero_data.equipment_loadout != null:
		available_hands = hero_data.equipment_loadout.available_hands
	
	for eq: EquipmentItemData in items:
		if eq == null:
			continue
		var card: PanelContainer = _create_item_card_panel()
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		card.add_child(hbox)
		
		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 1)
		hbox.add_child(info_vbox)
		
		var name_lbl: Label = Label.new()
		var unique_tag: String = " [Уник.]" if eq.is_unique else ""
		name_lbl.text = "%s%s" % [eq.display_name, unique_tag]
		name_lbl.add_theme_font_size_override("font_size", 9)
		if eq.is_unique:
			name_lbl.modulate = Color(1.0, 0.88, 0.55, 1.0)
		info_vbox.add_child(name_lbl)
		
		var sub_lbl: Label = Label.new()
		sub_lbl.text = "%s · %s" % [InventoryTypes.get_slot_type_display_name(eq.slot_type), eq.get_stat_summary()]
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_font_size_override("font_size", 8)
		sub_lbl.modulate = Color(0.74, 0.80, 0.90, 1.0)
		info_vbox.add_child(sub_lbl)
		
		var btn_hbox: HBoxContainer = HBoxContainer.new()
		btn_hbox.add_theme_constant_override("separation", 2)
		hbox.add_child(btn_hbox)
		
		var captured_eq: EquipmentItemData = eq
		match eq.slot_type:
			InventoryTypes.EquipmentSlotType.ONE_HAND, InventoryTypes.EquipmentSlotType.SHIELD:
				var left_btn: Button = _create_compact_action_btn("Л", "Надеть в левую руку")
				left_btn.pressed.connect(func() -> void:
					_on_equip_clicked(captured_eq, InventoryTypes.SLOT_LEFT_HAND)
				)
				btn_hbox.add_child(left_btn)
				
				var right_btn: Button = _create_compact_action_btn("П", "Надеть в правую руку")
				right_btn.disabled = available_hands < 2
				right_btn.pressed.connect(func() -> void:
					_on_equip_clicked(captured_eq, InventoryTypes.SLOT_RIGHT_HAND)
				)
				btn_hbox.add_child(right_btn)
			InventoryTypes.EquipmentSlotType.TWO_HAND:
				var two_h_btn: Button = _create_compact_action_btn("Обе", "Надеть в обе руки")
				two_h_btn.disabled = available_hands < 2
				two_h_btn.pressed.connect(func() -> void:
					_on_equip_clicked(captured_eq, InventoryTypes.SLOT_LEFT_HAND)
				)
				btn_hbox.add_child(two_h_btn)
			InventoryTypes.EquipmentSlotType.BODY:
				var body_btn: Button = _create_compact_action_btn("Надеть", "Надеть в слот «Тело»")
				body_btn.pressed.connect(func() -> void:
					_on_equip_clicked(captured_eq, InventoryTypes.SLOT_BODY)
				)
				btn_hbox.add_child(body_btn)
			InventoryTypes.EquipmentSlotType.ACCESSORY:
				var acc1_btn: Button = _create_compact_action_btn("Сл.1", "Надеть в Аксессуар 1")
				acc1_btn.pressed.connect(func() -> void:
					_on_equip_clicked(captured_eq, InventoryTypes.SLOT_ACCESSORY_1)
				)
				btn_hbox.add_child(acc1_btn)
				
				var acc2_btn: Button = _create_compact_action_btn("Сл.2", "Надеть в Аксессуар 2")
				acc2_btn.pressed.connect(func() -> void:
					_on_equip_clicked(captured_eq, InventoryTypes.SLOT_ACCESSORY_2)
				)
				btn_hbox.add_child(acc2_btn)
		
		card.tooltip_text = eq.description
		_item_list_container.add_child(card)

func _rebuild_consumables_list(hero_data: CombatantData) -> void:
	if _item_list_container == null:
		return
	for child: Node in _item_list_container.get_children():
		child.queue_free()
	
	if GameManager == null or GameManager.inventory == null:
		return
	
	var entries: Array[Dictionary] = GameManager.inventory.get_consumables(false, false)
	if entries.is_empty():
		_add_empty_list_label("Расходники закончились.")
		return
	
	for entry: Dictionary in entries:
		var cons: ConsumableItemData = entry.get("item", null) as ConsumableItemData
		var cnt: int = int(entry.get("count", 0))
		if cons == null or cnt <= 0:
			continue
		
		var card: PanelContainer = _create_item_card_panel()
		card.tooltip_text = cons.description
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		card.add_child(hbox)
		
		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 1)
		hbox.add_child(info_vbox)
		
		var name_lbl: Label = Label.new()
		name_lbl.text = "%s  x%d" % [cons.display_name, cnt]
		name_lbl.add_theme_font_size_override("font_size", 9)
		info_vbox.add_child(name_lbl)
		
		var sub_lbl: Label = Label.new()
		sub_lbl.text = cons.get_effect_summary()
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_font_size_override("font_size", 8)
		sub_lbl.modulate = Color(0.74, 0.80, 0.90, 1.0)
		info_vbox.add_child(sub_lbl)
		
		var use_btn: Button = _create_compact_action_btn(
			"Выпить" if cons.usable_in_overworld else "В бою",
			cons.description
		)
		use_btn.disabled = not cons.usable_in_overworld or hero_data == null
		var captured_cons: ConsumableItemData = cons
		use_btn.pressed.connect(func() -> void:
			_on_consumable_use_clicked(captured_cons)
		)
		hbox.add_child(use_btn)
		_item_list_container.add_child(card)

func _on_slot_unequip_pressed(slot_id: StringName) -> void:
	var hero_data: CombatantData = _get_hero_data()
	if hero_data == null or GameManager == null or GameManager.inventory == null:
		return
	var removed: Array[EquipmentItemData] = GameManager.inventory.unequip_slot(hero_data, slot_id)
	if not removed.is_empty():
		var names: PackedStringArray = PackedStringArray()
		for item: EquipmentItemData in removed:
			if item != null:
				names.append(item.display_name)
		_set_feedback("Снято в инвентарь: %s." % ", ".join(names))
		equipment_changed.emit(slot_id)
		_refresh_all()

func _on_equip_clicked(item: EquipmentItemData, slot_id: StringName) -> void:
	var hero_data: CombatantData = _get_hero_data()
	if hero_data == null or GameManager == null or GameManager.inventory == null or item == null:
		return
	var res: Dictionary = GameManager.inventory.equip_item(hero_data, slot_id, item)
	if bool(res.get("ok", false)):
		_set_feedback("Экипировано: «%s» (%s)." % [item.display_name, InventoryTypes.get_slot_display_name(slot_id)])
		equipment_changed.emit(slot_id)
		_refresh_all()
	else:
		_set_feedback(str(res.get("reason", "Не удалось экипировать предмет.")))

func _on_consumable_use_clicked(item: ConsumableItemData) -> void:
	var hero_data: CombatantData = _get_hero_data()
	if hero_data == null or GameManager == null or item == null:
		return
	var res: Dictionary = GameManager.use_overworld_consumable(hero_data, item)
	_set_feedback(str(res.get("message", "")))
	if bool(res.get("ok", false)):
		consumable_used.emit(item.item_id)
		_refresh_all()

func _set_feedback(text: String) -> void:
	if _feedback_label != null:
		_feedback_label.text = text

func _add_empty_list_label(text: String) -> void:
	if _item_list_container == null:
		return
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.modulate = Color(0.68, 0.72, 0.80, 1.0)
	_item_list_container.add_child(lbl)

func _create_item_card_panel() -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.bg_color = Color(0.14, 0.17, 0.24, 0.92)
	st.border_color = Color(0.28, 0.34, 0.48, 0.9)
	st.set_border_width_all(1)
	st.set_corner_radius_all(3)
	st.content_margin_left = 5.0
	st.content_margin_right = 5.0
	st.content_margin_top = 3.0
	st.content_margin_bottom = 3.0
	card.add_theme_stylebox_override("panel", st)
	return card

func _create_compact_action_btn(p_text: String, p_tooltip: String) -> Button:
	var btn: Button = Button.new()
	btn.text = p_text
	btn.tooltip_text = p_tooltip
	btn.custom_minimum_size = Vector2(36.0, 22.0)
	btn.add_theme_font_size_override("font_size", 9)
	return btn
