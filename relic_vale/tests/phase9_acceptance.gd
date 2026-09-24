extends "res://tests/phase9_stories.gd"

func finish() -> void:
	FileAccess.open("res://docs/PHASE_9_ACCEPTANCE_TESTS.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":results},"\t"))
	print("PHASE9_ACCEPTANCE_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)

func press_move(world_direction: Vector3) -> void:
	var input: Vector3=world_direction.rotated(Vector3.UP,-game.rig.yaw)
	Input.action_press("move_right",maxf(0,input.x)); Input.action_press("move_left",maxf(0,-input.x))
	Input.action_press("move_down",maxf(0,input.z)); Input.action_press("move_up",maxf(0,-input.z))

func release_move() -> void:
	for action in ["move_right","move_left","move_down","move_up","sprint"]: Input.action_release(action)

func walk_to(at: Dictionary,limit: int=1000) -> bool:
	var route:=PackedVector3Array()
	for frame in limit:
		var destination: Vector3=game.generator.position_of(at)
		destination.y=game.generator.landscape.height(Vector2(destination.x,destination.z))
		var delta: Vector3=destination-game.player.global_position; delta.y=0
		if delta.length()<1.4: release_move(); return true
		if frame%25==0: route=ValeResidents.travel_route(game.player,destination)
		while not route.is_empty() and Vector2(route[0].x-game.player.position.x,route[0].z-game.player.position.z).length()<.6: route.remove_at(0)
		if not route.is_empty(): delta=route[0]-game.player.position; delta.y=0
		press_move(delta.normalized()); await frames(1)
	release_move(); return false

func run() -> void:
	game=get_tree().current_scene; await frames(12)
	check(game.load_game(STORY_SAVE),"Load completed Act I in the actual game"); game.active_save_path=ValeSave.PATH
	game.player.god_mode=true; game.life.set_process(false); game.world_events.autonomous=false; game.hud.close_modal(); await frames(12)
	check(State.narrative.flags.get("act1_complete",false),"Full narrative fixture includes the ending")
	await camp(); State.life_data.minute=19*60; game.party.sync(); await frames(30)
	check(game.party.actors.size()==4,"All four companions appear together at camp")
	for id in game.party.actors:
		var actor: ValeCompanionActor=game.party.actors[id]
		check(actor.visual.animator.has_animation(actor.visual.clips.attack),"Retargeted combat animation is available: "+id)
		check(ResourceLoader.exists(ValeNarrative.companions[id].portrait),"Actual-model portrait imports: "+id)
	ValeNarrativeUI.roster(game.hud.ui,"bren"); await shot("company-details"); game.hud.close_modal()
	State.talk_npc("tarin"); await shot("camp-dialogue"); game.hud.close_modal()
	game.hud.ui.quest_filter="Main"; ValeJourneyPages.journal(game.hud.ui); await shot("main-journal"); game.hud.close_modal()
	ValeNarrativeUI.lore(game.hud.ui,"History"); await shot("lore-history"); game.hud.close_modal()
	ValeNarrativeUI.debug(game.hud.ui); await shot("story-debug"); game.hud.close_modal()
	check(game.party.set_active("bren"),"Select frontline companion from completed roster")
	await combat_roles()
	game.party.command("passive")
	game.party.equip("bren","Weapon",""); State.inventory.iron_sword=1; State.equip("iron_sword")
	check(not game.party.equip("bren","Weapon","iron_sword"),"Shared inventory cannot give away the player’s last worn sword")
	State.add_item("iron_sword",1)
	check(game.party.equip("bren","Weapon","iron_sword") and int(State.inventory.iron_sword)==1,"A second sword can be transferred without stripping the player")
	check(not game.party.equip("bren","Weapon","oak_bow"),"Melee companion refuses incompatible ranged equipment")
	var old_max: int=game.party.active().max_hp; State.level+=1; State.recalculate(); game.party.sync()
	check(game.party.active().max_hp>old_max,"Active companion stats update on player level growth")
	for faction in ["hearth","bough","veil"]:
		var npc_id: String=""
		for npc in State.npc_data:
			if State.merchant_data[ValeLife.category(npc)].faction==faction: npc_id=npc; break
		check(npc_id!="","Faction has an existing merchant: "+faction)
		if npc_id=="": continue
		State.life_data.reputation[faction]=30; State.coins=1000
		check(ValeLife.trade(npc_id,faction+"_accord_token"),"Completed charter unlocks real merchant equipment: "+faction)
		State.life_data.reputation[faction]=-60
		check(not ValeLife.trade(npc_id,faction+"_accord_token"),"Hostile reputation closes faction stock: "+faction)
		State.life_data.reputation[faction]=30
	await visit("reed_pass"); game.party.after_transition(); await frames(10)
	var start: Vector3=game.player.position
	var destination: Dictionary=game.generator.address(start+Vector3(14,0,8))
	check(await walk_to(destination),"Player and companion traverse terrain using movement input and obstacle routes")
	await frames(150)
	check(game.party.active().position.distance_to(game.player.position)<8,"Follower catches formation after a terrain route")
	var actor: ValeCompanionActor=game.party.active(); var address: Dictionary=game.generator.address(actor.global_position)
	for i in 8:
		game.generator.shift_origin(Vector2i(1 if i%2==0 else -1,1 if i%4<2 else -1)); await frames(2)
	check(game.party.active()==actor and actor.global_position.distance_to(game.generator.position_of(address))<3,"Eight floating-origin shifts preserve the live companion and logical position")
	game.party.command("wait"); var waiting: Vector3=actor.position
	game.player.position+=Vector3(35,0,0); game.player.position.y=game.generator.landscape.height(Vector2(game.player.position.x,game.player.position.z)); game.rig.snap(); await frames(70)
	check(actor.position.distance_to(waiting)<1,"Wait order holds even when the player moves off camera")
	# Perspective keeps more distant scenery in view than the old orthographic
	# camera. Put the waiting companion genuinely outside the frustum before
	# testing recovery; a visible companion must not teleport in front of us.
	var toward_actor: Vector3=actor.global_position-game.player.global_position
	game.rig.yaw=atan2(toward_actor.x,toward_actor.z); game.rig.target_yaw=game.rig.yaw; game.rig.snap()
	check(not game.rig.camera.is_position_in_frustum(actor.global_position+Vector3.UP),"Catch-up fixture is genuinely outside the perspective camera view")
	game.party.command("follow"); await frames(150)
	check(actor.position.distance_to(game.player.position)<8,"Off-camera catch-up recovers a distant follower")
	game.generator.teleport_logical(1000000000,-1000000000); await frames(25)
	check(game.party.active().position.distance_to(game.player.position)<7 and game.party.actors.size()==1,"Billion-chunk travel keeps one active companion and unloads the camp roster")
	await camp(); game.party.command("passive")
	game.mounts.acquire(true); game.player.attack_timer=0
	check(game.mounts.call_mount(),"Call an owned horse while accompanied")
	if is_instance_valid(game.mounts.actor):
		game.player.position=game.mounts.actor.global_position+Vector3(.5,0,0)
		check(game.mounts.mount(),"Mount with an active companion")
		var ridden: Dictionary=game.generator.address(game.player.position+Vector3(8,0,6))
		check(await walk_to(ridden,600),"Mounted input travel shares the companion follow system")
		await frames(90); check(game.party.active().position.distance_to(game.player.position)<12,"Companion follows mounted travel")
		await shot("mounted-company"); game.mounts.park()
	await camp(); await game.interiors.enter(State.camp_data.buildings["0"]); await frames(50)
	check(game.party.active().position.distance_to(game.player.position)<7,"Active companion enters the player’s home")
	await shot("companion-interior"); game.interiors.leave(); await frames(50)
	check(game.party.active().position.distance_to(game.player.position)<7,"Active companion exits home without blocking the doorway")
	game.party.active().invulnerability=0; game.party.active().take_damage(99999); await frames(10)
	check(game.party.active().downed,"Companion can be downed without permanent loss")
	game.player.position=game.party.active().position+Vector3(0,0,1.3)
	check(game.party.active().revive(),"Manual nearby recovery succeeds after combat")
	var seed: int=State.world_seed; var positions: Dictionary=State.narrative.locations.duplicate(true)
	State.narrative.locations.clear()
	for id in ValeNarrative.locations:
		var at: Dictionary=game.narrative.location_address(id)
		if ValeNarrative.locations[id].get("fixed",false): continue
		var plan: ValeRegionPlan=game.generator.planner(at.x+","+at.z)
		check(plan.water_distance(Vector2(at.local[0],at.local[2]))>=7,"New authored site selects dry ground: "+id)
	State.narrative.locations=positions
	check(State.world_seed==seed,"Authored placement preserves the procedural world seed")
	await finish()
