extends "res://tests/phase9_stories.gd"
const EVENT_SAVE="user://phase9-events.json"

func finish() -> void:
	var suffix: String="EVENTS_RELOAD" if "--phase9-events-reload" in OS.get_cmdline_user_args() else "EVENTS"
	FileAccess.open("res://docs/PHASE_9_"+suffix+"_TESTS.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":results},"\t"))
	print("PHASE9_EVENTS_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)

func tick() -> void:
	game.hud.close_modal(); game.world_events._process(1); await frames(3)

func candidate(escort: bool=false) -> Dictionary:
	for x in range(-20,55,3):
		for z in range(-20,55,3):
			var p:=Vector3(x,0,z); p.y=game.generator.landscape.height(Vector2(x,z))
			var at: Dictionary=game.generator.address(p)
			var plan: ValeRegionPlan=game.generator.planner(at.x+","+at.z)
			if not plan.clear(Vector2(at.local[0],at.local[2]),3) or plan.water_distance(Vector2(at.local[0],at.local[2]))<4: continue
			if not game.generator.clear_for_prop(Vector2(x,z),{},3): continue
			if escort and game.world_events.escort_destination(at).is_empty(): continue
			return at
	return {}

func approach(id: String) -> ValeInteractable:
	var row: Dictionary=State.life_data.events[id]
	game.generator.teleport_logical(int(row.address.x),int(row.address.z),ValeSave.vector(row.address.local)+Vector3(0,.1,2))
	await frames(10); await tick()
	var contact: ValeInteractable=game.world_events.scenes[id].get_node("Contact")
	game.player.position=contact.global_position+Vector3(0,.1,1.5); game.rig.snap(); await frames(2)
	return contact

func run() -> void:
	game=get_tree().current_scene; await frames(12)
	var reload: bool="--phase9-events-reload" in OS.get_cmdline_user_args()
	check(game.load_game(EVENT_SAVE if reload else SAVE),"Load isolated event fixture"); game.active_save_path=ValeSave.PATH
	game.player.god_mode=true; game.life.set_process(false); game.world_events.autonomous=false; game.hud.close_modal(); await frames(12)
	if reload:
		check(ValeSave.valid(ValeSave.snapshot(game.player.position)),"Event ledger validates in a fresh process")
		for kind in ValeWorldEvents.definitions:
			check(State.narrative.flags.get(ValeWorldEvents.definitions[kind].outcome,false),"Event consequence survives: "+kind)
		var id: String=State.narrative.flags.event_fixture_id
		check(State.life_data.events[id].state=="active","Unresolved encounter survives process exit")
		await approach(id)
		check(game.world_events.scenes.has(id),"Unresolved event reconstructs from logical address")
		check(game.world_events.remaining(State.life_data.events[id])==1,"Only unresolved encounter enemy respawns")
		await finish(); return
	await camp(); game.party.command("passive")
	check(ValeWorldEvents.definitions.size()==8,"Eight authored event situations are installed")
	State.narrative.flags.act1_complete=true
	for kind in ValeWorldEvents.definitions:
		await camp()
		var at: Dictionary=candidate(kind=="lost_traveler")
		check(not at.is_empty(),"Find clear physical encounter ground: "+kind)
		if at.is_empty(): continue
		var id: String=game.world_events.spawn(kind,at,true)
		check(id!="","Create encounter: "+kind)
		if id=="": continue
		var row: Dictionary=State.life_data.events[id]
		var data: Dictionary=ValeWorldEvents.definitions[kind]
		check(not game.world_events.complete(id),"Cannot resolve an encounter remotely: "+kind)
		var contact: ValeInteractable=await approach(id)
		check(row.discovered,"Approaching discovers the temporary event: "+kind)
		for i in data.enemies.size(): await battle(id+"/enemy/"+str(i))
		check(game.world_events.remaining(row)==0,"Encounter combat requirements satisfied: "+kind)
		for item in data.cost:
			State.inventory.erase(item)
			check(not game.world_events.complete(id),"Required supplies enforced: "+kind)
			State.add_item(item,int(data.cost[item]))
		if kind=="lost_traveler":
			contact.interact(game.player); await frames(2)
			var buttons: Array=game.hud.ui.body.find_children("*","Button",true,false)
			for button in buttons:
				if button.text==data.action: button.pressed.emit(); break
			check(int(row.stage)==1,"Escort begins through its dialogue action")
			var destination: Vector3=game.generator.position_of(row.destination)
			for frame in 1800:
				if row.state!="active": break
				var direction: Vector3=destination-game.player.position; direction.y=0
				if contact.global_position.distance_to(game.player.position)<4 and direction.length()>1:
					game.player.position+=direction.normalized()*.055
					game.player.position.y=game.generator.landscape.height(Vector2(game.player.position.x,game.player.position.z))+.05
				await frames(1)
			check(row.state=="completed","Traveler walks to the road and resolves the escort")
		else:
			game.player.position=contact.global_position+Vector3(0,.1,1.5)
			check(game.world_events.complete(id),"Complete encounter with physical conditions: "+kind)
		for item in data.cost: check(int(State.inventory.get(item,0))==0,"Required supplies consumed once: "+kind)
		check(State.narrative.flags.get(data.outcome,false),"Persistent consequence recorded: "+kind)
		var coins: int=State.coins; var approval: int=State.narrative.companions.bren.approval
		check(not game.world_events.complete(id) and State.coins==coins and State.narrative.companions.bren.approval==approval,"Resolved event cannot duplicate rewards: "+kind)
		if kind=="broken_cart": game.rig.snap(); game.world_events.interact(id); await shot("road-story"); game.hud.close_modal()
		await tick()
	await camp()
	var at: Dictionary=candidate()
	State.life_data.minute=12*60; State.life_data.weather="Clear"
	check(not game.world_events.context_allows("lantern_vigil",at),"Night encounter excluded during the day")
	check(not game.world_events.context_allows("rain_shelter",at),"Rain encounter excluded in clear weather")
	State.life_data.reputation.bough=-70
	check(not game.world_events.context_allows("warden_patrol",at),"Hostile Wardens refuse witness parley")
	State.life_data.reputation.bough=30
	var visible: Dictionary=game.generator.address(game.player.position); game.rig.snap()
	check(game.world_events.on_camera(game.player.position) and game.world_events.spawn("field_medicine",visible)=="","Production spawning rejects a visible location")
	var offscreen: Dictionary={}
	# Quiet ground without a road is allowed to produce no event. Try several road tiles.
	for chunk in [Vector2i(3,0),Vector2i(5,0),Vector2i(0,3),Vector2i(-3,0)]:
		game.generator.teleport_logical(chunk.x,chunk.y); await frames(30); game.rig.snap()
		offscreen=game.world_events.find_site("field_medicine")
		if not offscreen.is_empty(): break
	check(not offscreen.is_empty(),"Production site search finds a valid road outside the view")
	if not offscreen.is_empty():
		check(not game.world_events.on_camera(game.generator.position_of(offscreen)) and game.world_events.context_allows("field_medicine",offscreen),"Production candidate satisfies camera and world context")
		var natural: String=game.world_events.spawn("field_medicine",offscreen)
		check(natural!="","Contextual production spawn succeeds"); game.world_events.expire(natural)
	await camp(); at=candidate()
	var first: String=game.world_events.spawn("broken_cart",at,true)
	var second: String=game.world_events.spawn("road_ambush",at,true)
	check(first!="" and second!="" and game.world_events.spawn("veil_echo",at,true)=="","Two unresolved encounters is a hard budget")
	State.life_data.events[first].expires=ValeCamp.now(); await tick()
	check(State.life_data.events[first].state=="expired","Unresolved event expires at its deadline")
	var coins: int=State.coins
	check(not game.world_events.complete(first) and State.coins==coins,"Expired encounter cannot grant a late reward")
	await approach(second); await battle(second+"/enemy/0")
	check(not State.defeated_unique.has(second+"/enemy/0"),"Temporary enemies do not grow the global unique-enemy ledger")
	State.narrative.flags.event_fixture_id=second
	for i in 70:
		var id: String=game.world_events.spawn("broken_cart",at,true)
		if id!="": game.world_events.expire(id)
	check(game.world_events.records().size()<=64 and State.life_data.events.has(second),"Old event records prune while preserving unresolved encounters")
	var valid: Dictionary=ValeSave.snapshot(game.player.position)
	check(ValeSave.valid(valid),"Combined event and companion snapshot validates")
	var bad: Dictionary=valid.duplicate(true); bad.narrative.active="missing"
	check(not ValeSave.valid(bad),"Reject nonexistent active companion")
	bad=valid.duplicate(true); bad.narrative.companions.bren.approval=INF
	check(not ValeSave.valid(bad),"Reject nonfinite relationship state")
	bad=valid.duplicate(true); bad.life.events[second].walker_address={"x":"bad","z":"0","local":[0,0,0]}
	check(not ValeSave.valid(bad),"Reject malformed event logical address")
	bad=valid.duplicate(true); bad.life.events[second].defeated[second+"/enemy/99"]=true
	check(not ValeSave.valid(bad),"Reject nonexistent defeated event enemy")
	check(game.save_game(false,EVENT_SAVE),"Write isolated partially resolved event fixture")
	await finish()
