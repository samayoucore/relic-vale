class_name ValeDungeonRoom
extends Node3D
@export var room_kind: String="combat"
var world: ValeWorld
var theme: String="crypt"
var doors: Array[Vector2i]=[]

func _ready() -> void:
	var floor_color: String="596568" if theme=="crypt" else "716653"
	var wall_color: String="46585c" if theme=="crypt" else "625e50"
	world.box(Vector3(0,-.3,0),Vector3(16,.6,16),floor_color,true,self)
	for x in range(-7,8,2):
		for z in range(-7,8,2): world.box(Vector3(x,.015,z),Vector3(1.93,.03,1.93),"65716b" if theme=="crypt" else "7d735d",false,self)
	for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		var axis:=Vector3(dir.x,0,dir.y)
		var tangent:=Vector3(-dir.y,0,dir.x)
		if dir in doors:
			for side in [-1.0,1.0]: wall(axis*8+tangent*5*side,Vector3(6,2.4,.6) if dir.y else Vector3(.6,2.4,6),wall_color)
		else: wall(axis*8,Vector3(16,2.4,.6) if dir.y else Vector3(.6,2.4,16),wall_color)
	for x in [-6.5,6.5]:
		var p:=Vector3(x,0,-5.8)
		world.place(world.DUNGEON+"pillar_decorated.gltf.glb" if theme=="crypt" else world.NATURE+"rock_tallA.glb",p,2.8,0,self)
		if theme=="mine": world.box(p+Vector3(0,1.7,0),Vector3(.35,3.4,.35),"876046",false,self)
		var lamp:=OmniLight3D.new()
		lamp.position=p+Vector3(0,2.2,0)
		lamp.light_color=Color("9bc4c4") if theme=="crypt" else Color("edc186")
		lamp.omni_range=10
		lamp.light_energy=.65
		add_child(lamp)
	if theme=="mine":
		for z in [-5.5,5.5]: world.box(Vector3(0,3.1,z),Vector3(13,.3,.3),"876046",false,self)
	elif room_kind in ["combat","large_combat","elite"]:
		for z in [-4.0,4.0]: world.box(Vector3(-4,.45,z),Vector3(1.3,.9,2),"778383",true,self)
	if room_kind=="trap":
		for x in [-3.0,3.0]:
			var hazard:=ValeHazard.new()
			hazard.position=to_global(Vector3(x,0,0))
			hazard.duration=99999
			hazard.tick=2
			hazard.radius=1.2
			hazard.damage=8
			world.add_child(hazard)
			hazard.set_meta("expedition",true)
	if room_kind=="shrine": world.interactable("shrine","Quiet oathstone",Vector3(0,0,-2),self)

func wall(p: Vector3, size: Vector3, color: String) -> void:
	var mesh:=world.box(p+Vector3(0,1.2,0),size,color,false,self)
	world.solid(p+Vector3(0,1.2,0),size,self,mesh)
