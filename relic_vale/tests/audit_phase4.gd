extends "res://tests/phase2_test.gd"
## Read-only baseline traversal and camera samples before Phase 4 visual changes.
func shot(name: String) -> void:
	await frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase4-before-"+name+".png")
	print("AUDIT4: ",name," position=",game.player.position," fps=",Engine.get_frames_per_second()," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

func run() -> void:
	game=get_tree().current_scene
	await frames(25)
	game.player.god_mode=true
	freeze_enemies()
	await shot("village")
	for pos in [Vector3(9,0,2),Vector3(17,0,-2),Vector3(25,0,-7),Vector3(31,0,-12),Vector3(37,0,-22),Vector3(48,0,-25),Vector3(60,0,-25)]:
		check(await walk_to(pos),"Baseline road traversal toward generated chunks")
	await shot("hub-transition")
	for biome in ValeGenerator.BIOMES:
		for data in game.generator.layout.values():
			if data.biome!=biome or game.generator.HUB.grow(10).has_point(data.center): continue
			await teleport(Vector3(data.center.x,0,data.center.y+5))
			freeze_enemies()
			await shot(biome.to_lower().replace(" ","-"))
			game.rig.target_yaw+=PI/2
			await frames(25)
			await shot(biome.to_lower().replace(" ","-")+"-orbit")
			break
	await teleport(Vector3(120,0,112))
	freeze_enemies()
	for i in 4:
		game.rig.target_yaw=i*PI/2
		await frames(30)
		await shot("edge-%d" % i)
	print("AUDIT4_COMPLETE")
	await Feel.shutdown()
	get_tree().quit()
