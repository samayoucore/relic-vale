class_name ValeSettlement
extends Node3D
var world: ValeWorld
var definition: Dictionary

func _ready() -> void:
	var kind: String=definition.settlement
	var rng:=RandomNumberGenerator.new()
	rng.seed=definition.id.hash()
	var central: String="well" if kind=="forest" else ("windmill" if kind=="mining" else "market_stall")
	# Reuse the same village family; central features and yard layouts distinguish each template.
	if kind=="forest":
		world.place(world.NATURE+"tree_oak.glb",Vector3(0,0,-1),7.5,0,self)
	else:
		world.place(world.VILLAGE+("mine" if kind=="mining" else "market")+".gltf.glb",Vector3(0,0,-3),5.4 if kind=="mining" else 2.4,0,self)
	world.cylinder(Vector3(0,.02,3),3.8,.06,"b7a07a",24,self)
	var buildings: Array=[]
	for i in 3:
		var p:=Vector3(-7 if i==0 else (7 if i==1 else 0),0,-4 if i<2 else -10)
		var building:=world.place(world.VILLAGE+"house.gltf.glb",p,4.1+rng.randf()*.5,rng.randf_range(-9,9),self)
		world.solid(p+Vector3(0,1.8,0),Vector3(3.7,3.6,3.7),self,building)
		buildings.append(ValeInteriors.register(world,self,definition.id,i,"tavern" if i==2 else ("shop" if i==0 else ("blacksmith" if kind=="mining" else "alchemist")),p+Vector3(0,0,2.6),definition.title+" · "+(["Provisions","Forge" if kind=="mining" else "Apothecary","Tavern"][i])))
		for x in [-2.0,2.0]:
			world.box(p+Vector3(x,.45,2.6),Vector3(.15,.9,2),"876046",false,self)
		world.place(world.DUNGEON+"barrel_large.gltf.glb",p+Vector3(2.4,0,1),.8,20,self)
		world.place(world.NATURE+"plant_bushSmall.glb",p+Vector3(-2.2,0,2),.6,40,self)
		var glow:=world.box(p+Vector3(.9,1.7,1.9),Vector3(.6,.6,.05),"f6d598",false,self)
		glow.material_override=world.mat("f6d598",true)
	# Wide central lanes connect building entrances and the external access road.
	for x in [-7.0,7.0]:
		world.box(Vector3(x,.035,1),Vector3(2,.055,7),"b7a07a",false,self)
	world.box(Vector3(0,.035,4),Vector3(16,.055,2.3),"b7a07a",false,self)
	world.box(Vector3(0,.035,8),Vector3(2.7,.055,8),"b7a07a",false,self)
	var cottage_position:=Vector3(-8,0,8)
	var cottage:=world.place(world.VILLAGE+"house.gltf.glb",cottage_position,4.2,0,self)
	world.solid(cottage_position+Vector3(0,1.8,0),Vector3(3.7,3.6,3.7),self,cottage)
	buildings.append(ValeInteriors.register(world,self,definition.id,3,"house",cottage_position+Vector3(0,0,2.6),definition.title+" · Farmhouse"))
	world.box(Vector3(-4,.035,10.8),Vector3(8,.055,1.8),"b7a07a",false,self)
	var npc_ids: Array=["fernwatch_ranger","fernwatch_alchemist"] if kind=="forest" else (["ironvein_smith"] if kind=="mining" else ["crossroads_trader"])
	for i in npc_ids.size():
		var id: String=npc_ids[i]
		if "/region/" in definition.id:
			var source: Dictionary=State.npc_data[id].duplicate(true)
			id=definition.id+"/resident/"+str(i)
			source.name=["Alden","Bria","Cora","Dain","Edda","Finn","Greta","Hale"][absi(id.hash())%8]+" "+["Reed","Moss","Vale","Brook"][absi((id+"surname").hash())%4]
			State.npc_data[id]=source
		var npc:=world.interactable("npc",State.npc_data[id].name+" · "+State.npc_data[id].role,Vector3(-7 if i==0 else 7,0,.5),self)
		npc.npc_id=id
		ValeResidents.bind(npc,definition.id+"/resident/"+str(i),definition.id,buildings[1 if kind=="mining" or i==1 else 0].id,buildings[1 if kind=="mining" or i==1 else 0].id,buildings[2].id)
		ValeSchedule.attach(npc,npc.global_position,to_global(Vector3(i*1.5,0,4)))
	for i in 4:
		var id: String=definition.id+"/villager/"+str(i)
		State.npc_data[id]={"name":"Innkeeper "+["Robin","Ash","Nell","Wren"][absi(id.hash())%4] if i==0 else "Farmer "+["Perrin","Rosa","Hollis","Meryl"][absi(id.hash())%4],"role":"Innkeeper" if i==0 else "Farmer","category":"general","shop":i==0,"dialogue":"The hearth is warm. Travelers are welcome here."}
		var npc:=world.interactable("npc",State.npc_data[id].name,Vector3(i*2,0,5),self); npc.npc_id=id
		ValeResidents.bind(npc,id,definition.id,buildings[2 if i==0 else 3].id,buildings[2].id if i==0 else "",buildings[2].id)
		ValeSchedule.attach(npc,npc.global_position,to_global(Vector3(i*2,0,5)))
	if kind=="forest":
		for i in 2:
			var animal:=ValeFauna.new(); animal.gen=world.generator; animal.species="cow" if i==0 else "alpaca"; animal.farm=true; animal.group_id=definition.id; animal.position=Vector3(11+i*2,0,7); add_child(animal)
	var stations: Array=["alchemy","workbench"] if kind=="forest" else (["forge","workbench"] if kind=="mining" else ["campfire"])
	for i in stations.size(): station(world,stations[i],Vector3(4+i*2,0,6),self)
	State.life_data.settlements[definition.id].merge({"name":definition.title,"position":[global_position.x,global_position.y,global_position.z],"address":world.generator.address(global_position),"kind":kind},true)
	var lamp:=OmniLight3D.new()
	lamp.position=Vector3(0,2,4)
	lamp.light_color=Color("ffd38f")
	lamp.omni_range=8
	add_child(lamp)
	world.lanterns.append(lamp)

static func station(world: ValeWorld, kind: String, pos: Vector3, parent: Node3D) -> ValeInteractable:
	var node:=world.interactable("station",kind.capitalize(),pos,parent)
	node.set_meta("station",kind)
	if kind=="campfire":
		world.place(world.NATURE+"log.glb",Vector3.ZERO,.35,0,node)
		world.cylinder(Vector3(0,.35,0),.3,.4,"d49c5a",6,node).material_override=world.mat("d49c5a",true)
	else:
		world.box(Vector3(0,.65,0),Vector3(1.2,.18,.7),"876046",false,node)
		for x in [-.45,.45]: world.box(Vector3(x,.3,0),Vector3(.15,.6,.55),"604334",false,node)
		world.place(world.DUNGEON+("chest.glb" if kind=="workbench" else "box_large.gltf.glb"),Vector3(0,.74,0),.28,0,node)
		world.cylinder(Vector3(.3,.9,0),.13,.25,"8dc3b0" if kind=="alchemy" else "cf8c56",6,node)
	return node
