# res://scripts/ui/inventory_menu_builder.gd
class_name InventoryMenuBuilder
extends RefCounted

## Процедурный сборщик UI инвентаря и 5 слотов экипировки для базового Viewport 640x360
static func build_overlay_ui(root: CanvasLayer) -> Dictionary:
	if root == null:
		return {}
	
	# Компактная кнопка открытия в правом верхнем углу оверворлда
	var hud_btn: Button = Button.new()
	hud_btn.name = "HudToggleButton"
	hud_btn.text = "Инвентарь [I]"
	hud_btn.position = Vector2(520.0, 8.0)
	hud_btn.size = Vector2(112.0, 22.0)
	hud_btn.focus_mode = Control.FOCUS_NONE
	hud_btn.add_theme_font_size_override("font_size", 10)
	root.add_child(hud_btn)
	
	# Корневой экран оверлея
	var overlay_root: Control = Control.new()
	overlay_root.name = "OverlayRoot"
	overlay_root.position = Vector2.ZERO
	overlay_root.size = Vector2(640.0, 360.0)
	overlay_root.visible = false
	overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay_root)
	
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(640.0, 360.0)
	backdrop.color = Color(0.02, 0.03, 0.06, 0.76)
	overlay_root.add_child(backdrop)
	
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.position = Vector2(14.0, 10.0)
	panel.size = Vector2(612.0, 340.0)
	var p_style: StyleBoxFlat = StyleBoxFlat.new()
	p_style.bg_color = Color(0.09, 0.11, 0.16, 0.98)
	p_style.border_color = Color(0.38, 0.46, 0.64, 1.0)
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(4)
	p_style.content_margin_left = 8.0
	p_style.content_margin_right = 8.0
	p_style.content_margin_top = 6.0
	p_style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", p_style)
	overlay_root.add_child(panel)
	
	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.add_theme_constant_override("separation", 4)
	panel.add_child(main_vbox)
	
	# Заголовок окна
	var header: HBoxContainer = HBoxContainer.new()
	header.name = "HeaderHBox"
	main_vbox.add_child(header)
	
	var title_lbl: Label = Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.text = "ИНВЕНТАРЬ И ЭКИПИРОВКА (ГГ)"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.modulate = Color(1.0, 0.88, 0.52, 1.0)
	header.add_child(title_lbl)
	
	var close_btn: Button = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "Закрыть [Esc]"
	close_btn.custom_minimum_size = Vector2(98.0, 20.0)
	close_btn.add_theme_font_size_override("font_size", 10)
	header.add_child(close_btn)
	
	var hsep_top: HSeparator = HSeparator.new()
	main_vbox.add_child(hsep_top)
	
	# Основная двухколоночная область
	var body_hbox: HBoxContainer = HBoxContainer.new()
	body_hbox.name = "BodyHBox"
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(body_hbox)
	
	# Левая колонка: 5 слотов + статы + синергия рук
	var left_col: VBoxContainer = VBoxContainer.new()
	left_col.name = "LeftEquipmentColumn"
	left_col.custom_minimum_size = Vector2(264.0, 0.0)
	left_col.add_theme_constant_override("separation", 4)
	body_hbox.add_child(left_col)
	
	var slots_title: Label = Label.new()
	slots_title.name = "SlotsHeaderLabel"
	slots_title.text = "Слоты (клик по занятому — снять):"
	slots_title.add_theme_font_size_override("font_size", 9)
	slots_title.modulate = Color(0.80, 0.86, 0.96, 1.0)
	left_col.add_child(slots_title)
	
	var slots_container: VBoxContainer = VBoxContainer.new()
	slots_container.name = "SlotsContainer"
	slots_container.add_theme_constant_override("separation", 2)
	left_col.add_child(slots_container)
	
	var sep_stats: HSeparator = HSeparator.new()
	left_col.add_child(sep_stats)
	
	var stats_lbl: Label = Label.new()
	stats_lbl.name = "StatsLabel"
	stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_lbl.add_theme_font_size_override("font_size", 9)
	stats_lbl.modulate = Color(0.86, 0.94, 1.0, 1.0)
	left_col.add_child(stats_lbl)
	
	var synergy_lbl: Label = Label.new()
	synergy_lbl.name = "SynergyLabel"
	synergy_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	synergy_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	synergy_lbl.add_theme_font_size_override("font_size", 9)
	synergy_lbl.modulate = Color(0.68, 0.96, 0.78, 1.0)
	left_col.add_child(synergy_lbl)
	
	var vsep: VSeparator = VSeparator.new()
	body_hbox.add_child(vsep)
	
	# Правая колонка: вкладки + скролл списка предметов
	var right_col: VBoxContainer = VBoxContainer.new()
	right_col.name = "RightInventoryColumn"
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 4)
	body_hbox.add_child(right_col)
	
	var tabs_hbox: HBoxContainer = HBoxContainer.new()
	tabs_hbox.name = "TabsHBox"
	tabs_hbox.add_theme_constant_override("separation", 4)
	right_col.add_child(tabs_hbox)
	
	var tab_eq_btn: Button = Button.new()
	tab_eq_btn.name = "TabEquipmentButton"
	tab_eq_btn.text = "Экипировка"
	tab_eq_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_eq_btn.custom_minimum_size = Vector2(0.0, 22.0)
	tab_eq_btn.add_theme_font_size_override("font_size", 10)
	tabs_hbox.add_child(tab_eq_btn)
	
	var tab_cons_btn: Button = Button.new()
	tab_cons_btn.name = "TabConsumablesButton"
	tab_cons_btn.text = "Расходники"
	tab_cons_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_cons_btn.custom_minimum_size = Vector2(0.0, 22.0)
	tab_cons_btn.add_theme_font_size_override("font_size", 10)
	tabs_hbox.add_child(tab_cons_btn)
	
	var item_scroll: ScrollContainer = ScrollContainer.new()
	item_scroll.name = "ItemListScroll"
	item_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_col.add_child(item_scroll)
	
	var item_list: VBoxContainer = VBoxContainer.new()
	item_list.name = "ItemListContainer"
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 4)
	item_scroll.add_child(item_list)
	
	var hsep_bottom: HSeparator = HSeparator.new()
	main_vbox.add_child(hsep_bottom)
	
	var feedback_lbl: Label = Label.new()
	feedback_lbl.name = "StatusFeedbackLabel"
	feedback_lbl.custom_minimum_size = Vector2(0.0, 16.0)
	feedback_lbl.add_theme_font_size_override("font_size", 9)
	feedback_lbl.modulate = Color(1.0, 0.88, 0.45, 1.0)
	main_vbox.add_child(feedback_lbl)
	
	return {
		"hud_toggle_button": hud_btn,
		"overlay_root": overlay_root,
		"close_button": close_btn,
		"slots_container": slots_container,
		"stats_label": stats_lbl,
		"synergy_label": synergy_lbl,
		"tab_equipment_button": tab_eq_btn,
		"tab_consumables_button": tab_cons_btn,
		"item_list_container": item_list,
		"feedback_label": feedback_lbl
	}
