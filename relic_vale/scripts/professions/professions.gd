class_name ValeProfessions
extends RefCounted
## Independent personal progress. Workers never call award().
static var definitions: Dictionary={}
static var fish: Dictionary={}
static var crops: Dictionary={}
static var motion: Dictionary={}

static func defaults() -> Dictionary:
	var result: Dictionary={}
	for id in ["woodcutting","mining","herbalism","fishing","cooking","farming"]: result[id]={"level":1,"xp":0,"unlocks":[]}
	return result

static func activity_defaults() -> Dictionary:
	return {"fish_journal":{},"casts":0,"bait":"bait_basic","farm":{},"food":{},"mounts":{},"active_mount":"","treasures":{},"next_treasure":1,"rare_notes":{},"production":{},"weather_history":[],"weather_last":-1.0}

static func install() -> void:
	definitions=JSON.parse_string(FileAccess.get_file_as_string("res://data/professions.json"))
	fish=JSON.parse_string(FileAccess.get_file_as_string("res://data/fish.json"))
	crops=JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	motion=JSON.parse_string(FileAccess.get_file_as_string("res://data/profession_motion.json"))
	State.items.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/phase8_items.json")),true)
	for id in State.items: State.items[id].color=State.RARITY_COLORS[State.items[id].rarity]
	State.resource_data.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/profession_resources.json")),true)
	for id in State.resource_data:
		var row: Dictionary=State.resource_data[id]
		if not row.has("profession"): row.profession="woodcutting" if row.tool=="axe" else ("mining" if row.tool=="pickaxe" else "herbalism")
		if not row.has("xp"): row.xp=8+int(row.hits)*3
	for recipe in JSON.parse_string(FileAccess.get_file_as_string("res://data/cooking.json")): State.crafting_data[recipe.id]=recipe
	for group in ["general","traveling","carpenter"]:
		if not State.merchant_data.has(group): continue
		for id in ["fishing_rod_1","bait_basic","bait_insect","watering_can","seed_carrot","seed_beet"]: offer(group,id)
	State.merchant_data["fisher"]={"faction":"hearth","offers":[]}
	State.merchant_data["farmer"]={"faction":"bough","offers":[]}
	State.npc_data["willow_fisher"]={"name":"Iona","role":"Fishing merchant","category":"fisher","shop":true,"dialogue":"Dough catches the everyday fish. Insects bring quicker bites; moon bait tempts the rare ones. Face open water from a dry bank and watch your float."}
	State.npc_data["willow_farmer"]={"name":"Nell","role":"Seed merchant","category":"farmer","shop":true,"dialogue":"Prepare a bed, plant a seed and keep it moist. Rain is a gardener's friend. I sell seeds for every season of your skill."}
	for id in ["fishing_rod_1","fishing_rod_2","fishing_rod_3","bait_basic","bait_insect","bait_rare"]: offer("fisher",id)
	for id in crops: offer("farmer",crops[id].seed)
	offer("farmer","watering_can")
	offer("farmer","raw_meat")
	for group in ["tavern","general"]:
		if not State.merchant_data.has(group): continue
		for id in ["meal_grilled_fish","meal_roast_meat","meal_forest_bites"]: offer(group,id)
		for id in ["cook_harvest_pie","cook_elder_roast"]: State.merchant_data[group].offers.append(["recipe:"+id,85])
	State.base_items=State.items.duplicate(true)
	if State.loot_tables.has("wolf"): State.loot_tables.wolf.drops.append({"id":"raw_meat","chance":.7})
	for id in ["skeleton","elite","guardian"]:
		if State.loot_tables.has(id): State.loot_tables[id].drops.append({"id":"map_fragment","chance":.06})

static func offer(group: String,id: String) -> void:
	State.merchant_data[group].offers.append([id,State.items[id].base_price])

static func level(id: String) -> int: return int(State.professions.get(id,{}).get("level",1))
static func needed(id: String,at_level: int=-1) -> int:
	var value: int=level(id) if at_level<0 else at_level
	var row: Dictionary=definitions[id]
	return int(row.xp_base)+value*int(row.xp_linear)+value*value*int(row.xp_square)

static func award(id: String,amount: int) -> void:
	if not definitions.has(id) or amount<=0 or level(id)>=25: return
	var row: Dictionary=State.professions[id]
	row.xp+=maxi(1,roundi(amount*(1.0+food_bonus("profession_xp"))))
	var old: int=level(id)
	while int(row.xp)>=needed(id) and level(id)<25:
		row.xp-=needed(id); row.level+=1
		for unlock in definitions[id].unlocks:
			if int(unlock.level)==level(id) and not unlock.name in row.unlocks: row.unlocks.append(unlock.name)
	if level(id)>=25: row.xp=0
	if level(id)>old: State.notification.emit("%s %d · %s" % [definitions[id].name,level(id),next_unlock(id)])
	State.changed.emit()

static func next_unlock(id: String) -> String:
	for unlock in definitions[id].unlocks:
		if int(unlock.level)>level(id): return "Next at %d: %s" % [unlock.level,unlock.name]
	return "Mastery grows to level 25"

static func set_level(id: String,value: int) -> void:
	State.professions[id]={"level":clampi(value,1,25),"xp":0,"unlocks":[]}
	for unlock in definitions[id].unlocks:
		if int(unlock.level)<=level(id): State.professions[id].unlocks.append(unlock.name)
	State.changed.emit()

static func condition_ok(condition: String) -> bool:
	var hour: float=float(State.life_data.minute)/60
	if condition in ["","any"]: return true
	if condition=="night": return hour<5 or hour>=20
	if condition=="day": return hour>=7 and hour<19
	if condition=="dawn": return hour>=5 and hour<8
	return State.life_data.weather==condition

static func gathering_error(row: Dictionary,tool: Dictionary) -> String:
	var id: String=row.get("profession","herbalism")
	if level(id)<int(row.get("min_level",1)): return "%s %d required" % [definitions[id].name,row.min_level]
	if int(tool.get("tier",0))<int(row.get("tool_tier",0)): return "Tool tier %d required" % row.tool_tier
	if not condition_ok(row.get("condition","any")): return "Available during "+str(row.condition)
	return ""

static func gather_speed(id: String) -> float: return 1.0+(.1 if level(id)>=15 else 0.0)+food_bonus("gather_speed")
static func yield_bonus(id: String,rng: RandomNumberGenerator) -> int:
	return 1 if rng.randf()<(0.05 if level(id)>=5 else 0.0)+(0.05 if level(id)>=20 else 0.0) else 0

static func food_bonus(stat: String) -> float:
	var food: Dictionary=State.activities.get("food",{})
	return float(food.get("value",0)) if food.get("stat","")==stat and float(food.get("end",0))>ValeCamp.now() else 0.0

static func eat(id: String) -> void:
	var item: Dictionary=State.items[id]
	if not item.has("food"): return
	State.activities.food=item.food.duplicate(true)
	State.activities.food.end=ValeCamp.now()+float(item.food.minutes)
	State.activities.food.item=id
	State.recalculate()
	State.notification.emit(item.name+" · "+item.food.stat.replace("_"," ")+" refreshed")

static func tool_motion(clip: String,fraction: float) -> float:
	var samples: Array=motion.clips[clip].samples
	var index: float=clampf(fraction,0,1)*(samples.size()-1)
	var first: int=floori(index); var second: int=mini(samples.size()-1,first+1)
	return lerpf(float(samples[first][1]),float(samples[second][1]),index-first)
