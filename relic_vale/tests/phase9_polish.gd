extends "res://tests/phase9_stories.gd"

func finish() -> void:
	FileAccess.open("res://docs/PHASE_9_POLISH_TESTS.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":results},"\t"))
	print("PHASE9_POLISH_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)

func key(code: Key) -> void:
	var event:=InputEventKey.new(); event.physical_keycode=code; event.pressed=true; Input.parse_input_event(event)
	for frame in 3: await get_tree().process_frame
	var release: InputEventKey=event.duplicate(); release.pressed=false; Input.parse_input_event(release)
	for frame in 2: await get_tree().process_frame

func run() -> void:
	game=get_tree().current_scene; await frames(12)
	check(game.load_game(STORY_SAVE),"Graphical polish uses isolated completed story"); game.active_save_path=ValeSave.PATH
	game.player.god_mode=true; game.life.set_process(false); game.world_events.autonomous=false; game.hud.close_modal(); await frames(15)
	check(not game.narrative.condition({"type":"flag","id":"unwritten_story","value":"shelter"}),"An unset string-valued story flag is safely false")
	var snapshot: Dictionary=ValeSave.snapshot(game.player.position)
	snapshot.narrative.lore[&"oathbound"]=true
	check(ValeSave.valid(snapshot),"Interned Godot dictionary keys validate before JSON serialization")
	snapshot.quest_progress.act1_01=.5
	check(not ValeSave.valid(snapshot),"Fractional narrative quest stages are rejected")
	await camp(); game.rig.snap()
	await key(KEY_O); check(game.hud.modal_kind=="companions","O opens the company roster through real input"); game.hud.close_modal()
	await key(KEY_Z); check(game.hud.modal_kind=="party_commands","Z opens companion orders through real input"); game.hud.close_modal()
	var rig: ValeCamera=game.rig
	var button:=InputEventMouseButton.new(); button.button_index=MOUSE_BUTTON_RIGHT; button.pressed=true; Input.parse_input_event(button); await get_tree().process_frame
	var motion:=InputEventMouseMotion.new(); motion.relative=Vector2(20,-900); rig._unhandled_input(motion)
	check(rig.target_pitch==60,"Vertical camera drag clamps to the upper limit")
	motion.relative=Vector2(0,1800); rig._unhandled_input(motion); check(rig.target_pitch==18,"Vertical camera drag reaches the horizon angle")
	var release: InputEventMouseButton=button.duplicate(); release.pressed=false; Input.parse_input_event(release); await key(KEY_HOME); await frames(30)
	check(rig.target_pitch==50 and rig.target_zoom==24,"Camera reset keeps the requested default tilt and zoom")
	var eye: Vector3=rig.camera.global_position; var focus: Vector3=game.player.position+Vector3(0,.8,0)
	var obstacle: MeshInstance3D=game.world.box(eye.lerp(focus,.85),Vector3(3,4,3),"c6a16a",true)
	var body: StaticBody3D=game.world.get_child(game.world.get_child_count()-1)
	await frames(3); rig.update_obstructions(); check(obstacle.visible and body.collision_layer==1,"Scenery between camera and player stays visible and solid")
	obstacle.position+=Vector3(20,0,0); body.position+=Vector3(20,0,0); await frames(2); rig.update_obstructions()
	check(obstacle.visible,"Camera obstruction restores after the view clears")
	obstacle.position=rig.camera.global_position; body.position=obstacle.position; rig.update_obstructions(); check(not obstacle.visible,"Object enclosing the camera is hidden")
	obstacle.queue_free(); body.queue_free(); await frames(2)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(Vector2i(1280,720)); await frames(12)
	ValeNarrativeUI.roster(game.hud.ui,"tarin"); await shot("company-720"); game.hud.close_modal()
	game.hud.ui.quest_filter="Main"; ValeJourneyPages.journal(game.hud.ui); await shot("journal-720"); game.hud.close_modal()
	State.talk_npc("ilyra"); await shot("dialogue-720"); game.hud.close_modal()
	State.completed_quests.erase("act1_09"); State.quest_progress.act1_09=3
	ValeJourneyPages.show_objective(game.hud.ui,"act1_09"); await shot("objective-map-720"); game.hud.close_modal()
	var sites: Dictionary=State.narrative.locations.duplicate(true)
	await visit("glass_archive"); game.rig.target_zoom=16; game.rig.snap(); await shot("restored-archive")
	check(game.narrative.scenes.glass_archive.get_meta("variant")=="shelter","Archive reconstructs the chosen public variant with reading props")
	check(sites.glass_archive==State.narrative.locations.glass_archive,"Returning preserves the authored logical address")
	await finish()
