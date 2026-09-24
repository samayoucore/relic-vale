extends "res://tests/visual_phase4.gd"

func settle(gen: ValeStreamingGenerator) -> bool:
	for i in 4000:
		await frames(1)
		if gen.jobs.is_empty() and gen.requests.is_empty() and not gen.building:
			await frames(3)
			return true
	return false

func run() -> void:
	game=get_tree().current_scene
	await frames(25)
	game.player.god_mode=true
	var gen: ValeStreamingGenerator=game.generator
	if "--far-reload" in OS.get_cmdline_user_args():
		check(gen.origin_x==10000 and gen.origin_z==10000,"Fresh process resumes far logical origin")
		check(game.player.is_on_floor() and game.player.position.length()<150,"Fresh process resumes far physical floor near local origin")
		check(not State.gathered_resources.is_empty(),"Content-addressed chunk records restore harvested delta")
		var id: String=State.world_data.test_resource
		check(State.gathered_resources.has(id),"Exact stable resource remains harvested after exit/reload")
	else:
		# Neighboring planners independently calculate the shared border, including region boundaries.
		for pair in [[3,0],[10000,-500],[1000000000,-1000000000]]:
			var a:=gen.planner(ValeRegionPlan.key(pair[0],pair[1]))
			var b:=gen.planner(ValeRegionPlan.key(pair[0]+1,pair[1]))
			var maximum: float=0
			for z in range(0,33,2): maximum=maxf(maximum,absf(a.height_at(Vector2(32,z))-b.height_at(Vector2(0,z))))
			check(maximum<.0001,"Shared terrain edge agrees at "+str(pair))
			check(absf(a.water_distance(Vector2(32,16))-b.water_distance(Vector2(0,16)))<.0001,"River field crosses shared edge at "+str(pair))
		gen.teleport_logical(50,50)
		var maximum_nodes: int=0
		var travelled: int=0
		for i in 100:
			# Step into an already preloaded neighbor, then allow normal asynchronous streaming to catch up.
			var pos: Vector3=game.player.position+Vector3(32,0,0 if i%7 else 32)
			pos.y=gen.landscape.height(Vector2(pos.x,pos.z))+.15
			game.player.position=pos; game.player.velocity=Vector3.ZERO
			gen.update_streaming()
			var ready: bool=await settle(gen)
			if not ready: check(false,"Streaming queue drains at step "+str(i)); break
			freeze_enemies()
			travelled+=1
			maximum_nodes=maxi(maximum_nodes,int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
			if gen.active_chunks.size()>49 or gen.blueprints.size()>110: check(false,"Stream/cache bound at step "+str(i)); break
			if i%20==0: print("STREAM_STRESS_STEP ",i," active=",gen.active_chunks.size()," data=",gen.blueprints.size()," ms=",gen.generation_ms," stages=",gen.worst_stages)
		check(travelled==100,"Travel through 100 neighboring chunks using asynchronous generation")
		check(gen.shifts>=15,"Repeated floating-origin shifts occur during travel")
		check(gen.blueprints.size()<=110 and gen.active_chunks.size()<=49,"Data cache and active scene counts remain bounded")
		gen.teleport_logical(10000,10000)
		await frames(25)
		freeze_enemies()
		var resource: ValeInteractable
		for node in get_tree().get_nodes_in_group("interactables"):
			if node.kind=="resource": resource=node; break
		check(resource!=null,"Far chunks contain physical resource nodes")
		if resource:
			game.player.position=resource.global_position+Vector3(0,.15,1)
			if resource is ValeResource:
				var tool: String=resource.definition.tool
				if not tool.is_empty(): State.equip("crude_"+tool)
				for hit in 8:
					if resource.remaining()<=0: break
					resource.interact(game.player); await frames(58)
			else: resource.interact(game.player)
			State.world_data.test_resource=resource.persistent_id
			check(State.gathered_resources.has(resource.persistent_id),"Far resource interaction changes its stable delta")
		check(game.save_game(false,"user://phase5-far.json"),"Far journey writes current save version and separate delta records")
		var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://phase5-far.json"))
		check(raw.gathered_resources.is_empty() and not raw.chunk_manifest.is_empty(),"Main save stores references instead of generated scenery or aggregate resource records")
		check(game.load_game("user://phase5-far.json"),"Far v5 journey reloads in-session")
		check(State.gathered_resources.has(State.world_data.test_resource),"Exact resource delta survives in-session reload")
		print("STREAM_STRESS_METRICS traversed=",travelled," nodes_max=",maximum_nodes," build_stage_max_ms=",gen.worst_build_ms," last_worker_ms=",gen.generation_ms)
	var report: String="# Phase 6 streamed-world regression\n\n%d passed; %d failed.\n\n" % [checks.size(),failures.size()]
	for item in checks: report+="- PASS: "+item+"\n"
	for item in failures: report+="- FAIL: "+item+"\n"
	FileAccess.open("res://docs/PHASE_6_"+("FAR_RELOAD" if "--far-reload" in OS.get_cmdline_user_args() else "STRESS")+".md",FileAccess.WRITE).store_string(report)
	print("STRESS5_RESULT ",checks.size()," passed ",failures.size()," failed")
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)
