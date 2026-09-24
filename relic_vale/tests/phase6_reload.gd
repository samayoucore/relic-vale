extends "res://tests/phase6_test.gd"
func run() -> void:
	game=get_tree().current_scene; await frames(30)
	check(game.load_game("user://phase6-interior.json"),"A fresh process loads the saved interior")
	await frames(90)
	check(game.player.position.x>2990 and game.player.is_on_floor(),"Reload creates the room before the player resumes")
	check(game.interiors.active.get("template","")=="blacksmith","Reload restores the same building template and identity")
	# The core run advances four days: timber and two plants have legitimately regrown.
	check(State.inventory.has("wood") and State.resource_states.values().any(func(r): return int(r.hits)==0),"Inventory and still-depleted records survive restarting")
	check(State.interior_data.get("storage",{}).size()==1,"Household storage survives restarting")
	var address: Dictionary=State.interior_data.active.return.duplicate(true)
	await game.interiors.leave(); await frames(5)
	check(game.player.position.distance_to(game.generator.position_of(address))<.5,"Reloaded interior exits to the saved world address")
	print("PHASE6_RELOAD_RESULT ",checks.size()," passed / ",failures.size()," failed")
	await Feel.shutdown(); get_tree().quit(0 if failures.is_empty() else 1)
