extends "res://tests/phase6_test.gd"
func run() -> void:
	game=get_tree().current_scene; await frames(35)
	game.player.god_mode=true; game.life.set_time(10); State.life_data.weather="Clear"
	game.life.set_process(false)
	game.life._process(0)
	game.player.position=Vector3(0,0,4); game.rig.target_zoom=12; game.rig.target_yaw=0; game.rig.yaw=0
	State.equip("crude_axe"); await frames(30)
	var node:=ValeResource.spawn(game.world,game.world,"debug/resource/visual","wood",game.player.position+Vector3(1.6,0,0),game.world.NATURE+"tree_oak.glb",4,0,true)
	var controller: ValeGathering=game.player.gathering
	game.player.facing=Vector3.RIGHT
	await capture6("tool-rest-close")
	controller.start(node); await frames(16); controller.set_process(false)
	print("TOOL_DIAGNOSTIC ",controller.global_transform," MODEL ",controller.tool_model.transform," VISIBLE ",controller.hand.is_visible_in_tree()," BOUNDS ",game.world.bounds(controller.tool_model))
	await capture6("tool-swing-close")
	controller.set_process(true); await frames(60)
	var buildings: Dictionary=State.life_data.settlements["%d/willowmere" % State.world_seed].buildings
	game.life.set_time(19)
	game.life._process(0)
	for building in buildings.values():
		if building.template=="tavern": await game.interiors.enter(building); break
	await frames(720)
	await capture6("tavern-polished")
	for npc in game.interiors.occupants.values():
		for child in npc.get_children():
			if child is ValeIndoorActivity: print("INDOOR ",npc.npc_id," ",child.activity," route ",child.route.size()," pos ",npc.position," goal ",child.spot)
	check(game.interiors.occupants.size()==7,"Seven residents occupy the evening tavern")
	await game.interiors.leave(); game.life.set_time(23); game.life._process(0)
	for building in buildings.values():
		if building.template=="house": await game.interiors.enter(building); break
	await frames(25); await capture6("house-sleeping")
	var sleepers: int=0
	for npc in game.interiors.occupants.values():
		for child in npc.get_children():
			if child is ValeIndoorActivity and child.activity=="Sleeping": sleepers+=1
	check(sleepers==3,"Three household residents use separate beds at night")
	await game.interiors.leave(); game.life.set_time(10); game.life._process(0)
	game.generator.teleport_logical(0,0,Vector3(20,0,14)); await frames(60)
	await capture6("pasture-final")
	var cow: ValeFauna=get_tree().get_nodes_in_group("fauna").filter(func(a): return a.species=="cow")[0]
	cow.timer=100; cow.state="Grazing"; cow.flee_timer=0
	await frames(3); var position: float=cow.visual.animator.current_animation_position
	await frames(20)
	check(absf(cow.visual.animator.current_animation_position-position)>.1,"Grazing clip advances rather than restarting every frame")
	await key(KEY_F4); await frames(5); check(game.hud.modal_kind=="phase6_debug","F4 opens village simulation controls"); await capture6("debug"); game.hud.close_modal()
	print("PHASE6_VISUAL_RESULT ",checks.size()," passed / ",failures.size()," failed")
	await Feel.shutdown(); get_tree().quit()
