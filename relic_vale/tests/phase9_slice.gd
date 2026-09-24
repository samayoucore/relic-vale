extends Node
const SAVE="user://phase9-slice.json"
var game: Node
var passed: int=0
var failed: int=0
var results: Array=[]

func _ready() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func check(ok: bool,message: String) -> void:
	if ok: passed+=1
	else: failed+=1
	results.append({"pass":ok,"check":message}); print("PHASE9 ","PASS " if ok else "FAIL ",message)
func finish() -> void:
	var suffix: String="RELOAD" if "--phase9-reload" in OS.get_cmdline_user_args() else "SLICE"
	if "--phase9-portraits" in OS.get_cmdline_user_args(): suffix="PORTRAITS"
	var file:=FileAccess.open("res://docs/PHASE_9_"+suffix+"_TESTS.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":results},"\t")); file.close()
	print("PHASE9_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	for frame in 3: await get_tree().process_frame
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase9-"+name+".png")
func visit(id: String) -> void:
	game.hud.close_modal()
	var at: Dictionary=game.narrative.location_address(id)
	game.generator.teleport_logical(int(at.x),int(at.z),ValeSave.vector(at.local)+Vector3(0,.1,2))
	await frames(65); game.rig.snap()
func camp() -> void:
	game.hud.close_modal()
	var at: Dictionary=State.camp_data.address
	game.generator.teleport_logical(int(at.x),int(at.z),ValeSave.vector(at.local)+Vector3(0,.1,4))
	await frames(65); game.party.after_transition(); await frames(2)
func choose(key: String) -> void:
	var choices: Array=ValeNarrative.dialogues.get(game.narrative.dialogue_id,{}).get("choices",[])
	for i in choices.size():
		if choices[i].id==key: check(game.narrative.choose(i),"Choose dialogue: "+key); await frames(2); return
	check(false,"Dialogue choice exists: "+key)
func object_at(location: String,id: String) -> void:
	for node in game.narrative.scenes[location].get_children():
		if node is ValeInteractable and node.get_meta("story_object","")==id:
			game.player.position=node.global_position+Vector3(0,.1,1); await frames(2)
			check(game.narrative.inspect_object(location,id),"Inspect physical object: "+id); game.hud.close_modal(); return
	check(false,"Object exists: "+id)
func portraits() -> void:
	var viewport:=SubViewport.new(); viewport.size=Vector2i(300,360); viewport.own_world_3d=true; viewport.transparent_bg=true; viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; viewport.msaa_3d=Viewport.MSAA_4X; add_child(viewport)
	var root:=Node3D.new(); viewport.add_child(root)
	var camera:=Camera3D.new(); root.add_child(camera); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=1.55; camera.position=Vector3(.5,1.4,3); camera.look_at(Vector3(0,1.13,0)); camera.current=true
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-35,-30,0); sun.light_energy=1.35; root.add_child(sun)
	var fill:=DirectionalLight3D.new(); fill.rotation_degrees=Vector3(-20,140,0); fill.light_energy=.65; root.add_child(fill)
	var environment:=WorldEnvironment.new(); var env:=Environment.new(); env.background_mode=Environment.BG_COLOR; env.background_color=Color(0,0,0,0); env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("ddd9c6"); env.ambient_light_energy=.6; environment.environment=env; root.add_child(environment)
	DirAccess.make_dir_recursive_absolute("res://assets/ui/phase9/portraits")
	for id in ValeNarrative.companions:
		var visual:=ValeCreatureVisual.new(); root.add_child(visual); visual.setup("companion",1.85,ValeNarrative.companions[id].model)
		visual.companion_role(ValeNarrative.companions[id].role)
		visual.animator.advance(.2); await frames(5); RenderingServer.force_draw(false)
		check(viewport.get_texture().get_image().save_png(ValeNarrative.companions[id].portrait)==OK,"Render actual model portrait: "+id)
		root.remove_child(visual); visual.queue_free()
	viewport.queue_free()

func run() -> void:
	game=get_tree().current_scene; await frames(15)
	if "--phase9-portraits" in OS.get_cmdline_user_args(): await portraits(); await finish(); return
	if "--phase9-reload" in OS.get_cmdline_user_args():
		check(game.load_game(SAVE),"Fresh process reads version 9 companion save"); game.active_save_path=ValeSave.PATH; await frames(65)
		check(State.completed_quests.has("bren_oath") and State.narrative.flags.get("cinder_outcome")=="shelter","Personal arc and chosen outcome persist")
		check(State.narrative.companions.bren.recruited and State.narrative.active=="bren","Recruited and active identity persist")
		check(State.narrative.companions.bren.equipment.Accessory=="bren_watch_token","Companion equipment persists without duplicate inventory")
		check(is_instance_valid(game.party.active()),"Active companion reconstructs in fresh process")
		await visit("cinder_watch"); check(game.narrative.scenes.cinder_watch.get_meta("variant")=="shelter","Restored location reconstructs chosen shelter")
		check(State.defeated_unique.has("cinder_guard"),"Personal enemy does not respawn after reload")
		await finish(); return
	game.new_world(20260907); game.player.god_mode=true; game.life.set_process(false); await frames(65)
	check(ValeNarrative.companions.has("bren"),"First companion remains available for end-to-end regression")
	check(is_instance_valid(game.party.actors.get("bren")),"Bren exists physically by the east road")
	await visit("bren_watch"); State.talk_npc("bren"); await choose("help")
	check(State.quest_progress.get("bren_recruit")==0,"Recruitment uses the existing quest ledger")
	check(not game.narrative.inspect_object("dispatch","dispatch"),"Distant story object cannot be claimed remotely")
	await visit("dispatch"); await object_at("dispatch","dispatch")
	check(State.quest_progress.get("bren_recruit")==1,"Dispatch advances recruitment")
	await visit("bren_watch"); State.talk_npc("bren"); await choose("welcome"); await frames(5)
	check(State.narrative.companions.bren.recruited and State.narrative.active=="bren","Bren joins and becomes the sole active companion")
	var actor: ValeCompanionActor=game.party.active(); game.party.command("passive")
	var start: Vector3=actor.global_position
	game.player.position+=Vector3(10,0,0); await frames(180)
	check(actor.global_position.distance_to(start)>2 and actor.global_position.distance_to(game.player.global_position)<7,"Companion follows across terrain")
	game.party.command("wait"); start=actor.global_position; game.player.position+=Vector3(7,0,0); await frames(90)
	check(actor.global_position.distance_to(start)<1.1,"Wait holds position")
	game.party.command("follow"); game.party.command("aggressive"); game.party.after_transition()
	var enemy: Mossling=load("res://scenes/characters/Enemy.tscn").instantiate(); enemy.position=actor.position+Vector3(1.5,0,0); enemy.set_meta("archetype","elite"); enemy.set_meta("elite_modifier","vampiric"); game.world.add_child(enemy); enemy.hp=250; enemy.max_hp=250
	State.hp=roundi(State.max_hp*.55); await frames(220)
	check(enemy.hp<250,"Companion damages a real elite enemy")
	check(int(actor.ability_uses.get("shield_rush",0))>0 and int(actor.ability_uses.get("hold_line",0))>0,"Both distinctive combat abilities activate")
	check(enemy.combat_target==actor,"Hold the Line draws enemy attacks")
	check(actor.hp<actor.max_hp,"Enemy attacks can damage companion")
	check(State.hp==roundi(State.max_hp*.55),"Friendly companion attacks do not damage player")
	enemy.take_damage(99999); await frames(3)
	for other in get_tree().get_nodes_in_group("enemies"):
		if other.global_position.distance_to(actor.position)<14: other.queue_free()
	await frames(45); actor.take_damage(99999)
	check(actor.downed and actor.hp==0,"Companion enters downed state instead of permanent death")
	game.player.position=actor.position+Vector3(1,0,0); check(actor.revive(),"Nearby player can revive after combat")
	check(actor.hp>0 and not actor.downed,"Revival restores a living companion")
	game.party.command("passive")
	var address: Dictionary=await game.phase7_find_clearing(); check(not address.is_empty(),"Find legal camp site for personal conversations")
	check(game.camp.establish(address),"Establish actual camp")
	await camp(); State.talk_npc("bren"); await choose("letters"); await choose("listen")
	check(State.quest_progress.get("bren_letters")==1,"Camp conversation begins the first personal quest")
	await visit("cinder_watch"); await object_at("cinder_watch","watch_letters")
	await camp(); State.talk_npc("bren"); await choose("return_letters"); await choose("kind")
	check(State.completed_quests.has("bren_letters"),"Letters quest resolves through camp return")
	State.talk_npc("bren"); await choose("watchfire")
	await visit("cinder_watch"); game.party.command("aggressive"); game.party.after_transition()
	var guard: Mossling
	for node in game.narrative.scenes.cinder_watch.get_children():
		if node is Mossling: guard=node
	check(is_instance_valid(guard),"Cinder Watch contains a persistent guard encounter")
	if guard:
		game.player.position=guard.global_position+Vector3(1.5,0,0); game.party.after_transition()
		for i in 30:
			if guard.dead: break
			await frames(60)
		check(guard.dead,"Companion wins the quest encounter through normal combat")
	await object_at("cinder_watch","watch_brazier")
	await camp(); State.talk_npc("bren"); await choose("return_fire"); await choose("consider")
	State.talk_npc("bren"); await choose("oath"); await shot("bren-decision"); await choose("shelter")
	check(State.completed_quests.has("bren_oath"),"All three personal quests complete through authored dialogue")
	check(State.narrative.flags.get("cinder_outcome")=="shelter" and ValeLife.reputation("hearth")<0,"Choice records persistent faction consequence")
	var rep: int=ValeLife.reputation("hearth"); game.narrative.show_dialogue("bren_oath_choice")
	check(not game.narrative.choose(1) and ValeLife.reputation("hearth")==rep,"Opposite choice cannot replay consequence from stale dialogue")
	game.hud.close_modal()
	check(game.party.equip("bren","Accessory","bren_watch_token"),"Equip the personal story reward")
	check(int(State.inventory.get("bren_watch_token",0))==0,"Equipped companion item leaves shared inventory")
	State.level=7; game.party.sync(); check(State.narrative.companions.bren.level==7,"Companion catches up with player level")
	game.generator.teleport_logical(90000000,-70000000); await frames(70)
	check(game.party.active().global_position.distance_to(game.player.global_position)<7,"Companion survives distant logical teleport")
	await visit("cinder_watch"); check(game.narrative.scenes.cinder_watch.get_meta("variant")=="shelter","Authored site visibly becomes a shelter after branch")
	check(not game.narrative.scenes.cinder_watch.get_children().any(func(n): return n is Mossling and not n.dead),"Defeated story enemy stays absent after unload")
	await camp(); State.camp_data.level=4; State.camp_data.tier=4; game.camp.sync_visual(true); await frames(30)
	await game.interiors.enter(State.camp_data.buildings["0"]); await frames(70)
	check(game.party.active().global_position.distance_to(game.player.global_position)<7,"Companion follows into a camp interior")
	game.interiors.leave(); await frames(70)
	check(game.party.active().global_position.distance_to(game.player.global_position)<7,"Companion returns outside with player")
	ValeNarrativeUI.roster(game.hud.ui,"bren"); await shot("bren-company"); game.hud.close_modal()
	game.party.active().record_position()
	var snapshot: Dictionary=ValeSave.snapshot(game.player.position)
	check(ValeSave.valid(snapshot),"Version 9 snapshot validates")
	var bad: Dictionary=snapshot.duplicate(true); bad.narrative.companions.bren.approval="Loyal"
	check(not ValeSave.valid(bad),"Malformed approval is rejected")
	bad=snapshot.duplicate(true); bad.narrative.active="missing"
	check(not ValeSave.valid(bad),"Unknown active companion is rejected")
	bad=snapshot.duplicate(true); bad.version=8; bad.erase("narrative")
	check(ValeSave.valid(bad),"Version 8 save remains accepted")
	check(game.save_game(false,SAVE),"Write isolated companion fixture")
	await finish()
