class_name ValeWorldEvents
extends Node
## Reuses the existing life.events ledger. At most two unresolved encounters and 64 records.
static var definitions: Dictionary={}
var game: Node
var scenes: Dictionary={}
var clock: float=0
var attempt_clock: float=30
var autonomous: bool=true

func _ready() -> void:
	game=get_tree().current_scene
	State.objective_event.connect(on_event)
	autonomous=not game.test_mode

func records() -> Dictionary:
	var result: Dictionary={}
	for id in State.life_data.events:
		if str(id).begins_with("encounter_"): result[id]=State.life_data.events[id]
	return result

func context_allows(kind: String,address: Dictionary) -> bool:
	var data: Dictionary=definitions[kind]
	var hour: float=float(State.life_data.minute)/60
	if data.time=="day" and (hour<6 or hour>=21): return false
	if data.time=="night" and hour>=6 and hour<21: return false
	if not data.weather.is_empty() and not State.life_data.weather in data.weather: return false
	if not game.narrative.allowed(data.get("conditions",[])): return false
	if data.has("reputation") and ValeLife.reputation(data.reputation.faction)<int(data.reputation.minimum): return false
	var plan: ValeRegionPlan=game.generator.planner(address.x+","+address.z)
	var p:=Vector2(address.local[0],address.local[2])
	match data.where:
		"road": return plan.road_distance(p)<5
		"forest": return plan.weights(p).y>.45
		"settlement","ruin":
			for poi in plan.pois:
				var matches: bool=poi.kind=="settlement" if data.where=="settlement" else poi.kind in ["ruin","chapel","mine","circle"]
				if matches and poi.position.distance_to(p)<50: return true
			return false
	return true

func on_camera(p: Vector3) -> bool:
	for offset in [Vector3.ZERO,Vector3(-3,1,-3),Vector3(3,1,3),Vector3(-3,1,3),Vector3(3,3,-3)]:
		if game.rig.camera.is_position_in_frustum(p+offset): return true
	return false

func find_site(kind: String) -> Dictionary:
	var rng:=RandomNumberGenerator.new(); rng.seed=(str(State.world_seed)+"/event/"+str(State.narrative.event_serial)+"/"+kind).hash()
	for attempt in 160:
		var angle: float=rng.randf()*TAU
		var p: Vector3=game.player.position+Vector3(cos(angle),0,sin(angle))*rng.randf_range(27,53)
		p.y=game.generator.landscape.height(Vector2(p.x,p.z))
		if on_camera(p): continue
		var address: Dictionary=game.generator.address(p)
		if not game.generator.active_chunks.has(address.x+","+address.z) or not context_allows(kind,address): continue
		var plan: ValeRegionPlan=game.generator.planner(address.x+","+address.z)
		var local:=Vector2(address.local[0],address.local[2])
		if plan.water_distance(local)<4 or not plan.clear(local,3): continue
		if not game.generator.clear_for_prop(Vector2(p.x,p.z),{},3): continue
		var close: bool=false
		for row in records().values():
			if row.state=="active" and game.generator.position_of(row.address).distance_to(p)<22: close=true
		if not close: return address
	return {}

func escort_destination(address: Dictionary) -> Dictionary:
	var from: Vector3=game.generator.position_of(address)
	var best: Vector3=from; var distance: float=INF
	for road in game.generator.roads:
		var a:=Vector2(from.x,from.z)
		var p: Vector2=Geometry2D.get_closest_point_to_segment(a,road[0],road[1])
		var d: float=p.distance_to(a)
		if d>7 and d<distance and d<35:
			best=Vector3(p.x,game.generator.landscape.height(p),p.y); distance=d
	return game.generator.address(best) if distance<INF else {}

func spawn(kind: String,address: Dictionary={},debug: bool=false) -> String:
	if not definitions.has(kind) or game.player.position.x>900: return ""
	var unresolved: int=0
	for row in records().values():
		if row.state=="active": unresolved+=1
	if unresolved>=2: return ""
	prune(63)
	if records().size()>=64: return ""
	if address.is_empty(): address=find_site(kind)
	if address.is_empty() or not ValeSave.valid_address(address): return ""
	if not debug and (not context_allows(kind,address) or on_camera(game.generator.position_of(address))): return ""
	var destination: Dictionary=escort_destination(address) if definitions[kind].get("escort",false) else {}
	if definitions[kind].get("escort",false) and destination.is_empty(): return ""
	var id: String="encounter_"+str(int(State.narrative.event_serial)); State.narrative.event_serial=int(State.narrative.event_serial)+1
	State.life_data.events[id]={"id":id,"kind":kind,"address":address.duplicate(true),"destination":destination,"walker_address":address.duplicate(true),"created":ValeCamp.now(),"expires":ValeCamp.now()+240,"state":"active","stage":0,"discovered":false,"defeated":{}}
	State.narrative.event_last=ValeCamp.now(); prune(); State.save_requested.emit(); return id

func prune(limit: int=64) -> void:
	var entries: Dictionary=records()
	if entries.size()<=limit: return
	for id in entries:
		if entries[id].state=="active" or scenes.has(id): continue
		State.life_data.events.erase(id)
		if records().size()<=limit: break

func remaining(row: Dictionary) -> int:
	return definitions[row.kind].enemies.size()-row.defeated.size()

func on_event(kind: String,target: String,_amount: int) -> void:
	if kind!="defeat" or not target.begins_with("encounter_"): return
	var id: String=target.get_slice("/",0)
	if State.life_data.events.has(id):
		State.life_data.events[id].defeated[target]=true; State.save_requested.emit()

func complete(id: String,debug: bool=false) -> bool:
	var row: Dictionary=State.life_data.events.get(id,{})
	if row.is_empty() or row.state!="active" or (remaining(row)>0 and not debug): return false
	var data: Dictionary=definitions[row.kind]
	if not debug:
		if not scenes.has(id) or game.player.position.distance_to(scenes[id].get_node("Contact").global_position)>4: return false
		if data.get("escort",false) and (int(row.stage)!=1 or game.player.position.distance_to(game.generator.position_of(row.destination))>6): return false
		for item in data.cost:
			if int(State.inventory.get(item,0))<int(data.cost[item]): return false
		for item in data.cost: ValeLife.consume(item,int(data.cost[item]))
	row.state="completed"; row.stage=2
	var reward: Dictionary=data.reward
	State.coins+=int(reward.coins); State.gain_xp(20)
	State.life_data.reputation[reward.faction]=clampi(ValeLife.reputation(reward.faction)+int(reward.reputation),-100,100)
	if reward.has("item"): State.add_item(reward.item)
	State.narrative.flags[data.outcome]=true
	if row.kind=="veil_echo": State.narrative.lore.oathbound=true
	if row.kind=="road_ambush" and not State.camp_data.is_empty(): State.camp_data.food+=3
	if not State.narrative.active.is_empty(): game.narrative.approve(State.narrative.active,3,"event_"+row.kind+"/"+State.narrative.active)
	State.quest_event("world_event",row.kind)
	State.notification.emit("Road story resolved · "+data.name)
	State.changed.emit(); State.save_requested.emit(); return true

func expire(id: String) -> void:
	if State.life_data.events.has(id) and State.life_data.events[id].get("state","")=="active":
		State.life_data.events[id].state="expired"; State.save_requested.emit()

func interact(id: String) -> void:
	var row: Dictionary=State.life_data.events.get(id,{})
	if row.is_empty(): return
	var data: Dictionary=definitions[row.kind]; var ui: ValeInterface=game.hud.ui
	ui.page("world_event",data.name,"ON THE ROAD")
	var box:=ui.scroll(ui.body); ui.text(box,data.text,"Heading",true)
	if row.state!="active": ui.text(box,"The road is quiet again. This encounter has ended.","Muted",true); return
	if remaining(row)>0: ui.text(box,"Clear the nearby threats first.","Muted",true); return
	var can_pay: bool=true
	for item in data.cost:
		ui.text(box,"%s · %d / %d carried" % [State.items[item].name,State.inventory.get(item,0),data.cost[item]],"Muted")
		if int(State.inventory.get(item,0))<int(data.cost[item]): can_pay=false
	ui.button(box,data.action,func():
		game.hud.close_modal()
		if data.get("escort",false): row.stage=1; State.notification.emit("Walk toward the marked road. The traveler follows your light."); State.save_requested.emit()
		else: complete(id),not can_pay)
	ui.text(box,"The encounter will move on if left unresolved.","Muted",true)

func build(id: String,row: Dictionary) -> void:
	var root:=Node3D.new(); root.name=id; game.world.add_child(root); root.position=game.generator.position_of(row.address); scenes[id]=root
	var data: Dictionary=definitions[row.kind]
	game.world.place("res://assets/3d/phase7/"+data.model,Vector3(-1,0,0),1.8 if data.model=="tent-canvas.glb" else .7,0,root)
	var npc: ValeInteractable=game.world.interactable("npc","Wayfarer",Vector3(1,0,0),root); npc.name="Contact"; npc.set_meta("world_event",id)
	if data.get("escort",false):
		npc.global_position=game.generator.position_of(row.walker_address)
		var walker:=ValeEventWalker.new(); walker.event_id=id; npc.add_child(walker)
	for i in data.enemies.size():
		var enemy_id: String=id+"/enemy/"+str(i)
		if row.defeated.has(enemy_id): continue
		var actor: Mossling=load("res://scenes/characters/Enemy.tscn").instantiate()
		actor.position=Vector3(-3+i*6,0,-4); actor.set_meta("archetype",data.enemies[i]); actor.set_meta("persistent_id",enemy_id); actor.set_meta("event_enemy",true); actor.set_meta("narrative_enemy",true); root.add_child(actor)

func reset() -> void:
	for node in scenes.values():
		if is_instance_valid(node): node.queue_free()
	scenes.clear(); attempt_clock=30

func _process(delta: float) -> void:
	if not game.gameplay_started or State.paused or State.modal: return
	clock-=delta; attempt_clock-=delta
	if clock>0: return
	clock=.6
	for id in records():
		var row: Dictionary=State.life_data.events[id]
		if row.state=="active" and ValeCamp.now()>=float(row.expires): expire(id)
		var near: bool=game.player.position.x<900 and absi(int(row.address.x)-game.generator.origin_x)<=2 and absi(int(row.address.z)-game.generator.origin_z)<=2
		var p: Vector3=game.generator.position_of(row.address)
		if scenes.has(id):
			if not near or (row.state!="active" and not on_camera(p)):
				scenes[id].queue_free(); scenes.erase(id); continue
			scenes[id].position=p
		elif near and row.state=="active": build(id,row)
		if row.state!="active" or not near: continue
		if game.player.position.distance_to(p)<16 and not row.discovered:
			row.discovered=true; State.notification.emit(data_name(row)+" · marked on the atlas"); State.save_requested.emit()
		if int(row.stage)==1 and scenes.has(id):
			var npc: Node3D=scenes[id].get_node("Contact"); row.walker_address=game.generator.address(npc.global_position)
			if game.player.position.distance_to(game.generator.position_of(row.destination))<6 and npc.global_position.distance_to(game.player.position)<4: complete(id)
	if autonomous and attempt_clock<=0 and game.player.position.x<900 and not game.party.enemies_near(game.player.position,12):
		attempt_clock=35
		if ValeCamp.now()-float(State.narrative.event_last)>=120:
			var ids: Array=definitions.keys(); ids.shuffle()
			for kind in ids:
				if spawn(kind)!="": break

func data_name(row: Dictionary) -> String: return definitions[row.kind].name
