extends "res://tests/phase9_slice.gd"
const CAMP_SAVE="user://phase9-camera-camp.json"

func finish() -> void:
	var suffix: String="CAMERA_RELOAD" if "--phase9-camera-reload" in OS.get_cmdline_user_args() else "CAMERA"
	FileAccess.open("res://docs/PHASE_9_"+suffix+"_TESTS.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":results},"\t"))
	print("PHASE9_"+suffix+"_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)

func renders(count: int=3) -> void:
	for frame in count: await get_tree().process_frame

func camp_is_clear() -> bool:
	var center: Vector3=game.generator.position_of(State.camp_data.address)
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is ValeResource:
			var offset: Vector3=node.global_position-center
			if absf(offset.x)<20 and absf(offset.z)<20: return false
	return true

func capture() -> Image:
	await renders(); RenderingServer.force_draw(false)
	return game.viewport.get_texture().get_image()

func edge_energy(img: Image,box: Rect2i) -> float:
	var sum: float=0
	for x in range(box.position.x,box.end.x-1):
		for y in range(box.position.y,box.end.y):
			sum+=absf(img.get_pixel(x,y).get_luminance()-img.get_pixel(x+1,y).get_luminance())
	return sum/maxi(1,box.get_area())

func run() -> void:
	game=get_tree().current_scene; await frames(12)
	game.player.god_mode=true; game.hud.close_modal(); game.world_events.autonomous=false
	if "--phase9-camera-reload" in OS.get_cmdline_user_args():
		check(game.load_game(CAMP_SAVE),"Fresh process loads cleared camp fixture"); game.active_save_path=ValeSave.PATH
		await frames(12)
		check(camp_is_clear(),"Cleared resources stay absent after process restart")
		check(State.resource_states.get("camera-test-tree",{}).get("respawn_day",-1)==0,"Camp clearance has no regrowth timer")
		State.life_data.day+=60
		var at: Dictionary=State.camp_data.address
		game.generator.teleport_logical(int(at.x),int(at.z),ValeSave.vector(at.local)); await frames(6)
		check(camp_is_clear(),"Resources do not regrow inside camp after sixty days")
		check(is_instance_valid(game.camp.visual),"The loaded camp retains its physical presentation")
		await finish(); return
	Preferences.values.display="Windowed"; Preferences.values.resolution=Vector2i(1280,720)
	Preferences.values.pixelated=false; Preferences.values.render_scale=.85; game.graphics.apply()
	game.life.set_time(11); State.life_data.weather="Clear"; game.life._process(0); game.life.set_process(false)
	var rig: ValeCamera=game.rig
	rig.pitch=18; rig.target_pitch=18; rig.yaw=deg_to_rad(42); rig.target_yaw=rig.yaw; rig.snap()
	await renders(12)
	check(rig.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"Low camera uses perspective")
	var size: Vector2=game.viewport.size
	check(rig.camera.project_ray_normal(Vector2(size.x*.5,0)).y>0,"The top of the lowest view looks above the horizon")
	check(rig.camera.project_ray_normal(size*.5).y<0,"The center still looks down toward the traveler")
	await shot("horizon-village")
	for preset in ["Minimal","Medium","High","Ultra"]:
		Preferences.set_preset(preset); game.generator.update_streaming(true); game.atmosphere.update_effect(0)
		var safe: float=game.atmosphere.safe_radius()
		check(game.atmosphere.fog_end<=safe and safe>=50,"Haze closes before the loaded terrain boundary: "+preset)
		var before: float=safe
		game.generator.shift_origin(Vector2i(1,0)); game.atmosphere.update_effect(0)
		check(is_equal_approx(game.atmosphere.safe_radius(),before),"Haze radius survives a floating-origin shift: "+preset)
	Preferences.set_preset("Medium"); game.generator.update_streaming(true)
	check(is_finite(game.atmosphere.safe_radius()) and game.atmosphere.safe_radius()<=64,"Lowering draw distance with retained chunks keeps a finite haze boundary")
	var center: Vector2i=game.generator.coord_at(game.player.position)
	var hole: Node3D=game.generator.active_chunks[game.generator.chunk_key(center+Vector2i(1,0))]
	hole.visible=false; game.atmosphere.update_effect(0)
	check(game.atmosphere.fog_end<=28,"Haze covers a nearby chunk that has not finished rendering")
	hole.visible=true; await renders(3); game.atmosphere.update_effect(0)
	rig.set_process(false); rig.snap()
	var eye: Vector3=rig.camera.global_position; var focus: Vector3=game.player.global_position+Vector3(0,.65,0)
	var obstacle: MeshInstance3D=game.world.box(eye.lerp(focus,.8),Vector3(2,3,2),"6b8753",true)
	var body: StaticBody3D=game.world.get_child(game.world.get_child_count()-1)
	await renders(); rig.update_obstructions()
	check(obstacle.visible,"A solid object between camera and hero is not hidden")
	game.player.position=obstacle.position+Vector3(.9,0,0); rig.update_obstructions()
	check(obstacle.visible,"Player proximity alone never hides scenery")
	game.player.position=focus-Vector3(0,.65,0)
	obstacle.position=eye; body.position=eye; rig.update_obstructions()
	check(not obstacle.visible and body.collision_layer==1,"Only camera containment hides a visual, leaving collision intact")
	obstacle.position=eye+Vector3(2.1,0,0); body.position=obstacle.position; rig.update_obstructions()
	check(obstacle.visible,"The visual returns as soon as the camera leaves it")
	obstacle.queue_free(); body.queue_free(); await renders()
	var round_object: MeshInstance3D=game.world.cylinder(eye-Vector3(.95,0,.95),1,3,"6b8753",12)
	round_object.add_to_group("camera_occluders"); rig.update_obstructions()
	check(round_object.visible,"Empty corners of a canopy's bounding box do not hide its mesh")
	round_object.position=eye; rig.update_obstructions()
	check(not round_object.visible,"Entering the actual curved mesh volume hides it")
	round_object.queue_free(); await renders()
	# A real foreground canopy, with no body at the camera eye, should soften.
	var tree: Node3D=game.world.place(game.world.NATURE+"tree_oak.glb",rig.camera.to_global(Vector3(-4,-4,-10)),5,0)
	tree.add_to_group("camera_occluders"); rig.update_obstructions()
	check(tree.visible,"A foreground tree remains visible instead of disappearing")
	await shot("horizon-foreground")
	tree.queue_free(); await renders()
	if DisplayServer.get_name()!="headless": await blur_pixels()
	rig.set_process(true); rig.pitch=50; rig.target_pitch=50
	# Add actual harvestable scenery to an otherwise valid surveyed site.
	var site: Dictionary=await game.phase7_find_clearing()
	check(not site.is_empty(),"Survey finds a valid dry camp location")
	if site.is_empty(): await finish(); return
	var at: Vector3=game.generator.position_of(site)
	var chunk: Node3D=game.generator.active_chunks[game.generator.chunk_key(game.generator.coord_at(at))]
	var tree_pos: Vector3=at+Vector3(4,0,0); tree_pos.y=game.generator.landscape.height(Vector2(tree_pos.x,tree_pos.z))
	var timber: ValeResource=ValeResource.spawn(game.world,chunk,"camera-test-tree","wood",tree_pos,game.world.NATURE+"tree_oak.glb",5,0,true)
	var stone: ValeResource=ValeResource.spawn(game.world,chunk,"camera-test-rock","stone",tree_pos+Vector3(0,0,3),game.world.NATURE+"rock_largeA.glb",1.4)
	await renders()
	check(is_instance_valid(timber.body) and is_instance_valid(stone.body),"Camp test uses real harvestable tree and rock collisions")
	check(game.camp.placement_at(site).is_empty(),"Natural obstacles permit camp establishment")
	var house: Node3D=game.world.place(game.world.VILLAGE+"house.gltf.glb",at+Vector3(-4,0,0),4)
	var wall: StaticBody3D=game.world.solid(at+Vector3(-4,1.8,0),Vector3(3,3.6,3),game.world,house)
	await frames(3)
	check(not game.camp.placement_at(site).is_empty(),"A house in the footprint blocks placement")
	check(not game.camp.establish(site) and is_instance_valid(house) and timber.remaining()>0,"Rejected placement leaves buildings and natural resources intact")
	house.queue_free(); wall.queue_free(); await frames(3)
	check(not game.camp.placement_at({"x":"0","z":"0","local":[0,0,4]},false).is_empty(),"Village structures and their surroundings stay protected")
	var protected_key: String="camera_test_landmark"
	State.narrative.locations[protected_key]=site.duplicate(true)
	check(not game.camp.placement_at(site).is_empty(),"Story landmarks are protected even without a solid collider")
	State.narrative.locations.erase(protected_key)
	var inventory: Dictionary=State.inventory.duplicate(true)
	check(game.camp.establish(site),"Camp establishment clears the occupied natural site")
	await renders(6)
	check(camp_is_clear(),"No harvestable or trunk collision remains in the camp reserve")
	check(State.resource_states.get("camera-test-tree",{}).get("hits",-1)==0 and State.resource_states.get("camera-test-rock",{}).get("hits",-1)==0,"Cleared tree and rock have persistent depletion records")
	check(State.inventory==inventory,"Land clearance does not duplicate gathering loot")
	await shot("cleared-camp")
	check(game.save_game(false,CAMP_SAVE),"Cleared camp saves to its isolated fixture")
	game.generator.teleport_logical(int(site.x)+8,int(site.z)+8); await frames(3)
	game.generator.teleport_logical(int(site.x),int(site.z),ValeSave.vector(site.local)); await frames(6)
	check(camp_is_clear(),"Leaving and returning does not recreate camp obstacles")
	await finish()

func blur_pixels() -> void:
	game.atmosphere.set_process(false)
	# Keep the production camera/effect but move the calibration cards above
	# village roofs so unrelated foreground scenery cannot cover the focus card.
	game.rig.global_position.y+=100
	game.atmosphere.material.set_shader_parameter("outdoors",false)
	var checker:=Image.create(128,128,false,Image.FORMAT_RGB8)
	for x in 128:
		for y in 128: checker.set_pixel(x,y,Color.WHITE if (x/4+y/4)%2==0 else Color.BLACK)
	var panel:=MeshInstance3D.new(); var mesh:=QuadMesh.new(); mesh.size=Vector2(3.2,3.2); panel.mesh=mesh
	var mat:=StandardMaterial3D.new(); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_texture=ImageTexture.create_from_image(checker); mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	panel.material_override=mat; game.rig.camera.add_child(panel); panel.position=Vector3(-3,-1,-9)
	game.atmosphere.material.set_shader_parameter("blur_strength",0.0)
	var sharp: Image=await capture()
	game.atmosphere.material.set_shader_parameter("blur_strength",1.0)
	var blurred: Image=await capture()
	var center: Vector2=game.rig.camera.unproject_position(panel.global_position)
	var region:=Rect2i(Vector2i(center)-Vector2i(25,25),Vector2i(50,50))
	var energy_sharp: float=edge_energy(sharp,region); var energy_blur: float=edge_energy(blurred,region)
	check(energy_sharp>.02 and energy_blur<energy_sharp*.8,"Rendered near-object detail visibly softens (%.3f to %.3f)" % [energy_sharp,energy_blur])
	var far_panel: MeshInstance3D=panel.duplicate(); game.rig.camera.add_child(far_panel); far_panel.position=Vector3(3,-1,-game.rig.camera.position.length())
	game.atmosphere.material.set_shader_parameter("blur_strength",0.0); sharp=await capture()
	game.atmosphere.material.set_shader_parameter("blur_strength",1.0); blurred=await capture()
	center=game.rig.camera.unproject_position(far_panel.global_position); region=Rect2i(Vector2i(center)-Vector2i(12,12),Vector2i(24,24))
	energy_sharp=edge_energy(sharp,region); energy_blur=edge_energy(blurred,region)
	check(energy_sharp>.02 and absf(energy_sharp-energy_blur)<.003,"Detail at the player's focus distance stays sharp (%.3f / %.3f)" % [energy_sharp,energy_blur])
	panel.queue_free(); far_panel.queue_free(); game.rig.global_position.y-=100; game.atmosphere.set_process(true)
