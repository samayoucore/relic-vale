extends Node
## Progression, computed equipment stats, quest events and UI signals. Serialized by ValeSave.
signal changed
signal notification(message: String)
signal conversation(speaker: String, message: String)
signal enemy_defeated
signal shrine_requested
signal cooldown_reset
signal save_requested
signal appearance_changed
signal objective_event(kind: String, target: String, amount: int)
const RARITY_COLORS: Dictionary={"Common":"c8cdb6","Uncommon":"9ac989","Rare":"8ecbdc","Epic":"c5a0e0","Legendary":"ecc276"}

var life_data: Dictionary=ValeLife.defaults()
var map_data: Dictionary={"markers":{},"next_id":1}
var camp_data: Dictionary={}
var professions: Dictionary=ValeProfessions.defaults()
var activities: Dictionary=ValeProfessions.activity_defaults()
var narrative: Dictionary=ValeNarrative.defaults()
var world_data: Dictionary={"origin_x":"0","origin_z":"0","name":"The Lower Vale","playtime":0.0,"discovered":{}}
var faction_data: Dictionary={}
var merchant_data: Dictionary={}
var crafting_data: Dictionary={}
var hp: int = 100
var max_hp: int = 100
var xp: int = 0
var level: int = 1
var coins: int = 0
var kills: int = 0
var items: Dictionary = {}
var inventory: Dictionary = {"trail_tonic":2,"rustic_sword":1,"linen_hood":1}
var equipment: Dictionary={"Weapon":"rustic_sword","Head":"linen_hood","Body":"","Accessory":"","Relic":"","Tool":""}
var enemy_data: Dictionary={}
var loot_tables: Dictionary={}
var relic_data: Dictionary={}
var defeated_unique: Dictionary={}
var discoveries: Dictionary={}
var gathered_resources: Dictionary={}
var resource_states: Dictionary={}
var resource_data: Dictionary={}
var residents: Dictionary={}
var interior_data: Dictionary={}
var quest_progress: Dictionary={}
var completed_quests: Dictionary={}
var quest_data: Dictionary={}
var npc_data: Dictionary={}
var attack_count: int=0
var weapon_data: Dictionary={}
var ability_data: Dictionary={}
var affix_data: Dictionary={}
var abilities: Array[String]=["whirlwind","heal"]
var base_items: Dictionary={}
var generated_items: Dictionary={}
var next_item_id: int=1
var pending_loot: Dictionary={}
var next_loot_id: int=1
var character_name: String="Traveler"
var appearance: Dictionary={"skin":0,"hair":0,"outfit":0,"cape":true}
var appearance_confirmed: bool=false
var audio_settings: Dictionary={"Master":.65,"Music":.3,"SFX":.7}
var flags: Dictionary = {"met_rowan":false, "chest":false, "crypt":false, "moonseed":false, "returned":false, "shrine":false}
var modal: bool = false
var paused: bool = false
var region: String = "Willowmere"
var world_seed: int = 20260907
var astral_shards: int = 3
var opened_chests: Dictionary = {}
var dungeon_return := Vector3(37,0,-18)

func reset_progress(seed_value: int) -> void:
	narrative=ValeNarrative.defaults()
	professions=ValeProfessions.defaults(); activities=ValeProfessions.activity_defaults()
	map_data={"markers":{},"next_id":1}; camp_data={}
	life_data=ValeLife.defaults()
	world_data={"origin_x":"0","origin_z":"0","name":"The Lower Vale","playtime":0.0,"discovered":{}}
	if not base_items.is_empty(): items=base_items.duplicate(true)
	generated_items.clear()
	pending_loot.clear()
	next_item_id=1
	next_loot_id=1
	abilities=["whirlwind","heal"]
	character_name="Traveler"
	appearance={"skin":0,"hair":0,"outfit":0,"cape":true}
	appearance_confirmed=false
	hp=100
	max_hp=100
	xp=0
	level=1
	coins=0
	kills=0
	astral_shards=3
	attack_count=0
	world_seed=absi(seed_value)%2147483647
	inventory={"trail_tonic":2,"rustic_sword":1,"linen_hood":1,"iron_greatsword":1,"twin_daggers":1,"apprentice_staff":1,"oak_bow":1,"crude_axe":1,"crude_pickaxe":1}
	equipment={"Weapon":"rustic_sword","Head":"linen_hood","Body":"","Accessory":"","Relic":"","Tool":""}
	flags={"met_rowan":false,"chest":false,"crypt":false,"moonseed":false,"returned":false,"shrine":false}
	for values in [resource_states,residents,interior_data,opened_chests,defeated_unique,discoveries,gathered_resources,quest_progress,completed_quests]: values.clear()
	dungeon_return=Vector3(37,0,-18)
	modal=false
	paused=false
	recalculate()

func _ready() -> void:
	items = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
	for id in items: items[id].color=RARITY_COLORS[items[id].rarity]
	resource_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/resources.json"))
	base_items=items.duplicate(true)
	for id in ["iron_greatsword","twin_daggers","apprentice_staff","oak_bow","crude_axe","crude_pickaxe"]: inventory[id]=1
	enemy_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
	loot_tables=JSON.parse_string(FileAccess.get_file_as_string("res://data/loot_tables.json"))
	relic_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/relics.json"))
	weapon_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
	ability_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	affix_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/affixes.json"))
	if FileAccess.file_exists("res://data/quests.json"): quest_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"))
	if FileAccess.file_exists("res://data/npcs.json"): npc_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	quest_data.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/quest_chains.json")))
	faction_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/factions.json"))
	merchant_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/merchants.json"))
	for recipe in JSON.parse_string(FileAccess.get_file_as_string("res://data/crafting.json")): crafting_data[recipe.id]=recipe
	ValeProfessions.install()
	ValeNarrative.install()
	recalculate()

func stats(loadout: Dictionary = {}) -> Dictionary:
	if loadout.is_empty(): loadout=equipment
	var result: Dictionary={"max_hp":100+(level-1)*10,"attack":10+(level-1)*3,"defense":(level-1),"move_speed":5.0,"crit":.05,"move_percent":0.0,"fire_percent":0.0,"attack_speed":0.0,"damage_percent":0.0,"vampiric":0.0,"burn_chance":0.0,"slow_chance":0.0,"cooldown_reduction":0.0,"tonic_bonus":0.0,"dodge_reduction":0.0,"coin_bonus":0.0}
	for id in loadout.values():
		for stat in items.get(id,{}).get("stats",{}): result[stat]=result.get(stat,0)+items[id].stats[stat]
	for stat in ["max_hp","damage_percent","move_percent"]: result[stat]+=ValeProfessions.food_bonus(stat)
	result.attack*=1.0+float(result.damage_percent)
	if not weapon_data.is_empty(): result.crit+=float(weapon_data.get(items.get(loadout.Weapon,{}).get("weapon_type","sword"),weapon_data.sword).crit_chance)
	result.move_speed*=1.0+result.move_percent
	result.crit=clampf(result.crit,0,.8)
	return result

func weapon_profile() -> Dictionary:
	var item: Dictionary=items.get(equipment.Weapon,{})
	return weapon_data.get(item.get("weapon_type","sword"),weapon_data.get("sword",{}))

func set_ability(slot: int, id: String) -> bool:
	if slot<0 or slot>1 or not ability_data.has(id): return false
	if abilities[1-slot]==id:
		abilities[1-slot]=abilities[slot]
	abilities[slot]=id
	changed.emit()
	return true

func recalculate() -> void:
	max_hp=int(stats().max_hp)
	hp=mini(hp,max_hp)

func equip(id: String) -> bool:
	if int(inventory.get(id,0))<1 or not items.get(id,{}).has("slot"): return false
	equipment[items[id].slot]=id
	attack_count=0
	recalculate()
	changed.emit()
	return true

func unequip(slot: String) -> void:
	if not equipment.has(slot): return
	equipment[slot]=""
	attack_count=0
	recalculate()
	changed.emit()

func relic_proc() -> String:
	return items.get(equipment.Relic,{}).get("proc","")

func damage_amount() -> int:
	return int(stats().attack)

func attack_roll(rng: RandomNumberGenerator = null) -> Dictionary:
	if rng==null:
		rng=RandomNumberGenerator.new()
		rng.randomize()
	attack_count+=1
	var values:=stats()
	var critical: bool=rng.randf()<float(values.crit)
	var amount: int=roundi(values.attack*(1.5 if critical else 1.0))
	amount+=ceili(values.attack*values.fire_percent)
	var storm: bool=relic_proc()=="storm" and rng.randf()<.10
	if storm: amount+=8
	return {"damage":amount,"critical":critical,"storm":storm,"echo":relic_proc()=="void" and attack_count%5==0}

func add_item(id: String, count: int = 1) -> void:
	if not items.has(id) or count<=0: return
	inventory[id] = int(inventory.get(id, 0)) + count
	quest_event("collect",id,count)
	changed.emit()

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= level * 60:
		xp -= level * 60
		level += 1
		recalculate()
		hp = max_hp
		Feel.sound("level",.7)
		var actor:=get_tree().get_first_node_in_group("player") as ValePlayer
		if actor: Feel.ring(actor.get_parent(),actor.global_position,2.5,Color("e1ce88"),.7)
		notification.emit("LEVEL %d  ·  A little stronger, a little braver." % level)
	changed.emit()

func quest_event(type: String, target: String, amount: int = 1) -> void:
	objective_event.emit(type,target,amount)
	for id in quest_data:
		var q: Dictionary=quest_data[id]
		if completed_quests.has(id) or not quest_progress.has(id): continue
		if q.type==type and q.target==target:
			quest_progress[id]=mini(int(q.count),int(quest_progress[id])+amount)
	changed.emit()

func enemy_killed(kind: String, unique_id: String, reward_xp: int) -> void:
	kills+=1
	if not unique_id.is_empty(): defeated_unique[unique_id]=true
	gain_xp(reward_xp)
	quest_event("kill",kind)
	if relic_proc()=="king" and randf()<.20:
		cooldown_reset.emit()
		notification.emit("The Fallen King quickens your blade.")
	enemy_defeated.emit()

func drink_tonic() -> void:
	if hp >= max_hp:
		notification.emit("Already feeling your best.")
	elif int(inventory.get("trail_tonic", 0)) > 0:
		inventory["trail_tonic"] -= 1
		if inventory["trail_tonic"] == 0:
			inventory.erase("trail_tonic")
		var amount: int=roundi(45*(1+float(stats().tonic_bonus)))
		var actor:=get_tree().get_first_node_in_group("player") as ValePlayer
		if actor:
			actor.restore_health(amount)
			if relic_proc()=="drinking_moon": actor.statuses.apply("regeneration",3,3)
		else: hp=mini(hp+amount,max_hp)
		Feel.sound("heal",.55)
		notification.emit("Trail tonic  ·  +%d health" % amount)
		changed.emit()
	else:
		notification.emit("No tonics left. The village shrine can restore you.")

func open_chest() -> bool:
	if flags.chest:
		notification.emit("Only a few old leaves remain.")
		return false
	flags.chest = true
	Feel.sound("chest",.55)
	coins += 25
	add_item("trail_tonic", 2)
	conversation.emit("A gift for the road", "Inside the weathered chest: two trail tonics and 25 copper.\n\nMay your road be kind, and your boots stay dry.")
	return true

func talk_to_rowan() -> void:
	for id in quest_data:
		if not quest_data[id].has("chain") and not quest_progress.has(id) and not completed_quests.has(id): quest_progress[id]=0
	var rewards: Array[String]=[]
	for id in quest_data:
		if not quest_data[id].has("chain") and claim_quest(id): rewards.append(quest_data[id].name)
	if not rewards.is_empty():
		conversation.emit("Rowan · Keeper of the vale","Well done, traveler. Your efforts have made these roads kinder.\n\nCompleted: %s\n\nYour XP, copper and Astral Shards are in your care. The field journal holds the remaining tasks." % ", ".join(rewards))
		save_requested.emit()
		return
	if flags.moonseed and not flags.returned:
		flags.returned = true
		inventory.erase("moonseed")
		coins += 75
		gain_xp(40)
		conversation.emit("Rowan · Keeper of the vale", "You found it. I thought the old paths had forgotten us.\n\nThe moonseed will keep Willowmere's lanterns burning through winter. Take this copper, traveler. You have a home here now.\n\nJourney complete · +75 copper · +40 XP")
	elif flags.returned:
		conversation.emit("Rowan · Keeper of the vale", "The vale feels brighter already. Stay a while. There are still quiet corners to explore, and the shrine has a gift if you haven't visited it.")
	else:
		flags.met_rowan = true
		conversation.emit("Rowan · Keeper of the vale", "Welcome to Willowmere. Slimes are troubling the east road. Defeat five, then return for 80 XP, 35 copper and an Astral Shard.\n\nAn old moonseed also waits in the Forgotten Crypt. Follow the lanterns east. Take supplies by the well and meet our shrine keeper.\n\nJ · Field journal tracks your tasks.")
	changed.emit()

func claim_quest(id: String) -> bool:
	if not quest_data.has(id) or completed_quests.has(id): return false
	var q: Dictionary=quest_data[id]
	if int(quest_progress.get(id,0))<int(q.count): return false
	completed_quests[id]=true
	coins+=int(q.reward.coins)
	astral_shards+=int(q.reward.shards)
	gain_xp(int(q.reward.xp))
	if q.reward.has("faction"):
		var faction: String=q.reward.faction
		life_data.reputation[faction]=clampi(int(life_data.reputation.get(faction,0))+int(q.reward.reputation),-100,100)
		if not q.reward.get("unlock","").is_empty(): life_data.unlocks[q.reward.unlock]=true
	return true

func talk_npc(id: String,stories: bool=true) -> void:
	var game: Node=get_tree().current_scene
	if stories and is_instance_valid(game.narrative) and game.narrative.talk(id): return
	quest_event("talk",id)
	var chain_rewards: Array[String]=ValeLife.quest_talk(id)
	if not chain_rewards.is_empty(): notification.emit("Completed: "+", ".join(chain_rewards))
	if id=="rowan":
		talk_to_rowan()
		return
	var npc: Dictionary=npc_data.get(id,npc_data.keeper)
	var message: String=npc.dialogue
	if npc.has("category"):
		var faction: String=merchant_data[npc.category].faction
		message+="\n\n"+faction_data[faction].name+" · "+ValeLife.tier(ValeLife.reputation(faction))+" ("+str(ValeLife.reputation(faction))+")"
	for qid in quest_progress:
		if quest_data[qid].get("npc","")==id and not completed_quests.has(qid): message+="\n\n"+quest_data[qid].name+": "+quest_data[qid].description
	conversation.emit(npc.name+" · "+npc.role,message)

func discover(id: String, title: String) -> void:
	if discoveries.has(id): return
	discoveries[id]=true
	gain_xp(10)
	notification.emit("DISCOVERED  ·  %s  ·  +10 XP" % title)

func visit_shrine() -> void:
	Feel.sound("shrine",.5)
	hp = max_hp
	flags.shrine=true
	changed.emit()
	shrine_requested.emit()

func summon(rng: RandomNumberGenerator = null) -> String:
	var cost: int=int(relic_data.cost)
	if astral_shards<cost: return ""
	if rng==null:
		rng=RandomNumberGenerator.new()
		rng.randomize()
	var total: float=0
	for rate in relic_data.rates: total+=float(rate.weight)
	var roll: float=rng.randf()*total
	for rate in relic_data.rates:
		roll-=float(rate.weight)
		if roll<0:
			var id: String=rate.items[rng.randi_range(0,rate.items.size()-1)]
			astral_shards-=cost
			add_item(id)
			# Commit the result before visual reveal, including if the menu is closed early.
			save_requested.emit()
			return id
	return ""

func objective() -> String:
	var tracked: String=narrative.get("tracked","")
	if quest_data.has(tracked) and not completed_quests.has(tracked):
		var index: int=int(quest_progress.get(tracked,-1))
		if index>=0 and index<quest_data[tracked].get("stages",[]).size(): return quest_data[tracked].name+"\n"+str(quest_data[tracked].stages[index].text)
	if quest_progress.has("woods") and not completed_quests.has("woods"):
		return "Trouble in the Woods  ·  %d / 5\n%s" % [int(quest_progress.woods),"Return to Rowan for your reward." if int(quest_progress.woods)>=5 else "Hunt slimes east of the village."]
	if flags.returned: return "A light returned\nThe vale is yours to explore."
	if flags.moonseed: return "Bring the moonseed home\nReturn to Rowan in Willowmere."
	if not flags.met_rowan: return "A stranger in the vale\nSpeak to Rowan by the well."
	if not flags.chest: return "Prepare for the road\nOpen the supply chest by the well."
	if kills == 0: return "A path through the green\nDefeat a mossling in Mossfall Wood."
	if not flags.crypt: return "Where the lanterns end\nEnter Forgotten Crypt, northeast."
	return "A light beneath the roots\nFind the moonseed in the crypt."
