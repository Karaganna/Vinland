# res://scripts/battle/battle_ui_builder.gd
class_name BattleUIBuilder
extends RefCounted

## Процедурный сборщик боевого UI для быстрого теста в Viewport 640x360
## Не зависит от BattleUIPresenter (возвращает Dictionary со ссылками на созданные узлы)

static func build_sandbox_ui(root: Control) -> Dictionary:
	if root == null:
		return {}
	
	root.position = Vector2.ZERO
	root.size = Vector2(640.0, 360.0)
	root.custom_minimum_size = Vector2(640.0, 360.0)
	
	# 1. Фон и верхняя боевая арена (y = 0..210)
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
	
	# Верхний баннер телеграфа
	var telegraph_banner: Label = Label.new()
	telegraph_banner.name = "TelegraphBanner"
	telegraph_banner.position = Vector2(16.0, 10.0)
	telegraph_banner.size = Vector2(608.0, 20.0)
	telegraph_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	telegraph_banner.add_theme_font_size_override("font_size", 11)
	telegraph_banner.modulate = Color(1.0, 0.45, 0.22, 1.0)
	telegraph_banner.visible = false
	root.add_child(telegraph_banner)
	
	# 2. Левая сторона: Главный герой + 4 шкалы ресурсов
	var player_name_lbl: Label = _create_label("PlayerNameLabel", Vector2(18.0, 32.0), Vector2(236.0, 18.0), "Герой", 12)
	root.add_child(player_name_lbl)
	
	var hero_tex_path: String = "res://assets/sprites/player/walk/right/sprite_0.png"
	if ResourceLoader.exists(hero_tex_path):
		var hero_spr: Sprite2D = Sprite2D.new()
		hero_spr.name = "HeroSprite"
		hero_spr.texture = load(hero_tex_path) as Texture2D
		hero_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hero_spr.scale = Vector2(1.5, 1.5)
		hero_spr.position = Vector2(54.0, 102.0)
		root.add_child(hero_spr)
	else:
		var hero_rect: ColorRect = ColorRect.new()
		hero_rect.name = "HeroPlaceholder"
		hero_rect.position = Vector2(34.0, 68.0)
		hero_rect.size = Vector2(44.0, 56.0)
		hero_rect.color = Color(0.25, 0.55, 0.90, 1.0)
		root.add_child(hero_rect)
	
	var player_hp_bar: ProgressBar = _create_bar("PlayerHPBar", Vector2(102.0, 54.0), Vector2(154.0, 13.0), Color(0.22, 0.78, 0.34, 1.0))
	root.add_child(player_hp_bar)
	var player_hp_lbl: Label = _create_label("PlayerHPLabel", Vector2(106.0, 52.0), Vector2(146.0, 15.0), "HP: 140/140", 9, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(player_hp_lbl)
	
	# Шкалы Энергии, Маны, Ярости и Напряжения
	var res_x: float = 102.0
	var res_w: float = 154.0
	var energy_row: Dictionary = _create_resource_row(root, "Energy", "ЭН", Vector2(res_x, 72.0), res_w, Color(0.95, 0.80, 0.20, 1.0))
	var mana_row: Dictionary = _create_resource_row(root, "Mana", "МН", Vector2(res_x, 90.0), res_w, Color(0.25, 0.60, 0.98, 1.0))
	var rage_row: Dictionary = _create_resource_row(root, "Rage", "ЯР", Vector2(res_x, 108.0), res_w, Color(0.92, 0.28, 0.22, 1.0))
	var tension_row: Dictionary = _create_resource_row(root, "Tension", "УЛ", Vector2(res_x, 126.0), res_w, Color(0.75, 0.38, 0.98, 1.0))
	
	var player_statuses_lbl: Label = _create_label("PlayerStatusesLabel", Vector2(18.0, 152.0), Vector2(242.0, 48.0), "", 10)
	player_statuses_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_statuses_lbl.modulate = Color(0.78, 0.90, 1.0, 1.0)
	root.add_child(player_statuses_lbl)
	
	# 3. Правая сторона: Противник + части тела
	var enemy_name_lbl: Label = _create_label("EnemyNameLabel", Vector2(364.0, 32.0), Vector2(258.0, 18.0), "Противник", 12, HORIZONTAL_ALIGNMENT_RIGHT)
	root.add_child(enemy_name_lbl)
	
	var enemy_visual: ColorRect = ColorRect.new()
	enemy_visual.name = "EnemyVisualRect"
	enemy_visual.position = Vector2(544.0, 74.0)
	enemy_visual.size = Vector2(68.0, 82.0)
	enemy_visual.color = Color(0.75, 0.20, 0.16, 1.0)
	root.add_child(enemy_visual)
	
	var enemy_hp_bar: ProgressBar = _create_bar("EnemyHPBar", Vector2(364.0, 54.0), Vector2(170.0, 13.0), Color(0.86, 0.24, 0.24, 1.0))
	root.add_child(enemy_hp_bar)
	var enemy_hp_lbl: Label = _create_label("EnemyHPLabel", Vector2(368.0, 52.0), Vector2(162.0, 15.0), "HP: 220/220", 9, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(enemy_hp_lbl)
	
	var enemy_parts_lbl: Label = _create_label("EnemyPartsLabel", Vector2(364.0, 72.0), Vector2(172.0, 86.0), "", 9)
	enemy_parts_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_parts_lbl.modulate = Color(0.95, 0.90, 0.72, 1.0)
	root.add_child(enemy_parts_lbl)
	
	var enemy_statuses_lbl: Label = _create_label("EnemyStatusesLabel", Vector2(364.0, 162.0), Vector2(258.0, 38.0), "", 10, HORIZONTAL_ALIGNMENT_RIGHT)
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
	
	# Левая колонка: 5 кнопок меню
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
	
	# Правая колонка: лог боя сверху + подменю / слот QTE снизу
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
		"player_name_label": player_name_lbl,
		"player_hp_bar": player_hp_bar,
		"player_hp_label": player_hp_lbl,
		"energy_bar": energy_row["bar"],
		"mana_bar": mana_row["bar"],
		"rage_bar": rage_row["bar"],
		"tension_bar": tension_row["bar"],
		"energy_value_label": energy_row["val_label"],
		"mana_value_label": mana_row["val_label"],
		"rage_value_label": rage_row["val_label"],
		"tension_value_label": tension_row["val_label"],
		"player_statuses_label": player_statuses_lbl,
		"enemy_name_label": enemy_name_lbl,
		"enemy_hp_bar": enemy_hp_bar,
		"enemy_hp_label": enemy_hp_lbl,
		"enemy_parts_label": enemy_parts_lbl,
		"enemy_statuses_label": enemy_statuses_lbl,
		"enemy_visual_rect": enemy_visual,
		"telegraph_banner_label": telegraph_banner,
		"combat_log_label": log_lbl
	}

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
	bg_st.bg_color = Color(0.14, 0.16, 0.22, 1.0)
	bg_st.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg_st)
	
	var fill_st: StyleBoxFlat = StyleBoxFlat.new()
	fill_st.bg_color = fill_color
	fill_st.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill_st)
	return bar

static func _create_resource_row(
	parent: Control,
	p_prefix: String,
	short_tag: String,
	pos: Vector2,
	total_w: float,
	fill_color: Color
) -> Dictionary:
	var tag_lbl: Label = _create_label(p_prefix + "Tag", pos + Vector2(0.0, -1.0), Vector2(22.0, 14.0), short_tag, 9)
	tag_lbl.modulate = Color(0.85, 0.88, 0.96, 1.0)
	parent.add_child(tag_lbl)
	
	var bar_w: float = total_w - 24.0
	var bar: ProgressBar = _create_bar(p_prefix + "Bar", pos + Vector2(24.0, 0.0), Vector2(bar_w, 12.0), fill_color)
	parent.add_child(bar)
	
	var val_lbl: Label = _create_label(p_prefix + "ValueLabel", pos + Vector2(24.0, -2.0), Vector2(bar_w, 14.0), "0/100", 8, HORIZONTAL_ALIGNMENT_CENTER)
	parent.add_child(val_lbl)
	
	return {"bar": bar, "val_label": val_lbl}

static func _create_menu_button(p_name: String, p_text: String) -> Button:
	var btn: Button = Button.new()
	btn.name = p_name
	btn.text = p_text
	btn.custom_minimum_size = Vector2(146.0, 22.0)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 10)
	return btn
