class_name ValePOI
extends Node3D
## Small reusable handcrafted compositions. Their placement is seeded; their design is authored.
@export var kind: String = "camp"
var world: ValeWorld
var persistent_id: String

func _ready() -> void:
	world.cylinder(Vector3(0,-.005,0),5,.04,"8c9871" if kind!="ruin" else "8a927e",16,self)
	match kind:
		"camp": build_camp()
		"ruin": build_ruin()
		"shrine": build_shrine()
		"pond": build_pond()
		"crypt": build_crypt()

func cache(offset: Vector3) -> void:
	var chest:=world.interactable("cache","Explorer's cache",offset,self)
	chest.persistent_id=persistent_id+"/cache"
	chest.model=world.place(world.DUNGEON+"chest.glb",Vector3.ZERO,.8,0,chest)
	chest.opened=State.opened_chests.has(chest.persistent_id)
	chest.synchronize()

func build_camp() -> void:
	world.cylinder(Vector3(0,.05,0),1,.15,"68665b",10,self)
	for i in range(5):
		var a: float=i*TAU/5
		world.place(world.NATURE+"rock_smallA.glb",Vector3(sin(a),.1,cos(a)),.3,i*30,self)
	var log1:=world.box(Vector3(0,.25,0),Vector3(1.3,.3,.24),"63462f",false,self)
	log1.rotation.y=.5
	var log2:=world.box(Vector3(0,.4,0),Vector3(1.3,.3,.24),"765536",false,self)
	log2.rotation.y=-.5
	var ember:=world.cylinder(Vector3(0,.55,0),.25,.4,"e4ab67",5,self)
	ember.material_override=world.mat("e4ab67",true)
	world.box(Vector3(-2,.25,.8),Vector3(1.8,.45,.7),"7d6948",true,self)
	world.place(world.DUNGEON+"barrel_large.gltf.glb",Vector3(2,0,-1.6),.9,30,self)
	world.place(world.DUNGEON+"box_large.gltf.glb",Vector3(2.5,0,-.5),.7,8,self)
	cache(Vector3(-1.8,0,-2))

func build_ruin() -> void:
	world.box(Vector3(0,.03,0),Vector3(8,.08,7),"81897c",false,self)
	for p in [Vector3(-3,0,-2.5),Vector3(3,0,-2.5),Vector3(3,0,2.5)]:
		var column:=world.place(world.DUNGEON+"pillar_decorated.gltf.glb",p,3.3,0,self)
		world.solid(p+Vector3(0,1.2,0),Vector3(.9,2.4,.9),self,column)
	world.box(Vector3(0,.75,-3),Vector3(5,1.5,.6),"717d75",true,self)
	world.box(Vector3(-3,.55,0),Vector3(.6,1.1,3),"717d75",true,self)
	var rubble:=world.box(Vector3(2,.3,1),Vector3(1.8,.6,.8),"909785",false,self)
	rubble.rotation.y=.6
	cache(Vector3(0,0,-1.7))

func build_shrine() -> void:
	world.cylinder(Vector3(0,.2,0),1.5,.4,"818e7d",8,self)
	world.cylinder(Vector3(0,.65,0),.75,.55,"b5bba2",8,self)
	var shard:=world.cylinder(Vector3(0,1.3,0),.23,.85,"a2ddd0",5,self)
	shard.material_override=world.mat("a2ddd0",true)
	var altar:=world.interactable("shrine","Wayside wishing stone",Vector3(0,0,1.5),self)
	altar.persistent_id=persistent_id+"/shrine"
	for x in [-2.0,2.0]: world.place(world.NATURE+"plant_bush.glb",Vector3(x,0,-1),.8,0,self)

func build_pond() -> void:
	world.cylinder(Vector3(0,.015,0),4.5,.1,"aaae81",24,self)
	var water:=world.cylinder(Vector3(0,.09,0),4,.07,"437c7a",28,self)
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/water.gdshader")
	water.material_override=material
	for i in range(8):
		var a: float=i*TAU/8
		world.place(world.NATURE+"plant_bushSmall.glb",Vector3(sin(a)*4.4,0,cos(a)*4.4),.55,i*15,self)
	cache(Vector3(4.8,0,1.7))

func build_crypt() -> void:
	for x in [-2.6,2.6]:
		var pillar:=world.place(world.DUNGEON+"pillar_decorated.gltf.glb",Vector3(x,0,-1),3.8,0,self)
		world.solid(Vector3(x,1.5,-1),Vector3(1.1,3,1.1),self,pillar)
	world.box(Vector3(0,3.4,-1),Vector3(5.8,.65,1.2),"69756e",false,self)
	world.box(Vector3(0,1.5,-1.5),Vector3(4,3,.4),"253c3d",true,self)
	world.box(Vector3(0,.1,.2),Vector3(6,.2,3),"8a9585",false,self)
	var door:=world.interactable("entrance","Forgotten Crypt",Vector3(0,0,1.4),self)
	door.persistent_id=persistent_id+"/door"
