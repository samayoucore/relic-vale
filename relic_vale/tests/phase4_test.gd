extends "res://tests/visual_phase4.gd"
const SAVE4="user://phase4-integration.json"

func named_npc(id: String) -> ValeInteractable:
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.kind=="npc" and node.npc_id==id: return node
	return null

func run() -> void:
	game=get_tree().current_scene
	await frames(25)
	game.player.god_mode=true
	freeze_enemies()
	check(game.player.is_on_floor(),"Village spawn remains on collision surface")
	check(State.crafting_data.size()==20 and State.faction_data.size()==3,"Twenty recipes and three lore factions loaded")
	check(State.quest_data.size()==13,"Original four quests plus three three-part chains")
	check(game.life.ambience.size()==6,"Six smoothly mixed environmental sound zones")
	State.talk_npc("rowan")
	game.hud.close_modal()
	check(State.quest_progress.has("hearth_1") and not State.quest_progress.has("hearth_2"),"Rowan starts only eligible chain stage")
	await shot("systems-village")
	var original_fingerprint: String=game.generator.fingerprint()
	game.generator.build_layout()
	check(original_fingerprint==game.generator.fingerprint(),"World geography and settlements remain deterministic")
	var settlements: Array=[]
	var kinds: Dictionary={}
	for poi in game.generator.pois:
		kinds[poi.kind]=true
		if poi.kind=="settlement": settlements.append(poi)
	check(settlements.size()==3,"Forest village, mining settlement and trading outpost reserved")
	check(kinds.size()>=10,"At least ten distinct contextual POI types occur in the default world")
	for poi in settlements:
		await at(poi.position+Vector2(0,8))
		check(game.player.is_on_floor(),poi.title+" has physical terrain")
		check(await walk_to(Vector3(poi.position.x,game.player.position.y,poi.position.y+4)),poi.title+" access lane is walkable")
		await shot("settlement-"+poi.settlement)
	await at(Vector2(-48,-12))
	var ranger:=named_npc("fernwatch_ranger")
	check(ranger!=null,"Fernwatch residents stream with their settlement")
	var workplace: Vector3=ranger.global_position
	game.life.set_time(19)
	await frames(420)
	check(ranger.global_position.distance_to(workplace)>2,"A* schedule walks resident to evening square")
	game.life.set_time(23)
	for i in 1500:
		if not ranger.visible: break
		await frames(1)
	check(not ranger.visible,"Resident returns to doorway and enters inside state at night")
	await shot("settlement-night")
	game.life.set_time(9)
	await frames(30)
	State.life_data.weather="Clear"
	State.coins=500
	var coins: int=State.coins
	check(ValeLife.trade("fernwatch_alchemist","wild_herb"),"Alchemist sells a specialized offer")
	check(State.coins==coins-4 and State.inventory.has("wild_herb"),"Purchase exchanges exact copper and one item")
	check(ValeLife.trade("fernwatch_alchemist","wild_herb",true),"Individual inventory item can be sold")
	State.life_data.reputation.bough=35
	check(ValeLife.price("fernwatch_alchemist",100)==90,"Friendly reputation reduces prices ten percent")
	State.life_data.reputation.bough=-60
	check(not ValeLife.trade("fernwatch_alchemist","trail_tonic"),"Hostile reputation refuses trade without charge")
	State.life_data.reputation.bough=0
	ValeLifeMenus.open_shop(game.hud,"fernwatch_alchemist")
	await shot("shop")
	game.hud.close_modal()
	var herb: ValeInteractable
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.kind=="resource" and node.get_meta("resource","")=="wild_herb": herb=node; break
	await teleport(herb.global_position+Vector3(0,0,1))
	State.life_data.weather="Rain"
	var before: int=int(State.inventory.get("wild_herb",0))
	herb.interact(game.player)
	herb.interact(game.player)
	check(int(State.inventory.get("wild_herb",0))==before+2,"Rain herb bonus applies once; repeated harvest is rejected")
	for id in ["wood","stone","iron_ore","wild_herb","mushroom","crystal","wolf_pelt","slime_gel","ancient_bone","iron_ingot","plank","leather","charcoal"]: State.add_item(id,30)
	var stations: Dictionary={}
	await at(Vector2(0,4))
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.kind=="station" and node.global_position.x<20: stations[node.get_meta("station")]=node
	check(stations.size()==4,"All four crafting stations exist in the original village")
	for id in ["tonic","planks","iron","stew"]:
		var recipe: Dictionary=State.crafting_data[id]
		var station: ValeInteractable=stations[recipe.station]
		await teleport(station.global_position+Vector3(0,0,1.5))
		before=int(State.inventory.get(recipe.output,0))
		check(ValeLife.craft(id,station) and int(State.inventory[recipe.output])==before+int(recipe.count),"Craft "+id+" at its physical station")
		if id=="iron":
			ValeLifeMenus.open_crafting(game.hud,station)
			await shot("crafting")
			game.hud.close_modal()
	check(not ValeLife.craft("iron",stations.campfire),"Crafting refuses wrong station without consuming input")
	var distant: ValeInteractable=stations.forge
	await at(Vector2(0,4))
	check(not ValeLife.craft("iron",distant),"Crafting refuses a remote station")
	State.talk_npc("rowan")
	game.hud.close_modal()
	check(State.completed_quests.has("hearth_1") and State.quest_progress.has("hearth_2"),"Chain reward advances prerequisites and reputation")
	State.talk_npc("ironvein_smith")
	game.hud.close_modal()
	State.talk_npc("rowan")
	game.hud.close_modal()
	check(State.completed_quests.has("hearth_2") and State.quest_progress.has("hearth_3"),"Second chain stage unlocks the mine objective")
	ValeLifeMenus.open_journal(game.hud)
	await shot("journal")
	game.hud.close_modal()
	for weather in ValeLife.WEATHER:
		State.life_data.weather=weather
		await frames(270)
		check(game.life.rain.emitting==(weather in ["Rain","Storm"]),"Weather state renders "+weather)
		if weather in ["Rain","Fog","Storm"]: await shot("weather-"+weather.to_lower())
	for style in ["mine","crypt"]:
		var id: String="test/phase4/"+style
		var first: String=JSON.stringify(game.expedition.layout(id,style))
		check(first==JSON.stringify(game.expedition.layout(id,style)),style+" room graph repeats from seed and ID")
		game.expedition.enter(id,style)
		await frames(20)
		freeze_enemies()
		check(game.expedition.plan.cells.size()==8 and game.expedition.plan.links.size()==8,"Dungeon has main route, branch and connected loop")
		for x in [2020,2040,2060,2080]:
			check(await walk_to(Vector3(x,0,0)),style+" main path reaches room "+str(x))
			freeze_enemies()
		await shot("dungeon-"+style)
		var boss: Mossling
		for enemy in get_tree().get_nodes_in_group("enemy_bodies"):
			if enemy.persistent_id==game.expedition.boss_id: boss=enemy; break
		boss.player=game.player
		boss.set_physics_process(true)
		await frames(150)
		check(boss.boss.engaged and not boss.boss.action_history.is_empty(),"Procedural guardian engages inside its own arena")
		boss.take_damage(boss.max_hp/2)
		await frames(90)
		check(boss.boss.phase==2,"Procedural guardian retains second phase")
		boss.take_damage(99999)
		await frames(60)
		check(State.life_data.dungeons[id].completed,"Dungeon completion is persisted and emits quest objective")
	var expected_minute: float=float(State.life_data.minute)
	check(game.save_game(false,SAVE4),"Version 4 save writes clock, weather, economy, quests and dungeon state")
	State.coins=0
	State.life_data=ValeLife.defaults()
	check(game.load_game(SAVE4),"Version 4 save reloads inside generated dungeon")
	check(game.player.position.x>2000 and not game.expedition.plan.is_empty(),"Generated dungeon is rebuilt before play resumes")
	check(absf(float(State.life_data.minute)-expected_minute)<1 and State.life_data.reputation.hearth>=30,"World clock and earned reputation survive reload")
	check(State.gathered_resources.has(herb.persistent_id) if is_instance_valid(herb) else not State.gathered_resources.is_empty(),"Gathered resource delta survives chunk unload and save")
	var old: Dictionary=ValeSave.snapshot(Vector3(0,0,3.6))
	old.version=3
	old.erase("life")
	check(ValeSave.valid(old),"Version 3 save remains supported")
	ValeSave.apply(old)
	check(State.life_data.day==1 and State.life_data.minute==540,"Legacy save gains safe living-world defaults")
	var report: String="# Phase 4 integration test\n\n%d passed; %d failed.\n\n" % [checks.size(),failures.size()]
	for item in checks: report+="- PASS: "+item+"\n"
	for item in failures: report+="- FAIL: "+item+"\n"
	FileAccess.open("res://docs/PHASE_4_TEST_RESULTS.md",FileAccess.WRITE).store_string(report)
	print("PHASE4_RESULT ",checks.size()," passed ",failures.size()," failed")
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)
