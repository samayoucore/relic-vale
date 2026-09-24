class_name ValeWorld
extends Node3D
## A handcrafted layout; deterministic scatter is used only for flowers and small ground details.
const NATURE := "res://assets/3d/nature/"
const VILLAGE := "res://assets/3d/medieval/"
const DUNGEON := "res://assets/3d/dungeon/"
const INTERACTABLE := preload("res://scenes/world/Interactable.tscn")
var material_cache: Dictionary = {}
var scene_cache: Dictionary = {}
var imported_materials: Dictionary = {}
var lanterns: Array[OmniLight3D] = []
var environment: Environment
var sun: DirectionalLight3D
var player: ValePlayer
var elapsed: float = 0
var crystal: Node3D
var outside: bool = true
var generator: Node3D
var hub_root: Node3D
var path_points: Array[Vector2] = [Vector2(0,3),Vector2(9,2),Vector2(17,-2),Vector2(25,-7),Vector2(31,-12),Vector2(38,-21)]

func _ready() -> void:
	lighting()
	terrain()
	village()
	for definition in [{"id":"smith","p":Vector3(7,0,-3)},{"id":"merchant","p":Vector3(.8,0,-8)},{"id":"keeper","p":Vector3(-5.4,0,-3.8)}]:
		var data: Dictionary=State.npc_data[definition.id]
		var npc:=interactable("npc",data.name+" · "+data.role,definition.p)
		npc.npc_id=definition.id
		npc.sprite.modulate=Color("bcd6c5") if definition.id=="keeper" else (Color("cab9a5") if definition.id=="smith" else Color("d8c0d1"))
	forest()
	hub_root=Node3D.new()
	hub_root.name="WillowmereHandcrafted"
	add_child(hub_root)
	for node in get_children():
		if node is Node3D and node!=hub_root and node!=sun and not node is WorldEnvironment: node.reparent(hub_root)
	crypt()
	for node in get_children():
		if node is Node3D and node!=hub_root and node!=sun: node.set_meta("interior",true)
	ambient_motes(Vector3(5,2,0),Vector3(23,2,16),Color("eddcaa"),60)
	ambient_motes(Vector3(29,2,-12),Vector3(14,2,12),Color("b7e3b3"),40)

func mat(hex: String, emissive: bool = false) -> StandardMaterial3D:
	var key: String=hex+str(emissive)
	if material_cache.has(key): return material_cache[key]
	var m:=StandardMaterial3D.new()
	m.albedo_color=Color(hex)
	m.roughness=.9
	if emissive:
		m.emission_enabled=true
		m.emission=Color(hex)
		m.emission_energy_multiplier=1.4
	material_cache[key]=m
	return m

func box(pos: Vector3, size: Vector3, color: String, collision: bool = false, parent: Node3D = self) -> MeshInstance3D:
	var mesh:=BoxMesh.new()
	mesh.size=size
	var node:=MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=mat(color)
	node.position=pos
	parent.add_child(node)
	if collision: solid(pos,size,parent,node)
	return node

func cylinder(pos: Vector3, radius: float, height: float, color: String, vertices: int = 12, parent: Node3D = self) -> MeshInstance3D:
	var mesh:=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=vertices
	var node:=MeshInstance3D.new()
	node.mesh=mesh
	node.position=pos
	node.material_override=mat(color)
	parent.add_child(node)
	return node

func solid(pos: Vector3, size: Vector3, parent: Node3D = self, visual: Node3D = null) -> StaticBody3D:
	var body:=StaticBody3D.new()
	var shape:=CollisionShape3D.new()
	var geometry:=BoxShape3D.new()
	geometry.size=size
	shape.shape=geometry
	body.position=pos
	body.add_child(shape)
	parent.add_child(body)
	if visual:
		body.set_meta("occluder",weakref(visual))
		visual.add_to_group("camera_occluders")
	return body

func bounds(node: Node3D, transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var result:=AABB()
	var current: Transform3D=transform*node.transform
	if node is MeshInstance3D: result=current*node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var child_bounds: AABB=bounds(child,current)
			if child_bounds.size.length_squared()>0:
				result=child_bounds if result.size.length_squared()==0 else result.merge(child_bounds)
	return result

func place(file: String, pos: Vector3, height: float, yaw: float = 0.0, parent: Node3D = self) -> Node3D:
	if not scene_cache.has(file): scene_cache[file]=load(file)
	var model: Node3D=scene_cache[file].instantiate()
	tune_materials(model,file)
	var aabb: AABB=bounds(model)
	var scale_factor: float=height/maxf(.01,aabb.size.y)
	var root:=Node3D.new()
	root.name=file.get_file().get_basename()
	parent.add_child(root)
	root.add_child(model)
	model.position=-Vector3(aabb.get_center().x,aabb.position.y,aabb.get_center().z)*scale_factor
	model.scale=Vector3.ONE*scale_factor
	root.position=pos
	root.rotation.y=deg_to_rad(yaw)
	return root

func tune_materials(node: Node, file: String) -> void:
	if node is MeshInstance3D:
		for index in node.mesh.get_surface_count():
			var source: Material=node.mesh.surface_get_material(index)
			if not source is StandardMaterial3D: continue
			var key: String=file+source.resource_name+str(index)
			if not imported_materials.has(key):
				var edited: StandardMaterial3D=source.duplicate()
				edited.metallic=0.0
				edited.roughness=.9
				if "/phase6/props/" in file:
					edited.normal_enabled=false
					edited.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				if file.begins_with(NATURE):
					var name_lower: String=source.resource_name.to_lower()
					if "leaf" in name_lower:
						edited.albedo_color=Color("658b5c") if "fall" not in file else Color("bf9659")
					elif "wood" in name_lower: edited.albedo_color=Color("7d6245")
					elif name_lower=="grass": edited.albedo_color=Color("68854f")
					elif name_lower=="dirt": edited.albedo_color=Color("858475") if "rock" in file else Color("9c805c")
					elif name_lower=="_defaultmat": edited.albedo_color=Color("859082")
					elif name_lower=="coloryellow": edited.albedo_color=Color("dfbb69")
					elif name_lower=="colorpurple": edited.albedo_color=Color("a8a0cf")
					elif name_lower=="colorred": edited.albedo_color=Color("c36e62")
				if file.begins_with(VILLAGE):
					var palette: Dictionary={"Beige":"b17d52","White":"cfccb1","Stone":"677773","BrownDark":"604334","Brown":"876046"}
					if palette.has(source.resource_name): edited.albedo_color=Color(palette[source.resource_name])
				imported_materials[key]=edited
				if file.begins_with(NATURE) and "leaf" in source.resource_name.to_lower():
					var leaf:=ShaderMaterial.new(); leaf.shader=preload("res://shaders/leaf_wind.gdshader")
					leaf.set_shader_parameter("leaf_color",edited.albedo_color)
					imported_materials[key]=leaf
			node.set_surface_override_material(index,imported_materials[key])
	for child in node.get_children(): tune_materials(child,file)

func lighting() -> void:
	var env:=WorldEnvironment.new()
	environment=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("8bada4")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("c0d9cf")
	environment.ambient_light_energy=.32
	environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled=true
	environment.fog_light_color=Color("96b8ab")
	environment.fog_density=.00085
	env.environment=environment
	add_child(env)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-30,0)
	sun.light_color=Color("ffdfb2")
	sun.light_energy=.8
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=150
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_blur=1.4
	add_child(sun)

func terrain() -> void:
	box(Vector3(12,-1.03, -5),Vector3(74,2,62),"665d49",true)
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng:=RandomNumberGenerator.new()
	rng.seed=431
	for x in range(-25,49,2):
		for z in range(-36,26,2):
			var c:=Color("788957").lerp(Color("839362"),rng.randf())
			if x>15: c=Color("5e795b").lerp(Color("70845a"),rng.randf())
			for p in [Vector3(x,0,z),Vector3(x+2,0,z),Vector3(x,0,z+2),Vector3(x+2,0,z),Vector3(x+2,0,z+2),Vector3(x,0,z+2)]:
				surface.set_color(c)
				surface.set_normal(Vector3.UP)
				surface.add_vertex(p)
	var m=preload("res://materials/master_terrain.tres")
	var ground:=MeshInstance3D.new()
	ground.mesh=surface.commit()
	ground.material_override=m
	add_child(ground)
	# Finite outer boundaries are owned by the procedural generator in phase 2.
	path(path_points,3.2)
	path([Vector2(-11,6),Vector2(-8,0),Vector2(0,0),Vector2(0,-10)],2.5)
	path([Vector2(0,-1),Vector2(7,-7)],2)
	path([Vector2(5,2),Vector2(10,7)],2)
	# Deliberate extensions leave the preserved hub around its existing trees and buildings.
	path([Vector2(-8,0),Vector2(-10,-1),Vector2(-14,-1),Vector2(-18,0)],2.4)
	path([Vector2(17,-2),Vector2(18,1),Vector2(20,4),Vector2(23,6),Vector2(26,10),Vector2(27,14),Vector2(28,22),Vector2(31,25)],2.4)
	path([Vector2(26,10),Vector2(23,12),Vector2(20,12)],2.4)
	cylinder(Vector3(0,.025,0),5.0,.09,"b3a58a",32)
	cylinder(Vector3(0,.075,0),4.65,.06,"c3b290",32)
	# A shallow, oval village pond with reeds, a dock, and real animated 3D water.
	var pond:=cylinder(Vector3(-13,.055,12),5.0,.09,"c0ae80",32)
	pond.scale.z=.72
	var water:=cylinder(Vector3(-13,.115,12),4.6,.06,"437c7a",40)
	water.scale.z=.69
	var water_mat:=ShaderMaterial.new()
	water_mat.shader=preload("res://shaders/water.gdshader")
	water.material_override=water_mat
	for i in range(9):
		box(Vector3(-10.5+i*.34,.23,12.0),Vector3(.31,.12,1.8),"93785a")
	for p in [Vector3(-10.5,.4,11.15),Vector3(-7.8,.4,11.15),Vector3(-10.5,.4,12.85),Vector3(-7.8,.4,12.85)]:
		box(p,Vector3(.17,.9,.17),"685846")

func path(points: Array[Vector2], width: float) -> void:
	for i in range(points.size()-1):
		var a: Vector2=points[i]
		var b: Vector2=points[i+1]
		var offset: Vector2=(b-a).normalized().orthogonal()*width*.5
		var mesh:=ImmediateMesh.new()
		var road_material:=mat("b7a07a")
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,road_material)
		for p in [a-offset,a+offset,b-offset,a+offset,b+offset,b-offset]:
			mesh.surface_set_normal(Vector3.UP)
			mesh.surface_add_vertex(Vector3(p.x,.03,p.y))
		mesh.surface_end()
		var piece:=MeshInstance3D.new()
		piece.mesh=mesh
		add_child(piece)
		cylinder(Vector3(a.x,.025,a.y),width*.5,.035,"b7a07a",16)

func village() -> void:
	var homes: Array = [
		["house",Vector3(-8,0,-5),5.4,18,Vector3(4.0,4.5,3.8)],
		["house",Vector3(7,0,-7.5),4.8,-25,Vector3(3.8,4,3.7)],
		["watermill",Vector3(-14,0,3),6.0,95,Vector3(5,4,4)],
		["lumbermill",Vector3(10,0,7.5),5.0,-145,Vector3(4.5,4,4)],
		["market",Vector3(.2,0,-10.5),3.6,5,Vector3(4.5,3.2,2.8)]
	]
	for home in homes:
		var visual:=place(VILLAGE+home[0]+".gltf.glb",home[1],home[2],home[3])
		var size: Vector3=home[4]
		solid(home[1]+Vector3(0,size.y*.5,0),size,self,visual)
		box(home[1]+Vector3(0,.06,0),Vector3(size.x+.4,.12,size.z+.4),"9b927b")
	place(VILLAGE+"well.gltf.glb",Vector3(0,.13,-.3),2.8)
	solid(Vector3(0,.8,-.3),Vector3(1.7,1.6,1.7))
	var rowan:=interactable("npc","Rowan · Keeper",Vector3(-2.5,.05,1.0))
	var chest:=interactable("chest","Road supplies",Vector3(3.4,.12,.4))
	chest.model=place(DUNGEON+"chest.glb",Vector3.ZERO,.78,15,chest)
	solid(chest.position+Vector3(0,.4,0),Vector3(1.2,.8,.85))
	var shrine:=interactable("shrine","The wishing stone",Vector3(-3.1,.02,-4.0))
	cylinder(shrine.position+Vector3(0,.17,0),1.1,.35,"989b87",8)
	cylinder(shrine.position+Vector3(0,.45,0),.62,.3,"b8b79b",8)
	var gem:=crystal_mesh(shrine.position+Vector3(0,1.3,0),.55,"b3e4cc")
	gem.rotation_degrees.z=13
	lantern(shrine.position+Vector3(0,1.3,0),Color("a9dec6"),false,3)
	for p in [Vector3(-5,0,4),Vector3(5.5,0,4.5),Vector3(1.5,0,-7),Vector3(-10,0,-1),Vector3(11.8,0,.6)]: lantern(p)
	for p in [Vector3(-9.8,0,-2.5),Vector3(5.6,0,-5),Vector3(2,0,-9),Vector3(11.5,0,5.5)]:
		place(DUNGEON+"barrel_large.gltf.glb",p,.8,20)
	for p in [Vector3(-6,0,-3.1),Vector3(8.9,0,-4.9),Vector3(-2.7,0,-9)]:
		place(DUNGEON+"box_large.gltf.glb",p,.65,-20)
	# Garden fences remain low so every camera angle is readable.
	for i in range(6):
		fence(Vector3(-11+i*.85,0,-8.6))
	for i in range(5):
		fence(Vector3(7+i*.85,0,10.6))
	place(VILLAGE+"farm_plot.gltf.glb",Vector3(-6,.02,-10),.5)
	signpost(Vector3(9,0,3.5),"MOSSFALL WOOD  →")
	# Cloth pennants strung over the square.
	for x in [-5.5,5.5]: box(Vector3(x,2.2,-3.1),Vector3(.13,4.4,.13),"685b46")
	for i in range(12):
		var x: float=-5.1+i*.9
		var y: float=3.75+pow(x/5.5,2)*.55
		box(Vector3(x,y,-3.1),Vector3(.95,.024,.035),"544d40")
		var pennant:=BoxMesh.new()
		pennant.size=Vector3(.38,.46,.025)
		var flag:=MeshInstance3D.new()
		flag.mesh=pennant
		flag.material_override=mat("cc8e63" if i%2==0 else "689fa1")
		flag.position=Vector3(x,y-.22,-3.1)
		flag.rotation.z=.1 if i%2==0 else -.13
		add_child(flag)

func fence(pos: Vector3) -> void:
	box(pos+Vector3(0,.45,0),Vector3(.13,.9,.13),"817356")
	for y in [.3,.65]: box(pos+Vector3(.43,y,0),Vector3(.9,.09,.07),"aa9870")

func forest() -> void:
	var tree_positions: Array[Vector2] = [
		Vector2(-19,-9),Vector2(-15,-13),Vector2(-10,-15),Vector2(-5,-16),Vector2(1,-16),Vector2(6,-16),Vector2(12,-13),
		Vector2(-20,-3),Vector2(-20,5),Vector2(-20,12),Vector2(-18,18),Vector2(-11,19),Vector2(-5,18),Vector2(3,17),Vector2(11,17),
		Vector2(15,9),Vector2(18,6),Vector2(21,2),Vector2(25,-1),Vector2(29,-4),Vector2(33,-7),Vector2(39,-8),
		Vector2(15,-7),Vector2(19,-10),Vector2(23,-14),Vector2(28,-18),Vector2(32,-22),Vector2(29,-26),Vector2(24,-22),
		Vector2(21,-18),Vector2(17,-16),Vector2(15,-21),Vector2(20,-25),Vector2(37,-28),Vector2(43,-25),
		Vector2(44,-19),Vector2(43,-13),Vector2(44,-5),Vector2(40,1),Vector2(33,3),Vector2(28,7),Vector2(23,10),Vector2(20,16),
		Vector2(35,10),Vector2(41,9),Vector2(43,17),Vector2(30,17),Vector2(25,20),Vector2(36,21)]
	var rng:=RandomNumberGenerator.new()
	rng.seed=819
	for i in tree_positions.size():
		var p: Vector2=tree_positions[i]
		var species: String="tree_oak" if i%3==0 else ("tree_pineRoundA" if i%3==1 else "tree_oak_fall")
		if p.x>15: species="tree_pineTallA" if i%2==0 else "tree_oak"
		var h: float=rng.randf_range(4.5,7.3)
		var yaw: float=rng.randf_range(0,360)
		if Rect2(16,6,9,8).has_point(p): continue
		var resource:=ValeResource.spawn(self,self,"%d/resource/hub/tree_%d" % [State.world_seed,i],"wood",Vector3(p.x,0,p.y),NATURE+species+".glb",h,yaw,true)
		resource.set_meta("authored_resource","tree_"+str(i))
	for p in [Vector3(12,0,-5),Vector3(20,0,-6),Vector3(27,0,-11),Vector3(34,0,-16)]: lantern(p)
	for p in [Vector3(23,0,-5),Vector3(30,0,-10)]:
		var enemy:=preload("res://scenes/characters/Enemy.tscn").instantiate()
		enemy.position=p
		add_child(enemy)
	# Border boulders frame the crypt, leaving its approach clear.
	for i in range(7):
		var pos:=Vector3(30+i*2.5,0,-26.5+sin(i)*.4)
		place(NATURE+"rock_tallA.glb",pos,rng.randf_range(3.2,5.0),i*47)
	for i in range(180):
		var p:=Vector2(rng.randf_range(-21,45),rng.randf_range(-30,23))
		if p.length()<6 or near_road(p,2.4): continue
		if p.x<13 and p.y>-13 and p.y<11: continue
		var species: String=["plant_bush","plant_bushSmall","grass","flower_yellowA","flower_purpleA","mushroom_redGroup"][i%6]
		var h: float=rng.randf_range(.2,.45) if i%6>1 else rng.randf_range(.4,.9)
		if species in ["plant_bushSmall","grass","mushroom_redGroup"]:
			var item: String="wild_herb" if species=="plant_bushSmall" else ("fiber" if species=="grass" else "mushroom")
			var resource:=ValeResource.spawn(self,self,"%d/resource/hub/plant_%d" % [State.world_seed,i],item,Vector3(p.x,0,p.y),NATURE+species+".glb",maxf(h,.45),rng.randf_range(0,360))
			resource.set_meta("authored_resource","plant_"+str(i))
		else: place(NATURE+species+".glb",Vector3(p.x,0,p.y),h,rng.randf_range(0,360))
	# Flowers deliberately border houses and the plaza.
	for i in range(38):
		var a: float=i*TAU/38
		var p:=Vector3(cos(a)*5.35,0,sin(a)*5.35)
		if p.x>4 and absf(p.z)<2: continue
		if p.z < -4: continue
		place(NATURE+("flower_yellowA.glb" if i%2==0 else "flower_purpleA.glb"),p,.3,i*25)
	for i in range(35):
		var p:=Vector3(rng.randf_range(-18,43),0,rng.randf_range(-29,21))
		if near_road(Vector2(p.x,p.z),3) or Vector2(p.x,p.z).length()<15: continue
		var resource:=ValeResource.spawn(self,self,"%d/resource/hub/rock_%d" % [State.world_seed,i],"iron_ore" if i%4==0 else "stone",p,NATURE+"rock_largeB.glb" if i%4==0 else NATURE+"rock_smallA.glb",rng.randf_range(.5,1.1),i*37)
		resource.set_meta("authored_resource","rock_"+str(i))

func near_road(p: Vector2, distance: float) -> bool:
	for i in range(path_points.size()-1):
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,path_points[i],path_points[i+1]))<distance: return true
	return false

func crypt() -> void:
	# A freestanding, thick stone arch with an open threshold and a dark entrance.
	for x in [35.4,40.6]:
		place(DUNGEON+"pillar_decorated.gltf.glb",Vector3(x,0,-22.5),4.1)
		solid(Vector3(x,2,-22.5),Vector3(1.2,4,1.2))
	box(Vector3(38,3.7,-22.5),Vector3(5.8,.75,1.4),"656c68")
	box(Vector3(38,1.6,-23),Vector3(4,3.2,.3),"253c3d",true)
	box(Vector3(38,.12,-21.4),Vector3(5.4,.24,3),"858a79")
	for x in [35.4,40.6]: lantern(Vector3(x,1.5,-21.6),Color("b5d8c1"),false,4)
	interactable("entrance","Forgotten Crypt",Vector3(38,.3,-20.5))
	signpost(Vector3(33.2,0,-18),"FORGOTTEN CRYPT  ↑")
	# The interior lives in the same world, beyond the overworld boundary.
	box(Vector3(110,-.3,0),Vector3(15,.6,20),"434e54",true)
	for x in range(103,118,2):
		for z in range(-9,10,2):
			box(Vector3(x,.015,z),Vector3(1.94,.035,1.94),"58636a" if (x+z)%4==0 else "616a6c")
	for x in [102.5,117.5]:
		box(Vector3(x,1.45,0),Vector3(.8,2.9,20),"3d494e",true)
		for z in range(-8,10,4): place(DUNGEON+"pillar_decorated.gltf.glb",Vector3(x,0,z),3.5)
	for x in [104.8,115.2]: box(Vector3(x,1.4,-10),Vector3(5.6,2.8,.8),"404e53",true)
	# Low south wall keeps the room readable from the initial camera angle.
	box(Vector3(110,.5,10),Vector3(16,1,.8),"4f5a60",true)
	for x in [106.5,113.5]:
		box(Vector3(x,1,2.8),Vector3(2.3,2,1),"465159",true)
		place(DUNGEON+"pillar_decorated.gltf.glb",Vector3(x,0,2.8),3)
	for p in [Vector3(103.8,1.7,-7),Vector3(116.2,1.7,-7),Vector3(103.8,1.7,6),Vector3(116.2,1.7,6)]:
		place(DUNGEON+"torch_mounted.gltf.glb",p,.65)
		lantern(p+Vector3(0,.4,0),Color("8ed8d5"),false,6)
	interactable("exit","Stairway to the wood",Vector3(110,0,8.6))
	place(DUNGEON+"stairs.gltf.glb",Vector3(110,0,8.7),1.2,180)
	place(DUNGEON+"barrel_large.gltf.glb",Vector3(115.5,0,5.5),1.1)
	place(DUNGEON+"box_large.gltf.glb",Vector3(104.5,0,-4.5),.9,15)
	cylinder(Vector3(110,.35,-6.7),1.4,.7,"7d8681",8)
	cylinder(Vector3(110,.8,-6.7),1.0,.25,"a0a89c",8)
	var seed:=interactable("moonseed","The moonseed",Vector3(110,0,-6.7))
	seed.marker.position.y=2.65
	crystal=crystal_mesh(Vector3(110,1.7,-6.7),.7,"b4ece5")
	seed.model=crystal
	lantern(Vector3(110,2,-6.7),Color("98e0d9"),false,7)
	ambient_motes(Vector3(110,1.8,-5),Vector3(5,2,4),Color("9bc9ca"),30)
	var guardian:=preload("res://scenes/characters/Enemy.tscn").instantiate()
	guardian.position=Vector3(111,0,-2)
	guardian.set_meta("archetype","skeleton")
	add_child(guardian)
	# Keep the original room intact, but reserve distant coordinates for interiors.
	for child in get_children():
		if child is Node3D and child.position.x>90 and child.position.x<130:
			child.position.x+=890
			if child is Mossling: child.origin.x+=890
	# The original entrance chamber is extended by an authored two-room scene.
	var extension:=preload("res://scenes/dungeons/ForgottenCrypt.tscn").instantiate()
	extension.world=self
	add_child(extension)
	seed.position.z=-43
	crystal.position.z=-43
	crystal.visible=not State.flags.moonseed

func crystal_mesh(pos: Vector3, size: float, color: String) -> MeshInstance3D:
	var mesh:=CylinderMesh.new()
	mesh.top_radius=0
	mesh.bottom_radius=size*.5
	mesh.height=size*1.5
	mesh.radial_segments=5
	var node:=MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=mat(color,true)
	node.position=pos
	add_child(node)
	var lower:=MeshInstance3D.new()
	lower.mesh=mesh
	lower.material_override=node.material_override
	lower.rotation.x=PI
	lower.position.y=-size*.75
	node.add_child(lower)
	return node

func interactable(kind: String, title: String, pos: Vector3, parent: Node3D = self) -> ValeInteractable:
	var node: ValeInteractable=INTERACTABLE.instantiate()
	node.kind=kind
	node.title=title
	node.position=pos
	parent.add_child(node)
	return node

func signpost(pos: Vector3, title: String) -> void:
	box(pos+Vector3(0,.6,0),Vector3(.16,1.2,.16),"655541")
	box(pos+Vector3(.15,1.2,0),Vector3(1.65,.43,.13),"a4906b")
	var text:=Label3D.new()
	text.text=title
	text.font_size=36
	text.pixel_size=.010
	text.position=pos+Vector3(0,1.7,0)
	text.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	text.modulate=Color("eee0ae")
	text.visible=false
	add_child(text)

func lantern(pos: Vector3, color: Color = Color("ffce84"), pole: bool = true, radius: float = 4) -> void:
	var bulb: Vector3=pos
	if pole:
		box(pos+Vector3(0,1.1,0),Vector3(.12,2.2,.12),"615744")
		box(pos+Vector3(.2,2.13,0),Vector3(.55,.12,.12),"615744")
		bulb+=Vector3(.4,1.9,0)
		box(bulb,Vector3(.28,.42,.28),"554c3c")
		var glow:=box(bulb+Vector3(0,0,.015),Vector3(.22,.27,.27),"ffe0a0")
		glow.material_override=mat("ffe0a0",true)
	var light:=OmniLight3D.new()
	light.position=bulb
	light.light_color=color
	light.light_energy=.11 if pos.x<80 else .75
	light.omni_range=radius
	light.omni_attenuation=1.3
	add_child(light)
	lanterns.append(light)

func ambient_motes(pos: Vector3, extents: Vector3, color: Color, amount: int) -> void:
	var particles:=CPUParticles3D.new()
	particles.position=pos
	particles.amount=amount
	particles.lifetime=8
	particles.preprocess=8
	particles.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents=extents
	particles.direction=Vector3(1,.4,.3)
	particles.spread=65
	particles.gravity=Vector3.ZERO
	particles.initial_velocity_min=.08
	particles.initial_velocity_max=.25
	particles.scale_amount_min=.025
	particles.scale_amount_max=.055
	var mesh:=SphereMesh.new()
	mesh.radius=.5
	mesh.height=1
	mesh.radial_segments=4
	mesh.rings=2
	mesh.material=mat(color.to_html(false),true)
	particles.mesh=mesh
	add_child(particles)

func _process(delta: float) -> void:
	elapsed+=delta
	if is_instance_valid(crystal):
		crystal.rotation.y+=delta*.5
		crystal.position.y=1.75+sin(elapsed*1.4)*.13
	lanterns=lanterns.filter(func(lamp): return is_instance_valid(lamp) and lamp.is_inside_tree())
	for i in lanterns.size():
		var energy: float=.08 if lanterns[i].global_position.x<900 else .7
		lanterns[i].light_energy=energy*(1+sin(elapsed*3.1+i*1.9)*.1)
	if not is_instance_valid(player): return
	var is_outside: bool=player.position.x<900
	var new_region: String="Willowmere" if generator.in_hub(Vector2(player.position.x,player.position.z)) else ("Mossfall Wood" if is_outside else "Forgotten Crypt")
	if is_outside and is_instance_valid(generator) and not generator.in_hub(Vector2(player.position.x,player.position.z)):
		new_region=generator.biome_at(player.position)
		for poi in generator.pois:
			if poi.kind=="settlement" and poi.position.distance_to(Vector2(player.position.x,player.position.z))<16: new_region=poi.title
	elif player.position.x>1500:
		var active: Dictionary=State.life_data.dungeons.get("active",{})
		new_region="Old Ironvein Mine" if active.get("theme","")=="mine" else "Veilbound Crypt"
	if player.position.x>2900 and not get_tree().current_scene.interiors.active.is_empty(): new_region=get_tree().current_scene.interiors.active.title
	if State.region!=new_region:
		State.region=new_region
		State.changed.emit()
	if is_outside!=outside:
		outside=is_outside
		sun.light_energy=.8 if outside else .12
		environment.ambient_light_energy=.32 if outside else .28
		environment.ambient_light_color=Color("c0d9cf") if outside else Color("86b3c7")
		environment.background_color=Color("8bada4") if outside else Color("172830")
		environment.fog_light_color=Color("96b8ab") if outside else Color("273d48")
