extends "res://tests/phase8_test.gd"

func finish() -> void:
	var file:=FileAccess.open("res://docs/PHASE_8_EDGE_RESULTS.json",FileAccess.WRITE); file.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":results},"\t")); file.close()
	print("PHASE8_EDGE_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)

func run() -> void:
	game=get_tree().current_scene; await frames(12); game.player.god_mode=true
	check(game.load_game(SAVE),"Load completed phase 8 fixture"); game.active_save_path=ValeSave.PATH
	await frames(10); game.hud.close_modal(); game.life.set_process(false)
	var campus: Dictionary=State.camp_data.address.duplicate(true)
	game.generator.teleport_logical(int(campus.x),int(campus.z)); game.player.position=game.generator.position_of(campus)+Vector3(0,.1,6); game.camp.sync_visual(true)
	var worker: Dictionary=State.camp_data.workers.values()[0]
	game.cultivation.assign_role(worker.id,"")
	var store: Dictionary=game.cultivation.storehouse()
	for role in ["Cook","Forager","Woodworker"]:
		store.fish_minnow=8; store.wood=12
		var item: String={"Cook":"meal_grilled_fish","Forager":"wild_herb","Woodworker":"plank"}[role]
		var before: int=int(store.get(item,0)); var xp: Dictionary=State.professions.duplicate(true)
		check(game.cultivation.assign_role(worker.id,role),"Assign ongoing "+role+" role")
		game.camp.advance(1440); game.cultivation.resolve()
		check(int(store.get(item,0))>before,role+" produces through world-clock catch-up")
		check(State.professions==xp,role+" never grants personal XP")
		var after: int=int(store.get(item,0)); game.cultivation.resolve(); game.cultivation.resolve()
		check(int(store.get(item,0))==after,role+" completed production cannot duplicate")
		game.cultivation.assign_role(worker.id,"")
	var site: Dictionary=game.cultivation.fishing_worksite()
	check(not site.is_empty() or not game.cultivation.assign_role(worker.id,"Fisher"),"Fisher requires a real nearby bank")
	State.camp_data.food=999; State.camp_data.materials=999; State.camp_data.gold=999
	game.camp.refresh_board(false)
	var task: Dictionary={}
	for offer in State.camp_data.offers:
		if int(offer.workers)==1 and game.camp.task_reason(offer,[worker.id]).is_empty(): task=offer; break
	check(not task.is_empty(),"Find an eligible one-resident mission")
	if not task.is_empty():
		game.cultivation.assign_role(worker.id,"Farmer")
		check(not game.camp.assign(task.contract,[worker.id]),"Occupation prevents duplicate expedition assignment")
		game.cultivation.assign_role(worker.id,"")
		check(game.camp.assign(task.contract,[worker.id]),"Release occupation and send resident on mission")
		check(not game.cultivation.assign_role(worker.id,"Cook"),"Mission prevents duplicate occupation assignment")
		game.camp.advance(1440); game.camp.resolve()
	var plot: Dictionary=game.cultivation.farm()["1"]
	plot.prepared=true; plot.crop="beet"; plot.progress=0; plot.last=ValeCamp.now(); plot.moist_until=ValeCamp.now()
	State.life_data.weather="Clear"; State.activities.weather_history=[]; game.cultivation.record_weather()
	game.camp.advance(30); game.cultivation.resolve()
	check(float(plot.progress)==0,"Dry soil pauses growth")
	State.life_data.weather="Rain"; game.cultivation.record_weather(); game.camp.advance(40); game.cultivation.resolve()
	check(float(plot.progress)==40 and float(plot.moist_until)>ValeCamp.now(),"Rain resumes growth with exact elapsed minutes")
	var xp: int=State.professions.mining.xp
	ValeProfessions.set_level("mining",1)
	check(ValeProfessions.gathering_error(State.resource_data.silver_ore,State.items.steel_pickaxe)!="","High-tier tool does not bypass profession requirement")
	ValeProfessions.set_level("mining",10)
	check(ValeProfessions.gathering_error(State.resource_data.silver_ore,State.items.crude_pickaxe)!="","High profession level does not bypass tool requirement")
	check(ValeProfessions.gathering_error(State.resource_data.silver_ore,State.items.iron_pickaxe)=="","Correct profession and tool unlock silver")
	ValeProfessions.set_level("mining",1); ValeProfessions.award("mining",1000000)
	check(ValeProfessions.level("mining")==25 and State.professions.mining.xp==0,"Profession XP caps safely at level 25")
	var good: Dictionary=ValeSave.snapshot(game.player.position)
	for version in range(2,8):
		var old: Dictionary=good.duplicate(true); old.version=version; old.erase("activities"); old.erase("professions")
		check(ValeSave.valid(old),"Version %d remains readable without new fields" % version)
	var malformed: Dictionary=good.duplicate(true); malformed.activities.farm["1"].progress=-3
	check(not ValeSave.valid(malformed),"Reject malformed crop growth")
	malformed=good.duplicate(true); malformed.professions.mining.level="bad"
	check(not ValeSave.valid(malformed),"Reject malformed profession level")
	malformed=good.duplicate(true); malformed.activities.mounts.horse_1.address.x=4
	check(not ValeSave.valid(malformed),"Reject non-string logical mount coordinate")
	var prices_safe: bool=true
	for recipe in State.crafting_data.values():
		if recipe.get("profession","")!="cooking": continue
		var cost: float=0
		for id in recipe.input: cost+=int(State.items[id].base_price)*int(recipe.input[id])*.8
		if float(State.items[recipe.output].base_price)*.68>=cost: prices_safe=false
	check(prices_safe,"No buy/cook/sell profit loop at best vendor rates")
	var image_ok: bool=true
	for id in ValeProfessions.fish:
		var image: Image=load("res://assets/ui/phase8/icons/"+id+".png").get_image()
		if image.get_used_rect().size==Vector2i.ZERO: image_ok=false
	check(image_ok,"All 20 fish journal icons contain visible pixels")
	var curves: bool=true
	for clip in ValeProfessions.motion.clips.values():
		if clip.samples.size()<30: curves=false
	check(curves,"Authored Quaternius arm motion is present for casting and all farm actions")
	Preferences.set_option("mount_key","T")
	check(InputMap.action_get_events("call_mount")[0].physical_keycode==KEY_T,"Mount binding responds to Controls setting")
	Preferences.set_option("mount_key","V")
	# Real fish animation, cast restrictions, rare bait and cancellation.
	State.add_item("fishing_rod_1"); State.add_item("bait_rare",5); State.add_item("bait_basic",5); State.equip("fishing_rod_1")
	game.player.position=game.camp.visual.position+Vector3(0,.1,4); game.player.facing=Vector3.RIGHT
	check(not game.fishing.cast(),"A dry camp cannot be used as an arbitrary fishing spot")
	var bank: Dictionary=ValeProfessionPages.find_bank(game)
	if not bank.is_empty():
		var original_camp: Dictionary=State.camp_data.address.duplicate(true)
		var center: Vector3=bank.bank-bank.direction*20
		State.camp_data.address=game.generator.address(center)
		State.activities.production.erase("fish_bank")
		var worksite: Dictionary=game.cultivation.fishing_worksite()
		check(not worksite.is_empty(),"Find a genuine riverbank for a waterside camp")
		check(game.cultivation.assign_role(worker.id,"Fisher"),"Assign Fisher beside real water")
		var fish_before: int=int(store.get("fish_minnow",0)); var fishing_xp: Dictionary=State.professions.duplicate(true)
		game.camp.advance(1440); game.cultivation.resolve()
		check(int(store.get("fish_minnow",0))>fish_before and State.professions==fishing_xp,"Fisher supplies common fish without granting personal XP")
		game.cultivation.assign_role(worker.id,""); State.camp_data.address=original_camp; State.activities.production.erase("fish_bank")
		game.player.invulnerability=0; game.player.attack_timer=0
		ValeProfessions.set_level("fishing",1); State.activities.bait="bait_rare"
		check(not game.fishing.cast(),"Rare bait requires Fishing 10")
		State.activities.bait="bait_basic"; check(game.fishing.cast(),"Cast from bank after choosing valid bait")
		await frames(65)
		check(is_instance_valid(game.fishing.fish_model) and game.fishing.fish_model.get_child_count()==2,"Only two nearby animated fish are instantiated")
		game.rig.zoom=17; game.rig.target_zoom=17; game.rig.snap()
		await shot("cast-final")
		var attack_before: float=game.player.attack_timer; game.player.attack()
		check(game.player.attack_timer==attack_before and not game.player.abilities.use(0),"HUD attacks and abilities cannot interrupt fishing")
		var event:=InputEventAction.new(); event.action="pause"; event.pressed=true; game._unhandled_input(event)
		check(not game.fishing.busy(),"Escape cancels fishing without granting a catch")
	# Logical ownership and render transforms across extremely distant coordinates.
	game.mounts.park(); game.generator.teleport_logical(1000000000,-1000000000); await frames(10)
	check(game.mounts.own() and not is_instance_valid(game.camp.visual),"Far-coordinate streaming keeps logical ownership and unloads camp")
	game.player.invulnerability=0; game.player.attack_timer=0
	check(game.mounts.call_mount(),"Horse can be called a billion chunks from camp")
	if is_instance_valid(game.mounts.actor):
		var address: Dictionary=game.mounts.record().address.duplicate(true)
		game.generator.teleport_logical(1000000001,-1000000000); await frames(35)
		check(is_instance_valid(game.mounts.actor) and game.mounts.actor.global_position.distance_to(game.generator.position_of(address))<.1,"Nearby teleport repositions waiting horse from its logical address")
	game.mounts.park(); game.generator.teleport_logical(int(campus.x),int(campus.z)); game.player.position=game.generator.position_of(campus)+Vector3(0,.1,7); game.camp.sync_visual(true); await frames(35)
	# Visually review all five stages and the final hamlet footprint.
	State.camp_data.level=5; State.camp_data.tier=5; game.camp.sync_visual(true); game.cultivation.assign_role(worker.id,"")
	for i in 8:
		var p: Dictionary=game.cultivation.farm()[str(i)]; var id: String=ValeProfessions.crops.keys()[i]
		p.prepared=true; p.crop=id; p.progress=float(ValeProfessions.crops[id].minutes)*[0,.2,.5,.8,1,1,1,1][i]; p.last=ValeCamp.now(); p.moist_until=ValeCamp.now()+480
	game.cultivation.sync_visual(true); game.rig.zoom=28; game.rig.target_zoom=28; game.rig.snap(); await frames(30); await shot("farm-world-final")
	check(game.cultivation.plots.size()==8 and is_instance_valid(game.mounts.stable_root),"Full hamlet contains farm and stable in reserved positions")
	var home: Dictionary=State.camp_data.buildings["0"]
	await game.interiors.enter(home); await frames(8)
	check(not game.mounts.mounted and not game.mounts.blocked().is_empty(),"Horse stays outside player home")
	var kitchen: ValeInteractable
	for node in game.interiors.room.get_children():
		if node is ValeInteractable and node.get_meta("station","")=="kitchen": kitchen=node
	check(is_instance_valid(kitchen),"Player home contains a real kitchen station")
	await shot("home-kitchen"); await game.interiors.leave(); await frames(10)
	game.player.position=game.camp.visual.position+Vector3(0,.1,16); game.player.attack_timer=0; game.player.invulnerability=0
	game.mounts.call_mount()
	if is_instance_valid(game.mounts.actor):
		game.player.position=game.mounts.actor.global_position+Vector3(.5,0,0); game.mounts.mount()
		game.rig.zoom=13; game.rig.target_zoom=13; game.rig.yaw=.9; game.rig.target_yaw=.9; game.rig.snap(); await frames(35); await shot("rider-final")
		check(game.player.sprite.sprite_frames==game.mounts.riding_frames,"Mounted rider retains custom seated LPC appearance")
		game.player.attack(); await frames(2)
		check(game.player.attack_timer==0 and not game.player.abilities.use(0) and not game.player.weapon_sprite.visible,"Mounted HUD actions cannot attack or reveal held weapons")
		game.mounts.dismount()
	for tab in ["Professions","Fishing","Garden","Mounts","Exploration"]:
		ValeProfessionPages.show(game.hud.ui,tab); await frames(3)
		check(game.hud.modal_kind=="professions" and game.hud.ui.body.get_child_count()>1,"Open themed "+tab+" page")
		await shot(tab.to_lower()+"-final"); game.hud.close_modal()
	Preferences.set_option("ui_scale",1.5); ValeProfessionPages.show(game.hud.ui,"Garden"); await frames(5)
	check(game.hud.modal_panel.get_global_rect().end.x<=1280 and game.hud.modal_panel.get_global_rect().end.y<=720,"Garden UI stays within viewport at 150% scale")
	await shot("ui-150"); game.hud.close_modal(); Preferences.set_option("ui_scale",1.0)
	# Test outputs never replace the user's actual saved journey.
	var original: Dictionary=ValeSave.read(ValeSave.PATH)
	check(not original.is_empty() and int(original.world_seed)!=20260907,"Existing personal journey remains readable in its separate world")
	await finish()
