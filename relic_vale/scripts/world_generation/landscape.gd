class_name ValeLandscape
extends RefCounted
## World-space fields, independent of chunks. The original village is the palette reference.
const MASTER = preload("res://materials/master_terrain.tres")
var gen: ValeGenerator
var height_noise := FastNoiseLite.new()
var stream: Array[Vector2] = []
var lake := Vector2(72,83)
var cache: Dictionary = {}

func setup(generator: ValeGenerator) -> void:
	gen=generator
	height_noise.seed=gen.world_seed+3101
	height_noise.frequency=.024
	height_noise.fractal_octaves=2
	stream.clear()
	cache.clear()
	for z in range(-112,145,4):
		stream.append(Vector2(62+sin(z*.035+float(gen.world_seed%19)*.04)*8+sin(z*.087)*2,z))
	lake=stream[48]+Vector2(3,0)

func hub_distance(p: Vector2) -> float:
	return p.distance_to(p.clamp(gen.HUB.position,gen.HUB.end))

func water_distance(p: Vector2) -> float:
	# The stream is monotonic in z: only nearby segments need evaluation.
	var index: int=clampi(floori((p.y+112)/4),0,stream.size()-2)
	var d: float=INF
	for i in range(maxi(0,index-3),mini(stream.size()-1,index+4)):
		d=minf(d,p.distance_to(Geometry2D.get_closest_point_to_segment(p,stream[i],stream[i+1]))-1.8)
	return minf(d,(p-lake).length()-9.0)

func raw_height(p: Vector2) -> float:
	return (height_noise.get_noise_2d(p.x,p.y)*3.8+.45)*smoothstep(0,12,hub_distance(p))

func height(p: Vector2) -> float:
	# Match the triangulated collision/render surface between the 2 m vertices.
	var a:=Vector2(floor(p.x/2)*2,floor(p.y/2)*2)
	var f: Vector2=(p-a)/2
	var b: float=field_height(a+Vector2(2,0))
	var c: float=field_height(a+Vector2(0,2))
	if f.x+f.y<=1: return field_height(a)*(1-f.x-f.y)+b*f.x+c*f.y
	return field_height(a+Vector2(2,2))*(f.x+f.y-1)+b*(1-f.y)+c*(1-f.x)

func field_height(p: Vector2) -> float:
	if cache.has(p): return cache[p]
	var h: float=raw_height(p)
	# Flat authored footprints blend into surrounding slopes over 7 m.
	for poi in gen.pois:
		var distance: float=p.distance_to(poi.position)
		var radius: float=poi.get("radius",7.0)
		if distance<radius+7:
			h=lerpf(raw_height(poi.position),h,smoothstep(radius,radius+7,distance))
	var wet: float=water_distance(p)
	if hub_distance(p)>1 and wet<4:
		h=lerpf(-.65,h,smoothstep(-.5,4,wet))
		# All road crossings are shallow wooden bridges; their banks gently ramp up.
		var rd: float=gen.road_distance(p)
		if rd<3: h=lerpf(.1,h,smoothstep(1.8,3,rd))
	# An irregular inward rocky rise masks the physical finite limit.
	var edge: float=minf(minf(p.x+96,128-p.x),minf(p.y+96,128-p.y))
	var ridge_start: float=12+sin(p.x*.1+p.y*.045)*4.5
	if edge<ridge_start:
		h+=pow(clampf((ridge_start-edge)/13,0,1),1.7)*(11+sin(p.x*.071+p.y*.096)*3)
	if gen.HUB.has_point(p): h=-.04
	cache[p]=h
	return h

func weights(p: Vector2) -> Vector3:
	var n: float=gen.biome_noise.get_noise_2d(p.x,p.y)
	var meadow: float=1-smoothstep(-.25,.03,n)
	var ruins: float=smoothstep(.07,.3,n)
	var forest: float=maxf(0,1-meadow-ruins)
	return Vector3(meadow,forest,ruins).normalized() / maxf(.001,Vector3(meadow,forest,ruins).normalized().dot(Vector3.ONE))

func color_at(p: Vector2) -> Color:
	var cell:=Vector2(floor(p.x/2),floor(p.y/2))
	var n: float=fposmod(sin(cell.dot(Vector2(12.9898,78.233))+gen.world_seed*.001)*43758.5453,1)
	var w: Vector3=weights(p)
	var a:=Color("788957").lerp(Color("839362"),n)
	var b:=Color("5e795b").lerp(Color("70845a"),n)
	var c:=Color("7e8861").lerp(Color("919373"),n)
	var mixed: Color=a*w.x+b*w.y+c*w.z
	# The hub's eastern ground is intentionally darker; carry that palette across its edge.
	var village: Color=a.lerp(b,smoothstep(10,22,p.x))
	mixed=village.lerp(mixed,smoothstep(0,22,hub_distance(p)))
	var wet: float=water_distance(p)
	if wet<3 and hub_distance(p)>1: mixed=Color("a69b73").lerp(mixed,smoothstep(0,3,wet))
	var edge: float=minf(minf(p.x+96,128-p.x),minf(p.y+96,128-p.y))
	mixed=mixed.lerp(Color("7b8777"),1-smoothstep(-3,9+sin(p.x*.1+p.y*.045)*4,edge))
	mixed.a=1
	return mixed

func ground(data: Dictionary, parent: Node3D) -> void:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var origin: Vector2=Vector2(data.coord)*32
	for x in range(0,32,2):
		for z in range(0,32,2):
			var a:=origin+Vector2(x,z)
			var color: Color=color_at(a+Vector2.ONE)
			for offset in [Vector2.ZERO,Vector2(2,0),Vector2(0,2),Vector2(2,0),Vector2(2,2),Vector2(0,2)]:
				var p: Vector2=a+offset
				surface.set_color(color)
				surface.set_normal(Vector3(height(p-Vector2(.2,0))-height(p+Vector2(.2,0)),.4,height(p-Vector2(0,.2))-height(p+Vector2(0,.2))).normalized())
				surface.add_vertex(Vector3(p.x,height(p),p.y))
	var node:=MeshInstance3D.new()
	node.name="VillageTerrain"
	node.mesh=surface.commit()
	node.material_override=MASTER
	parent.add_child(node)
	var body:=StaticBody3D.new()
	var collision:=CollisionShape3D.new()
	collision.shape=node.mesh.create_trimesh_shape()
	collision.shape.backface_collision=true
	body.add_child(collision)
	parent.add_child(body)

func boundary() -> void:
	# A continuous mesh ring, extending far beyond every possible camera footprint.
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-176,208,2):
		for z in range(-176,208,2):
			if x>=-96 and x<128 and z>=-96 and z<128: continue
			for d in [Vector2.ZERO,Vector2(2,0),Vector2(0,2),Vector2(2,0),Vector2(2,2),Vector2(0,2)]:
				var p: Vector2=Vector2(x,z)+d
				var outside: float=p.distance_to(p.clamp(Vector2(-96,-96),Vector2(128,128)))
				var h: float=height(p)+smoothstep(0,35,outside)*(8+absf(height_noise.get_noise_2d(p.x*2,p.y*2))*36)
				st.set_color(color_at(p).lerp(Color("70867d"),smoothstep(0,50,outside)))
				st.add_vertex(Vector3(p.x,h,p.y))
	st.generate_normals()
	var mesh:=MeshInstance3D.new()
	mesh.name="ContinuousMountainWatershed"
	mesh.mesh=st.commit()
	mesh.material_override=MASTER
	gen.add_child(mesh)
	var rocks: Array=[]
	var trees: Array=[]
	var rng:=gen.local_rng(Vector2i(-9,-9),807)
	for side in 4:
		for step in range(-96,132,4):
			var bend: float=sin(step*.09+side)*3
			var p:=Vector2(-93+bend,step) if side==0 else (Vector2(125+bend,step) if side==1 else (Vector2(step,-93+bend) if side==2 else Vector2(step,125+bend)))
			rocks.append({"p":p,"h":rng.randf_range(2.2,4.3),"yaw":rng.randf()*360})
			var tree: Vector2=p+(Vector2(16,16)-p).normalized()*5
			trees.append({"p":tree,"h":rng.randf_range(4,7),"yaw":rng.randf()*360})
	gen.batch_decoration("rock_tallA",rocks,gen)
	gen.batch_decoration("tree_pineTallA",trees,gen)
	for x in [-96.5,128.5]: gen.world.solid(Vector3(x,20,16),Vector3(1,50,225),gen)
	for z in [-96.5,128.5]: gen.world.solid(Vector3(16,20,z),Vector3(225,50,1),gen)

func water(parent: Node3D, data: Dictionary) -> void:
	var rect:=Rect2(Vector2(data.coord)*32,Vector2(32,32))
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int=0
	# Gridded contour cells create natural stream and lake outlines with an irregular bank.
	for x in range(32):
		for z in range(32):
			var a: Vector2=rect.position+Vector2(x,z)
			if water_distance(a+Vector2(.5,.5))>.3: continue
			for o in [Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]:
				st.set_normal(Vector3.UP)
				st.set_uv((a+o)*.2)
				st.add_vertex(Vector3(a.x+o.x,-.18,a.y+o.y))
				count+=1
	if count==0: return
	var node:=MeshInstance3D.new()
	node.name="StreamAndLake"
	node.mesh=st.commit()
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/water.gdshader")
	node.material_override=material
	parent.add_child(node)

func cover(data: Dictionary, parent: Node3D) -> void:
	var rng:=gen.local_rng(data.coord,4970)
	var origin: Vector2=Vector2(data.coord)*32
	var groups: Dictionary={}
	for i in 1900:
		var p:=origin+Vector2(rng.randf()*32,rng.randf()*32)
		if not gen.clear_for_prop(p,data.poi,1.75): continue
		if water_distance(p)<.6: continue
		var patch: float=gen.density_noise.get_noise_2d(p.x*1.7,p.y*1.7)
		if rng.randf()>.7+patch*.7: continue
		var asset: String="Grass_Common_Short" if i%3 else "Grass_Wispy_Short"
		if i%21==0: asset="Fern_1" if weights(p).y>.35 else "Clover_1"
		if i%37==0: asset="Flower_3_Group"
		if i%43==0: asset="Pebble_Round_1"
		if i%61==0: asset="Mushroom_Common"
		if not groups.has(asset): groups[asset]=[]
		groups[asset].append({"p":p,"h":rng.randf_range(.4,.72) if "Grass" in asset else rng.randf_range(.22,.5),"yaw":rng.randf()*360,"tint":Color("93a772").lerp(Color("b1b783"),rng.randf()*.6)})
	for asset in groups: gen.batch_decoration("res://assets/3d/phase4/nature/"+asset+".gltf",groups[asset],parent)
