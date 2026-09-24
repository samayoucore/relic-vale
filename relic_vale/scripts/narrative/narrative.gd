class_name ValeNarrative
extends Node
## Extends the existing quest ledger and event bus; authored text stays in data/narrative.
static var companions: Dictionary={}
static var dialogues: Dictionary={}
static var locations: Dictionary={}
static var lore: Dictionary={}
static var contacts: Dictionary={}
var game: Node
var scenes: Dictionary={}
var clock: float=0
var dialogue_id: String=""
var history: Array[String]=[]

static func defaults() -> Dictionary:
	return {"companions":{},"active":"","command":"follow","stance":"defensive","flags":{},"approval_flags":{},"counters":{},"locations":{},"lore":{},"tracked":"","seen":{},"event_serial":1,"event_last":0.0}

static func read(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/narrative/"+name+".json"))

static func install() -> void:
	companions=read("companions"); dialogues=read("dialogue"); locations=read("locations"); lore=read("lore")
	contacts=read("contacts")
	ValeWorldEvents.definitions=read("events")
	for id in contacts:
		if contacts[id].has("name"): State.npc_data[id]=contacts[id].duplicate(true)
	State.quest_data.merge(read("quests"),true)
	State.items.merge(read("items"),true)
	for id in State.items: State.items[id].color=State.RARITY_COLORS[State.items[id].rarity]
	State.base_items=State.items.duplicate(true)
	for id in companions: State.npc_data[id]={"name":companions[id].name,"role":companions[id].role.capitalize()+" companion","dialogue":"","faction":companions[id].faction}

func _ready() -> void:
	game=get_tree().current_scene
	State.objective_event.connect(on_event)
	ensure()

func ensure() -> void:
	for id in companions:
		if not State.narrative.companions.has(id):
			State.narrative.companions[id]={"recruited":false,"level":1,"approval":0,"equipment":companions[id].equipment.duplicate(true),"hp":0,"state":"waiting","address":{},"camp_state":"Resting"}

static func tier(score: int) -> String:
	if score<0: return "Distant"
	if score<20: return "Acquaintance"
	if score<40: return "Trusted"
	if score<65: return "Close"
	return "Loyal"

func condition(rule: Dictionary) -> bool:
	var id: String=rule.get("id",""); var value: Variant=rule.get("value",true)
	match rule.type:
		"flag":
			var current: Variant=State.narrative.flags.get(id,false)
			if (current is String or current is StringName) and (value is String or value is StringName): return str(current)==str(value)
			if (current is int or current is float) and (value is int or value is float): return current==value
			return current==value if typeof(current)==typeof(value) else false
		"recruited": return State.narrative.companions.get(id,{}).get("recruited",false)
		"active": return State.narrative.active==id
		"approval": return int(State.narrative.companions.get(id,{}).get("approval",0))>=int(value)
		"completed": return State.completed_quests.has(id)
		"not_completed": return not State.completed_quests.has(id)
		"not_started": return not State.quest_progress.has(id)
		"stage": return not State.completed_quests.has(id) and int(State.quest_progress.get(id,-1))==int(value)
		"profession": return ValeProfessions.level(id)>=int(value)
		"reputation": return ValeLife.reputation(id)>=int(value)
		"item": return int(State.inventory.get(id,0))>=int(value)
		"camp": return int(State.camp_data.get("tier",0))>=int(value)
		"at_camp": return game.camp.near_camp()
		"defeated": return State.defeated_unique.has(id)
	return false

func allowed(rules: Array) -> bool:
	for rule in rules:
		if not condition(rule): return false
	return true

func choice_visible(choice: Dictionary) -> bool:
	for rule in choice.get("conditions",[]):
		if not condition(rule) and rule.type not in ["approval","profession","reputation","item","active","camp"]: return false
	return true

func dialogue_text(id: String) -> String:
	var row: Dictionary=dialogues[id]
	for variant in row.get("variants",[]):
		if allowed(variant.conditions): return variant.text
	return row.text

func requirement_text(rules: Array) -> String:
	var messages: Array[String]=[]
	for rule in rules:
		if condition(rule): continue
		match rule.type:
			"profession": messages.append(ValeProfessions.definitions[rule.id].name+" "+str(rule.value))
			"approval": messages.append("Trust with "+companions[rule.id].name)
			"reputation": messages.append(State.faction_data[rule.id].name+" · "+ValeLife.tier(int(rule.value)))
			"item": messages.append(State.items[rule.id].name+" ×"+str(rule.value))
			"active": messages.append(companions[rule.id].name+" accompanying you")
			"camp": messages.append("Camp tier "+str(rule.value))
			_: messages.append("Continue this story first")
	return " · ".join(messages)

func start(id: String) -> bool:
	if not State.quest_data.has(id) or State.quest_progress.has(id) or State.completed_quests.has(id): return false
	var q: Dictionary=State.quest_data[id]
	for previous in q.get("prerequisites",[]):
		if not State.completed_quests.has(previous): return false
	if not allowed(q.get("conditions",[])): return false
	State.quest_progress[id]=0; State.narrative.counters[id]=0; State.narrative.tracked=id
	State.notification.emit("Quest started · "+q.name)
	reconcile(id); State.changed.emit(); State.save_requested.emit(); return true

func objective(id: String) -> Dictionary:
	var q: Dictionary=State.quest_data.get(id,{})
	var index: int=int(State.quest_progress.get(id,-1))
	if not q.has("stages") or index<0 or index>=q.stages.size() or State.completed_quests.has(id): return {}
	return q.stages[index]

func objective_address(id: String) -> Dictionary:
	var step: Dictionary=objective(id)
	if step.get("camp",false): return State.camp_data.get("address",{})
	if step.has("location"): return location_address(step.location)
	return {}

func on_event(kind: String,target: String,amount: int=1) -> void:
	for id in State.quest_progress.keys():
		var step: Dictionary=objective(id)
		if step.is_empty() or step.type!=kind or step.get("target","") not in [target,"*"]: continue
		if step.get("camp",false) and not game.camp.near_camp(): continue
		if not allowed(step.get("conditions",[])): continue
		State.narrative.counters[id]=int(State.narrative.counters.get(id,0))+amount
		if int(State.narrative.counters[id])>=int(step.get("count",1)): advance(id)

func reconcile(id: String) -> void:
	var step: Dictionary=objective(id)
	if step.is_empty(): return
	if step.type=="interact" and State.narrative.flags.get("object_"+step.target,false): advance(id)
	elif step.type=="defeat" and State.defeated_unique.has(step.target): advance(id)
	elif step.type=="collect" and int(State.inventory.get(step.target,0))>=int(step.get("count",1)): advance(id)
	elif step.type=="camp" and not State.camp_data.is_empty(): advance(id)
	elif step.type=="recruit":
		for row in State.narrative.companions.values():
			if row.recruited: advance(id); break

func advance(id: String) -> void:
	if objective(id).is_empty(): return
	State.quest_progress[id]+=1; State.narrative.counters[id]=0
	if State.quest_progress[id]>=State.quest_data[id].stages.size():
		State.claim_quest(id)
		effects(State.quest_data[id].get("effects",[]))
		State.notification.emit("Completed · "+State.quest_data[id].name)
		if State.narrative.tracked==id:
			State.narrative.tracked=""
			for other in State.quest_progress:
				if not objective(other).is_empty(): State.narrative.tracked=other; break
	else: reconcile(id)
	State.changed.emit(); State.save_requested.emit()

func approve(id: String,amount: int,key: String) -> void:
	if State.narrative.approval_flags.has(key) or not State.narrative.companions.has(id): return
	State.narrative.approval_flags[key]=true
	var row: Dictionary=State.narrative.companions[id]
	row.approval=clampi(int(row.approval)+amount,-100,100)
	State.notification.emit(companions[id].name+(" approves." if amount>0 else " disapproves."))

func effects(actions: Array) -> void:
	for effect in actions:
		var id: String=effect.get("id","")
		match effect.type:
			"start": start(id)
			"event": State.quest_event(effect.event,id,int(effect.get("amount",1)))
			"flag": State.narrative.flags[id]=effect.get("value",true)
			"approval": approve(id,int(effect.amount),effect.key)
			"reputation": State.life_data.reputation[id]=clampi(ValeLife.reputation(id)+int(effect.amount),-100,100)
			"item": State.add_item(id,int(effect.get("amount",1)))
			"consume": ValeLife.consume(id,int(effect.get("amount",1)))
			"recruit": game.party.recruit(id)
			"lore": State.narrative.lore[id]=true
			"coins": State.coins+=int(effect.amount)
	State.changed.emit(); State.save_requested.emit()

func talk(id: String) -> bool:
	if not companions.has(id):
		if contacts.has(id): show_dialogue(contacts[id].entry); return true
		return false
	State.narrative.seen[id]=true
	State.narrative.lore[id]=true
	var row: Dictionary=State.narrative.companions[id]
	if not row.recruited:
		var quest: String=companions[id].recruitment
		show_dialogue(id+"_recruit_choice" if objective(quest).get("type","")=="choice" else id+"_intro")
	elif not game.camp.near_camp():
		State.conversation.emit(companions[id].name,"I am with you. We can speak properly when we make camp.\n\nZ · Follow, wait and battle orders.  O · Your company.")
	else: show_dialogue(id+"_camp")
	return true

func show_dialogue(id: String) -> void:
	if not dialogues.has(id): return
	dialogue_id=id
	var row: Dictionary=dialogues[id]
	history.append(dialogue_text(id))
	while history.size()>10: history.pop_front()
	ValeNarrativeUI.dialogue(game.hud.ui,id)

func choose(index: int) -> bool:
	if not dialogues.has(dialogue_id): return false
	var row: Dictionary=dialogues[dialogue_id]
	if index<0 or index>=row.choices.size(): return false
	var choice: Dictionary=row.choices[index]
	if not allowed(choice.get("conditions",[])): return false
	if companions.has(row.speaker) and State.narrative.companions[row.speaker].recruited and not game.camp.near_camp(): return false
	# A consequential terminal choice cannot be repeated from a stale dialogue panel.
	var key: String="choice_"+dialogue_id
	var consequential: bool=false
	for action in choice.get("effects",[]):
		if action.type in ["flag","reputation","item","consume","coins","approval"]: consequential=true
	if consequential and State.narrative.flags.get(key,false): return false
	if consequential: State.narrative.flags[key]=true
	for id in companions:
		if not State.narrative.companions[id].recruited or (State.narrative.active!=id and not game.camp.near_camp()): continue
		var reaction: int=0
		for tag in choice.get("tags",[]):
			if tag in companions[id].tags: reaction+=3
			if tag in companions[id].get("opposes",[]): reaction-=3
		if reaction!=0: approve(id,clampi(reaction,-6,6),key+"/"+id)
	effects(choice.get("effects",[]))
	if choice.get("next","")=="@legacy": game.hud.close_modal(); dialogue_id=""; State.talk_npc(row.speaker,false)
	elif choice.get("next","").is_empty(): game.hud.close_modal(); dialogue_id=""
	else: show_dialogue(choice.next)
	return true

func location_address(id: String) -> Dictionary:
	if State.narrative.locations.has(id): return State.narrative.locations[id]
	if not locations.has(id): return {}
	var definition: Dictionary=locations[id]; var at: Dictionary=definition.address.duplicate(true)
	if not definition.get("fixed",false):
		var rng:=RandomNumberGenerator.new(); rng.seed=(str(State.world_seed)+"/story/"+id).hash()
		var found: bool=false
		# Search neighboring tiles only when the intended one cannot hold this site.
		# The chosen canonical address is then permanent in the journey ledger.
		for radius in range(0,5):
			for dx in range(-radius,radius+1):
				for dz in range(-radius,radius+1):
					if maxi(absi(dx),absi(dz))!=radius: continue
					var x: int=int(definition.address.x)+dx; var z: int=int(definition.address.z)+dz
					var plan: ValeRegionPlan=game.generator.planner(str(x)+","+str(z))
					for attempt in 128:
						var p:=Vector2(rng.randf_range(6,26),rng.randf_range(6,26))
						if not plan.clear(p,6) or plan.water_distance(p)<7: continue
						if not State.camp_data.is_empty():
							var home: Dictionary=State.camp_data.address
							if absi(x-int(home.x))<=2 and absi(z-int(home.z))<=2:
								var camp_offset:=Vector2((x-int(home.x))*32+p.x-float(home.local[0]),(z-int(home.z))*32+p.y-float(home.local[2]))
								if absf(camp_offset.x)<29 and absf(camp_offset.y)<29: continue
						at={"x":str(x),"z":str(z),"local":[p.x,plan.height_at(p),p.y]}; found=true; break
					if found: break
				if found: break
			if found: break
		if not found: push_error("No dry ground for authored site: "+id)
	State.narrative.locations[id]=at; return at

func inspect_object(location: String,id: String) -> bool:
	if not locations.has(location) or not scenes.has(location): return false
	var close: bool=false
	for node in scenes[location].get_children():
		if node is ValeInteractable and node.get_meta("story_object","")==id and node.global_position.distance_to(game.player.global_position)<3: close=true
	if not close: return false
	for object in locations[location].get("objects",[]):
		if object.id!=id: continue
		if object.get("action","")=="dungeon":
			game.hud.close_modal(); game.expedition.enter(object.dungeon,"crypt"); return true
		if not State.narrative.flags.get("object_"+id,false):
			if not allowed(object.get("requires",[])): State.notification.emit(requirement_text(object.requires)); return false
			effects(object.get("effects",[]))
		State.narrative.flags["object_"+id]=true
		State.quest_event("interact",id)
		State.conversation.emit(object.name,object.text)
		State.save_requested.emit(); return true
	return false

func reset() -> void:
	for node in scenes.values():
		if is_instance_valid(node): node.queue_free()
	scenes.clear(); dialogue_id=""; history.clear(); ensure()

func build_site(id: String,position: Vector3) -> void:
	var root:=Node3D.new(); root.name="Story_"+id; game.world.add_child(root); root.position=position; scenes[id]=root
	var definition: Dictionary=locations[id]
	root.set_meta("variant",str(State.narrative.flags.get(definition.get("variant",""),"ruined")))
	root.set_meta("encounter_enabled",allowed(definition.get("enemy_conditions",[])))
	if definition.has("variant"):
		var shelter: bool=root.get_meta("variant")=="shelter"
		var restored: bool=root.get_meta("variant") in ["shelter","garrison"]
		game.world.place("res://assets/3d/phase7/"+("tent-canvas" if shelter else "fence")+".glb",Vector3(-3,0,0),2.3 if shelter else 1.2,0,root)
		if restored: game.world.place("res://assets/3d/phase7/campfire-pit.glb",Vector3(-2,0,3),.5,0,root)
		if restored and id=="glass_archive":
			game.world.place("res://assets/3d/phase6/props/Bookcase_2.gltf",Vector3(-4,0,-2),1.8,0,root)
			game.world.place("res://assets/3d/phase6/props/Table_Large.gltf",Vector3(0,0,-3),.8,0,root)
		if restored and id=="reed_well":
			for x in [-3.0,-1.0]: game.world.place("res://assets/3d/phase7/bedroll.glb",Vector3(x,0,-2),.25,0,root)
	var index: int=0
	for person in definition.get("npcs",[]):
		var npc: ValeInteractable=game.world.interactable("npc",State.npc_data[person.id].name,ValeSave.vector(person.offset),root)
		npc.npc_id=person.id
	for object in definition.get("objects",[]):
		var local:=Vector3(index*2,0,0); index+=1
		var node: ValeInteractable=game.world.interactable("story",object.name,local,root)
		node.set_meta("story_location",id); node.set_meta("story_object",object.id)
		node.model=game.world.place(object.model,Vector3.ZERO,float(object.height),0,node)
	for enemy in definition.get("enemies",[]) if allowed(definition.get("enemy_conditions",[])) else []:
		if State.defeated_unique.has(enemy.id): continue
		var actor: Mossling=load("res://scenes/characters/Enemy.tscn").instantiate()
		actor.position=ValeSave.vector(enemy.offset); actor.set_meta("archetype",enemy.archetype); actor.set_meta("persistent_id",enemy.id); actor.set_meta("narrative_enemy",true)
		root.add_child(actor)

func _process(delta: float) -> void:
	clock-=delta
	if clock>0 or not game.gameplay_started: return
	clock=.5
	for id in locations:
		var address: Dictionary=location_address(id)
		var near: bool=game.player.position.x<900 and absi(int(address.x)-game.generator.origin_x)<=2 and absi(int(address.z)-game.generator.origin_z)<=2
		if not near:
			if scenes.has(id): scenes[id].queue_free(); scenes.erase(id)
			continue
		var p: Vector3=game.generator.position_of(address); p.y=game.generator.landscape.height(Vector2(p.x,p.z))
		if game.player.global_position.distance_to(p)<8:
			State.quest_event("reach",id)
			State.narrative.lore[id]=true
		if scenes.has(id):
			var variant: String=str(State.narrative.flags.get(locations[id].get("variant",""),"ruined"))
			if scenes[id].get_meta("variant","")!=variant or scenes[id].get_meta("encounter_enabled")!=allowed(locations[id].get("enemy_conditions",[])): scenes[id].queue_free(); scenes.erase(id)
			else:
				var displacement: Vector3=p-scenes[id].position
				for enemy in scenes[id].get_children():
					if enemy is Mossling: enemy.origin+=displacement
				scenes[id].position=p
		if not scenes.has(id): build_site(id,p)
	for id in State.quest_progress.keys():
		var step: Dictionary=objective(id)
		if step.get("type","") in ["collect","camp"]: reconcile(id)
