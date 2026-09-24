extends "res://tests/phase6_acceptance.gd"
func run() -> void:
	game=get_tree().current_scene; await frames(40); game.player.god_mode=true; set_hour(10)
	game.generator.teleport_logical(0,-1,Vector3(20,0,42)); await frames(20)
	for animal in get_tree().get_nodes_in_group("fauna"):
		if animal.farm: continue
		print("WILD ",animal.species," at ",animal.global_position," origin ",animal.origin," state ",animal.state," path ",walking_route(animal.global_position+Vector3(0,0,6)).size())
	check(await walk_to(game.world.hub_root.to_global(Vector3(28,0,18))),"Walk along the village road into the wilderness")
	for animal in get_tree().get_nodes_in_group("fauna"):
		if not animal.farm: print("WILD_AFTER ",animal.species," at ",animal.global_position," path ",walking_route(animal.global_position+Vector3(0,0,6)).size())
	await Feel.shutdown(); get_tree().quit()
