class_name ValeCampUI
extends RefCounted

static func confirm(ui: ValeInterface,title: String,detail: String,action: Callable,back: Callable) -> void:
	ui.page("confirmation",title,"PLEASE CONFIRM")
	ui.text(ui.scroll(ui.body),detail,"Heading",true)
	ui.button(ui.footer,"Confirm",action); ui.button(ui.footer,"Back",back)

static func marker(ui: ValeInterface,record: Dictionary) -> void:
	ui.page("marker",record.name,"ATLAS / WAYPOINT")
	var box:=ui.scroll(ui.body)
	var name:=LineEdit.new(); name.text=record.name; name.max_length=32; box.add_child(name)
	var a: Dictionary=record.address
	ui.text(box,"Area %s, %s · %.1f, %.1f" % [a.x,a.z,a.local[0],a.local[2]],"Muted")
	if record.id!="camp":
		ui.option(box,ValeCartography.ICONS,ValeCartography.ICONS.find(record.icon),func(i): record.icon=ValeCartography.ICONS[i]; State.save_requested.emit())
		ui.button(box,"Save name",func(): record.name=name.text.strip_edges().left(32); State.save_requested.emit(); ui.map_page())
		ui.button(box,"Remove marker",func(): confirm(ui,"Remove this marker?",record.name,func(): State.map_data.markers.erase(record.id); State.save_requested.emit(); ui.map_page(),func(): marker(ui,record)))
	else:
		ui.button(box,"Rename camp",func(): State.camp_data.name=name.text.strip_edges().left(32); State.save_requested.emit(); ui.map_page())
	var reason: String=ui.game.travel.blocked()
	ui.text(box,reason if not reason.is_empty() else "Travel to safe ground near this waypoint.","Muted",true)
	ui.button(box,"Travel here",func(): ui.game.travel.go(record),not reason.is_empty())
	ui.button(ui.footer,"Atlas",ui.map_page)

static func show(ui: ValeInterface,tab: String="Overview") -> void:
	var camp: ValeCamp=ui.game.camp
	if camp.data().is_empty():
		ui.page("camp","A place to call home","CAMP / ESTABLISH")
		ui.text(ui.scroll(ui.body),"Choose level, dry ground away from roads and settlements. Trees, rocks, bushes and small natural obstacles will be cleared when you establish camp. Houses, crypt entrances and other landmarks are protected. The green boundary reserves room for a future hamlet. Your first traveler will arrive soon after the fire is lit.","Heading",true)
		ui.button(ui.footer,"Choose a camp site",camp.begin_placement,not ui.game.travel.blocked().is_empty()); return
	var data: Dictionary=camp.data()
	ui.page("camp",data.name,"CAMP / "+tab.to_upper())
	var tabs:=ui.row(ui.body)
	for label in ["Overview","Residents","Tasks","Upgrade","Storage"]: ui.button(tabs,label,func(): show(ui,label),label==tab)
	var box:=ui.scroll(ui.body)
	match tab:
		"Overview":
			ui.text(box,"%s · Level %d · %d / %d residents" % [camp.level_data().name,data.level,data.workers.size(),camp.level_data().population],"Heading",true)
			resources(ui,box,data)
			var bar:=ProgressBar.new(); bar.max_value=maxf(1,camp.level_data().xp); bar.value=data.xp; bar.custom_minimum_size.y=24; box.add_child(bar)
			ui.text(box,"Camp XP %d / %d" % [data.xp,camp.level_data().xp] if int(data.level)<5 else "Hamlet complete","Heading")
			ui.text(box,"Upgrade pending: Camp XP is capped. Further XP is discarded; supplies and worker experience continue." if data.upgrade_pending else "Residents earn camp supplies and experience through tasks. Donations are optional.","Muted",true)
			for mission in data.active.values(): ui.text(box,"%s · %s · %d min remaining" % [mission.task.name,", ".join(mission.workers.map(func(id): return data.workers[id].name)),maxi(0,ceili(float(mission.end)-ValeCamp.now()))],"",true)
			var name:=LineEdit.new(); name.text=data.name; name.max_length=32; box.add_child(name)
			ui.button(box,"Rename camp",func(): if not name.text.strip_edges().is_empty(): data.name=name.text.strip_edges(); State.save_requested.emit(); show(ui))
			ui.button(box,"Travel home",func(): ui.game.travel.go({"id":"camp","name":data.name,"address":data.address}))
			ui.text(box,"Camp management [G] · Atlas [Tab]","Muted",true)
		"Residents":
			ui.text(box,"Population %d / %d · %d mission slots" % [data.workers.size(),camp.level_data().population,camp.level_data().slots],"Heading")
			if not data.candidate.is_empty(): ui.button(box,"Meet "+data.candidate.name+" by the task board",func(): candidate(ui))
			elif data.workers.size()>=int(camp.level_data().population): ui.text(box,"The camp is full. Improve it to welcome more residents.","Muted",true)
			else: ui.text(box,"Next traveler in approximately %d game minutes" % maxi(0,ceili(float(data.next_traveler)-ValeCamp.now())),"Muted",true)
			for worker in data.workers.values():
				ui.text(box,"%s · Level %d · %s" % [worker.name,worker.level,worker.residence],"Heading",true)
				ui.text(box,"%s · XP %d / %d · %s" % [worker.activity,worker.xp,int(worker.level)*50,worker.trait],"",true)
				ui.text(box,skill_text(worker),"Muted",true)
				ValeProfessionPages.occupations(ui,box,worker)
		"Tasks":
			resources(ui,box,data)
			ui.text(box,"Board cycle %d · %d / %d missions active" % [data.cycle,data.active.size(),camp.level_data().slots],"Heading")
			ui.button(box,"Refresh offers · %d Camp Gold" % camp.config.refresh_gold,func(): confirm(ui,"Refresh the task board?","Spend %d Camp Gold to replace the displayed offers. Active missions continue." % camp.config.refresh_gold,func(): camp.refresh_board(); show(ui,"Tasks"),func(): show(ui,"Tasks")),int(data.gold)<int(camp.config.refresh_gold))
			for task in data.offers:
				var reason: String=camp.task_reason(task)
				ui.text(box,"%s · %s · %d residents · %.1f h" % [task.name,task.category,task.workers,float(task.minutes)/60],"Heading",true)
				ui.text(box,"Rewards: %d XP · %d Food · %d Materials · %d Gold · %d worker XP" % [task.rewards.xp,task.rewards.food,task.rewards.materials,task.rewards.gold,task.rewards.worker_xp],"Muted",true)
				if not reason.is_empty(): ui.text(box,"Locked: "+reason,"Muted",true)
				ui.button(box,"Choose residents",func(): assign(ui,task),not reason.is_empty())
		"Upgrade":
			resources(ui,box,data)
			ui.text(box,camp.level_data().description,"Heading",true)
			if int(data.level)<5:
				var next: Dictionary=camp.config.levels[int(data.level)]
				ui.text(box,"Next: "+next.name+" — "+next.description,"",true)
				ui.text(box,"Cost: %d Food · %d Materials · %d Camp Gold" % [camp.level_data().cost.food,camp.level_data().cost.materials,camp.level_data().cost.gold],"Heading",true)
				ui.text(box,camp.upgrade_reason(),"Muted",true)
				ui.button(box,"Improve the camp",func(): confirm(ui,"Build "+next.name+"?","Spend the listed camp supplies. Camp XP resets to zero and begins accumulating again; excess XP has not been banked.",func(): camp.upgrade(); show(ui,"Upgrade"),func(): show(ui,"Upgrade")),not camp.upgrade_reason().is_empty())
			else: ui.text(box,"Your hamlet has reached its final tier.","Heading")
		"Storage":
			resources(ui,box,data)
			ui.text(box,"Optional contributions. Your camp can progress through resident tasks without donations.","Muted",true)
			for item in camp.config.contributions:
				if not State.items.has(item): continue
				var amount: int=int(State.inventory.get(item,0))
				ui.button(box,"Give 1 %s (%d carried) → %s" % [State.items[item].name,amount,str(camp.config.contributions[item])],func(): confirm(ui,"Donate "+State.items[item].name+"?","Remove one item from your inventory and add its value to camp storage.",func(): camp.donate(item,1); show(ui,"Storage"),func(): show(ui,"Storage")),amount<1)
			ui.button(box,"Give 10 personal coins → 10 Camp Gold",func(): confirm(ui,"Contribute 10 coins?","Your personal purse decreases by 10. Camp Gold increases by 10. This does not grant Camp XP.",func(): camp.donate("coins",10); show(ui,"Storage"),func(): show(ui,"Storage")),State.coins<10)
			if data.buildings.has("0"): ui.text(box,"Your personal household chest is inside your camp home.","Muted",true)

static func resources(ui: ValeInterface,parent: Node,data: Dictionary) -> void:
	ui.text(parent,"Food %d    Materials %d    Camp Gold %d" % [data.food,data.materials,data.gold],"Heading",true)
static func skill_text(worker: Dictionary) -> String:
	var values: Array[String]=[]
	for skill in worker.skills: values.append(str(skill).capitalize()+" "+str(worker.skills[skill]))
	return " · ".join(values)

static func candidate(ui: ValeInterface) -> void:
	var camp: ValeCamp=ui.game.camp
	if camp.data().candidate.is_empty(): show(ui,"Residents"); return
	var person: Dictionary=camp.data().candidate
	ui.page("camp_candidate",person.name,"A TRAVELER AT YOUR FIRE")
	ui.text(ui.scroll(ui.body),"%s · Level %d\n%s\n\nA place to sleep and a share of honest work. May I join your camp?" % [person.trait,person.level,skill_text(person)],"Heading",true)
	ui.text(ui.body,camp.meeting_reason(),"Muted",true)
	ui.button(ui.footer,"Welcome to camp",func(): camp.recruit(); show(ui,"Residents"),camp.data().workers.size()>=int(camp.level_data().population) or not camp.meeting_reason().is_empty())
	ui.button(ui.footer,"Decline",func(): camp.refuse(); ui.hud.close_modal(),not camp.meeting_reason().is_empty())

static func assign(ui: ValeInterface,task: Dictionary) -> void:
	ui.page("camp_assign",task.name,"CHOOSE THE PARTY")
	var selected: Array=[]
	var box:=ui.scroll(ui.body)
	ui.text(box,"Select %d residents · Level %d · %s %d · %.1f game hours" % [task.workers,task.worker_level,task.skill,task.skill_level,float(task.minutes)/60],"Heading",true)
	for worker in ui.game.camp.data().workers.values():
		var check:=CheckBox.new(); check.text="%s · Level %d · %s %d · %s" % [worker.name,worker.level,task.skill,worker.skills[task.skill],"Available" if worker.assignment=="" else "On mission"]
		check.disabled=worker.assignment!="" or worker.get("role","")!="" or int(worker.level)<int(task.worker_level) or int(worker.skills[task.skill])<int(task.skill_level)
		box.add_child(check); check.toggled.connect(func(pressed):
			if pressed: selected.append(worker.id)
			else: selected.erase(worker.id))
	var error:=ui.text(box,"","Muted",true)
	ui.button(ui.footer,"Send party",func():
		var reason: String=ui.game.camp.task_reason(task,selected)
		if selected.size()!=int(task.workers): reason="Select exactly %d residents." % task.workers
		if reason.is_empty() and ui.game.camp.assign(task.contract,selected): show(ui,"Tasks")
		else: error.text=reason)
	ui.button(ui.footer,"Back",func(): show(ui,"Tasks"))

static func debug(ui: ValeInterface) -> void:
	ui.page("camp_debug","Phase 7 tools","DEVELOPMENT / MAP AND CAMP")
	var box:=ui.scroll(ui.body)
	var camp: ValeCamp=ui.game.camp
	ui.text(box,"Logical origin: %s, %s · tile cache %d / %d" % [ui.game.generator.origin_x,ui.game.generator.origin_z,ui.game.cartography.cache.size(),ValeCartography.LIMIT],"Muted",true)
	ui.button(box,"Reveal loaded area",func(): for key in ui.game.generator.blueprints: ui.game.generator.chart_chunk(key))
	ui.button(box,"Hide map discovery",func(): ui.game.generator.discovered.clear(); ui.game.cartography.forget_cache())
	ui.button(box,"Regenerate map tiles",ui.game.cartography.forget_cache)
	ui.button(box,"Place marker here",func(): ui.game.cartography.add_marker(ui.game.cartography.player_address()))
	ui.button(box,"Clear custom markers",func(): State.map_data.markers.clear())
	ui.button(box,"Find a camp clearing",func(): ui.game.phase7_find_clearing())
	if camp.data().is_empty():
		ui.button(box,"Establish here if valid",func(): camp.establish(ui.game.generator.address(ui.game.player.position)))
		return
	for resource in ["food","materials","gold","xp"]: ui.button(box,"Add 100 "+resource,func(): camp.add_rewards({resource:100}); show(ui))
	ui.button(box,"Spawn traveler",camp.candidate)
	ui.button(box,"Recruit traveler",func(): camp.recruit())
	ui.button(box,"Complete all active tasks",func():
		for mission in camp.data().active.values(): mission.end=ValeCamp.now()
		camp.resolve())
	ui.button(box,"Advance 1 game day",func(): camp.advance(1440))
	ui.button(box,"Refresh board free",func(): camp.refresh_board(false))
	ui.button(box,"Force upgrade pending",func(): camp.add_rewards({"xp":99999}))
	ui.button(box,"Apply eligible upgrade",func(): camp.upgrade())
	for tier in range(1,6): ui.button(box,"Preview tier "+str(tier),func(): camp.data().level=tier; camp.data().tier=tier; camp.data().xp=0; camp.data().upgrade_pending=false; camp.sync_visual(true); ui.hud.close_modal())
