extends "res://tests/ui_check.gd"
var largest: int=0
var traversed: Dictionary={}
var travelled: float=0

func save_path() -> String: return "user://phase5-final.json"
func walk_address(destination: Dictionary) -> bool:
	var previous: Vector3=game.player.position
	for i in 4500:
		var pos: Vector3=game.generator.position_of(destination)
		var difference: Vector3=pos-game.player.position; difference.y=0
		if difference.length()<.65:
			for action in ["move_up","move_down","move_left","move_right","sprint"]: Input.action_release(action)
			return true
		var direction: Vector3=difference.normalized().rotated(Vector3.UP,-game.rig.yaw)
		Input.action_press("move_right",maxf(0,direction.x)); Input.action_press("move_left",maxf(0,-direction.x))
		Input.action_press("move_down",maxf(0,direction.z)); Input.action_press("move_up",maxf(0,-direction.z)); Input.action_press("sprint")
		var before: Dictionary=game.generator.address(game.player.position)
		await frames(1)
		var distance: float=game.player.position.distance_to(game.generator.position_of(before))
		travelled+=distance
		var key: String=game.generator.chunk_key(game.generator.coord_at(game.player.position)); traversed[key]=true
		largest=maxi(largest,game.generator.active_chunks.size())
		if game.player.position.y< -5: return false
		if i%420==0: game.rig.target_yaw+=.3
		if i%1000==0: print("WALK5 ",key," · ",roundi(travelled),"m · ",game.generator.active_chunks.size()," chunks")
	for action in ["move_up","move_down","move_left","move_right","sprint"]: Input.action_release(action)
	return false

func run() -> void:
	game=get_tree().current_scene; await frames(30)
	game.player.god_mode=true
	Preferences.set_preset("Medium"); Preferences.set_option("pixelated",false)
	game.generator.teleport_logical(1000,-500)
	var planner: ValeRegionPlan=game.generator.planner("1000,-500")
	var rx: int=ValeRegionPlan.divide(1004,8); var rz: int=ValeRegionPlan.divide(-496,8)
	var plan: Dictionary=planner.region(rx,rz)
	var start: Vector2=plan.roads[1][1]
	game.player.position=Vector3(start.x,game.generator.landscape.height(start)+.15,start.y); game.rig.snap()
	game.generator.update_streaming(true)
	# Follow two adjoining regional arterial roads with ordinary controller movement.
	var portal: Vector2=plan.roads[1][0]
	var next: Dictionary=planner.region(rx+1,rz)
	var finish: Vector2=next.roads[0][1]
	var addresses: Array=[game.generator.address(Vector3(portal.x,0,portal.y)),game.generator.address(Vector3(finish.x,0,finish.y))]
	await frames(5)
	for destination in addresses: check(await walk_address(destination),"Walk along an uninterrupted regional road to "+str(destination))
	check(traversed.size()>=8,"Continuous physics travel crosses at least eight chunks")
	check(game.generator.shifts>=1,"Continuous travel shifts origin without stopping movement")
	check(largest<=49,"Continuous travel keeps scene chunks bounded")
	check(game.player.is_on_floor(),"Streamed road has physical ground at the destination")
	await shot("phase5-road-walk")
	game.expedition.enter("phase5/far/crypt","crypt"); await frames(8)
	check(game.player.position.x>1900,"Generated dungeon can be entered far from origin")
	var exit_node: ValeInteractable=null
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.kind=="exit" and node.global_position.x>1900: exit_node=node; break
	if exit_node:
		exit_node.interact(game.player); await frames(12)
	check(game.player.position.x<900 and abs(game.generator.origin_x)>100,"Dungeon exit preserves the far logical world")
	var before: Dictionary=game.generator.address(game.player.position)
	for i in 5:
		State.opened_chests["0/poi/test/"+str(i)]=true
		check(game.save_game(false,save_path()),"Atomic delta save "+str(i))
	var count: int=DirAccess.get_files_at(save_path()+".chunks").size()
	var current: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(save_path()))
	var backup: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(save_path()+".bak"))
	check(count<=current.chunk_manifest.size()+backup.chunk_manifest.size(),"Delta garbage collection retains only current and backup records")
	check(game.load_game(save_path()),"Far saved journey reloads through the main game flow")
	check(game.generator.address(game.player.position)==before,"Save/load returns to the same far logical position")
	var malformed: Dictionary=ValeSave.snapshot(game.player.position); malformed.world={"origin_x":[],"discovered":{}}
	check(not ValeSave.valid(malformed),"Malformed logical origin is rejected")
	check(not ValeChunkDeltas.valid_map({"roads":[[1,2]]}),"Malformed map records are rejected")
	Preferences.set_option("shadows",0,true); check(Preferences.values.preset=="Custom","Manual advanced setting selects Custom")
	Preferences.set_preset("Medium")
	game.generator.teleport_logical(0,0,Vector3(0,0,4)); game.life.set_time(18)
	game.gameplay_started=false; game.hud.ui.main_menu(); await frames(5)
	check(not game.save_game(false),"Title screen cannot overwrite a journey")
	game.hud.ui.settings_page(); game.hud.close_modal(); check(game.hud.modal_kind=="main_menu","Closing title-screen settings returns to main menu")
	game.gameplay_started=true; game.hud.close_modal()
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]:
		Preferences.set_option("resolution",resolution); game.hud.show_inventory(); await frames(12)
		check(game.hud.modal_panel.get_global_rect().end.x<=get_viewport().get_visible_rect().size.x+2,"Responsive UI at requested "+str(resolution))
		print("RESOLUTION5 requested=",resolution," actual=",DisplayServer.window_get_size()," image=",get_viewport().get_texture().get_image().get_size())
		await shot("phase5-resolution-"+str(resolution.x)); game.hud.close_modal()
	Preferences.set_option("resolution",Vector2i(1280,720))
	var report: String="# Phase 5 final integration\n\n%d passed, %d failed.\n\nContinuous controller travel: %.1f m, %d discovered chunks, maximum %d active chunks.\n" % [checks.size(),failures.size(),travelled,traversed.size(),largest]
	var file:=FileAccess.open("res://docs/PHASE_5_FINAL_TEST.md",FileAccess.WRITE); file.store_string(report); file.close()
	print("FINAL5_RESULT ",checks.size()," passed ",failures.size()," failed")
	await Feel.shutdown(); get_tree().quit(0 if failures.is_empty() else 1)
