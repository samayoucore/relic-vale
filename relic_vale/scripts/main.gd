extends Node

var active_save_path: String=ValeSave.PATH
var gameplay_started: bool=false
var graphics: Node
var atmosphere: ValeCameraAtmosphere
var viewport: SubViewport
var screen: TextureRect
var world: ValeWorld
var player: ValePlayer
var rig: ValeCamera
var hud: ValeHUD
var nearest: ValeInteractable
var interaction_timer: float = 0
var pixel_mode: bool = true
var generator: ValeGenerator
var debug_panel: Control
var test_mode: bool=false
var life: ValeLife
var interiors: ValeInteriors
var expedition: ValeExpedition
var loot_manager: ValeLootManager
var cartography: ValeCartography
var camp: ValeCamp
var travel: ValeTravel
var fishing: ValeFishing
var cultivation: ValeCultivation
var mounts: ValeMounts
var exploration: ValeExploration
var narrative: ValeNarrative
var party: ValeParty
var world_events: ValeWorldEvents

func _exit_tree() -> void:
	if cartography!=null: cartography.forget_cache()

func _ready() -> void:
	var start:=Vector3(0,0,3.6)
	var arguments:=OS.get_cmdline_user_args() if OS.is_debug_build() else PackedStringArray()
	arguments=arguments.duplicate(); arguments.erase("--safe-mode")
	test_mode=not arguments.is_empty()
	gameplay_started=test_mode
	if "--phase4-startup" in arguments: start=ValeSave.apply(ValeSave.read("user://phase4-integration.json"))
	if "--far-reload" in arguments: start=ValeSave.apply(ValeSave.read("user://phase5-far.json"))
	setup_input()
	Preferences.changed.connect(sync_mount_binding)
	viewport=SubViewport.new()
	viewport.name="PixelWorld"
	viewport.size=Vector2i(768,432)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_2X
	add_child(viewport)
	screen=TextureRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.texture=viewport.get_texture()
	screen.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	screen.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	screen.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	world=preload("res://scenes/world/World.tscn").instantiate()
	viewport.add_child(world)
	player=preload("res://scenes/characters/Player.tscn").instantiate()
	player.position=start
	rig=preload("res://scenes/world/CameraRig.tscn").instantiate()
	rig.target=player
	player.camera_rig=rig
	world.add_child(player)
	world.add_child(rig)
	rig.snap()
	world.player=player
	loot_manager=ValeLootManager.new()
	world.add_child(loot_manager)
	generator=preload("res://scripts/world_generation/streaming_generator.gd").new()
	generator.player=player
	generator.world_seed=State.world_seed
	generator.origin_x=int(State.world_data.origin_x)
	generator.origin_z=int(State.world_data.origin_z)
	generator.discovered=State.world_data.discovered.duplicate(true)
	world.generator=generator
	world.add_child(generator)
	interiors=ValeInteriors.new(); world.add_child(interiors); interiors.setup_hub()
	life=ValeLife.new()
	world.add_child(life)
	expedition=ValeExpedition.new()
	world.add_child(expedition)
	if start.x>1500 and not State.life_data.dungeons.get("active",{}).is_empty():
		expedition.generate(State.life_data.dungeons.active.id,State.life_data.dungeons.active.theme)
	var nameplates:=Control.new()
	nameplates.set_script(preload("res://scripts/nameplates.gd"))
	nameplates.game=self
	nameplates.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nameplates.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(nameplates)
	hud=preload("res://scenes/ui/HUD.tscn").instantiate()
	hud.player=player
	hud.rig=rig
	hud.world=world
	add_child(hud)
	cartography=ValeCartography.new(); cartography.game=self
	camp=ValeCamp.new(); add_child(camp)
	travel=ValeTravel.new(); add_child(travel)
	fishing=ValeFishing.new(); add_child(fishing)
	cultivation=ValeCultivation.new(); add_child(cultivation)
	mounts=ValeMounts.new(); add_child(mounts)
	exploration=ValeExploration.new(); add_child(exploration)
	narrative=ValeNarrative.new(); add_child(narrative)
	party=ValeParty.new(); add_child(party)
	world_events=ValeWorldEvents.new(); add_child(world_events)
	var minimap:=ValeAtlas.new(); minimap.hud=hud; minimap.minimap=true; hud.ui.chrome.add_child(minimap)
	graphics=ValeGraphics.new()
	add_child(graphics)
	atmosphere=ValeCameraAtmosphere.new(); add_child(atmosphere)
	debug_panel=Panel.new()
	if OS.is_debug_build():
		debug_panel.set_script(preload("res://scripts/ui/world_debug.gd"))
		debug_panel.game=self
	debug_panel.visible=false
	hud.add_child(debug_panel)
	hud.show_toast("Welcome to Willowmere. Your journey begins by the well.")
	if not test_mode and FileAccess.file_exists(ValeSave.PATH): hud.show_toast("Your saved journey continues.  F6 save · F9 load")
	State.save_requested.connect(func(): save_game(false))
	generator.sync_hub()
	if not test_mode:
		life.set_time(18)
		hud.ui.main_menu.call_deferred()
	get_tree().auto_accept_quit=false
	if not OS.is_debug_build(): return
	var args:=arguments
	if "--phase10-save" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase10_save.gd")); add_child(check)
	if "--phase10-stress" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase10_stress.gd")); add_child(check)
	if "--phase9-camera" in args or "--phase9-camera-reload" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase9_camera.gd")); add_child(check)
	if "--phase9-slice" in args or "--phase9-reload" in args or "--phase9-portraits" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase9_slice.gd")); add_child(check)
	if "--phase9-stories" in args or "--phase9-stories-reload" in args or "--phase9-stories-resume" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase9_stories.gd")); add_child(check)
	if "--phase9-events" in args or "--phase9-events-reload" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase9_events.gd")); add_child(check)
	if "--phase9-acceptance" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase9_acceptance.gd")); add_child(check)
	if "--phase9-polish" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase9_polish.gd")); add_child(check)
	if "--phase8-edges" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase8_edges.gd")); add_child(check)
	if "--phase8-icons" in args:
		var render:=Node.new(); render.set_script(load("res://tests/phase8_icons.gd")); add_child(render)
	if "--phase8-test" in args or "--phase8-reload" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase8_test.gd")); add_child(check)
	if "--phase8-final" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase8_final.gd")); add_child(check)
	if "--phase7-test" in args or "--phase7-reload" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase7_test.gd")); add_child(check)
	if "--phase7-extra" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase7_extra.gd")); add_child(check)
	if "--phase7-visual" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase7_visual.gd")); add_child(check)
	if "--phase6-validation" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase6_validation.gd")); add_child(check)
	if "--phase6-wild-check" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase6_wild_check.gd")); add_child(check)
	if "--phase6-life-check" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase6_life_check.gd")); add_child(check)
	if "--phase6-acceptance-reload" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase6_acceptance_reload.gd")); add_child(check)
	if "--phase6-acceptance" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase6_acceptance.gd")); add_child(check)
	if "--phase6-visual" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase6_visual.gd")); add_child(check)
	if "--phase6-reload" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase6_reload.gd")); add_child(check)
	if "--phase6-test" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase6_test.gd")); add_child(check)
	if "--ui-phase5-final" in args:
		var check:=Node.new(); check.set_script(load("res://tests/ui_phase5_final.gd")); add_child(check)
	if "--final-phase5" in args:
		var check:=Node.new(); check.set_script(load("res://tests/phase5_final.gd")); add_child(check)
	if "--presentation-test" in args:
		var check:=Node.new(); check.set_script(load("res://tests/presentation_phase5.gd")); add_child(check)
	if "--smoke-test" in args:
		var test:=Node.new()
		test.set_script(load("res://tests/phase2_test.gd"))
		add_child(test)
	if "--capture" in args:
		capture_gallery.call_deferred()
	if "--capture-generated" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/generation_check.gd"))
		add_child(check)
	if "--phase2-test" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/phase2_test.gd"))
		add_child(check)
	if "--ui-check" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/ui_check.gd"))
		add_child(check)
	if "--combat-check" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/combat_phase3.gd"))
		add_child(check)
	if "--encounter-check" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/encounter_phase3.gd"))
		add_child(check)
	if "--phase3-test" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/phase3_test.gd"))
		add_child(check)

	if "--regression-check" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/regression_phase3.gd"))
		add_child(check)
	if "--boss-playtest" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/boss_playtest.gd"))
		add_child(check)
	if "--visual-phase4" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/visual_phase4.gd"))
		add_child(check)
	if "--phase4-test" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/phase4_test.gd"))
		add_child(check)
	if "--phase4-extra" in args or "--phase4-startup" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/extra_phase4.gd"))
		add_child(check)
	if "--stream-test" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/streaming_phase5.gd"))
		add_child(check)
	if "--stress-world" in args or "--far-reload" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/stream_stress.gd"))
		add_child(check)
	if "--walk-phase4" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/walk_phase4.gd"))
		add_child(check)
	if "--audit-phase4" in args:
		var check:=Node.new()
		check.set_script(load("res://tests/audit_phase4.gd"))
		add_child(check)

func setup_input() -> void:
	InputMap.add_action("call_mount")
	sync_mount_binding()
	for pair in [{"id":"ability_1","key":KEY_1},{"id":"ability_2","key":KEY_2}]:
		if not InputMap.has_action(pair.id): InputMap.add_action(pair.id)
		var bind:=InputEventKey.new()
		bind.physical_keycode=pair.key
		InputMap.action_add_event(pair.id,bind)
	InputMap.add_action("dodge")
	var dodge_key:=InputEventKey.new()
	dodge_key.physical_keycode=KEY_CTRL
	InputMap.action_add_event("dodge",dodge_key)
	var mapping: Dictionary={"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"rotate_left":[KEY_Q],"rotate_right":[KEY_R],"interact":[KEY_E],"attack":[KEY_SPACE],"inventory":[KEY_I],"heal":[KEY_H],"sprint":[KEY_SHIFT],"camera_reset":[KEY_HOME],"pause":[KEY_ESCAPE],"map":[KEY_TAB],"fullscreen":[KEY_F11]}
	for action in mapping:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in mapping[action]:
			var event:=InputEventKey.new()
			event.physical_keycode=key
			InputMap.action_add_event(action,event)
	var mouse:=InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack",mouse)

func sync_mount_binding() -> void:
	InputMap.action_erase_events("call_mount")
	var event:=InputEventKey.new(); event.physical_keycode=OS.find_keycode_from_string(Preferences.values.mount_key)
	InputMap.action_add_event("call_mount",event)

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(fishing) and fishing.input(event): return
	if event is InputEventKey and event.pressed and not event.echo and gameplay_started:
		if event.physical_keycode==KEY_P:
			if State.modal and hud.modal_kind=="professions": hud.close_modal()
			elif not State.modal: ValeProfessionPages.show(hud.ui)
			return
		if OS.is_debug_build() and event.physical_keycode==KEY_F8: ValeProfessionPages.debug(hud.ui); return
		if event.physical_keycode==KEY_O: ValeNarrativeUI.roster(hud.ui); return
		if event.physical_keycode==KEY_Z: ValeNarrativeUI.commands(hud.ui); return
		if OS.is_debug_build() and event.physical_keycode==KEY_F10: ValeNarrativeUI.debug(hud.ui); return
	if event.is_action_pressed("call_mount") and not State.modal: mounts.call_mount(); return
	if event is InputEventKey and event.pressed and not event.echo:
		if travel.busy: return
		if camp.placing and event.physical_keycode==KEY_ESCAPE: camp.cancel_placement(); return
		if camp.placing and event.physical_keycode==KEY_ENTER: camp.establish(camp.preview_address); return
		if event.physical_keycode==KEY_G and gameplay_started and not camp.placing:
			if hud.modal_kind=="camp" and State.modal: hud.close_modal()
			else: ValeCampUI.show(hud.ui)
			return
		if OS.is_debug_build() and event.physical_keycode==KEY_F7:
			ValeCampUI.debug(hud.ui); return
		if event.physical_keycode==KEY_C and not State.modal and not debug_panel.visible:
			hud.show_character()
			return
		if event.physical_keycode==KEY_B and not debug_panel.visible:
			if hud.modal_kind=="abilities": hud.close_modal()
			elif not State.modal: hud.show_abilities()
			return
		if OS.is_debug_build() and event.physical_keycode==KEY_F4:
			if hud.modal_kind=="phase6_debug": hud.close_modal()
			else: ValePhase6Debug.show(hud.ui)
			return
		if event.physical_keycode==KEY_F6:
			save_game()
			return
		if event.physical_keycode==KEY_F9:
			load_game()
			return
		if event.physical_keycode==KEY_J and not debug_panel.visible:
			if hud.modal_kind=="quests": hud.close_modal()
			elif not State.modal: hud.show_quests()
			return
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F3:
		debug_panel.toggle()
		return
	if debug_panel.visible:
		if event.is_action_pressed("pause"): debug_panel.toggle()
		return
	if event is InputEventKey and event.alt_pressed and event.physical_keycode==KEY_E: return
	if event.is_action_pressed("fullscreen"):
		var fullscreen: bool=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if event.is_action_pressed("pause"):
		if State.modal: hud.close_modal()
		else: hud.show_pause()
		return
	if State.modal:
		if event.is_action_pressed("interact") and hud.modal_kind=="dialogue": hud.close_modal()
		elif event.is_action_pressed("inventory") and hud.modal_kind=="inventory": hud.close_modal()
		elif event.is_action_pressed("map") and hud.modal_kind=="map": hud.close_modal()
		return
	if event.is_action_pressed("inventory"):
		hud.show_inventory()
		return
	if event.is_action_pressed("map"):
		hud.show_map()
		return
	if event.is_action_pressed("interact"):
		try_interact()
		return
	# A TextureRect displays the SubViewport; forward only unconsumed game input.
	rig._unhandled_input(event)
	player._unhandled_input(event)

func _process(delta: float) -> void:
	interaction_timer-=delta
	if interaction_timer>0: return
	interaction_timer=.08
	nearest=null
	var distance: float=2.3
	for candidate in get_tree().get_nodes_in_group("interactables"):
		if not candidate.is_visible_in_tree(): continue
		var d: float=player.global_position.distance_to(candidate.global_position)
		if d<distance:
			distance=d
			nearest=candidate
	var prompt: String=nearest.prompt() if is_instance_valid(nearest) else ("Face the water · E to cast · P to choose bait" if fishing.equipped() else "")
	if mounts.mounted: prompt="Shift: gallop · E: dismount"
	if fishing.busy() or cultivation.busy(): prompt=""
	hud.set_prompt(prompt)

func try_interact() -> void:
	if State.modal: return
	if mounts.mounted: mounts.dismount(); return
	if cultivation.busy() or fishing.busy(): return
	# Recheck at input time; never interact with a stale cached target.
	if is_instance_valid(nearest) and player.global_position.distance_to(nearest.global_position)<2.4:
		nearest.interact(player)
	elif fishing.equipped(): fishing.cast()
	else: hud.show_toast("Move closer to a person, chest, or wishing stone.")

func save_game(show_message: bool = true, path: String = "") -> bool:
	if not gameplay_started: return false
	if path.is_empty(): path=active_save_path
	if test_mode and path==ValeSave.PATH: return false
	State.world_data.origin_x=str(generator.origin_x)
	State.world_data.origin_z=str(generator.origin_z)
	State.world_data.discovered=generator.discovered.duplicate(true)
	State.world_data.address=generator.address(player.position) if player.position.x<900 else generator.address(State.dungeon_return)
	if State.interior_data.has("active"): State.world_data.address=State.interior_data.active.return.duplicate(true)
	if mounts.mounted: mounts.record().address=generator.address(player.global_position)
	for actor in party.actors.values(): actor.record_position()
	var success: bool=ValeSave.write(player.global_position,path)
	if success and show_message and DisplayServer.get_name()!="headless":
		var preview:=viewport.get_texture().get_image()
		if not preview.is_empty():
			preview.resize(256,144,Image.INTERPOLATE_BILINEAR)
			if preview.save_png(path+".preview.tmp.png")==OK: DirAccess.rename_absolute(path+".preview.tmp.png",path+".png")
	if show_message or not success: hud.show_toast("Journey saved." if success else ValeSave.last_error)
	return success

func load_game(path: String = "") -> bool:
	if path.is_empty(): path=active_save_path
	var data:=ValeSave.read(path)
	if data.is_empty():
		hud.show_toast(ValeSave.last_error)
		return false
	var position:=ValeSave.apply(data)
	active_save_path=path; gameplay_started=true
	hud.modal_kind=""
	hud.close_modal()
	debug_panel.visible=false
	restore_world(position)
	hud.show_toast("Journey restored." if ValeSave.last_error.is_empty() else ValeSave.last_error)
	return true

func restore_world(position: Vector3) -> void:
	party.reset(); narrative.reset()
	world_events.reset()
	fishing.cancel(); cultivation.action={}; mounts.reset(); exploration.reset()
	camp.cancel_placement(); camp.clear_visual(); cartography.forget_cache()
	interiors.reset()
	player.gathering.cancel()
	loot_manager.clear()
	player.statuses.clear()
	player.shield=0
	player.shield_time=0
	player.dodge_bonus=0
	player.dash_timer=0
	player.dash_cooldown=0
	player.combat.cancel()
	player.abilities.dash_pending=0
	for id in player.abilities.cooldowns: player.abilities.cooldowns[id]=0
	for node in get_tree().get_nodes_in_group("projectiles"): node.queue_free()
	for node in get_tree().get_nodes_in_group("combat_hazards"): node.queue_free()
	player.global_position=position
	player.velocity=Vector3.ZERO
	player.attack_timer=0
	player.invulnerability=2
	rig.snap()
	generator.origin_x=int(State.world_data.origin_x)
	generator.origin_z=int(State.world_data.origin_z)
	generator.discovered=State.world_data.discovered.duplicate(true)
	generator.regenerate(State.world_seed)
	generator.sync_hub()
	interiors.setup_hub()
	for npc in world.hub_root.get_children():
		if npc is ValeInteractable and npc.is_inside_tree() and npc.kind=="npc" and not npc.has_meta("schedule"): ValeSchedule.attach(npc,npc.global_position,world.hub_root.to_global(Vector3(0,0,5.5)))
	expedition.clear()
	if position.x>1500 and position.x<2900 and not State.life_data.dungeons.get("active",{}).is_empty(): expedition.generate(State.life_data.dungeons.active.id,State.life_data.dungeons.active.theme)
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"):
		if enemy.boss: enemy.boss.reset()
		if enemy.unique and State.defeated_unique.has(enemy.persistent_id):
			enemy.dead=true
			enemy.visible=false
			enemy.remove_from_group("enemies")
		else: enemy.revive()
	for target in get_tree().get_nodes_in_group("interactables"): target.synchronize()
	if position.x>2900 and State.interior_data.has("active"): interiors.enter.call_deferred(State.interior_data.active.building,true)
	State.appearance_changed.emit()
	State.changed.emit()
	camp.resolve(); camp.sync_visual(true)

func phase7_find_clearing() -> Dictionary:
	hud.close_modal(); State.modal=true
	for ring in range(3,22):
		for dx in range(-ring,ring+1):
			for dz in [-ring,ring]:
				if posmod(dx,4)!=2 or posmod(dz,4)!=2: continue
				var address: Dictionary={"x":str(dx),"z":str(dz),"local":[16,0,16]}
				if not camp.placement_at(address,false).is_empty(): continue
				generator.teleport_logical(dx,dz)
				await get_tree().physics_frame; await get_tree().physics_frame
				address=generator.address(player.position)
				if camp.placement_at(address).is_empty():
					State.modal=false; rig.snap(); hud.show_toast("Open clearing found. G: establish camp."); return address
	State.modal=false; hud.show_toast("No open clearing nearby. Clear trees or search farther afield."); return {}

func new_world(seed_value: int,world_name: String="The Lower Vale") -> void:
	gameplay_started=true
	hud.modal_kind=""
	hud.close_modal()
	debug_panel.visible=false
	State.reset_progress(seed_value)
	State.world_data.name=world_name if not world_name.is_empty() else "The Lower Vale"
	player.god_mode=false
	restore_world(Vector3(0,0,3.6))
	save_game(false)
	hud.show_toast("A new journey  ·  Seed %d" % State.world_seed)
	if not test_mode: hud.show_character()

func quit_game() -> void:
	if not test_mode and gameplay_started and not save_game(false):
		hud.show_toast("Could not save. Keep playing or retry Save Game before quitting.")
		return
	await Feel.shutdown()
	get_tree().quit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: quit_game()

func capture_gallery() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	await get_tree().create_timer(5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/01-village.png")
	player.position=Vector3(24,0,-6)
	rig.snap()
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/02-forest.png")
	player.position=Vector3(37,0,-18)
	rig.snap()
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/03-entrance.png")
	player.position=Vector3(1000,0,1)
	rig.snap()
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/04-crypt.png")
	player.position=Vector3(0,0,3.6)
	rig.target_yaw=deg_to_rad(-28)
	rig.yaw=rig.target_yaw
	rig.snap()
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/05-camera-orbit.png")
	rig.target_yaw=deg_to_rad(42)
	rig.yaw=rig.target_yaw
	State.open_chest()
	await get_tree().create_timer(.7).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/06-dialogue.png")
	hud.close_modal()
	State.add_item("copper_leaf")
	hud.show_inventory()
	await get_tree().create_timer(.7).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/07-satchel.png")
	print("GALLERY_CAPTURED")
	get_tree().quit()
