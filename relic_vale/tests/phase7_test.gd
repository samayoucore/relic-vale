extends Node
var game: Node
var passed: int=0
var failed: int=0
const SAVE="user://phase7-integration.json"
func check(value: bool,title: String) -> void:
	if value: passed+=1; print("PASS: "+title)
	else: failed+=1; print("FAIL: "+title)
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(4); RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase7-"+name+".png")
func _ready() -> void: run.call_deferred()
func finish() -> void:
	print("PHASE7_RESULT %d passed / %d failed" % [passed,failed]); await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)
func run() -> void:
	game=get_tree().current_scene
	await frames(20); game.player.god_mode=true
	if "--phase7-reload" in OS.get_cmdline_user_args():
		check(game.load_game(SAVE),"Fresh process restores phase 7 save")
		game.active_save_path=ValeSave.PATH
		await frames(8)
		check(State.map_data.markers.size()>0,"Markers survived restart")
		check(int(State.camp_data.level)==5 and State.camp_data.workers.size()>=2,"Camp tier and residents survived restart")
		check(State.camp_data.active.size()==1,"Active job survived restart")
		var old: int=int(State.camp_data.materials); game.camp.advance(4000)
		check(int(State.camp_data.materials)>old,"Offline game-time job resolves after restart")
		old=int(State.camp_data.materials); game.camp.resolve(); game.camp.resolve()
		check(int(State.camp_data.materials)==old,"Reloaded rewards apply exactly once")
		await finish(); return
	check(State.camp_data.is_empty(),"Old journey defaults to no owned camp")
	game.hud.close_modal(); State.modal=true
	for chunk in [Vector2i(0,0),Vector2i(2,0),Vector2i(8,8),Vector2i(-8,-8)]:
		game.generator.teleport_logical(chunk.x,chunk.y)
		for key in game.generator.blueprints: game.generator.chart_chunk(key)
		await frames(2)
	game.generator.teleport_logical(0,0,Vector3(0,0,4)); await frames(3)
	check(game.generator.discovered.size()>50,"Several actual regions explored")
	game.hud.ui.map_page(); await shot("atlas")
	var marker: Dictionary=game.cartography.add_marker(game.generator.address(game.player.position),"Willowmere trail","Home")
	check(not marker.is_empty(),"Create persistent marker on explored ground")
	check(game.cartography.add_marker({"x":"99999999","z":"88888888","local":[16,0,16]}).is_empty(),"Unknown terrain cannot accept marker")
	game.hud.close_modal()
	var scouted: Dictionary=await game.phase7_find_clearing()
	check(not scouted.is_empty() and absi(int(scouted.x))>=3,"Move several chunks away before marker travel")
	State.modal=true; await frames(4)
	check(await game.travel.go(marker),"Travel loads destination and finds safe ground")
	check(not State.modal and not game.hud.modal_panel.visible,"Loading screen closes and gameplay resumes")
	check(game.travel.last_ready.get("chunks",0)>=25,"Terrain and collisions ready before reveal")
	game.player.attack_timer=.4; check(not game.travel.blocked().is_empty(),"Fast travel blocked during attack"); game.player.attack_timer=0; game.travel.combat_until=0
	var site: Dictionary=await game.phase7_find_clearing()
	print("CAMP_SITE ",site)
	check(not site.is_empty(),"Find valid flat open masterplan site")
	if site.is_empty(): await finish(); return
	check(game.camp.establish(site),"Establish initial physical camp")
	game.life.set_time(10); game.rig.zoom=36; game.rig.target_zoom=36; game.rig.snap()
	game.camp.advance(2); await frames(8)
	check(not State.camp_data.candidate.is_empty(),"First traveler guaranteed")
	check(game.camp.actors.has(State.camp_data.candidate.id),"Traveler is a physical NPC")
	await shot("camp-tier1")
	check(game.camp.recruit(),"Recruit first resident")
	var first: String=State.camp_data.workers.keys()[0]
	var task: Dictionary=State.camp_data.offers.filter(func(offer): return offer.id=="forage")[0]
	check(game.camp.assign(task.contract,[first]),"Assign starter single-worker task without donations")
	check(not game.camp.assign(State.camp_data.offers[0].contract,[first]),"No double worker assignment")
	game.camp.advance(300)
	check(int(State.camp_data.materials)>0 and int(State.camp_data.xp)>0,"Mission rewards independent camp resources and XP")
	var amounts: Array=[State.camp_data.food,State.camp_data.materials,State.camp_data.gold,State.camp_data.xp]
	game.camp.resolve(); check(amounts==[State.camp_data.food,State.camp_data.materials,State.camp_data.gold,State.camp_data.xp],"No duplicate completion reward")
	game.camp.advance(1440); check(game.camp.recruit(),"Second visitor joins on game-clock schedule")
	var party: Array=State.camp_data.workers.keys()
	var hunting: Dictionary={}
	for offer in State.camp_data.offers:
		if offer.id=="hunt": hunting=offer
	check(game.camp.assign(hunting.contract,party),"Assign a two-resident task")
	game.camp.advance(500)
	game.camp.add_rewards({"xp":999})
	check(State.camp_data.upgrade_pending and int(State.camp_data.xp)==int(game.camp.level_data().xp),"Camp XP freezes exactly at threshold")
	var cap: int=int(State.camp_data.xp); var materials: int=int(State.camp_data.materials)
	for offer in State.camp_data.offers:
		if offer.id=="firewood": game.camp.assign(offer.contract,[first]); break
	game.camp.advance(300)
	check(int(State.camp_data.xp)==cap and int(State.camp_data.materials)>materials,"Pending upgrade discards XP but grants mission supplies")
	State.inventory.wood=4; var coins: int=State.coins; State.coins=20
	check(game.camp.donate("wood",2) and int(State.inventory.wood)==2,"Item contribution has exact inventory debit")
	check(game.camp.donate("coins",10) and State.coins==10,"Coin contribution uses separate player purse")
	State.coins=coins
	game.camp.add_rewards({"food":500,"materials":500,"gold":500})
	check(game.camp.upgrade() and int(State.camp_data.xp)==0 and not State.camp_data.upgrade_pending,"Confirm upgrade spends resources and resets XP without overflow")
	for tier in range(2,6):
		State.camp_data.level=tier; State.camp_data.tier=tier; State.camp_data.xp=0; State.camp_data.upgrade_pending=false
		game.life.set_time(10); game.camp.sync_visual(true); await frames(6); await shot("camp-tier"+str(tier))
	check(State.camp_data.buildings.has("0"),"Tier 4+ provides real enterable player home")
	await game.interiors.enter(State.camp_data.buildings["0"]); await shot("player-home")
	check(not game.interiors.active.is_empty(),"Camp home reuses playable interior system")
	await game.interiors.leave(); await frames(6)
	for tab in ["Overview","Residents","Tasks","Upgrade","Storage"]:
		ValeCampUI.show(game.hud.ui,tab); await shot(tab.to_lower())
	game.hud.close_modal(); State.modal=true
	var before: Dictionary=State.camp_data.duplicate(true)
	game.generator.teleport_logical(1000000000002,-999999999998); game.camp.sync_visual()
	check(not is_instance_valid(game.camp.visual),"Distant camp has no actors or per-frame AI")
	var far: Dictionary=game.generator.address(game.player.position); game.generator.chart_chunk(far.x+","+far.z)
	var far_marker: Dictionary=game.cartography.add_marker(far,"Distant trail")
	check(far_marker.address.x=="1000000000002","Far marker preserves integer logical address")
	check(await game.travel.go({"id":"camp","name":State.camp_data.name,"address":State.camp_data.address}),"Travel home from huge logical distance")
	if not game.travel.last_error.is_empty(): print("TRAVEL_ERROR ",game.travel.last_error)
	check(State.camp_data.workers.size()==before.workers.size() and State.camp_data.materials==before.materials,"Unload and return preserve camp state")
	for offer in State.camp_data.offers:
		if offer.id=="firewood": game.camp.assign(offer.contract,[first]); break
	check(game.save_game(false,SAVE),"Save markers camp workers jobs and resources")
	check(not ValeSave.read(SAVE).is_empty(),"New save validates")
	var invalid: Dictionary=ValeSave.read(SAVE); invalid.camp_data.workers[first].assignment="missing_job"
	check(not ValeSave.valid(invalid),"Reject broken worker assignment save")
	await finish()
