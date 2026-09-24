class_name ValeNarrativeUI
extends RefCounted

static func portrait(ui: ValeInterface,parent: Node,id: String,size: Vector2=Vector2(100,120)) -> void:
	var path: String=ValeNarrative.companions.get(id,{}).get("portrait","")
	if not path.is_empty() and ResourceLoader.exists(path):
		var picture: TextureRect=ui.picture(parent,load(path),size)
		picture.size_flags_vertical=Control.SIZE_SHRINK_BEGIN

static func dialogue(ui: ValeInterface,id: String) -> void:
	var row: Dictionary=ValeNarrative.dialogues[id]
	var speaker: String=ValeNarrative.companions.get(row.speaker,State.npc_data.get(row.speaker,{})).get("name",row.speaker)
	ui.page("story_dialogue",speaker,"CONVERSATION")
	var columns:=ui.row(ui.body); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	portrait(ui,columns,row.speaker,Vector2(165,210))
	var body:=ui.scroll(columns); ui.text(body,ui.game.narrative.dialogue_text(id),"Heading",true)
	for index in row.choices.size():
		var choice: Dictionary=row.choices[index]
		if not ui.game.narrative.choice_visible(choice): continue
		var reason: String=ui.game.narrative.requirement_text(choice.get("conditions",[]))
		ui.button(body,choice.text+("\nRequires: "+reason if reason!="" else ""),func(): ui.game.narrative.choose(index),reason!="")
	if ui.game.narrative.history.size()>1:
		ui.button(ui.footer,"Recent conversation",func(): history(ui,id))

static func history(ui: ValeInterface,return_to: String) -> void:
	ui.page("conversation_history","Words remembered","RECENT CONVERSATION")
	var box:=ui.scroll(ui.body)
	for line in ui.game.narrative.history: ui.text(box,line,"",true)
	ui.button(ui.footer,"Back",func(): dialogue(ui,return_to))

static func roster(ui: ValeInterface,selected: String="") -> void:
	ui.page("companions","Your company","COMPANIONS / O    ·    COMMANDS / Z")
	var box:=ui.scroll(ui.body)
	for id in ValeNarrative.companions:
		var row: Dictionary=State.narrative.companions[id]; var definition: Dictionary=ValeNarrative.companions[id]
		if not row.recruited and not State.narrative.seen.has(id): continue
		var columns:=ui.row(box); portrait(ui,columns,id)
		var detail:=ui.vbox(columns,true)
		ui.text(detail,definition.name+" · "+definition.role.capitalize(),"Heading")
		ui.text(detail,definition.biography,"",true)
		ui.text(detail,(ValeNarrative.tier(int(row.approval))+" · Level %d · " % row.level+("Traveling with you" if State.narrative.active==id else row.camp_state)) if row.recruited else "You have crossed paths.","Muted",true)
		if not row.recruited: continue
		var completed: int=0
		for quest_id in definition.personal:
			if State.completed_quests.has(quest_id): completed+=1
		ui.text(detail,"Personal story · %d / %d completed" % [completed,definition.personal.size()],"Muted")
		var actions:=ui.row(detail)
		ui.button(actions,"Rest at camp" if State.narrative.active==id else "Travel together",func(): ui.game.party.set_active("" if State.narrative.active==id else id); roster(ui,id))
		ui.button(actions,"Equipment & abilities",func(): roster(ui,"" if selected==id else id))
		if selected!=id: continue
		for slot in ["Weapon","Armor","Accessory"]:
			var ids: Array[String]=[""]; var choices: Array=[slot+" · Empty"]
			if row.equipment[slot]!="": ids.append(row.equipment[slot]); choices.append(slot+" · "+State.items[row.equipment[slot]].name+" (equipped)")
			for item in State.inventory:
				if int(State.inventory[item])>0 and ui.game.party.accepts_equipment(id,slot,item) and not item in ids: ids.append(item); choices.append(slot+" · "+State.items[item].name)
			ui.option(detail,choices,maxi(0,ids.find(row.equipment[slot])),func(i): ui.game.party.equip(id,slot,ids[i]); roster(ui,id))
		for ability in definition.abilities: ui.text(detail,ability.name+" · "+ability.description,"",true)
		if State.narrative.flags.get(id+"_personal_complete",false): ui.text(detail,"Personal bond · "+definition.passive,"Heading",true)
	if box.get_child_count()==0: ui.text(box,"Meet fellow travelers along the roads. A shieldbearer is keeping watch east of Willowmere.","",true)
	ui.button(ui.footer,"Commands",func(): commands(ui))
	ui.button(ui.footer,"Lore",func(): lore(ui))

static func commands(ui: ValeInterface) -> void:
	ui.page("party_commands","Traveling together","ONE ACTIVE COMPANION")
	var box:=ui.scroll(ui.body)
	var actor: ValeCompanionActor=ui.game.party.active()
	if not is_instance_valid(actor): ui.text(box,"Invite a recruited companion from the company page.","",true)
	else:
		ui.text(box,"%s · %d / %d health" % [ValeNarrative.companions[actor.id].name,actor.hp,actor.max_hp],"Heading")
		ui.text(box,"Follow keeps a loose formation. Wait holds this spot. Passive avoids combat; Defensive protects the party; Aggressive engages nearby foes.","",true)
		for value in ["follow","wait","passive","defensive","aggressive"]:
			ui.button(box,value.capitalize()+(" · Active" if value in [State.narrative.command,State.narrative.stance] else ""),func(): ui.game.party.command(value); ui.hud.close_modal())
	ui.button(ui.footer,"Company",func(): roster(ui))

static func lore(ui: ValeInterface,category: String="All") -> void:
	ui.page("lore","The vale remembers","PEOPLE / FACTIONS / PLACES / CREATURES / RELICS / HISTORY")
	var categories: Array=["All","People","Factions","Places","Creatures","Relics","History"]
	ui.option(ui.body,categories,maxi(0,categories.find(category)),func(i): lore(ui,categories[i]))
	var box:=ui.scroll(ui.body)
	for id in State.narrative.lore:
		var entry: Dictionary=ValeNarrative.lore.get(id,{})
		if entry.is_empty(): continue
		if category!="All" and entry.category!=category: continue
		ui.text(box,entry.title+" · "+entry.category,"Heading"); ui.text(box,entry.text,"",true)
	if box.get_child_count()==0: ui.text(box,"Stories and discoveries will fill these pages.","Muted")

static func debug(ui: ValeInterface) -> void:
	ui.page("narrative_debug","Story field tools","DEBUG / F10")
	var box:=ui.scroll(ui.body)
	for id in ValeNarrative.companions:
		var row:=ui.row(box); ui.text(row,ValeNarrative.companions[id].name,"Heading")
		ui.button(row,"Recruit",func(): ui.game.party.recruit(id); debug(ui))
		ui.button(row,"Active",func(): ui.game.party.set_active(id); debug(ui))
		ui.button(row,"+15 approval",func(): ui.game.narrative.approve(id,15,"debug_"+str(Time.get_ticks_msec())); debug(ui))
		ui.button(row,"−15 approval",func(): ui.game.narrative.approve(id,-15,"debug_"+str(Time.get_ticks_msec())); debug(ui))
		ui.text(box,"%s · approval %d · %s · %s" % [id,State.narrative.companions[id].approval,ValeNarrative.tier(State.narrative.companions[id].approval),State.narrative.companions[id].state],"Muted",true)
		var thresholds: Array=[-10,0,20,40,65]
		var tiers: Array=["Distant","Acquaintance","Trusted","Close","Loyal"]
		ui.option(box,tiers,maxi(0,tiers.find(ValeNarrative.tier(State.narrative.companions[id].approval))),func(i): State.narrative.companions[id].approval=thresholds[i]; State.save_requested.emit(); debug(ui))
		ui.button(row,"Meet",func():
			var at: Dictionary=ui.game.narrative.location_address(ValeNarrative.companions[id].location)
			ui.hud.close_modal(); ui.game.generator.teleport_logical(int(at.x),int(at.z),ValeSave.vector(at.local)+Vector3(2,0,0)))
	ui.button(box,"Down active companion",func():
		var actor: ValeCompanionActor=ui.game.party.active()
		if actor: actor.invulnerability=0; actor.take_damage(99999)
		ui.hud.close_modal())
	ui.button(box,"Regroup active companion",func(): ui.game.party.after_transition(); ui.hud.close_modal())
	for faction in State.faction_data:
		var row:=ui.row(box); ui.text(row,State.faction_data[faction].name+" · "+str(ValeLife.reputation(faction)),"Muted",true)
		for amount in [-20,20]: ui.button(row,str(amount),func(): State.life_data.reputation[faction]=clampi(ValeLife.reputation(faction)+amount,-100,100); State.save_requested.emit(); debug(ui))
		var thresholds: Array=[-60,-10,0,30,70]
		var tiers: Array=["Hostile","Unfriendly","Neutral","Friendly","Honored"]
		ui.option(box,tiers,maxi(0,tiers.find(ValeLife.tier(ValeLife.reputation(faction)))),func(i): State.life_data.reputation[faction]=thresholds[i]; State.save_requested.emit(); debug(ui))
	for id in State.quest_data:
		if State.quest_data[id].type!="narrative": continue
		var row:=ui.row(box); ui.text(row,State.quest_data[id].name,"Muted",true)
		ui.button(row,"Start",func(): ui.game.narrative.start(id); debug(ui))
		ui.button(row,"Advance",func(): ui.game.narrative.advance(id); debug(ui))
		ui.button(row,"Complete",func():
			ui.game.narrative.start(id)
			for step in State.quest_data[id].stages.size(): ui.game.narrative.advance(id)
			debug(ui))
		ui.button(row,"Reset",func(): State.quest_progress.erase(id); State.completed_quests.erase(id); State.narrative.counters.erase(id); State.save_requested.emit(); debug(ui))
		ui.button(row,"Visit",func():
			var step: Dictionary=ui.game.narrative.objective(id)
			if step.has("location"):
				var at: Dictionary=ui.game.narrative.location_address(step.location)
				ui.hud.close_modal(); ui.game.generator.teleport_logical(int(at.x),int(at.z),ValeSave.vector(at.local)+Vector3(2,0,0)))
	ui.text(box,"Flags: "+JSON.stringify(State.narrative.flags),"Muted",true)
	var flag_row:=ui.row(box)
	var flag_key:=LineEdit.new(); flag_key.placeholder_text="Story flag ID"; flag_key.max_length=160; flag_key.size_flags_horizontal=Control.SIZE_EXPAND_FILL; flag_row.add_child(flag_key)
	var flag_value:=LineEdit.new(); flag_value.placeholder_text="JSON value: true or \"shelter\""; flag_value.max_length=170; flag_value.size_flags_horizontal=Control.SIZE_EXPAND_FILL; flag_row.add_child(flag_value)
	ui.button(flag_row,"Set flag",func():
		var value: Variant=JSON.parse_string(flag_value.text)
		if flag_key.text.strip_edges().is_empty() or not (value is bool or value is String or ValePhase8Save.number(value,-1e6,1e6)): return
		State.narrative.flags[flag_key.text.strip_edges()]=value; State.save_requested.emit(); debug(ui))
	ui.text(box,"WORLD EVENTS · at most two unresolved","Heading")
	for kind in ValeWorldEvents.definitions:
		ui.button(box,"Spawn · "+ValeWorldEvents.definitions[kind].name,func():
			var at: Dictionary=ui.game.world_events.find_site(kind)
			if at.is_empty(): at=ui.game.generator.address(ui.game.party.safe_position(ui.game.player.position+Vector3(7,0,0)))
			var id: String=ui.game.world_events.spawn(kind,at,true)
			ui.hud.show_toast("Encounter created: "+id if id!="" else "No suitable site, or two encounters are still active."); ui.hud.close_modal())
	for id in ui.game.world_events.records():
		var entry: Dictionary=State.life_data.events[id]
		var row:=ui.row(box); ui.text(row,id+" · "+entry.kind+" · "+entry.state,"Muted",true)
		ui.button(row,"Visit",func(): ui.hud.close_modal(); ui.game.generator.teleport_logical(int(entry.address.x),int(entry.address.z),ValeSave.vector(entry.address.local)+Vector3(0,.1,3)))
		ui.button(row,"Resolve",func(): ui.game.world_events.complete(id,true); debug(ui))
		ui.button(row,"Expire",func(): ui.game.world_events.expire(id); debug(ui))
