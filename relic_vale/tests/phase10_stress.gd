extends Node
var game: Node
var passed: int=0
var failed: int=0
var checks: Array=[]
var samples: Array=[]
var seen: Dictionary={}
var began: int=0
func _ready() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i in n: await get_tree().process_frame
func check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else: failed+=1
	checks.append({"pass":ok,"check":label}); print("PHASE10_STRESS ","PASS " if ok else "FAIL ",label)
func sample(label: String) -> void:
	var gen: ValeStreamingGenerator=game.generator
	var row: Dictionary={"label":label,"elapsed_seconds":(Time.get_ticks_msec()-began)/1000.0,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphan_nodes":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"active_chunks":gen.active_chunks.size(),"blueprints":gen.blueprints.size(),"map_cache":game.cartography.cache.size(),"samplers":gen.landscape.samplers.size(),"height_cache":gen.landscape.cache.size(),"shifts":gen.shifts}
	samples.append(row); print("STRESS_SAMPLE ",JSON.stringify(row))
	write_report()
func write_report() -> void:
	var file:=FileAccess.open("res://docs/PHASE_10_STRESS_TESTS.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":checks,"samples":samples,"unique_chunks":seen.size(),"finished":false},"\t")); file.close()
func settle() -> bool:
	var deadline: int=Time.get_ticks_msec()+20000
	while Time.get_ticks_msec()<deadline:
		await frames(1)
		game.player.invulnerability=10
		for key in game.generator.active_chunks: seen[key]=true
		if game.generator.jobs.is_empty() and game.generator.requests.is_empty() and not game.generator.building:
			await frames(3); return true
	return false
func fingerprint(x: int,z: int) -> String:
	var plan: ValeRegionPlan=game.generator.planner(ValeRegionPlan.key(x,z)); plan.generate()
	plan.result.erase("generation_ms")
	return JSON.stringify(plan.result).sha256_text()
func run() -> void:
	game=get_tree().current_scene; began=Time.get_ticks_msec()
	game.test_mode=true; game.gameplay_started=true; game.hud.close_modal()
	Preferences.temporary=true; Preferences.set_preset("Medium"); Engine.max_fps=120
	game.new_world(20260907); game.world_events.autonomous=false; game.player.invulnerability=1000
	await frames(15)
	var gen: ValeStreamingGenerator=game.generator
	var initial_hash: String=fingerprint(50,50)
	gen.teleport_logical(50,50); await settle(); sample("warmup")
	for step in 100:
		var point: Vector3=game.player.position+Vector3(32,0,32 if step%7==0 else 0)
		point.y=gen.landscape.height(Vector2(point.x,point.z))+.15
		game.player.position=point; game.player.velocity=Vector3.ZERO
		if not await settle(): check(false,"Streaming deadline at "+str(step)); break
		check(gen.active_chunks.size()<=49 and gen.blueprints.size()<=110,"Bounded streaming window at step "+str(step))
		check(gen.landscape.samplers.size()<=80 and gen.landscape.cache.size()<=19000,"Bounded terrain caches at step "+str(step))
		if step%10==0: sample("travel_"+str(step))
	check(seen.size()>=300,"At least 300 distinct chunks materialized")
	check(gen.shifts>=15,"At least 15 automatic origin shifts")
	check(fingerprint(50,50)==initial_hash,"Terrain, props, biome, POI, roads and river remain deterministic")
	for address in [Vector2i(1000,1000),Vector2i(10000,-10000),Vector2i(100000,100000),Vector2i(1000000000,-1000000000)]:
		gen.teleport_logical(address.x,address.y); await settle()
		check(gen.origin_x==address.x and gen.origin_z==address.y and game.player.position.length()<150,"Far logical address stays near render origin: "+str(address))
		var a:=gen.planner(ValeRegionPlan.key(address.x,address.y)); var b:=gen.planner(ValeRegionPlan.key(address.x+1,address.y))
		check(absf(a.height_at(Vector2(32,16))-b.height_at(Vector2(0,16)))<.0001,"Terrain edge agrees at "+str(address))
		check(absf(a.water_distance(Vector2(32,16))-b.water_distance(Vector2(0,16)))<.0001,"River agrees at "+str(address))
		check(game.save_game(false,"user://phase10-far.json"),"Far save succeeds at "+str(address))
	var loaded: Dictionary=ValeSave.read("user://phase10-far.json")
	check(loaded.get("world",{}).get("origin_x")=="1000000000","Far origin persists as exact decimal string")
	for cycle in 12:
		gen.teleport_logical(200+cycle*17,-300-cycle*11); await settle()
		gen.teleport_logical(0,0,Vector3(0,0,3.6)); await settle()
		check(game.party.actors.size()<=4,"No duplicated companions after teleport "+str(cycle))
		if cycle%3==0: sample("teleport_return_"+str(cycle))
	var building: Dictionary={}
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.has_meta("building"): building=node.get_meta("building"); break
	check(not building.is_empty(),"An authored building is available")
	if not building.is_empty():
		for cycle in 12:
			await game.interiors.enter(building)
			await frames(4)
			check(is_instance_valid(game.interiors.room),"One interior created "+str(cycle))
			await game.interiors.leave(); await frames(6)
			check(not is_instance_valid(game.interiors.room),"Interior freed on exit "+str(cycle))
	sample("after_interiors")
	for index in 540:
		var key: String=ValeRegionPlan.key(5000+index,10000)
		var deadline: int=Time.get_ticks_msec()+10000
		while game.cartography.tile(key)==null and Time.get_ticks_msec()<deadline: await frames(1)
		if index%90==0: sample("atlas_"+str(index))
	check(game.cartography.cache.size()==ValeCartography.LIMIT and game.cartography.pending.size()<=1,"Atlas LRU caps at 512 textures and one worker")
	game.cartography.forget_cache(); await frames(10)
	check(game.cartography.cache.is_empty() and game.cartography.pending.is_empty(),"Atlas reset joins and clears workers")
	gen.teleport_logical(0,0,Vector3(0,0,3.6)); await settle(); sample("final_village")
	check(samples[-1].nodes<16000,"Returned village does not retain distant scene nodes")
	check(game.save_game(false,"user://phase10-stress.json"),"Long-session save succeeds")
	check(game.load_game("user://phase10-stress.json"),"Long-session save reloads")
	game.active_save_path=ValeSave.PATH; await settle()
	game.process_mode=Node.PROCESS_MODE_DISABLED; game.cartography.forget_cache()
	write_report()
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/PHASE_10_STRESS_TESTS.json")); data.finished=true
	FileAccess.open("res://docs/PHASE_10_STRESS_TESTS.json",FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	print("PHASE10_STRESS_RESULT ",passed," / ",failed)
	await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)
