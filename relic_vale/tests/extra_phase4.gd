extends "res://tests/ui_check.gd"

func talk(id: String) -> void:
	State.talk_npc(id)
	game.hud.close_modal()

func run() -> void:
	game=get_tree().current_scene
	await frames(25)
	game.player.god_mode=true
	if "--phase4-startup" in OS.get_cmdline_user_args():
		check(game.player.position.x>2000 and game.player.is_on_floor(),"Fresh process restores a generated dungeon before physics")
		check(not game.expedition.plan.is_empty(),"Fresh process reconstructs saved seeded rooms")
		game.new_world(9283412)
		await frames(30)
		check(game.expedition.active_id.is_empty() and not is_instance_valid(game.expedition.content),"New world clears the previous expedition")
	else:
		for enemy in get_tree().get_nodes_in_group("enemy_bodies"): enemy.set_physics_process(false)
		State.coins=3000
		for id in ["wood","stone","iron_ore","wild_herb","mushroom","crystal","wolf_pelt","slime_gel","ancient_bone","iron_ingot","plank","leather","charcoal"]: State.add_item(id,100)
		for faction in ["hearth","bough","veil"]:
			var npc: String={"hearth":"rowan","bough":"fernwatch_ranger","veil":"keeper"}[faction]
			talk(npc)
			talk(npc)
			check(State.completed_quests.has(faction+"_1"),faction+" first reward claims from collected resources")
			if faction=="hearth": talk("ironvein_smith")
			if faction=="bough":
				for i in 3:
					var wolf: Mossling=load("res://scenes/characters/Enemy.tscn").instantiate()
					wolf.set_meta("archetype","wolf")
					wolf.position=Vector3(20+i,0,10)
					game.world.add_child(wolf)
					wolf.take_damage(99999)
			talk(npc)
			check(State.completed_quests.has(faction+"_2"),faction+" second reward unlocks final objective")
			if faction=="bough":
				for poi in game.generator.pois:
					if poi.kind=="grove":
						game.player.position=Vector3(poi.position.x,game.generator.landscape.height(poi.position)+.1,poi.position.y)
						game.generator.update_streaming(true)
						await frames(60)
						break
			else:
				game.expedition.enter("extra/"+faction,"mine" if faction=="hearth" else "crypt")
				await frames(10)
				for enemy in get_tree().get_nodes_in_group("enemy_bodies"):
					if enemy.persistent_id==game.expedition.boss_id: enemy.take_damage(99999)
			talk(npc)
			check(State.completed_quests.has(faction+"_3") and State.life_data.unlocks.has(faction+"_3"),faction+" final reward grants its crafting pattern")
			var copper: int=State.coins
			talk(npc)
			check(State.coins==copper,"Repeated "+faction+" report cannot duplicate rewards")
		game.player.position=Vector3(0,0,4)
		game.generator.update_streaming(true)
		await frames(30)
		var stations: Dictionary={}
		for node in get_tree().get_nodes_in_group("interactables"):
			if node.kind=="station" and node.global_position.x<20: stations[node.get_meta("station")]=node
		for id in State.crafting_data:
			var recipe: Dictionary=State.crafting_data[id]
			var station: ValeInteractable=stations[recipe.station]
			game.player.position=station.global_position+Vector3(0,.1,1)
			var count: int=int(State.inventory.get(recipe.output,0))
			check(ValeLife.craft(id,station) and int(State.inventory[recipe.output])==count+int(recipe.count),"Recipe "+id+" transacts after earned pattern unlocks")
		ValeLifeMenus.open_crafting(game.hud,stations.alchemy)
		game.player.position=stations.alchemy.global_position+Vector3(0,.1,1)
		ValeLifeMenus.open_crafting(game.hud,stations.alchemy)
		await frames(15)
		var tonic: int=State.inventory.trail_tonic
		await press("Craft")
		check(State.inventory.trail_tonic==tonic+2,"Crafting button accepts real mouse input and produces two tonics")
		game.hud.close_modal()
		ValeLifeMenus.open_shop(game.hud,"fernwatch_alchemist")
		await frames(15)
		var copper: int=State.coins
		await press("Buy")
		check(State.coins<copper,"Merchant Buy button accepts real mouse input")
		game.hud.close_modal()
		game.hud.show_map()
		await shot("phase4-atlas")
		game.hud.close_modal()
	var report: String="# Phase 4 additional integration\n\n%d passed; %d failed.\n\n" % [checks.size(),failures.size()]
	for item in checks: report+="- PASS: "+item+"\n"
	for item in failures: report+="- FAIL: "+item+"\n"
	FileAccess.open("res://docs/PHASE_4_"+("STARTUP" if "--phase4-startup" in OS.get_cmdline_user_args() else "EXTRA")+".md",FileAccess.WRITE).store_string(report)
	print("EXTRA4_RESULT ",checks.size()," passed ",failures.size()," failed")
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)
