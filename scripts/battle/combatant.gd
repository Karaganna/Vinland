# res://scripts/battle/combatant.gd
class_name Combatant
extends RefCounted

## Сигналы runtime-состояния бойца (строго снизу вверх)
signal hp_changed(current_hp: int, max_hp: int)
signal resolve_changed(current_resolve: int, max_resolve: int)
signal died(combatant: Combatant)
signal status_applied(status_type: BattleTypes.StatusType)
signal status_removed(status_type: BattleTypes.StatusType)
signal part_broken(part_id: String)
signal telegraph_started(skill: SkillData, warning_text: String)
signal telegraph_cleared()

var runtime_id: String = ""
var display_name: String = "Боец"
var role_title: String = ""
var is_player_controlled: bool = false
var is_hero: bool = false
var is_viking: bool = true
var primary_resource: BattleTypes.ResourceType = BattleTypes.ResourceType.ENERGY
var ancestral_rune_id: StringName = &""
var patron_god: BattleTypes.GodId = BattleTypes.GodId.NONE
var sprite_color: Color = Color.WHITE

var stats: CombatStatsData = null
var max_hp: int = 100
var current_hp: int = 100

## Legacy-поля Завета (оставлены для обратной совместимости со старыми EnemyData, в бою отключены)
var max_resolve: int = 100
var current_resolve: int = 0
var resolve_per_vow: int = 35

var resources: ResourcePool = null
var basic_attack: SkillData = null
var skills: Array[SkillData] = []
var ultimate_skill: SkillData = null

var equipment_loadout: EquipmentLoadout = null
var active_synergies: Array[WeaponSynergyData] = []

var equipment_modifiers: Array[EquipmentModifierStub] = []
var item_slots: Array[ItemSlotStub] = []
var rune_slots: Array[RuneSlotStub] = []

## Прогрессия Футарка, Резонанса, Покровителя и Благословений отряда
var progression_stat_bonuses: Dictionary = {}
var active_seal_ids: Array[StringName] = []
var has_resonance_active: bool = false
var resonance_label: String = ""
var active_blessing_names: Array[String] = []
var active_great_bind_name: String = ""
var start_battle_barrier: int = 0
var eihwaz_death_ward_ready: bool = false
var skill_cost_multiplier: float = 1.0

var parts: Array[EnemyPartState] = []
var statuses: Array[StatusEffectInstance] = []

var is_blocking: bool = false
var block_energy_restore: int = 20

var pending_telegraph_skill: SkillData = null
var telegraph_turns_left: int = 0

var source_enemy_data: EnemyData = null

func _init() -> void:
	resources = ResourcePool.new()
	stats = CombatStatsData.new()

## Создает runtime-бойца для отряда игрока из иммутабельного ресурса CombatantData
static func from_combatant_data(
	data: CombatantData,
	p_runtime_id: String = "",
	synergy_catalog: Array[WeaponSynergyData] = []
) -> Combatant:
	var c: Combatant = Combatant.new()
	if data == null:
		return c
	
	c.runtime_id = p_runtime_id if not p_runtime_id.is_empty() else data.combatant_id
	c.display_name = data.display_name
	c.role_title = data.role_title
	c.is_player_controlled = data.is_player_controlled
	c.is_hero = data.is_hero
	c.is_viking = data.is_viking
	c.ancestral_rune_id = data.ancestral_rune_id
	c.patron_god = data.patron_god
	c.sprite_color = data.sprite_color
	c.stats = data.stats.create_copy() if data.stats != null else CombatStatsData.new()
	
	if data.equipment_loadout != null:
		c.equipment_loadout = data.equipment_loadout.create_copy()
		c.active_synergies = c.equipment_loadout.get_active_synergies(synergy_catalog)
	
	c.equipment_modifiers = data.equipment_modifiers.duplicate()
	c.item_slots = data.item_slots.duplicate()
	c.rune_slots = data.rune_slots.duplicate()
	
	c.max_hp = maxi(1, c.stats.max_hp + c._get_equipment_hp_bonus())
	c.current_hp = c.max_hp
	
	c.basic_attack = data.basic_attack
	c.skills.clear()
	var seen_skill_ids: Array[String] = []
	for p_sk: SkillData in data.personal_skills:
		if p_sk == null:
			continue
		if not p_sk.skill_id.is_empty() and seen_skill_ids.has(p_sk.skill_id):
			continue
		if not p_sk.skill_id.is_empty():
			seen_skill_ids.append(p_sk.skill_id)
		c.skills.append(p_sk)
	for existing_sk: SkillData in data.skills:
		if existing_sk == null:
			continue
		if not existing_sk.skill_id.is_empty() and seen_skill_ids.has(existing_sk.skill_id):
			continue
		if not existing_sk.skill_id.is_empty():
			seen_skill_ids.append(existing_sk.skill_id)
		c.skills.append(existing_sk)
	if c.equipment_loadout != null:
		for granted_sk: SkillData in c.equipment_loadout.get_granted_skills(synergy_catalog):
			if granted_sk == null:
				continue
			if not granted_sk.skill_id.is_empty() and seen_skill_ids.has(granted_sk.skill_id):
				continue
			if not granted_sk.skill_id.is_empty():
				seen_skill_ids.append(granted_sk.skill_id)
			c.skills.append(granted_sk)
	c.ultimate_skill = data.ultimate_skill
	
	c.resources.enable_low_energy_penalty = data.enable_low_energy_penalty
	c.resources.energy_low_threshold_ratio = data.energy_low_threshold_ratio
	c.resources.energy_low_outgoing_multiplier = data.energy_low_outgoing_multiplier
	c.resources.energy_low_incoming_multiplier = data.energy_low_incoming_multiplier
	c.resources.ultimate_unlocked = data.ultimate_unlocked
	c.resources.ultimate_max_tier = data.ultimate_max_tier
	
	if c.is_hero:
		var flow_mode: BattleTypes.ResourceType = data.default_flow_mode
		if c.equipment_loadout != null:
			flow_mode = c.equipment_loadout.resolve_hero_flow_mode(flow_mode)
		var flow_bounds: Vector2i = _get_resource_bounds_from_data(data, flow_mode)
		c.primary_resource = flow_mode
		c.resources.configure_hero_flow(flow_mode, flow_bounds.x, flow_bounds.y)
	else:
		var valid_tank: BattleTypes.ResourceType = data.get_validated_primary_resource()
		var tank_bounds: Vector2i = _get_resource_bounds_from_data(data, valid_tank)
		c.primary_resource = valid_tank
		c.resources.configure_recruit_single_tank(valid_tank, tank_bounds.x, tank_bounds.y)
	
	c.resources.configure_resource(BattleTypes.ResourceType.TENSION, data.max_tension, data.initial_tension, true)
	return c

## Применяет к бойцу модификаторы Старшего футарка (Вязь, Бандруны, Великая вязь, Отала, Резонанс) и Системы Богов
func apply_progression_modifiers(
	rune_state: RuneSystemState,
	god_state: GodAffinityState,
	party_data: Array[CombatantData],
	ship_count: int
) -> void:
	progression_stat_bonuses = {
		"max_hp": 0,
		"attack": 0,
		"magic_power": 0,
		"defense": 0,
		"speed": 0,
		"crit_chance": 0.0,
		"crit_multiplier": 0.0,
		"qte_perfect_delta": 0.0
	}
	active_seal_ids.clear()
	has_resonance_active = false
	resonance_label = ""
	active_blessing_names.clear()
	active_great_bind_name = ""
	start_battle_barrier = 0
	eihwaz_death_ward_ready = false
	skill_cost_multiplier = 1.0
	
	var hp_ratio_before: float = float(current_hp) / float(maxi(1, max_hp))
	var party_speed_aura: int = 0
	if rune_state != null:
		var hero_preview: Dictionary = rune_state.compute_hero_rune_modifiers(ship_count)
		party_speed_aura = int(hero_preview.get("party_speed_aura", 0))
		if is_hero:
			_add_prog_bonus(hero_preview)
			progression_stat_bonuses["qte_perfect_delta"] = float(hero_preview.get("qte_perfect_delta", 0.0))
			start_battle_barrier += int(hero_preview.get("start_barrier", 0))
			var seals_var: Variant = hero_preview.get("seal_ids", [])
			if seals_var is Array:
				for s_entry: Variant in seals_var:
					var s_id: StringName = s_entry as StringName
					if s_id != &"":
						active_seal_ids.append(s_id)
			if has_rune_seal(&"seal_ansuz"):
				skill_cost_multiplier = 0.85
			if has_rune_seal(&"seal_eihwaz"):
				eihwaz_death_ward_ready = true
			
			# Увеличение максимума/старта Потока (Лагуз, Райдо) и стартового Напряжения (Феху, Ингваз)
			var max_flow_add: int = int(hero_preview.get("max_flow_bonus", 0))
			var start_flow_add: int = int(hero_preview.get("start_flow_bonus", 0))
			if max_flow_add > 0 or start_flow_add > 0:
				var f_type: BattleTypes.ResourceType = resources.get_working_resource_type()
				var new_max_f: int = resources.get_max(f_type) + max_flow_add
				var new_cur_f: int = mini(new_max_f, resources.get_current(f_type) + start_flow_add)
				resources.configure_hero_flow(f_type, new_max_f, new_cur_f)
			var start_t_add: int = int(hero_preview.get("start_tension_bonus", 0))
			if start_t_add > 0:
				resources.restore_resource(BattleTypes.ResourceType.TENSION, start_t_add)
			
			# Активные умения Бандрун
			var br_var: Variant = hero_preview.get("bindrune_skills", [])
			if br_var is Array:
				for br_sk_v: Variant in br_var:
					if br_sk_v is SkillData:
						_append_skill_if_missing(br_sk_v as SkillData)
			
			# Активная Великая вязь заменяет Ульту ГГ (максимум 1 Великая вязь активна одновременно)
			var gb_ult: SkillData = hero_preview.get("great_bind_ultimate", null) as SkillData
			if gb_ult != null:
				ultimate_skill = gb_ult
				active_great_bind_name = str(hero_preview.get("great_bind_name", ""))
				resources.ultimate_unlocked = true
				resources.ultimate_max_tier = BattleTypes.TensionTier.FULL_100
		else:
			# Резонанс родовой руны рекрута с активной Вязью ГГ
			var res_info: Dictionary = rune_state.compute_recruit_resonance(ancestral_rune_id)
			if bool(res_info.get("active", false)):
				has_resonance_active = true
				resonance_label = str(res_info.get("rune_name", String(ancestral_rune_id)))
				_add_prog_bonus(res_info)
	
	if party_speed_aura != 0:
		progression_stat_bonuses["speed"] = int(progression_stat_bonuses["speed"]) + party_speed_aura
	
	if god_state != null:
		if is_hero:
			patron_god = god_state.active_patron
			var pat_mods: Dictionary = god_state.compute_hero_patron_modifiers()
			if bool(pat_mods.get("has_patron", false)):
				_add_prog_bonus(pat_mods)
				var g_skills_var: Variant = pat_mods.get("granted_skills", [])
				if g_skills_var is Array:
					for g_sk_v: Variant in g_skills_var:
						if g_sk_v is SkillData:
							_append_skill_if_missing(g_sk_v as SkillData)
		
		var bless_mods: Dictionary = god_state.compute_party_blessing_modifiers(party_data)
		if bool(bless_mods.get("active", false)):
			_add_prog_bonus(bless_mods)
			start_battle_barrier += int(bless_mods.get("start_barrier", 0))
			var b_names_var: Variant = bless_mods.get("blessing_names", [])
			if b_names_var is Array:
				for bn_v: Variant in b_names_var:
					active_blessing_names.append(str(bn_v))
	
	max_hp = maxi(1, stats.max_hp + _get_equipment_hp_bonus() + int(progression_stat_bonuses.get("max_hp", 0)))
	current_hp = clampi(roundi(float(max_hp) * clampf(hp_ratio_before, 0.01, 1.0)), 1, max_hp)

func _add_prog_bonus(src: Dictionary) -> void:
	progression_stat_bonuses["max_hp"] = int(progression_stat_bonuses.get("max_hp", 0)) + int(src.get("max_hp", 0))
	progression_stat_bonuses["attack"] = int(progression_stat_bonuses.get("attack", 0)) + int(src.get("attack", 0))
	progression_stat_bonuses["magic_power"] = int(progression_stat_bonuses.get("magic_power", 0)) + int(src.get("magic_power", 0))
	progression_stat_bonuses["defense"] = int(progression_stat_bonuses.get("defense", 0)) + int(src.get("defense", 0))
	progression_stat_bonuses["speed"] = int(progression_stat_bonuses.get("speed", 0)) + int(src.get("speed", 0))
	progression_stat_bonuses["crit_chance"] = float(progression_stat_bonuses.get("crit_chance", 0.0)) + float(src.get("crit_chance", 0.0))
	progression_stat_bonuses["crit_multiplier"] = float(progression_stat_bonuses.get("crit_multiplier", 0.0)) + float(src.get("crit_multiplier", 0.0))

func _append_skill_if_missing(sk: SkillData) -> void:
	if sk == null:
		return
	for existing: SkillData in skills:
		if existing != null and not sk.skill_id.is_empty() and existing.skill_id == sk.skill_id:
			return
	skills.append(sk)

func has_rune_seal(seal_id: StringName) -> bool:
	return active_seal_ids.has(seal_id)

func get_effective_skill_cost(skill: SkillData) -> int:
	if skill == null or skill.resource_cost <= 0:
		return 0
	if is_equal_approx(skill_cost_multiplier, 1.0):
		return skill.resource_cost
	return maxi(1, roundi(float(skill.resource_cost) * skill_cost_multiplier))

static func _get_resource_bounds_from_data(data: CombatantData, res_type: BattleTypes.ResourceType) -> Vector2i:
	match res_type:
		BattleTypes.ResourceType.MANA:
			return Vector2i(data.max_mana, data.initial_mana)
		BattleTypes.ResourceType.RAGE:
			return Vector2i(data.max_rage, data.initial_rage)
		BattleTypes.ResourceType.HAMINGJA:
			return Vector2i(data.max_hamingja, data.initial_hamingja)
		_:
			return Vector2i(data.max_energy, data.initial_energy)

## Создает runtime-бойца противника из ресурса EnemyData (с обратной совместимостью со старыми ресурсами)
static func from_enemy_data(data: EnemyData, p_runtime_id: String = "") -> Combatant:
	var c: Combatant = Combatant.new()
	if data == null:
		return c
	
	c.source_enemy_data = data
	var resolved_id: String = p_runtime_id.strip_edges()
	if resolved_id.is_empty():
		resolved_id = data.enemy_id.strip_edges()
	if resolved_id.is_empty():
		resolved_id = "enemy_legacy"
	c.runtime_id = resolved_id
	c.display_name = data.enemy_name if not data.enemy_name.strip_edges().is_empty() else "Противник"
	c.is_player_controlled = false
	c.is_hero = false
	c.sprite_color = data.sprite_color
	c.equipment_modifiers = data.equipment_modifiers.duplicate()
	
	if data.combat_stats != null:
		c.stats = data.combat_stats.create_copy()
	else:
		c.stats = CombatStatsData.new()
		c.stats.max_hp = maxi(1, data.max_hp)
		c.stats.attack = maxi(1, data.attack_power)
		c.stats.magic_power = maxi(1, data.attack_power)
		c.stats.defense = maxi(1, roundi(float(data.attack_power) * 0.3))
		c.stats.speed = 10
	
	c.max_hp = maxi(1, c.stats.max_hp + c._get_equipment_hp_bonus())
	if data.combat_stats == null and data.max_hp > 0 and data.current_hp > 0 and data.current_hp < data.max_hp:
		c.current_hp = clampi(data.current_hp, 1, c.max_hp)
	else:
		c.current_hp = c.max_hp
	
	c.max_resolve = maxi(1, data.max_resolve)
	c.current_resolve = clampi(data.current_resolve, 0, c.max_resolve)
	c.resolve_per_vow = data.resolve_per_vow
	
	if data.basic_attack != null:
		c.basic_attack = data.basic_attack
	else:
		c.basic_attack = _create_legacy_basic_attack(data, c.runtime_id)
	
	c.skills.clear()
	for sk: SkillData in data.skills:
		if sk != null:
			c.skills.append(sk)
	
	for res_type: BattleTypes.ResourceType in data.active_resources:
		var init_v: int = 50 if (res_type == BattleTypes.ResourceType.ENERGY or res_type == BattleTypes.ResourceType.HAMINGJA) else 0
		c.resources.configure_resource(res_type, 100, init_v, true)
	
	for part_data: EnemyPartData in data.parts:
		if part_data != null:
			c.parts.append(EnemyPartState.new(part_data))
	
	return c

## Создает базовый навык атаки для старых EnemyData без настроенного SkillData
static func _create_legacy_basic_attack(data: EnemyData, p_enemy_id: String) -> SkillData:
	var fallback: SkillData = SkillData.new()
	fallback.skill_id = "%s_legacy_attack" % p_enemy_id
	fallback.skill_name = "Выпад врага"
	fallback.description = "Базовая атака из классического ресурса EnemyData."
	fallback.action_category = BattleTypes.ActionType.ATTACK
	fallback.target_side = BattleTypes.TargetSide.ENEMY
	fallback.resource_type = BattleTypes.ResourceType.ENERGY
	fallback.resource_cost = 0
	fallback.damage_type = BattleTypes.DamageType.PHYSICAL
	var atk_power: int = data.attack_power if data != null else 10
	fallback.base_power = maxi(4, roundi(float(atk_power) * 0.6))
	fallback.power_multiplier = 1.0
	fallback.blockability = BattleTypes.Blockability.FULL_100
	fallback.requires_qte = false
	return fallback

## Создает снимок сохраняемого состояния (HP и Мана, если активна Мана; Энергия/Ярость/Хамингья/Напряжение сбрасываются)
func create_persistent_snapshot() -> Dictionary:
	var active_mana: bool = resources.has_resource(BattleTypes.ResourceType.MANA)
	return {
		"combatant_id": runtime_id,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"has_mana": active_mana,
		"current_mana": resources.get_current(BattleTypes.ResourceType.MANA) if active_mana else 0,
		"max_mana": resources.get_max(BattleTypes.ResourceType.MANA) if active_mana else 100
	}

func is_alive() -> bool:
	return current_hp > 0

func has_shield_equipped() -> bool:
	return equipment_loadout != null and equipment_loadout.has_shield_equipped()

func get_shield_defense_bonus() -> int:
	return equipment_loadout.get_shield_defense_bonus() if equipment_loadout != null else 0

func get_shield_block_chances() -> Dictionary:
	if equipment_loadout != null:
		return equipment_loadout.get_shield_block_chances()
	return {"has_shield": false, "enhanced_chance": 0.0, "full_chance": 0.0}

func get_base_attack_without_rage() -> int:
	var base_val: int = stats.attack + int(progression_stat_bonuses.get("attack", 0))
	if equipment_loadout != null:
		var bonuses: Dictionary = equipment_loadout.get_total_stat_bonuses()
		base_val += int(bonuses.get("attack", 0))
	for eq: EquipmentModifierStub in equipment_modifiers:
		if eq != null:
			base_val += eq.bonus_attack
	var atk_down: StatusEffectInstance = get_status(BattleTypes.StatusType.ATTACK_DOWN)
	if atk_down != null:
		var mult: float = clampf(1.0 - (0.25 * maxf(0.5, atk_down.magnitude)), 0.25, 1.0)
		base_val = roundi(float(base_val) * mult)
	return maxi(1, base_val)

func get_effective_attack() -> int:
	return maxi(1, roundi(float(get_base_attack_without_rage()) * resources.get_rage_attack_multiplier()))

func get_effective_magic() -> int:
	var base_val: int = stats.magic_power + int(progression_stat_bonuses.get("magic_power", 0))
	if equipment_loadout != null:
		var bonuses: Dictionary = equipment_loadout.get_total_stat_bonuses()
		base_val += int(bonuses.get("magic_power", 0))
	return maxi(1, base_val)

func get_effective_defense() -> int:
	var base_val: int = stats.defense + int(progression_stat_bonuses.get("defense", 0))
	if equipment_loadout != null:
		var bonuses: Dictionary = equipment_loadout.get_total_stat_bonuses()
		base_val += int(bonuses.get("defense", 0))
	for eq: EquipmentModifierStub in equipment_modifiers:
		if eq != null:
			base_val += eq.bonus_defense
	var def_down: StatusEffectInstance = get_status(BattleTypes.StatusType.DEFENSE_DOWN)
	if def_down != null:
		var shred_per_stack: int = maxi(2, roundi(float(maxi(4, base_val)) * 0.15 * maxf(0.5, def_down.magnitude)))
		base_val -= shred_per_stack * def_down.stacks
	return maxi(0, base_val)

func get_effective_speed() -> int:
	var base_val: int = stats.speed + int(progression_stat_bonuses.get("speed", 0))
	if equipment_loadout != null:
		var bonuses: Dictionary = equipment_loadout.get_total_stat_bonuses()
		base_val += int(bonuses.get("speed", 0))
	for eq: EquipmentModifierStub in equipment_modifiers:
		if eq != null:
			base_val += eq.bonus_speed
	base_val += resources.get_rage_speed_bonus()
	if has_status(BattleTypes.StatusType.SLOW):
		base_val -= maxi(2, roundi(float(maxi(4, base_val)) * 0.30))
	return maxi(1, base_val)

func acts_last() -> bool:
	return has_status(BattleTypes.StatusType.ACT_LAST)

func get_effective_crit_chance() -> float:
	var chance: float = stats.crit_chance + float(progression_stat_bonuses.get("crit_chance", 0.0))
	if equipment_loadout != null:
		var bonuses: Dictionary = equipment_loadout.get_total_stat_bonuses()
		chance += float(bonuses.get("crit_chance", 0.0))
	chance += resources.get_hamingja_crit_bonus()
	return clampf(chance, 0.0, 1.0)

func get_effective_crit_multiplier() -> float:
	var mult: float = stats.crit_multiplier + float(progression_stat_bonuses.get("crit_multiplier", 0.0))
	if equipment_loadout != null:
		var bonuses: Dictionary = equipment_loadout.get_total_stat_bonuses()
		mult += float(bonuses.get("crit_multiplier", 0.0))
	return maxf(1.0, mult)

func get_effective_qte_override() -> Dictionary:
	var base_ov: Dictionary = equipment_loadout.get_effective_qte_overrides() if equipment_loadout != null else {"has_override": false}
	var rune_perf_delta: float = float(progression_stat_bonuses.get("qte_perfect_delta", 0.0))
	if not is_zero_approx(rune_perf_delta):
		var merged: Dictionary = base_ov.duplicate()
		merged["has_override"] = true
		merged["perfect_delta"] = float(merged.get("perfect_delta", 0.0)) + rune_perf_delta
		return merged
	return base_ov

func has_passive_tag(tag: StringName) -> bool:
	if equipment_loadout == null or tag.is_empty():
		return false
	return equipment_loadout.get_passive_tags().has(tag)

## Возвращает список экипированных предметов ГГ, чья пороговая пассивка «Потока» активна прямо сейчас
func get_triggered_flow_threshold_items() -> Array[EquipmentItemData]:
	var result: Array[EquipmentItemData] = []
	if not is_hero or equipment_loadout == null or not resources.is_flow_mode:
		return result
	var flow_ratio: float = resources.get_flow_ratio()
	for eq: EquipmentItemData in equipment_loadout.get_flow_threshold_items():
		if flow_ratio >= eq.flow_threshold_ratio:
			result.append(eq)
	return result

## Переводит бойца в базовую стойку блока: восстанавливает Энергию (если активна) и снижает Ярость
func enter_block_stance(energy_gain: int = -1) -> int:
	is_blocking = true
	var restore_amt: int = energy_gain if energy_gain >= 0 else block_energy_restore
	var gained: int = resources.restore_resource(BattleTypes.ResourceType.ENERGY, restore_amt)
	resources.decay_rage_on_idle_or_block()
	if has_rune_seal(&"seal_isa"):
		apply_status(BattleTypes.StatusType.SHIELD_BARRIER, 2, runtime_id, 1.0, false, 1, false, 14)
	return gained

func clear_block_stance() -> void:
	is_blocking = false

## Снимает активные оружейные стойки (COVER_ALLY, PARRY_STANCE, INTERCEPT_MELEE)
func clear_weapon_stances() -> void:
	for st_type: BattleTypes.StatusType in [
		BattleTypes.StatusType.COVER_ALLY,
		BattleTypes.StatusType.PARRY_STANCE,
		BattleTypes.StatusType.INTERCEPT_MELEE
	]:
		if has_status(st_type):
			remove_status(st_type)

## Запускает подготовку (телеграф) спецатаки противника
func start_telegraph(skill: SkillData) -> void:
	if skill == null:
		return
	pending_telegraph_skill = skill
	telegraph_turns_left = maxi(1, skill.telegraph_turns)
	var warning: String = skill.telegraph_warning_text
	if warning.is_empty():
		warning = "%s готовит особую атаку «%s»!" % [display_name, skill.skill_name]
	telegraph_started.emit(skill, warning)

## Продвигает таймер телеграфа на 1 ход и возвращает готовый к применению навык (либо null)
func advance_telegraph() -> SkillData:
	if pending_telegraph_skill == null:
		return null
	telegraph_turns_left -= 1
	if telegraph_turns_left <= 0:
		var ready_skill: SkillData = pending_telegraph_skill
		clear_telegraph()
		return ready_skill
	return null

func clear_telegraph() -> void:
	if pending_telegraph_skill != null:
		pending_telegraph_skill = null
		telegraph_turns_left = 0
		telegraph_cleared.emit()

func is_telegraphing() -> bool:
	return pending_telegraph_skill != null and telegraph_turns_left > 0

## Накладывает или обновляет статус-эффект / стойку на бойце
func apply_status(
	status_type: BattleTypes.StatusType,
	duration_turns: int,
	source_id: String = "",
	magnitude: float = 1.0,
	guaranteed_crit: bool = false,
	stacks: int = 1,
	is_permanent: bool = false,
	barrier_hp: int = 0,
	protected_ally_id: String = ""
) -> void:
	if status_type == BattleTypes.StatusType.SLOW and has_rune_seal(&"seal_raidho"):
		return
	if BattleTypes.is_stance_status(status_type):
		clear_weapon_stances()
	
	# Повторная потеря равновесия переводит цель в падение (KNOCKED_DOWN)
	if status_type == BattleTypes.StatusType.UNBALANCED and has_status(BattleTypes.StatusType.UNBALANCED):
		remove_status(BattleTypes.StatusType.UNBALANCED)
		status_type = BattleTypes.StatusType.KNOCKED_DOWN
		duration_turns = maxi(1, duration_turns)
	
	var existing: StatusEffectInstance = get_status(status_type)
	if existing != null:
		if StatusEffectInstance.is_stackable_type(status_type):
			existing.is_permanent_in_battle = existing.is_permanent_in_battle or is_permanent
			existing.add_stacks(stacks, duration_turns, magnitude)
		elif status_type == BattleTypes.StatusType.SHIELD_BARRIER:
			existing.remaining_turns = maxi(existing.remaining_turns, duration_turns)
			existing.barrier_hp = maxi(existing.barrier_hp, barrier_hp)
		else:
			existing.remaining_turns = maxi(existing.remaining_turns, duration_turns)
			existing.magnitude = maxf(existing.magnitude, magnitude)
			existing.is_permanent_in_battle = existing.is_permanent_in_battle or is_permanent
			if not protected_ally_id.is_empty():
				existing.protected_ally_id = protected_ally_id
		existing.source_combatant_id = source_id
		existing.guaranteed_crit_against = existing.guaranteed_crit_against or guaranteed_crit
	else:
		var inst: StatusEffectInstance = StatusEffectInstance.new(
			status_type,
			duration_turns,
			source_id,
			magnitude,
			guaranteed_crit,
			stacks,
			is_permanent,
			barrier_hp,
			protected_ally_id
		)
		statuses.append(inst)
		if inst.is_control_status():
			resources.decay_rage_on_control_status()
	
	if (
		status_type == BattleTypes.StatusType.STAGGER
		or status_type == BattleTypes.StatusType.FREEZE
		or status_type == BattleTypes.StatusType.STUN
		or status_type == BattleTypes.StatusType.KNOCKED_DOWN
	):
		clear_block_stance()
		clear_weapon_stances()
		clear_telegraph()
	
	status_applied.emit(status_type)

func remove_status(status_type: BattleTypes.StatusType) -> void:
	for i: int in range(statuses.size() - 1, -1, -1):
		if statuses[i].status_type == status_type:
			statuses.remove_at(i)
			status_removed.emit(status_type)

func has_status(status_type: BattleTypes.StatusType) -> bool:
	return get_status(status_type) != null

func get_status(status_type: BattleTypes.StatusType) -> StatusEffectInstance:
	for st: StatusEffectInstance in statuses:
		if st.status_type == status_type:
			return st
	return null

func get_shield_barrier_hp() -> int:
	var st: StatusEffectInstance = get_status(BattleTypes.StatusType.SHIELD_BARRIER)
	return st.barrier_hp if st != null else 0

## Обрабатывает периодический урон (BURN, BLEED со стаками, POISON) в конце раунда
func process_end_of_round_dots() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not is_alive():
		return events
	
	for st: StatusEffectInstance in statuses.duplicate():
		if not is_alive():
			break
		var dot_dmg: int = 0
		match st.status_type:
			BattleTypes.StatusType.BURN:
				dot_dmg = maxi(4, roundi(float(max_hp) * 0.06 * maxf(0.5, st.magnitude)))
			BattleTypes.StatusType.BLEED:
				var per_stack: int = maxi(3, roundi(float(max_hp) * 0.04 * maxf(0.5, st.magnitude)))
				dot_dmg = per_stack * maxi(1, st.stacks)
			BattleTypes.StatusType.POISON:
				dot_dmg = maxi(4, roundi(float(max_hp) * 0.05 * maxf(0.5, st.magnitude)))
		if dot_dmg > 0:
			var res: Dictionary = take_damage(dot_dmg, null, false)
			events.append({
				"status_type": st.status_type,
				"damage": int(res.get("damage_taken", 0)),
				"absorbed": int(res.get("absorbed_by_barrier", 0)),
				"stacks": st.stacks
			})
	return events

## Снимает временные статусы, наложенные указанным источником после его гибели
func clear_statuses_from_source(source_id: String) -> void:
	if source_id.is_empty():
		return
	for i: int in range(statuses.size() - 1, -1, -1):
		if statuses[i].source_combatant_id == source_id and not statuses[i].is_permanent_in_battle:
			var removed_type: BattleTypes.StatusType = statuses[i].status_type
			statuses.remove_at(i)
			status_removed.emit(removed_type)

## Обновляет длительности всех статусов в конце раунда и возвращает список истекших
func tick_statuses() -> Array[BattleTypes.StatusType]:
	var expired: Array[BattleTypes.StatusType] = []
	for i: int in range(statuses.size() - 1, -1, -1):
		var st: StatusEffectInstance = statuses[i]
		if st.tick_turn():
			statuses.remove_at(i)
			expired.append(st.status_type)
			status_removed.emit(st.status_type)
	return expired

func is_staggered() -> bool:
	return has_status(BattleTypes.StatusType.STAGGER)

func is_incapacitated() -> bool:
	for st: StatusEffectInstance in statuses:
		if st.causes_turn_skip():
			return true
	return false

func get_incapacitation_reason() -> String:
	if has_status(BattleTypes.StatusType.FREEZE):
		return "заморожен"
	if has_status(BattleTypes.StatusType.STUN):
		return "оглушён"
	if has_status(BattleTypes.StatusType.KNOCKED_DOWN):
		return "сбит с ног"
	if has_status(BattleTypes.StatusType.SLEEP):
		return "спит"
	return "ошеломлён"

func is_hypnotized() -> bool:
	return has_status(BattleTypes.StatusType.HYPNOSIS)

func can_evade() -> bool:
	return not is_incapacitated() and not has_status(BattleTypes.StatusType.TETHERED)

func get_taunt_source_id() -> String:
	var taunt_st: StatusEffectInstance = get_status(BattleTypes.StatusType.TAUNT)
	return taunt_st.source_combatant_id if taunt_st != null else ""

func get_no_guard_status() -> StatusEffectInstance:
	return get_status(BattleTypes.StatusType.NO_GUARD)

## Возвращает доступные для атаки части тела многосоставного врага
func get_targetable_parts() -> Array[EnemyPartState]:
	var result: Array[EnemyPartState] = []
	var staggered: bool = is_staggered() or has_status(BattleTypes.StatusType.KNOCKED_DOWN)
	var telegraphing: bool = is_telegraphing()
	for part: EnemyPartState in parts:
		if part.is_targetable(staggered, telegraphing):
			result.append(part)
	return result

func get_part_by_id(part_id: String) -> EnemyPartState:
	for part: EnemyPartState in parts:
		if part.data != null and part.data.part_id == part_id:
			return part
	return null

## Применяет урон с учетом SHIELD_BARRIER и выбранной части тела
func take_damage(raw_amount: int, target_part: EnemyPartState = null, grant_rage: bool = true) -> Dictionary:
	var actual_hp_damage: int = maxi(0, raw_amount)
	var part_broke_now: bool = false
	var triggered_stagger: bool = false
	var broken_part_id: String = ""
	var absorbed_by_barrier: int = 0
	
	if target_part != null and target_part.data != null:
		var part_dmg: int = actual_hp_damage
		actual_hp_damage = maxi(0, roundi(float(actual_hp_damage) * target_part.data.shared_hp_transfer_ratio))
		if target_part.apply_part_damage(part_dmg):
			part_broke_now = true
			broken_part_id = target_part.data.part_id
			part_broken.emit(broken_part_id)
			if target_part.data.triggers_stagger_on_break:
				triggered_stagger = true
				apply_status(
					BattleTypes.StatusType.STAGGER,
					target_part.data.stagger_duration_turns,
					runtime_id
				)
	
	var barrier_st: StatusEffectInstance = get_status(BattleTypes.StatusType.SHIELD_BARRIER)
	if barrier_st != null and barrier_st.barrier_hp > 0 and actual_hp_damage > 0:
		absorbed_by_barrier = mini(actual_hp_damage, barrier_st.barrier_hp)
		barrier_st.barrier_hp -= absorbed_by_barrier
		actual_hp_damage -= absorbed_by_barrier
		if barrier_st.barrier_hp <= 0:
			remove_status(BattleTypes.StatusType.SHIELD_BARRIER)
	
	var prev_hp: int = current_hp
	current_hp = maxi(0, current_hp - actual_hp_damage)
	var survived_by_eihwaz: bool = false
	if prev_hp > 0 and current_hp == 0 and eihwaz_death_ward_ready:
		eihwaz_death_ward_ready = false
		current_hp = 1
		survived_by_eihwaz = true
	var applied_damage: int = prev_hp - current_hp
	
	if applied_damage > 0:
		if grant_rage:
			resources.add_rage_on_damage_taken()
		hp_changed.emit(current_hp, max_hp)
		if has_status(BattleTypes.StatusType.SLEEP):
			remove_status(BattleTypes.StatusType.SLEEP)
	
	if prev_hp > 0 and current_hp == 0:
		died.emit(self)
	
	return {
		"damage_taken": applied_damage,
		"absorbed_by_barrier": absorbed_by_barrier,
		"part_broken": part_broke_now,
		"broken_part_id": broken_part_id,
		"triggered_stagger": triggered_stagger,
		"survived_by_eihwaz": survived_by_eihwaz
	}

## Восстанавливает здоровье (внешнее лечение снижает Ярость; самолечение сжигает часть Ярости)
func heal_hp(amount: int, is_external: bool = true, burn_rage_if_self: bool = true) -> int:
	if amount <= 0 or not is_alive():
		return 0
	var boosted_amount: int = roundi(float(amount) * 1.25) if has_rune_seal(&"seal_berkana") else amount
	var prev_hp: int = current_hp
	current_hp = mini(max_hp, current_hp + boosted_amount)
	var healed: int = current_hp - prev_hp
	if healed > 0:
		hp_changed.emit(current_hp, max_hp)
	if is_external:
		resources.decay_rage_on_external_heal()
	elif burn_rage_if_self:
		resources.burn_rage_on_self_heal()
	return healed

## Возвращает павшего союзника в строй с указанным здоровьем
func revive_hp(amount: int) -> int:
	if is_alive():
		return heal_hp(amount, true, false)
	current_hp = clampi(maxi(1, amount), 1, max_hp)
	hp_changed.emit(current_hp, max_hp)
	return current_hp

## Legacy-метод шкалы Завета (оставлен для совместимости, в активном боевом цикле не используется)
func add_resolve(amount: int) -> int:
	if amount <= 0:
		return 0
	var prev_val: int = current_resolve
	current_resolve = mini(max_resolve, current_resolve + amount)
	var gained: int = current_resolve - prev_val
	if gained > 0:
		resolve_changed.emit(current_resolve, max_resolve)
	return gained

func is_pacified() -> bool:
	return false

## Делегирует восполнение ресурса в ResourcePool
func restore_resource(res_type: BattleTypes.ResourceType, amount: int) -> int:
	return resources.restore_resource(res_type, amount)

## Возвращает модификатор уязвимости/сопротивления от исходных данных врага
func get_damage_type_multiplier(damage_type: BattleTypes.DamageType) -> float:
	if source_enemy_data != null:
		return source_enemy_data.get_damage_type_modifier(damage_type)
	return 1.0

func _get_equipment_hp_bonus() -> int:
	var total: int = 0
	if equipment_loadout != null:
		var bonuses: Dictionary = equipment_loadout.get_total_stat_bonuses()
		total += int(bonuses.get("max_hp", 0))
	for eq: EquipmentModifierStub in equipment_modifiers:
		if eq != null:
			total += eq.bonus_max_hp
	return total
