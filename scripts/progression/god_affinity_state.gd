# res://scripts/progression/god_affinity_state.gd
class_name GodAffinityState
extends RefCounted

## Модульное состояние склонности к Богам: 4 пары антагонистов, БЕЗ сброса, покровитель ГГ, Благословение отряда и ступени вербовки
signal gods_changed()

var all_gods: Array[GodData] = []
var _god_by_id: Dictionary = {}

## Накопленная склонность по каждому богу {BattleTypes.GodId (int): int (0..100)} — НЕ имеет метода сброса
var affinities: Dictionary = {}
## Активный выбранный бог-покровитель Главного Героя
var active_patron: BattleTypes.GodId = BattleTypes.GodId.NONE
## Debug-флаг отображения точных чисел склонности рядом со словесными ступенями (по умолчанию false)
var show_god_affinity_numbers: bool = false

func initialize_defaults() -> void:
	all_gods = GodCatalogFactory.create_all_gods()
	_god_by_id.clear()
	affinities.clear()
	for g: GodData in all_gods:
		if g == null:
			continue
		_god_by_id[int(g.god_id)] = g
		affinities[int(g.god_id)] = 0
	active_patron = BattleTypes.GodId.NONE
	show_god_affinity_numbers = false

func get_god_data(god_id: BattleTypes.GodId) -> GodData:
	return _god_by_id.get(int(god_id), null) as GodData

func get_affinity(god_id: BattleTypes.GodId) -> int:
	if god_id == BattleTypes.GodId.NONE:
		return 0
	return int(affinities.get(int(god_id), 0))

func get_verbal_affinity(god_id: BattleTypes.GodId) -> String:
	return GodTypes.get_verbal_affinity_label(get_affinity(god_id), show_god_affinity_numbers)

func can_choose_as_patron(god_id: BattleTypes.GodId) -> bool:
	if god_id == BattleTypes.GodId.NONE:
		return false
	return get_affinity(god_id) >= GodTypes.PATRON_THRESHOLD

## Необратимо накапливает склонность к указанному богу от поступка/выбора (только положительный прирост, без сброса!)
func add_affinity(god_id: BattleTypes.GodId, delta: int) -> Dictionary:
	if god_id == BattleTypes.GodId.NONE or delta <= 0:
		return {"ok": false, "reason": "Склонность к богам накапливается необратимо и не может быть уменьшена или сброшена."}
	var prev_val: int = get_affinity(god_id)
	var next_val: int = clampi(prev_val + delta, 0, GodTypes.MAX_AFFINITY)
	affinities[int(god_id)] = next_val
	
	var g_data: GodData = get_god_data(god_id)
	var g_name: String = g_data.display_name if g_data != null else BattleTypes.get_god_display_name(god_id)
	var unlocked_note: String = ""
	if prev_val < GodTypes.PATRON_THRESHOLD and next_val >= GodTypes.PATRON_THRESHOLD:
		unlocked_note = " Открыто избрание покровителем и I дар пути!"
	elif prev_val < GodTypes.TIER_2_SKILL_THRESHOLD and next_val >= GodTypes.TIER_2_SKILL_THRESHOLD:
		unlocked_note = " Открыто II умение пути бога!"
	
	gods_changed.emit()
	return {
		"ok": true,
		"reason": "Поступок запечатлён навечно (%s — %s).%s" % [
			g_name,
			get_verbal_affinity(god_id),
			unlocked_note
		]
	}

## Избирает активного бога-покровителя ГГ из богов, достигших порога благосклонности (>= 15)
func set_active_patron(god_id: BattleTypes.GodId) -> Dictionary:
	if god_id == BattleTypes.GodId.NONE:
		active_patron = BattleTypes.GodId.NONE
		gods_changed.emit()
		return {"ok": true, "reason": "ГГ временно не возносит молитву конкретному покровителю (склонности сохранены)."}
	if not can_choose_as_patron(god_id):
		return {
			"ok": false,
			"reason": "%s ещё не проявил достаточной благосклонности для покровительства." % BattleTypes.get_god_display_name(god_id)
		}
	active_patron = god_id
	gods_changed.emit()
	return {
		"ok": true,
		"reason": "%s избран активным покровителем Главного Героя!" % BattleTypes.get_god_display_name(god_id)
	}

func set_show_affinity_numbers(enabled: bool) -> void:
	show_god_affinity_numbers = enabled
	gods_changed.emit()

## Рассчитывает ступень сложности вербовки рекрута (IMMEDIATE / STANDARD / HARD_1..HARD_MAX с жестким потолком)
func get_recruitment_tier(recruit_god: BattleTypes.GodId) -> GodTypes.RecruitmentTier:
	if recruit_god == BattleTypes.GodId.NONE:
		return GodTypes.RecruitmentTier.STANDARD
	
	var antagonist: BattleTypes.GodId = GodTypes.get_antagonist(recruit_god)
	var same_aff: int = get_affinity(recruit_god)
	var opp_aff: int = get_affinity(antagonist)
	
	# 1. Совпадение: ГГ избрал того же покровителя (или явно предан этому богу сильнее антагониста)
	if active_patron == recruit_god and same_aff >= opp_aff:
		return GodTypes.RecruitmentTier.IMMEDIATE
	if active_patron != antagonist and same_aff >= GodTypes.PATRON_THRESHOLD and (same_aff - opp_aff) >= GodTypes.PATRON_THRESHOLD:
		return GodTypes.RecruitmentTier.IMMEDIATE
	
	# 2. Конфликт с антагонистом: ступенчатый рост с жестким потолком HARD_MAX (вербовка всегда остается возможной!)
	var conflict_score: int = maxi(0, opp_aff - same_aff)
	if active_patron == antagonist:
		conflict_score += 15
	
	if conflict_score >= 45:
		return GodTypes.RecruitmentTier.HARD_MAX
	if conflict_score >= 30:
		return GodTypes.RecruitmentTier.HARD_2
	if conflict_score >= 15:
		return GodTypes.RecruitmentTier.HARD_1
	
	# 3. Нейтральное отношение
	return GodTypes.RecruitmentTier.STANDARD

## Возвращает список активных Благословений отряда (если в active_party >= 2 бойцов одного бога, считая покровителя ГГ)
func compute_party_blessings(party_members: Array[CombatantData]) -> Array[GodData]:
	var counts: Dictionary = {}
	for m: CombatantData in party_members:
		if m == null:
			continue
		var eff_god: BattleTypes.GodId = active_patron if m.is_hero else m.patron_god
		if eff_god == BattleTypes.GodId.NONE:
			continue
		counts[int(eff_god)] = int(counts.get(int(eff_god), 0)) + 1
	
	var result: Array[GodData] = []
	for g: GodData in all_gods:
		if g != null and int(counts.get(int(g.god_id), 0)) >= 2:
			result.append(g)
	return result

## Возвращает бонусы активного покровителя и открытые умения пути бога для Главного Героя
func compute_hero_patron_modifiers() -> Dictionary:
	var mods: Dictionary = {
		"has_patron": false,
		"patron_name": "",
		"max_hp": 0,
		"attack": 0,
		"magic_power": 0,
		"defense": 0,
		"speed": 0,
		"crit_chance": 0.0,
		"granted_skills": []
	}
	if active_patron == BattleTypes.GodId.NONE:
		return mods
	var g: GodData = get_god_data(active_patron)
	if g == null:
		return mods
	
	var aff: int = get_affinity(active_patron)
	var skills_arr: Array[SkillData] = []
	if aff >= GodTypes.PATRON_THRESHOLD and g.tier_1_skill != null:
		skills_arr.append(g.tier_1_skill)
	if aff >= GodTypes.TIER_2_SKILL_THRESHOLD and g.tier_2_skill != null:
		skills_arr.append(g.tier_2_skill)
	
	mods["has_patron"] = true
	mods["patron_name"] = g.display_name
	mods["max_hp"] = g.patron_hp_bonus
	mods["attack"] = g.patron_attack_bonus
	mods["magic_power"] = g.patron_magic_bonus
	mods["defense"] = g.patron_defense_bonus
	mods["speed"] = g.patron_speed_bonus
	mods["crit_chance"] = g.patron_crit_bonus
	mods["granted_skills"] = skills_arr
	return mods

## Суммирует боевые баффы всех активных Благословений отряда (>= 2 бойцов одного бога)
func compute_party_blessing_modifiers(party_members: Array[CombatantData]) -> Dictionary:
	var mods: Dictionary = {
		"active": false,
		"blessing_names": [],
		"max_hp": 0,
		"attack": 0,
		"magic_power": 0,
		"defense": 0,
		"speed": 0,
		"crit_chance": 0.0,
		"start_barrier": 0
	}
	var blessings: Array[GodData] = compute_party_blessings(party_members)
	if blessings.is_empty():
		return mods
	
	var names: Array[String] = []
	for g: GodData in blessings:
		names.append("%s (%s)" % [g.blessing_name, g.display_name])
		mods["max_hp"] = int(mods["max_hp"]) + g.blessing_hp_bonus
		mods["attack"] = int(mods["attack"]) + g.blessing_attack_bonus
		mods["magic_power"] = int(mods["magic_power"]) + g.blessing_magic_bonus
		mods["defense"] = int(mods["defense"]) + g.blessing_defense_bonus
		mods["speed"] = int(mods["speed"]) + g.blessing_speed_bonus
		mods["crit_chance"] = float(mods["crit_chance"]) + g.blessing_crit_bonus
		mods["start_barrier"] = int(mods["start_barrier"]) + g.blessing_start_barrier
	mods["active"] = true
	mods["blessing_names"] = names
	return mods
