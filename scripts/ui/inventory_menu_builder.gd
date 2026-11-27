# res://scripts/ui/inventory_menu_builder.gd
class_name InventoryMenuBuilder
extends RefCounted

## Процедурный сборщик 16-битного скандинавского UI инвентаря строго под базовый Viewport 640x360
## Использует 9-slice текстуры дерева/железа/золота и пиксельные иконки из InventoryVisualFactory
static func build_overlay_ui(root: CanvasLayer) -> Dictionary:
	if root == null:
		return {}
	
	# Компактная кованая кнопка открытия в правом верхнем углу оверворлда
	var hud_btn: Button = Button.new()
	hud_btn.name = "HudToggleButton"
	hud_btn.text = "ИНВЕНТАРЬ [I]"
	hud_btn.position = Vector2(512.0, 8.0)
	hud_btn.size = Vector2(120.0, 22.0)
	hud_btn.focus_mode = Control.FOCUS_NONE
	hud_btn.add_theme_font_size_override("font_size", 9)
	InventoryVisualFactory.style_iron_button(hud_btn, true)
	root.add_child(hud_btn)
	
	# Корневой полноэкранный контейнер 640x360 с жестким клиппингом и Nearest-фильтрацией
	var overlay_root: Control = Control.new()
	overlay_root.name = "OverlayRoot"
	overlay_root.position = Vector2.ZERO
	overlay_root.size = Vector2(640.0, 360.0)
	overlay_root.clip_contents = true
	overlay_root.visible = false
	overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(overlay_root)
	
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(640.0, 360.0)
	backdrop.color = InventoryVisualFactory.COLOR_BACKDROP
	overlay_root.add_child(backdrop)
	
	# Рабочая область 628x348 с полями 6 px по периметру
	var workspace: VBoxContainer = VBoxContainer.new()
	workspace.name = "WorkspaceRoot"
	workspace.position = Vector2(6.0, 6.0)
	workspace.size = Vector2(628.0, 348.0)
	workspace.clip_contents = true
	workspace.add_theme_constant_override("separation", 3)
	overlay_root.add_child(workspace)
	
	# =========================================================================
	# 1. ВЕРХНЯЯ ШАПКА (628x44): Заголовок + 4 портрета отряда + кнопка [X]
	# =========================================================================
	var header_panel: PanelContainer = PanelContainer.new()
	header_panel.name = "HeaderPanel"
	header_panel.custom_minimum_size = Vector2(628.0, 44.0)
	header_panel.add_theme_stylebox_override("panel", InventoryVisualFactory.get_header_metal_style())
	workspace.add_child(header_panel)
	
	var header_hbox: HBoxContainer = HBoxContainer.new()
	header_hbox.name = "HeaderHBox"
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 6)
	header_panel.add_child(header_hbox)
	
	var title_vbox: VBoxContainer = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_vbox.add_theme_constant_override("separation", 0)
	header_hbox.add_child(title_vbox)
	
	var title_main_lbl: Label = Label.new()
	title_main_lbl.name = "TitleLabel"
	title_main_lbl.text = "ИНВЕНТАРЬ"
	title_main_lbl.clip_text = true
	title_main_lbl.add_theme_font_size_override("font_size", 12)
	title_main_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD)
	title_main_lbl.add_theme_color_override("font_outline_color", InventoryVisualFactory.OUTLINE_DARK)
	title_main_lbl.add_theme_constant_override("outline_size", 2)
	title_vbox.add_child(title_main_lbl)
	
	var title_sub_lbl: Label = Label.new()
	title_sub_lbl.name = "SubtitleLabel"
	title_sub_lbl.text = "Главный герой · Вождь дружины"
	title_sub_lbl.clip_text = true
	title_sub_lbl.add_theme_font_size_override("font_size", 8)
	title_sub_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_SECONDARY)
	title_vbox.add_child(title_sub_lbl)
	
	var portraits_hbox: HBoxContainer = HBoxContainer.new()
	portraits_hbox.name = "MemberSelectorHBox"
	portraits_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	portraits_hbox.add_theme_constant_override("separation", 4)
	header_hbox.add_child(portraits_hbox)
	
	var close_btn: Button = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = ""
	close_btn.tooltip_text = "Закрыть меню [Esc]"
	close_btn.custom_minimum_size = Vector2(32.0, 32.0)
	InventoryVisualFactory.style_iron_button(close_btn, false)
	header_hbox.add_child(close_btn)
	
	var close_icon: TextureRect = TextureRect.new()
	close_icon.texture = InventoryVisualFactory.get_close_cross_icon()
	close_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	close_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	close_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close_icon.position = Vector2(10.0, 10.0)
	close_icon.size = Vector2(12.0, 12.0)
	close_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_btn.add_child(close_icon)
	
	# =========================================================================
	# 2. СРЕДНЯЯ ДВУХКОЛОНОЧНАЯ ОБЛАСТЬ (282 px по высоте)
	# =========================================================================
	var middle_hbox: HBoxContainer = HBoxContainer.new()
	middle_hbox.name = "BodyHBox"
	middle_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle_hbox.clip_contents = true
	middle_hbox.add_theme_constant_override("separation", 6)
	workspace.add_child(middle_hbox)
	
	# -------------------------------------------------------------------------
	# 2A. Левая панель (258 px): Кукла бойца + 5 слотов + ячейка-герб + бары + статы
	# -------------------------------------------------------------------------
	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.name = "LeftDollPanel"
	left_panel.custom_minimum_size = Vector2(258.0, 0.0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.clip_contents = true
	left_panel.add_theme_stylebox_override("panel", InventoryVisualFactory.get_panel_wood_iron_style())
	middle_hbox.add_child(left_panel)
	
	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.name = "LeftDollVBox"
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.clip_contents = true
	left_vbox.add_theme_constant_override("separation", 3)
	left_panel.add_child(left_vbox)
	
	# Верхняя сцена куклы (244x166)
	var doll_stage: Control = Control.new()
	doll_stage.name = "DollStageControl"
	doll_stage.custom_minimum_size = Vector2(244.0, 166.0)
	doll_stage.clip_contents = true
	left_vbox.add_child(doll_stage)
	
	var stage_niche: Panel = Panel.new()
	stage_niche.name = "DollPedestalNiche"
	stage_niche.position = Vector2(46.0, 2.0)
	stage_niche.size = Vector2(152.0, 162.0)
	stage_niche.add_theme_stylebox_override("panel", InventoryVisualFactory.get_inspector_recessed_style())
	doll_stage.add_child(stage_niche)
	
	var doll_role_lbl: Label = Label.new()
	doll_role_lbl.name = "MemberProfileLabel"
	doll_role_lbl.position = Vector2(50.0, 6.0)
	doll_role_lbl.size = Vector2(144.0, 14.0)
	doll_role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	doll_role_lbl.clip_text = true
	doll_role_lbl.add_theme_font_size_override("font_size", 8)
	doll_role_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD)
	doll_stage.add_child(doll_role_lbl)
	
	var shadow_rect: TextureRect = TextureRect.new()
	shadow_rect.name = "DollShadowRect"
	shadow_rect.texture = InventoryVisualFactory.get_pedestal_shadow_texture()
	shadow_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow_rect.stretch_mode = TextureRect.STRETCH_SCALE
	shadow_rect.position = Vector2(78.0, 138.0)
	shadow_rect.size = Vector2(88.0, 18.0)
	shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	doll_stage.add_child(shadow_rect)
	
	var doll_sprite: TextureRect = TextureRect.new()
	doll_sprite.name = "DollFullbodySprite"
	doll_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	doll_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	doll_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	doll_sprite.position = Vector2(74.0, 22.0)
	doll_sprite.size = Vector2(96.0, 128.0)
	doll_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	doll_stage.add_child(doll_sprite)
	
	# Левый столбец (3 слота 40x40: Левая рука, Тело, Аксессуар 1)
	var left_slots_col: VBoxContainer = VBoxContainer.new()
	left_slots_col.name = "LeftSlotsColumn"
	left_slots_col.position = Vector2(2.0, 13.0)
	left_slots_col.size = Vector2(40.0, 140.0)
	left_slots_col.add_theme_constant_override("separation", 8)
	doll_stage.add_child(left_slots_col)
	
	# Правый столбец (2 слота 40x40: Правая рука, Аксессуар 2 + 1 информационная ячейка-герб)
	var right_slots_col: VBoxContainer = VBoxContainer.new()
	right_slots_col.name = "RightSlotsColumn"
	right_slots_col.position = Vector2(202.0, 13.0)
	right_slots_col.size = Vector2(40.0, 140.0)
	right_slots_col.add_theme_constant_override("separation", 8)
	doll_stage.add_child(right_slots_col)
	
	# Парные пиксельные шкалы HP и Потока/бака
	var bars_hbox: HBoxContainer = HBoxContainer.new()
	bars_hbox.name = "VitalsBarsHBox"
	bars_hbox.add_theme_constant_override("separation", 4)
	left_vbox.add_child(bars_hbox)
	
	var hp_bar_dict: Dictionary = _build_vital_bar("HpBar", InventoryVisualFactory.BAR_HP, false)
	bars_hbox.add_child(hp_bar_dict["bar"] as ProgressBar)
	
	var res_bar_dict: Dictionary = _build_vital_bar("ResourceBar", InventoryVisualFactory.BAR_ENERGY, true)
	bars_hbox.add_child(res_bar_dict["bar"] as ProgressBar)
	
	# Полоса иконочных статов (АТК, МАГ, ЗАЩ, СКР, Крит)
	var stats_strip: HBoxContainer = HBoxContainer.new()
	stats_strip.name = "StatsIconStrip"
	stats_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_strip.add_theme_constant_override("separation", 5)
	left_vbox.add_child(stats_strip)
	
	var atk_val_lbl: Label = _add_stat_chip(stats_strip, "atk", "16", InventoryVisualFactory.TEXT_PRIMARY)
	var mag_val_lbl: Label = _add_stat_chip(stats_strip, "mag", "18", InventoryVisualFactory.TEXT_PRIMARY)
	var def_val_lbl: Label = _add_stat_chip(stats_strip, "def", "12", InventoryVisualFactory.TEXT_PRIMARY)
	var spd_val_lbl: Label = _add_stat_chip(stats_strip, "spd", "14", InventoryVisualFactory.TEXT_PRIMARY)
	var crit_val_lbl: Label = _add_stat_chip(stats_strip, "crit", "15%", InventoryVisualFactory.TEXT_GOLD)
	
	# Компактное окно сводки синергий / Резонанса / Благословения / ограничений
	var synergy_scroll: ScrollContainer = ScrollContainer.new()
	synergy_scroll.name = "SynergyScroll"
	synergy_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	synergy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	synergy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_vbox.add_child(synergy_scroll)
	
	var synergy_lbl: Label = Label.new()
	synergy_lbl.name = "SynergyLabel"
	synergy_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	synergy_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	synergy_lbl.add_theme_font_size_override("font_size", 8)
	synergy_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_SECONDARY)
	synergy_scroll.add_child(synergy_lbl)
	
	# -------------------------------------------------------------------------
	# 2B. Правая панель (364 px): 5 иконочных вкладок + гибкий Scroll + закрепленный Инспектор
	# -------------------------------------------------------------------------
	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.name = "RightMainPanel"
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.clip_contents = true
	right_panel.add_theme_stylebox_override("panel", InventoryVisualFactory.get_panel_wood_iron_style())
	middle_hbox.add_child(right_panel)
	
	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.name = "RightMainVBox"
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.clip_contents = true
	right_vbox.add_theme_constant_override("separation", 4)
	right_panel.add_child(right_vbox)
	
	# Полоса из 5 равных иконочных вкладок (height = 36 px)
	var tabs_hbox: HBoxContainer = HBoxContainer.new()
	tabs_hbox.name = "TabsHBox"
	tabs_hbox.custom_minimum_size = Vector2(0.0, 36.0)
	tabs_hbox.add_theme_constant_override("separation", 3)
	right_vbox.add_child(tabs_hbox)
	
	var tab_eq: Dictionary = _build_icon_tab_button("TabEquipmentButton", "equip", "ЭКИП")
	tabs_hbox.add_child(tab_eq["button"] as Button)
	
	var tab_cons: Dictionary = _build_icon_tab_button("TabConsumablesButton", "items", "ВЕЩИ")
	tabs_hbox.add_child(tab_cons["button"] as Button)
	
	var tab_ship: Dictionary = _build_icon_tab_button("TabShipButton", "party", "ОТРЯД")
	tabs_hbox.add_child(tab_ship["button"] as Button)
	
	var tab_runes: Dictionary = _build_icon_tab_button("TabRunesButton", "runes", "РУНЫ")
	tabs_hbox.add_child(tab_runes["button"] as Button)
	
	var tab_gods: Dictionary = _build_icon_tab_button("TabGodsButton", "gods", "БОГИ")
	tabs_hbox.add_child(tab_gods["button"] as Button)
	
	# Гибкий вертикальный ScrollContainer между вкладками и закрепленным инспектором
	var item_scroll: ScrollContainer = ScrollContainer.new()
	item_scroll.name = "ItemListScroll"
	item_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_vbox.add_child(item_scroll)
	
	var item_list: VBoxContainer = VBoxContainer.new()
	item_list.name = "ItemListContainer"
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 4)
	item_scroll.add_child(item_list)
	
	# Закрепленный инспектор выбранного предмета (height = 76 px, виден на ЭКИП и ВЕЩИ)
	var inspector_panel: PanelContainer = PanelContainer.new()
	inspector_panel.name = "InspectorPanel"
	inspector_panel.custom_minimum_size = Vector2(0.0, 76.0)
	inspector_panel.clip_contents = true
	inspector_panel.add_theme_stylebox_override("panel", InventoryVisualFactory.get_inspector_recessed_style())
	right_vbox.add_child(inspector_panel)
	
	var insp_hbox: HBoxContainer = HBoxContainer.new()
	insp_hbox.name = "InspectorHBox"
	insp_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	insp_hbox.add_theme_constant_override("separation", 6)
	inspector_panel.add_child(insp_hbox)
	
	var insp_icon_frame: PanelContainer = PanelContainer.new()
	insp_icon_frame.name = "InspectorIconFrame"
	insp_icon_frame.custom_minimum_size = Vector2(46.0, 46.0)
	insp_icon_frame.add_theme_stylebox_override("panel", InventoryVisualFactory.get_slot_style("selected"))
	insp_hbox.add_child(insp_icon_frame)
	
	var insp_icon_center: CenterContainer = CenterContainer.new()
	insp_icon_frame.add_child(insp_icon_center)
	
	var insp_icon_rect: TextureRect = TextureRect.new()
	insp_icon_rect.name = "InspectorIconRect"
	insp_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	insp_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	insp_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	insp_icon_rect.custom_minimum_size = Vector2(32.0, 32.0)
	insp_icon_center.add_child(insp_icon_rect)
	
	var insp_info_vbox: VBoxContainer = VBoxContainer.new()
	insp_info_vbox.name = "InspectorInfoVBox"
	insp_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insp_info_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	insp_info_vbox.clip_contents = true
	insp_info_vbox.add_theme_constant_override("separation", 1)
	insp_hbox.add_child(insp_info_vbox)
	
	var insp_title_lbl: Label = Label.new()
	insp_title_lbl.name = "InspectorTitleLabel"
	insp_title_lbl.clip_text = true
	insp_title_lbl.add_theme_font_size_override("font_size", 9)
	insp_title_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD)
	insp_info_vbox.add_child(insp_title_lbl)
	
	var insp_stats_hbox: HBoxContainer = HBoxContainer.new()
	insp_stats_hbox.name = "InspectorStatsHBox"
	insp_stats_hbox.add_theme_constant_override("separation", 5)
	insp_info_vbox.add_child(insp_stats_hbox)
	
	var insp_desc_lbl: Label = Label.new()
	insp_desc_lbl.name = "InspectorDescLabel"
	insp_desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insp_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	insp_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	insp_desc_lbl.clip_text = true
	insp_desc_lbl.add_theme_font_size_override("font_size", 8)
	insp_desc_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_SECONDARY)
	insp_info_vbox.add_child(insp_desc_lbl)
	
	var insp_actions_vbox: VBoxContainer = VBoxContainer.new()
	insp_actions_vbox.name = "InspectorActionsVBox"
	insp_actions_vbox.custom_minimum_size = Vector2(60.0, 0.0)
	insp_actions_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	insp_actions_vbox.add_theme_constant_override("separation", 3)
	insp_hbox.add_child(insp_actions_vbox)
	
	# =========================================================================
	# 3. НИЖНИЙ ФУТЕР УВЕДОМЛЕНИЙ (628x16)
	# =========================================================================
	var footer_panel: PanelContainer = PanelContainer.new()
	footer_panel.name = "FooterPanel"
	footer_panel.custom_minimum_size = Vector2(628.0, 16.0)
	var foot_style: StyleBoxFlat = StyleBoxFlat.new()
	foot_style.bg_color = Color(0.05, 0.07, 0.11, 0.90)
	foot_style.border_color = InventoryVisualFactory.IRON_DARK
	foot_style.set_border_width_all(1)
	foot_style.content_margin_left = 8.0
	foot_style.content_margin_right = 8.0
	foot_style.content_margin_top = 1.0
	foot_style.content_margin_bottom = 1.0
	footer_panel.add_theme_stylebox_override("panel", foot_style)
	workspace.add_child(footer_panel)
	
	var feedback_lbl: Label = Label.new()
	feedback_lbl.name = "StatusFeedbackLabel"
	feedback_lbl.clip_text = true
	feedback_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_lbl.add_theme_font_size_override("font_size", 8)
	feedback_lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_GOLD)
	footer_panel.add_child(feedback_lbl)
	
	return {
		"hud_toggle_button": hud_btn,
		"overlay_root": overlay_root,
		"title_label": title_main_lbl,
		"subtitle_label": title_sub_lbl,
		"close_button": close_btn,
		"member_selector_hbox": portraits_hbox,
		"member_profile_label": doll_role_lbl,
		"doll_fullbody_sprite": doll_sprite,
		"left_slots_column": left_slots_col,
		"right_slots_column": right_slots_col,
		"hp_bar": hp_bar_dict["bar"],
		"hp_bar_label": hp_bar_dict["label"],
		"res_bar": res_bar_dict["bar"],
		"res_bar_label": res_bar_dict["label"],
		"res_bar_icon": res_bar_dict["icon"],
		"atk_value_label": atk_val_lbl,
		"mag_value_label": mag_val_lbl,
		"def_value_label": def_val_lbl,
		"spd_value_label": spd_val_lbl,
		"crit_value_label": crit_val_lbl,
		"synergy_label": synergy_lbl,
		"tab_equipment_button": tab_eq["button"],
		"tab_equipment_label": tab_eq["label"],
		"tab_consumables_button": tab_cons["button"],
		"tab_consumables_label": tab_cons["label"],
		"tab_ship_button": tab_ship["button"],
		"tab_ship_label": tab_ship["label"],
		"tab_runes_button": tab_runes["button"],
		"tab_runes_label": tab_runes["label"],
		"tab_gods_button": tab_gods["button"],
		"tab_gods_label": tab_gods["label"],
		"item_list_scroll": item_scroll,
		"item_list_container": item_list,
		"inspector_panel": inspector_panel,
		"inspector_icon_frame": insp_icon_frame,
		"inspector_icon_rect": insp_icon_rect,
		"inspector_title_label": insp_title_lbl,
		"inspector_stats_hbox": insp_stats_hbox,
		"inspector_desc_label": insp_desc_lbl,
		"inspector_actions_vbox": insp_actions_vbox,
		"feedback_label": feedback_lbl
	}

static func _build_vital_bar(p_name: String, fill_color: Color, with_icon: bool) -> Dictionary:
	var bar: ProgressBar = ProgressBar.new()
	bar.name = p_name
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0.0, 16.0)
	bar.show_percentage = false
	bar.max_value = 100.0
	bar.value = 100.0
	bar.add_theme_stylebox_override("background", InventoryVisualFactory.get_bar_frame_style())
	bar.add_theme_stylebox_override("fill", InventoryVisualFactory.get_bar_fill_style(fill_color))
	
	var overlay_hbox: HBoxContainer = HBoxContainer.new()
	overlay_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay_hbox.add_theme_constant_override("separation", 2)
	overlay_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(overlay_hbox)
	
	var icon_rect: TextureRect = null
	if with_icon:
		icon_rect = TextureRect.new()
		icon_rect.texture = InventoryVisualFactory.get_resource_icon(BattleTypes.ResourceType.ENERGY)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(11.0, 11.0)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_hbox.add_child(icon_rect)
	
	var lbl: Label = Label.new()
	lbl.text = "100/100"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_PRIMARY)
	lbl.add_theme_color_override("font_outline_color", InventoryVisualFactory.OUTLINE_DARK)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_hbox.add_child(lbl)
	
	return {"bar": bar, "label": lbl, "icon": icon_rect}

static func _add_stat_chip(parent: HBoxContainer, stat_key: String, default_text: String, txt_color: Color) -> Label:
	var pair: HBoxContainer = HBoxContainer.new()
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	pair.add_theme_constant_override("separation", 2)
	parent.add_child(pair)
	
	var icon: TextureRect = TextureRect.new()
	icon.texture = InventoryVisualFactory.get_stat_icon(stat_key)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(12.0, 12.0)
	pair.add_child(icon)
	
	var lbl: Label = Label.new()
	lbl.text = default_text
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", txt_color)
	pair.add_child(lbl)
	return lbl

static func _build_icon_tab_button(p_name: String, icon_key: String, caption: String) -> Dictionary:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0.0, 36.0)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 1)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)
	
	var center_ic: CenterContainer = CenterContainer.new()
	center_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(center_ic)
	
	var ic: TextureRect = TextureRect.new()
	ic.texture = InventoryVisualFactory.get_tab_icon(icon_key)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(14.0, 14.0)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_ic.add_child(ic)
	
	var lbl: Label = Label.new()
	lbl.text = caption
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", InventoryVisualFactory.TEXT_PRIMARY)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	
	return {"button": btn, "label": lbl}
