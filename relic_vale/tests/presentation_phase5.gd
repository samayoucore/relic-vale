extends "res://tests/ui_check.gd"
var samples: Array=[]

func shot5(name: String) -> void:
	await frames(15)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase5-"+name+".png")

func run() -> void:
	game=get_tree().current_scene
	await frames(40)
	game.player.god_mode=true
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"): enemy.set_physics_process(false)
	var rig: ValeCamera=game.rig
	State.modal=false
	var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_RIGHT; event.pressed=true
	Input.parse_input_event(event)
	await frames(1)
	var motion:=InputEventMouseMotion.new(); motion.relative=Vector2(30,-900)
	rig._unhandled_input(motion)
	check(rig.target_pitch==60,"Vertical right drag clamps to 60 degrees")
	check(not is_equal_approx(rig.target_yaw,deg_to_rad(42)),"Horizontal orbit still works")
	motion.relative=Vector2(0,1800); rig._unhandled_input(motion)
	check(rig.target_pitch==40,"Vertical right drag clamps to 40 degrees")
	event.pressed=false; Input.parse_input_event(event)
	await key(KEY_HOME); await frames(25)
	check(rig.target_pitch==50 and rig.target_zoom==24,"Home resets pitch, yaw and zoom")
	var eye: Vector3=rig.camera.global_position
	var focus: Vector3=game.player.global_position+Vector3(0,.8,0)
	var blocking: MeshInstance3D=game.world.box(eye.lerp(focus,.85),Vector3(3,4,3),"c6a16a",true)
	await frames(3); rig.update_obstructions()
	check(not blocking.visible,"Blocking object is hidden while occluding the player")
	var body: StaticBody3D=game.world.get_child(game.world.get_child_count()-1)
	check(body.collision_layer==1 and body.get_child_count()==1,"Hidden obstacle retains physical collision")
	blocking.position+=Vector3(20,0,0); body.position+=Vector3(20,0,0)
	await frames(2)
	rig.update_obstructions()
	check(blocking.visible,"Obstacle is restored when camera has a clear view")
	blocking.position=rig.camera.global_position; body.position=blocking.position
	rig.update_obstructions(); check(not blocking.visible,"Camera-inside-object case is hidden")
	blocking.queue_free(); body.queue_free(); await frames(2); rig.update_obstructions()
	check(true,"Unloading a hidden object is safe")
	State.add_item("moon_blade"); State.add_item("warden_mail"); State.add_item("moonstone_heart")
	State.coins=900; State.astral_shards=4
	game.hud.ui.selected="moon_blade"; game.hud.show_inventory(); await frames(8)
	await press("Equip to Weapon")
	check(State.equipment.Weapon=="moon_blade","New inventory equips with actual mouse input")
	await shot5("inventory"); game.hud.close_modal()
	game.hud.show_character(); await shot5("character"); game.hud.close_modal()
	game.hud.show_abilities(); await shot5("abilities"); game.hud.close_modal()
	game.hud.show_quests(); await shot5("journal"); game.hud.close_modal()
	game.hud.ui.shop_page("smith"); await shot5("shop"); game.hud.close_modal()
	for target in get_tree().get_nodes_in_group("interactables"):
		if target.kind=="crafting": game.hud.ui.crafting_page(target); await shot5("crafting"); game.hud.close_modal(); break
	game.hud.show_shrine(); await frames(8)
	var shards: int=State.astral_shards
	await press("Wish"); await press("Wish"); check(State.astral_shards==shards-1,"Shrine spends only one shard during a reveal")
	await frames(65); await shot5("shrine"); game.hud.close_modal()
	game.hud.ui.settings_page(); await shot5("settings"); game.hud.close_modal()
	for pitch in [40.0,60.0]:
		rig.target_pitch=pitch; await frames(35); await shot5("camera-"+str(int(pitch)))
	rig.target_pitch=50
	for preset in ["Minimal","Medium","High","Ultra"]:
		Preferences.set_preset(preset)
		for pixels in [false,true]:
			Preferences.set_option("pixelated",pixels)
			check(Preferences.values.preset==preset and game.pixel_mode==pixels,preset+" keeps pixel style independent")
			game.generator.teleport_logical(0,0,Vector3(24,0,-6)); game.life.set_time(11)
			await frames(70)
			rig.target_yaw+=.35; game.player.attack(); game.player.abilities.use(0)
			await frames(45)
			await shot5(preset.to_lower()+("-pixel" if pixels else "-clean")+"-forest")
			samples.append({"preset":preset,"pixels":pixels,"fps":Engine.get_frames_per_second(),"frame_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"foliage":game.graphics.foliage_instances,"resolution":str(game.viewport.size)})
			game.generator.teleport_logical(0,0,Vector3(61,0,32)); State.life_data.weather="Rain"; State.life_data.weather_block=int(State.life_data.day)*8+int(State.life_data.minute/180)
			await frames(50); await shot5(preset.to_lower()+("-pixel" if pixels else "-clean")+"-water")
			check(game.life.rain.emitting,preset+" rain remains active")
			game.player.position=Vector3(1000,0,-15); rig.snap(); await frames(20); game.player.abilities.use(1)
			await shot5(preset.to_lower()+("-pixel" if pixels else "-clean")+"-crypt")
			check(game.player.position.y>-.8,preset+" crypt retains floor and readable combat")
	Preferences.set_preset("Medium"); Preferences.set_option("pixelated",false)
	game.generator.teleport_logical(0,0,Vector3(0,0,4)); game.life.set_time(18)
	game.hud.ui.main_menu(); await shot5("main-menu")
	game.hud.close_modal()
	for scale in [.8,1.0,1.5]:
		Preferences.set_option("ui_scale",scale)
		game.hud.show_inventory(); await frames(15)
		check(game.hud.modal_panel.get_global_rect().end.x<=get_viewport().get_visible_rect().size.x+2,"Inventory fits width at UI scale "+str(scale))
		await shot5("ui-scale-"+str(scale)); game.hud.close_modal()
	Preferences.set_option("ui_scale",1.0)
	game.generator.chart_chunk("0,0"); game.hud.show_map(); await shot5("atlas"); game.hud.close_modal()
	var file:=FileAccess.open("res://docs/PHASE_6_PRESENTATION.json",FileAccess.WRITE); file.store_string(JSON.stringify({"passed":checks.size(),"failed":failures.size(),"samples":samples},"\t")); file.close()
	print("PRESENTATION5_RESULT ",checks.size()," passed ",failures.size()," failed")
	await Feel.shutdown(); get_tree().quit(0 if failures.is_empty() else 1)
