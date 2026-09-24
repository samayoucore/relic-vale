extends "res://tests/ui_check.gd"
var metrics: Array=[]
func capture6(name: String) -> void:
	await frames(10)
	if DisplayServer.get_name()!="headless":
		# Offscreen QA remains available when the desktop window is covered/minimized.
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase6-"+name+".png")
	metrics.append({"scene":name,"fps":Engine.get_frames_per_second(),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})

func run() -> void:
	game=get_tree().current_scene; await frames(40)
	game.player.god_mode=true; game.active_save_path="user://phase6-test.json"
	game.life.set_time(10); State.life_data.weather="Clear"; State.life_data.weather_block=int(State.life_data.day)*8+3
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"): enemy.set_physics_process(false)
	var buildings: Dictionary=State.life_data.settlements["%d/willowmere" % State.world_seed].buildings
	check(buildings.size()==5,"Five authored buildings have stable interior records")
	await capture6("village")
	var start: Dictionary=game.generator.address(game.player.position)
	for type in ["house","tavern","blacksmith","alchemist","shop"]:
		var building: Dictionary={}
		for record in buildings.values():
			if record.template==type: building=record
		game.player.global_position=game.generator.position_of(building.door)+Vector3(0,0,.65)
		var return_address: Dictionary=game.generator.address(game.player.position)
		if type=="tavern": game.life.set_time(19)
		else: game.life.set_time(10)
		await game.interiors.enter(building)
		await frames(150)
		check(game.player.position.x>2990 and game.player.is_on_floor(),type+" enters with physical ground")
		check(game.interiors.room!=null and game.generator.process_mode==Node.PROCESS_MODE_DISABLED,type+" loads one room and suspends outdoors")
		await capture6(type)
		if type=="tavern": check(game.interiors.occupants.size()>=4,"Evening tavern contains persistent village patrons")
		if type=="blacksmith":
			var bram: ValeInteractable=null
			for npc in game.interiors.occupants.values():
				if npc.npc_id=="smith": bram=npc
			check(bram!=null,"Bram works inside his forge")
			State.coins=100
			check(ValeLife.trade("smith","iron_axe") and State.inventory.has("iron_axe"),"Buy an iron axe from the blacksmith")
			game.hud.ui.selected="iron_axe"; game.hud.show_inventory(); await frames(6)
			if DisplayServer.get_name()=="headless": State.equip("iron_axe")
			else: await press("Equip to Tool")
			check(State.equipment.Tool=="iron_axe","Inventory equips the tool slot (pointer in GUI runs)")
			await capture6("tool-inventory"); game.hud.close_modal()
		await game.interiors.leave(); await frames(5)
		check(game.generator.position_of(return_address).distance_to(game.player.position)<.4,type+" returns to the exact exterior address")
	check(game.interiors.room==null,"Leaving releases the interior instance")
	game.generator.teleport_logical(0,0,Vector3(30,0,4)); await frames(10)
	var samples: Array=[]
	for pair in [["wood","tree_oak",4.3,true],["stone","rock_largeA",1.2,false],["iron_ore","rock_largeB",1.4,false],["wild_herb","plant_bushSmall",.65,false],["fiber","grass",.55,false]]:
		var position: Vector3=game.player.position+Vector3(1.5,0,0)
		var node:=ValeResource.spawn(game.world,game.world,"%d/resource/0,0/test_%s" % [State.world_seed,pair[0]],pair[0],position,game.world.NATURE+pair[1]+".glb",pair[2],0,pair[3]); samples.append(node)
		var before: int=int(State.inventory.get(pair[0],0))
		if pair[0]=="stone":
			check(not game.player.gathering.start(node),"Axe cannot mine stone")
			State.equip("crude_pickaxe")
		await frames(3)
		check(game.player.gathering.start(node),"Begin physical harvest of "+pair[0])
		await frames(12)
		check(int(State.inventory.get(pair[0],0))==before,"No materials before timed impact: "+pair[0])
		await capture6("harvest-"+pair[0])
		await frames(45)
		for i in 8:
			if node.remaining()<=0: break
			game.player.gathering.start(node); await frames(58)
		check(node.remaining()==0 and not node.model.visible,"Physical depletion of "+pair[0])
		check(int(State.inventory.get(pair[0],0))>before,"Inventory receives harvested "+pair[0])
		await frames(10); game.rig.update_obstructions()
		check(not node.model.visible,"Camera restoration does not resurrect depleted "+pair[0])
		node.position+=Vector3(0,0,3)
	check(ValeLife.item_price("smith","iron_ore",true)>ValeLife.item_price("merchant","iron_ore",true),"Smith pays more for ore than general merchant")
	check(ValeLife.item_price("willow_carpenter","wood",true)>ValeLife.item_price("merchant","wood",true),"Carpenter pays more for wood")
	check(ValeLife.item_price("willow_alchemist","wild_herb",true)>ValeLife.item_price("merchant","wild_herb",true),"Alchemist pays more for herbs")
	var copper: int=State.coins; check(ValeLife.trade("smith","iron_ore",true) and State.coins>copper,"Gathered ore sells for copper")
	var resource_state: Dictionary=State.resource_states.duplicate(true)
	check(game.save_game(false),"Save v6 with harvest state")
	var data: Dictionary=ValeSave.read(game.active_save_path)
	var matches: bool=not data.is_empty() and data.resource_states.size()==resource_state.size()
	for id in resource_state:
		for field in ["hits","respawn_day"]: matches=matches and int(data.resource_states.get(id,{}).get(field,-1))==int(resource_state[id][field])
	check(matches,"Hash-backed resource changes round trip")
	check(data.residents.size()>=7 and data.equipment.Tool==State.equipment.Tool,"Resident identities and equipped tool persist")
	var tree: ValeResource=samples[0]
	State.life_data.day+=4; tree.synchronize()
	check(tree.remaining()==tree.max_hits and tree.model.visible,"Renewable timber regrows after configured days")
	game.generator.teleport_logical(0,0,Vector3(20,0,10)); await frames(50)
	var farms: Array=get_tree().get_nodes_in_group("fauna").filter(func(a): return a.farm)
	check(farms.size()>=3,"Village pasture contains imported farm animals")
	for animal in farms: check(animal.visual.clips.has("walk"),animal.species+" uses an authored locomotion clip")
	await capture6("pasture")
	var cow: ValeFauna=farms[0]; cow.flee(); await frames(3); check(cow.state=="Fleeing","Non-hostile fauna reacts by fleeing")
	game.player.position+=Vector3(0,0,12); game.life.set_time(23); await frames(400)
	check(cow.state in ["Sleeping","Returning home"],"Farm animals return home at night")
	game.life.set_time(10)
	var smith_record: Dictionary=buildings.values().filter(func(b): return b.template=="blacksmith")[0]
	game.player.position=game.generator.position_of(smith_record.door)+Vector3(0,0,.6)
	await game.interiors.enter(smith_record); await frames(20)
	State.add_item("wood",2); State.interior_data.storage={smith_record.id+"/storage":{"wood":2}}
	check(game.save_game(false,"user://phase6-interior.json"),"Save while inside an interior")
	var file:=FileAccess.open("res://docs/PHASE_6_"+("HEADLESS" if DisplayServer.get_name()=="headless" else "GUI")+"_METRICS.json",FileAccess.WRITE); file.store_string(JSON.stringify(metrics,"\t")); file.close()
	print("PHASE6_CORE_RESULT ",checks.size()," passed / ",failures.size()," failed")
	await Feel.shutdown(); get_tree().quit(0 if failures.is_empty() else 1)
