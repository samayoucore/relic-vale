extends Node
var game: Node
var rows: Array=[]
var started_ms: int=0
func _ready() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i in n: await get_tree().process_frame
func sample(label: String,seconds: float=5.0,movement: bool=false,mounted_input: bool=false) -> void:
	await frames(120)
	var samples: Array=[]
	var starting_position: Vector3=game.player.global_position
	if mounted_input:
		Input.action_press("move_right"); Input.action_press("sprint")
	var start: int=Time.get_ticks_usec()
	var previous: int=start
	var cpu: float=0.0
	var physics: float=0.0
	var navigation: float=0.0
	var draw: float=0.0
	var previous_move: int=start
	while Time.get_ticks_usec()-start<int(seconds*1000000):
		if movement:
			game.player.position.x+=20.0*(Time.get_ticks_usec()-previous_move)/1000000.0
			previous_move=Time.get_ticks_usec()
		State.hp=State.max_hp
		await get_tree().process_frame
		var now: int=Time.get_ticks_usec()
		samples.append((now-previous)/1000.0); previous=now
		cpu+=Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
		physics+=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0
		navigation+=Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS)*1000.0
		draw+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	if mounted_input:
		Input.action_release("move_right"); Input.action_release("sprint")
	samples.sort()
	var n: int=samples.size()
	var row: Dictionary={"scenario":label,"preset":Preferences.values.preset,"resolution":str(DisplayServer.window_get_size()),"frames":n,"fps":n*1000000.0/(previous-start),"p50_ms":samples[n/2],"p95_ms":samples[mini(n-1,int(n*.95))],"max_ms":samples[-1],"cpu_process_ms":cpu/n,"physics_ms":physics/n,"navigation_ms":navigation/n,"draw_calls":draw/n,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"gpu_ms":null,"loaded_chunks":game.generator.active_chunks.size(),"chunk_worst_ms":game.generator.worst_build_ms,"chunk_stage_ms":game.generator.worst_stages.duplicate()}
	row.map_tile_worst_ms=game.cartography.worst_tile_ms
	row.mounted=game.mounts.mounted
	row.movement_m=game.player.global_position.distance_to(starting_position)
	row.process_working_set_bytes=null
	rows.append(row); print("BENCHMARK ",JSON.stringify(row))
	var file:=FileAccess.open(OS.get_environment("VALE_QA_OUTPUT"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"debug_build":OS.is_debug_build(),"renderer":RenderingServer.get_current_rendering_method(),"samples":rows},"\t")); file.close()
func mounted_benchmark() -> void:
	if not game.mounts.own():
		State.coins=maxi(State.coins,180)
		game.mounts.acquire()
	for other in get_tree().get_nodes_in_group("enemies"):
		if other.global_position.distance_to(game.player.global_position)<20: other.queue_free()
	await frames(4)
	if not game.mounts.own() or not game.mounts.call_mount():
		push_error("Mounted benchmark could not summon the owned horse")
		return
	if not is_instance_valid(game.mounts.actor):
		push_error("Mounted benchmark horse actor missing")
		return
	game.player.position=game.mounts.actor.global_position+Vector3(0,0,1)
	if not game.mounts.mount():
		push_error("Mounted benchmark could not mount the horse")
		return
	await sample("H_mounted_travel",8.0,false,true)
	game.mounts.dismount()
func run() -> void:
	game=get_tree().current_scene
	started_ms=Time.get_ticks_msec()
	await frames(5)
	game.test_mode=true; game.gameplay_started=true; game.hud.close_modal()
	Preferences.temporary=true
	Preferences.values.display="Windowed"; Preferences.values.resolution=Vector2i(1280,720)
	Preferences.values.vsync=false; Preferences.values.fps_limit=0
	Preferences.set_preset("Medium")
	game.new_world(20260907); game.hud.close_modal(); game.life.set_time(12)
	if OS.get_environment("VALE_QA_ONLY")=="stream":
		await sample("H_streaming_travel",8.0,true)
		print("BENCHMARK_COMPLETE"); await Feel.shutdown(); get_tree().quit(); return
	if OS.get_environment("VALE_QA_ONLY")=="mount":
		if FileAccess.file_exists("user://phase9-stories.json"): game.load_game("user://phase9-stories.json")
		game.hud.close_modal()
		game.generator.teleport_logical(0,0,Vector3(0,0,3.6)); game.rig.snap()
		await mounted_benchmark()
		print("BENCHMARK_COMPLETE"); await Feel.shutdown(); get_tree().quit(); return
	if OS.get_environment("VALE_QA_ONLY")=="presets":
		State.life_data.weather="Clear"
		for preset in ["Minimal","Medium","High","Ultra"]:
			Preferences.set_preset(preset)
			await sample("A_preset_scaling")
		print("BENCHMARK_COMPLETE"); await Feel.shutdown(); get_tree().quit(); return
	await sample("A_starting_village")
	game.generator.teleport_logical(8,8,Vector3(16,0,16)); game.rig.snap()
	await sample("B_procedural_forest")
	if FileAccess.file_exists("user://phase9-stories.json"):
		game.load_game("user://phase9-stories.json"); game.active_save_path="user://phase10-benchmark.json"; game.hud.close_modal()
		var at: Dictionary=State.camp_data.address
		game.generator.teleport_logical(int(at.x),int(at.z),ValeSave.vector(at.local)+Vector3(0,0,4)); game.rig.snap()
		await sample("C_developed_camp")
	game.generator.teleport_logical(0,0,Vector3(0,0,3.6)); game.rig.snap()
	var settlement: Dictionary={}
	var region_plan: ValeRegionPlan=game.generator.planner(ValeRegionPlan.key(0,0))
	for rx in range(1,9):
		for rz in range(1,9):
			for poi in region_plan.region(rx,rz).pois:
				if poi.kind=="settlement":
					var cx: int=floori(poi.position.x/32.0)
					var cz: int=floori(poi.position.y/32.0)
					settlement={"x":cx,"z":cz,"offset":Vector3(poi.position.x-cx*32,0,poi.position.y-cz*32+5)}
					break
			if not settlement.is_empty(): break
		if not settlement.is_empty(): break
	if not settlement.is_empty():
		game.generator.teleport_logical(settlement.x,settlement.z,settlement.offset); game.rig.snap()
		await sample("D_procedural_settlement")
	else: push_error("Benchmark settlement not found")
	game.generator.teleport_logical(0,0,Vector3(0,0,3.6)); game.rig.snap()
	var enemies: Array=[]
	for i in 12:
		var enemy=load("res://scenes/characters/Enemy.tscn").instantiate()
		enemy.position=game.player.position+Vector3(cos(i)*5,0,sin(i)*5); game.world.add_child(enemy); enemy.hp=9999; enemies.append(enemy)
	await sample("E_twelve_enemies")
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	game.player.position=Vector3(1000,0,-34); game.rig.snap()
	var guardian=load("res://scenes/characters/Enemy.tscn").instantiate()
	guardian.set_meta("archetype","guardian"); guardian.position=game.player.position+Vector3(0,0,-7); guardian.hp=9999
	game.world.add_child(guardian)
	await sample("F_guardian_encounter")
	if is_instance_valid(guardian): guardian.queue_free()
	game.player.position=Vector3(0,0,3.6); game.rig.snap()
	State.life_data.weather="Storm"
	State.life_data.weather_block=int(State.life_data.day)*8+int(State.life_data.minute/180)
	await sample("G_storm")
	await mounted_benchmark()
	await sample("H_streaming_travel",8.0,true)
	var loading: Array=[]
	for at in [Vector2i(1000,1000),Vector2i(10000,-10000),Vector2i(0,0)]:
		var begin: int=Time.get_ticks_usec()
		game.generator.teleport_logical(at.x,at.y); game.rig.snap()
		await frames(3)
		loading.append({"address":str(at),"ms":(Time.get_ticks_usec()-begin)/1000.0})
	print("BENCHMARK_LOADING ",JSON.stringify(loading))
	State.life_data.weather="Clear"
	for preset in ["Minimal","Medium","High","Ultra"]:
		Preferences.set_preset(preset)
		game.generator.teleport_logical(0,0,Vector3(0,0,3.6)); game.rig.snap()
		await sample("A_preset_scaling")
	if OS.get_environment("VALE_QA_SOAK")=="1":
		Preferences.set_preset("Medium")
		while Time.get_ticks_msec()-started_ms<900000:
			await sample("long_session_village",20.0)
	var output=FileAccess.open(OS.get_environment("VALE_QA_OUTPUT"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"debug_build":OS.is_debug_build(),"renderer":RenderingServer.get_current_rendering_method(),"samples":rows},"\t")); output.close()
	print("BENCHMARK_COMPLETE")
	await Feel.shutdown(); get_tree().quit()
