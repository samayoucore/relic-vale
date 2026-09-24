class_name ValeProfessionPages
extends RefCounted

static func show(ui: ValeInterface,tab: String="Professions") -> void:
	ui.page("professions","Life in the vale","PROFESSIONS / "+tab.to_upper())
	var tabs:=ui.row(ui.body)
	for title in ["Professions","Fishing","Garden","Mounts","Exploration"]: ui.button(tabs,title,func(): show(ui,title),title==tab)
	var box:=ui.scroll(ui.body)
	match tab:
		"Professions":
			for id in ValeProfessions.definitions:
				var definition: Dictionary=ValeProfessions.definitions[id]; var progress: Dictionary=State.professions[id]
				var row:=ui.row(box); ui.picture(row,ui.icon(definition.icon),Vector2(48,48)); var detail:=ui.vbox(row,true)
				ui.text(detail,"%s · Level %d / 25" % [definition.name,progress.level],"Heading")
				var bar:=ProgressBar.new(); bar.custom_minimum_size.y=18; bar.max_value=ValeProfessions.needed(id); bar.value=progress.xp; bar.show_percentage=false; detail.add_child(bar)
				ui.text(detail,"%d / %d XP · %s" % [progress.xp,bar.max_value,ValeProfessions.next_unlock(id)],"Muted",true)
				if not progress.unlocks.is_empty(): ui.text(detail,"Learned: "+", ".join(progress.unlocks),"",true)
			var food: Dictionary=State.activities.food
			if not food.is_empty(): ui.text(box,"Meal: %s · %d game min remaining" % [State.items[food.item].name,maxi(0,ceili(float(food.end)-ValeCamp.now()))],"Heading",true)
		"Fishing": fishing(ui,box)
		"Garden": garden(ui,box)
		"Mounts": mounts(ui,box)
		"Exploration": exploration(ui,box)

static func fishing(ui: ValeInterface,box: Node) -> void:
	ui.text(box,"Equip a rod, stand on dry bank and face fresh water. E casts; respond to the bite, then tap or hold Space / left mouse to keep the fish in the green zone.","",true)
	var choices: Array=[]; var ids: Array[String]=["bait_basic","bait_insect","bait_rare"]
	for id in ids: choices.append("%s · %d carried" % [State.items[id].name,State.inventory.get(id,0)])
	ui.option(box,choices,maxi(0,ids.find(State.activities.bait)),func(i): State.activities.bait=ids[i]; State.save_requested.emit())
	ui.text(box,"Dough: everyday catches · Insects: faster bites, better uncommon chance · Moon bait: Fishing 10, best rare chance","Muted",true)
	ui.text(box,"Field journal · %d / %d species" % [State.activities.fish_journal.size(),ValeProfessions.fish.size()],"Heading")
	for id in ValeProfessions.fish:
		var fish: Dictionary=ValeProfessions.fish[id]; var known: bool=State.activities.fish_journal.has(id)
		var row:=ui.row(box)
		var art:=ui.picture(row,ui.icon(id),Vector2(58,58)); art.modulate=Color.WHITE if known else Color(.12,.17,.15,1)
		var detail:=ui.vbox(row,true)
		ui.text(detail,fish.name if known else "Undiscovered fish","Heading")
		ui.text(detail,"%s · %s · %s · %s · Fishing %d" % [fish.rarity,fish.biome,fish.time,fish.weather,fish.min_level],"Muted",true)
		if known:
			var record: Dictionary=State.activities.fish_journal[id]
			ui.text(detail,"%d caught · best %.2f kg / %.1f cm · %s (%s, %s)" % [record.count,record.best_weight,record.best_size,record.water,record.address.x,record.address.z],"",true)

static func garden(ui: ValeInterface,box: Node) -> void:
	var service: ValeCultivation=ui.game.cultivation
	ui.text(box,"Eight beds open at camp tier 3. Prepare with E, choose seeds here, then plant with E. Equip the watering can to water. Crops grow while soil is moist; rain waters them too.","",true)
	var ids: Array=ValeProfessions.crops.keys(); var choices: Array=[]
	for id in ids:
		var crop: Dictionary=ValeProfessions.crops[id]
		choices.append("%s · Farming %d · %d seeds" % [crop.name,crop.min_level,State.inventory.get(crop.seed,0)])
	ui.option(box,choices,maxi(0,ids.find(service.chosen_seed)),func(i): service.chosen_seed=ids[i])
	for id in ValeProfessions.crops:
		var crop: Dictionary=ValeProfessions.crops[id]
		ui.text(box,"%s · %.1f game h · %d produce · Farming %d" % [crop.name,float(crop.minutes)/60,crop.yield,crop.min_level],"Muted",true)
	if service.unlocked():
		for id in service.farm(): ui.text(box,"Bed %d · %s" % [int(id)+1,service.prompt(id)],"",true)
		ui.button(box,"Produce chest",func(): ValeStorage.show(ui,"camp_production"),not ui.game.camp.near_camp())
	ui.text(box,"A Farmer waters prepared beds, harvests and uses chest seeds to replant staples. A Cook turns chest ingredients into simple meals. Set occupations in Camp → Residents.","",true)
	ui.button(box,"Manage residents",func(): ValeCampUI.show(ui,"Residents"),State.camp_data.is_empty())

static func mounts(ui: ValeInterface,box: Node) -> void:
	ui.text(box,"Your horse travels with your journey. %s calls it; E nearby mounts; E dismounts. Shift gallops. Mounting requires safe ground outside buildings and combat." % Preferences.values.mount_key,"",true)
	if ui.game.mounts.own():
		var record: Dictionary=ui.game.mounts.record()
		ui.text(box,record.name+" · "+record.state,"Heading")
		ui.text(box,"Trot 1.5× walking speed · Gallop 2.3× · Camera orbit and zoom remain available","Muted",true)
		ui.button(box,"Call Bramble",func(): ui.hud.close_modal(); ui.game.mounts.call_mount())
		ui.button(box,"Return to stable",func(): ui.game.mounts.park(); show(ui,"Mounts"))
	else:
		ui.text(box,"Bramble · a steady trail horse · 180 copper\nStable opens at camp tier 3.","Heading",true)
		ui.button(box,"Purchase Bramble · 180 copper",func(): ui.game.mounts.acquire(); show(ui,"Mounts"),int(State.camp_data.get("tier",0))<3 or State.coins<180)

static func exploration(ui: ValeInterface,box: Node) -> void:
	ui.text(box,"Charts mark a broad search area on the atlas. Explore the ground inside it to uncover a cache. Rare gathering sites are remembered after you approach them.","",true)
	ui.button(box,"Piece together a chart · 3 fragments (%d carried)" % State.inventory.get("map_fragment",0),func(): ui.game.exploration.assemble(); show(ui,"Exploration"),int(State.inventory.get("map_fragment",0))<3)
	for record in State.activities.treasures.values():
		ui.text(box,record.name+" · "+("Recovered" if record.claimed else "Search the amber circle on your atlas"),"Heading",true)
	ui.text(box,"%d rare gathering sites remembered" % State.activities.rare_notes.size(),"Muted")
	ui.button(box,"Open atlas",ui.map_page)

static func occupations(ui: ValeInterface,box: Node,worker: Dictionary) -> void:
	var roles: Array=["Rest / available"]+ValeCultivation.ROLES.keys()
	var selected: int=roles.find(worker.get("role","")); selected=maxi(0,selected)
	ui.option(box,roles,selected,func(i):
		ui.game.cultivation.assign_role(worker.id,"" if i==0 else roles[i]); ValeCampUI.show(ui,"Residents"))
	ui.text(box,"Ongoing work: "+worker.get("role","Rest")+" · Missions require a resting resident.","Muted",true)

static func debug(ui: ValeInterface) -> void:
	ui.page("phase8_debug","Phase 8 field tools","DEBUG / PROFESSIONS AND CAMP LIFE")
	var box:=ui.scroll(ui.body)
	for id in ValeProfessions.definitions:
		var row:=ui.row(box)
		ui.text(row,ValeProfessions.definitions[id].name,"Heading")
		ui.button(row,"+100 XP",func(): ValeProfessions.award(id,100); debug(ui))
		ui.button(row,"Level 25",func(): ValeProfessions.set_level(id,25); debug(ui))
	ui.button(box,"Give rod, watering can and 30 of each bait / seed",func():
		for id in ["fishing_rod_1","watering_can"]: State.add_item(id)
		for id in State.items:
			if id.begins_with("bait_") or id.begins_with("seed_"): State.add_item(id,30)
		debug(ui))
	ui.button(box,"Equip rod and find a nearby bank",func(): ui.hud.close_modal(); State.equip("fishing_rod_1"); find_bank(ui.game))
	ui.button(box,"Force next bite",func(): ui.hud.close_modal(); ui.game.fishing.wait_seconds=0)
	var fish_ids: Array=ValeProfessions.fish.keys()
	ui.option(box,fish_ids,0,func(i): ui.game.fishing.forced_fish=fish_ids[i])
	ui.button(box,"Reveal fishing journal",func():
		for id in fish_ids: State.activities.fish_journal[id]={"count":1,"best_weight":1.0,"best_size":34.0,"address":ui.game.generator.address(ui.game.player.position),"water":"debug","day":State.life_data.day}
		show(ui,"Fishing"))
	ui.button(box,"Unlock camp farm / stable (tier 3)",func():
		if State.camp_data.is_empty():
			var a: Dictionary=await ui.game.phase7_find_clearing()
			if not a.is_empty(): ui.game.generator.teleport_logical(int(a.x),int(a.z)); ui.game.camp.establish(a)
		if not State.camp_data.is_empty():
			State.camp_data.level=maxi(3,State.camp_data.level); State.camp_data.tier=State.camp_data.level; ui.game.camp.sync_visual(true); ui.game.cultivation.ensure()
		debug(ui))
	ui.button(box,"Plant carrot in every empty bed",func():
		ui.game.cultivation.ensure()
		for p in ui.game.cultivation.farm().values(): p.prepared=true; p.crop="carrot"; p.progress=0; p.planted=ValeCamp.now(); p.last=ValeCamp.now()
		ui.game.cultivation.sync_visual(true))
	ui.button(box,"Water every bed",func():
		for p in ui.game.cultivation.farm().values(): p.watered=ValeCamp.now(); p.moist_until=ValeCamp.now()+480
		ui.game.cultivation.sync_visual(true))
	ui.button(box,"Mature every planted bed",func():
		for p in ui.game.cultivation.farm().values():
			if not p.crop.is_empty(): p.progress=ValeProfessions.crops[p.crop].minutes
		ui.game.cultivation.sync_visual(true))
	ui.button(box,"Advance 6 game hours",func(): ui.game.camp.advance(360); ui.game.cultivation.resolve(); ui.game.cultivation.sync_visual(true))
	ui.button(box,"Rain / clear",func(): State.life_data.weather="Clear" if State.life_data.weather=="Rain" else "Rain"; ui.game.cultivation.record_weather())
	ui.button(box,"Grant and call horse",func(): ui.game.mounts.acquire(true); ui.hud.close_modal(); ui.game.mounts.call_mount())
	ui.button(box,"Mount / dismount",func(): ui.hud.close_modal(); ui.game.mounts.dismount() if ui.game.mounts.mounted else ui.game.mounts.mount())
	ui.button(box,"Generate treasure chart",func(): ui.game.exploration.create_map())
	ui.button(box,"Travel near latest treasure",func():
		if State.activities.treasures.is_empty(): return
		var a: Dictionary=State.activities.treasures.values().back().area
		ui.hud.close_modal(); ui.game.generator.teleport_logical(int(a.x),int(a.z),ValeSave.vector(a.local)))

static func find_bank(game: Node) -> Dictionary:
	for key in game.generator.active_chunks:
		var coord: Vector2i=game.generator.local_coord(key)
		for x in range(2,31,2):
			for z in range(2,31,2):
				var p:=Vector3(coord.x*32+x,0,coord.y*32+z); p.y=game.generator.landscape.height(Vector2(p.x,p.z))+.05
				if not game.mounts.clear_spot(p): continue
				for d in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
					var target: Dictionary=game.fishing.bank_target(p,d)
					if target.is_empty(): continue
					game.player.global_position=p; game.player.facing=d; game.rig.snap(); return {"bank":p,"direction":d,"target":target}
	State.notification.emit("No accessible bank in the currently loaded area.")
	return {}
