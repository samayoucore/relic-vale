class_name ValeGenerator
extends Node3D
## Finite deterministic world. Layout data is independent of chunk load order and runtime RNG.
const CHUNK_SIZE: int = 32
const MIN_CHUNK: int = -3
const MAX_CHUNK: int = 3
const HUB := Rect2(-25,-36,74,62)
const BIOMES: Array[String] = ["Briar Meadow","Elderwood","Fallen March"]
const POI_SCENES: Dictionary = {
	"camp":preload("res://scenes/poi/AbandonedCamp.tscn"),
	"ruin":preload("res://scenes/poi/RuinedTower.tscn"),
	"shrine":preload("res://scenes/poi/WoodlandShrine.tscn"),
	"pond":preload("res://scenes/poi/QuietPond.tscn"),
	"crypt":preload("res://scenes/poi/CryptEntrance.tscn")
}
var world: ValeWorld
var player: ValePlayer
var world_seed: int = 20260907
var biome_noise := FastNoiseLite.new()
var density_noise := FastNoiseLite.new()
var ground_noise := FastNoiseLite.new()
var layout: Dictionary = {}
var roads: Array[Array] = []
var pois: Array[Dictionary] = []
var active_chunks: Dictionary = {}
var pending: Array[Vector2i] = []
var current_chunk := Vector2i(999,999)
var generation_frame: int = 0
var stream_radius: int = 1
var decoration_cache: Dictionary = {}
var discovery_clock: float=0
var landscape := ValeLandscape.new()
var staged: bool=false
var stage_tag: String=""

func budget_yield() -> void: pass

func _ready() -> void:
	world=get_parent()
	regenerate(world_seed)

func in_hub(p: Vector2) -> bool:
	return HUB.has_point(p)

func coord_at(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x/CHUNK_SIZE),floori(pos.z/CHUNK_SIZE))

func valid_coord(coord: Vector2i) -> bool:
	return coord.x>=MIN_CHUNK and coord.y>=MIN_CHUNK and coord.x<=MAX_CHUNK and coord.y<=MAX_CHUNK

func chunk_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x,coord.y]

func biome_at(pos: Vector3) -> String:
	var data: Dictionary=layout.get(chunk_key(coord_at(pos)),{})
	return data.get("biome",BIOMES[0])

func local_rng(coord: Vector2i, salt: int = 0) -> RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=(world_seed ^ ((coord.x+31)*73856093) ^ ((coord.y+31)*19349663) ^ salt) & 0x7fffffffffffffff
	return rng

func regenerate(seed_value: int) -> void:
	world_seed=absi(seed_value)%2147483647
	State.world_seed=world_seed
	for child in get_children():
		remove_child(child)
		child.queue_free()
	active_chunks.clear()
	pending.clear()
	build_layout()
	landscape.boundary()
	current_chunk=Vector2i(999,999)
	update_streaming(true)

func build_layout() -> void:
	layout.clear()
	pois.clear()
	roads.clear()
	biome_noise.seed=world_seed
	biome_noise.frequency=.012
	biome_noise.fractal_octaves=3
	density_noise.seed=world_seed+113
	density_noise.frequency=.055
	ground_noise.seed=world_seed+711
	ground_noise.frequency=.032
	landscape.setup(self)
	var sorted_noise: Array[Dictionary] = []
	for x in range(MIN_CHUNK,MAX_CHUNK+1):
		for z in range(MIN_CHUNK,MAX_CHUNK+1):
			var coord:=Vector2i(x,z)
			var center:=Vector2(x*32+16,z*32+16)
			var noise: float=biome_noise.get_noise_2d(center.x,center.y)
			var biome: String=BIOMES[0] if noise<-.13 else (BIOMES[1] if noise<.18 else BIOMES[2])
			var data: Dictionary={"coord":coord,"center":center,"biome":biome,"noise":noise,"poi":{},"props":[],"enemies":[]}
			layout[chunk_key(coord)]=data
			if not HUB.grow(8).has_point(center) and landscape.water_distance(center)>14: sorted_noise.append(data)
	# Guarantee all three biomes while still choosing their anchors from the noise field.
	sorted_noise.sort_custom(func(a,b): return a.noise<b.noise)
	sorted_noise[0].biome=BIOMES[0]
	sorted_noise[sorted_noise.size()/2].biome=BIOMES[1]
	sorted_noise[-1].biome=BIOMES[2]
	for data in sorted_noise:
		var rng:=local_rng(data.coord,91)
		if rng.randf()<.22:
			var types: Array=["camp","shrine","pond"] if data.biome!=BIOMES[2] else ["ruin","crypt"]
			add_poi(data,types[rng.randi_range(0,types.size()-1)])
	# An accessible camp, shrine, ruin and two rare entrances always exist.
	add_poi(sorted_noise[0],"camp")
	add_poi(sorted_noise[sorted_noise.size()/2],"shrine")
	add_poi(sorted_noise[-1],"crypt")
	add_poi(sorted_noise[-2],"ruin")
	add_poi(sorted_noise[-3],"crypt")
	# More authored templates are selected from compatible geographic contexts.
	var extra: Array=["grove","graveyard","mine","cave","wagon","battlefield","chapel","circle","lumber","well","hunter"]
	for kind in extra:
		for data in sorted_noise:
			if not data.poi.is_empty(): continue
			if kind in ["graveyard","mine","cave","battlefield","chapel"] and data.biome!=BIOMES[2]: continue
			if kind in ["grove","hunter","lumber"] and data.biome==BIOMES[2]: continue
			add_poi(data,kind)
			break
	# Reserve three spacious, river-free footprints before vegetation planning.
	for def in [{"coord":Vector2i(-2,-1),"kind":"forest","title":"Fernwatch"},{"coord":Vector2i(-1,2),"kind":"mining","title":"Ironvein"},{"coord":Vector2i(2,-2),"kind":"trading","title":"Crossroads"}]:
		var data: Dictionary=layout[chunk_key(def.coord)]
		data.poi={"kind":"settlement","settlement":def.kind,"title":def.title,"position":data.center,"access":data.center+Vector2(0,12),"radius":13.0,"id":"%d/settlement/%s" % [world_seed,def.kind]}
		data.biome=BIOMES[1] if def.kind=="forest" else (BIOMES[2] if def.kind=="mining" else BIOMES[0])
	# Quest-critical destinations cannot be lost when a settlement takes a footprint.
	for required in ["grove","mine","chapel"]:
		var exists: bool=false
		for entry in layout.values():
			if entry.poi.get("kind","")==required: exists=true
		if not exists:
			for entry in sorted_noise:
				if entry.poi.is_empty():
					add_poi(entry,required)
					entry.biome=BIOMES[1] if required=="grove" else BIOMES[2]
					break
	pois.clear()
	for data in layout.values():
		if not data.poi.is_empty(): pois.append(data.poi)
	connect_roads()
	for data in layout.values(): populate_data(data)

func add_poi(data: Dictionary, kind: String) -> void:
	data.poi={"kind":kind,"position":data.center,"access":data.center+Vector2(0,6),"id":"%d/poi/%s" % [world_seed,chunk_key(data.coord)]}
	if kind in ["ruin","crypt"]: data.biome=BIOMES[2]

func connect_roads() -> void:
	var connected: Array[Vector2]=[Vector2(-18,0),Vector2(20,12),Vector2(31,25)]
	var remaining: Array[Dictionary]=pois.duplicate()
	while not remaining.is_empty():
		var best_index: int=0
		var from:=connected[0]
		var shortest: float=INF
		for i in remaining.size():
			for source in connected:
				var distance: float=source.distance_squared_to(remaining[i].access)
				if distance<shortest:
					shortest=distance
					best_index=i
					from=source
		var destination: Vector2=remaining[best_index].access
		var middle: Vector2=(from+destination)*.5
		middle+=(destination-from).normalized().orthogonal()*ground_noise.get_noise_2d(middle.x,middle.y)*9
		roads.append([from,middle,destination])
		connected.append(destination)
		remaining.remove_at(best_index)

func road_distance(p: Vector2) -> float:
	var distance: float=INF
	for road in roads:
		for i in range(road.size()-1):
			distance=minf(distance,p.distance_to(Geometry2D.get_closest_point_to_segment(p,road[i],road[i+1])))
	return distance

func clear_for_prop(p: Vector2, poi: Dictionary, padding: float = 2.4) -> bool:
	if HUB.grow(.8).has_point(p) or road_distance(p)<padding: return false
	if landscape.water_distance(p)<.7 or minf(minf(p.x+96,128-p.x),minf(p.y+96,128-p.y))<5: return false
	for feature in pois:
		if p.distance_to(feature.position)<float(feature.get("radius",7)): return false
	return true

func populate_data(data: Dictionary) -> void:
	var rng:=local_rng(data.coord,327)
	var origin: Vector2=Vector2(data.coord)*32
	var density: float=density_noise.get_noise_2d(data.center.x,data.center.y)
	var clusters: int=9 if data.biome==BIOMES[0] else (22 if data.biome==BIOMES[1] else 12)
	if data.biome==BIOMES[1] and density>.05: clusters=28
	var trees: Array[Vector2] = []
	for i in range(clusters*4):
		if trees.size()>=clusters: break
		var p: Vector2=origin+Vector2(rng.randf_range(3,29),rng.randf_range(3,29))
		if not clear_for_prop(p,data.poi,3.0): continue
		var too_close: bool=false
		for previous in trees:
			if p.distance_to(previous)<4.5: too_close=true
		if too_close: continue
		trees.append(p)
		var tree: String="tree_oak" if data.biome==BIOMES[0] else "tree_pineTallA"
		if i%3==0: tree="tree_oak_fall" if data.biome==BIOMES[2] else "tree_oak"
		data.props.append({"asset":tree,"p":p,"h":rng.randf_range(4.5,6.7),"yaw":rng.randf()*360,"solid":true})
		# Every tree anchors a small authored-style understory group.
		for j in range(7):
			var angle: float=rng.randf()*TAU
			var under: Vector2=p+Vector2(sin(angle),cos(angle))*rng.randf_range(1.2,2.1)
			if not clear_for_prop(under,data.poi,2.1): continue
			data.props.append({"asset":"plant_bushSmall" if j<4 else ("log" if j==4 else "rock_smallA"),"p":under,"h":rng.randf_range(.3,.65),"yaw":rng.randf()*360,"solid":false})
	for i in range(9 if data.biome==BIOMES[2] else 3):
		var p: Vector2=origin+Vector2(rng.randf_range(2,30),rng.randf_range(2,30))
		if not clear_for_prop(p,data.poi): continue
		for j in range(3):
			data.props.append({"asset":"rock_tallA" if data.biome==BIOMES[2] and j==0 else "rock_smallA","p":p+Vector2(j*.65,j*.37),"h":rng.randf_range(.7,1.3) if j==0 else .25,"yaw":rng.randf()*360,"solid":false})
	for i in range(12):
		var p: Vector2=origin+Vector2(rng.randf_range(1,31),rng.randf_range(1,31))
		if not clear_for_prop(p,data.poi,1.9): continue
		var flower: String="flower_yellowA" if data.biome==BIOMES[0] else ("mushroom_redGroup" if data.biome==BIOMES[1] else "flower_purpleA")
		for j in range(3):
			data.props.append({"asset":flower,"p":p+Vector2(j*.3,sin(j)*.4),"h":rng.randf_range(.18,.32),"yaw":rng.randf()*360,"solid":false})
	var enemy_count: int=1 if data.biome==BIOMES[0] else 2
	for i in range(enemy_count):
		for attempt in 15:
			var p: Vector2=origin+Vector2(rng.randf_range(6,26),rng.randf_range(6,26))
			if HUB.grow(5).has_point(p) or p.length()<24: continue
			if not clear_for_prop(p,data.poi,1.5): continue
			var blocked: bool=false
			for prop in data.props:
				if prop.solid and p.distance_to(prop.p)<1.7: blocked=true
			if blocked: continue
			var pool: Array=["slime","slime","wolf"] if data.biome==BIOMES[0] else (["wolf","bat","witch"] if data.biome==BIOMES[1] else ["skeleton","archer","witch"])
			var difficulty: int=clampi(1+floori(p.length()/28)+(2 if data.biome==BIOMES[2] else 0),1,10)
			data.enemies.append({"p":p,"id":"%d/enemy/%s/%d" % [world_seed,chunk_key(data.coord),i],"kind":pool[rng.randi_range(0,pool.size()-1)],"level":difficulty})
			break

func update_streaming(immediate: bool = false) -> void:
	if not is_instance_valid(player): return
	if player.global_position.x>900: return
	var center: Vector2i=coord_at(player.global_position)
	if center==current_chunk and not immediate: return
	current_chunk=center
	pending.clear()
	for x in range(center.x-stream_radius,center.x+stream_radius+1):
		for z in range(center.y-stream_radius,center.y+stream_radius+1):
			var coord:=Vector2i(x,z)
			if valid_coord(coord) and not active_chunks.has(chunk_key(coord)): pending.append(coord)
	pending.sort_custom(func(a,b): return (a-center).length_squared()<(b-center).length_squared())
	for key in active_chunks.keys():
		var chunk: Node3D=active_chunks[key]
		var coord: Vector2i=chunk.get_meta("coord")
		if maxi(absi(coord.x-center.x),absi(coord.y-center.y))>stream_radius+1:
			remove_child(chunk)
			chunk.queue_free()
			active_chunks.erase(key)
	if immediate:
		while not pending.is_empty(): build_chunk(pending.pop_front())

func build_chunk(coord: Vector2i) -> void:
	var key: String=chunk_key(coord)
	if active_chunks.has(key): return
	var data: Dictionary=layout[key]
	var chunk:=Node3D.new()
	chunk.name="Chunk_%d_%d" % [coord.x,coord.y]
	chunk.set_meta("coord",coord)
	add_child(chunk)
	active_chunks[key]=chunk
	chunk.visible=not staged
	stage_tag="terrain_roads"
	build_ground(data,chunk)
	if staged:
		await budget_yield()
		if not is_instance_valid(chunk) or not chunk.is_inside_tree(): return
	var batches: Dictionary={}
	stage_tag="trees"
	var resource_index: int=0
	var resource_counts: Dictionary={}
	var tree_index: int=0
	for prop in data.props:
		var p: Vector3=Vector3(prop.p.x,landscape.height(prop.p),prop.p.y)
		var item: String="wood" if prop.asset=="log" else ("wild_herb" if prop.asset=="plant_bushSmall" else ("mushroom" if "mushroom" in prop.asset else ("stone" if "rock" in prop.asset else "")))
		if item=="stone" and data.biome==BIOMES[2]: item="iron_ore" if resource_index%3 else "crystal"
		var harvest: bool=not item.is_empty() and resource_index<10 and int(resource_counts.get(item,0))<2
		if prop.solid:
			if not prop.get("reserved",false) and not camp_reserved(prop.p): ValeResource.spawn(world,chunk,"%d/resource/%s/tree_%d" % [world_seed,key,tree_index],"wood",p,world.NATURE+prop.asset+".glb",prop.h,prop.yaw,true)
			tree_index+=1
		elif harvest:
			resource_counts[item]=int(resource_counts.get(item,0))+1
			if not prop.get("reserved",false) and not camp_reserved(prop.p): ValeResource.spawn(world,chunk,"%d/resource/%s/%d" % [world_seed,key,resource_index],item,p,world.NATURE+prop.asset+".glb",maxf(prop.h,.5),prop.yaw)
			resource_index+=1
		else:
			if prop.get("reserved",false) or camp_reserved(prop.p): continue
			if not batches.has(prop.asset): batches[prop.asset]=[]
			batches[prop.asset].append(prop)
		if staged:
			await budget_yield()
			if not is_instance_valid(chunk) or not chunk.is_inside_tree(): return
	for asset in batches:
		stage_tag="small_"+asset
		batch_decoration(asset,batches[asset],chunk)
		if staged:
			await budget_yield()
			if not is_instance_valid(chunk) or not chunk.is_inside_tree(): return
	stage_tag="cover_water"
	if not data.props.is_empty() and data.biome!=BIOMES[2]:
		var p: Vector2=data.props[-1].p+Vector2(.7,.4)
		if clear_for_prop(p,{},.3): ValeResource.spawn(world,chunk,"%d/resource/%s/fiber" % [world_seed,key],"fiber",Vector3(p.x,landscape.height(p),p.y),world.NATURE+"grass.glb",.55)
	landscape.cover(data,chunk)
	landscape.water(chunk,data)
	if staged:
		await budget_yield()
		if not is_instance_valid(chunk) or not chunk.is_inside_tree(): return
	if data.biome!=BIOMES[2] and not data.props.is_empty() and absi(key.hash())%5==0:
		var point: Vector2=data.props[0].p+Vector2(2,1)
		var animal:=ValeFauna.new()
		animal.gen=self
		animal.species="fox" if absi(key.hash())%3==0 else ("deer" if absi(key.hash())%2==0 else "stag")
		animal.group_id=key
		animal.position=Vector3(point.x,landscape.height(point),point.y)
		chunk.add_child(animal)
		if animal.species!="fox" and absi(key.hash())%2==0:
			var companion:=ValeFauna.new(); companion.gen=self; companion.species="deer"; companion.group_id=key
			var second: Vector2=point+Vector2(1.8,1)
			companion.position=Vector3(second.x,landscape.height(second),second.y); companion.scale=Vector3.ONE*.82; chunk.add_child(companion)
	if not data.poi.is_empty():
		stage_tag="poi_"+data.poi.kind
		var poi: Node3D
		if data.poi.kind=="settlement":
			poi=ValeSettlement.new()
			poi.definition=data.poi
		else:
			poi=POI_SCENES[data.poi.kind].instantiate() if POI_SCENES.has(data.poi.kind) else ValeStoryPOI.new()
			poi.kind=data.poi.kind
			poi.persistent_id=data.poi.id
		poi.world=world
		poi.position=Vector3(data.poi.position.x,landscape.height(data.poi.position),data.poi.position.y)
		chunk.add_child(poi)
	if staged:
		await budget_yield()
		if not is_instance_valid(chunk) or not chunk.is_inside_tree(): return
	for spawn in data.enemies:
		stage_tag="enemies"
		var enemy:=preload("res://scenes/characters/Enemy.tscn").instantiate()
		enemy.position=Vector3(spawn.p.x,landscape.height(spawn.p)+.1,spawn.p.y)
		enemy.set_meta("archetype",spawn.kind)
		enemy.set_meta("persistent_id",spawn.id)
		enemy.set_meta("enemy_level",spawn.level)
		chunk.add_child(enemy)
	if not data.poi.is_empty() and data.poi.kind=="ruin":
		var elite:=preload("res://scenes/characters/Enemy.tscn").instantiate()
		elite.position=Vector3(data.center.x,landscape.height(data.center),data.center.y+4)
		elite.set_meta("archetype","elite")
		elite.set_meta("persistent_id",data.poi.id+"/elite")
		elite.set_meta("enemy_level",clampi(2+floori(data.center.length()/30),2,8))
		chunk.add_child(elite)
	if not data.poi.is_empty() and data.poi.kind in ["camp","pond","shrine"]:
		var encounter:=preload("res://scenes/characters/Enemy.tscn").instantiate()
		encounter.position=Vector3(data.center.x+3,landscape.height(data.center),data.center.y+2)
		encounter.set_meta("archetype","mimic" if data.poi.kind=="pond" else ("wolf" if data.poi.kind=="camp" else "witch"))
		encounter.set_meta("persistent_id",data.poi.id+"/encounter")
		encounter.set_meta("enemy_level",clampi(1+floori(data.center.length()/30),1,7))
		chunk.add_child(encounter)
	if data.poi.get("kind","")=="camp": ValeSettlement.station(world,"campfire",Vector3(data.center.x+3,landscape.height(data.center),data.center.y+4),chunk)
	chunk.visible=true

func build_ground(data: Dictionary, parent: Node3D) -> void:
	landscape.ground(data,parent)
	build_roads(data,parent)

func ground_color(p: Vector2) -> Color:
	return landscape.color_at(p)

func build_roads(data: Dictionary, parent: Node3D) -> void:
	var origin: Vector2=Vector2(data.coord)*32
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int=0
	for road in roads:
		for segment in range(road.size()-1):
			var a: Vector2=road[segment]
			var b: Vector2=road[segment+1]
			var side: Vector2=(b-a).normalized().orthogonal()*1.55
			var ribbon:=PackedVector2Array([a-side,b-side,b+side,a+side])
			for x in range(0,32,2):
				for z in range(0,32,2):
					var p:=origin+Vector2(x,z)
					if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))>5: continue
					for tri in [[p,p+Vector2(2,0),p+Vector2(0,2)],[p+Vector2(2,0),p+Vector2(2,2),p+Vector2(0,2)]]:
						for polygon in Geometry2D.intersect_polygons(ribbon,PackedVector2Array(tri)):
							for j in range(1,polygon.size()-1):
								for v in [polygon[0],polygon[j],polygon[j+1]]:
									surface.set_normal(Vector3.UP)
									surface.add_vertex(Vector3(v.x,landscape.height(v)+.06,v.y))
									count+=1
			var steps: int=ceili(a.distance_to(b))
			for step in steps:
				var p: Vector2=a.lerp(b,float(step)/steps)
				if Rect2(origin,Vector2(32,32)).has_point(p) and landscape.water_distance(p)<2:
					var plank:=world.box(Vector3(p.x,.24,p.y),Vector3(3.7,.16,.92),"93785a",false,parent)
					plank.rotation.y=-atan2((b-a).y,(b-a).x)+PI/2
	if count==0: return
	var mesh:=MeshInstance3D.new()
	mesh.name="TerrainFollowingRoad"
	mesh.mesh=surface.commit()
	var material: StandardMaterial3D=world.mat("b7a07a").duplicate()
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=material
	parent.add_child(mesh)

func collect_mesh_parts(node: Node3D, transform: Transform3D, result: Array) -> void:
	var current: Transform3D=transform*node.transform
	if node is MeshInstance3D:
		var mesh: Mesh=node.mesh.duplicate()
		for i in mesh.get_surface_count(): mesh.surface_set_material(i,node.get_active_material(i))
		result.append({"mesh":mesh,"transform":current})
	for child in node.get_children():
		if child is Node3D: collect_mesh_parts(child,current,result)

func camp_reserved(_p: Vector2,_radius: float=17) -> bool: return false

func batch_decoration(asset: String, props: Array, parent: Node3D) -> void:
	if props.is_empty(): return
	if not decoration_cache.has(asset):
		var prototype:=world.place(asset if asset.begins_with("res://") else world.NATURE+asset+".glb",Vector3.ZERO,1,0,self)
		var parts: Array=[]
		collect_mesh_parts(prototype,Transform3D.IDENTITY,parts)
		if "Grass_" in asset:
			for part in parts:
				for i in part.mesh.get_surface_count():
					var material:=ShaderMaterial.new()
					material.shader=preload("res://shaders/ground_cover.gdshader")
					material.set_shader_parameter("blade_texture",load("res://assets/3d/phase4/nature/Grass.png"))
					part.mesh.surface_set_material(i,material)
		decoration_cache[asset]=parts
		remove_child(prototype)
		prototype.free()
	for part in decoration_cache[asset]:
		var multi:=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.use_colors=true
		multi.use_custom_data=true
		multi.mesh=part.mesh
		multi.instance_count=props.size()
		for i in props.size():
			var prop: Dictionary=props[i]
			var transform:=Transform3D(Basis(Vector3.UP,deg_to_rad(prop.yaw)).scaled(Vector3.ONE*prop.h),Vector3(prop.p.x,prop.y if prop.has("y") else landscape.height(prop.p),prop.p.y))
			multi.set_instance_transform(i,transform*part.transform)
			multi.set_instance_color(i,prop.get("tint",Color.WHITE))
			multi.set_instance_custom_data(i,prop.get("tint",Color.WHITE))
		var node:=MultiMeshInstance3D.new()
		node.multimesh=multi
		if "phase4/nature" in asset:
			node.set_meta("decorative_foliage",true)
			node.add_to_group("foliage_batches")
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end=140 if "phase4/nature" in asset else 0
		parent.add_child(node)

func fingerprint() -> String:
	return JSON.stringify(layout).sha256_text()

func _process(delta: float) -> void:
	update_streaming()
	generation_frame+=1
	if generation_frame%2==0 and not pending.is_empty(): build_chunk(pending.pop_front())
	discovery_clock-=delta
	if discovery_clock<=0 and not State.modal and is_instance_valid(player):
		discovery_clock=.4
		for poi in pois:
			if player.global_position.distance_to(Vector3(poi.position.x,landscape.height(poi.position),poi.position.y))<9:
				State.discover(poi.id,poi.get("title",poi.kind.capitalize()))
				State.quest_event("discover",poi.kind)
