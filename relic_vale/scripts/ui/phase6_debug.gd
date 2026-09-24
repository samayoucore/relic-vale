class_name ValePhase6Debug
extends RefCounted
static func show(ui: ValeInterface) -> void:
	var game: Node=ui.get_tree().current_scene
	ui.page("phase6_debug","Village simulation","DEVELOPMENT / F4")
	var columns:=ui.row(ui.body); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var resources:=ui.scroll(columns); var homes:=ui.scroll(columns); var people:=ui.scroll(columns)
	ui.text(resources,"GATHERING","Heading")
	for tier in ["crude","iron","steel"]:
		ui.button(resources,"Give "+tier+" tools",func(): State.add_item(tier+"_axe"); State.add_item(tier+"_pickaxe"))
	for id in ["wood","stone"]: ui.button(resources,"Add 100 "+id,func(): State.add_item(id,100))
	ui.button(resources,"+20 materials / 200 copper",func():
		for id in State.resource_data: State.add_item(id,20)
		State.coins+=200; State.changed.emit())
	ui.button(resources,"Clear material stacks",func():
		for id in State.resource_data: State.inventory.erase(id)
		State.changed.emit())
	for item in ["wood","stone","iron_ore","wild_herb"]:
		ui.button(resources,"Spawn "+item,func():
			var assets: Dictionary={"wood":"tree_oak","stone":"rock_largeA","iron_ore":"rock_largeB","wild_herb":"plant_bushSmall"}
			ValeResource.spawn(game.world,game.world,"debug/resource/"+str(Time.get_ticks_msec()),item,game.player.position+game.player.facing*1.8,game.world.NATURE+assets[item]+".glb",4.5 if item=="wood" else 1,0,item=="wood"); game.hud.close_modal())
	ui.button(resources,"Regrow loaded resources",func():
		for node in ui.get_tree().get_nodes_in_group("interactables"):
			if node is ValeResource: State.resource_states.erase(node.persistent_id); State.gathered_resources.erase(node.persistent_id); node.synchronize()
		State.save_requested.emit())
	ui.text(homes,"INTERIORS","Heading")
	ui.text(homes,"Active: "+game.interiors.active.get("id","outside"),"Muted",true)
	ui.button(homes,"Leave interior",func(): game.hud.close_modal(); game.interiors.leave(),game.interiors.active.is_empty())
	ui.button(homes,"Reload current room",func():
		var active: Dictionary=game.interiors.active.duplicate(true); game.hud.close_modal(); game.interiors.enter(active,true),game.interiors.active.is_empty())
	for settlement in State.life_data.settlements.values():
		for building in settlement.get("buildings",{}).values():
			ui.button(homes,building.title,func():
				if not game.interiors.active.is_empty(): await game.interiors.leave()
				var address: Dictionary=building.door
				game.generator.teleport_logical(int(address.x),int(address.z),ValeSave.vector(address.local)+Vector3(0,0,.8))
				game.hud.close_modal(); game.interiors.enter(building))
	ui.text(people,"CLOCK / RESIDENTS","Heading")
	for hour in [6,9,12,18,23]: ui.button(people,"Set %02d:00" % hour,func(): game.life.set_time(hour); game.hud.close_modal())
	for node in ui.get_tree().get_nodes_in_group("interactables"):
		if node.kind!="npc": continue
		for controller in node.get_children():
			if not controller is ValeSchedule and not controller is ValeIndoorActivity: continue
			ui.text(people,node.title+" · "+controller.activity,"Muted",true)
			var record: Dictionary=State.residents.get(node.get_meta("resident",""),{})
			ui.text(people,"Home: "+record.get("home","")+"\nWork: "+record.get("work","")+"\nNow: "+(ValeResidents.destination(record) if not record.is_empty() else ""),"Muted",true)
			ui.text(people,"Next point: "+str(controller.route[0] if not controller.route.is_empty() else node.global_position),"Muted",true)
			ui.button(people,"Show "+node.title+" path",func():
				for point in controller.route: Feel.ring(game.world,point,.2,Color("f2cc8c"),8)
				game.hud.close_modal())
	ui.text(people,"FAUNA","Heading")
	for kind in ["deer","fox","cow","horse","alpaca"]:
		ui.button(people,"Spawn "+kind,func():
			var animal:=ValeFauna.new(); animal.gen=game.generator; animal.species=kind; animal.farm=kind in ["cow","horse","alpaca"]; animal.position=game.player.position+Vector3(3,0,1); game.world.add_child(animal); game.hud.close_modal())
	ui.button(people,"Flee nearby animals",func():
		for animal in ui.get_tree().get_nodes_in_group("fauna"):
			if animal.global_position.distance_to(game.player.position)<20: animal.flee()
		game.hud.close_modal())
	ui.button(people,"Clear loaded wildlife",func():
		for animal in ui.get_tree().get_nodes_in_group("fauna"): animal.queue_free())
	for animal in ui.get_tree().get_nodes_in_group("fauna"): ui.text(people,animal.species+" · "+animal.state+" · LOD "+animal.lod+" · "+animal.group_id,"Muted",true)
