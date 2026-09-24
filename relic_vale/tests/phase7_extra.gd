extends "res://tests/phase7_test.gd"
func finish() -> void:
	print("PHASE7_EXTRA_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)
func click_at(position: Vector2,button_index: int=MOUSE_BUTTON_LEFT) -> void:
	var motion:=InputEventMouseMotion.new(); motion.position=position; Input.parse_input_event(motion)
	await frames(2)
	for down in [true,false]:
		var event:=InputEventMouseButton.new(); event.button_index=button_index; event.position=position; event.pressed=down; Input.parse_input_event(event); await frames(3)
func find_button(node: Node,title: String) -> Button:
	if node is Button and node.text.begins_with(title): return node
	for child in node.get_children():
		var found: Button=find_button(child,title)
		if found: return found
	return null
func press(title: String) -> void:
	var button: Button=find_button(game.hud,title)
	check(button!=null,"UI button: "+title)
	if button: await click_at(button.get_global_rect().get_center())
func run() -> void:
	game=get_tree().current_scene; await frames(12); game.player.god_mode=true
	check(game.load_game(SAVE),"Load completed camp for extended validation")
	game.active_save_path=ValeSave.PATH
	await frames(10); game.hud.close_modal()
	var camp: ValeCamp=game.camp
	camp.advance(4000); game.life.set_time(10); camp.resolve(); camp.sync_visual(true)
	await frames(8)
	var worker: Dictionary=State.camp_data.workers.values()[0]
	var actor: ValeInteractable=camp.actors[worker.id]
	game.player.position=camp.visual.position+Vector3(7,0,5)
	var old_position: Vector3=actor.position
	await frames(240)
	check(actor.position.distance_to(old_position)>1,"Resident physically walks between camp activities")
	check(actor.sprite.is_playing(),"Resident uses existing animated character frames")
	game.life.set_time(23); await frames(900)
	check(not actor.visible and worker.activity=="Sleeping","Resident reaches shelter and sleeps at night")
	if worker.has("home"):
		var home: Dictionary=State.life_data.settlements.player_camp.buildings[worker.home]
		await game.interiors.enter(home); await frames(12)
		check(game.interiors.occupants.has(worker.id),"Veteran occupies the assigned house interior at night")
		await shot("veteran-home"); await game.interiors.leave()
	game.life.set_time(10); await frames(10); State.modal=true
	# Actual right-click and pointer-driven marker editor.
	game.hud.ui.map_page(); await frames(16)
	var atlas: ValeAtlas=game.hud.ui.body.get_child(0)
	var before: int=State.map_data.markers.size()
	await click_at(atlas.get_global_rect().get_center()+Vector2(16,0),MOUSE_BUTTON_RIGHT)
	check(State.map_data.markers.size()==before+1 and game.hud.modal_kind=="marker","Right click discovered terrain opens marker editor")
	var editor: LineEdit=game.hud.ui.body.find_children("*","LineEdit",true,false)[0]; editor.text="QA waypoint"
	await press("Save name"); check(game.hud.modal_kind=="map" and State.map_data.markers.values().any(func(m): return m.name=="QA waypoint"),"Marker rename returns to atlas with pointer input")
	await shot("atlas-final")
	atlas=game.hud.ui.body.get_child(0)
	atlas.center_x=1000000000002; atlas.center_z=-999999999998; atlas.pan=Vector2(13,-9)
	await frames(2)
	var address: Dictionary=atlas.address_at(Vector2(270,175))
	var pixel: Vector2=atlas.point(int(address.x),int(address.z),Vector2(address.local[0],address.local[2]))
	check(pixel.distance_to(Vector2(270,175))<.01,"Huge positive and negative map coordinates round trip")
	game.hud.close_modal(); State.modal=true
	# Freeze wall-clock simulation while evaluating the independent economy deterministically.
	camp.clear_visual(); camp.set_process(false)
	var saved: Dictionary=State.camp_data.duplicate(true)
	State.camp_data.active={}; State.camp_data.completed=[]; State.camp_data.workers={worker.id:worker.duplicate(true)}
	State.camp_data.workers[worker.id].assignment=""
	State.camp_data.level=1; State.camp_data.tier=1; State.camp_data.xp=0; State.camp_data.upgrade_pending=false
	for resource in ["food","materials","gold"]: State.camp_data[resource]=0
	camp.refresh_board(false)
	var purse: int=State.coins; var player_xp: int=State.xp; var completed: int=0
	for i in 240:
		if int(State.camp_data.level)==5: break
		var id: String=["forage","stone","supply"][i%3]
		var task: Dictionary=State.camp_data.offers.filter(func(offer): return offer.id==id)[0]
		if camp.assign(task.contract,[worker.id]): camp.advance(float(task.minutes)+1); completed+=1
		if camp.upgrade_reason().is_empty(): camp.upgrade()
	check(int(State.camp_data.level)==5,"One resident can fund every camp upgrade without donations")
	check(State.coins==purse and State.xp==player_xp,"Camp economy never spends player coins or grants player XP")
	print("AUTONOMOUS_CAMP_MISSIONS ",completed)
	State.camp_data=saved; camp.advance(4000)
	State.camp_data.level=4; State.camp_data.tier=4; State.camp_data.xp=0; State.camp_data.upgrade_pending=false
	while State.camp_data.workers.size()<4:
		camp.candidate(); camp.recruit()
	for person in State.camp_data.workers.values():
		person.level=5; person.assignment=""
		for skill in person.skills: person.skills[skill]=5
	camp.add_rewards({"food":100,"materials":100,"gold":100}); camp.refresh_board(false)
	var ids: Array=State.camp_data.workers.keys()
	for pair in [["ore",3],["expedition",4]]:
		var offer: Dictionary=State.camp_data.offers.filter(func(t): return t.id==pair[0])[0]
		check(camp.assign(offer.contract,ids.slice(0,pair[1])),"Assign %d-person mission" % pair[1]); camp.advance(4000)
	var gold: int=int(State.camp_data.gold); var cycle: int=int(State.camp_data.cycle)
	check(camp.refresh_board() and int(State.camp_data.gold)==gold-int(camp.config.refresh_gold) and int(State.camp_data.cycle)==cycle+1,"Paid board refresh charges Camp Gold exactly once")
	var board: String=JSON.stringify(State.camp_data.offers)
	ValeCampUI.show(game.hud.ui,"Tasks"); ValeCampUI.show(game.hud.ui,"Overview"); ValeCampUI.show(game.hud.ui,"Tasks")
	check(JSON.stringify(State.camp_data.offers)==board,"Reopening task board cannot reroll offers")
	State.camp_data.candidate={}; camp.candidate(); var declined: String=State.camp_data.candidate.id; camp.refuse()
	camp.advance(float(camp.config.traveler_minutes)+1)
	check(not State.camp_data.candidate.is_empty() and State.camp_data.candidate.id!=declined,"Declining a traveler schedules a different future candidate")
	var snapshot: Dictionary=ValeSave.snapshot(game.player.position)
	check(ValeSave.valid(snapshot),"Phase 7 snapshot validates all camp and map state")
	snapshot.camp_data.food=-1; check(not ValeSave.valid(snapshot),"Negative camp balances rejected")
	snapshot=ValeSave.snapshot(game.player.position)
	for version in [2,3,4,5,6]:
		snapshot.version=version; snapshot.erase("camp_data"); snapshot.erase("map_data")
		check(ValeSave.valid(snapshot),"Save version %d remains accepted" % version)
	await finish()
