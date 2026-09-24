class_name ValeLife
extends Node
## Clock, factions, economy and crafting share one serializable state, separate from base generation.
const WEATHER=["Clear","Cloudy","Rain","Fog","Storm"]
var game: Node
var rain: CPUParticles3D
var blend: float=0
var lightning: float=0
var last_block: int=-1
var ambience: Dictionary={}
var event_clock: float=0
var event_actor: ValeInteractable

static func defaults() -> Dictionary:
	return {"minute":540.0,"day":1,"weather":"Clear","weather_block":-1,"reputation":{"hearth":0,"bough":0,"veil":0},"unlocks":{},"stock":{},"dungeons":{},"settlements":{},"events":{}}

static func reputation(faction: String) -> int:
	return int(State.life_data.reputation.get(faction,0))

static func tier(value: int) -> String:
	if value<=-50: return "Hostile"
	if value<0: return "Unfriendly"
	if value>=70: return "Honored"
	if value>=30: return "Friendly"
	return "Neutral"

static func available(id: String) -> bool:
	var q: Dictionary=State.quest_data[id]
	for previous in q.get("prerequisites",[]):
		if not State.completed_quests.has(previous): return false
	return reputation(q.get("chain","hearth"))>=int(q.get("reputation_requirement",0))

static func quest_talk(npc: String) -> Array[String]:
	var completed: Array[String]=[]
	for id in State.quest_data:
		var q: Dictionary=State.quest_data[id]
		if q.get("npc","")!=npc or q.type=="narrative": continue
		if State.quest_progress.has(id) and State.claim_quest(id): completed.append(q.name)
	for id in State.quest_data:
		var q: Dictionary=State.quest_data[id]
		if q.get("npc","")!=npc or q.type=="narrative" or not available(id) or State.completed_quests.has(id): continue
		if not State.quest_progress.has(id):
			State.quest_progress[id]=mini(int(q.count),int(State.inventory.get(q.target,0))) if q.type=="collect" else 0
			if q.type=="dungeon":
				for record in State.life_data.dungeons.values():
					if record.get("theme","")==q.target and record.get("completed",false): State.quest_progress[id]=int(q.count)
			elif q.type=="discover":
				var scene: Node=State.get_tree().current_scene
				for poi in scene.generator.pois:
					if poi.kind==q.target and State.discoveries.has(poi.id): State.quest_progress[id]=int(q.count)
	return completed

static func category(npc_id: String) -> String:
	return State.npc_data.get(npc_id,{}).get("category","general")

static func offers(npc_id: String) -> Array:
	var merchant: Dictionary=State.merchant_data[category(npc_id)]
	var result: Array=merchant.offers.duplicate(true)
	var faction: String=merchant.faction
	if State.life_data.unlocks.get(faction+"_accord",false) and reputation(faction)>=30:
		result.append([faction+"_accord_token",95])
	return result

static func price(npc_id: String, amount: int, selling: bool = false) -> int:
	var rep: int=reputation(State.merchant_data[category(npc_id)].faction)
	var factor: float=.8 if rep>=70 else (.9 if rep>=30 else (1.25 if rep<0 else 1.0))
	return maxi(1,roundi(amount*.4/factor) if selling else ceili(amount*factor))

static func item_price(npc_id: String,id: String,selling: bool=false) -> int:
	var merchant: Dictionary=State.merchant_data[category(npc_id)]
	var base: int=int(State.items.get(id,{}).get("base_price",10))
	if not selling:
		for offer in offers(npc_id):
			if offer[0]==id: base=maxi(int(offer[1]),int(State.items.get(id,{}).get("base_price",0)))
	var demand: float=1.0
	if selling:
		var preferred: Dictionary={"blacksmith":["iron_ore","iron_ingot","stone","charcoal"],"carpenter":["wood","plank","fiber"],"alchemist":["wild_herb","mushroom","crystal"]}
		if id in preferred.get(category(npc_id),[]): demand=1.65
	var value: int=maxi(1,roundi(price(npc_id,base,selling)*demand))
	if not selling and id=="trail_tonic" and State.narrative.flags.get("medicine_shared",false): value=maxi(1,ceili(value*.9))
	# Even honored specialists pay less than the best retail price; no vendor arbitrage.
	return mini(value,maxi(1,floori(base*.68))) if selling else value

static func trade(npc_id: String, id: String, selling: bool = false) -> bool:
	var merchant: Dictionary=State.merchant_data[category(npc_id)]
	if reputation(merchant.faction)<=-50: return false
	var base: int=10
	for offer in offers(npc_id):
		if offer[0]==id: base=int(offer[1])
	if selling:
		if not State.items.has(id) or State.items[id].kind=="quest" or int(State.inventory.get(id,0))<=0: return false
		if id in State.equipment.values() and int(State.inventory[id])<=1: return false
		consume(id,1)
		State.coins+=item_price(npc_id,id,true)
	else:
		if id.begins_with("recipe:") and State.life_data.unlocks.has(State.crafting_data[id.trim_prefix("recipe:")].get("unlock","")): return false
		var offered: bool=false
		for offer in offers(npc_id):
			if offer[0]==id: offered=true
		if not offered: return false
		var cost: int=item_price(npc_id,id)
		var key: String="%d/%s/%s" % [int(State.life_data.day),npc_id,id]
		if State.coins<cost or int(State.life_data.stock.get(key,0))>=8: return false
		State.coins-=cost
		State.life_data.stock[key]=int(State.life_data.stock.get(key,0))+1
		if id=="astral_shard": State.astral_shards+=1
		elif id.begins_with("recipe:"):
			var recipe: Dictionary=State.crafting_data[id.trim_prefix("recipe:")]
			State.life_data.unlocks[recipe.get("unlock",recipe.id)]=true
		else: State.add_item(id)
	State.changed.emit()
	State.save_requested.emit()
	Feel.sound("chest",.3)
	return true

static func consume(id: String, count: int) -> void:
	State.inventory[id]=int(State.inventory.get(id,0))-count
	if State.inventory[id]<=0:
		State.inventory.erase(id)
		for slot in State.equipment:
			if State.equipment[slot]==id: State.equipment[slot]=""
	State.recalculate()

static func crafting_inputs(recipe: Dictionary) -> Dictionary:
	var ingredients: Dictionary=recipe.input.duplicate()
	if recipe.id!="cook_grilled_fish": return ingredients
	var available: Array=[]
	for id in State.inventory:
		if ValeProfessions.fish.has(id) and int(State.inventory[id])>0: available.append(id)
	available.sort_custom(func(a,b): return int(State.items[a].base_price)<int(State.items[b].base_price))
	if not available.is_empty(): ingredients={available[0]:1}
	return ingredients

static func craft_error(id: String, station: ValeInteractable) -> String:
	if not State.crafting_data.has(id): return "Unknown recipe"
	var r: Dictionary=State.crafting_data[id]
	var player: Node3D=State.get_tree().get_first_node_in_group("player")
	if not is_instance_valid(station) or station.kind!="station" or station.get_meta("station","")!=r.station: return "Needs a "+r.station
	if player.global_position.distance_to(station.global_position)>3: return "Move closer to the station"
	if r.has("unlock") and not State.life_data.unlocks.has(r.unlock): return "Pattern: faction chain reward or relic merchant"
	if r.has("profession") and ValeProfessions.level(r.profession)<int(r.min_level): return "%s %d required" % [r.profession.capitalize(),r.min_level]
	if State.coins<int(r.cost): return "Not enough copper"
	var ingredients: Dictionary=crafting_inputs(r)
	for item in ingredients:
		if int(State.inventory.get(item,0))<int(ingredients[item]): return "Missing "+State.items[item].name
	return ""

static func craft(id: String, station: ValeInteractable) -> bool:
	var error: String=craft_error(id,station)
	if not error.is_empty(): State.notification.emit(error); return false
	var r: Dictionary=State.crafting_data[id]
	var ingredients: Dictionary=crafting_inputs(r)
	for item in ingredients: consume(item,int(ingredients[item]))
	State.coins-=int(r.cost)
	State.add_item(r.output,int(r.count))
	if r.has("profession"): ValeProfessions.award(r.profession,int(r.xp))
	State.quest_event("craft",id)
	State.notification.emit("Crafted "+State.items[r.output].name+" ×"+str(int(r.count)))
	State.save_requested.emit()
	Feel.sound("chest",.4)
	return true

static func use_item(id: String) -> void:
	if int(State.inventory.get(id,0))<=0 or State.items.get(id,{}).get("kind","")!="consumable": return
	if id=="trail_tonic": State.drink_tonic(); return
	var player: ValePlayer=State.get_tree().get_first_node_in_group("player")
	consume(id,1)
	ValeProfessions.eat(id)
	player.restore_health(int(State.items[id].get("heal",0)))
	match State.items[id].get("status",""):
		"regeneration": player.statuses.apply("regeneration",8,3)
		"shield": player.shield+=25; player.shield_time=12
		"swift": player.statuses.apply("haste",12,.2)
	State.changed.emit()
	State.save_requested.emit()

func _ready() -> void:
	game=get_tree().current_scene
	ValeSettlement.station(game.world,"forge",Vector3(8.8,0,-2),game.world.hub_root)
	ValeSettlement.station(game.world,"alchemy",Vector3(-3.8,0,-7.7),game.world.hub_root)
	ValeSettlement.station(game.world,"workbench",Vector3(12.5,0,4),game.world.hub_root)
	ValeSettlement.station(game.world,"campfire",Vector3(-4,0,7),game.world.hub_root)
	rain=CPUParticles3D.new()
	rain.amount=220
	rain.lifetime=1.1
	rain.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents=Vector3(15,4,15)
	rain.direction=Vector3(-.12,-1,.03)
	rain.initial_velocity_min=14
	rain.initial_velocity_max=20
	rain.gravity=Vector3(0,-6,0)
	rain.scale_amount_min=.7
	rain.scale_amount_max=1.1
	var streak:=BoxMesh.new()
	streak.size=Vector3(.012,.36,.012)
	streak.material=game.world.mat("8fb9ba")
	rain.mesh=streak
	game.world.add_child(rain)
	rain.emitting=false
	for zone in ["wind","forest","water","night","rain","village"]:
		var file: String="res://assets/audio/phase4/"+zone+".wav"
		if not ResourceLoader.exists(file): continue
		var audio:=AudioStreamPlayer.new()
		audio.stream=load(file)
		audio.bus="SFX"
		audio.volume_db=-60
		add_child(audio)
		audio.play()
		ambience[zone]=audio
	for npc in get_tree().get_nodes_in_group("interactables"):
		if npc.kind=="npc" and not npc.has_meta("schedule"):
			ValeSchedule.attach(npc,npc.global_position,Vector3(0,0,5.5))

func set_time(hour: float) -> void:
	State.life_data.minute=fposmod(hour*60,1440)
	State.changed.emit()

func _process(delta: float) -> void:
	if State.paused or State.modal: delta=0
	State.life_data.minute+=delta*1.2
	State.world_data.playtime=float(State.world_data.get("playtime",0))+delta
	if State.life_data.minute>=1440:
		State.life_data.minute-=1440
		State.life_data.day+=1
		State.life_data.stock.clear()
	var block: int=int(State.life_data.day)*8+int(State.life_data.minute/180)
	if int(State.life_data.weather_block)!=block:
		State.life_data.weather_block=block
		var rng:=RandomNumberGenerator.new()
		rng.seed=State.world_seed+block*197
		State.life_data.weather=WEATHER[[0,0,0,1,1,2,3,4][rng.randi_range(0,7)]]
	var h: float=float(State.life_data.minute)/60
	var daylight: float=smoothstep(5,8,h)*(1-smoothstep(17,21,h))
	var wet: bool=State.life_data.weather in ["Rain","Storm"]
	blend=move_toward(blend,1.0 if wet else 0.0,delta*.25)
	var outside: bool=game.player.position.x<900
	var env: Environment=game.world.environment
	if outside:
		var dusk: float=maxf(0,1-absf(h-18)/2)+maxf(0,1-absf(h-6)/2)
		game.world.sun.light_energy=lerpf(.14,.8,daylight)*(1-blend*.35)*(.78 if State.life_data.weather=="Cloudy" else 1.0)+lightning
		game.world.sun.light_color=Color("91b5d1").lerp(Color("ffdfb2"),daylight).lerp(Color("e5a06f"),dusk*.35)
		game.world.sun.rotation_degrees.x=-35-daylight*13
		env.ambient_light_energy=lerpf(.28,.32,daylight)
		env.ambient_light_color=Color("89a9bd").lerp(Color("c0d9cf"),daylight)
		env.background_color=Color("263e53").lerp(Color("8bada4"),daylight)
		env.fog_light_color=Color("364f64").lerp(Color("96b8ab"),daylight)
		env.fog_density=lerpf(env.fog_density,.003 if State.life_data.weather=="Fog" else (.0015 if wet else .00085),minf(1,delta))
	for lamp in game.world.lanterns:
		if is_instance_valid(lamp) and lamp.is_inside_tree() and lamp.global_position.x<900: lamp.light_energy=lerpf(.8,.08,daylight)
	rain.position=game.player.position+Vector3(0,8,0)
	rain.emitting=outside and blend>.15
	var amount: int=360 if State.life_data.weather=="Storm" else 220
	amount=maxi(4,roundi(amount*float(Preferences.values.particles)))
	if rain.amount!=amount: rain.amount=amount
	lightning=move_toward(lightning,0,delta*6)
	if outside and State.life_data.weather=="Storm" and delta>0 and randf()<delta*.035:
		lightning=.65
		Feel.sound("storm",.3)
	if is_instance_valid(game.hud): game.hud.region_subtitle.text="DAY %02d  ·  %02d:%02d  ·  %s" % [int(State.life_data.day),int(h),int(State.life_data.minute)%60,State.life_data.weather]
	update_ambience(delta,daylight,outside)
	event_clock+=delta
	if event_clock>180 and outside and not State.life_data.events.has(str(State.life_data.day)):
		spawn_event()
	if is_instance_valid(event_actor) and (h>=21 or h<6): event_actor.queue_free()
	elif outside and h>=6 and h<21 and not is_instance_valid(event_actor):
		var record: Dictionary=State.life_data.events.get(str(State.life_data.day),{})
		if record.get("kind","")=="traveling_merchant":
			var p:=Vector2(record.position[0],record.position[1])
			if record.has("address"):
				if absi(int(record.address.x)-game.generator.origin_x)>3 or absi(int(record.address.z)-game.generator.origin_z)>3: return
				var local: Vector3=game.generator.position_of(record.address)
				p=Vector2(local.x,local.z)
			if p.distance_to(Vector2(game.player.position.x,game.player.position.z))<40: create_traveler(p)

func spawn_event() -> void:
	var p: Vector2=Vector2(game.player.position.x,game.player.position.z)+Vector2(3,2)
	if not game.generator.clear_for_prop(p,{},1): return
	State.life_data.events[str(State.life_data.day)]={"kind":"traveling_merchant","position":[p.x,p.y]}
	State.life_data.events[str(State.life_data.day)].address=game.generator.address(Vector3(p.x,0,p.y))
	create_traveler(p)
	State.notification.emit("A pack-bell on the road. Peregrin trades here until dusk.")
	event_clock=0

func create_traveler(p: Vector2) -> void:
	event_actor=game.world.interactable("npc","Peregrin · Traveling merchant",Vector3(p.x,game.generator.landscape.height(p),p.y),game.world)
	event_actor.npc_id="traveling"

func update_ambience(delta: float, daylight: float, outside: bool) -> void:
	var p:=Vector2(game.player.position.x,game.player.position.z)
	var weights: Vector3=game.generator.landscape.weights(p)
	var water: float=1-smoothstep(0,12,game.generator.landscape.water_distance(p))
	for zone in ambience:
		var volume: float=0
		if outside:
			match zone:
				"wind": volume=.11
				"forest": volume=weights.y*daylight*.18
				"water": volume=water*.28
				"night": volume=(1-daylight)*.2
				"rain": volume=blend*.35
				"village": volume=.1 if game.generator.in_hub(p) else 0
		var target: float=linear_to_db(maxf(.001,volume))
		ambience[zone].volume_db=lerpf(ambience[zone].volume_db,target,minf(1,delta*1.5))

func stop_audio() -> void:
	for audio in ambience.values(): audio.stop(); audio.stream=null
