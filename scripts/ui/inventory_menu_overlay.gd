# res://scripts/ui/inventory_menu_overlay.gd
class_name InventoryMenuOverlay
extends CanvasLayer

## Сигналы окна инвентаря, экипировки и ротации отряда (снизу вверх)
signal inventory_opened()
signal inventory_closed()
signal equipment_changed(slot_id: StringName)
signal consumable_used(item_id: String)

enum ActiveTab {
	EQUIPMENT,
	CONSUMABLES,
	SHIP_ROSTER
}

const TOGGLE_ACTION_NAME: StringName = &"inventory_toggle"

var _bound_player: Player = null
var _is_open: bool = false
var _active_tab: ActiveTab = ActiveTab.EQUIPMENT
var _selected_party_index: int = 0
var _is_listening_inventory: bool = false
var _is_listening_party: bool = false

var _hud_toggle_btn: Button = null
var _overlay_root: Control = null
var _title_label: Label = null
var _close_btn: Button = null
var _member_selector_hbox: HBoxContainer = null
var _member_profile_label: Label = null
var _slots_container: VBoxContainer = null
var _stats_label: Label = null
var _synergy_label: Label = null
var _tab_eq_btn: Button = null
var _tab_cons_btn: Button = null
var _tab_ship_btn: Button = null
var _item_list_container: VBoxContainer = null
var _feedback_label: Label = null

func _ready() -> void:
	layer = 20
	if GameManager != null:
		GameManager.ensure_party_initialized()
	
	var built: Dictionary = InventoryMenuBuilder.build_overlay_ui(self)
	_hud_toggle_btn = built.get("hud_toggle_button") as Button
	_overlay_root = built.get("overlay_root") as Control
	_title_label = built.get("title_label") as Label
	_close_btn = built.get("close_button") as Button
	_member_selector_hbox = built.get("member_selector_hbox") as HBoxContainer
	_member_profile_label = built.get("member_profile_label") as Label
	_slots_container = built.get("slots_container") as VBoxContainer
	_stats_label = built.get("stats_label") as Label
	_synergy_label = built.get("synergy_label") as Label
	_tab_eq_btn = built.get("tab_equipment_button") as Button
	_tab_cons_btn = built.get("tab_consumables_button") as Button
	_tab_ship_btn = built.get("tab_ship_button") as Button
	_item_list_container = built.get("item_list_container") as VBoxContainer
	_feedback_label = built.get("feedback_label") as Label
	
	_connect_ui_signals()
	_connect_inventory_signal()
	_connect_party_signal()
	_update_visibility()

func _exit_tree() -> void:
	_disconnect_inventory_signal()
	_disconnect_party_signal()
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
	
	_clamp_selected_party_index()
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
	if _tab_ship_btn != null and not _tab_ship_btn.pressed.is_connected(_on_tab_ship_pressed):
		_tab_ship_btn.pressed.connect(_on_tab_ship_pressed)

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

func _on_tab_ship_pressed() -> void:
	_active_tab = ActiveTab.SHIP_ROSTER
	_refresh_right_column()

func _on_inventory_changed() -> void:
	if _is_open:
		_refresh_all()

func _on_party_changed() -> void:
	_clamp_selected_party_index()
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
		_set_feedback("Выбран боец: %s." % selected.display_name)
	_refresh_all()

func _refresh_all() -> void:
	_clamp_selected_party_index()
	var member_data: CombatantData = _get_selected_member_data()
	_rebuild_member_selector()
	_refresh_header_and_profile(member_data)
	_rebuild_slots(member_data)
	_refresh_stats_and_synergy(member_data)
	_refresh_right_column()

func _rebuild_member_selector() -> void:
	if _member_selector_hbox == null:
		return
	for child: Node in _member_selector_hbox.get_children():
		child.queue_free()
	
	var cap_lbl: Label = Label.new()
	cap_lbl.text = "Боец отряда:"
	cap_lbl.add_theme_font_size_override("font_size", 9)
	cap_lbl.modulate = Color(0.78, 0.84, 0.94, 1.0)
	_member_selector_hbox.add_child(cap_lbl)
	
	if GameManager == null:
		return
	
	for i: int in range(GameManager.active_party.size()):
		var m: CombatantData = GameManager.active_party[i]
		if m == null:
			continue
		var short_res: String = "Поток" if m.is_hero else BattleTypes.get_resource_short_tag(m.primary_resource)
		var btn: Button = Button.new()
		btn.text = "%d. %s [%s]" % [i + 1, m.display_name, short_res]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 20.0)
		btn.add_theme_font_size_override("font_size", 9)
		if i == _selected_party_index:
			btn.disabled = true
			btn.modulate = Color(1.0, 0.92, 0.55, 1.0)
		var captured_idx: int = i
		btn.pressed.connect(func() -> void:
			_on_party_member_button_pressed(captured_idx)
		)
		_member_selector_hbox.add_child(btn)
	
	if GameManager != null and not GameManager.ship_roster.is_empty():
		var ship_hint_btn: Button = Button.new()
		ship_hint_btn.text = "Драккар (%d)" % GameManager.ship_roster.size()
		ship_hint_btn.custom_minimum_size = Vector2(78.0, 20.0)
		ship_hint_btn.add_theme_font_size_override("font_size", 8)
		ship_hint_btn.tooltip_text = "Открыть ротацию отряда с резервом корабля"
		ship_hint_btn.pressed.connect(_on_tab_ship_pressed)
		_member_selector_hbox.add_child(ship_hint_btn)

func _refresh_header_and_profile(member_data: CombatantData) -> void:
	if member_data == null:
		if _title_label != null:
			_title_label.text = "ОТРЯД И СНАРЯЖЕНИЕ"
		if _member_profile_label != null:
			_member_profile_label.text = ""
		return
	
	var role_str: String = member_data.role_title if not member_data.role_title.is_empty() else ("Лидер" if member_data.is_hero else "Рекрут")
	if _title_label != null:
		_title_label.text = "ОТРЯД И СНАРЯЖЕНИЕ — %s (%s)" % [member_data.display_name, role_str]
	
	if _member_profile_label != null:
		_member_profile_label.text = _format_member_profile(member_data)

func _format_member_profile(member_data: CombatantData) -> String:
	if member_data == null:
		return ""
	var parts: PackedStringArray = PackedStringArray()
	if member_data.is_hero:
		parts.append("Фирменное оружие ГГ")
	else:
		parts.append(InventoryTypes.get_weapon_category_display_name(member_data.weapon_category))
	
	var hands_cnt: int = member_data.equipment_loadout.available_hands if member_data.equipment_loadout != null else 2
	parts.append("1 рука" if hands_cnt == 1 else "2 руки")
	parts.append("Тяж.: да" if (member_data.is_hero or member_data.can_wear_heavy) else "Тяж.: нет")
	
	if not member_data.gifts.is_empty():
		var gift_names: PackedStringArray = PackedStringArray()
		for g: InventoryTypes.RelicGift in member_data.gifts:
			gift_names.append(InventoryTypes.get_relic_gift_display_name(g))
		parts.append("Дары: %s" % ", ".join(gift_names))
	
	if member_data.patron_god != BattleTypes.GodId.NONE:
		parts.append("Бог: %s" % BattleTypes.get_god_display_name(member_data.patron_god))
	if member_data.ancestral_rune_id != &"":
		parts.append("Руна: %s" % String(member_data.ancestral_rune_id))
	
	return " · ".join(parts)

func _rebuild_slots(member_data: CombatantData) -> void:
	if _slots_container == null:
		return
	for child: Node in _slots_container.get_children():
		child.queue_free()
	
	if member_data == null or member_data.equipment_loadout == null:
		return
	
	var loadout: EquipmentLoadout = member_data.equipment_loadout
	var two_handed: bool = loadout.is_two_handed_equipped()
	
	for slot_id: StringName in InventoryTypes.get_all_slot_ids():
		var slot_title: String = InventoryTypes.get_slot_display_name(slot_id)
		var item: EquipmentItemData = loadout.get_slot_item(slot_id)
		var btn: Button = Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0.0, 19.0)
		btn.add_theme_font_size_override("font_size", 8)
		
		if slot_id == InventoryTypes.SLOT_RIGHT_HAND and two_handed and loadout.left_hand != null:
			var occupied_item: EquipmentItemData = loadout.left_hand
			btn.text = "%s: [занята: %s]" % [slot_title, occupied_item.display_name]
			btn.tooltip_text = "Обе руки заняты двуручным оружием / комплектом. Нажмите, чтобы снять."
			var captured_slot: StringName = slot_id
			btn.pressed.connect(func() -> void:
				_on_slot_unequip_pressed(captured_slot)
			)
		elif item != null:
			var tag_2h: String = ""
			if item.is_set_bundle:
				tag_2h = " [Компл.]"
			elif item.slot_type == InventoryTypes.EquipmentSlotType.TWO_HAND:
				tag_2h = " [2Р]"
			btn.text = "%s: %s%s" % [slot_title, item.display_name, tag_2h]
			btn.tooltip_text = "%s\nНажмите, чтобы снять в инвентарь" % item.get_stat_summary()
			var captured_slot: StringName = slot_id
			btn.pressed.connect(func() -> void:
				_on_slot_unequip_pressed(captured_slot)
			)
		else:
			if slot_id == InventoryTypes.SLOT_RIGHT_HAND and loadout.available_hands < 2:
				btn.text = "%s: [1 рука — свободная]" % slot_title
			else:
				btn.text = "%s: — пусто —" % slot_title
			btn.disabled = true
		
		_slots_container.add_child(btn)

func _refresh_stats_and_synergy(member_data: CombatantData) -> void:
	if GameManager == null or member_data == null:
		return
	var status: Dictionary = GameManager.get_party_member_status(member_data)
	if status.is_empty():
		return
	
	if _stats_label != null:
		var work_res_name: String = str(status.get("working_resource_name", "Поток (ЭН)"))
		var flow_note: String = " [≥90% → Ожог]" if bool(status.get("has_flow_passive", false)) else ""
		var mana_part: String = ""
		if bool(status.get("has_mana", false)):
			mana_part = " (%d/%d)" % [int(status.get("current_mana", 0)), int(status.get("max_mana", 100))]
		var crit_pct: int = roundi(float(status.get("crit_chance", 0.05)) * 100.0)
		var crit_mult: float = float(status.get("crit_multiplier", 1.5))
		_stats_label.text = (
			"HP: %d/%d · %s%s%s\nАТК: %d  МАГ: %d  ЗАЩ: %d  СКР: %d  Крит: %d%% (x%.2f)" % [
				int(status.get("current_hp", 100)),
				int(status.get("max_hp", 100)),
				work_res_name,
				mana_part,
				flow_note,
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
					lines.append("✦ Синергия: %s" % syn.display_name)
		if syn_count == 0 and member_data.equipment_loadout != null:
			var l_item: EquipmentItemData = member_data.equipment_loadout.left_hand
			var r_item: EquipmentItemData = member_data.equipment_loadout.right_hand
			if member_data.equipment_loadout.is_two_handed_equipped() and l_item != null:
				lines.append("Раскладка рук: %s" % ("парный комплект" if l_item.is_set_bundle else "двуручное оружие"))
			elif (l_item != null and l_item.is_shield_item()) or (r_item != null and r_item.is_shield_item()):
				lines.append("✦ Щит: пассивное усиление Блока")
			elif member_data.equipment_loadout.available_hands == 1:
				lines.append("Раскладка рук: 1 рука (вторая свободна)")
			else:
				lines.append("Синергия рук: базовая раскладка")
		
		var sk_variant: Variant = status.get("granted_weapon_skills", [])
		var skill_names: PackedStringArray = PackedStringArray()
		if sk_variant is Array:
			for sk_entry: Variant in sk_variant:
				if sk_entry is SkillData:
					var sk_obj: SkillData = sk_entry as SkillData
					var qte_tag: String = ""
					if sk_obj.requires_qte and sk_obj.qte_config != null:
						qte_tag = " [%s]" % BattleTypes.get_qte_display_name(sk_obj.qte_config.qte_type)
					skill_names.append("%s%s" % [sk_obj.skill_name, qte_tag])
		if not skill_names.is_empty():
			lines.append("Оружие: %s" % ", ".join(skill_names))
		
		if not member_data.personal_skills.is_empty():
			var p_names: PackedStringArray = PackedStringArray()
			for p_sk: SkillData in member_data.personal_skills:
				if p_sk != null:
					p_names.append(p_sk.skill_name)
			if not p_names.is_empty():
				lines.append("Личные: %s" % ", ".join(p_names))
		
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
	if _tab_ship_btn != null:
		var ship_cnt: int = GameManager.ship_roster.size() if GameManager != null else 0
		_tab_ship_btn.text = "Отряд / Корабль (%d)" % ship_cnt
		_tab_ship_btn.disabled = (_active_tab == ActiveTab.SHIP_ROSTER)
	
	var member_data: CombatantData = _get_selected_member_data()
	match _active_tab:
		ActiveTab.EQUIPMENT:
			_rebuild_equipment_list(member_data)
		ActiveTab.CONSUMABLES:
			_rebuild_consumables_list(member_data)
		ActiveTab.SHIP_ROSTER:
			_rebuild_ship_roster_list()

func _rebuild_equipment_list(member_data: CombatantData) -> void:
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
	
	var loadout: EquipmentLoadout = member_data.equipment_loadout if member_data != null else null
	
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
		name_lbl.text = "%s%s" % [eq.display_name, _format_item_badges(eq)]
		name_lbl.add_theme_font_size_override("font_size", 9)
		if eq.is_legendary:
			name_lbl.modulate = Color(1.0, 0.62, 0.24, 1.0)
		elif eq.is_hero_signature:
			name_lbl.modulate = Color(0.55, 0.88, 1.0, 1.0)
		elif eq.is_unique:
			name_lbl.modulate = Color(1.0, 0.88, 0.55, 1.0)
		info_vbox.add_child(name_lbl)
		
		var cat_prefix: String = InventoryTypes.get_slot_type_display_name(eq.slot_type)
		var eff_cat: InventoryTypes.WeaponCategory = eq.get_effective_weapon_category()
		if eff_cat != InventoryTypes.WeaponCategory.NONE:
			cat_prefix = "%s (%s)" % [cat_prefix, InventoryTypes.get_weapon_category_display_name(eff_cat)]
		
		var sub_lbl: Label = Label.new()
		sub_lbl.text = "%s · %s" % [cat_prefix, eq.get_stat_summary()]
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_font_size_override("font_size", 8)
		sub_lbl.modulate = Color(0.74, 0.80, 0.90, 1.0)
		info_vbox.add_child(sub_lbl)
		
		var btn_hbox: HBoxContainer = HBoxContainer.new()
		btn_hbox.add_theme_constant_override("separation", 2)
		hbox.add_child(btn_hbox)
		
		var captured_eq: EquipmentItemData = eq
		if eq.occupies_both_hands():
			_add_validated_equip_button(btn_hbox, member_data, loadout, captured_eq, InventoryTypes.SLOT_LEFT_HAND, "Обе", "Надеть в обе руки")
		elif eq.slot_type == InventoryTypes.EquipmentSlotType.ONE_HAND or eq.is_shield_item():
			_add_validated_equip_button(btn_hbox, member_data, loadout, captured_eq, InventoryTypes.SLOT_LEFT_HAND, "Л", "Надеть в левую руку")
			_add_validated_equip_button(btn_hbox, member_data, loadout, captured_eq, InventoryTypes.SLOT_RIGHT_HAND, "П", "Надеть в правую руку")
		elif eq.slot_type == InventoryTypes.EquipmentSlotType.BODY:
			_add_validated_equip_button(btn_hbox, member_data, loadout, captured_eq, InventoryTypes.SLOT_BODY, "Надеть", "Надеть в слот «Тело»")
		elif eq.slot_type == InventoryTypes.EquipmentSlotType.ACCESSORY:
			_add_validated_equip_button(btn_hbox, member_data, loadout, captured_eq, InventoryTypes.SLOT_ACCESSORY_1, "Сл.1", "Надеть в Аксессуар 1")
			_add_validated_equip_button(btn_hbox, member_data, loadout, captured_eq, InventoryTypes.SLOT_ACCESSORY_2, "Сл.2", "Надеть в Аксессуар 2")
		
		card.tooltip_text = eq.description
		_item_list_container.add_child(card)

func _add_validated_equip_button(
	parent: HBoxContainer,
	member_data: CombatantData,
	loadout: EquipmentLoadout,
	eq: EquipmentItemData,
	slot_id: StringName,
	btn_label: String,
	default_tip: String
) -> void:
	var check: Dictionary = {"ok": true, "reason": ""}
	if loadout != null:
		check = loadout.can_equip_for_combatant(member_data, slot_id, eq)
	var allowed: bool = bool(check.get("ok", false))
	var reason: String = str(check.get("reason", ""))
	var btn: Button = _create_compact_action_btn(btn_label, default_tip if allowed else reason)
	if not allowed:
		btn.modulate = Color(0.62, 0.62, 0.68, 0.85)
	btn.pressed.connect(func() -> void:
		_on_equip_clicked(eq, slot_id)
	)
	parent.add_child(btn)

func _format_item_badges(eq: EquipmentItemData) -> String:
	var tags: PackedStringArray = PackedStringArray()
	if eq.is_hero_signature:
		tags.append("ГГ")
	if eq.is_legendary:
		tags.append("Легенд.")
	elif eq.is_unique and not eq.is_hero_signature:
		tags.append("Уник.")
	if eq.is_set_bundle:
		tags.append("Комплект")
	if eq.is_heavy:
		tags.append("Тяж.")
	return " [%s]" % ", ".join(tags) if not tags.is_empty() else ""

func _rebuild_consumables_list(member_data: CombatantData) -> void:
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
	
	var target_name: String = member_data.display_name if member_data != null else "Боец"
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
		sub_lbl.text = "%s (цель: %s)" % [cons.get_effect_summary(), target_name]
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_font_size_override("font_size", 8)
		sub_lbl.modulate = Color(0.74, 0.80, 0.90, 1.0)
		info_vbox.add_child(sub_lbl)
		
		var use_btn: Button = _create_compact_action_btn(
			"Выпить" if cons.usable_in_overworld else "В бою",
			cons.description
		)
		use_btn.disabled = not cons.usable_in_overworld or member_data == null
		var captured_cons: ConsumableItemData = cons
		use_btn.pressed.connect(func() -> void:
			_on_consumable_use_clicked(captured_cons)
		)
		hbox.add_child(use_btn)
		_item_list_container.add_child(card)

func _rebuild_ship_roster_list() -> void:
	if _item_list_container == null:
		return
	for child: Node in _item_list_container.get_children():
		child.queue_free()
	
	if GameManager == null:
		return
	
	var active_header: Label = Label.new()
	active_header.text = "АКТИВНЫЙ ОТРЯД (%d/%d) — слот 1 закреплён за ГГ:" % [
		GameManager.active_party.size(),
		BattleContext.MAX_PLAYER_PARTY_SIZE
	]
	active_header.add_theme_font_size_override("font_size", 9)
	active_header.modulate = Color(1.0, 0.88, 0.52, 1.0)
	_item_list_container.add_child(active_header)
	
	for i: int in range(GameManager.active_party.size()):
		var p_member: CombatantData = GameManager.active_party[i]
		if p_member == null:
			continue
		var st: Dictionary = GameManager.get_party_member_status(p_member)
		var card: PanelContainer = _create_item_card_panel()
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		card.add_child(hbox)
		
		var info_vbox: VBoxContainer = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 1)
		hbox.add_child(info_vbox)
		
		var role_txt: String = p_member.role_title if not p_member.role_title.is_empty() else ("Лидер" if p_member.is_hero else "Рекрут")
		var name_lbl: Label = Label.new()
		name_lbl.text = "[Слот %d] %s — %s" % [i + 1, p_member.display_name, role_txt]
		name_lbl.add_theme_font_size_override("font_size", 9)
		if i == _selected_party_index:
			name_lbl.modulate = Color(1.0, 0.92, 0.55, 1.0)
		info_vbox.add_child(name_lbl)
		
		var sub_lbl: Label = Label.new()
		sub_lbl.text = "HP %d/%d · %s · %s" % [
			int(st.get("current_hp", 100)),
			int(st.get("max_hp", 100)),
			str(st.get("working_resource_name", "Энергия")),
			_format_member_profile(p_member)
		]
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_font_size_override("font_size", 8)
		sub_lbl.modulate = Color(0.74, 0.82, 0.92, 1.0)
		info_vbox.add_child(sub_lbl)
		
		var btn_hbox: HBoxContainer = HBoxContainer.new()
		btn_hbox.add_theme_constant_override("separation", 2)
		hbox.add_child(btn_hbox)
		
		var sel_btn: Button = _create_compact_action_btn("Инв.", "Показать экипировку этого бойца слева")
		sel_btn.disabled = (i == _selected_party_index)
		var captured_i: int = i
		sel_btn.pressed.connect(func() -> void:
			_on_party_member_button_pressed(captured_i)
		)
		btn_hbox.add_child(sel_btn)
		
		if i > 0 and not p_member.is_hero:
			var send_btn: Button = _create_compact_action_btn("На драккар", "Отправить рекрута в резерв корабля")
			send_btn.pressed.connect(func() -> void:
				_on_send_to_ship_clicked(captured_i)
			)
			btn_hbox.add_child(send_btn)
		
		_item_list_container.add_child(card)
	
	var ship_header: Label = Label.new()
	ship_header.text = "РЕЗЕРВ НА ДРАККАРЕ (%d):" % GameManager.ship_roster.size()
	ship_header.add_theme_font_size_override("font_size", 9)
	ship_header.modulate = Color(0.62, 0.88, 1.0, 1.0)
	_item_list_container.add_child(ship_header)
	
	if GameManager.ship_roster.is_empty():
		_add_empty_list_label("На драккаре сейчас нет свободных рекрутов.")
		return
	
	for s_idx: int in range(GameManager.ship_roster.size()):
		var s_member: CombatantData = GameManager.ship_roster[s_idx]
		if s_member == null:
			continue
		var s_st: Dictionary = GameManager.get_party_member_status(s_member)
		var card: PanelContainer = _create_item_card_panel()
		var vbox_card: VBoxContainer = VBoxContainer.new()
		vbox_card.add_theme_constant_override("separation", 3)
		card.add_child(vbox_card)
		
		var name_lbl: Label = Label.new()
		var s_role: String = s_member.role_title if not s_member.role_title.is_empty() else "Рекрут"
		name_lbl.text = "%s — %s (%s)" % [
			s_member.display_name,
			s_role,
			str(s_st.get("working_resource_name", "Ресурс"))
		]
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.modulate = Color(0.88, 0.96, 1.0, 1.0)
		vbox_card.add_child(name_lbl)
		
		var sub_lbl: Label = Label.new()
		sub_lbl.text = "HP %d/%d · %s" % [
			int(s_st.get("current_hp", 100)),
			int(s_st.get("max_hp", 100)),
			_format_member_profile(s_member)
		]
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.add_theme_font_size_override("font_size", 8)
		sub_lbl.modulate = Color(0.74, 0.80, 0.90, 1.0)
		vbox_card.add_child(sub_lbl)
		
		var swap_row: HBoxContainer = HBoxContainer.new()
		swap_row.add_theme_constant_override("separation", 3)
		vbox_card.add_child(swap_row)
		
		var captured_ship_idx: int = s_idx
		if GameManager.active_party.size() < BattleContext.MAX_PLAYER_PARTY_SIZE:
			var add_btn: Button = _create_compact_action_btn("В отряд (+)", "Добавить рекрута в свободный слот отряда")
			add_btn.pressed.connect(func() -> void:
				_on_add_from_ship_clicked(captured_ship_idx)
			)
			swap_row.add_child(add_btn)
		
		for p_idx: int in range(1, GameManager.active_party.size()):
			var target_ally: CombatantData = GameManager.active_party[p_idx]
			if target_ally == null or target_ally.is_hero:
				continue
			var swap_btn: Button = _create_compact_action_btn(
				"↔ Сл.%d (%s)" % [p_idx + 1, target_ally.display_name],
				"Поменять местами с %s (слот %d)" % [target_ally.display_name, p_idx + 1]
			)
			var captured_party_idx: int = p_idx
			swap_btn.pressed.connect(func() -> void:
				_on_swap_party_ship_clicked(captured_party_idx, captured_ship_idx)
			)
			swap_row.add_child(swap_btn)
		
		_item_list_container.add_child(card)

func _on_swap_party_ship_clicked(party_idx: int, ship_idx: int) -> void:
	if GameManager == null:
		return
	var res: Dictionary = GameManager.swap_party_and_ship_member(party_idx, ship_idx)
	_set_feedback(str(res.get("reason", "")))
	if bool(res.get("ok", false)):
		_selected_party_index = party_idx
		_refresh_all()

func _on_send_to_ship_clicked(party_idx: int) -> void:
	if GameManager == null:
		return
	var res: Dictionary = GameManager.send_party_member_to_ship(party_idx)
	_set_feedback(str(res.get("reason", "")))
	if bool(res.get("ok", false)):
		_clamp_selected_party_index()
		_refresh_all()

func _on_add_from_ship_clicked(ship_idx: int) -> void:
	if GameManager == null:
		return
	var res: Dictionary = GameManager.add_ship_member_to_party(ship_idx)
	_set_feedback(str(res.get("reason", "")))
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
		_set_feedback("%s снимает в инвентарь: %s." % [member_data.display_name, ", ".join(names)])
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
		])
		equipment_changed.emit(slot_id)
		_refresh_all()
	else:
		_set_feedback(str(res.get("reason", "Не удалось экипировать предмет.")))

func _on_consumable_use_clicked(item: ConsumableItemData) -> void:
	var member_data: CombatantData = _get_selected_member_data()
	if member_data == null or GameManager == null or item == null:
		return
	var res: Dictionary = GameManager.use_overworld_consumable(member_data, item)
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
	btn.custom_minimum_size = Vector2(36.0, 20.0)
	btn.add_theme_font_size_override("font_size", 8)
	return btn
