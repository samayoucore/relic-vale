extends "res://tests/phase6_test.gd"
func run() -> void:
	game=get_tree().current_scene; await frames(35)
	check(game.load_game("user://phase6-acceptance.json"),"Step 28: Reload in a fresh Godot process")
	await frames(50)
	var expected: Dictionary=State.interior_data.get("acceptance",{})
	check(not expected.is_empty(),"Previous gameplay run saved its verification record")
	if not expected.is_empty():
		var inventory_matches: bool=State.inventory.size()==expected.inventory.size()
		for id in expected.inventory: inventory_matches=inventory_matches and int(State.inventory.get(id,-1))==int(expected.inventory[id])
		check(inventory_matches and State.equipment==expected.equipment and State.coins==int(expected.coins),"Step 29: Inventory, equipped tool and sale proceeds survive restarting")
		var depleted: bool=true
		for id in expected.harvested: depleted=depleted and int(State.resource_states.get(id,{}).get("hits",-1))==0
		check(depleted,"Step 29: All physically harvested nodes remain depleted")
		var same_people: bool=true
		for id in expected.identity: same_people=same_people and State.residents.get(id,{})==expected.identity[id]
		check(same_people and State.residents.size()>=int(expected.residents),"Step 29: Persistent resident identities, homes and workplaces survive restarting")
		check(int(State.life_data.minute)/60==int(expected.hour) and game.world.hub_root.is_inside_tree() and game.player.is_on_floor(),"Step 29: Time, world destination and physical ground restored")
	var base: String=FileAccess.get_file_as_string("res://docs/PHASE_6_ACCEPTANCE.md").split("\n28.")[0]
	var report:=FileAccess.open("res://docs/PHASE_6_ACCEPTANCE.md",FileAccess.WRITE)
	if report:
		report.store_string(base+"\n28. Reload in a fresh process — %s\n\n29. Verify inventory, equipment, money, resources, residents and world — %s\n\nFresh-process checks: %d passed, %d failed.\n" % ["PASS" if checks.size()>0 else "FAIL","PASS" if failures.is_empty() else "FAIL",checks.size(),failures.size()]); report.close()
	await capture6("accept-reloaded")
	print("PHASE6_ACCEPTANCE_RELOAD_RESULT ",checks.size()," passed / ",failures.size()," failed")
	await Feel.shutdown(); get_tree().quit(0 if failures.is_empty() else 1)
