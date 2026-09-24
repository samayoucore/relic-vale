class_name ValeStoryPOI
extends ValePOI

func _ready() -> void:
	match kind:
		"grove":
			world.place(world.NATURE+"tree_oak.glb",Vector3(0,0,-1),10,0,self)
			for i in 9:
				var p:=Vector3(sin(i*TAU/9)*4,0,cos(i*TAU/9)*4)
				world.place(world.NATURE+"mushroom_redGroup.glb",p,.7,i*40,self)
		"graveyard", "chapel":
			if kind=="chapel": build_ruin()
			for i in 6:
				var p:=Vector3((i%3)*2-2,0,(i/3)*2-1)
				world.box(p+Vector3(0,.5,0),Vector3(.7,1,.22),"7b8777",false,self)
				world.place(world.NATURE+"plant_bushSmall.glb",p+Vector3(.5,0,.4),.4,0,self)
			entrance("crypt",Vector3(0,0,3.5))
		"mine", "cave":
			world.place(world.NATURE+"cliff_cave_rock.glb",Vector3(0,0,-1.5),4.5,0,self)
			for x in [-1.8,1.8]: world.box(Vector3(x,1.3,0),Vector3(.3,2.6,.3),"876046",true,self)
			world.box(Vector3(0,2.5,0),Vector3(4,.35,.4),"876046",false,self)
			world.place(world.DUNGEON+"barrel_large.gltf.glb",Vector3(3,0,0),1,0,self)
			entrance("mine",Vector3(0,0,2))
		"wagon":
			world.box(Vector3(0,.65,0),Vector3(2,.2,1.1),"876046",false,self)
			for x in [-.7,.7]:
				for z in [-.65,.65]:
					var wheel:=world.cylinder(Vector3(x,.45,z),.45,.16,"604334",12,self)
					wheel.rotation_degrees.x=90
			world.box(Vector3(1.5,.65,0),Vector3(1.6,.12,.12),"876046",false,self)
			world.place(world.DUNGEON+"box_large.gltf.glb",Vector3(2,0,1),.7,40,self)
			world.place(world.NATURE+"log.glb",Vector3(-2,0,2),.4,90,self)
			cache(Vector3(2,0,-1))
		"battlefield":
			for i in 8:
				world.place(world.NATURE+"rock_smallA.glb",Vector3(sin(i*2.3)*4,0,cos(i*2.3)*3),.4,i*30,self)
				world.box(Vector3(sin(i*2.3)*4,.2,cos(i*2.3)*3),Vector3(.12,.7,.08),"abb6a0",false,self).rotation.z=.65
			cache(Vector3(0,0,1))
		"circle":
			for i in 7: world.place(world.NATURE+"rock_tallA.glb",Vector3(sin(i*TAU/7)*4,0,cos(i*TAU/7)*4),2.5,i*50,self)
			build_shrine()
		"lumber":
			for i in 5: world.place(world.NATURE+"log.glb",Vector3(i*.8-2,0,-1),.5,15,self)
			world.place(world.DUNGEON+"box_large.gltf.glb",Vector3(2,0,1),1,0,self)
			ValeSettlement.station(world,"workbench",Vector3(0,0,3),self)
		"well":
			world.cylinder(Vector3(0,.5,0),1.2,1,"859082",12,self)
			world.cylinder(Vector3(0,1.02,0),.8,.04,"253c3d",12,self)
			world.place(world.NATURE+"plant_bushSmall.glb",Vector3(1.3,0,.5),.8,0,self)
			cache(Vector3(-2,0,1))
		"hunter":
			build_camp()
			world.place(world.NATURE+"log.glb",Vector3(2,0,2),.6,100,self)
			ValeSettlement.station(world,"campfire",Vector3(0,0,3),self)

func entrance(theme: String, p: Vector3) -> void:
	var node:=world.interactable("dungeon","Veilbound Crypt" if theme=="crypt" else "Old Ironvein Mine",p,self)
	node.persistent_id=persistent_id+"/expedition"
	node.set_meta("theme",theme)
