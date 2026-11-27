# res://scripts/progression/rune_system_state.gd
class_name RuneSystemState
extends RefCounted

## Модульное состояние Старшего футарка ГГ (Знаки, уровни 0..5, активная Вязь 2..6, Бандруны, Великие вязи, Резонанс и сброс)
signal runes_changed()

var all_runes: Array[RuneData] = []
var all_bindrunes: Array[BindruneData] = []
var all_great_binds: Array[GreatBindData] = []

var _rune_by_id: Dictionary = {}

## Доступные очки прокачки «Знаки» и счетчик вложенных Знаков для полного возврата при сбросе
var signs_available: int = 0
var signs_spent_total: int = 0

## Открытые по сюжету руны {StringName: true}
var unlocked_runes: Dictionary = {}
## Постоянный уровень прокачки каждой руны {StringName: int (0..5)}, сохраняется при снятии из Вязи
var rune_ranks: Dictionary = {}
## Активная Вязь ГГ (до max_bind_slots рун одновременно)
var active_runes: Array[StringName] = []
## Лимит слотов активной Вязи (от 2 до 6 по мере эпизодов)
var max_bind_slots: int = 6
## Выбранная активная Великая вязь (максимум 1 Ульта одновременно)
var selected_great_bind_id: StringName = &""

func initialize_defaults() -> void:
	all_runes = RuneCatalogFactory.create_all_runes()
	all_bindrunes = RuneCatalogFactory.create_all_bindrunes()
	all_great_binds = RuneCatalogFactory.create_all_great_binds()
	_rune_by_id.clear()
	unlocked_runes.clear()
	rune_ranks.clear()
	active_runes.clear()
	
	for r: RuneData in all_runes:
		if r == null:
			continue
		_rune_by_id[r.rune_id] = r
		rune_ranks[r.rune_id] = 0
		# В стартовом пресете открываем руны эпизодов 1..2 (18 рун, включая родовые руны отряда и ядра Бандрун/Великих вязей)
		if r.unlock_episode <= 2:
			unlocked_runes[r.rune_id] = true
	
	# Тестовый стартовый пресет для удобной проверки в деревне и песочнице
	max_bind_slots = 6
	signs_available = 26
	signs_spent_total = 0
	
	_seed_initial_rank(&"fehu", 3)
	_seed_initial_rank(&"uruz", 3)
	_seed_initial_rank(&"thurisaz", 3)
	_seed_initial_rank(&"tiwaz", 3)
	_seed_initial_rank(&"othala", 3)
	
	active_runes = [&"uruz", &"thurisaz", &"tiwaz", &"othala"]
	_sync_selected_great_bind()

func _seed_initial_rank(rune_id: StringName, rank: int) -> void:
	var clamped: int = clampi(rank, 0, RuneTypes.MAX_RUNE_RANK)
	unlocked_runes[rune_id] = true
	rune_ranks[rune_id] = clamped
	signs_spent_total += clamped

func get_rune_data(rune_id: StringName) -> RuneData:
	return _rune_by_id.get(rune_id, null) as RuneData

func is_rune_unlocked(rune_id: StringName) -> bool:
	return bool(unlocked_runes.get(rune_id, false))

func get_rune_rank(rune_id: StringName) -> int:
	return int(rune_ranks.get(rune_id, 0))

func is_rune_in_bind(rune_id: StringName) -> bool:
	return active_runes.has(rune_id)

## Открывает все 24 руны Старшего футарка (удобная кнопка для песочницы/деревни)
func unlock_all_runes_for_testing() -> void:
	for r: RuneData in all_runes:
		if r != null:
			unlocked_runes[r.rune_id] = true
	runes_changed.emit()

## Изменяет лимит слотов активной Вязи (2..6), при сужении аккуратно обрезая хвост Вязи без потери уровней веток
func set_max_bind_slots(new_limit: int) -> void:
	max_bind_slots = clampi(new_limit, RuneTypes.MIN_BIND_SLOTS, RuneTypes.MAX_BIND_SLOTS)
	while active_runes.size() > max_bind_slots:
		active_runes.pop_back()
	_sync_selected_great_bind()
	runes_changed.emit()

## Вкладывает 1 Знак в выбранную открытую руну (до 5-й ступени — Печати)
func invest_sign(rune_id: StringName) -> Dictionary:
	var r: RuneData = get_rune_data(rune_id)
	if r == null:
		return {"ok": false, "reason": "Руна не найдена."}
	if not is_rune_unlocked(rune_id):
		return {"ok": false, "reason": "Руна «%s» ещё не открыта по сюжету." % r.display_name}
	var cur_rank: int = get_rune_rank(rune_id)
	if cur_rank >= RuneTypes.MAX_RUNE_RANK:
		return {"ok": false, "reason": "На руне «%s» уже открыта 5-я ступень (Печать)." % r.display_name}
	if signs_available <= 0:
		return {"ok": false, "reason": "Недостаточно свободных Знаков."}
	
	signs_available -= 1
	signs_spent_total += 1
	var next_rank: int = cur_rank + 1
	rune_ranks[rune_id] = next_rank
	_sync_selected_great_bind()
	runes_changed.emit()
	
	if next_rank == RuneTypes.SEAL_RANK:
		return {"ok": true, "reason": "Открыта ПЕЧАТЬ руны %s — «%s»!" % [r.get_titled_name(), r.seal_name]}
	return {"ok": true, "reason": "%s повышена до ступени %d/%d." % [r.get_titled_name(), next_rank, RuneTypes.MAX_RUNE_RANK]}

## Бесплатно вставляет руну в активную Вязь или вынимает её (уровень ветки сохраняется)
func toggle_rune_in_bind(rune_id: StringName) -> Dictionary:
	var r: RuneData = get_rune_data(rune_id)
	if r == null:
		return {"ok": false, "reason": "Руна не найдена."}
	if active_runes.has(rune_id):
		active_runes.erase(rune_id)
		_sync_selected_great_bind()
		runes_changed.emit()
		return {"ok": true, "reason": "%s снята из активной Вязи (ступень %d сохранена)." % [r.get_titled_name(), get_rune_rank(rune_id)]}
	
	if not is_rune_unlocked(rune_id):
		return {"ok": false, "reason": "Сначала откройте руну «%s»." % r.display_name}
	if get_rune_rank(rune_id) <= 0:
		return {"ok": false, "reason": "Вложите хотя бы 1 Знак в %s, чтобы вплести её в Вязь." % r.get_titled_name()}
	if active_runes.size() >= max_bind_slots:
		return {"ok": false, "reason": "Все слоты Вязи заняты (%d/%d). Снимите одну из рун." % [active_runes.size(), max_bind_slots]}
	
	active_runes.append(rune_id)
	_sync_selected_great_bind()
	runes_changed.emit()
	return {"ok": true, "reason": "%s вплетена в активную Вязь (%d/%d)." % [r.get_titled_name(), active_runes.size(), max_bind_slots]}

## Выбирает активную Великую вязь среди удовлетворенных троек (максимум 1 активна одновременно)
func select_great_bind(great_bind_id: StringName) -> Dictionary:
	for gb: GreatBindData in get_available_great_binds():
		if gb.great_bind_id == great_bind_id:
			selected_great_bind_id = great_bind_id
			runes_changed.emit()
			return {"ok": true, "reason": "Активной Ультой ГГ выбрана «%s»." % gb.display_name}
	return {"ok": false, "reason": "Эта Великая вязь сейчас не собрана в активной Вязи."}

## Полный сброс рун за дешёвый расходник: возвращает 100% вложенных Знаков и очищает Вязь
func reset_all_runes_with_consumable(inventory: InventoryState, reset_item_id: String) -> Dictionary:
	if signs_spent_total <= 0:
		return {"ok": false, "reason": "В руны пока не вложено ни одного Знака."}
	if inventory == null or inventory.get_item_count(reset_item_id) <= 0:
		return {"ok": false, "reason": "Для обряда сброса нужна «Зола обряда» в инвентаре."}
	if not inventory.remove_item(reset_item_id, 1):
		return {"ok": false, "reason": "Не удалось списать расходник сброса."}
	
	var refunded: int = signs_spent_total
	signs_available += refunded
	signs_spent_total = 0
	for key: Variant in rune_ranks.keys():
		var r_id: StringName = key as StringName
		rune_ranks[r_id] = 0
	active_runes.clear()
	selected_great_bind_id = &""
	runes_changed.emit()
	return {
		"ok": true,
		"reason": "Обряд очищения проведён: возвращено %d Знаков, Вязь очищена." % refunded
	}

## Возвращает все активные Бандруны (обе руны в Вязи и обе уровня >= 3)
func get_active_bindrunes() -> Array[BindruneData]:
	var result: Array[BindruneData] = []
	for b: BindruneData in all_bindrunes:
		if b != null and b.is_satisfied(active_runes, rune_ranks):
			result.append(b)
	return result

## Возвращает все собранные Великие вязи (все 3 руны в Вязи на уровне 5 — Печать)
func get_available_great_binds() -> Array[GreatBindData]:
	var result: Array[GreatBindData] = []
	for gb: GreatBindData in all_great_binds:
		if gb != null and gb.is_satisfied(active_runes, rune_ranks):
			result.append(gb)
	return result

## Возвращает единственную активную Великую вязь (либо null, если ни одна не собрана)
func get_active_great_bind() -> GreatBindData:
	var avail: Array[GreatBindData] = get_available_great_binds()
	if avail.is_empty():
		return null
	for gb: GreatBindData in avail:
		if gb.great_bind_id == selected_great_bind_id:
			return gb
	return avail[0]

func _sync_selected_great_bind() -> void:
	var avail: Array[GreatBindData] = get_available_great_binds()
	if avail.is_empty():
		selected_great_bind_id = &""
		return
	for gb: GreatBindData in avail:
		if gb.great_bind_id == selected_great_bind_id:
			return
	selected_great_bind_id = avail[0].great_bind_id

## Рассчитывает прогресс развития Футарка для масштабирования силы Великой вязи (от 0.50 до 1.00)
func get_great_bind_progression_ratio() -> float:
	# 15 вложенных Знаков (минимум на 1 Великую вязь) = 50%; 60+ вложенных Знаков = 100%
	var extra_signs: float = float(maxi(0, signs_spent_total - 15))
	var t: float = clampf(extra_signs / 45.0, 0.0, 1.0)
	return lerpf(0.50, 1.00, t)

## Вычисляет бонус Оталы (ᛟ) от числа рекрутов в резерве корабля (ship_roster)
func get_othala_ship_bonus(ship_roster_count: int) -> Dictionary:
	if not active_runes.has(&"othala") or ship_roster_count <= 0:
		return {"active": false, "max_hp": 0, "attack": 0, "defense": 0}
	var rank: int = get_rune_rank(&"othala")
	if rank <= 0:
		return {"active": false, "max_hp": 0, "attack": 0, "defense": 0}
	var has_seal: bool = rank >= RuneTypes.SEAL_RANK
	var hp_per: int = 14 if has_seal else (4 + rank)
	var atk_per: int = 5 if has_seal else maxi(1, int(floor(float(rank + 1) * 0.5)))
	var def_per: int = 3 if has_seal else maxi(1, int(floor(float(rank) * 0.5)))
	return {
		"active": true,
		"max_hp": hp_per * ship_roster_count,
		"attack": atk_per * ship_roster_count,
		"defense": def_per * ship_roster_count,
		"ship_count": ship_roster_count,
		"has_seal": has_seal
	}

## Вычисляет полный пакет модификаторов рунной Вязи для Главного Героя
func compute_hero_rune_modifiers(ship_roster_count: int) -> Dictionary:
	var totals: Dictionary = {
		"max_hp": 0,
		"attack": 0,
		"magic_power": 0,
		"defense": 0,
		"speed": 0,
		"crit_chance": 0.0,
		"crit_multiplier": 0.0,
		"qte_perfect_delta": 0.0,
		"max_flow_bonus": 0,
		"start_flow_bonus": 0,
		"start_tension_bonus": 0,
		"start_barrier": 0,
		"party_speed_aura": 0,
		"seal_ids": [],
		"bindrune_skills": [],
		"great_bind_ultimate": null,
		"great_bind_name": "",
		"othala_bonus": get_othala_ship_bonus(ship_roster_count)
	}
	
	var seal_list: Array[StringName] = []
	for r_id: StringName in active_runes:
		var r: RuneData = get_rune_data(r_id)
		var rank: int = get_rune_rank(r_id)
		if r == null or rank <= 0:
			continue
		var b: Dictionary = r.get_bonuses_for_rank(rank)
		totals["max_hp"] = int(totals["max_hp"]) + int(b.get("max_hp", 0))
		totals["attack"] = int(totals["attack"]) + int(b.get("attack", 0))
		totals["magic_power"] = int(totals["magic_power"]) + int(b.get("magic_power", 0))
		totals["defense"] = int(totals["defense"]) + int(b.get("defense", 0))
		totals["speed"] = int(totals["speed"]) + int(b.get("speed", 0))
		totals["crit_chance"] = float(totals["crit_chance"]) + float(b.get("crit_chance", 0.0))
		totals["crit_multiplier"] = float(totals["crit_multiplier"]) + float(b.get("crit_multiplier", 0.0))
		
		if bool(b.get("has_seal", false)) and r.seal_id != &"":
			seal_list.append(r.seal_id)
			match r.seal_id:
				&"seal_fehu":
					totals["start_tension_bonus"] = int(totals["start_tension_bonus"]) + 15
				&"seal_raidho":
					totals["start_flow_bonus"] = int(totals["start_flow_bonus"]) + 12
				&"seal_perthro":
					totals["qte_perfect_delta"] = float(totals["qte_perfect_delta"]) - 0.06
				&"seal_algiz":
					totals["start_barrier"] = int(totals["start_barrier"]) + 26
				&"seal_ehwaz":
					totals["party_speed_aura"] = int(totals["party_speed_aura"]) + 2
				&"seal_laguz":
					totals["max_flow_bonus"] = int(totals["max_flow_bonus"]) + 20
					totals["start_flow_bonus"] = int(totals["start_flow_bonus"]) + 15
				&"seal_ingwaz":
					totals["start_tension_bonus"] = int(totals["start_tension_bonus"]) + 25
	
	var oth: Dictionary = totals["othala_bonus"] as Dictionary
	if bool(oth.get("active", false)):
		totals["max_hp"] = int(totals["max_hp"]) + int(oth.get("max_hp", 0))
		totals["attack"] = int(totals["attack"]) + int(oth.get("attack", 0))
		totals["defense"] = int(totals["defense"]) + int(oth.get("defense", 0))
	
	totals["seal_ids"] = seal_list
	
	var b_skills: Array[SkillData] = []
	for br: BindruneData in get_active_bindrunes():
		if br.granted_skill != null:
			b_skills.append(br.granted_skill)
	totals["bindrune_skills"] = b_skills
	
	var gb: GreatBindData = get_active_great_bind()
	if gb != null:
		totals["great_bind_name"] = gb.display_name
		totals["great_bind_ultimate"] = gb.build_scaled_ultimate(get_great_bind_progression_ratio(), ship_roster_count)
	
	return totals

## Проверяет Резонанс родовой руны рекрута с активной Вязью ГГ
func compute_recruit_resonance(ancestral_rune_id: StringName) -> Dictionary:
	if ancestral_rune_id == &"" or not active_runes.has(ancestral_rune_id):
		return {"active": false}
	var r: RuneData = get_rune_data(ancestral_rune_id)
	var rank: int = get_rune_rank(ancestral_rune_id)
	if r == null or rank <= 0:
		return {"active": false}
	# Бонус резонанса слегка растет при высокой прокачке родовой руны у ГГ (1.0x .. 1.5x на Печати)
	var scale: float = 1.5 if rank >= RuneTypes.SEAL_RANK else (1.25 if rank >= 3 else 1.0)
	return {
		"active": true,
		"rune_name": r.get_titled_name(),
		"summary": r.resonance_description,
		"max_hp": roundi(float(r.resonance_hp) * scale),
		"attack": roundi(float(r.resonance_attack) * scale),
		"magic_power": roundi(float(r.resonance_magic) * scale),
		"defense": roundi(float(r.resonance_defense) * scale),
		"speed": r.resonance_speed + (1 if rank >= RuneTypes.SEAL_RANK and r.resonance_speed > 0 else 0),
		"crit_chance": r.resonance_crit * scale
	}
