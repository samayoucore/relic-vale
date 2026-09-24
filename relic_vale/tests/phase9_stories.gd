extends "res://tests/phase9_slice.gd"
const STORY_SAVE="user://phase9-stories.json"

func finish() -> void:
	var suffix: String="STORIES_RELOAD" if "--phase9-stories-reload" in OS.get_cmdline_user_args() else "STORIES"
	var file:=FileAccess.open("res://docs/PHASE_9_"+suffix+"_TESTS.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":results},"\t")); file.close()
	print("PHASE9_STORIES_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)

func visit(id: String) -> void:
	game.hud.close_modal()
	var at: Dictionary=game.narrative.location_address(id)
	game.generator.teleport_logical(int(at.x),int(at.z),ValeSave.vector(at.local)+Vector3(0,.1,2))
	await frames(10); game.narrative._process(1); game.party._process(1); await frames(2); game.rig.snap()

func camp() -> void:
	game.hud.close_modal()
	var at: Dictionary=State.camp_data.address
	game.generator.teleport_logical(int(at.x),int(at.z),ValeSave.vector(at.local)+Vector3(0,.1,4))
	await frames(12); game.camp.sync_visual(); game.party._process(1); game.party.after_transition(); await frames(2)

func talk_contact(id: String) -> void:
	if ValeNarrative.companions.has(id):
		if State.narrative.companions[id].recruited: await camp()
		else: await visit(ValeNarrative.companions[id].location)
	else: await visit("willowmere_well" if id=="rowan" else ("shrine_contact" if id=="keeper" else "three_promises"))
	for node in get_tree().get_nodes_in_group("interactables"):
		if (node.kind=="npc" and node.npc_id==id) or node.get_meta("companion","")==id:
			game.player.position=node.global_position+Vector3(0,.1,1.3); await frames(2); node.interact(game.player); return
	check(false,"Physical contact is available: "+id)

func matching_choice(event: String,target: String,next: String="") -> bool:
	var row: Dictionary=ValeNarrative.dialogues.get(game.narrative.dialogue_id,{})
	for i in row.get("choices",[]).size():
		var choice: Dictionary=row.choices[i]
		if not game.narrative.allowed(choice.get("conditions",[])): continue
		var matches: bool=next!="" and choice.get("next","")==next
		for effect in choice.get("effects",[]):
			if effect.type=="event" and effect.event==event and effect.id==target: matches=true
		if matches: check(game.narrative.choose(i),"Follow authored dialogue: "+str(choice.id)); await frames(2); return true
	return false

func start_quest(id: String) -> void:
	if State.quest_progress.has(id): return
	var q: Dictionary=State.quest_data[id]
	await talk_contact(q.npc)
	var row: Dictionary=ValeNarrative.dialogues.get(game.narrative.dialogue_id,{})
	for i in row.get("choices",[]).size():
		for effect in row.choices[i].get("effects",[]):
			if effect.type=="start" and effect.id==id:
				check(game.narrative.choose(i),"Accept authored quest: "+id); await frames(2); return
	check(false,"Quest offer exists: "+id)

func battle(id: String) -> void:
	var target: Mossling
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.persistent_id==id: target=enemy; break
	if not target:
		check(State.defeated_unique.has(id),"Encounter is already resolved: "+id); return
	game.hud.close_modal(); State.equip("iron_sword") if State.inventory.has("iron_sword") else State.equip("rustic_sword")
	for i in 90:
		if not is_instance_valid(target) or target.dead: break
		var point: Vector3=target.global_position+Vector3(0,.05,1.2)
		if target.has_meta("arena"):
			var bounds: Rect2=target.get_meta("arena").grow(-1.5)
			point.x=clampf(point.x,bounds.position.x,bounds.end.x); point.z=clampf(point.z,bounds.position.y,bounds.end.y)
		game.player.position=point; game.player.facing=(target.global_position-point).normalized(); game.player.velocity=Vector3.ZERO
		game.rig.snap()
		game.player.attack(); await frames(42)
		if i%15==0 and is_instance_valid(target): print("PHASE9 BATTLE ",id," hp=",target.hp," hero=",game.player.position," enemy=",target.global_position," weapon=",State.equipment.Weapon," modal=",State.modal)
	check((is_instance_valid(target) and target.dead) or State.defeated_unique.has(id),"Defeat through timed primary attacks: "+id)

func play_quest(id: String) -> void:
	if State.completed_quests.has(id): return
	await start_quest(id)
	if not State.quest_progress.has(id): return
	var q: Dictionary=State.quest_data[id]
	for attempt in 12:
		if State.completed_quests.has(id): break
		var s: Dictionary=game.narrative.objective(id)
		var before: int=int(State.quest_progress[id])
		match s.type:
			"interact":
				await visit(s.location)
				for object in ValeNarrative.locations[s.location].get("objects",[]):
					if object.id!=s.target: continue
					for rule in object.get("requires",[]):
						if rule.type=="item": State.add_item(rule.id,int(rule.value))
				await object_at(s.location,s.target)
			"defeat":
				await visit(s.location)
				if s.target=="story_oath_vault/guardian":
					await object_at("oath_vault","vault_door"); await frames(18); game.party._process(1)
					check(game.party.active().position.distance_to(game.player.position)<8,"Active companion enters authored dungeon")
				await battle(s.target)
			"talk":
				await talk_contact(q.npc if s.get("camp",false) else s.target)
				check(await matching_choice("talk",s.target),"Talk objective is reachable: "+id)
				game.hud.close_modal()
			"choice":
				if s.target=="watch_supplies":
					State.add_item("wood",6); State.add_item("wild_herb",3); await talk_contact("bren")
				else: await talk_contact(q.npc)
				if game.narrative.dialogue_id!=s.target: await matching_choice("choice",s.target,s.target)
				if not State.completed_quests.has(id): check(await matching_choice("choice",s.target),"Consequential choice is reachable: "+id)
			"reach":
				for rule in s.get("conditions",[]):
					if rule.type=="active":
						await camp(); check(game.party.set_active(rule.id),"Select required story companion: "+rule.id)
				await visit(s.location); game.narrative._process(1); await frames(3)
			"collect": State.add_item(s.target,int(s.get("count",1))); game.narrative.reconcile(id)
			"camp","recruit": game.narrative.reconcile(id)
			_: check(false,"Supported story objective "+s.type)
		if int(State.quest_progress[id])==before:
			check(false,"Quest advances from stage %d: %s" % [before,id]); break
	check(State.completed_quests.has(id),"Finish authored quest: "+id)
	game.hud.close_modal(); check(game.save_game(false,STORY_SAVE),"Save narrative checkpoint: "+id)

func combat_roles() -> void:
	await camp()
	for id in ["tarin","ilyra","sera"]:
		check(game.party.set_active(id),"Switch active role: "+id); game.party.command("aggressive")
		var actor: ValeCompanionActor=game.party.active()
		check(get_tree().get_nodes_in_group("combat_allies").size()==2,"Only player and one companion are combat allies")
		var enemy: Mossling=load("res://scenes/characters/Enemy.tscn").instantiate(); enemy.set_meta("archetype","elite"); enemy.set_meta("elite_modifier","vampiric"); enemy.position=actor.position+Vector3(0,0,5); game.world.add_child(enemy); enemy.hp=500; enemy.max_hp=500
		State.hp=30; game.player.statuses.apply("poison",5,2)
		await frames(220)
		check(enemy.hp<500,"Real ranged/support primary attack hits: "+id)
		for ability in ValeNarrative.companions[id].abilities: check(int(actor.ability_uses.get(ability.id,0))>0,"Role ability activates: "+ability.id)
		if id=="sera": check(State.hp>30 and not game.player.statuses.has("poison"),"Sera heals and cleanses the player")
		enemy.queue_free(); await frames(2); game.party.command("passive")
	check(game.party.set_active("bren"),"Restore Bren after combat-role checks")

func run() -> void:
	game=get_tree().current_scene; await frames(12)
	var reload: bool="--phase9-stories-reload" in OS.get_cmdline_user_args()
	var resume: bool="--phase9-stories-resume" in OS.get_cmdline_user_args()
	check(game.load_game(STORY_SAVE if reload or resume else SAVE),"Load isolated story fixture"); game.active_save_path=ValeSave.PATH
	game.player.god_mode=true; game.life.set_process(false); game.world_events.autonomous=false; game.hud.close_modal(); await frames(12)
	check(ValeNarrative.companions.size()==4,"Four distinct companions are installed")
	if reload:
		check(State.narrative.companions.values().all(func(row): return row.recruited),"All recruited identities survive fresh load")
		check(State.narrative.flags.get("act1_complete",false),"Act I ending survives fresh load")
		for id in State.quest_data:
			if State.quest_data[id].type=="narrative": check(State.completed_quests.has(id),"Completed quest survives fresh process: "+id)
		check(ValeSave.valid(ValeSave.snapshot(game.player.position)),"Expanded save validates after load")
		await finish(); return
	for id in ["tarin","ilyra","sera"]:
		await play_quest(id+"_recruit")
		for quest_id in ValeNarrative.companions[id].personal: await play_quest(quest_id)
	await combat_roles()
	for n in range(1,11):
		await play_quest("act1_%02d" % n)
		if n==4:
			for faction in ["hearth","bough","veil"]:
				for index in range(1,4): await play_quest(faction+"_story_"+str(index))
	check(State.narrative.flags.get("act1_complete",false),"All ten chapters resolve the first story arc")
	check(State.life_data.unlocks.get("hearth_accord",false) and State.life_data.unlocks.get("bough_accord",false) and State.life_data.unlocks.get("veil_accord",false),"Three faction chains unlock their accords")
	await camp(); ValeNarrativeUI.roster(game.hud.ui); await shot("all-companions"); game.hud.close_modal()
	check(game.save_game(false,STORY_SAVE),"Write complete expanded story fixture")
	await finish()
