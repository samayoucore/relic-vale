extends Node
const SAVE="user://phase8-validation.json"
var game: Node
var passed: int=0
var failed: int=0
var results: Array=[]

func _ready() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	if ok: passed+=1
	else: failed+=1
	results.append({"pass":ok,"check":message})
	print("PHASE8 ","PASS " if ok else "FAIL ",message)
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(3); RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase8-"+name+".png")
func finish() -> void:
	var file:=FileAccess.open("res://docs/PHASE_8_TEST_RESULTS.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":results},"\t")); file.close()
	print("PHASE8_RESULT %d passed / %d failed" % [passed,failed])
	await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)

func gather(id: String,tool: String) -> void:
	var target: ValeResource
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is ValeResource and node.resource_id==id and node.remaining()>0: target=node; break
	check(is_instance_valid(target),"Find physical "+id+" node")
	if not target: return
	game.player.position=target.global_position+Vector3(1.1,.1,0); game.player.attack_timer=0
	State.equip(tool) if tool!="" else State.unequip("Tool")
	await frames(3)
	var prof: String=target.definition.profession; var xp: int=int(State.professions[prof].xp)
	for i in 10:
		if target.remaining()<=0: break
		check(game.player.gathering.start(target),"Start "+id+" tool swing")
		await frames(60)
	check(target.remaining()==0 and int(State.inventory.get(id,0))>0,"Finish gathering "+id)
	check(int(State.professions[prof].xp)>xp or ValeProfessions.level(prof)>1,prof+" gains personal profession XP")

func farm_action(id: String,index: String,crop: String="") -> void:
	var p: Vector3=game.generator.position_of(State.camp_data.address)+game.cultivation.plot_position(int(index))+Vector3(0,0,1)
	p.y=game.generator.landscape.height(Vector2(p.x,p.z))+.06
	game.player.position=p; game.player.velocity=Vector3.ZERO; game.player.invulnerability=0; game.player.attack_timer=0
	await frames(3)
	check(game.cultivation.start_action(id,index,crop),"Start physical farm action: "+id)
	await frames(85)
	check(not game.cultivation.busy(),"Complete farm animation: "+id)

func catch_fish(id: String) -> void:
	game.fishing.forced_fish=id; game.player.invulnerability=0; game.player.attack_timer=0
	check(game.fishing.cast(),"Cast rod toward actual fresh water")
	if not game.fishing.busy(): return
	for i in 500:
		await frames(1)
		if game.fishing.state=="bite": break
	check(game.fishing.state=="bite","Visible bite follows the short wait")
	var event:=InputEventAction.new(); event.action="attack"; event.pressed=true; game._unhandled_input(event)
	check(game.fishing.state=="reeling","Respond to bite with the normal attack binding")
	await shot("fishing")
	for i in 2400:
		if not game.fishing.busy(): break
		if game.fishing.zone<game.fishing.fish_position: Input.action_press("attack")
		else: Input.action_release("attack")
		await frames(1)
	Input.action_release("attack")
	check(not game.fishing.busy() and not game.fishing.latest.is_empty(),"Skill minigame lands a catch")

func run() -> void:
	game=get_tree().current_scene; await frames(40); game.player.god_mode=true
	if "--phase8-reload" in OS.get_cmdline_user_args():
		check(game.load_game(SAVE),"Fresh process loads phase 8 save"); game.active_save_path=ValeSave.PATH
		await frames(10)
		check(State.professions.fishing.level>1 and State.activities.fish_journal.size()>=2,"Fishing progress and journal survive restart")
		check(State.activities.farm.size()==8 and State.activities.farm["0"].harvests>0,"Crop identities and harvest state survive restart")
		check(game.mounts.own() and game.mounts.record().name=="Bramble","Owned horse survives restart")
		check(not State.activities.food.is_empty(),"Food buff survives restart")
		check(State.activities.treasures.size()>0,"Treasure claim state survives restart")
		await finish(); return
	game.hud.close_modal(); game.life.set_process(false)
	await gather("wood","crude_axe")
	await gather("iron_ore","crude_pickaxe")
	await gather("wild_herb","")
	check(State.level==1,"Professions do not increase combat level")
	for id in ["fishing_rod_1","watering_can"]: State.add_item(id)
	State.add_item("bait_basic",30); State.add_item("seed_carrot",12)
	State.equip("fishing_rod_1"); game.player.gathering.cancel()
	var bank: Dictionary=ValeProfessionPages.find_bank(game)
	check(not bank.is_empty(),"Reach an accessible river or lake bank")
	if bank.is_empty(): await finish(); return
	await catch_fish("fish_minnow"); await catch_fish("fish_sun_perch")
	check(State.activities.fish_journal.size()>=2,"Two caught fish recorded in field journal")
	ValeProfessions.set_level("fishing",25)
	State.life_data.minute=720; State.life_data.weather="Clear"
	check(not "fish_moon_koi" in game.fishing.eligible("lake") and "fish_minnow" in game.fishing.eligible("lake"),"Daylight changes rare eligibility; common fish remain available")
	State.life_data.minute=1320; State.life_data.weather="Fog"
	check("fish_moon_koi" in game.fishing.eligible("lake") and "fish_lantern_fish" in game.fishing.eligible("lake"),"Night and fog unlock their rare species")
	ValeProfessionPages.show(game.hud.ui,"Fishing"); await shot("journal"); game.hud.close_modal()
	State.life_data.minute=540; State.life_data.weather="Clear"; State.activities.weather_history=[]; game.cultivation.record_weather()
	var clearing: Dictionary=await game.phase7_find_clearing()
	check(not clearing.is_empty(),"Find a safe camp master plan location")
	if clearing.is_empty(): await finish(); return
	game.generator.teleport_logical(int(clearing.x),int(clearing.z)); await frames(15)
	check(game.camp.establish(clearing),"Establish camp at the checked clearing")
	State.camp_data.level=3; State.camp_data.tier=3; game.camp.sync_visual(true); game.cultivation.ensure()
	game.player.position=game.generator.position_of(clearing)+Vector3(0,.1,6); game.rig.snap(); await frames(10)
	check(game.cultivation.farm().size()==8,"Tier 3 opens eight reserved farm plots")
	await farm_action("prepare","0"); await farm_action("plant","0","carrot")
	State.equip("watering_can"); await farm_action("water","0")
	game.camp.advance(90); game.cultivation.resolve()
	check(game.cultivation.stage(game.cultivation.farm()["0"])==2,"Watered crop advances to growing stage with game time")
	await shot("growing")
	game.cultivation.farm()["0"].moist_until=ValeCamp.now()
	State.life_data.weather="Rain"; game.cultivation.record_weather(); game.camp.advance(30); game.cultivation.resolve()
	check(game.cultivation.farm()["0"].moist_until>ValeCamp.now(),"Rain automatically waters the planted bed")
	game.camp.advance(100); game.cultivation.resolve(); game.cultivation.sync_visual(true)
	check(game.cultivation.stage(game.cultivation.farm()["0"])==4,"Crop becomes harvestable")
	await farm_action("harvest","0")
	check(int(State.inventory.get("crop_carrot",0))>=3,"Harvest grants produce and farming XP")
	State.add_item("raw_meat",3); State.add_item("fish_minnow",3); State.add_item("mushroom",3)
	var station: ValeInteractable
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.kind=="station" and node.get_meta("station","")=="campfire" and node.global_position.distance_to(game.camp.visual.position)<4: station=node; break
	check(is_instance_valid(station),"Camp has a physical cooking station")
	if station:
		game.player.position=station.global_position+Vector3(0,.1,1)
		for id in ["cook_grilled_fish","cook_roast_meat","cook_forest_bites"]: check(ValeLife.craft(id,station),"Cook "+id)
		game.hud.ui.crafting_page(station); await shot("cooking"); game.hud.close_modal()
	ValeLife.use_item("meal_grilled_fish")
	check(ValeProfessions.food_bonus("gather_speed")>0,"Eating cooked fish applies its gathering buff")
	ValeLife.use_item("meal_roast_meat")
	check(ValeProfessions.food_bonus("damage_percent")>0 and ValeProfessions.food_bonus("gather_speed")==0,"A new meal replaces the previous food buff")
	# Recruit through the normal nearby-candidate path.
	game.camp.sync_actors(0); await frames(5)
	var candidate: Dictionary=State.camp_data.candidate
	if not candidate.is_empty():
		game.player.position=game.camp.actors[candidate.id].global_position+Vector3(0,0,.6)
		check(game.camp.recruit(),"Recruit a resident for ongoing work")
	var worker: Dictionary=State.camp_data.workers.values()[0]
	check(game.cultivation.assign_role(worker.id,"Farmer"),"Assign Farmer independently of mission board")
	game.cultivation.storehouse().seed_carrot=20
	var xp_before: Dictionary=State.professions.duplicate(true)
	var old_harvests: int=game.cultivation.farm()["0"].harvests
	game.generator.teleport_logical(int(clearing.x)+8,int(clearing.z)+8); await frames(10); game.camp.sync_visual()
	check(not is_instance_valid(game.camp.visual),"Leaving camp unloads its physical farm")
	State.life_data.weather="Clear"; game.cultivation.record_weather(); game.camp.advance(1440); game.cultivation.resolve()
	game.generator.teleport_logical(int(clearing.x),int(clearing.z)); game.player.position=game.generator.position_of(clearing)+Vector3(0,.1,5); game.camp.sync_visual(true); await frames(15)
	check(game.cultivation.farm()["0"].harvests>old_harvests and int(game.cultivation.storehouse().get("crop_carrot",0))>0,"Farmer harvests and replants while camp is unloaded")
	check(State.professions==xp_before,"Resident production grants no personal profession XP")
	check(worker.assignment=="" and worker.role=="Farmer","Occupation and mission state remain distinct")
	State.coins=250
	check(game.mounts.acquire(),"Purchase a persistent horse at tier 3")
	game.player.position=game.camp.visual.position+Vector3(0,.1,18); game.player.invulnerability=0; game.player.attack_timer=0
	check(game.mounts.call_mount(),"Call horse onto safe nearby ground")
	if is_instance_valid(game.mounts.actor): game.player.position=game.mounts.actor.global_position+Vector3(.6,0,0)
	check(game.mounts.mount(),"Mount the animated horse")
	await frames(5); await shot("mounted")
	check(game.mounts.visual.clips.has("gallop") and game.mounts.visual.animator.has_animation("Gallop"),"Horse has authored idle, walk and gallop animation")
	var a_before: Dictionary=game.generator.address(game.player.position)
	game.rig.yaw=0; game.rig.target_yaw=0
	Input.action_press("move_down"); Input.action_press("sprint")
	await frames(720)
	Input.action_release("move_down"); Input.action_release("sprint")
	var a_after: Dictionary=game.generator.address(game.player.position)
	check(absi(int(a_after.z)-int(a_before.z))>=3,"Physically gallop through at least three streamed chunks")
	game.generator.teleport_logical(int(clearing.x),int(clearing.z)); await frames(10)
	check(game.mounts.own() and is_instance_valid(game.mounts.actor),"Horse remains available after logical teleport")
	game.mounts.park(); game.player.position=game.generator.position_of(clearing)+Vector3(0,.1,18)
	var chart: Dictionary=game.exploration.create_map()
	check(not chart.is_empty(),"Treasure chart chooses safe discovered ground")
	if not chart.is_empty():
		game.player.position=game.generator.position_of(chart.address)+Vector3(0,.1,.8); game.exploration.clock=0; await frames(55)
		check(game.exploration.claim(chart.id),"Find and recover the physical treasure")
		check(not game.exploration.claim(chart.id),"Treasure reward cannot be claimed twice")
	State.add_item("meal_roast_meat"); ValeLife.use_item("meal_roast_meat")
	game.player.position=game.generator.position_of(clearing)+Vector3(0,.1,6); game.rig.zoom=32; game.rig.target_zoom=32; game.rig.snap(); await frames(20)
	await shot("camp")
	check(ValeSave.valid(ValeSave.snapshot(game.player.position)),"Phase 8 snapshot passes strict validation")
	check(game.save_game(false,SAVE),"Save the complete profession / farm / mount journey")
	var data: Dictionary=ValeSave.read(SAVE)
	check(not data.is_empty() and int(data.version)==ValeSave.VERSION,"Read the current versioned profession save successfully")
	check(game.load_game(SAVE),"Reload the complete journey"); game.active_save_path=ValeSave.PATH
	check(State.activities.farm.size()==8 and game.mounts.own(),"Farm and mount ownership survive load")
	await finish()
