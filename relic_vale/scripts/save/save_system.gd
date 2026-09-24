class_name ValeSave
extends RefCounted
## Versioned, local JSON. Write/flush a temporary file, then replace with a recoverable backup.
const VERSION: int=9
const PATH: String="user://journey.json"
static var last_error: String=""

static func snapshot(player_position: Vector3) -> Dictionary:
	var data: Dictionary=base_snapshot(player_position)
	data.map_data=State.map_data.duplicate(true); data.camp_data=State.camp_data.duplicate(true)
	data.professions=State.professions.duplicate(true); data.activities=State.activities.duplicate(true)
	data.narrative=State.narrative.duplicate(true)
	return data

static func base_snapshot(player_position: Vector3) -> Dictionary:
	return {"world":State.world_data.duplicate(true),"resource_states":State.resource_states.duplicate(true),"residents":State.residents.duplicate(true),"interior_data":State.interior_data.duplicate(true),"life":State.life_data.duplicate(true),"version":VERSION,"generated_items":State.generated_items.duplicate(true),"pending_loot":State.pending_loot.duplicate(true),"abilities":State.abilities.duplicate(),"character_name":State.character_name,"appearance":State.appearance.duplicate(),"appearance_confirmed":State.appearance_confirmed,"audio_settings":State.audio_settings.duplicate(),"saved_at":Time.get_datetime_string_from_system(true),"position":[player_position.x,player_position.y,player_position.z],"world_seed":State.world_seed,"level":State.level,"xp":State.xp,"hp":State.hp,"stats":State.stats(),"coins":State.coins,"astral_shards":State.astral_shards,"inventory":State.inventory.duplicate(true),"equipment":State.equipment.duplicate(true),"flags":State.flags.duplicate(true),"kills":State.kills,"quest_progress":State.quest_progress.duplicate(true),"completed_quests":State.completed_quests.duplicate(true),"opened_chests":State.opened_chests.duplicate(true),"discoveries":State.discoveries.duplicate(true),"gathered_resources":State.gathered_resources.duplicate(true),"defeated_unique":State.defeated_unique.duplicate(true),"dungeon_return":[State.dungeon_return.x,State.dungeon_return.y,State.dungeon_return.z],"attack_count":State.attack_count}

static func write(position: Vector3, path: String = PATH) -> bool:
	last_error=""
	var data: Dictionary=snapshot(position)
	if not valid(data):
		last_error="The journey could not be validated. Your previous save was kept."
		return false
	if not ValeChunkDeltas.pack(data,path):
		last_error="Could not write world changes."
		return false
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:
		last_error="Could not open the save folder."
		return false
	file.store_string(JSON.stringify(data,"\t"))
	file.flush()
	var error: Error=file.get_error()
	file.close()
	if error!=OK:
		last_error="The save could not be written."
		return false
	# Validate the actual bytes and every referenced chunk before replacing anything.
	if checked_read(path+".tmp",path).is_empty():
		last_error="Save verification failed. Your previous save was kept."
		return false
	if not checked_read(path,path).is_empty():
		if DirAccess.copy_absolute(path,path+".bak.tmp")!=OK or checked_read(path+".bak.tmp",path).is_empty() or DirAccess.rename_absolute(path+".bak.tmp",path+".bak")!=OK:
			last_error="Could not create the save backup."
			return false
	if DirAccess.rename_absolute(path+".tmp",path)!=OK:
		last_error="Could not replace the save file."
		return false
	ValeChunkDeltas.prune(path)
	return true

static func valid(data: Variant) -> bool:
	if not data is Dictionary or not whole(data.get("version"),2,VERSION) or int(data.version) not in [2,3,4,5,6,7,8,VERSION]: return false
	if not finite_tree(data): return false
	if not ValePhase7Save.valid(data): return false
	if not ValePhase8Save.valid(data): return false
	if not ValePhase9Save.valid(data): return false
	if not data.get("world",{}) is Dictionary: return false
	var world: Dictionary=data.get("world",{})
	for key in ["origin_x","origin_z"]:
		if not valid_coordinate(world.get(key,"0")): return false
	if not world.get("name","") is String or not world.get("discovered",{}) is Dictionary: return false
	var playtime: Variant=world.get("playtime",0)
	if not number(playtime,0,1e12): return false
	for key in world.get("discovered",{}):
		if not ValeChunkDeltas.valid_map(world.discovered[key]): return false
	for key in ["resource_states","residents","interior_data","life","generated_items","pending_loot","appearance","audio_settings"]:
		if not data.get(key,{}) is Dictionary: return false
	var life: Dictionary=data.get("life",{})
	for key in ["reputation","unlocks","stock","dungeons","settlements","events"]:
		if not life.get(key,{}) is Dictionary: return false
	for key in ["minute","day","weather_block"]:
		var value: Variant=life.get(key,0)
		if not (value is int or value is float) or not is_finite(float(value)): return false
	for key in ["reputation","stock"]:
		for value in life.get(key,{}).values():
			if not (value is int or value is float): return false
	for key in life.get("dungeons",{}):
		if not life.dungeons[key] is Dictionary: return false
	if not data.get("abilities",[]) is Array: return false
	if not data.get("character_name","") is String: return false
	for recipe in data.get("generated_items",{}).values():
		if not recipe is Dictionary or not recipe.get("affixes",[]) is Array: return false
	for record in data.get("pending_loot",{}).values():
		if not record is Dictionary or not record.get("bundle",{}) is Dictionary: return false
		if record.has("address") and not valid_address(record.address): return false
		if not record.get("position",[]) is Array or record.position.size()!=3: return false
		for value in record.position:
			if not (value is int or value is float) or not is_finite(float(value)): return false
		if not record.bundle.get("items",{}) is Dictionary: return false
		if not (record.bundle.get("coins",0) is int or record.bundle.get("coins",0) is float): return false
		for value in record.bundle.get("items",{}).values():
			if not (value is int or value is float): return false
	for key in ["inventory","equipment","flags","quest_progress","completed_quests","opened_chests","discoveries","gathered_resources","defeated_unique"]:
		if not data.get(key,{}) is Dictionary: return false
	for key in ["position","dungeon_return"]:
		var values: Variant=data.get(key,[])
		if not values is Array or values.size()!=3: return false
		for value in values:
			if not (value is int or value is float) or not is_finite(float(value)): return false
	for key in ["level","xp","hp","coins","astral_shards","world_seed","kills","attack_count"]:
		if not whole(data.get(key),1 if key=="level" else 0,100 if key=="level" else 2147483647): return false
	for count in data.inventory.values():
		if not whole(count,0,2147483647): return false
	for id in data.equipment.values():
		if not id is String: return false
	for count in data.get("quest_progress",{}).values():
		if not whole(count,0,2147483647): return false
	for key in ["flags","completed_quests","opened_chests","discoveries","gathered_resources","defeated_unique"]:
		for value in data.get(key,{}).values():
			if not value is bool: return false
	if not valid_village(data): return false
	return true

static func number(value: Variant,minimum: float,maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and float(value)<=maximum

static func whole(value: Variant,minimum: float,maximum: float) -> bool:
	return number(value,minimum,maximum) and float(value)==floorf(float(value))

static func finite_tree(value: Variant,depth: int=0) -> bool:
	if depth>32: return false
	if value is float: return is_finite(value)
	if value is Dictionary:
		for item in value.values():
			if not finite_tree(item,depth+1): return false
	elif value is Array:
		for item in value:
			if not finite_tree(item,depth+1): return false
	return true

static func valid_coordinate(value: Variant) -> bool:
	# Decimal strings preserve logical precision; leave ample headroom for neighbor arithmetic.
	return value is String and value.is_valid_int() and value.length()<=17 and absf(float(value))<=9e15

static func checked_read(candidate: String,chunk_path: String) -> Dictionary:
	if not FileAccess.file_exists(candidate): return {}
	var json:=JSON.new()
	if json.parse(FileAccess.get_file_as_string(candidate))!=OK or not valid(json.data): return {}
	if int(json.data.version)>=5 and not ValeChunkDeltas.unpack(json.data,chunk_path): return {}
	if not valid(json.data): return {}
	return json.data

static func valid_village(data: Dictionary) -> bool:
	for record in data.get("resource_states",{}).values():
		if not record is Dictionary: return false
		for key in ["hits","respawn_day"]:
			var value: Variant=record.get(key,0)
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0: return false
	for record in data.get("residents",{}).values():
		if not record is Dictionary or not record.get("identity",{}) is Dictionary: return false
		for key in ["id","npc_id","settlement","home","work","tavern"]:
			if not record.get(key,"") is String: return false
		for key in ["name","role","dialogue"]:
			if not record.identity.get(key,"") is String: return false
		if record.identity.has("category") and not State.merchant_data.has(record.identity.category): return false
	var interior: Dictionary=data.get("interior_data",{})
	if not interior.get("storage",{}) is Dictionary: return false
	for container in interior.get("storage",{}).values():
		if not container is Dictionary: return false
		for id in container:
			var amount: Variant=container[id]
			if not State.items.has(id) and not data.get("generated_items",{}).has(id): return false
			if not (amount is int or amount is float) or not is_finite(float(amount)) or float(amount)<1 or float(amount)>99999: return false
	if interior.has("active"):
		var active: Variant=interior.active
		if not active is Dictionary or not valid_address(active.get("return",{})): return false
		if not valid_building(active.get("building",{})): return false
		if not active.get("camera",{}) is Dictionary: return false
		for value in active.get("camera",{}).values():
			if not (value is int or value is float) or not is_finite(float(value)): return false
	for settlement in data.get("life",{}).get("settlements",{}).values():
		if not settlement is Dictionary or not settlement.get("buildings",{}) is Dictionary: return false
		for building in settlement.get("buildings",{}).values():
			if not valid_building(building): return false
	return true

static func valid_building(record: Variant) -> bool:
	if not record is Dictionary: return false
	for key in ["id","settlement","template","title"]:
		if not record.get(key,0) is String: return false
	return record.template in ["house","shop","blacksmith","tavern","alchemist"] and valid_address(record.get("door",{}))

static func read(path: String = PATH) -> Dictionary:
	last_error=""
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(path+".bak"):
		last_error="No saved journey yet."
		return {}
	for candidate in [path,path+".bak"]:
		var data: Dictionary=checked_read(candidate,path)
		if not data.is_empty():
			if candidate!=path: last_error="Recovered the previous save from backup."
			return data
	last_error="Save format is damaged or from an unsupported version. Your current journey was kept."
	return {}

static func vector(values: Array) -> Vector3:
	return Vector3(float(values[0]),float(values[1]),float(values[2]))

static func valid_address(address: Variant) -> bool:
	if not address is Dictionary: return false
	for key in ["x","z"]:
		if not valid_coordinate(address.get(key,"")): return false
	if not address.get("local",[]) is Array or address.local.size()!=3: return false
	for value in address.local:
		if not (value is float or value is int) or not is_finite(float(value)): return false
	return true

static func safe_position(pos: Vector3) -> Vector3:
	if pos.x>=2993 and pos.x<=3007 and absf(pos.z)<=6: return Vector3(pos.x,clampf(pos.y,0,2),pos.z)
	if pos.x>=1990 and pos.x<=2150 and pos.z>=-100 and pos.z<=100: return Vector3(pos.x,clampf(pos.y,-2,8),pos.z)
	if pos.x>=992 and pos.x<=1008 and pos.z>=-48 and pos.z<=10: return Vector3(pos.x,clampf(pos.y,0,3),pos.z)
	if pos.x>=-256 and pos.x<=256 and pos.z>=-256 and pos.z<=256: return Vector3(pos.x,clampf(pos.y,-3,20),pos.z)
	return Vector3(0,0,3.6)

static func apply(data: Dictionary) -> Vector3:
	State.reset_progress(int(data.world_seed))
	State.professions.merge(data.get("professions",{}).duplicate(true),true)
	State.activities.merge(data.get("activities",{}).duplicate(true),true)
	State.narrative.merge(data.get("narrative",{}).duplicate(true),true)
	State.map_data=data.get("map_data",{"markers":{},"next_id":1}).duplicate(true)
	State.camp_data=data.get("camp_data",{}).duplicate(true)
	State.world_data.merge(data.get("world",{}),true)
	State.resource_states=data.get("resource_states",{}).duplicate(true)
	State.residents=data.get("residents",{}).duplicate(true)
	State.interior_data=data.get("interior_data",{}).duplicate(true)
	var life: Dictionary=data.get("life",{})
	for key in ["reputation","unlocks","stock","dungeons","settlements","events"]:
		if life.get(key,{}) is Dictionary: State.life_data[key]=life.get(key,State.life_data[key]).duplicate(true)
	for faction in State.faction_data: State.life_data.reputation[faction]=clampi(int(State.life_data.reputation.get(faction,0)),-100,100)
	State.life_data.minute=clampf(float(life.get("minute",540)),0,1439.99)
	State.life_data.day=maxi(1,int(life.get("day",1)))
	State.life_data.weather=life.get("weather","Clear") if life.get("weather","Clear") in ValeLife.WEATHER else "Clear"
	State.life_data.weather_block=int(life.get("weather_block",-1))
	State.level=clampi(int(data.level),1,100)
	State.xp=maxi(0,int(data.xp))
	while State.xp>=State.level*60 and State.level<100:
		State.xp-=State.level*60
		State.level+=1
	State.xp=mini(State.xp,State.level*60-1)
	for id in data.get("generated_items",{}): ValeGear.materialize(str(id),data.generated_items[id])
	State.next_item_id=1
	for id in State.generated_items: State.next_item_id=maxi(State.next_item_id,int(str(id).trim_prefix("gear_"))+1)
	for id in data.get("pending_loot",{}):
		var record: Dictionary=data.pending_loot[id].duplicate(true)
		var pos:=safe_position(vector(record.position))
		record.position=[pos.x,pos.y,pos.z]
		record.bundle.coins=clampi(int(record.bundle.get("coins",0)),0,999999)
		for item_id in record.bundle.items.keys():
			if item_id!="astral_shard" and not State.items.has(item_id): record.bundle.items.erase(item_id)
			else: record.bundle.items[item_id]=clampi(int(record.bundle.items[item_id]),1,9999)
		State.pending_loot[str(id)]=record
		State.next_loot_id=maxi(State.next_loot_id,int(str(id).trim_prefix("drop_"))+1)
	for slot in mini(2,data.get("abilities",[]).size()):
		if data.abilities[slot] is String: State.set_ability(slot,data.abilities[slot])
	State.character_name=str(data.get("character_name","Traveler")).strip_edges().substr(0,20)
	if State.character_name.is_empty(): State.character_name="Traveler"
	State.appearance=PixelArt.clean_appearance(data.get("appearance",{}))
	State.appearance_confirmed=bool(data.get("appearance_confirmed",true))
	for bus in State.audio_settings:
		Feel.volume(bus,float(Preferences.values[bus]))
	State.inventory.clear()
	for id in data.inventory:
		if State.items.has(id) and int(data.inventory[id])>0: State.inventory[id]=int(data.inventory[id])
	for slot in State.equipment:
		var id: String=data.equipment.get(slot,"")
		State.equipment[slot]=id if State.inventory.has(id) and State.items.get(id,{}).get("slot","")==slot else ""
	for key in State.flags: State.flags[key]=bool(data.flags.get(key,false))
	for key in ["coins","astral_shards","kills","attack_count"]: State.set(key,int(data.get(key,0)))
	for key in ["completed_quests","opened_chests","discoveries","gathered_resources","defeated_unique"]:
		var clean: Dictionary={}
		for id in data.get(key,{}):
			if data[key][id]==true: clean[str(id)]=true
		State.set(key,clean)
	for id in data.get("quest_progress",{}):
		if State.quest_data.has(id): State.quest_progress[id]=clampi(int(data.quest_progress[id]),0,int(State.quest_data[id].count))
	State.recalculate()
	State.hp=clampi(int(data.hp),1,State.max_hp)
	State.dungeon_return=safe_position(vector(data.dungeon_return))
	if State.dungeon_return.x>900: State.dungeon_return=Vector3(37,0,-18)
	State.changed.emit()
	return safe_position(vector(data.position))
