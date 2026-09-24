class_name ValeStreamingGenerator
extends ValeGenerator
## Logical 64-bit chunk addresses; rendering coordinates stay within a small floating window.
var origin_x: int=0
var origin_z: int=0
var starter: Dictionary={}
var starter_roads: Array=[]
var starter_pois: Array=[]
var blueprints: Dictionary={}
var jobs: Dictionary={}
var requests: Array[String]=[]
var lifecycle: Dictionary={}
var lru: Array[String]=[]
var cache_limit: int=48
var preload_radius: int=2
var unload_radius: int=3
var generation_ms: float=0
var worst_build_ms: float=0
var shifts: int=0
var building: bool=false
var revision: int=0
var stage_started: int=0
var last_center: String=""
var discovered: Dictionary={}
var game: Node
var hub_origin:=Vector2i.ZERO
var worst_stages: Dictionary={}

func _ready() -> void:
	game=get_tree().current_scene
	world=get_parent()
	regenerate(world_seed)

func chunk_key(coord: Vector2i) -> String: return ValeRegionPlan.key(origin_x+coord.x,origin_z+coord.y)
func valid_coord(_coord: Vector2i) -> bool: return true
func in_hub(p: Vector2) -> bool:
	return absi(origin_x)<12 and absi(origin_z)<12 and HUB.has_point(p+Vector2(origin_x*32,origin_z*32))
func local_rng(coord: Vector2i,salt: int=0) -> RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=(str(world_seed)+"/"+chunk_key(coord)+"/"+str(salt)).hash()
	return rng

func regenerate(seed_value: int) -> void:
	finish_jobs()
	revision+=1
	for child in get_children(): remove_child(child); child.queue_free()
	active_chunks.clear(); layout.clear(); pending.clear(); requests.clear(); lifecycle.clear(); blueprints.clear(); lru.clear()
	last_center=""
	world_seed=absi(seed_value)%2147483647; State.world_seed=world_seed
	# Only the unique starter region is authored eagerly. Everything else is streamed.
	if starter.is_empty() or int(starter.get("seed",-1))!=world_seed:
		var old_x: int=origin_x; var old_z: int=origin_z
		origin_x=0; origin_z=0
		landscape=ValeLandscape.new()
		super.build_layout()
		starter=layout.duplicate(true); starter["seed"]=world_seed
		starter_roads=roads.duplicate(true); starter_pois=pois.duplicate(true)
		origin_x=old_x; origin_z=old_z
	landscape=ValeInfiniteLandscape.new()
	landscape.setup(self)
	layout.clear(); pois.clear(); roads.clear()
	staged=false
	update_streaming(true)

func local_coord(key: String) -> Vector2i:
	var parts:=key.split(",")
	return Vector2i(int(parts[0])-origin_x,int(parts[1])-origin_z)
func address(p: Vector3) -> Dictionary:
	var c: Vector2i=coord_at(p)
	return {"x":str(origin_x+c.x),"z":str(origin_z+c.y),"local":[fposmod(p.x,32),p.y,fposmod(p.z,32)]}
func position_of(value: Dictionary) -> Vector3:
	var offset: Array=value.get("local",[0,0,0])
	return Vector3((int(value.get("x","0"))-origin_x)*32+float(offset[0]),float(offset[1]),(int(value.get("z","0"))-origin_z)*32+float(offset[2]))

func planner(key: String) -> ValeRegionPlan:
	var parts:=key.split(",")
	var plan:=ValeRegionPlan.new()
	plan.setup(world_seed,int(parts[0]),int(parts[1]),starter,starter_roads,starter_pois)
	return plan
func request(key: String) -> void:
	if blueprints.has(key) or jobs.has(key) or requests.has(key): return
	requests.append(key); lifecycle[key]="REQUESTED"
func start_jobs() -> void:
	while jobs.size()<2 and not requests.is_empty():
		var key: String=requests.pop_front()
		var plan:=planner(key)
		var task: int=WorkerThreadPool.add_task(plan.generate,false,"Chunk "+key)
		jobs[key]={"task":task,"plan":plan}; lifecycle[key]="GENERATING_DATA"
func collect_jobs() -> void:
	for key in jobs.keys():
		if not WorkerThreadPool.is_task_completed(jobs[key].task): continue
		WorkerThreadPool.wait_for_task_completion(jobs[key].task)
		blueprints[key]=jobs[key].plan.result
		generation_ms=blueprints[key].generation_ms
		jobs.erase(key); lifecycle[key]="READY_TO_INSTANTIATE"
func finish_jobs() -> void:
	for job in jobs.values(): WorkerThreadPool.wait_for_task_completion(job.task)
	jobs.clear()
func _exit_tree() -> void:
	finish_jobs()
	if is_instance_valid(world.hub_root) and world.hub_root.get_parent()==null: world.hub_root.free()

func materialize_data(key: String) -> Dictionary:
	var data: Dictionary=blueprints[key].duplicate(true)
	var coord: Vector2i=local_coord(key); var offset:=Vector2(coord)*32
	var plan: ValeRegionPlan=planner(key)
	if not starter.has(key):
		for prop in data.props: prop.reserved=plan.natural_clearing(prop.p)
		data.enemies=data.enemies.filter(func(entry): return not plan.natural_clearing(entry.p,27))
	data.coord=coord; data.center=offset+Vector2(16,16)
	for field in ["props","enemies"]:
		for entry in data[field]: entry.p+=offset
	data.enemies=data.enemies.filter(func(entry): return not camp_reserved(entry.p,25))
	if not data.poi.is_empty(): data.poi.position+=offset; data.poi.access+=offset
	for asset in data.cover:
		for prop in data.cover[asset]: prop.p+=offset
		data.cover[asset]=data.cover[asset].filter(func(prop): return not camp_reserved(prop.p))
	for p in data.grid: landscape.cache[p+offset]=data.grid[p]
	return data

func camp_reserved(p: Vector2,radius: float=20) -> bool:
	if State.camp_data.is_empty(): return false
	var address: Dictionary=State.camp_data.address
	if absi(int(address.x)-origin_x)>6 or absi(int(address.z)-origin_z)>6: return false
	var center: Vector3=position_of(address)
	return absf(p.x-center.x)<radius and absf(p.y-center.z)<radius
func refresh_context() -> void:
	roads.clear(); pois.clear()
	var seen: Dictionary={}
	for key in active_chunks:
		if not blueprints.has(key): continue
		var data: Dictionary=blueprints[key]
		var offset:=Vector2(local_coord(key))*32
		for road in data.roads: roads.append([road[0]+offset,road[1]+offset])
		for feature in data.features:
			if seen.has(feature.id): continue
			seen[feature.id]=true
			var copy: Dictionary=feature.duplicate(true); copy.position+=offset; copy.access+=offset; pois.append(copy)

func update_streaming(immediate: bool=false) -> void:
	if not is_instance_valid(player) or player.position.x>900: return
	var coord: Vector2i=coord_at(player.position); var center: String=chunk_key(coord)
	current_chunk=coord
	if center==last_center and not immediate: return
	last_center=center
	if not discovered.has(center): discovered[center]={"biome":biome_at(player.position)}
	var wanted: Array[String]=[]
	for radius in range(preload_radius+1):
		for x in range(-radius,radius+1):
			for z in range(-radius,radius+1):
				if maxi(absi(x),absi(z))!=radius: continue
				var key: String=chunk_key(coord+Vector2i(x,z))
				wanted.append(key); request(key)
	requests=requests.filter(func(key): return key in wanted)
	for key in lifecycle.keys():
		if not key in wanted and not active_chunks.has(key) and not blueprints.has(key) and not jobs.has(key): lifecycle.erase(key)
	for key in active_chunks.keys():
		var c: Vector2i=local_coord(key)
		if maxi(absi(c.x-coord.x),absi(c.y-coord.y))>unload_radius:
			var chunk: Node3D=active_chunks[key]
			remove_child(chunk); chunk.queue_free(); active_chunks.erase(key); layout.erase(key)
			lifecycle[key]="CACHED"; lru.erase(key); lru.append(key)
	for key in blueprints:
		if not active_chunks.has(key) and not key in wanted and not key in lru: lru.append(key)
	while lru.size()>cache_limit:
		var key: String=lru.pop_front()
		if active_chunks.has(key): continue
		blueprints.erase(key); lifecycle.erase(key)
	if immediate:
		# Blocking generation is limited to explicit loading/teleport operations.
		finish_jobs(); requests.clear()
		for key in wanted:
			if not blueprints.has(key):
				var plan:=planner(key); plan.generate(); blueprints[key]=plan.result
			if not active_chunks.has(key):
				layout[key]=materialize_data(key)
				# Current chunk roads, including neighboring region portal segments.
				var offset:=Vector2(local_coord(key))*32
				roads.assign(blueprints[key].roads.map(func(r): return [r[0]+offset,r[1]+offset]))
				super.build_chunk(local_coord(key))
				lifecycle[key]="ACTIVE"
		refresh_context()
	for key in active_chunks:
		var c: Vector2i=local_coord(key)-coord
		active_chunks[key].process_mode=Node.PROCESS_MODE_INHERIT if maxi(absi(c.x),absi(c.y))<=stream_radius else Node.PROCESS_MODE_DISABLED

func clear_for_prop(p: Vector2,_poi: Dictionary,padding: float=2.4) -> bool:
	if camp_reserved(p): return false
	if not landscape is ValeInfiniteLandscape: return super.clear_for_prop(p,_poi,padding)
	return landscape.sampler(p).clear(landscape.local_point(p),padding)

func build_roads(data: Dictionary,parent: Node3D) -> void:
	var offset:=Vector3(data.coord.x*32,0,data.coord.y*32)
	if not data.road_vertices.is_empty():
		var node:=MeshInstance3D.new(); var normals:=PackedVector3Array()
		normals.resize(data.road_vertices.size()); normals.fill(Vector3.UP)
		node.mesh=landscape.prepared_mesh(data.road_vertices,normals)
		node.material_override=world.mat("b7a07a"); node.position=offset
		parent.add_child(node)
	for bridge in data.bridges:
		var plank:=world.box(offset+Vector3(bridge.p.x,.24,bridge.p.y),Vector3(3.7,.16,.92),"93785a",false,parent)
		plank.rotation.y=bridge.yaw

func build_next(key: String) -> void:
	building=true
	var token: int=revision
	layout[key]=materialize_data(key)
	var offset:=Vector2(local_coord(key))*32
	roads.assign(blueprints[key].roads.map(func(r): return [r[0]+offset,r[1]+offset]))
	staged=true; stage_started=Time.get_ticks_usec()
	await super.build_chunk(local_coord(key))
	staged=false
	if token==revision:
		if active_chunks.has(key): lifecycle[key]="ACTIVE"; lru.erase(key)
		if active_chunks.has(key):
			var distance: Vector2i=local_coord(key)-current_chunk
			active_chunks[key].process_mode=Node.PROCESS_MODE_INHERIT if maxi(absi(distance.x),absi(distance.y))<=stream_radius else Node.PROCESS_MODE_DISABLED
		refresh_context()
	building=false

func budget_yield() -> void:
	var elapsed: float=(Time.get_ticks_usec()-stage_started)/1000.0
	worst_build_ms=maxf(worst_build_ms,elapsed)
	worst_stages[stage_tag]=maxf(float(worst_stages.get(stage_tag,0)),elapsed)
	if elapsed>=3:
		await get_tree().process_frame
		stage_started=Time.get_ticks_usec()

func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	if player.position.x<900 and not building and maxf(absf(player.position.x),absf(player.position.z))>128:
		shift_origin(coord_at(player.position))
	update_streaming()
	collect_jobs(); start_jobs()
	if not building and player.position.x<900:
		var available: Array=[]
		for key in blueprints:
			var c: Vector2i=local_coord(key)-current_chunk
			if not active_chunks.has(key) and maxi(absi(c.x),absi(c.y))<=preload_radius: available.append(key)
		available.sort_custom(func(a,b): return (local_coord(a)-current_chunk).length_squared()<(local_coord(b)-current_chunk).length_squared())
		if not available.is_empty(): build_next(available[0])
	discovery_clock-=delta
	if discovery_clock<=0 and not State.modal and player.position.x<900:
		discovery_clock=.4
		for poi in pois:
			if Vector2(player.position.x,player.position.z).distance_to(poi.position)<9:
				State.discover(poi.id,poi.get("title",poi.kind.capitalize())); State.quest_event("discover",poi.kind)
		var key: String=chunk_key(coord_at(player.position))
		if blueprints.has(key):
			if not discovered.get(key,{}).has("roads"): chart_chunk(key)

func chart_chunk(key: String) -> void:
	var data: Dictionary=blueprints[key]
	var record: Dictionary={"biome":data.biome,"poi":data.poi.get("kind",""),"title":data.poi.get("title",""),"roads":[],"water":[]}
	for road in data.roads:
		# Atlas lines are clipped to the explored tile so they reveal no unvisited land.
		var segments: Array=[]
		var steps: int=maxi(1,ceili(road[0].distance_to(road[1])/2))
		for i in steps:
			var a: Vector2=road[0].lerp(road[1],float(i)/steps)
			var b: Vector2=road[0].lerp(road[1],float(i+1)/steps)
			if Rect2(0,0,32,32).has_point(a) and Rect2(0,0,32,32).has_point(b): record.roads.append([a.x,a.y,b.x,b.y])
	for i in range(0,data.water_vertices.size(),24):
		var p: Vector3=data.water_vertices[i]; record.water.append([p.x,p.z])
	discovered[key]=record

func shift_origin(delta_chunk: Vector2i) -> void:
	if delta_chunk==Vector2i.ZERO: return
	var delta:=Vector3(delta_chunk.x*32,0,delta_chunk.y*32)
	origin_x+=delta_chunk.x; origin_z+=delta_chunk.y; shifts+=1
	for child in world.get_children():
		if child==self or child==game.expedition or child==world.hub_root or child.has_meta("interior") or child is WorldEnvironment or child is DirectionalLight3D: continue
		if child is Node3D and child.position.x<900: child.position-=delta
	if is_instance_valid(game.party): game.party.shift_paths(delta)
	for chunk in active_chunks.values(): chunk.position-=delta
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"):
		if enemy.origin.x<900: enemy.origin-=delta
	for animal in get_tree().get_nodes_in_group("fauna"): animal.shift_origin(delta)
	for npc in get_tree().get_nodes_in_group("interactables"):
		for child in npc.get_children():
			if child is ValeSchedule: child.shift_origin(delta)
	if world.hub_root.is_inside_tree(): hub_origin=Vector2i(origin_x,origin_z)
	State.dungeon_return-=delta
	landscape.cache.clear(); landscape.samplers.clear()
	for key in active_chunks:
		layout[key]=materialize_data(key)
		active_chunks[key].set_meta("coord",local_coord(key))
	refresh_context(); last_center=""
	sync_hub()
	# Rig is shifted by exactly the same delta; retain its interpolation and camera orbit.

func teleport_logical(x: int,z: int,offset: Vector3=Vector3(16,0,16)) -> void:
	# A loading transition may replace the whole window. Large addresses never become Vector3s.
	if is_instance_valid(game.party):
		for actor in game.party.actors.values(): actor.record_position()
		game.party.reset()
	if is_instance_valid(game.narrative): game.narrative.reset()
	if is_instance_valid(game.world_events): game.world_events.reset()
	finish_jobs(); revision+=1
	if is_instance_valid(game.loot_manager): game.loot_manager.clear()
	if is_instance_valid(game.life) and is_instance_valid(game.life.event_actor): game.life.event_actor.queue_free()
	for child in get_children(): remove_child(child); child.queue_free()
	active_chunks.clear(); layout.clear(); requests.clear(); blueprints.clear(); lru.clear(); lifecycle.clear()
	origin_x=x; origin_z=z
	landscape.cache.clear(); landscape.samplers.clear()
	player.position=offset
	last_center=""; staged=false
	update_streaming(true)
	player.position.y=landscape.height(Vector2(offset.x,offset.z))+.15
	player.velocity=Vector3.ZERO
	game.rig.snap()
	sync_hub()
	if is_instance_valid(game.party): game.party.sync(); game.party.after_transition()

func sync_hub() -> void:
	var near: bool=absi(origin_x)<8 and absi(origin_z)<8
	if near:
		var attaching: bool=not world.hub_root.is_inside_tree()
		if attaching: world.add_child(world.hub_root)
		world.hub_root.position=Vector3(-origin_x*32,0,-origin_z*32)
		var delta:=Vector3((origin_x-hub_origin.x)*32,0,(origin_z-hub_origin.y)*32)
		for npc in world.hub_root.find_children("*","",true,false):
			if npc is ValeSchedule: npc.shift_origin(delta)
			if npc is ValeFauna: npc.shift_origin(delta)
			if npc is OmniLight3D and not npc in world.lanterns: world.lanterns.append(npc)
		hub_origin=Vector2i(origin_x,origin_z)
		if is_instance_valid(game.interiors) and not State.residents.has("%d/willowmere/resident/rowan" % State.world_seed): game.interiors.setup_hub()
	elif world.hub_root.is_inside_tree():
		world.remove_child(world.hub_root)
		world.hub_root.position=Vector3.ZERO
