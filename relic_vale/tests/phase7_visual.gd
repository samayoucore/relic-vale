extends "res://tests/phase7_extra.gd"
func finish() -> void:
	print("PHASE7_VISUAL_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)
func run() -> void:
	game=get_tree().current_scene; await frames(10); game.player.god_mode=true
	check(game.load_game(SAVE),"Load saved camp with final models")
	game.active_save_path=ValeSave.PATH
	await frames(10); game.camp.advance(4000); game.life.set_time(10)
	State.life_data.weather="Clear"; State.life_data.weather_block=int(State.life_data.day)*8+3
	game.rig.zoom=36; game.rig.target_zoom=36; game.rig.snap(); game.hud.close_modal()
	var camp: ValeCamp=game.camp
	var saved: Dictionary=State.camp_data.duplicate(true)
	camp.clear_visual(); State.camp_data={}; await frames(3)
	game.player.position=game.generator.position_of(saved.address)+Vector3(0,0,8)
	camp.begin_placement(); await frames(40)
	check(camp.placement_reason.is_empty(),"Placement preview validates the full expansion footprint")
	await shot("placement"); camp.cancel_placement(); State.camp_data=saved
	game.player.position=game.generator.position_of(saved.address)+Vector3(0,0,2); game.rig.snap()
	for tier in range(1,6):
		State.camp_data.level=tier; State.camp_data.tier=tier
		camp.sync_visual(true); await frames(35); await shot("camp-tier"+str(tier))
		check(is_instance_valid(camp.visual) and camp.visual.get_child_count()>10,"Tier %d contains physical camp structures" % tier)
	check(State.npc_data.camp_trader.get("shop",false),"Hamlet trader has a functional shop identity")
	await game.interiors.enter(State.camp_data.buildings["10"]); await frames(5)
	check(game.interiors.active.template=="blacksmith","Permanent camp workshop has a usable interior")
	await shot("workshop"); await game.interiors.leave(); await frames(8)
	game.hud.close_modal(); camp.candidate(); await frames(10)
	if not State.camp_data.candidate.is_empty():
		var npc: ValeInteractable=camp.actors[State.camp_data.candidate.id]
		game.player.position=npc.global_position+Vector3(0,0,.8); game.rig.snap()
		npc.interact(game.player); await frames(5); await shot("traveler")
		var count: int=State.camp_data.workers.size()
		await press("Welcome to camp")
		check(State.camp_data.workers.size()==count+1,"Nearby traveler can be recruited through UI")
	game.hud.ui.map_page(); await frames(150); await shot("atlas-final")
	game.hud.close_modal(); await finish()
