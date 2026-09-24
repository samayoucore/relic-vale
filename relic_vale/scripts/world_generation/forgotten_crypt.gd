extends Node3D
## Authored gallery and reliquary join the preserved entry chamber at x=1000.
var world: ValeWorld

func _ready() -> void:
	world.box(Vector3(1000,-.25,-11.5),Vector3(5,.5,4),"4c5b61",true,self)
	for x in [997.2,1002.8]: world.box(Vector3(x,.75,-11.5),Vector3(.6,1.5,4),"46565c",true,self)
	for z_center in [-22.0,-40.0]:
		world.box(Vector3(1000,-.3,z_center),Vector3(16,.6,18),"4c5b61",true,self)
		for x in range(993,1008,2):
			for z in range(int(z_center)-8,int(z_center)+9,2):
				world.box(Vector3(x,.015,z),Vector3(1.94,.03,1.94),"5c696d" if (x+z)%4==0 else "55636b",false,self)
		for x in [992.0,1008.0]:
			world.box(Vector3(x,1.3,z_center),Vector3(.8,2.6,18),"3e5059",true,self)
			for z in [z_center-6,z_center,z_center+6]:
				world.place(world.DUNGEON+"pillar_decorated.gltf.glb",Vector3(x,0,z),3.5,0,self)
		for p in [Vector3(994,2,z_center-5),Vector3(1006,2,z_center+5)]:
			world.place(world.DUNGEON+"torch_mounted.gltf.glb",p,.7,0,self)
			world.lantern(p,Color("91c9d5"),false,7)
	for x in [994.4,1005.6]:
		for z in [-13,-31]: world.box(Vector3(x,1.1,z),Vector3(5.6,2.2,.7),"42565f",true,self)
	world.box(Vector3(1000,1.5,-49),Vector3(16,3,.8),"3c505a",true,self)
	for p in [Vector3(995,0,-20),Vector3(1005,0,-25)]:
		world.box(p+Vector3(0,.6,0),Vector3(1.5,1.2,3),"778383",true,self)
		world.place(world.DUNGEON+"box_large.gltf.glb",p+Vector3(0,1.2,0),.7,0,self)
	spawn("skeleton",Vector3(998,0,-18),"")
	spawn("archer",Vector3(1003,0,-26),"")
	spawn("guardian",Vector3(1000,0,-38),"crypt/warden")
	var chest:=world.interactable("cache","The warden's treasure",Vector3(1004.5,0,-45),self)
	chest.persistent_id="crypt/final_treasure"
	chest.set_meta("loot_table","crypt_treasure")
	chest.set_meta("requires","crypt/warden")
	chest.model=world.place(world.DUNGEON+"chest.glb",Vector3.ZERO,1,0,chest)
	chest.synchronize()
	world.cylinder(Vector3(1000,.15,-43),2,.3,"788781",12,self)
	world.lantern(Vector3(1000,2.5,-43),Color("9ae3d5"),false,8)
	world.ambient_motes(Vector3(1000,2,-40),Vector3(6,2,6),Color("acd6d3"),35)

func spawn(kind: String, pos: Vector3, id: String) -> void:
	var enemy:=preload("res://scenes/characters/Enemy.tscn").instantiate()
	enemy.position=pos
	enemy.set_meta("archetype",kind)
	enemy.set_meta("persistent_id",id)
	enemy.set_meta("enemy_level",5 if kind=="guardian" else 3)
	add_child(enemy)
