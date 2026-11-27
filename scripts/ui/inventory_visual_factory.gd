# res://scripts/ui/inventory_visual_factory.gd
class_name InventoryVisualFactory
extends RefCounted

## Процедурная 16-битная пиксельная фабрика рамок (9-slice StyleBoxTexture), иконок, портретов и кукол для InventoryMenuOverlay
## Поддерживает прозрачную замену на реальные PNG из Aseprite (через поля ресурсов или папку res://assets/ui/inventory/)

# =========================================================================
# 1. СКАНДИНАВСКАЯ 16-БИТНАЯ ПАЛИТРА
# =========================================================================
const COLOR_BACKDROP: Color = Color(0.03, 0.05, 0.09, 0.72)

const OAK_DARK: Color = Color("#3b271b")
const OAK_MID: Color = Color("#523726")
const OAK_HIGHLIGHT: Color = Color("#6b4933")
const OAK_SHADOW: Color = Color("#22150e")

const IRON_DARK: Color = Color("#46505e")
const IRON_MID: Color = Color("#6e7b8c")
const IRON_HIGHLIGHT: Color = Color("#9aa6b5")
const OUTLINE_DARK: Color = Color("#121721")

const SLATE_PANEL: Color = Color("#151c28")
const SLATE_HEADER: Color = Color("#111722")
const SLATE_NICHE: Color = Color("#0f1520")
const SLATE_SHADOW: Color = Color("#090d14")

const GOLD_MID: Color = Color("#d99a32")
const GOLD_BRIGHT: Color = Color("#f5c962")
const GOLD_BG: Color = Color("#6e4718")
const GOLD_NICHE: Color = Color("#2a1e10")

const BAR_HP: Color = Color("#c93640")
const BAR_ENERGY: Color = Color("#38c4d9")
const BAR_MANA: Color = Color("#4a78e0")
const BAR_RAGE: Color = Color("#d9582b")
const BAR_HAMINGJA: Color = Color("#e0b843")

const TEXT_PRIMARY: Color = Color("#eef2f7")
const TEXT_SECONDARY: Color = Color("#9aa6b8")
const TEXT_GOLD: Color = Color("#f5c962")
const TEXT_DISABLED: Color = Color("#5e6775")
const TEXT_DANGER: Color = Color("#e85d5d")
const TEXT_RUNE_CYAN: Color = Color("#52d9e8")

const EXTERNAL_UI_ROOT: String = "res://assets/ui/inventory"

static var _texture_cache: Dictionary = {}
static var _style_cache: Dictionary = {}

## Возвращает цвет шкалы ресурса по типу бака / режима Потока
static func get_resource_bar_color(res_type: BattleTypes.ResourceType) -> Color:
	match res_type:
		BattleTypes.ResourceType.MANA:
			return BAR_MANA
		BattleTypes.ResourceType.RAGE:
			return BAR_RAGE
		BattleTypes.ResourceType.HAMINGJA:
			return BAR_HAMINGJA
		_:
			return BAR_ENERGY

# =========================================================================
# 2. 9-SLICE STYLEBOX TEXTURES (ДЕРЕВО + КОВАНОЕ ЖЕЛЕЗО + ЗОЛОТО)
# =========================================================================

static func get_panel_wood_iron_style() -> StyleBoxTexture:
	return _get_or_build_style("panel_wood_iron", _build_panel_wood_iron_tex(), 8, 7, 7, 6, 6)

static func get_header_metal_style() -> StyleBoxTexture:
	return _get_or_build_style("header_metal", _build_header_metal_tex(), 6, 8, 8, 4, 4)

static func get_inspector_recessed_style() -> StyleBoxTexture:
	return _get_or_build_style("inspector_recessed", _build_inspector_recessed_tex(), 5, 6, 6, 5, 5)

static func get_slot_style(variant: String = "normal") -> StyleBoxTexture:
	var key: String = "slot_%s" % variant
	if _style_cache.has(key):
		return _style_cache[key] as StyleBoxTexture
	var tex: Texture2D = _build_slot_iron_tex(variant)
	return _get_or_build_style(key, tex, 5, 3, 3, 3, 3)

static func get_tab_style(is_active: bool, is_hover: bool = false) -> StyleBoxTexture:
	var variant: String = "active" if is_active else ("hover" if is_hover else "normal")
	var key: String = "tab_%s" % variant
	if _style_cache.has(key):
		return _style_cache[key] as StyleBoxTexture
	var tex: Texture2D = _build_tab_tex(variant)
	return _get_or_build_style(key, tex, 5, 3, 3, 3, 2)

static func get_card_style(highlighted: bool = false) -> StyleBoxTexture:
	var key: String = "card_gold" if highlighted else "card_slate"
	if _style_cache.has(key):
		return _style_cache[key] as StyleBoxTexture
	var tex: Texture2D = _build_slot_iron_tex("selected" if highlighted else "card")
	return _get_or_build_style(key, tex, 5, 5, 5, 4, 4)

static func get_button_style(variant: String = "normal") -> StyleBoxTexture:
	var key: String = "btn_%s" % variant
	if _style_cache.has(key):
		return _style_cache[key] as StyleBoxTexture
	var tex: Texture2D = _build_button_tex(variant)
	return _get_or_build_style(key, tex, 4, 4, 4, 2, 2)

static func get_bar_frame_style() -> StyleBoxTexture:
	return _get_or_build_style("bar_frame", _build_bar_frame_tex(), 3, 2, 2, 2, 2)

static func get_bar_fill_style(fill_color: Color) -> StyleBoxTexture:
	var key: String = "bar_fill_%s" % fill_color.to_html(false)
	if _style_cache.has(key):
		return _style_cache[key] as StyleBoxTexture
	var tex: Texture2D = _build_bar_fill_tex(fill_color)
	return _get_or_build_style(key, tex, 2, 0, 0, 0, 0)

## Применяет пиксельную кованую тему к кнопке действия
static func style_iron_button(btn: Button, gold_accent: bool = false) -> void:
	if btn == null:
		return
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_stylebox_override("normal", get_button_style("gold" if gold_accent else "normal"))
	btn.add_theme_stylebox_override("hover", get_button_style("gold_hover" if gold_accent else "hover"))
	btn.add_theme_stylebox_override("pressed", get_button_style("pressed"))
	btn.add_theme_stylebox_override("disabled", get_button_style("disabled"))
	btn.add_theme_stylebox_override("focus", get_button_style("hover"))
	btn.add_theme_color_override("font_color", TEXT_GOLD if gold_accent else TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", GOLD_BRIGHT)
	btn.add_theme_color_override("font_pressed_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_disabled_color", TEXT_DISABLED)

# =========================================================================
# 3. ПОРТРЕТЫ БОЙЦОВ (28x28) И РОСТОВЫЕ КУКЛЫ (48x64) С ПОДДЕРЖКОЙ PNG
# =========================================================================

static func get_fighter_portrait(member: CombatantData) -> Texture2D:
	if member != null and member.portrait_texture != null:
		return member.portrait_texture
	var cid: String = member.combatant_id.strip_edges() if member != null else "hero"
	var ext_tex: Texture2D = _try_load_external_png("%s/portraits/%s.png" % [EXTERNAL_UI_ROOT, cid])
	if ext_tex != null:
		return ext_tex
	var arch_key: String = _resolve_fighter_archetype_key(member)
	var cache_key: String = "portrait_%s" % arch_key
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var img: Image = _draw_portrait_image(arch_key)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func get_fighter_fullbody(member: CombatantData) -> Texture2D:
	if member != null and member.fullbody_texture != null:
		return member.fullbody_texture
	var cid: String = member.combatant_id.strip_edges() if member != null else "hero"
	var ext_tex: Texture2D = _try_load_external_png("%s/fullbody/%s.png" % [EXTERNAL_UI_ROOT, cid])
	if ext_tex != null:
		return ext_tex
	var arch_key: String = _resolve_fighter_archetype_key(member)
	var cache_key: String = "fullbody_%s" % arch_key
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var img: Image = _draw_fullbody_image(arch_key)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func get_pedestal_shadow_texture() -> Texture2D:
	var key: String = "pedestal_shadow"
	if _texture_cache.has(key):
		return _texture_cache[key] as Texture2D
	var img: Image = Image.create_empty(44, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y: int in range(10):
		for x: int in range(44):
			var dx: float = (float(x) - 21.5) / 20.0
			var dy: float = (float(y) - 4.5) / 4.2
			var d2: float = dx * dx + dy * dy
			if d2 <= 0.55:
				img.set_pixel(x, y, Color(0.02, 0.03, 0.06, 0.68))
			elif d2 <= 1.0:
				img.set_pixel(x, y, Color(0.04, 0.06, 0.10, 0.36))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[key] = tex
	return tex

# =========================================================================
# 4. ИКОНКИ ПРЕДМЕТОВ (24x24), СЛОТОВ (16x16), ВКЛАДОК (14x14) И СТАТОВ (12x12)
# =========================================================================

static func get_item_icon(item: ItemData) -> Texture2D:
	if item != null and item.icon_texture != null:
		return item.icon_texture
	if item != null and not item.item_id.strip_edges().is_empty():
		var ext_tex: Texture2D = _try_load_external_png("%s/items/%s.png" % [EXTERNAL_UI_ROOT, item.item_id.strip_edges()])
		if ext_tex != null:
			return ext_tex
	var icon_kind: String = _resolve_item_icon_kind(item)
	var cache_key: String = "item_icon_%s" % icon_kind
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var img: Image = _draw_item_icon_image(icon_kind)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func get_empty_slot_icon(slot_id: StringName) -> Texture2D:
	var kind: String = "hand_left"
	if slot_id == InventoryTypes.SLOT_RIGHT_HAND:
		kind = "hand_right"
	elif slot_id == InventoryTypes.SLOT_BODY:
		kind = "body"
	elif slot_id == InventoryTypes.SLOT_ACCESSORY_1 or slot_id == InventoryTypes.SLOT_ACCESSORY_2:
		kind = "accessory"
	var cache_key: String = "slot_ghost_%s" % kind
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var img: Image = _draw_slot_ghost_image(kind)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func get_tab_icon(tab_key: String) -> Texture2D:
	var ext_tex: Texture2D = _try_load_external_png("%s/icons/tab_%s.png" % [EXTERNAL_UI_ROOT, tab_key])
	if ext_tex != null:
		return ext_tex
	var cache_key: String = "tab_icon_%s" % tab_key
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var img: Image = _draw_tab_icon_image(tab_key)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func get_stat_icon(stat_key: String) -> Texture2D:
	var ext_tex: Texture2D = _try_load_external_png("%s/icons/stat_%s.png" % [EXTERNAL_UI_ROOT, stat_key])
	if ext_tex != null:
		return ext_tex
	var cache_key: String = "stat_icon_%s" % stat_key
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var img: Image = _draw_stat_icon_image(stat_key)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func get_resource_icon(res_type: BattleTypes.ResourceType) -> Texture2D:
	var r_name: String = "energy"
	match res_type:
		BattleTypes.ResourceType.MANA:
			r_name = "mana"
		BattleTypes.ResourceType.RAGE:
			r_name = "rage"
		BattleTypes.ResourceType.HAMINGJA:
			r_name = "hamingja"
	var cache_key: String = "res_icon_%s" % r_name
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var img: Image = _draw_resource_icon_image(r_name)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func get_crest_icon(has_god_blessing_or_patron: bool, has_hand_synergy: bool) -> Texture2D:
	var kind: String = "knot"
	if has_god_blessing_or_patron:
		kind = "god_horn"
	elif has_hand_synergy:
		kind = "synergy_blades"
	var cache_key: String = "crest_icon_%s" % kind
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var img: Image = _draw_crest_icon_image(kind)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func get_close_cross_icon() -> Texture2D:
	var cache_key: String = "close_cross_icon"
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var img: Image = Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i: int in range(2, 10):
		_px(img, i, i, GOLD_BRIGHT)
		_px(img, i + 1, i, GOLD_MID)
		_px(img, 11 - i, i, GOLD_BRIGHT)
		_px(img, 10 - i, i, GOLD_MID)
	_apply_outline(img, OUTLINE_DARK)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

# =========================================================================
# ВНУТРЕННИЕ ПОСТРОИТЕЛИ 9-SLICE РАМОК
# =========================================================================

static func _get_or_build_style(
	key: String,
	tex: Texture2D,
	margin: int,
	pad_l: int,
	pad_r: int,
	pad_t: int,
	pad_b: int
) -> StyleBoxTexture:
	if _style_cache.has(key):
		return _style_cache[key] as StyleBoxTexture
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = float(margin)
	sb.texture_margin_right = float(margin)
	sb.texture_margin_top = float(margin)
	sb.texture_margin_bottom = float(margin)
	sb.content_margin_left = float(pad_l)
	sb.content_margin_right = float(pad_r)
	sb.content_margin_top = float(pad_t)
	sb.content_margin_bottom = float(pad_b)
	_style_cache[key] = sb
	return sb

static func _build_panel_wood_iron_tex() -> Texture2D:
	if _texture_cache.has("tex_panel_wood_iron"):
		return _texture_cache["tex_panel_wood_iron"] as Texture2D
	var s: int = 32
	var img: Image = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	# Внутренний сланцевый фон
	_rect(img, 0, 0, s, s, SLATE_PANEL)
	# Внешний черный контур
	_border(img, 0, 0, s, s, OUTLINE_DARK)
	# Резная дубовая рама (толщина 4 px: 1..4)
	_border(img, 1, 1, s - 2, s - 2, OAK_MID)
	_border(img, 2, 2, s - 4, s - 4, OAK_DARK)
	_border(img, 3, 3, s - 6, s - 6, OAK_SHADOW)
	# Блик на верхней и левой грани дуба
	_hline(img, 2, s - 3, 1, OAK_HIGHLIGHT)
	_vline(img, 1, 2, s - 3, OAK_HIGHLIGHT)
	# Тонкая железная внутренняя окантовка и тень ниши
	_border(img, 4, 4, s - 8, s - 8, IRON_DARK)
	_hline(img, 5, s - 6, 5, SLATE_SHADOW)
	_vline(img, 5, 5, s - 6, SLATE_SHADOW)
	
	# Кованые металлические уголки L-формы (7x7 px) с заклепками в 4 углах
	_draw_iron_corner_bracket(img, 0, 0, false, false)
	_draw_iron_corner_bracket(img, s - 8, 0, true, false)
	_draw_iron_corner_bracket(img, 0, s - 8, false, true)
	_draw_iron_corner_bracket(img, s - 8, s - 8, true, true)
	
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache["tex_panel_wood_iron"] = tex
	return tex

static func _draw_iron_corner_bracket(img: Image, ox: int, oy: int, flip_x: bool, flip_y: bool) -> void:
	for dy: int in range(8):
		for dx: int in range(8):
			var lx: int = (7 - dx) if flip_x else dx
			var ly: int = (7 - dy) if flip_y else dy
			if lx < 4 or ly < 4:
				var col: Color = IRON_DARK
				if lx == 0 or ly == 0:
					col = OUTLINE_DARK
				elif lx == 1 or ly == 1:
					col = IRON_HIGHLIGHT if (not flip_y and ly == 1) or (not flip_x and lx == 1) else IRON_MID
				elif lx == 3 or ly == 3:
					col = OUTLINE_DARK
				else:
					col = IRON_MID
				img.set_pixel(ox + dx, oy + dy, col)
	# Яркая клепка в углу уголка
	var rx: int = ox + (5 if flip_x else 2)
	var ry: int = oy + (5 if flip_y else 2)
	img.set_pixel(rx, ry, IRON_HIGHLIGHT)

static func _build_header_metal_tex() -> Texture2D:
	if _texture_cache.has("tex_header_metal"):
		return _texture_cache["tex_header_metal"] as Texture2D
	var s: int = 24
	var img: Image = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	_rect(img, 0, 0, s, s, SLATE_HEADER)
	_border(img, 0, 0, s, s, OUTLINE_DARK)
	_border(img, 1, 1, s - 2, s - 2, IRON_MID)
	_hline(img, 2, s - 3, 1, IRON_HIGHLIGHT)
	_hline(img, 2, s - 3, s - 2, IRON_DARK)
	_border(img, 2, 2, s - 4, s - 4, OAK_DARK)
	_border(img, 3, 3, s - 6, s - 6, OUTLINE_DARK)
	# Заклепки в углах шапки
	for pt: Vector2i in [Vector2i(2, 2), Vector2i(s - 3, 2), Vector2i(2, s - 3), Vector2i(s - 3, s - 3)]:
		img.set_pixel(pt.x, pt.y, IRON_HIGHLIGHT)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache["tex_header_metal"] = tex
	return tex

static func _build_inspector_recessed_tex() -> Texture2D:
	if _texture_cache.has("tex_inspector_recessed"):
		return _texture_cache["tex_inspector_recessed"] as Texture2D
	var s: int = 20
	var img: Image = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	_rect(img, 0, 0, s, s, SLATE_NICHE)
	_border(img, 0, 0, s, s, OUTLINE_DARK)
	_border(img, 1, 1, s - 2, s - 2, IRON_DARK)
	_hline(img, 2, s - 3, 2, SLATE_SHADOW)
	_vline(img, 2, 2, s - 3, SLATE_SHADOW)
	_hline(img, 2, s - 3, s - 2, IRON_MID)
	for pt: Vector2i in [Vector2i(2, 2), Vector2i(s - 3, 2), Vector2i(2, s - 3), Vector2i(s - 3, s - 3)]:
		img.set_pixel(pt.x, pt.y, GOLD_MID)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache["tex_inspector_recessed"] = tex
	return tex

static func _build_slot_iron_tex(variant: String) -> Texture2D:
	var cache_key: String = "tex_slot_%s" % variant
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var s: int = 20
	var img: Image = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	
	var bg: Color = SLATE_NICHE
	var rim_top: Color = IRON_MID
	var rim_bot: Color = IRON_DARK
	var rivet: Color = IRON_HIGHLIGHT
	
	if variant == "selected":
		bg = GOLD_NICHE
		rim_top = GOLD_BRIGHT
		rim_bot = GOLD_MID
		rivet = GOLD_BRIGHT
	elif variant == "hover":
		bg = Color("#182234")
		rim_top = IRON_HIGHLIGHT
		rim_bot = IRON_MID
		rivet = GOLD_BRIGHT
	elif variant == "disabled" or variant == "locked":
		bg = Color("#0b1018")
		rim_top = Color("#343c47")
		rim_bot = Color("#252b34")
		rivet = Color("#46505e")
	elif variant == "card":
		bg = Color("#121926")
		rim_top = IRON_DARK
		rim_bot = Color("#2c3440")
		rivet = IRON_MID
	
	_rect(img, 0, 0, s, s, bg)
	_border(img, 0, 0, s, s, OUTLINE_DARK)
	_border(img, 1, 1, s - 2, s - 2, rim_bot)
	_hline(img, 1, s - 2, 1, rim_top)
	_vline(img, 1, 1, s - 2, rim_top)
	_border(img, 2, 2, s - 4, s - 4, SLATE_SHADOW if variant != "selected" else GOLD_BG)
	
	# Угловые заклепки
	for pt: Vector2i in [Vector2i(2, 2), Vector2i(s - 3, 2), Vector2i(2, s - 3), Vector2i(s - 3, s - 3)]:
		img.set_pixel(pt.x, pt.y, rivet)
	
	# Для заблокированной второй руки однорукого бойца — аккуратная диагональная железная стяжка
	if variant == "locked":
		for i: int in range(4, s - 4):
			img.set_pixel(i, i, Color("#3a4352"))
			img.set_pixel(s - 1 - i, i, Color("#3a4352"))
	
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func _build_tab_tex(variant: String) -> Texture2D:
	var cache_key: String = "tex_tab_%s" % variant
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var s: int = 20
	var img: Image = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	if variant == "active":
		_rect(img, 0, 0, s, s, GOLD_BG)
		_rect(img, 2, 3, s - 4, s - 5, Color("#3a2711"))
		_border(img, 0, 0, s, s, OUTLINE_DARK)
		_border(img, 1, 1, s - 2, s - 2, GOLD_MID)
		_hline(img, 1, s - 2, 1, GOLD_BRIGHT)
		_hline(img, 2, s - 3, 2, GOLD_BRIGHT)
	elif variant == "hover":
		_rect(img, 0, 0, s, s, Color("#1c2638"))
		_border(img, 0, 0, s, s, OUTLINE_DARK)
		_border(img, 1, 1, s - 2, s - 2, IRON_HIGHLIGHT)
	else:
		_rect(img, 0, 0, s, s, SLATE_NICHE)
		_border(img, 0, 0, s, s, OUTLINE_DARK)
		_border(img, 1, 1, s - 2, s - 2, IRON_DARK)
		_hline(img, 2, s - 3, 1, IRON_MID)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func _build_button_tex(variant: String) -> Texture2D:
	var cache_key: String = "tex_btn_%s" % variant
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D
	var s: int = 16
	var img: Image = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	var bg: Color = Color("#1a2230")
	var top_c: Color = IRON_MID
	var bot_c: Color = IRON_DARK
	if variant == "gold":
		bg = GOLD_BG
		top_c = GOLD_BRIGHT
		bot_c = GOLD_MID
	elif variant == "gold_hover":
		bg = Color("#87581e")
		top_c = GOLD_BRIGHT
		bot_c = GOLD_BRIGHT
	elif variant == "hover":
		bg = Color("#243044")
		top_c = IRON_HIGHLIGHT
		bot_c = IRON_MID
	elif variant == "pressed":
		bg = SLATE_NICHE
		top_c = IRON_DARK
		bot_c = IRON_MID
	elif variant == "disabled":
		bg = Color("#0e131c")
		top_c = Color("#2f3640")
		bot_c = Color("#232932")
	_rect(img, 0, 0, s, s, bg)
	_border(img, 0, 0, s, s, OUTLINE_DARK)
	_border(img, 1, 1, s - 2, s - 2, bot_c)
	_hline(img, 1, s - 2, 1, top_c)
	_vline(img, 1, 1, s - 2, top_c)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

static func _build_bar_frame_tex() -> Texture2D:
	if _texture_cache.has("tex_bar_frame"):
		return _texture_cache["tex_bar_frame"] as Texture2D
	var img: Image = Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	_rect(img, 0, 0, 12, 12, SLATE_SHADOW)
	_border(img, 0, 0, 12, 12, OUTLINE_DARK)
	_border(img, 1, 1, 10, 10, IRON_DARK)
	_hline(img, 2, 9, 10, IRON_MID)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_cache["tex_bar_frame"] = tex
	return tex

static func _build_bar_fill_tex(col: Color) -> Texture2D:
	var img: Image = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	var hi: Color = col.lightened(0.26)
	var lo: Color = col.darkened(0.28)
	_rect(img, 0, 0, 8, 8, col)
	_hline(img, 0, 7, 0, hi)
	_hline(img, 0, 7, 1, hi)
	_hline(img, 0, 7, 6, lo)
	_hline(img, 0, 7, 7, lo)
	return ImageTexture.create_from_image(img)

# =========================================================================
# ГЕНЕРАЦИЯ ПИКСЕЛЬНЫХ ПОРТРЕТОВ (28x28) И КУКОЛ В ПОЛНЫЙ РОСТ (48x64)
# =========================================================================

static func _resolve_fighter_archetype_key(member: CombatantData) -> String:
	if member == null or member.is_hero:
		return "hero"
	var cid: String = member.combatant_id.to_lower()
	if cid.contains("holmganger") or (member.equipment_loadout != null and member.equipment_loadout.available_hands == 1):
		return "holmganger"
	if cid.contains("sniper") or member.weapon_category == InventoryTypes.WeaponCategory.RANGED:
		return "sniper"
	if cid.contains("galdr") or member.weapon_category == InventoryTypes.WeaponCategory.RELICS or not member.is_viking:
		return "galdr"
	if cid.contains("berserk") or member.primary_resource == BattleTypes.ResourceType.RAGE:
		return "berserker"
	if cid.contains("shield") or member.can_wear_heavy:
		return "shieldbearer"
	return "holmganger"

static func _draw_portrait_image(arch: String) -> Image:
	var img: Image = Image.create_empty(28, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var skin: Color = Color("#e0b18c")
	var skin_sh: Color = Color("#b88462")
	var eye_c: Color = Color("#243447")
	
	# Плечи и плащ (y = 20..26)
	var cloak_c: Color = Color("#2b4f78")
	var trim_c: Color = Color("#8c7355")
	if arch == "holmganger":
		cloak_c = Color("#6e4c1e")
		trim_c = GOLD_MID
	elif arch == "sniper":
		cloak_c = Color("#1e5954")
		trim_c = Color("#6b4933")
	elif arch == "galdr":
		cloak_c = Color("#2f3f7a")
		trim_c = GOLD_BRIGHT
	elif arch == "berserker":
		cloak_c = Color("#6e261e")
		trim_c = Color("#523726")
	elif arch == "shieldbearer":
		cloak_c = Color("#2a4563")
		trim_c = IRON_MID
	
	_rect(img, 5, 20, 18, 7, cloak_c)
	_rect(img, 7, 19, 14, 3, trim_c)
	
	# Голова / лицо (x = 9..18, y = 8..18)
	_rect(img, 9, 8, 10, 11, skin)
	_vline(img, 9, 9, 18, skin_sh)
	_vline(img, 18, 9, 18, skin_sh)
	# Глаза
	_px(img, 11, 13, eye_c)
	_px(img, 16, 13, eye_c)
	
	if arch == "hero":
		# Шлем вождя с наносником и крылатыми накладками + рыже-русая борода
		var beard_c: Color = Color("#9c5a2b")
		_rect(img, 9, 15, 10, 5, beard_c)
		_rect(img, 11, 19, 6, 3, beard_c.darkened(0.18))
		_rect(img, 8, 5, 12, 6, IRON_MID)
		_hline(img, 9, 18, 5, IRON_HIGHLIGHT)
		_hline(img, 8, 19, 10, GOLD_MID)
		_vline(img, 13, 10, 14, IRON_HIGHLIGHT)
		_vline(img, 14, 10, 14, IRON_DARK)
	elif arch == "holmganger":
		# Светловолосый дуэлянт с повязкой и шрамом
		var hair_c: Color = Color("#d9b45b")
		_rect(img, 8, 6, 12, 4, hair_c)
		_vline(img, 8, 8, 15, hair_c)
		_rect(img, 8, 9, 12, 2, Color("#8c2d2d"))
		_px(img, 16, 12, Color("#a84848"))
		_px(img, 16, 14, Color("#a84848"))
		_hline(img, 12, 15, 16, skin_sh)
	elif arch == "sniper":
		# Охотничий глубокий капюшон Скади и светлая прядь
		var hood_c: Color = Color("#1c4d48")
		_rect(img, 7, 5, 14, 6, hood_c)
		_vline(img, 7, 7, 20, hood_c)
		_vline(img, 8, 8, 19, hood_c.darkened(0.2))
		_vline(img, 20, 7, 20, hood_c)
		_vline(img, 19, 8, 19, hood_c.darkened(0.2))
		_px(img, 11, 13, BAR_ENERGY)
		_px(img, 16, 13, BAR_ENERGY)
		_vline(img, 9, 11, 18, Color("#e6c97a"))
	elif arch == "galdr":
		# Светловолосая провидица гальдра с золотым обручем и бирюзовым камнем
		var s_hair: Color = Color("#f0dfa8")
		_rect(img, 8, 5, 12, 5, s_hair)
		_vline(img, 7, 8, 22, s_hair)
		_vline(img, 8, 9, 22, s_hair.darkened(0.12))
		_vline(img, 19, 9, 22, s_hair.darkened(0.12))
		_vline(img, 20, 8, 22, s_hair)
		_hline(img, 9, 18, 9, GOLD_MID)
		_px(img, 13, 9, BAR_ENERGY)
		_px(img, 14, 9, BAR_ENERGY)
	elif arch == "berserker":
		# Медвежья шкура-капюшон и огненная борода берсерка
		var pelt_c: Color = Color("#4f3524")
		_rect(img, 7, 4, 14, 7, pelt_c)
		_vline(img, 7, 7, 19, pelt_c)
		_vline(img, 20, 7, 19, pelt_c)
		_px(img, 10, 9, TEXT_PRIMARY)
		_px(img, 17, 9, TEXT_PRIMARY)
		_rect(img, 9, 15, 10, 6, Color("#b84321"))
		_px(img, 11, 12, BAR_RAGE)
		_px(img, 16, 12, BAR_RAGE)
	else:
		# Хирдман в закрытом полушлеме с бармицей
		_rect(img, 8, 5, 12, 6, IRON_MID)
		_hline(img, 9, 18, 5, IRON_HIGHLIGHT)
		_vline(img, 13, 9, 15, IRON_HIGHLIGHT)
		_rect(img, 8, 11, 2, 9, IRON_DARK)
		_rect(img, 18, 11, 2, 9, IRON_DARK)
		_rect(img, 10, 15, 8, 5, Color("#6b4933"))
	
	_apply_outline(img, OUTLINE_DARK)
	return img

static func _draw_fullbody_image(arch: String) -> Image:
	var img: Image = Image.create_empty(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var skin: Color = Color("#e0b18c")
	var boot_c: Color = OAK_DARK
	var pants_c: Color = Color("#283242")
	var tunic_c: Color = Color("#264c73")
	var cloak_c: Color = Color("#1c334d")
	var belt_c: Color = OAK_MID
	
	if arch == "holmganger":
		tunic_c = Color("#6e4c1e")
		cloak_c = Color("#452f14")
	elif arch == "sniper":
		tunic_c = Color("#1e5954")
		cloak_c = Color("#143b38")
	elif arch == "galdr":
		tunic_c = Color("#2f3f7a")
		cloak_c = Color("#1f2952")
	elif arch == "berserker":
		tunic_c = Color("#6e261e")
		cloak_c = Color("#4a2c1d")
	elif arch == "shieldbearer":
		tunic_c = IRON_DARK
		cloak_c = Color("#592222")
	
	# Плащ за спиной
	_rect(img, 14, 19, 20, 32, cloak_c)
	
	# Сапоги и ноги (y = 44..59)
	_rect(img, 18, 44, 5, 9, pants_c)
	_rect(img, 25, 44, 5, 9, pants_c)
	_rect(img, 17, 52, 6, 7, boot_c)
	_rect(img, 25, 52, 6, 7, boot_c)
	_hline(img, 17, 22, 52, OAK_HIGHLIGHT)
	_hline(img, 25, 30, 52, OAK_HIGHLIGHT)
	
	# Торс / туника / кольчуга (y = 20..44)
	if arch == "galdr":
		# Длинное скандинавское одеяние сейдконы с золотой вышивкой
		_rect(img, 16, 20, 16, 33, tunic_c)
		_vline(img, 23, 21, 52, GOLD_MID)
		_vline(img, 24, 21, 52, GOLD_MID)
		_hline(img, 16, 31, 51, GOLD_BRIGHT)
	else:
		_rect(img, 16, 20, 16, 25, tunic_c)
		if arch == "hero" or arch == "shieldbearer":
			# Кольчужный нагрудник
			_rect(img, 18, 22, 12, 14, IRON_MID)
			for cy: int in range(23, 35, 2):
				for cx: int in range(19, 29, 2):
					_px(img, cx, cy, IRON_DARK)
		elif arch == "berserker":
			# Перевязь через мощный торс берсерка
			_rect(img, 17, 21, 14, 14, skin.darkened(0.06))
			_line(img, 17, 21, 30, 34, OAK_DARK)
			_line(img, 18, 21, 30, 33, OAK_MID)
	
	# Меховое оплечье и пояс с пряжкой
	_rect(img, 14, 19, 20, 4, OAK_HIGHLIGHT if arch != "shieldbearer" else IRON_HIGHLIGHT)
	_rect(img, 16, 36, 16, 3, belt_c)
	_rect(img, 22, 36, 4, 3, GOLD_BRIGHT)
	
	# Руки: левая рука всегда есть, у однорукого Хольмгангера правый рукав заколот фибулой!
	_rect(img, 12, 22, 4, 15, tunic_c.lightened(0.08))
	_rect(img, 12, 36, 4, 4, skin)
	if arch == "holmganger":
		_rect(img, 32, 22, 4, 8, cloak_c.lightened(0.12))
		_rect(img, 32, 28, 3, 2, GOLD_BRIGHT)
	else:
		_rect(img, 32, 22, 4, 15, tunic_c.lightened(0.08))
		_rect(img, 32, 36, 4, 4, skin)
	
	# Голова (y = 7..19)
	_rect(img, 19, 8, 10, 11, skin)
	_px(img, 21, 13, OUTLINE_DARK)
	_px(img, 26, 13, OUTLINE_DARK)
	
	if arch == "hero":
		_rect(img, 19, 15, 10, 5, Color("#9c5a2b"))
		_rect(img, 18, 5, 12, 6, IRON_MID)
		_hline(img, 19, 28, 5, IRON_HIGHLIGHT)
		_hline(img, 18, 29, 10, GOLD_MID)
		_vline(img, 23, 10, 14, IRON_HIGHLIGHT)
	elif arch == "holmganger":
		_rect(img, 18, 6, 12, 4, Color("#d9b45b"))
		_rect(img, 18, 9, 12, 2, Color("#8c2d2d"))
	elif arch == "sniper":
		_rect(img, 17, 5, 14, 6, Color("#1c4d48"))
		_vline(img, 17, 8, 19, Color("#1c4d48"))
		_vline(img, 30, 8, 19, Color("#1c4d48"))
		# Лук/колчан за плечом
		_line(img, 31, 12, 35, 18, OAK_HIGHLIGHT)
	elif arch == "galdr":
		_rect(img, 18, 5, 12, 5, Color("#f0dfa8"))
		_vline(img, 17, 9, 25, Color("#f0dfa8"))
		_vline(img, 30, 9, 25, Color("#f0dfa8"))
		_hline(img, 19, 28, 9, GOLD_BRIGHT)
		_px(img, 23, 9, BAR_ENERGY)
	elif arch == "berserker":
		_rect(img, 17, 4, 14, 7, Color("#4f3524"))
		_rect(img, 19, 15, 10, 6, Color("#b84321"))
	else:
		_rect(img, 18, 5, 12, 6, IRON_MID)
		_hline(img, 19, 28, 5, IRON_HIGHLIGHT)
		_vline(img, 23, 9, 15, IRON_HIGHLIGHT)
		_rect(img, 20, 15, 8, 4, Color("#6b4933"))
	
	_apply_outline(img, OUTLINE_DARK)
	return img

# =========================================================================
# ГЕНЕРАЦИЯ ПИКСЕЛЬНЫХ ИКОНОК ПРЕДМЕТОВ (24x24)
# =========================================================================

static func _resolve_item_icon_kind(item: ItemData) -> String:
	if item == null:
		return "bag"
	var id_lc: String = item.item_id.to_lower()
	if item is ConsumableItemData:
		var cons: ConsumableItemData = item as ConsumableItemData
		if cons.is_rune_reset_item or id_lc.contains("ash"):
			return "ritual_ash"
		if cons.heal_hp > 0:
			return "potion_hp"
		if cons.restore_resource_amount > 0:
			return "potion_mana"
		return "herb_clarity"
	
	if item is EquipmentItemData:
		var eq: EquipmentItemData = item as EquipmentItemData
		if id_lc.contains("dragonblood"):
			return "dragonblood_greatsword"
		if eq.is_set_bundle:
			return "twin_blades_set"
		if eq.slot_type == InventoryTypes.EquipmentSlotType.BODY:
			return "armor_heavy" if eq.is_heavy else "armor_mail"
		if eq.slot_type == InventoryTypes.EquipmentSlotType.ACCESSORY:
			return "ring_gold" if id_lc.contains("ring") else "amulet_rune"
		if eq.is_shield_item():
			return "shield_heavy" if eq.slot_type == InventoryTypes.EquipmentSlotType.SHIELD_HEAVY else "shield_round"
		
		match eq.weapon_type:
			InventoryTypes.WeaponType.SPEAR, InventoryTypes.WeaponType.BOAR_SPEAR, InventoryTypes.WeaponType.HARPOON:
				return "spear"
			InventoryTypes.WeaponType.ATGEIR, InventoryTypes.WeaponType.GAFF_HOOK:
				return "atgeir"
			InventoryTypes.WeaponType.HOLMSVERD:
				return "holmsverd_leg" if eq.is_legendary else "holmsverd"
			InventoryTypes.WeaponType.SWORD, InventoryTypes.WeaponType.BROAD_BLADE, InventoryTypes.WeaponType.CURVED_BLADE:
				return "sword"
			InventoryTypes.WeaponType.LANGSAX, InventoryTypes.WeaponType.SEAX, InventoryTypes.WeaponType.DAGGER, InventoryTypes.WeaponType.WIDE_KNIFE, InventoryTypes.WeaponType.THROWING_KNIFE, InventoryTypes.WeaponType.SICKLE:
				return "seax"
			InventoryTypes.WeaponType.GREATSWORD:
				return "greatsword"
			InventoryTypes.WeaponType.BOW, InventoryTypes.WeaponType.SHORT_BOW:
				return "bow"
			InventoryTypes.WeaponType.LONG_BOW:
				return "longbow_leg" if eq.is_legendary else "bow"
			InventoryTypes.WeaponType.CROSSBOW:
				return "crossbow"
			InventoryTypes.WeaponType.SLING:
				return "sling"
			InventoryTypes.WeaponType.BEARDED_AXE:
				return "axe_1h"
			InventoryTypes.WeaponType.DANE_AXE:
				return "dane_axe"
			InventoryTypes.WeaponType.FLAIL, InventoryTypes.WeaponType.WAR_FLAIL, InventoryTypes.WeaponType.MORNINGSTAR:
				return "flail"
			InventoryTypes.WeaponType.ONE_HAND_HAMMER, InventoryTypes.WeaponType.WARHAMMER, InventoryTypes.WeaponType.CLUB, InventoryTypes.WeaponType.TWO_HAND_CLUB:
				return "hammer"
			InventoryTypes.WeaponType.SONG_TABLET:
				return "relic_tablet"
			InventoryTypes.WeaponType.VOLVA_STAFF:
				return "relic_staff"
			_:
				if eq.get_effective_weapon_category() == InventoryTypes.WeaponCategory.RELICS:
					return "relic_charm"
				return "sword"
	return "bag"

static func _draw_item_icon_image(kind: String) -> Image:
	var img: Image = Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	match kind:
		"spear":
			_line(img, 4, 19, 16, 7, OAK_HIGHLIGHT)
			_line(img, 5, 19, 16, 8, OAK_MID)
			_line(img, 16, 7, 20, 3, IRON_HIGHLIGHT)
			_line(img, 15, 7, 19, 3, IRON_MID)
			_px(img, 15, 9, BAR_HP)
			_px(img, 14, 10, BAR_HP)
		"atgeir":
			_line(img, 4, 20, 17, 7, OAK_HIGHLIGHT)
			_line(img, 16, 7, 20, 3, IRON_HIGHLIGHT)
			_rect(img, 14, 5, 4, 4, IRON_MID)
			_line(img, 13, 6, 17, 4, IRON_HIGHLIGHT)
		"dragonblood_greatsword":
			# Двуручный меч из крови дракона с багровым свечением
			_line(img, 5, 19, 8, 16, OAK_MID)
			_px(img, 4, 20, GOLD_BRIGHT)
			_line(img, 6, 13, 11, 18, GOLD_MID)
			_line(img, 9, 15, 19, 5, Color("#e04848"))
			_line(img, 8, 14, 18, 4, IRON_HIGHLIGHT)
			_line(img, 10, 15, 19, 6, BAR_RAGE)
			_px(img, 20, 4, GOLD_BRIGHT)
		"greatsword":
			_line(img, 4, 20, 8, 16, OAK_MID)
			_line(img, 6, 13, 11, 18, GOLD_MID)
			_line(img, 8, 14, 19, 3, IRON_HIGHLIGHT)
			_line(img, 9, 15, 20, 4, IRON_MID)
		"holmsverd", "holmsverd_leg":
			var guard_c: Color = GOLD_BRIGHT if kind == "holmsverd_leg" else IRON_MID
			var blade_c: Color = Color("#fff2b2") if kind == "holmsverd_leg" else IRON_HIGHLIGHT
			_line(img, 5, 19, 8, 16, OAK_MID)
			_line(img, 6, 14, 10, 18, guard_c)
			_px(img, 6, 16, guard_c)
			_line(img, 8, 15, 19, 4, blade_c)
			_line(img, 9, 15, 19, 5, IRON_MID)
		"sword":
			_line(img, 5, 19, 7, 17, OAK_MID)
			_px(img, 4, 20, IRON_HIGHLIGHT)
			_line(img, 6, 14, 10, 18, IRON_HIGHLIGHT)
			_line(img, 8, 15, 18, 5, IRON_HIGHLIGHT)
			_line(img, 9, 15, 19, 5, IRON_MID)
		"seax":
			_line(img, 5, 19, 8, 16, OAK_HIGHLIGHT)
			_line(img, 8, 15, 18, 5, IRON_HIGHLIGHT)
			_line(img, 9, 16, 17, 8, IRON_DARK)
		"twin_blades_set":
			_line(img, 5, 18, 18, 5, IRON_HIGHLIGHT)
			_line(img, 6, 19, 18, 7, Color("#4bc978"))
			_line(img, 5, 6, 18, 19, IRON_HIGHLIGHT)
			_px(img, 5, 19, GOLD_MID)
			_px(img, 18, 19, GOLD_MID)
		"bow", "longbow_leg":
			var bow_c: Color = GOLD_BRIGHT if kind == "longbow_leg" else OAK_HIGHLIGHT
			var str_c: Color = BAR_ENERGY if kind == "longbow_leg" else IRON_MID
			_line(img, 7, 4, 15, 7, bow_c)
			_line(img, 15, 7, 17, 15, bow_c)
			_line(img, 17, 15, 13, 19, bow_c)
			_line(img, 7, 4, 13, 19, str_c)
			_line(img, 6, 17, 18, 5, IRON_HIGHLIGHT)
		"crossbow":
			_line(img, 5, 18, 16, 7, OAK_MID)
			_line(img, 8, 6, 18, 16, IRON_HIGHLIGHT)
			_line(img, 8, 7, 17, 16, IRON_MID)
			_line(img, 10, 13, 18, 5, GOLD_BRIGHT)
		"sling":
			_line(img, 6, 18, 12, 8, OAK_HIGHLIGHT)
			_line(img, 17, 17, 13, 8, OAK_MID)
			_rect(img, 10, 6, 5, 4, OAK_DARK)
			_rect(img, 11, 5, 3, 3, IRON_HIGHLIGHT)
		"axe_1h":
			_line(img, 5, 19, 16, 8, OAK_HIGHLIGHT)
			_rect(img, 13, 5, 6, 6, IRON_MID)
			_vline(img, 18, 5, 12, IRON_HIGHLIGHT)
			_px(img, 17, 12, IRON_HIGHLIGHT)
		"dane_axe":
			_line(img, 4, 20, 17, 7, OAK_HIGHLIGHT)
			_rect(img, 12, 4, 8, 8, IRON_MID)
			_vline(img, 19, 4, 13, IRON_HIGHLIGHT)
			_hline(img, 13, 19, 4, IRON_HIGHLIGHT)
		"flail":
			_line(img, 5, 19, 12, 12, OAK_HIGHLIGHT)
			_px(img, 13, 10, IRON_HIGHLIGHT)
			_px(img, 15, 9, IRON_MID)
			_rect(img, 15, 11, 5, 5, IRON_MID)
			_px(img, 17, 10, IRON_HIGHLIGHT)
			_px(img, 20, 13, IRON_HIGHLIGHT)
			_px(img, 17, 16, IRON_HIGHLIGHT)
		"hammer":
			_line(img, 5, 19, 15, 9, OAK_HIGHLIGHT)
			_rect(img, 12, 5, 7, 5, IRON_MID)
			_hline(img, 12, 18, 5, IRON_HIGHLIGHT)
		"relic_tablet":
			_rect(img, 6, 4, 12, 16, OAK_MID)
			_border(img, 6, 4, 12, 16, GOLD_MID)
			_vline(img, 11, 7, 16, BAR_ENERGY)
			_line(img, 11, 8, 14, 10, BAR_ENERGY)
			_line(img, 11, 12, 14, 14, BAR_ENERGY)
		"relic_staff":
			_line(img, 5, 19, 17, 7, OAK_HIGHLIGHT)
			_rect(img, 15, 4, 5, 5, BAR_MANA)
			_px(img, 17, 5, TEXT_PRIMARY)
		"relic_charm":
			_border(img, 8, 4, 8, 6, OAK_HIGHLIGHT)
			_rect(img, 7, 9, 10, 10, Color("#ded2b8"))
			_rect(img, 10, 12, 4, 4, BAR_ENERGY)
		"shield_round":
			for y: int in range(5, 19):
				for x: int in range(5, 19):
					var dx: float = float(x) - 11.5
					var dy: float = float(y) - 11.5
					var d2: float = dx * dx + dy * dy
					if d2 <= 42.0:
						var c: Color = OAK_MID if ((x + y) % 4 != 0) else OAK_DARK
						if d2 >= 30.0:
							c = IRON_MID
						img.set_pixel(x, y, c)
			_rect(img, 10, 10, 4, 4, IRON_HIGHLIGHT)
		"shield_heavy":
			_rect(img, 6, 4, 12, 12, IRON_DARK)
			_rect(img, 7, 16, 10, 2, IRON_DARK)
			_rect(img, 9, 18, 6, 2, IRON_DARK)
			_border(img, 6, 4, 12, 12, IRON_HIGHLIGHT)
			_vline(img, 11, 5, 18, GOLD_MID)
			_hline(img, 7, 16, 10, GOLD_MID)
			_rect(img, 10, 9, 4, 4, GOLD_BRIGHT)
		"armor_mail":
			_rect(img, 6, 6, 12, 13, IRON_MID)
			_rect(img, 4, 6, 3, 6, IRON_DARK)
			_rect(img, 17, 6, 3, 6, IRON_DARK)
			_rect(img, 9, 6, 6, 2, OAK_MID)
			for y: int in range(9, 18, 2):
				for x: int in range(7, 17, 2):
					_px(img, x, y, IRON_DARK)
			_hline(img, 6, 17, 14, OAK_DARK)
		"armor_heavy":
			_rect(img, 5, 5, 14, 14, IRON_DARK)
			_rect(img, 3, 5, 4, 6, IRON_HIGHLIGHT)
			_rect(img, 17, 5, 4, 6, IRON_HIGHLIGHT)
			_hline(img, 6, 17, 9, GOLD_MID)
			_hline(img, 6, 17, 13, IRON_HIGHLIGHT)
			_rect(img, 10, 13, 4, 3, GOLD_BRIGHT)
		"amulet_rune":
			_line(img, 8, 4, 11, 9, OAK_HIGHLIGHT)
			_line(img, 15, 4, 12, 9, OAK_HIGHLIGHT)
			_rect(img, 8, 9, 8, 9, IRON_MID)
			_border(img, 8, 9, 8, 9, GOLD_BRIGHT)
			_vline(img, 11, 11, 15, BAR_ENERGY)
			_px(img, 12, 12, BAR_ENERGY)
		"ring_gold":
			for y: int in range(6, 19):
				for x: int in range(6, 18):
					var dx: float = float(x) - 11.5
					var dy: float = float(y) - 12.5
					var d2: float = dx * dx + dy * dy
					if d2 >= 12.0 and d2 <= 28.0:
						img.set_pixel(x, y, GOLD_BRIGHT if y < 12 else GOLD_MID)
			_rect(img, 10, 5, 4, 3, BAR_ENERGY)
		"potion_hp":
			_rect(img, 10, 4, 4, 3, OAK_HIGHLIGHT)
			_rect(img, 9, 7, 6, 2, IRON_HIGHLIGHT)
			_rect(img, 7, 9, 10, 9, BAR_HP)
			_rect(img, 8, 10, 2, 5, Color("#ff8b94"))
		"potion_mana":
			_rect(img, 10, 4, 4, 3, OAK_HIGHLIGHT)
			_rect(img, 9, 7, 6, 2, IRON_HIGHLIGHT)
			_rect(img, 8, 9, 8, 9, BAR_MANA)
			_rect(img, 9, 10, 2, 5, BAR_ENERGY)
		"herb_clarity":
			_line(img, 7, 18, 16, 6, Color("#4ebf6b"))
			_rect(img, 8, 10, 4, 3, Color("#6ee089"))
			_rect(img, 13, 8, 4, 3, Color("#6ee089"))
			_rect(img, 11, 13, 4, 3, GOLD_BRIGHT)
		"ritual_ash":
			_rect(img, 10, 5, 4, 2, GOLD_MID)
			_rect(img, 7, 7, 10, 11, Color("#6d6875"))
			_hline(img, 8, 15, 7, GOLD_BRIGHT)
			_vline(img, 11, 10, 15, BAR_RAGE)
			_px(img, 12, 11, GOLD_BRIGHT)
		_:
			_rect(img, 6, 7, 12, 11, OAK_MID)
			_hline(img, 7, 16, 7, GOLD_MID)
	
	_apply_outline(img, OUTLINE_DARK)
	return img

static func _draw_slot_ghost_image(kind: String) -> Image:
	var img: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ghost_c: Color = Color(0.42, 0.48, 0.58, 0.42)
	match kind:
		"hand_left":
			_line(img, 3, 12, 12, 3, ghost_c)
			_line(img, 4, 9, 7, 12, ghost_c)
		"hand_right":
			_border(img, 4, 3, 8, 9, ghost_c)
			_rect(img, 7, 6, 2, 3, ghost_c)
		"body":
			_rect(img, 4, 4, 8, 9, ghost_c)
			_rect(img, 6, 4, 4, 2, Color(0, 0, 0, 0))
		"accessory":
			_border(img, 4, 5, 8, 7, ghost_c)
			_rect(img, 7, 3, 2, 2, ghost_c)
	return img

static func _draw_tab_icon_image(tab_key: String) -> Image:
	var img: Image = Image.create_empty(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match tab_key:
		"equip":
			_line(img, 3, 11, 11, 3, IRON_HIGHLIGHT)
			_line(img, 4, 8, 6, 10, GOLD_BRIGHT)
		"items":
			_rect(img, 5, 3, 4, 2, GOLD_BRIGHT)
			_rect(img, 3, 5, 8, 7, OAK_HIGHLIGHT)
			_hline(img, 4, 9, 5, GOLD_MID)
		"party":
			_rect(img, 3, 3, 3, 3, IRON_HIGHLIGHT)
			_rect(img, 2, 7, 5, 4, GOLD_MID)
			_rect(img, 8, 4, 3, 3, IRON_MID)
			_rect(img, 8, 8, 4, 3, IRON_HIGHLIGHT)
		"runes":
			# Светящаяся руна ᚱ Райдо
			_vline(img, 4, 2, 11, BAR_ENERGY)
			_line(img, 4, 2, 9, 5, TEXT_RUNE_CYAN)
			_line(img, 9, 5, 4, 7, TEXT_RUNE_CYAN)
			_line(img, 5, 7, 10, 11, BAR_ENERGY)
		"gods":
			# Рог / ритуальная чаша богов
			_rect(img, 4, 3, 6, 4, GOLD_BRIGHT)
			_rect(img, 5, 7, 4, 2, GOLD_MID)
			_vline(img, 6, 9, 11, GOLD_BRIGHT)
			_vline(img, 7, 9, 11, GOLD_MID)
			_hline(img, 4, 9, 11, GOLD_BRIGHT)
	_apply_outline(img, OUTLINE_DARK)
	return img

static func _draw_stat_icon_image(stat_key: String) -> Image:
	var img: Image = Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match stat_key:
		"atk":
			_line(img, 2, 9, 9, 2, IRON_HIGHLIGHT)
			_line(img, 2, 2, 9, 9, IRON_MID)
			_px(img, 3, 8, GOLD_BRIGHT)
			_px(img, 8, 8, GOLD_BRIGHT)
		"mag":
			_vline(img, 5, 2, 9, BAR_ENERGY)
			_hline(img, 2, 8, 5, BAR_ENERGY)
			_px(img, 5, 5, TEXT_PRIMARY)
		"def":
			_rect(img, 3, 2, 6, 6, IRON_MID)
			_rect(img, 4, 8, 4, 2, IRON_HIGHLIGHT)
			_px(img, 5, 4, GOLD_BRIGHT)
		"spd":
			_rect(img, 4, 2, 3, 5, OAK_HIGHLIGHT)
			_rect(img, 3, 7, 6, 3, GOLD_MID)
		"crit":
			_vline(img, 5, 1, 10, GOLD_BRIGHT)
			_hline(img, 1, 10, 5, GOLD_BRIGHT)
	_apply_outline(img, OUTLINE_DARK)
	return img

static func _draw_resource_icon_image(r_name: String) -> Image:
	var img: Image = Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match r_name:
		"mana":
			_rect(img, 4, 3, 4, 6, BAR_MANA)
			_px(img, 5, 2, BAR_ENERGY)
			_px(img, 5, 4, TEXT_PRIMARY)
		"rage":
			_rect(img, 4, 5, 4, 5, BAR_RAGE)
			_px(img, 5, 3, GOLD_BRIGHT)
			_px(img, 6, 4, BAR_HP)
		"hamingja":
			_rect(img, 3, 3, 2, 2, BAR_HAMINGJA)
			_rect(img, 7, 3, 2, 2, BAR_HAMINGJA)
			_rect(img, 3, 7, 2, 2, BAR_HAMINGJA)
			_rect(img, 7, 7, 2, 2, BAR_HAMINGJA)
			_rect(img, 5, 5, 2, 2, GOLD_BRIGHT)
		_:
			_line(img, 7, 2, 4, 6, BAR_ENERGY)
			_hline(img, 4, 7, 6, TEXT_PRIMARY)
			_line(img, 7, 6, 4, 10, BAR_ENERGY)
	_apply_outline(img, OUTLINE_DARK)
	return img

static func _draw_crest_icon_image(kind: String) -> Image:
	var img: Image = Image.create_empty(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if kind == "god_horn":
		_border(img, 4, 4, 12, 12, GOLD_MID)
		_vline(img, 9, 3, 16, GOLD_BRIGHT)
		_hline(img, 3, 16, 9, GOLD_BRIGHT)
		_rect(img, 8, 8, 4, 4, BAR_ENERGY)
	elif kind == "synergy_blades":
		_line(img, 4, 15, 15, 4, TEXT_RUNE_CYAN)
		_line(img, 4, 4, 15, 15, GOLD_BRIGHT)
		_rect(img, 8, 8, 4, 4, IRON_HIGHLIGHT)
	else:
		_border(img, 5, 5, 10, 10, IRON_MID)
		_border(img, 7, 7, 6, 6, OAK_HIGHLIGHT)
	_apply_outline(img, OUTLINE_DARK)
	return img

# =========================================================================
# НИЗКОУРОВНЕВЫЕ РАСТРОВЫЕ УТИЛИТЫ И ПОДДЕРЖКА ВНЕШНИХ PNG
# =========================================================================

static func _try_load_external_png(res_path: String) -> Texture2D:
	if _texture_cache.has(res_path):
		return _texture_cache[res_path] as Texture2D
	if ResourceLoader.exists(res_path):
		var loaded: Texture2D = load(res_path) as Texture2D
		if loaded != null:
			_texture_cache[res_path] = loaded
			return loaded
	return null

static func _px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, col)

static func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	var x0: int = clampi(x, 0, img.get_width())
	var y0: int = clampi(y, 0, img.get_height())
	var x1: int = clampi(x + w, 0, img.get_width())
	var y1: int = clampi(y + h, 0, img.get_height())
	for py: int in range(y0, y1):
		for px_i: int in range(x0, x1):
			img.set_pixel(px_i, py, col)

static func _hline(img: Image, x0: int, x1: int, y: int, col: Color) -> void:
	if y < 0 or y >= img.get_height():
		return
	var xa: int = mini(x0, x1)
	var xb: int = maxi(x0, x1)
	for x: int in range(xa, xb + 1):
		_px(img, x, y, col)

static func _vline(img: Image, x: int, y0: int, y1: int, col: Color) -> void:
	if x < 0 or x >= img.get_width():
		return
	var ya: int = mini(y0, y1)
	var yb: int = maxi(y0, y1)
	for y: int in range(ya, yb + 1):
		_px(img, x, y, col)

static func _border(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	_hline(img, x, x + w - 1, y, col)
	_hline(img, x, x + w - 1, y + h - 1, col)
	_vline(img, x, y, y + h - 1, col)
	_vline(img, x + w - 1, y, y + h - 1, col)

static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	var steps: int = maxi(absi(x1 - x0), absi(y1 - y0))
	if steps == 0:
		_px(img, x0, y0, col)
		return
	for i: int in range(steps + 1):
		var t: float = float(i) / float(steps)
		var cx: int = roundi(lerpf(float(x0), float(x1), t))
		var cy: int = roundi(lerpf(float(y0), float(y1), t))
		_px(img, cx, cy, col)

static func _apply_outline(img: Image, outline_col: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var copy: Image = img.duplicate() as Image
	for y: int in range(h):
		for x: int in range(w):
			if copy.get_pixel(x, y).a > 0.1:
				continue
			var has_neighbor: bool = false
			for off: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx: int = x + off.x
				var ny: int = y + off.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and copy.get_pixel(nx, ny).a > 0.25:
					has_neighbor = true
					break
			if has_neighbor:
				img.set_pixel(x, y, outline_col)
