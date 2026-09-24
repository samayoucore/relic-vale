extends "res://tests/phase8_test.gd"

func finish() -> void:
	var file:=FileAccess.open("res://docs/PHASE_8_FINAL_CHECKS.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":results},"\t")); file.close()
	print("PHASE8_FINAL_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)

func run() -> void:
	game=get_tree().current_scene; await frames(12); game.player.god_mode=true
	check(game.load_game(SAVE),"Load final gameplay fixture"); game.active_save_path=ValeSave.PATH
	await frames(5); game.hud.close_modal(); game.life.set_process(false); State.activities.food={}
	var basic: Dictionary=State.items.bait_basic.bait
	var previous: float=2
	for rarity in ["Common","Uncommon","Rare","Epic","Legendary"]:
		for id in ValeProfessions.fish:
			if ValeProfessions.fish[id].rarity!=rarity: continue
			var weight: float=game.fishing.catch_weight(id,basic)
			check(weight<previous,rarity+" has a lower base weight than the preceding grade")
			previous=weight; break
	var insect: Dictionary=basic.duplicate(true); insect.target_water="river"
	check(game.fishing.catch_weight("fish_golden_dace",insect)>game.fishing.catch_weight("fish_golden_dace",basic),"Insect bait targets river fish as a distinct group")
	check(game.fishing.catch_weight("fish_pond_carp",insect)==game.fishing.catch_weight("fish_pond_carp",basic),"River preference does not boost lake fish")
	check(game.fishing.catch_weight("fish_moon_koi",State.items.bait_rare.bait)>game.fishing.catch_weight("fish_moon_koi",basic),"Moon bait improves rare odds")
	ValeProfessions.set_level("fishing",25); State.life_data.minute=360; State.life_data.weather="Clear"
	check("fish_dawn_mandarin" in game.fishing.eligible("river"),"Legendary river fish is available at clear dawn")
	State.life_data.weather="Rain"
	check(not "fish_dawn_mandarin" in game.fishing.eligible("river"),"Weather restriction remains active independently of bait")
	var address: Dictionary=State.camp_data.address
	game.generator.teleport_logical(int(address.x),int(address.z)); game.player.position=game.generator.position_of(address)+Vector3(0,.1,5)
	State.camp_data.level=5; State.camp_data.tier=5; game.camp.sync_visual(true); await frames(35)
	var station: ValeInteractable
	for node in game.cultivation.farm_root.get_children():
		if node is ValeInteractable and node.get_meta("station","")=="campfire": station=node
	check(is_instance_valid(station),"Camp has a reachable cooking station")
	if is_instance_valid(station):
		for id in ValeProfessions.fish: State.inventory.erase(id)
		State.add_item("fish_golden_dace"); game.player.position=station.global_position+Vector3(0,.1,1)
		var before: int=int(State.inventory.get("meal_grilled_fish",0))
		check(ValeLife.craft("cook_grilled_fish",station),"Grill a non-minnow species at the actual station")
		check(not State.inventory.has("fish_golden_dace") and int(State.inventory.get("meal_grilled_fish",0))==before+1,"Generic fish recipe consumes the displayed fish and creates one meal")
	await game.interiors.enter(State.camp_data.buildings["0"]); await frames(8)
	game.player.position=game.interiors.room.position+Vector3(0,.1,-2.5); game.rig.zoom=17; game.rig.target_zoom=17; game.rig.snap()
	await shot("home-kitchen-final")
	check(ValeSave.valid(ValeSave.snapshot(game.player.position)),"Final interior/activity snapshot is valid")
	await finish()
