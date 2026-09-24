class_name ValeMenus
extends Control
var hud: ValeHUD
var selected: String="rustic_sword"
var reveal_tween: Tween
var busy: bool=false
var sort_mode: int=0
var pending_reveal: String=""
var shrine_zoom: float=-1

func flow_text(parent: Control, value: String, size: int, color: Color) -> Label:
	var node:=hud.label(value,Vector2.ZERO,Vector2(250,0),size,color,parent)
	node.custom_minimum_size.x=250
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return node

func ability_menu() -> void:
	clear()
	var i: int=0
	for id in State.ability_data:
		var data: Dictionary=State.ability_data[id]
		var x: float=25+(i%2)*395
		var y: float=91+floori(i/2.0)*125
		icon(PixelArt.item_icon(data.icon,Color(data.color)),Vector2(x,y),Vector2(35,35))
		text(data.name+"  ·  %ds" % int(data.cooldown),Vector2(x+47,y),Vector2(325,30),17,Color(data.color))
		text(data.description,Vector2(x,y+36),Vector2(365,48),13)
		for slot in 2:
			button(("✓ " if State.abilities[slot]==id else "")+"Slot %d" % (slot+1),Vector2(x+slot*145,y+87),Vector2(135,30),func(): State.set_ability(slot,id); ability_menu())
		i+=1
	text("1 / 2 cast your equipped abilities. Primary attacks follow your weapon type.\nSword & greatsword · Warrior   Daggers · Rogue   Bow · Ranger   Staff · Mage",Vector2(25,475),Vector2(575,50),12,hud.MUTED)

func quests() -> void:
	ValeLifeMenus.open_journal(hud)

func legacy_quests() -> void:
	var y: float=91
	for id in State.quest_data:
		var q: Dictionary=State.quest_data[id]
		var progress: int=int(State.quest_progress.get(id,0))
		var status: String="Completed" if State.completed_quests.has(id) else ("Return to Rowan" if progress>=int(q.count) else "%d / %d" % [progress,int(q.count)])
		if not State.quest_progress.has(id): status="Speak to Rowan"
		text(q.name,Vector2(30,y),Vector2(510,24),18,hud.GOLD)
		text(status,Vector2(555,y+2),Vector2(210,24),13,hud.MUTED)
		text(q.description,Vector2(30,y+29),Vector2(730,36),14)
		y+=80
	text("THE MOONSEED  ·  "+("Returned to Rowan" if State.flags.returned else ("Return it to Rowan" if State.flags.moonseed else "Find the silver light in the final crypt chamber")),Vector2(30,420),Vector2(730,35),13,hud.MUTED)

func add_trade_button(npc_id: String) -> void:
	hud.ui.add_trade(npc_id)

func shop(npc_id: String) -> void:
	ValeLifeMenus.open_shop(hud,npc_id)

func legacy_shop(npc_id: String) -> void:
	if npc_id=="smith":
		call_deferred("resize_shop")
	hud.open_modal("shop",State.npc_data[npc_id].name+"'s wares","VILLAGE TRADE")
	hud.modal_text.visible=false
	text("Your purse: %d copper" % State.coins,Vector2(30,87),Vector2(560,30),17,hud.GOLD)
	var offers: Array=[{"id":"iron_sword","cost":45},{"id":"leather_vest","cost":50}] if npc_id=="smith" else [{"id":"trail_tonic","cost":12}]
	if npc_id=="smith":
		for id in ["iron_greatsword","twin_daggers","apprentice_staff","oak_bow"]: offers.append({"id":id,"cost":35})
	var y: float=140
	for offer in offers:
		text(State.items[offer.id].name,Vector2(30,y),Vector2(310,35))
		var buy:=button("Buy · %d copper" % int(offer.cost),Vector2(360,y-4),Vector2(230,36),func():
			if State.coins<int(offer.cost): return
			State.coins-=int(offer.cost)
			State.add_item(offer.id)
			shop(npc_id))
		buy.disabled=State.coins<int(offer.cost)
		y+=53
	if npc_id=="merchant":
		button("Sell materials · 3 copper each",Vector2(30,220),Vector2(560,36),func():
			var total: int=0
			for id in State.inventory.keys():
				if State.items[id].kind=="material":
					total+=int(State.inventory[id])
					State.inventory.erase(id)
			State.coins+=total*3
			State.changed.emit()
			shop(npc_id))

func resize_shop() -> void:
	if hud.modal_kind!="shop": return
	hud.modal_panel.position.y=85
	hud.modal_panel.size.y=550
	hud.modal_button.position.y=496

func shrine(result: String = "") -> void:
	clear()
	var shard_label:=text("%d  ASTRAL SHARDS" % State.astral_shards,Vector2(30,84),Vector2(650,26),13,hud.GOLD)
	shard_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var rates: Array[String]=[]
	for rate in State.relic_data.rates: rates.append("%s %d%%" % [rate.rarity,int(rate.weight)])
	text("  ·  ".join(rates),Vector2(25,121),Vector2(670,30),12,hud.MUTED).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var gem:=icon(PixelArt.item_icon("gem",hud.GOLD),Vector2(302,166),Vector2(112,112))
	var title:=text("A small light, waiting",Vector2(30,282),Vector2(660,40),23,hud.PAPER)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var description:=text("Offer one shard to receive a relic. Equip it in your satchel.",Vector2(45,329),Vector2(630,65),14,hud.MUTED)
	description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	if not result.is_empty():
		var item: Dictionary=State.items[result]
		gem.texture=PixelArt.item_icon(item.icon,Color(item.color))
		title.text=item.name+"  ·  "+item.rarity
		title.add_theme_color_override("font_color",Color(item.color))
		description.text=item.description
		button("Equip relic",Vector2(280,426),Vector2(190,36),func(): State.equip(result); hud.show_toast("Equipped "+item.name))
	var wish:=button("Wish · %d shard" % int(State.relic_data.cost),Vector2(30,426),Vector2(200,36),func():
		if busy: return
		var id: String=State.summon()
		if id.is_empty(): return
		busy=true
		pending_reveal=id
		shard_label.text="%d  ASTRAL SHARDS" % State.astral_shards
		title.text="The stone remembers…"
		description.text="A light answers your wish."
		var color:=Color(State.items[id].color)
		Feel.sound("shrine",.75,.8)
		Feel.ring(hud.world,hud.player.global_position,2.0,color,2.4)
		Feel.burst(hud.world,hud.player.global_position,color,12)
		button("Skip reveal",Vector2(280,426),Vector2(190,36),finish_reveal)
		gem.pivot_offset=gem.size*.5
		reveal_tween=create_tween()
		reveal_tween.tween_property(gem,"scale",Vector2(1.25,1.25),1.2).set_trans(Tween.TRANS_SINE)
		reveal_tween.parallel().tween_property(gem,"modulate",color.lightened(.25),1.2)
		reveal_tween.tween_callback(func(): title.text=State.items[id].rarity.to_upper()+" · A light takes shape")
		reveal_tween.tween_property(gem,"scale",Vector2(1.5,1.5),.65)
		reveal_tween.tween_property(gem,"scale",Vector2(.3,.3),.55).set_trans(Tween.TRANS_BACK)
		reveal_tween.tween_callback(finish_reveal))
	wish.disabled=State.astral_shards<int(State.relic_data.cost)
	if wish.disabled: description.text+="\nEarn more shards from quests, enemies and hidden caches."

func finish_reveal() -> void:
	if pending_reveal.is_empty(): return
	var id: String=pending_reveal
	pending_reveal=""
	Feel.sound("level" if State.items[id].rarity=="Legendary" else "loot",.65)
	shrine(id)

func clear() -> void:
	if reveal_tween and reveal_tween.is_valid(): reveal_tween.kill()
	busy=false
	for child in get_children():
		remove_child(child)
		child.queue_free()

func text(value: String, pos: Vector2, extent: Vector2, size: int = 15, color: Color = Color("efe7ce")) -> Label:
	var node:=hud.label(value,pos,extent,size,color,self)
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.clip_text=true
	node.size=extent
	return node

func button(value: String, pos: Vector2, extent: Vector2, callback: Callable, parent: Node = self) -> Button:
	var node:=Button.new()
	node.text=value
	node.position=pos
	node.size=extent
	hud.style_button(node)
	parent.add_child(node)
	node.pressed.connect(callback)
	node.pressed.connect(func(): Feel.sound("click",.2))
	return node

func icon(texture: Texture2D, pos: Vector2, extent: Vector2, parent: Node = self) -> TextureRect:
	var node:=TextureRect.new()
	node.position=pos
	node.size=extent
	node.texture=texture
	node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func stats_text(item: Dictionary) -> String:
	var lines: Array[String]=[]
	for key in item.get("stats",{}):
		var value: float=item.stats[key]
		if key not in ["max_hp","attack","defense","move_speed"]:
			lines.append("%+d%% %s" % [roundi(value*100),key.replace("_"," ")])
		else: lines.append("%+d %s" % [int(value),key.replace("_"," ")])
	return "\n".join(lines)

func inventory() -> void:
	clear()
	if not State.inventory.has(selected): selected=State.inventory.keys()[0] if not State.inventory.is_empty() else ""
	text("PACK  ·  %d TYPES" % State.inventory.size(),Vector2(24,83),Vector2(155,25),11,hud.MUTED)
	var sorting:=OptionButton.new()
	sorting.position=Vector2(195,79)
	sorting.size=Vector2(178,29)
	for option in ["Sort: rarity","Sort: type","Sort: name"]: sorting.add_item(option)
	sorting.select(sort_mode)
	hud.style_button(sorting)
	add_child(sorting)
	sorting.item_selected.connect(func(value: int): sort_mode=value; inventory())
	var scroll:=ScrollContainer.new()
	scroll.position=Vector2(24,117)
	scroll.size=Vector2(350,306)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var grid:=GridContainer.new()
	grid.columns=5
	grid.add_theme_constant_override("h_separation",7)
	grid.add_theme_constant_override("v_separation",7)
	scroll.add_child(grid)
	var sorted_ids: Array=State.inventory.keys()
	sorted_ids.sort_custom(func(a: String,b: String):
		var first: Dictionary=State.items[a]
		var second: Dictionary=State.items[b]
		if sort_mode==0 and first.rarity!=second.rarity: return State.RARITY_COLORS.keys().find(first.rarity)>State.RARITY_COLORS.keys().find(second.rarity)
		if sort_mode==1 and first.kind!=second.kind: return first.kind<second.kind
		return first.name<second.name)
	for id in sorted_ids:
		var item: Dictionary=State.items[id]
		var color:=Color(item.color)
		var cell:=button("",Vector2.ZERO,Vector2(60,68),func(): selected=id; inventory(),grid)
		cell.custom_minimum_size=Vector2(60,68)
		cell.add_theme_stylebox_override("normal",hud.style(Color("304844") if selected==id else Color("1c3638"),color))
		cell.tooltip_text="%s · %s\n%s\n%s" % [item.name,item.rarity,item.description,stats_text(item)]
		icon(PixelArt.item_icon(item.icon,color),Vector2(13,7),Vector2(36,36),cell)
		hud.label("×%d" % State.inventory[id],Vector2(28,47),Vector2(30,18),11,hud.PAPER,cell)
		if id in State.equipment.values(): hud.label("E",Vector2(6,47),Vector2(18,18),10,hud.GOLD,cell)
	text("Select an item to inspect it. E marks equipped items.",Vector2(24,430),Vector2(350,35),11,hud.MUTED)
	if not selected.is_empty():
		var item: Dictionary=State.items[selected]
		var color:=Color(item.color)
		var detail_scroll:=ScrollContainer.new()
		detail_scroll.position=Vector2(395,91)
		detail_scroll.size=Vector2(277,355)
		detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		add_child(detail_scroll)
		var details:=VBoxContainer.new()
		details.custom_minimum_size.x=256
		details.add_theme_constant_override("separation",10)
		detail_scroll.add_child(details)
		var picture:=icon(PixelArt.item_icon(item.icon,color),Vector2.ZERO,Vector2(60,60),details)
		picture.custom_minimum_size=Vector2(60,60)
		flow_text(details,item.name,21,color)
		flow_text(details,item.rarity.to_upper()+" / "+item.kind.to_upper(),11,hud.MUTED)
		flow_text(details,item.description,14,hud.PAPER)
		flow_text(details,stats_text(item),13,hud.GOLD)
		for affix in item.get("affixes",[]): flow_text(details,State.affix_data[affix].name+": "+State.affix_data[affix].description,12,hud.MUTED)
		if item.has("slot") and State.equipment[item.slot]!=selected:
			var loadout: Dictionary=State.equipment.duplicate()
			loadout[item.slot]=selected
			var before:=State.stats()
			var after:=State.stats(loadout)
			flow_text(details,"IF EQUIPPED · CHANGE",11,hud.MUTED)
			for stat in after:
				var difference: float=float(after[stat])-float(before.get(stat,0))
				if absf(difference)<.001: continue
				var value: String="%+.1f" % difference if stat in ["max_hp","attack","defense","move_speed"] else "%+d%%" % roundi(difference*100)
				flow_text(details,value+" "+stat.replace("_"," "),12,Color("acd8a2") if difference>0 else Color("e5a69a"))
		if item.has("slot"):
			var is_equipped: bool=State.equipment[item.slot]==selected
			button("Unequip" if is_equipped else "Equip to "+item.slot,Vector2(395,459),Vector2(260,36),func():
				if is_equipped: State.unequip(item.slot)
				else: State.equip(selected))
		elif item.kind=="consumable": button("Use  ·  +%d HP" % int(item.get("heal",0)),Vector2(395,459),Vector2(260,36),func(): ValeLife.use_item(selected); inventory())
	text("EQUIPMENT",Vector2(693,83),Vector2(260,25),11,hud.MUTED)
	var row: int=0
	for slot in State.equipment:
		var id: String=State.equipment[slot]
		var item: Dictionary=State.items.get(id,{})
		var y: float=117+row*65
		var node:=button("",Vector2(690,y),Vector2(260,57),func():
			if not id.is_empty(): selected=id; inventory())
		if not item.is_empty(): icon(PixelArt.item_icon(item.icon,Color(item.color)),Vector2(9,11),Vector2(32,32),node)
		hud.label(slot.to_upper(),Vector2(51,7),Vector2(196,16),10,hud.MUTED,node)
		var equipment_name:=hud.label(item.get("name","Empty slot"),Vector2(51,25),Vector2(196,25),13,Color(item.get("color","a4b8af")),node)
		equipment_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		node.tooltip_text=item.get("name","Empty slot")
		row+=1
	var s:=State.stats()
	text("Level %d   ·   Attack %d   ·   Defense %d\nMax HP %d   ·   Speed %.2f   ·   Crit %d%%" % [State.level,int(s.attack),int(s.defense),int(s.max_hp),s.move_speed,roundi(s.crit*100)],Vector2(24,477),Vector2(350,53),13,hud.PAPER)
	text("Bonuses apply while equipped.\nOne relic may be worn at a time.",Vector2(693,452),Vector2(260,36),11,hud.MUTED)
