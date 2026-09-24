class_name ValeJourneyPages
extends RefCounted

static func journal(ui: ValeInterface) -> void:
	ui.page("quests","Field notes","QUESTS / ALLIANCES")
	var filters: Array=["Active","Available","Completed","Main","Companion","Faction","Side quests"]
	ui.option(ui.body,filters,maxi(0,filters.find(ui.quest_filter)),func(i): ui.quest_filter=filters[i]; journal(ui))
	var columns:=ui.row(ui.body); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var quests:=ui.scroll(columns); quests.size_flags_stretch_ratio=2
	for id in State.quest_data:
		var q: Dictionary=State.quest_data[id]
		var done: bool=State.completed_quests.has(id); var active: bool=State.quest_progress.has(id) and not done
		if q.type=="narrative":
			# Unmet and future chains remain undisclosed until an authored conversation starts them.
			if not active and not done: continue
			if ui.quest_filter=="Active" and not active: continue
			if ui.quest_filter=="Completed" and not done: continue
			if ui.quest_filter=="Available": continue
			if ui.quest_filter in ["Main","Companion","Faction","Side quests"] and q.category!=("Side" if ui.quest_filter=="Side quests" else ui.quest_filter): continue
			ui.text(quests,q.name+" · "+q.category,"Heading",true)
			if q.category=="Companion" and ValeNarrative.companions.has(q.npc):
				var personal: Array=ValeNarrative.companions[q.npc].personal
				var completed: int=0
				for quest_id in personal:
					if State.completed_quests.has(quest_id): completed+=1
				ui.text(quests,ValeNarrative.companions[q.npc].name+" · %d / %d personal chapters" % [completed,personal.size()],"Muted",true)
			ui.text(quests,q.description,"Muted",true)
			var step: Dictionary=ui.game.narrative.objective(id)
			ui.text(quests,"Completed" if done else step.get("text","Return to your contact."),"",true)
			if active:
				var buttons:=ui.row(quests)
				ui.button(buttons,"Tracked" if State.narrative.tracked==id else "Track",func(): State.narrative.tracked=id; State.changed.emit(); journal(ui))
				ui.button(buttons,"Show on map",func(): show_objective(ui,id),ui.game.narrative.objective_address(id).is_empty())
			continue
		if ui.quest_filter=="Active" and not active: continue
		if ui.quest_filter=="Completed" and not done: continue
		if ui.quest_filter=="Available" and (active or done or not ValeLife.available(id)): continue
		if ui.quest_filter=="Faction" and not q.has("chain"): continue
		if ui.quest_filter=="Companion": continue
		if ui.quest_filter=="Main": continue
		if ui.quest_filter=="Side quests" and q.has("chain"): continue
		ui.text(quests,q.name,"Heading",true)
		ui.text(quests,"Completed" if done else ("%d / %d" % [State.quest_progress.get(id,0),q.count] if active else "Speak to your patron"),"Caption")
		ui.text(quests,q.description,"",true)
		ui.text(quests,"Report to "+State.npc_data.get(q.get("npc","rowan"),{}).get("name","Rowan")+" · %d XP · %d copper" % [q.reward.xp,q.reward.coins],"Muted",true)
	if quests.get_child_count()==0: ui.text(quests,"No entries here yet. Speak with residents along the lantern roads.","Muted",true)
	var factions:=ui.scroll(columns); factions.custom_minimum_size.x=205
	ui.text(factions,"ALLIANCES","Caption")
	for id in State.faction_data:
		ui.text(factions,State.faction_data[id].name,"Heading",true)
		ui.text(factions,ValeLife.tier(ValeLife.reputation(id))+" · %d" % ValeLife.reputation(id),"Caption",true)
		ui.text(factions,State.faction_data[id].description,"Muted",true)
	ui.text(factions,"Friendly: 10% lower prices. Honored: 20%. Hostile residents refuse trade.","Muted",true)
	ui.button(factions,"Company [O]",func(): ValeNarrativeUI.roster(ui))
	ui.button(factions,"Lore",func(): ValeNarrativeUI.lore(ui))

static func show_objective(ui: ValeInterface,id: String) -> void:
	var address: Dictionary=ui.game.narrative.objective_address(id)
	if address.is_empty(): return
	State.narrative.tracked=id; State.changed.emit()
	ui.map_page()
	for node in ui.body.get_children():
		if node is ValeAtlas:
			node.center_x=int(address.x); node.center_z=int(address.z); node.pan=-Vector2(address.local[0],address.local[2])*node.zoom/32; node.queue_redraw()

static func abilities(ui: ValeInterface) -> void:
	ui.page("abilities","Ways of the road","ABILITIES / TWO ACTIVE SLOTS")
	var list:=ui.scroll(ui.body)
	for id in State.ability_data:
		var data: Dictionary=State.ability_data[id]
		var line:=ui.row(list); ui.picture(line,ui.icon(id))
		var desc:=ui.vbox(line,true); ui.text(desc,data.name+" · %ds" % data.cooldown,"Heading",true); ui.text(desc,data.description,"Muted",true)
		var actions:=ui.row(desc)
		for slot in 2: ui.button(actions,("Equipped · " if State.abilities[slot]==id else "Equip · ")+"Slot %d" % (slot+1),func(): State.set_ability(slot,id); abilities(ui))

static func character(ui: ValeInterface) -> void:
	ui.page("character","Your traveler","APPEARANCE / IDENTITY")
	var columns:=ui.row(ui.body); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var look: Dictionary=State.appearance.duplicate(true)
	var preview:=ui.picture(columns,PixelArt.character_frames(false,look).get_frame_texture("idle_2",0),Vector2(170,220))
	preview.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var fields:=ui.scroll(columns)
	ui.text(fields,"Traveler name","Caption")
	var name:=LineEdit.new(); name.text=State.character_name; name.max_length=20; name.custom_minimum_size.y=40; fields.add_child(name)
	for part in ["skin","hair","outfit"]:
		ui.text(fields,part.capitalize(),"Muted")
		ui.option(fields,{"skin":["Warm sand","Copper","Umber","Porcelain","Deep walnut"],"hair":["Chestnut","Flax","Raven","Auburn","Silver"],"outfit":["River teal","Sage","Rosewood","Heather","Wheat"]}[part],int(look[part]),func(i): look[part]=i; preview.texture=PixelArt.character_frames(false,look).get_frame_texture("idle_2",0))
	var cape:=CheckBox.new(); cape.text="Traveling cloak"; cape.button_pressed=look.cape; fields.add_child(cape)
	cape.toggled.connect(func(value): look.cape=value; preview.texture=PixelArt.character_frames(false,look).get_frame_texture("idle_2",0))
	ui.button(ui.footer,"Keep this traveler",func():
		var first_steps: bool=not State.appearance_confirmed
		State.character_name=name.text.strip_edges() if not name.text.strip_edges().is_empty() else "Traveler"
		State.appearance=PixelArt.clean_appearance(look); State.appearance_confirmed=true; State.appearance_changed.emit(); State.changed.emit(); ui.hud.close_modal(); State.save_requested.emit()
		if first_steps: ValeMenuPages.onboarding(ui))

static func shrine(ui: ValeInterface,result: String="") -> void:
	ui.page("shrine","The wishing stone","ASTRAL RELICS")
	var list:=ui.scroll(ui.body)
	ui.picture(list,ui.icon(result if not result.is_empty() else "moonstone_heart"),Vector2(110,110))
	ui.text(list,"%d astral shards" % State.astral_shards,"Heading")
	var rates: PackedStringArray=[]
	for rate in State.relic_data.rates: rates.append("%s %d%%" % [rate.rarity,rate.weight])
	ui.text(list," · ".join(rates),"Muted",true)
	if not result.is_empty():
		ui.text(list,State.items[result].name,"Heading",true)
		ui.text(list,State.items[result].rarity.to_upper(),"Caption")
		ui.text(list,State.items[result].description,"",true)
		ui.button(list,"Equip relic",func(): State.equip(result); ui.hud.show_toast("Equipped "+State.items[result].name))
	else: ui.text(list,"Offer one shard. A memory of the vale answers; every relic changes your journey.","",true)
	ui.button(list,"Wish · 1 shard",func():
		if ui.busy: return
		ui.busy=true
		var id: String=State.summon()
		if id.is_empty(): ui.busy=false; return
		ui.text(list,"The stone remembers…","Caption")
		Feel.ring(ui.hud.world,ui.hud.player.global_position,2,Color(State.items[id].color),1)
		await ui.get_tree().create_timer(.8).timeout
		ui.busy=false
		if ui.hud.modal_kind=="shrine": shrine(ui,id),State.astral_shards<1 or ui.busy)
