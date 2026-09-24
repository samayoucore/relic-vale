extends "res://tests/visual_phase4.gd"

func run() -> void:
	game=get_tree().current_scene
	await frames(25)
	game.player.god_mode=true
	var gen: ValeStreamingGenerator=game.generator
	check(game.player.is_on_floor(),"Starting village retains its physical floor")
	check(gen.active_chunks.size()==25,"Initial preload window contains 25 chunks")
	var plan:=gen.planner("10000,-5000")
	plan.generate()
	plan.result.erase("generation_ms")
	var fingerprint: String=JSON.stringify(plan.result).sha256_text()
	plan.generate()
	plan.result.erase("generation_ms")
	check(fingerprint==JSON.stringify(plan.result).sha256_text(),"Far logical chunk regenerates deterministically")
	for target in [[100,100],[1000,-500],[10000,10000],[1000000000,-1000000000]]:
		gen.teleport_logical(target[0],target[1])
		await frames(20)
		freeze_enemies()
		check(game.player.position.length()<35,"Far teleport keeps local player close: "+str(target))
		check(game.player.is_on_floor(),"Far world has collision: "+str(target))
		check(gen.origin_x==target[0] and gen.origin_z==target[1],"Far logical address preserved: "+str(target))
		var a: Dictionary=gen.address(game.player.position)
		check(gen.position_of(a).distance_to(game.player.position)<.001,"Logical/local position roundtrip")
		await shot("stream-"+str(target[0]))
	var before: Dictionary=gen.address(game.player.position)
	var near: Vector3=game.player.position
	gen.shift_origin(Vector2i(4,-4))
	check(gen.address(game.player.position)==before,"Floating origin preserves exact logical location")
	check(game.player.position==near-Vector3(128,0,-128),"Player and scene shift by the same offset")
	gen.teleport_logical(0,0,Vector3(0,0,4))
	await frames(20)
	check(game.world.hub_root.is_inside_tree() and game.player.is_on_floor(),"Return to original village restores authored scene")
	print("STREAM5_RESULT ",checks.size()," passed ",failures.size()," failed")
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)
