class_name ValeCamp
extends Node
## Persistent simulation is independent of the disposable nearby presentation.
var game: Node
var config: Dictionary
var visual: Node3D
var actors: Dictionary={}
var revision: String=""
var clock: float=0
var placing: bool=false
var preview: MeshInstance3D
var preview_address: Dictionary={}
var placement_reason: String=""
var origin_stamp: String=""

static func now() -> float: return (float(State.life_data.day)-1)*1440+float(State.life_data.minute)
func data() -> Dictionary: return State.camp_data
func level_data() -> Dictionary: return config.levels[int(data().get("level",1))-1]
func _ready() -> void:
	game=get_tree().current_scene
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/camp.json"))

func notify(message: String) -> void:
	State.notification.emit(message); State.changed.emit(); State.save_requested.emit()

func placement_at(address: Dictionary, check_objects: bool=true) -> String:
	if not data().is_empty(): return "You already have a camp."
	if not ValeSave.valid_address(address): return "Choose a place on solid ground."
	var plan: ValeRegionPlan=game.generator.planner(address.x+","+address.z)
	var at:=Vector2(address.local[0],address.local[2])
	var low: float=INF; var high: float=-INF
	for x in range(-17,18,4):
		for z in range(-17,18,4):
			var p: Vector2=at+Vector2(x,z)
			if plan.water_distance(p)<2: return "The whole future village needs dry ground."
			if plan.road_distance(p)<3: return "Leave the road clear of the village boundary."
			if plan.hub_distance(p)<12: return "Too close to Willowmere."
			for poi in plan.pois:
				if p.distance_to(poi.position)<float(poi.get("radius",7))+12: return "Too close to another landmark or settlement."
			var h: float=plan.height_at(p); low=minf(low,h); high=maxf(high,h)
	if high-low>2.2: return "Find flatter ground for future houses."
	# Authored story sites may not be part of the procedural landmark planner.
	for site in State.narrative.get("locations",{}).values():
		if absi(int(site.x)-int(address.x))>2 or absi(int(site.z)-int(address.z))>2: continue
		var offset:=Vector2((int(site.x)-int(address.x))*32+float(site.local[0])-at.x,(int(site.z)-int(address.z))*32+float(site.local[2])-at.y)
		if absf(offset.x)<29 and absf(offset.y)<29: return "Leave this story landmark and its approaches intact."
	if check_objects:
		if absi(int(address.x)-game.generator.origin_x)>3 or absi(int(address.z)-game.generator.origin_z)>3: return "Walk to the site first."
		var shape:=BoxShape3D.new(); shape.size=Vector3(34,5,34)
		var query:=PhysicsShapeQueryParameters3D.new(); query.shape=shape; query.collision_mask=1
		query.exclude=[game.player.get_rid()]
		var center: Vector3=game.generator.position_of(address); center.y=high+2.8
		query.transform.origin=center
		var hits: Array[Dictionary]=game.world.get_world_3d().direct_space_state.intersect_shape(query,512)
		if hits.size()>=512: return "The site is too crowded to survey. Move to a clearer spot."
		for hit in hits:
			# Only owned natural resources are clearable. Buildings, entrances,
			# settlement props and unknown structural colliders stay protected.
			if not hit.collider.get_parent() is ValeResource: return "A building or protected structure occupies this site."
	return ""

func begin_placement() -> void:
	game.hud.close_modal(); placing=true
	if is_instance_valid(preview): preview.queue_free()
	preview=MeshInstance3D.new(); var mesh:=PlaneMesh.new(); mesh.size=Vector2(34,34); preview.mesh=mesh
	var mat:=StandardMaterial3D.new(); mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.no_depth_test=true
	preview.material_override=mat; game.world.add_child(preview)
	State.notification.emit("Camp site: trees and small natural obstacles will be cleared · Enter establishes · Esc cancels")

func cancel_placement() -> void:
	placing=false
	if is_instance_valid(preview): preview.queue_free()

func establish(address: Dictionary) -> bool:
	var reason: String=placement_at(address)
	if not reason.is_empty(): State.notification.emit(reason); return false
	var cleared: int=clear_site(address)
	State.camp_data={"id":"player_camp","name":"Lantern Rest","address":address.duplicate(true),"level":1,"tier":1,"xp":0,"upgrade_pending":false,"food":0,"materials":0,"gold":0,"workers":{},"candidate":{},"next_worker":1,"next_traveler":now()+float(config.first_traveler_minutes),"offers":[],"cycle":0,"active":{},"next_job":1,"completed":[],"contributions":{},"founded":now(),"buildings":{}}
	refresh_board(false); cancel_placement()
	game.generator.teleport_logical(int(address.x),int(address.z),ValeSave.vector(address.local))
	sync_visual(true)
	notify("Lantern Rest established. %d natural obstacles cleared. A traveler has seen your campfire." % cleared); return true

func clear_site(address: Dictionary) -> int:
	var center: Vector3=game.generator.position_of(address)
	var cleared: int=0
	for node in get_tree().get_nodes_in_group("interactables"):
		if not node is ValeResource: continue
		var offset: Vector3=node.global_position-center
		if absf(offset.x)>=20 or absf(offset.z)>=20: continue
		if node.remaining()>0:
			cleared+=1
			if cleared<=12: Feel.burst(game.world,node.global_position+Vector3(0,.5,0),Color(node.definition.color),6)
		# Establishment is land clearance, without gathering loot or profession XP.
		State.resource_states[node.persistent_id]={"hits":0,"respawn_day":0}
		State.gathered_resources[node.persistent_id]=true
		if is_instance_valid(node.body): node.body.collision_layer=0
	if cleared>0: Feel.sound("wood_hit",.6)
	# The camp address reserves this area during every later materialization,
	# including batched shrubs/rocks/grass and trees rooted just outside the fence.
	return cleared

func refresh_board(paid: bool=true) -> bool:
	if data().is_empty(): return false
	if paid and int(data().gold)<int(config.refresh_gold): return false
	if paid: data().gold-=int(config.refresh_gold)
	data().cycle+=1; data().offers.clear()
	# All categories remain visible, but each cycle has deterministic contract variations.
	for template in config.tasks:
		var offer: Dictionary=template.duplicate(true)
		var variation: int=absi((str(State.world_seed)+"/"+str(data().cycle)+"/"+offer.id).hash())%3
		offer.minutes+=variation*15; offer.rewards.gold+=variation
		offer.contract="%d/%s" % [data().cycle,offer.id]; data().offers.append(offer)
	State.save_requested.emit(); return true

func candidate() -> void:
	if data().is_empty() or not data().candidate.is_empty(): return
	if data().workers.size()>=int(level_data().population): data().next_traveler=now()+float(config.traveler_minutes); return
	var serial: int=int(data().next_worker); data().next_worker+=1
	var names: Array=["Tessa","Orin","Lina","Alden","Maeve","Corin","Fenna","Silas","Wren","Edda"]
	var skills: Dictionary={}
	for skill in ["gathering","mining","hunting","trading","scouting"]: skills[skill]=1+(serial+str(skill).hash())%3
	data().candidate={"id":"camp_worker_"+str(serial),"name":names[(serial-1)%names.size()],"level":1,"xp":0,"skills":skills,"appearance":{"skin":serial%4,"hair":serial%4,"outfit":serial%4,"cape":false},"assignment":"","joined":now(),"activity":"Arriving","residence":"Newcomer tent","trait":["Patient gatherer","Curious traveler","Steady companion"][serial%3],"arrived":now()}
	notify(data().candidate.name+" is approaching your camp. Speak to them by the board.")

func recruit() -> bool:
	if data().is_empty() or data().candidate.is_empty() or data().workers.size()>=int(level_data().population): return false
	var worker: Dictionary=data().candidate.duplicate(true); worker.activity="Settling in"; worker.joined=now()
	data().workers[worker.id]=worker; data().candidate={}; data().next_traveler=now()+float(config.traveler_minutes)
	notify(worker.name+" joined your camp."); return true

func meeting_reason() -> String:
	if data().is_empty() or data().candidate.is_empty(): return "No traveler is waiting."
	var id: String=data().candidate.id
	if not near_camp() or not actors.has(id): return "Visit your camp to meet the traveler."
	if actors[id].global_position.distance_to(game.player.position)>3: return "Walk up to the traveler to discuss joining."
	return ""

func refuse() -> void:
	if data().candidate.is_empty(): return
	var id: String=data().candidate.id
	if actors.has(id): actors[id].set_meta("departing",true)
	data().candidate={}; data().next_traveler=now()+float(config.traveler_minutes)
	notify("The traveler sets off. Another may visit tomorrow.")

func task_reason(task: Dictionary, selected: Array=[]) -> String:
	var reasons: Array[String]=[]
	if int(data().level)<int(task.level): reasons.append("Camp level %d" % task.level)
	if data().active.size()>=int(level_data().slots): reasons.append("All mission slots occupied")
	for facility in task.facilities:
		if facility not in level_data().facilities: reasons.append("Requires "+str(facility))
	for resource in task.cost:
		if int(data()[resource])<int(task.cost[resource]): reasons.append("%d %s" % [task.cost[resource],resource])
	var eligible: int=0
	for worker in data().workers.values():
		if worker.assignment=="" and worker.get("role","")=="" and int(worker.level)>=int(task.worker_level) and int(worker.skills.get(task.skill,0))>=int(task.skill_level): eligible+=1
	if eligible<int(task.workers): reasons.append("%d free residents: level %d, %s %d" % [task.workers,task.worker_level,task.skill,task.skill_level])
	if not selected.is_empty():
		var unique: Dictionary={}
		for id in selected:
			if unique.has(id) or not data().workers.has(id): reasons.append("Invalid worker selection"); continue
			unique[id]=true
			var worker: Dictionary=data().workers[id]
			if worker.assignment!="" or worker.get("role","")!="" or int(worker.level)<int(task.worker_level) or int(worker.skills.get(task.skill,0))<int(task.skill_level): reasons.append(worker.name+" is unavailable or lacks the required skill")
		if selected.size()!=int(task.workers): reasons.append("Select exactly %d residents" % task.workers)
	return " · ".join(reasons)

func assign(contract: String, selected: Array) -> bool:
	for task in data().offers:
		if task.contract!=contract: continue
		if selected.is_empty() or not task_reason(task,selected).is_empty(): return false
		var id: String="mission_"+str(data().next_job); data().next_job+=1
		for resource in task.cost: data()[resource]-=int(task.cost[resource])
		for worker_id in selected: data().workers[worker_id].assignment=id; data().workers[worker_id].activity="Leaving camp"
		data().active[id]={"id":id,"task":task.duplicate(true),"workers":selected.duplicate(),"start":now(),"end":now()+float(task.minutes)}
		data().offers.erase(task)
		# Replenish just the accepted contract, preserving every other board entry.
		var next: Dictionary=task.duplicate(true); next.contract=contract+"/"+id; data().offers.append(next)
		notify(task.name+": party departing."); return true
	return false

func add_rewards(reward: Dictionary) -> void:
	for resource in ["food","materials","gold"]: data()[resource]=int(data()[resource])+int(reward.get(resource,0))
	if not data().upgrade_pending and int(data().level)<5:
		data().xp=mini(int(level_data().xp),int(data().xp)+int(reward.get("xp",0)))
		data().upgrade_pending=int(data().xp)>=int(level_data().xp)

func resolve() -> void:
	if data().is_empty(): return
	for id in data().active.keys():
		var mission: Dictionary=data().active[id]
		if now()<float(mission.end): continue
		# Remove the pending mission before awarding. A saved completion cannot replay.
		data().active.erase(id)
		if id in data().completed: continue
		data().completed.append(id)
		if int(data().tier)>=3 and absi(id.hash())%12==0: State.add_item("map_fragment")
		while data().completed.size()>128: data().completed.pop_front()
		add_rewards(mission.task.rewards)
		for worker_id in mission.workers:
			var worker: Dictionary=data().workers[worker_id]; worker.assignment=""; worker.activity="Returning with supplies"; worker.returned=now()
			worker.xp+=int(mission.task.rewards.worker_xp)
			while int(worker.xp)>=int(worker.level)*50:
				worker.xp-=int(worker.level)*50; worker.level+=1
				for skill in worker.skills: worker.skills[skill]+=1
			if actors.has(worker_id): actors[worker_id].position=Vector3(0,0,15)
		notify(mission.task.name+" completed. Supplies reached camp.")
	if data().candidate.is_empty() and now()>=float(data().next_traveler): candidate()

func upgrade_reason() -> String:
	if int(data().level)>=5: return "Your hamlet has reached the final tier."
	if not data().upgrade_pending: return "Complete tasks to fill Camp XP."
	var missing: Array[String]=[]
	for resource in level_data().cost:
		if int(data()[resource])<int(level_data().cost[resource]): missing.append("%d %s" % [int(level_data().cost[resource])-int(data()[resource]),resource])
	return "Need "+", ".join(missing) if not missing.is_empty() else ""

func upgrade() -> bool:
	if not upgrade_reason().is_empty(): return false
	for resource in level_data().cost: data()[resource]-=int(level_data().cost[resource])
	data().level+=1; data().tier=data().level; data().xp=0; data().upgrade_pending=false
	sync_visual(true); notify("Camp upgraded to "+level_data().name+". Camp XP is growing again."); return true

func donate(item: String, amount: int) -> bool:
	if amount<1 or data().is_empty(): return false
	if item=="coins":
		if State.coins<amount: return false
		State.coins-=amount; data().gold+=amount
	else:
		if not config.contributions.has(item) or int(State.inventory.get(item,0))<amount: return false
		State.inventory[item]-=amount
		if int(State.inventory[item])==0: State.inventory.erase(item)
		for resource in config.contributions[item]: data()[resource]+=int(config.contributions[item][resource])*amount
	data().contributions[item]=int(data().contributions.get(item,0))+amount
	notify("Contribution delivered to camp storage."); return true

func advance(minutes: float) -> void:
	var time: float=now()+maxf(0,minutes)
	State.life_data.day=1+floori(time/1440); State.life_data.minute=fposmod(time,1440)
	resolve(); State.changed.emit()

func clear_visual() -> void:
	if is_instance_valid(visual): visual.get_parent().remove_child(visual); visual.queue_free()
	visual=null
	actors.clear(); revision=""

func near_camp() -> bool:
	if data().is_empty() or State.interior_data.has("active") or game.player.position.x>900: return false
	return absi(int(data().address.x)-game.generator.origin_x)<=2 and absi(int(data().address.z)-game.generator.origin_z)<=2 and game.generator.position_of(data().address).distance_to(game.player.position)<78

func prop(asset: String, p: Vector3, height: float, solid: bool=false) -> Node3D:
	p.y+=game.generator.landscape.height(Vector2(visual.position.x+p.x,visual.position.z+p.z))-visual.position.y
	var model: Node3D=game.world.place("res://assets/3d/phase7/"+asset+".glb",p,height,0,visual)
	if solid: game.world.solid(p+Vector3(0,height*.45,0),Vector3(height*.8,height*.9,height*.7),visual,model)
	return model

func sync_visual(force: bool=false) -> void:
	if not near_camp(): clear_visual(); return
	var stamp: String=str(game.generator.origin_x)+","+str(game.generator.origin_z)
	if stamp!=origin_stamp:
		origin_stamp=stamp
		for actor in actors.values(): actor.set_meta("target",Vector3.INF)
	var wanted: String=str(data().tier)+"/"+str(data().workers.size())
	for worker in data().workers.values(): wanted+="/"+str(worker.level)+"/"+str(now()-float(worker.joined)>=1440)
	if is_instance_valid(visual) and revision==wanted and not force:
		visual.position=game.generator.position_of(data().address); return
	clear_visual(); revision=wanted
	visual=Node3D.new(); visual.name="PlayerCamp"; game.world.add_child(visual); visual.position=game.generator.position_of(data().address)
	var tier: int=int(data().tier)
	prop("campfire-pit",Vector3.ZERO,.5)
	prop("campfire-stand",Vector3.ZERO,1.1)
	var light:=OmniLight3D.new(); light.light_color=Color("ffb66c"); light.light_energy=1.4; light.omni_range=7; light.position=Vector3(0,1,0); visual.add_child(light)
	if tier<4: prop("tent-canvas",Vector3(-6,0,-6),2.6,true)
	prop("tent-canvas",Vector3(6,0,-6),2.3,true)
	prop("chest",Vector3(4,0,3),.9,true); prop("signpost",Vector3(-4,0,3),1.7)
	prop("bedroll",Vector3(-2,0,-2),.15); prop("resource-wood",Vector3(3,0,-2),.65)
	for entry in [["Task board",Vector3(-4,0,4),"Tasks"],["Camp storage",Vector3(4,0,4),"Storage"]]:
		var target: ValeInteractable=game.world.interactable("camp",entry[0],entry[1],visual); target.set_meta("camp_action",entry[2])
	if tier>=2:
		for p in ([Vector3(-11,0,2),Vector3(11,0,2)] if tier==2 else ([Vector3(-11,0,2)] if tier==3 else [])): prop("tent-canvas",p,2.2,true)
		prop("workbench",Vector3(-5,0,8),1.2,true); prop("barrel",Vector3(5,0,7),1,true); prop("box",Vector3(6,0,7),.8,true)
		for z in range(-9,13,2):
			var p:=Vector3(0,0,z); p.y=game.generator.landscape.height(Vector2(visual.position.x,visual.position.z+z))-visual.position.y+.025
			game.world.box(p,Vector3(2.2,.035,2),"9c906b",false,visual)
	if tier>=3:
		house(Vector3(-11,0,9),10,"Camp workshop",3.2,"blacksmith")
		prop("workbench",Vector3(-8,0,7),1.2,true)
		for x in [-12,-8,8,12]: prop("fence",Vector3(x,0,13),1,true)
	if tier>=4:
		house(Vector3(0,0,-11),0,"Your home",4.2 if tier==4 else 5.5)
		var veterans: int=mini(3,data().workers.size())
		var sorted: Array=data().workers.values().duplicate(); sorted.sort_custom(func(a,b): return int(a.level)>int(b.level) or (int(a.level)==int(b.level) and float(a.joined)<float(b.joined)))
		for i in veterans:
			var worker: Dictionary=sorted[i]
			if int(worker.level)<2 and now()-float(worker.joined)<1440: continue
			worker.residence="Cottage "+str(i+1); house([Vector3(-11,0,-8),Vector3(11,0,-8),Vector3(-11,0,-1)][i],i+1,worker.name+"'s cottage",3.2)
			worker.home=data().buildings[str(i+1)].id
			State.residents[worker.id]={"id":worker.id,"npc_id":worker.id,"settlement":"player_camp","home":worker.home,"work":"","tavern":"","identity":{"name":worker.name,"role":"Camp resident","dialogue":"The cottage is warm. Thank you for making room for us."}}
	if tier>=5:
		prop("structure-canvas",Vector3(10,0,9),2.2,true); prop("barrel",Vector3(12,0,7),.8,true)
		State.npc_data.camp_trader=State.npc_data.merchant.duplicate(true); State.npc_data.camp_trader.name="Rook"
		var merchant: ValeInteractable=game.world.interactable("npc","Rook · Camp trader",Vector3(9,0,7),visual); merchant.npc_id="camp_trader"
	data().buildings["tier"]=tier

func house(p: Vector3,index: int,title: String,height: float,template: String="house") -> void:
	p.y=game.generator.landscape.height(Vector2(visual.position.x+p.x,visual.position.z+p.z))-visual.position.y
	var model: Node3D=game.world.place("res://assets/3d/medieval/house.gltf.glb",p,height,0,visual)
	game.world.solid(p+Vector3(0,height*.45,0),Vector3(height*.85,height*.9,height*.65),visual,model)
	var record: Dictionary=ValeInteriors.register(game.world,visual,"player_camp",index,template,p+Vector3(0,0,height*.4+1),title)
	data().buildings[str(index)]=record

func sync_actors(delta: float) -> void:
	if not is_instance_valid(visual): return
	var people: Array=data().workers.values().duplicate()
	if not data().candidate.is_empty(): people.append(data().candidate)
	for person in people:
		var id: String=person.id
		if not actors.has(id):
			var npc: ValeInteractable=game.world.interactable("npc",person.name,Vector3(0,0,15),visual)
			npc.npc_id=id; npc.set_meta("camp_action","Candidate" if not data().workers.has(id) else "Residents"); npc.set_meta("camp_person",id)
			State.npc_data[id]={"name":person.name,"role":"Camp resident","dialogue":"A warm fire and honest work make a good home."}
			npc.sprite.sprite_frames=PixelArt.character_frames(false,person.appearance)
			actors[id]=npc
		var actor: ValeInteractable=actors[id]
		actor.set_meta("camp_action","Residents" if data().workers.has(id) else "Candidate")
		var target:=Vector3(-2+absi(id.hash())%5,0,4)
		var night: bool=float(State.life_data.minute)<360 or float(State.life_data.minute)>=1320 or State.life_data.weather=="Storm"
		if person.assignment!="":
			target=Vector3(0,0,18); person.activity="On assignment"
			actor.visible=now()-float(data().active.get(person.assignment,{}).get("start",now()))<20
		elif night:
			target=Vector3(6,0,-4.5); person.activity="Sheltering" if State.life_data.weather=="Storm" else "Sleeping"
			if person.has("home"):
				var building: Dictionary=State.life_data.settlements.get("player_camp",{}).get("buildings",{}).get(person.home,{})
				if not building.is_empty(): target=visual.to_local(game.generator.position_of(building.door))
			actor.visible=actor.position.distance_to(target)>1
		else:
			actor.visible=true
			if data().workers.has(id):
				var step: int=(floori(now()/40)+absi(id.hash()))%5
				target=[Vector3(-2,0,1),Vector3(3,0,4.5),Vector3(-4,0,4.5),Vector3(2,0,2),Vector3(-5,0,6.5)][step]
				person.activity=["Resting by the fire","Carrying supplies","Reading the task board","Sharing a meal","Working at the bench"][step]
				var job: Dictionary=game.cultivation.worker_activity(person) if is_instance_valid(game.cultivation) else {}
				if not job.is_empty(): target=job.target; person.activity=job.activity
			else: person.activity="Waiting by the task board"
		if actor.visible:
			walk_actor(actor,target,delta)
			if actor.position.distance_to(target)<.35:
				if person.activity in ["Working at the bench","Tending the garden","Preparing meals","Processing timber","Foraging the camp edge"]: actor.sprite.play("slash_2")
				actor.sprite.scale.y=.8 if person.activity in ["Resting by the fire","Sharing a meal"] else 1.0
			if not actor.has_meta("crate"):
				var crate: Node3D=game.world.place("res://assets/3d/phase7/box.glb",Vector3(0,.8,.35),.4,0,actor); actor.set_meta("crate",weakref(crate))
			var crate: Node3D=actor.get_meta("crate").get_ref()
			crate.visible=person.activity in ["Carrying supplies","Returning with supplies"]
	for id in actors.keys():
		if not is_instance_valid(actors[id]): actors.erase(id); continue
		if actors[id].get_meta("departing",false):
			walk_actor(actors[id],Vector3(0,0,20),delta)
			if actors[id].position.z>19: actors[id].queue_free(); actors.erase(id)

func walk_actor(actor: ValeInteractable,target: Vector3,delta: float) -> void:
	if actor.get_meta("target",Vector3.INF)!=target:
		actor.set_meta("target",target); actor.set_meta("path",ValeResidents.route(actor,visual.to_global(target)))
	var path: PackedVector3Array=actor.get_meta("path",PackedVector3Array())
	var motion:=Vector3.ZERO
	if not path.is_empty():
		motion=path[0]-actor.global_position; motion.y=0
		if motion.length()<.18: path.remove_at(0); actor.set_meta("path",path)
		else:
			var next: Vector3=actor.global_position+motion.normalized()*minf(delta*1.5,motion.length())
			if next.distance_to(game.player.position)>.65:
				actor.global_position=next
	actor.position.y=game.generator.landscape.height(Vector2(actor.global_position.x,actor.global_position.z))-visual.position.y
	var local: Vector3=game.rig.camera.global_basis.inverse()*motion
	var direction: int=2 if absf(local.z)>absf(local.x) and local.z>0 else (0 if absf(local.z)>absf(local.x) else (3 if local.x>0 else 1))
	var animation: String=("walk_" if motion.length()>.18 else "idle_")+str(direction)
	if actor.sprite.sprite_frames.has_animation(animation): actor.sprite.play(animation)

func _process(delta: float) -> void:
	if placing:
		preview_address=game.generator.address(game.player.position+Vector3(0,0,-8))
		preview.position=game.generator.position_of(preview_address); preview.position.y=game.generator.landscape.height(Vector2(preview.position.x,preview.position.z))+.1
		clock-=delta
		if clock<=0:
			clock=.5; placement_reason=placement_at(preview_address); preview.material_override.albedo_color=Color(.3,.9,.5,.24) if placement_reason.is_empty() else Color(.95,.25,.2,.25)
			game.hud.show_toast("Enter: establish camp" if placement_reason.is_empty() else placement_reason)
	if data().is_empty(): return
	clock-=delta
	if clock<=0:
		clock=.5; resolve(); sync_visual()
	if not State.modal and not State.paused: sync_actors(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if placing and event.physical_keycode==KEY_ENTER: establish(preview_address); get_viewport().set_input_as_handled()
	if placing and event.physical_keycode==KEY_ESCAPE: cancel_placement(); get_viewport().set_input_as_handled()
