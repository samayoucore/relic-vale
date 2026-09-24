extends "res://tests/phase2_test.gd"
func shot(name: String) -> void:
	await frames(25)
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase4-"+name+".png")
	print("VISUAL4 ",name," ",game.player.position," fps=",Engine.get_frames_per_second()," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
func at(p: Vector2) -> void:
	await teleport(Vector3(p.x,game.generator.landscape.height(p)+.2,p.y))
	freeze_enemies()
func run() -> void:
	game=get_tree().current_scene
	await frames(90)
	game.player.god_mode=true
	freeze_enemies()
	await shot("village")
	await at(Vector2(-29,3))
	await shot("hub-transition")
	for biome in ValeGenerator.BIOMES:
		for data in game.generator.layout.values():
			if data.biome!=biome or game.generator.HUB.grow(10).has_point(data.center): continue
			await at(data.center+Vector2(0,5))
			await shot(biome.to_lower().replace(" ","-"))
			game.rig.target_yaw+=PI/2
			await frames(25)
			await shot(biome.to_lower().replace(" ","-")+"-orbit")
			break
	await at(Vector2(64,30))
	await shot("river")
	for poi in game.generator.pois:
		if poi.kind=="ruin":
			await at(poi.position+Vector2(0,5))
			await shot("ruined-tower")
			break
	for p in [Vector2(118,112),Vector2(-87,108),Vector2(-85,-84),Vector2(110,-84)]:
		await at(p)
		for i in 4:
			game.rig.target_yaw=i*PI/2
			await frames(25)
			await shot("edge-%d-%d-%d" % [int(p.x),int(p.y),i])
	await at(Vector2(24,-6))
	for i in 9:
		var enemy: Mossling=foe(["slime","wolf","skeleton","archer","witch","bat","mimic","elite","guardian"][i],Vector3(20+(i%3)*3,0,-8+(i/3)*3))
		check(enemy.visual.model.find_children("*","MeshInstance3D",true,false).size()>0,"Imported mesh "+enemy.archetype)
		check(enemy.visual.animator!=null and enemy.visual.clips.has("walk"),"Animated rig "+enemy.archetype)
	await shot("creatures")
	print("VISUAL4_COMPLETE ",failures)
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)
