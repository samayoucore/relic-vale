class_name ValeInfiniteLandscape
extends ValeLandscape
var samplers: Dictionary={}
var water_material: ShaderMaterial

func sampler(p: Vector2) -> ValeRegionPlan:
	var coord:=Vector2i(floori(p.x/32),floori(p.y/32))
	var key: String=gen.chunk_key(coord)
	if not samplers.has(key):
		var plan:=ValeRegionPlan.new()
		plan.setup(gen.world_seed,gen.origin_x+coord.x,gen.origin_z+coord.y,gen.starter,gen.starter_roads,gen.starter_pois)
		samplers[key]=plan
		if samplers.size()>80: samplers.erase(samplers.keys()[0])
	return samplers[key]

func local_point(p: Vector2) -> Vector2: return Vector2(fposmod(p.x,32),fposmod(p.y,32))
func hub_distance(p: Vector2) -> float: return sampler(p).hub_distance(local_point(p))
func water_distance(p: Vector2) -> float: return sampler(p).water_distance(local_point(p))
func raw_height(p: Vector2) -> float: return sampler(p).raw_height(local_point(p))
func weights(p: Vector2) -> Vector3: return sampler(p).weights(local_point(p))
func field_height(p: Vector2) -> float:
	if cache.has(p): return cache[p]
	var value: float=sampler(p).height_at(local_point(p))
	cache[p]=value
	if cache.size()>18000: cache.clear()
	return value
func boundary() -> void: pass
func color_at(p: Vector2) -> Color:
	var plan:=sampler(p); var local: Vector2=local_point(p)
	var n: float=(plan.noise(local,4,213)+1)*.5
	var w: Vector3=plan.weights(local)
	var a:=Color("788957").lerp(Color("839362"),n)
	var b:=Color("5e795b").lerp(Color("70845a"),n)
	var c:=Color("7e8861").lerp(Color("919373"),n)
	var mixed: Color=a*w.x+b*w.y+c*w.z
	if plan.near_start():
		var village: Color=a.lerp(b,smoothstep(10,22,float(plan.cx*32)+local.x))
		mixed=village.lerp(mixed,smoothstep(0,22,plan.hub_distance(local)))
	var wet: float=plan.water_distance(local)
	if wet<3 and plan.hub_distance(local)>1: mixed=Color("a69b73").lerp(mixed,smoothstep(0,3,wet))
	mixed.a=1
	return mixed
func cover(data: Dictionary,parent: Node3D) -> void:
	for asset in data.get("cover",{}): gen.batch_decoration("res://assets/3d/phase4/nature/"+asset+".gltf",data.cover[asset],parent)

func prepared_mesh(vertices: PackedVector3Array,normals: PackedVector3Array,colors: PackedColorArray=PackedColorArray(),uv: PackedVector2Array=PackedVector2Array()) -> ArrayMesh:
	var arrays: Array=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	if not colors.is_empty(): arrays[Mesh.ARRAY_COLOR]=colors
	if not uv.is_empty(): arrays[Mesh.ARRAY_TEX_UV]=uv
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh
func ground(data: Dictionary,parent: Node3D) -> void:
	var node:=MeshInstance3D.new()
	node.name="StreamedTerrain"
	node.mesh=prepared_mesh(data.terrain_vertices,data.terrain_normals,data.terrain_colors)
	node.material_override=MASTER
	node.position=Vector3(data.coord.x*32,0,data.coord.y*32)
	parent.add_child(node)
	var body:=StaticBody3D.new(); var shape:=CollisionShape3D.new()
	# The worker already produced these triangles. Avoid reading them back from the GPU.
	var collision:=ConcavePolygonShape3D.new()
	collision.set_faces(data.terrain_vertices); collision.backface_collision=true; shape.shape=collision
	body.position=node.position; body.add_child(shape); parent.add_child(body)
func water(parent: Node3D,data: Dictionary) -> void:
	if data.water_vertices.is_empty(): return
	var node:=MeshInstance3D.new(); var normals:=PackedVector3Array()
	normals.resize(data.water_vertices.size()); normals.fill(Vector3.UP)
	node.mesh=prepared_mesh(data.water_vertices,normals,data.water_colors,data.water_uv)
	if water_material==null:
		water_material=ShaderMaterial.new(); water_material.shader=preload("res://shaders/water.gdshader")
	node.material_override=water_material
	node.position=Vector3(data.coord.x*32,0,data.coord.y*32)
	parent.add_child(node)
