extends "res://tests/phase6_acceptance.gd"
func run() -> void:
	game=get_tree().current_scene; await frames(40); game.player.god_mode=true; set_hour(10)
	var buildings: Dictionary=State.life_data.settlements["%d/willowmere" % State.world_seed].buildings
	var forge: Dictionary=buildings.values().filter(func(b): return b.template=="blacksmith")[0]
	game.player.position=game.generator.position_of(forge.door)+Vector3(0,0,.65)
	await game.interiors.enter(forge); await game.interiors.leave(); await frames(10)
	for animal in get_tree().get_nodes_in_group("fauna"):
		if animal.farm: check(Vector2(animal.global_position.x,animal.global_position.z).distance_to(animal.origin)<4,"Farm home follows interior return / floating origin: "+animal.species)
	check(await walk_to(game.world.hub_root.to_global(Vector3(20,0,10))),"Physical route to pasture")
	check(get_tree().get_nodes_in_group("fauna").any(func(a): return a.farm and a.global_position.distance_to(game.player.position)<10),"Pasture animals remain nearby")
	await walk_to(game.generator.position_of(forge.door)+Vector3(0,0,.65)); set_hour(18)
	await frames(30)
	var smith: ValeInteractable
	var schedule: ValeSchedule
	for npc in game.world.hub_root.get_children():
		if npc is ValeInteractable and npc.npc_id=="smith": smith=npc
	for child in smith.get_children():
		if child is ValeSchedule: schedule=child
	var moved: float=0; var old: Vector3=smith.global_position
	for i in 2400:
		if not smith.visible: break
		if smith.global_position.distance_to(game.player.position)>2.8: move_toward_point(smith.global_position)
		else: stop_moving()
		await frames(1); moved+=old.distance_to(smith.global_position); old=smith.global_position
		if i%300==0: print("BRAM_ROUTE ",i," ",smith.position," player ",game.player.position," path ",schedule.route," activity ",schedule.activity)
	stop_moving(); check(moved>15 and not smith.visible,"Bram walks around the player into the tavern")
	print("PHASE6_LIFE_RESULT ",checks.size()," passed / ",failures.size()," failed")
	await Feel.shutdown(); get_tree().quit(0 if failures.is_empty() else 1)
