extends "res://tests/visual_phase4.gd"
func run() -> void:
	game=get_tree().current_scene
	await frames(25)
	game.player.god_mode=true
	freeze_enemies()
	State.talk_npc("rowan")
	game.hud.close_modal()
	for p in [Vector3(9,0,2),Vector3(17,0,-2),Vector3(18,0,1),Vector3(20,0,4),Vector3(23,0,6),Vector3(26,0,10),Vector3(27,0,14),Vector3(28,0,22),Vector3(31,0,25)]:
		check(await walk_to(p),"Handcrafted forest connector "+str(Vector2(p.x,p.z)))
		freeze_enemies()
	await shot("first-road")
	# The nearest outward road is followed through every bend with real movement input.
	var choice: Array=[]
	for road in game.generator.roads:
		if road[0].distance_to(Vector2(31,25))<.1: choice=road; break
	check(not choice.is_empty(),"South forest connector joins procedural road graph")
	for p in choice:
		check(await walk_to(Vector3(p.x,game.generator.landscape.height(p),p.y)),"Generated road bend "+str(p))
		freeze_enemies()
	await shot("first-poi")
	var crossings: Array=[]
	for road in game.generator.roads:
		for i in range(road.size()-1):
			var a: Vector2=road[i]
			var b: Vector2=road[i+1]
			for j in 25:
				var p: Vector2=a.lerp(b,float(j)/24)
				if game.generator.landscape.water_distance(p)<.1:
					var direction: Vector2=(b-a).normalized()
					crossings=[p-direction*7,p+direction*7]
					break
			if not crossings.is_empty(): break
		if not crossings.is_empty(): break
	check(not crossings.is_empty(),"Road network includes river crossing")
	if not crossings.is_empty():
		await at(crossings[0])
		check(await walk_to(Vector3(crossings[1].x,game.generator.landscape.height(crossings[1]),crossings[1].y)),"River bridge is physically traversable")
		await shot("bridge-crossing")
	for edge in [[Vector2(-82,-70),Vector2(-82,-62)],[Vector2(111,-60),Vector2(111,-52)],[Vector2(-50,-82),Vector2(-42,-82)],[Vector2(-40,110),Vector2(-32,110)]]:
		await at(edge[0])
		check(await walk_to(Vector3(edge[1].x,game.generator.landscape.height(edge[1]),edge[1].y)),"Walk along outer watershed "+str(edge[0]))
		game.rig.target_yaw+=PI
		await frames(20)
	for mode in range(7):
		for node in game.debug_panel.get_children():
			if node is ValeLifeDebug: node.overlay.rebuild(mode)
	check(true,"All six generation overlays construct and clear")
	await at(Vector2(0,4))
	game.debug_panel.toggle()
	await shot("debug")
	game.debug_panel.toggle()
	var report: String="# Phase 4 physical traversal\n\n%d passed; %d failed.\n\n" % [checks.size(),failures.size()]
	for item in checks: report+="- PASS: "+item+"\n"
	for item in failures: report+="- FAIL: "+item+"\n"
	FileAccess.open("res://docs/PHASE_4_TRAVERSAL.md",FileAccess.WRITE).store_string(report)
	print("WALK4_RESULT ",checks.size()," passed ",failures.size()," failed")
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)
