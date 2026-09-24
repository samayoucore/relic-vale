extends "res://tests/phase8_test.gd"
var output_dir: String
var save_before: Dictionary={}
func shot(label: String) -> void:
	for i in 3: await get_tree().process_frame
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png(output_dir+"/"+label+".png")
func finish() -> void:
	var suffix: String="-reload" if OS.get_environment("VALE_QA_RELOAD")=="1" else ""
	var file:=FileAccess.open(output_dir+"/acceptance"+suffix+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":results,"release_template":not OS.is_debug_build(),"save_directory":OS.get_user_data_dir()},"\t")); file.close()
	print("RELEASE_ACCEPTANCE_RESULT ",passed," / ",failed)
	await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)
func button(label: String) -> Button:
	for node in game.hud.find_children("*","Button",true,false):
		if node.text==label and node.is_visible_in_tree(): return node
	return null
func press(label: String) -> bool:
	var node:=button(label)
	check(is_instance_valid(node),"Visible button: "+label)
	if is_instance_valid(node): node.pressed.emit(); await frames(5); return true
	return false
func run() -> void:
	game=get_tree().current_scene; output_dir=OS.get_environment("VALE_QA_DIR")
	DirAccess.make_dir_recursive_absolute(output_dir)
	await frames(10)
	check(not OS.is_debug_build(),"Using Windows x86_64 Release template")
	check(not game.test_mode and not game.gameplay_started,"Normal startup shows menu without developer mode")
	Preferences.temporary=true
	Preferences.values.display="Windowed"; Preferences.values.resolution=Vector2i(1280,720)
	Preferences.values.fps_limit=60; Preferences.set_preset("Medium")
	await shot("01-main-menu")
	if OS.get_environment("VALE_QA_RELOAD")=="1":
		check(game.load_game("user://journey.json"),"Fresh release process reloads journey")
		check(State.character_name=="Путник" and State.world_data.name=="Тестовая долина","Cyrillic traveler and world names persist")
		check(State.map_data.markers.size()>0,"Atlas marker persists")
		check(not State.gathered_resources.is_empty(),"Gathering deltas persist")
		check(game.mounts.own(),"Owned horse persists")
		await frames(15); await shot("20-fresh-reload")
		await finish(); return
	await press("Settings")
	Preferences.set_preset("Minimal"); Preferences.set_option("pixelated",true)
	await shot("02-settings")
	check(game.viewport.size.x<1280 and game.hud.ui.scale.x==1,"Pixelated world retains native-resolution interface")
	game.hud.ui.main_menu(); await press("New Game")
	var fields: Array=game.hud.ui.body.find_children("*","LineEdit",true,false).filter(func(node): return node.is_visible_in_tree())
	check(fields.size()==2,"New World has name and seed fields")
	fields[0].text="Тестовая долина"; fields[1].text="20260907"
	await press("Begin journey"); await frames(30)
	var names: Array=game.hud.find_children("*","LineEdit",true,false)
	for name in names:
		if name.is_visible_in_tree(): name.text="Путник"
	await shot("03-character")
	await press("Keep this traveler")
	check(game.hud.modal_kind=="help","First traveler receives lightweight onboarding")
	await shot("04-first-steps"); await press("Follow the road")
	check(game.gameplay_started and not State.modal,"New World enters playable state")
	var start: Vector3=game.player.position
	Input.action_press("move_right"); await frames(40); Input.action_release("move_right")
	check(game.player.position.distance_to(start)>1,"Movement input moves player through village")
	for key in [KEY_F3,KEY_F4,KEY_F7,KEY_F8,KEY_F10]:
		var event:=InputEventKey.new(); event.pressed=true; event.physical_keycode=key
		game._unhandled_input(event)
		check(not game.debug_panel.visible and not State.modal,"Developer key disabled in release: "+OS.get_keycode_string(key))
	game.player.god_mode=true
	game.player.invulnerability=0
	var hp: int=State.hp; game.player.take_damage(1)
	check(State.hp<hp,"God-mode field has no effect in release")
	game.player.god_mode=false; State.hp=State.max_hp
	game.player.invulnerability=1000
	var enemy=load("res://scenes/characters/Enemy.tscn").instantiate()
	enemy.position=game.player.position+Vector3(0,0,1.2); game.world.add_child(enemy)
	await frames(4); var enemy_hp: int=enemy.hp
	game.player.facing=Vector3.BACK
	var strike:=InputEventKey.new(); strike.physical_keycode=KEY_SPACE; strike.pressed=true
	Input.parse_input_event(strike); await frames(2)
	var released:=strike.duplicate(); released.pressed=false; Input.parse_input_event(released)
	await frames(83)
	check(not is_instance_valid(enemy) or enemy.dead or enemy.hp<enemy_hp,"Real attack input damages an enemy")
	if is_instance_valid(enemy): enemy.queue_free()
	await gather("wood","crude_axe")
	game.hud.show_inventory(); await frames(5); await shot("05-inventory"); game.hud.close_modal()
	game.hud.show_map(); await frames(90); await shot("06-atlas"); game.hud.close_modal()
	var address: Dictionary=game.generator.address(game.player.position)
	var marker: Dictionary=game.cartography.add_marker(address,"Домой","Home")
	check(not marker.is_empty(),"Explored location accepts a named marker")
	game.travel.combat_until=0; game.player.attack_timer=0
	for other in get_tree().get_nodes_in_group("enemies"):
		if other.global_position.distance_to(game.player.position)<20: other.queue_free()
	await frames(4)
	check(await game.travel.go(marker),"Fast travel completes with safe arrival")
	State.talk_npc("rowan"); await frames(5)
	check(State.modal,"NPC interaction opens dialogue"); await shot("07-dialogue"); game.hud.close_modal()
	var building: Dictionary={}
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.has_meta("building"): building=node.get_meta("building"); break
	await game.interiors.enter(building); await frames(10)
	check(is_instance_valid(game.interiors.room),"Building interior loads in release")
	await shot("08-interior"); await game.interiors.leave()
	# Advanced systems use the already completed Phase 9 journey as a controlled fixture.
	check(game.load_game("user://phase9-stories.json"),"Existing developed camp/story save migrates into release")
	game.active_save_path="user://journey.json"; State.character_name="Путник"; State.world_data.name="Тестовая долина"
	var camp_at: Dictionary=State.camp_data.address
	game.generator.teleport_logical(int(camp_at.x),int(camp_at.z),ValeSave.vector(camp_at.local)+Vector3(0,0,4)); game.camp.sync_visual(true); await frames(15)
	check(is_instance_valid(game.camp.visual),"Developed camp reconstructs")
	await shot("09-developed-camp")
	State.coins=maxi(State.coins,180)
	if not game.mounts.own(): check(game.mounts.acquire(),"Horse purchase follows tier and copper rules")
	game.player.attack_timer=0
	check(game.mounts.call_mount(),"Normal mount command calls owned horse")
	if is_instance_valid(game.mounts.actor):
		game.player.position=game.mounts.actor.global_position+Vector3(0,0,1)
		check(game.mounts.mount(),"Approaching horse allows mounting")
		start=game.player.position; Input.action_press("move_right"); Input.action_press("sprint"); await frames(45); Input.action_release("move_right"); Input.action_release("sprint")
		check(game.mounts.mounted and game.player.position.distance_to(start)>2,"Mounted movement uses player physics")
		await shot("10-mounted"); check(game.mounts.dismount(),"Horse dismount finds open ground")
	game.generator.teleport_logical(0,0,Vector3(0,0,3.6)); await frames(8)
	State.add_item("fishing_rod_1"); State.add_item("bait_basic",10); State.equip("fishing_rod_1"); State.activities.bait="bait_basic"
	var bank: Dictionary=ValeProfessionPages.find_bank(game)
	check(not bank.is_empty(),"Accessible fishing bank exists")
	if not bank.is_empty(): await catch_fish("fish_minnow")
	game.hud.close_modal(); game.generator.teleport_logical(0,0,Vector3(0,0,3.6)); await frames(5)
	await gather("wood","crude_axe")
	check(not State.gathered_resources.is_empty(),"Gathered tree recorded in the active journey")
	marker=game.cartography.add_marker(game.generator.address(game.player.position),"Домой","Home")
	check(not marker.is_empty(),"Release fixture includes persistent marker")
	check(game.save_game(true),"Manual release save succeeds")
	check(FileAccess.file_exists("user://journey.json.png"),"Manual save produces thumbnail outside install directory")
	for preset in ["Minimal","Medium","High","Ultra"]:
		Preferences.set_preset(preset)
		for pixelated in [false,true]:
			Preferences.set_option("pixelated",pixelated); await frames(12)
			await shot("preset-"+preset+("-pixel" if pixelated else "-smooth"))
			check(game.atmosphere.fog_end>0,"Atmosphere available: "+preset+str(pixelated))
	Preferences.set_preset("Medium"); Preferences.set_option("pixelated",false)
	for size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160),Vector2i(1280,800)]:
		Preferences.set_option("resolution",size); game.hud.ui.settings_page(); await frames(10)
		check(game.hud.modal_panel.get_global_rect().end.x<=game.hud.get_viewport_rect().size.x+1,"Settings fit horizontal viewport "+str(size))
		await shot("ui-"+str(size.x)+"x"+str(size.y))
	Preferences.set_option("resolution",Vector2i(1280,720))
	for amount in [.8,1.0,1.5]:
		Preferences.set_option("ui_scale",amount); await frames(5)
		check(game.hud.modal_panel.get_global_rect().size.x>300,"Usable settings width at UI scale "+str(amount))
		await shot("scale-"+str(amount))
	Preferences.set_option("ui_scale",1.0)
	var font: Font=game.hud.ui.theme.default_font
	for glyph in "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюяLatin0123456789—…!?":
		check(font.has_char(glyph.unicode_at(0)),"Font supports "+glyph)
	game.hud.close_modal(); await frames(3)
	check(game.save_game(true),"Final journey checkpoint saves")
	await finish()
