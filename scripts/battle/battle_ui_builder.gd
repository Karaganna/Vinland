# res://scripts/battle/battle_ui_builder.gd
class_name BattleUIBuilder
extends RefCounted

## Процедурный сборщик боевого UI под базовый Viewport 640x360 для отряда до 4 бойцов
## Левая колонка арены (x=12..308, y=12..204) содержит 4 компактные карточки по 45 px без наложений

const MAX_PARTY_CARDS: int = 4

static func build_sandbox_ui(root: Control) -> Dictionary:
	if root == null:
		return {}
	
	root.position = Vector2.ZERO
	root.size = Vector2(640.0, 360.0)
	root.custom_minimum_size = Vector2(640.0, 360.0)
	
	# 1. Фон и верхняя боевая арена (y = 8..208)
	var bg: ColorRect = ColorRect.new()
	bg.name = "ArenaBackground"
	bg.size = Vector2(640.0, 360.0)
	bg.color = Color(0.07, 0.08, 0.12, 1.0)
	root.add_child(bg)
	
	var arena_floor: ColorRect = ColorRect.new()
	arena_floor.name = "ArenaFloor"
	arena_floor.position = Vector2(8.0, 8.0)
	arena_floor.size = Vector2(624.0, 200.0)
	arena_floor.color = Color(0.11, 0.13, 0.19, 1.0)
	root.add_child(arena_floor)
	
	var arena_border: ReferenceRect = ReferenceRect.new()
	arena_border.name = "ArenaBorder"
	arena_border.position = Vector2(8.0, 8.0)
	arena_border.size = Vector2(624.0, 200.0)
	arena_border.border_color = Color(0.28, 0.34, 0.48, 1.0)
	arena_border.border_width = 2.0
	arena_border.editor_only = false
	root.add_child(arena_border)
	
	# 2. Левая колонка арены: до 4 карточек бойцов отряда (4 * 45 + 3 * 3 = 189 px в y=13..202)
	var party_vbox: VBoxContainer = VBoxContainer.new()
	party_vbox.name = "PartyCardsVBox"
	party_vbox.position = Vector2(14.0, 13.0)
	party_vbox.size = Vector2(296.0, 190.0)
	party_vbox.add_theme_constant_override("separation", 3)
	root.add_child(party_vbox)
	
	var party_cards: Array[Dictionary] = []
	for idx: int in range(MAX_PARTY_CARDS):
		var card_dict: Dictionary = _create_party_member_card(idx)
		party_vbox.add_child(card_dict["panel"] as PanelContainer)
		party_cards.append(card_dict)
	
	# 3. Правая сторона арены (x = 320..624): Баннер телеграфа + Противник + части тела
	var telegraph_banner: Label = _create_label("TelegraphBanner", Vector2(318.0, 11.0), Vector2(308.0, 26.0), "", 9, HORIZONTAL_ALIGNMENT_RIGHT)
	telegraph_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	telegraph_banner.modulate = Color(1.0, 0.48, 0.22, 1.0)
	telegraph_banner.visible = false
	root.add_child(telegraph_banner)
	
	var enemy_name_lbl: Label = _create_label("EnemyNameLabel", Vector2(320.0, 38.0), Vector2(304.0, 16.0), "Противник", 11, HORIZONTAL_ALIGNMENT_RIGHT)
	root.add_child(enemy_name_lbl)
	
	var enemy_visual: ColorRect = ColorRect.new()
	enemy_visual.name = "EnemyVisualRect"
	enemy_visual.position = Vector2(552.0, 76.0)
	enemy_visual.size = Vector2(64.0, 80.0)
	enemy_visual.color = Color(0.75, 0.20, 0.16, 1.0)
	root.add_child(enemy_visual)
	
	var enemy_hp_bar: ProgressBar = _create_bar("EnemyHPBar", Vector2(346.0, 56.0), Vector2(196.0, 13.0), Color(0.86, 0.24, 0.24, 1.0))
	root.add_child(enemy_hp_bar)
	var enemy_hp_lbl: Label = _create_label("EnemyHPLabel", Vector2(350.0, 54.0), Vector2(188.0, 15.0), "HP: 380/380", 9, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(enemy_hp_lbl)
	
	var enemy_parts_lbl: Label = _create_label("EnemyPartsLabel", Vector2(324.0, 74.0), Vector2(220.0, 84.0), "", 9)
	enemy_parts_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_parts_lbl.modulate = Color(0.95, 0.90, 0.72, 1.0)
	root.add_child(enemy_parts_lbl)
	
	var enemy_statuses_lbl: Label = _create_label("EnemyStatusesLabel", Vector2(324.0, 162.0), Vector2(298.0, 40.0), "", 9, HORIZONTAL_ALIGNMENT_RIGHT)
	enemy_statuses_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_statuses_lbl.modulate = Color(1.0, 0.80, 0.72, 1.0)
	root.add_child(enemy_statuses_lbl)
	
	# 4. Нижняя панель (y = 212..354)
	var bottom_panel: PanelContainer = PanelContainer.new()
	bottom_panel.name = "BottomBattlePanel"
	bottom_panel.position = Vector2(8.0, 212.0)
	bottom_panel.size = Vector2(624.0, 142.0)
	var bp_style: StyleBoxFlat = StyleBoxFlat.new()
	bp_style.bg_color = Color(0.09, 0.11, 0.16, 0.96)
	bp_style.border_color = Color(0.35, 0.42, 0.58, 1.0)
	bp_style.set_border_width_all(2)
	bp_style.set_corner_radius_all(3)
	bp_style.content_margin_left = 6.0
	bp_style.content_margin_right = 6.0
	bp_style.content_margin_top = 5.0
	bp_style.content_margin_bottom = 5.0
	bottom_panel.add_theme_stylebox_override("panel", bp_style)
	root.add_child(bottom_panel)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "BottomHBox"
	hbox.add_theme_constant_override("separation", 6)
	bottom_panel.add_child(hbox)
	
	# Левая колонка нижней панели: 5 кнопок меню
	var action_menu: VBoxContainer = VBoxContainer.new()
	action_menu.name = "ActionMenuContainer"
	action_menu.custom_minimum_size = Vector2(150.0, 128.0)
	action_menu.add_theme_constant_override("separation", 3)
	hbox.add_child(action_menu)
	
	var attack_btn: Button = _create_menu_button("AttackButton", "⚔ Атака")
	var skill_btn: Button = _create_menu_button("SkillButton", "✦ Умения")
	var block_btn: Button = _create_menu_button("BlockButton", "🛡 Блок")
	var item_btn: Button = _create_menu_button("ItemButton", "🎒 Предмет")
	var ultimate_btn: Button = _create_menu_button("UltimateButton", "★ Ульта")
	action_menu.add_child(attack_btn)
	action_menu.add_child(skill_btn)
	action_menu.add_child(block_btn)
	action_menu.add_child(item_btn)
	action_menu.add_child(ultimate_btn)
	
	var vsep: VSeparator = VSeparator.new()
	hbox.add_child(vsep)
	
	# Правая колонка нижней панели: лог боя сверху + подменю / слот QTE снизу
	var right_col: VBoxContainer = VBoxContainer.new()
	right_col.name = "RightInteractionColumn"
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 4)
	hbox.add_child(right_col)
	
	var log_lbl: RichTextLabel = RichTextLabel.new()
	log_lbl.name = "CombatLogLabel"
	log_lbl.bbcode_enabled = true
	log_lbl.scroll_following = true
	log_lbl.custom_minimum_size = Vector2(0.0, 42.0)
	log_lbl.add_theme_font_size_override("normal_font_size", 10)
	log_lbl.add_theme_font_size_override("bold_font_size", 10)
	right_col.add_child(log_lbl)
	
	var lower_area: Control = Control.new()
	lower_area.name = "LowerWorkArea"
	lower_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lower_area.custom_minimum_size = Vector2(0.0, 82.0)
	right_col.add_child(lower_area)
	
	var sub_scroll: ScrollContainer = ScrollContainer.new()
	sub_scroll.name = "SubMenuScroll"
	sub_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sub_scroll.visible = false
	lower_area.add_child(sub_scroll)
	
	var sub_menu: VBoxContainer = VBoxContainer.new()
	sub_menu.name = "SubMenuContainer"
	sub_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_menu.add_theme_constant_override("separation", 3)
	sub_menu.visible = false
	sub_scroll.add_child(sub_menu)
	
	var qte_slot: Control = Control.new()
	qte_slot.name = "QTESlotContainer"
	qte_slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	qte_slot.visible = false
	lower_area.add_child(qte_slot)
	
	var first_card: Dictionary = party_cards[0]
	return {
		"attack_button": attack_btn,
		"skill_button": skill_btn,
		"block_button": block_btn,
		"item_button": item_btn,
		"ultimate_button": ultimate_btn,
		"action_menu_container": action_menu,
		"sub_menu_scroll": sub_scroll,
		"sub_menu_container": sub_menu,
		"qte_slot_container": qte_slot,
		"party_cards": party_cards,
		"player_name_label": first_card["name_label"],
		"player_hp_bar": first_card["hp_bar"],
		"player_hp_label": first_card["hp_label"],
		"working_resource_bar": first_card["res_bar"],
		"working_resource_value_label": first_card["res_label"],
		"tension_bar": first_card["tension_bar"],
		"tension_value_label": first_card["tension_label"],
		"player_statuses_label": first_card["status_label"],
		"enemy_name_label": enemy_name_lbl,
		"enemy_hp_bar": enemy_hp_bar,
		"enemy_hp_label": enemy_hp_lbl,
		"enemy_parts_label": enemy_parts_lbl,
		"enemy_statuses_label": enemy_statuses_lbl,
		"enemy_visual_rect": enemy_visual,
		"telegraph_banner_label": telegraph_banner,
		"combat_log_label": log_lbl
	}

static func _create_party_member_card(index: int) -> Dictionary:
	var card: PanelContainer = PanelContainer.new()
	card.name = "PartyMemberCard_%d" % index
	card.custom_minimum_size = Vector2(296.0, 45.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.16, 0.23, 0.94)
	style.border_color = Color(0.30, 0.36, 0.50, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	card.add_theme_stylebox_override("panel", style)
	
	var row_hbox: HBoxContainer = HBoxContainer.new()
	row_hbox.add_theme_constant_override("separation", 5)
	card.add_child(row_hbox)
	
	# Цветной индикатор / портретная плашка бойца
	var badge: ColorRect = ColorRect.new()
	badge.name = "BadgeRect"
	badge.custom_minimum_size = Vector2(18.0, 38.0)
	badge.color = Color(0.25, 0.58, 0.94, 1.0)
	row_hbox.add_child(badge)
	
	if index == 0 and ResourceLoader.exists("res://assets/sprites/player/walk/right/sprite_0.png"):
		var mini_spr: Sprite2D = Sprite2D.new()
		mini_spr.texture = load("res://assets/sprites/player/walk/right/sprite_0.png") as Texture2D
		mini_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mini_spr.scale = Vector2(0.55, 0.55)
		mini_spr.position = Vector2(9.0, 19.0)
		badge.add_child(mini_spr)
	
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 1)
	row_hbox.add_child(info_vbox)
	
	# Строка 1: Имя бойца + краткие статусы
	var top_hbox: HBoxContainer = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 4)
	info_vbox.add_child(top_hbox)
	
	var name_lbl: Label = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = "Боец %d" % (index + 1)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 9)
	top_hbox.add_child(name_lbl)
	
	var status_lbl: Label = Label.new()
	status_lbl.name = "StatusLabel"
	status_lbl.text = ""
	status_lbl.custom_minimum_size = Vector2(112.0, 12.0)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_lbl.clip_text = true
	status_lbl.add_theme_font_size_override("font_size", 8)
	status_lbl.modulate = Color(0.80, 0.92, 1.0, 1.0)
	top_hbox.add_child(status_lbl)
	
	# Строка 2: HP (слева) + Напряжение Ульты (справа)
	var mid_hbox: HBoxContainer = HBoxContainer.new()
	mid_hbox.add_theme_constant_override("separation", 4)
	info_vbox.add_child(mid_hbox)
	
	var hp_pair: Dictionary = _create_compact_overlay_bar("HP", Vector2(142.0, 11.0), Color(0.22, 0.78, 0.34, 1.0))
	mid_hbox.add_child(hp_pair["holder"] as Control)
	
	var tension_pair: Dictionary = _create_compact_overlay_bar("Tension", Vector2(116.0, 11.0), BattleTypes.get_resource_color(BattleTypes.ResourceType.TENSION))
	mid_hbox.add_child(tension_pair["holder"] as Control)
	
	# Строка 3: Рабочий бак («Поток (режим)» у ГГ или единственный бак у рекрута)
	var res_pair: Dictionary = _create_compact_overlay_bar("WorkingRes", Vector2(262.0, 11.0), BattleTypes.get_resource_color(BattleTypes.ResourceType.ENERGY))
	info_vbox.add_child(res_pair["holder"] as Control)
	
	return {
		"panel": card,
		"style": style,
		"badge": badge,
		"name_label": name_lbl,
		"status_label": status_lbl,
		"hp_bar": hp_pair["bar"],
		"hp_label": hp_pair["label"],
		"tension_bar": tension_pair["bar"],
		"tension_label": tension_pair["label"],
		"res_bar": res_pair["bar"],
		"res_label": res_pair["label"]
	}

static func _create_compact_overlay_bar(p_prefix: String, p_size: Vector2, fill_col: Color) -> Dictionary:
	var holder: Control = Control.new()
	holder.name = p_prefix + "Holder"
	holder.custom_minimum_size = p_size
	holder.size = p_size
	
	var bar: ProgressBar = _create_bar(p_prefix + "Bar", Vector2.ZERO, p_size, fill_col)
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(bar)
	
	var lbl: Label = Label.new()
	lbl.name = p_prefix + "Text"
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 8)
	holder.add_child(lbl)
	
	return {"holder": holder, "bar": bar, "label": lbl}

static func _create_label(
	p_name: String,
	p_pos: Vector2,
	p_size: Vector2,
	p_text: String,
	p_font_size: int,
	p_align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var lbl: Label = Label.new()
	lbl.name = p_name
	lbl.position = p_pos
	lbl.size = p_size
	lbl.text = p_text
	lbl.horizontal_alignment = p_align
	lbl.add_theme_font_size_override("font_size", p_font_size)
	return lbl

static func _create_bar(p_name: String, p_pos: Vector2, p_size: Vector2, fill_color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.name = p_name
	bar.position = p_pos
	bar.size = p_size
	bar.show_percentage = false
	
	var bg_st: StyleBoxFlat = StyleBoxFlat.new()
	bg_st.bg_color = Color(0.10, 0.12, 0.17, 1.0)
	bg_st.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg_st)
	
	var fill_st: StyleBoxFlat = StyleBoxFlat.new()
	fill_st.bg_color = fill_color
	fill_st.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill_st)
	return bar

static func _create_menu_button(p_name: String, p_text: String) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.text = p_text
	btn.custom_minimum_size = Vector2(146.0, 22.0)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 10)
	return btn
