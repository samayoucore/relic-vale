class_name ValeInteriors
extends Node3D
## Exactly one interior is instantiated. Its exterior is an integer logical address.
const CENTER:=Vector3(3000,0,0)
const PROPS="res://assets/3d/phase6/props/"
var game: Node
var room: Node3D
var active: Dictionary={}
var transitioning: bool=false
var veil: ColorRect
var anchors: Array[Dictionary]=[]
var occupants: Dictionary={}
var clock: float=0
var sound_clock: float=0
var exterior_camera: Dictionary={}

func _ready() -> void:
	game=get_tree().current_scene; set_meta("interior",true)
	var canvas:=CanvasLayer.new(); canvas.layer=50; add_child(canvas)
	veil=ColorRect.new(); veil.color=Color(0,0,0,0); veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); canvas.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func register(world: ValeWorld,parent: Node3D,settlement: String,index: int,template: String,position: Vector3,title: String) -> Dictionary:
	var id: String=settlement+"/building/"+str(index)
	var door:=world.interactable("building",title,position,parent)
	var address: Dictionary=world.generator.address(door.global_position)
	var record: Dictionary={"id":id,"settlement":settlement,"template":template,"title":title,"door":address}
	door.persistent_id=id; door.set_meta("building",record)
	var plaque:=world.box(Vector3(0,1.6,-.18),Vector3(.65,.32,.08),"775432",false,door)
	plaque.set_meta("sign",true)
	if not State.life_data.settlements.has(settlement): State.life_data.settlements[settlement]={}
	if not State.life_data.settlements[settlement].has("buildings"): State.life_data.settlements[settlement].buildings={}
	State.life_data.settlements[settlement].buildings[id]=record
	return record

func setup_hub() -> void:
	var id: String="%d/willowmere" % State.world_seed
	var root: Node3D=game.world.hub_root
	if not root.is_inside_tree(): return
	# On a new seed the retained authored shell gets fresh IDs and resident records.
	for node in root.get_children():
		if node.has_meta("authored_resource"):
			node.persistent_id="%d/resource/hub/%s" % [State.world_seed,node.get_meta("authored_resource")]; node.synchronize()
		if node.get_meta("phase6",false): root.remove_child(node); node.queue_free()
	var list: Array=[]
	for entry in [[Vector3(-8,0,-2.6),"house","Rowan's cottage"],[Vector3(7,0,-4.9),"blacksmith","Bram's forge"],[Vector3(-14,0,5.6),"tavern","The Willow Hearth"],[Vector3(10,0,10.1),"alchemist","Hearthroot apothecary"],[Vector3(.2,0,-8.5),"shop","Mira's provisions"]]:
		var record: Dictionary=register(game.world,root,id,list.size(),entry[1],entry[0],entry[2]); list.append(record)
	for node in root.get_children():
		if node is ValeInteractable and node.kind=="building": node.set_meta("phase6",true)
	for pair in [["rowan",0,-1],["smith",1,1],["merchant",4,4],["keeper",0,-1],["willow_alchemist",3,3],["willow_innkeeper",2,2],["willow_carpenter",0,-1],["willow_fisher",0,4],["willow_farmer",0,4]]:
		var npc_id: String=pair[0]
		if not State.npc_data.has(npc_id):
			var category: String="alchemist" if pair[2]==3 else ("carpenter" if npc_id=="willow_carpenter" else "general")
			State.npc_data[npc_id]={"name":"Liora" if pair[2]==3 else ("Tobin" if category=="carpenter" else "Hazel"),"role":category.capitalize(),"category":category,"shop":true,"dialogue":"A warm hearth and honest work make a village. Take a look at my supplies."}
		var actor: ValeInteractable
		for node in root.get_children():
			if node is ValeInteractable and node.kind=="npc" and node.npc_id==npc_id: actor=node
		if not actor:
			actor=game.world.interactable("npc",State.npc_data[npc_id].name,Vector3(3+list.size()%3,0,5),root); actor.npc_id=npc_id; actor.set_meta("phase6",true)
		var resident_id: String=id+"/resident/"+npc_id
		var work_id: String=list[pair[2]].id if int(pair[2])>=0 else ""
		ValeResidents.bind(actor,resident_id,id,list[pair[1]].id,work_id,list[2].id)
		if not actor.has_meta("schedule"): ValeSchedule.attach(actor,actor.global_position,root.to_global(Vector3(0,0,5.5)))
	# A small open-front pasture beside the mill; all animals remain non-hostile.
	var farm:=Node3D.new(); farm.set_meta("phase6",true); root.add_child(farm); farm.position=Vector3(20,0,10)
	for x in [-4.0,4.0]:
		for z in [-3.0,-1.0,1.0,3.0]: game.world.box(Vector3(x,.55,z),Vector3(.12,1.1,.12),"806245",false,farm)
		game.world.box(Vector3(x,.7,0),Vector3(.09,.12,6),"987954",false,farm)
	for i in 3:
		var animal:=ValeFauna.new(); animal.gen=game.generator; animal.species=["cow","alpaca","horse"][i]; animal.farm=true; animal.group_id=id+"/pasture"; animal.position=Vector3(i*2-2,0,0); farm.add_child(animal)
	game.world.place(PROPS+"FarmCrate_Carrot.gltf",Vector3(-2,0,-2),.6,0,farm)
	game.world.place(PROPS+"Barrel.gltf",Vector3(3,0,-2),.9,0,farm)
	# One small herd in the authored woodland introduces wildlife along the forest trail.
	for i in 2:
		var animal:=ValeFauna.new(); animal.gen=game.generator; animal.species="deer" if i else "stag"
		animal.set_meta("phase6",true); animal.group_id=id+"/woodland"; animal.position=Vector3(34+i*2,0,15); root.add_child(animal)

func enter(building: Dictionary,restore: bool=false) -> void:
	if transitioning: return
	if is_instance_valid(game.mounts): game.mounts.park()
	if is_instance_valid(game.fishing): game.fishing.cancel()
	transitioning=true; game.player.gathering.cancel(); game.player.combat.cancel()
	if not restore:
		State.interior_data.active={"building":building.duplicate(true),"return":game.generator.address(game.player.global_position)}
		exterior_camera={"zoom":game.rig.zoom,"yaw":game.rig.yaw,"pitch":game.rig.pitch}
		State.interior_data.active.camera=exterior_camera.duplicate()
	State.modal=true
	Feel.sound("door_01",.25)
	await fade(1)
	clear_room()
	active=building.duplicate(true)
	room=Node3D.new(); room.name="Interior_"+building.template; room.position=CENTER; add_child(room)
	game.generator.process_mode=Node.PROCESS_MODE_DISABLED
	if is_instance_valid(game.world.hub_root): game.world.hub_root.process_mode=Node.PROCESS_MODE_DISABLED
	build_room(building)
	game.player.global_position=CENTER+Vector3(0,.1,4.5); game.player.velocity=Vector3.ZERO
	game.rig.zoom=14; game.rig.target_zoom=14; game.rig.yaw=deg_to_rad(8); game.rig.target_yaw=game.rig.yaw; game.rig.pitch=55; game.rig.target_pitch=55; game.rig.snap()
	refresh_occupants(true)
	await get_tree().physics_frame; await get_tree().physics_frame
	State.modal=false; game.hud.close_modal(); game.hud.show_toast(building.title)
	await fade(0); transitioning=false
	if not restore: State.save_requested.emit()

func leave() -> void:
	if transitioning or active.is_empty(): return
	transitioning=true; State.modal=true; game.player.gathering.cancel()
	await fade(1)
	var record: Dictionary=State.interior_data.active.duplicate(true)
	clear_room(); active={}; State.interior_data.erase("active")
	game.generator.process_mode=Node.PROCESS_MODE_INHERIT
	if is_instance_valid(game.world.hub_root): game.world.hub_root.process_mode=Node.PROCESS_MODE_INHERIT
	var address: Dictionary=record.return
	# Rebuild the destination synchronously before revealing the player, even after reload/far travel.
	game.generator.teleport_logical(int(address.x),int(address.z),ValeSave.vector(address.local))
	var camera: Dictionary=record.get("camera",{})
	game.rig.zoom=float(camera.get("zoom",24)); game.rig.target_zoom=game.rig.zoom; game.rig.yaw=float(camera.get("yaw",deg_to_rad(42))); game.rig.target_yaw=game.rig.yaw
	game.rig.pitch=float(camera.get("pitch",50)); game.rig.target_pitch=game.rig.pitch; game.rig.snap()
	await get_tree().physics_frame; await get_tree().physics_frame
	State.modal=false; await fade(0); transitioning=false
	State.save_requested.emit()

func fade(alpha: float) -> void:
	veil.mouse_filter=Control.MOUSE_FILTER_STOP if alpha>0 else Control.MOUSE_FILTER_IGNORE
	var tween:=create_tween(); tween.tween_property(veil,"color:a",alpha,.22); await tween.finished

func clear_room() -> void:
	if is_instance_valid(room): remove_child(room); room.queue_free()
	room=null; occupants.clear(); anchors.clear()

func reset() -> void:
	clear_room(); active={}; transitioning=false; veil.color.a=0
	game.generator.process_mode=Node.PROCESS_MODE_INHERIT
	if is_instance_valid(game.world.hub_root): game.world.hub_root.process_mode=Node.PROCESS_MODE_INHERIT

func prop(asset: String,p: Vector3,height: float=1,yaw: float=0,solid: bool=false) -> Node3D:
	var model: Node3D=game.world.place(PROPS+asset+".gltf",p,height,yaw,room)
	if asset in ["Book_5","Table_Plate"]:
		var bounds: AABB=game.world.bounds(model)
		model.scale*=(.45 if asset=="Table_Plate" else .35)/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
	if solid:
		var bounds: AABB=game.world.bounds(model)
		game.world.solid(bounds.get_center(),Vector3(maxf(.3,bounds.size.x*.75),maxf(.3,bounds.size.y),maxf(.3,bounds.size.z*.75)),room,model)
	return model

func anchor(tag: String,p: Vector3,facing: Vector3=Vector3.FORWARD) -> void:
	anchors.append({"tag":tag,"position":CENTER+p,"facing":facing,"resident":""})

func build_room(building: Dictionary) -> void:
	var world: ValeWorld=game.world
	var type: String=building.template
	var rng:=RandomNumberGenerator.new(); rng.seed=building.id.hash()
	world.box(Vector3(0,-.22,0),Vector3(90,.3,90),"262c29",false,room)
	world.box(Vector3(0,-.08,0),Vector3(14,.16,12),"866746",true,room)
	for x in range(-6,7): world.box(Vector3(x,.012,0),Vector3(.022,.015,11.8),"684d36",false,room)
	for wall in [[Vector3(0,1.5,-6),Vector3(14,3,.25)],[Vector3(-7,1.5,0),Vector3(.25,3,12)],[Vector3(7,1.5,0),Vector3(.25,3,12)],[Vector3(-4,1,6),Vector3(6,2,.25)],[Vector3(4,1,6),Vector3(6,2,.25)]]:
		var visual:=world.box(wall[0],wall[1],"b49c76",false,room); world.solid(wall[0],wall[1],room,visual)
	world.solid(Vector3(0,1,6.3),Vector3(2,2,.2),room)
	for x in [-6.8,-3.4,0,3.4,6.8]: world.box(Vector3(x,1.5,-5.8),Vector3(.2,3,.25),"624733",false,room)
	var carpet: String=["8b514d","5b7274","6c7654"][rng.randi_range(0,2)]
	world.box(Vector3(0,.025,.5),Vector3(4,.035,5),carpet,false,room)
	world.box(Vector3(0,.046,.5),Vector3(3.6,.009,4.6),"ad9265",false,room)
	world.box(Vector3(0,.055,.5),Vector3(3.4,.009,4.4),carpet,false,room)
	var exit:=world.interactable("building_exit","Outside · "+building.title,Vector3(0,0,5.25),room)
	exit.persistent_id=building.id+"/exit"
	anchor("Door",Vector3(0,0,4.3))
	prop("Cabinet",Vector3(-5.8,0,-4.8),2.1,0,true)
	prop("Bookcase_2",Vector3(5.7,0,-4.8),2.3,0,true); anchor("Bookshelf",Vector3(5.4,0,-3.5),Vector3.FORWARD)
	prop("Book_Stack_1",Vector3(-5.5,1.5,-4.8),.28)
	# A masonry hearth is part of the room shell; its fuel and accessories are imported.
	world.box(Vector3(0,.7,-5.1),Vector3(2,1.4,1.2),"625e52",true,room)
	world.box(Vector3(0,.55,-4.43),Vector3(1.3,.85,.02),"211f1b",false,room)
	world.place(world.NATURE+"log.glb",Vector3(0,.2,-4.35),.3,0,room)
	world.cylinder(Vector3(0,.48,-4.4),.34,.35,"e6a552",7,room).material_override=world.mat("e6a552",true)
	for p in [Vector3(0,2.2,-3.8),Vector3(-4,2.4,1),Vector3(4,2.4,1)]:
		var light:=OmniLight3D.new(); light.position=p; light.light_color=Color("ffcf92"); light.light_energy=1.5; light.omni_range=9; room.add_child(light)
	prop("Chandelier",Vector3(0,3.4,0),.8)
	if type=="house":
		for x in [-4.8,4.8]:
			prop("Bed_Twin1" if x<0 else "Bed_Twin2",Vector3(x,0,2),1.2,0,true); anchor("Bed",Vector3(x,.65,2))
		prop("Bed_Twin2",Vector3(4.8,0,-1.8),1.1,0,true); anchor("Bed",Vector3(4.8,.6,-1.8))
		prop("Table_Large",Vector3(-2.6,0,-1.7),.9,0,true); prop("Book_5",Vector3(-2.6,.94,-1.7),.16,60)
		prop("Chair_1",Vector3(-2.6,0,-.3),.95,180); anchor("Chair",Vector3(-2.6,.3,-.3))
		prop("Mug",Vector3(-2,.95,-1.7),.18)
	elif type=="tavern":
		for x in [-4.0,3.7]:
			prop("Table_Large",Vector3(x,0,.5),.95,0,true)
			for side in [-1.0,1.0]:
				prop("Chair_1",Vector3(x,0,.5+side*1.5),1,0 if side<0 else 180)
				anchor("TavernSeat",Vector3(x,.28,.5+side*1.5),Vector3(0,0,-side))
			prop("Mug",Vector3(x,.99,.5),.2); prop("Table_Plate",Vector3(x+.45,.99,.5),.08)
		prop("Workbench",Vector3(3.6,0,-3.4),1.1,0,true); anchor("Market",Vector3(3.6,0,-4.5),Vector3.BACK)
		for x in [2.5,4.7]: prop("Barrel",Vector3(x,0,-5.3),1.1)
		prop("Bed_Twin2",Vector3(-5.3,0,-3.8),1.1,90,true); anchor("Bed",Vector3(-5.3,.6,-3.8),Vector3.LEFT)
	elif type=="blacksmith":
		prop("Anvil_Log",Vector3(-3,0,-1),1.2,0,true); anchor("Forge",Vector3(-3,0,.2))
		prop("Workbench",Vector3(3,0,-3.2),1.1,0,true); anchor("Workbench",Vector3(3,0,-1.8))
		prop("Whetstone",Vector3(4.8,0,.6),1,40,true)
		prop("Axe_Bronze",Vector3(3,1.15,-3.2),.75,90)
		prop("Pickaxe_Bronze",Vector3(3.8,1.15,-3.2),.7,70)
		prop("Crate_Wooden",Vector3(-5,0,3),.9,15,true)
	elif type=="alchemist":
		prop("Workbench",Vector3(-3,0,-2),1,0,true); anchor("Workbench",Vector3(-3,0,-.6))
		prop("SmallBottles_1",Vector3(-3,1.03,-2),.4); prop("Potion_1",Vector3(-2.3,1.03,-2),.4)
		prop("Cauldron",Vector3(2.8,0,-2),1.1,0,true); anchor("Cauldron",Vector3(2.8,0,-.7))
		prop("FarmCrate_Carrot",Vector3(4.5,0,3),.6,0,true)
	else:
		prop("Workbench",Vector3(0,0,-2.2),1.1,0,true); anchor("Market",Vector3(0,0,-3.5),Vector3.BACK)
		for x in [-4.5,4.5]:
			prop("Crate_Wooden",Vector3(x,0,1.8),1,15,true); prop("Barrel_Apples",Vector3(x,0,-1),1.1,0,true)
		prop("Bag",Vector3(.3,1.15,-2.2),.4)
	if type in ["blacksmith","alchemist"]:
		var station:=ValeSettlement.station(world,"forge" if type=="blacksmith" else "alchemy",Vector3(-5.5,0,1),room)
		station.title="Forge recipes" if type=="blacksmith" else "Alchemy recipes"
	if type=="tavern" or building.id==State.camp_data.get("buildings",{}).get("0",{}).get("id",""):
		var kitchen: ValeInteractable=world.interactable("station","Kitchen",Vector3(0,0,-3.4),room)
		kitchen.set_meta("station","kitchen")
		world.place("res://assets/3d/phase8/ultimatefood/CookingPot_Soup.glb",Vector3(0,1.42,-4.9),.45,0,room)
	if type in ["blacksmith","alchemist","shop"]:
		prop("Bed_Twin2",Vector3(-5.2 if type!="blacksmith" else 4.5,0,3.9),1.05,90,true)
		anchor("Bed",Vector3(-5.2 if type!="blacksmith" else 4.5,.6,3.9),Vector3.LEFT)
	var storage:=world.interactable("storage","Household chest",Vector3(5.5,0,4.3),room)
	storage.persistent_id=building.id+"/storage"; storage.model=prop("Chest_Wood",storage.position,.7)
	for x in [-1.5,1.5]:
		prop("Chair_1",Vector3(x,0,2.8),.95,180); anchor("Chair",Vector3(x,.28,2.8))

func refresh_occupants(initial: bool=false) -> void:
	if active.is_empty() or not is_instance_valid(room): return
	var wanted: Dictionary={}
	for id in State.residents:
		var record: Dictionary=State.residents[id]
		if record.settlement!=active.settlement: continue
		if ValeResidents.destination(record)!=active.id: continue
		wanted[id]=true
		if occupants.has(id): continue
		var npc_id: String=record.npc_id
		State.npc_data[npc_id]=record.identity.duplicate(true)
		var npc: ValeInteractable=game.world.interactable("npc",record.identity.name,CENTER+Vector3(0,0,4),room)
		npc.position=Vector3((occupants.size()%3-1)*.65,0,4); npc.npc_id=npc_id
		npc.sprite.modulate=Color(["c8d9ca","dcc8b3","c6cfdf","dfc3cc"][absi(npc_id.hash())%4])
		npc.set_meta("resident",id); npc.set_meta("inside",true)
		if record.settlement=="player_camp":
			npc.set_meta("camp_action","Residents")
			npc.sprite.modulate=Color.WHITE
			npc.sprite.sprite_frames=PixelArt.character_frames(false,State.camp_data.workers[id].appearance)
		npc.set_meta("initial_activity",initial)
		var controller:=ValeIndoorActivity.new(); controller.manager=self; controller.npc=npc; controller.record=record; npc.add_child(controller)
		occupants[id]=npc
	for id in occupants.keys():
		if wanted.has(id): continue
		for controller in occupants[id].get_children():
			if controller is ValeIndoorActivity: controller.depart()

func _process(delta: float) -> void:
	if active.is_empty(): return
	game.world.environment.ambient_light_color=Color("dcc4a0"); game.world.environment.ambient_light_energy=.5
	game.world.environment.fog_density=.0001; game.world.sun.light_energy=.2
	sound_clock-=delta
	if sound_clock<=0 and not State.paused and not State.modal:
		sound_clock=randf_range(5,10)
		if active.template=="tavern": Feel.sound("glass_01",.09)
		elif active.template=="blacksmith": Feel.sound("metal_hit_01",.09)
		elif active.template=="alchemist": Feel.sound("loop_water_01",.05)
		else: Feel.sound("wood_03",.04)
	clock-=delta
	if clock<=0 and not transitioning: clock=1; refresh_occupants()
