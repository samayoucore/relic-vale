class_name ValeInventoryPage
extends RefCounted
const CATEGORIES=["All","Weapons","Armor","Consumables","Materials","Tools","Wood","Stone","Ore","Plants","Fish","Seeds","Crops","Rare materials","Relics","Quest"]

static func show(ui: ValeInterface) -> void:
	if not ui.category in CATEGORIES: ui.category="All"
	ui.page("inventory","Your satchel","BELONGINGS / EQUIPMENT")
	var filters:=ui.row(ui.body)
	ui.option(filters,CATEGORIES,CATEGORIES.find(ui.category),func(i): ui.category=CATEGORIES[i]; show(ui))
	ui.option(filters,["Rarity","Type","Name"],ui.sort_mode,func(i): ui.sort_mode=i; show(ui))
	ui.text(filters,"%d copper · %d shards" % [State.coins,State.astral_shards],"Muted")
	var columns:=ui.row(ui.body); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var left:=ui.scroll(columns); left.size_flags_stretch_ratio=1.2
	var grid:=GridContainer.new(); grid.columns=5 if ui.size.x>1050 else 3; left.add_child(grid)
	var ids: Array=State.inventory.keys()
	ids.sort_custom(func(a,b):
		var first: Dictionary=State.items[a]; var second: Dictionary=State.items[b]
		if ui.sort_mode==0 and first.rarity!=second.rarity: return State.RARITY_COLORS.keys().find(first.rarity)>State.RARITY_COLORS.keys().find(second.rarity)
		if ui.sort_mode==1 and first.kind!=second.kind: return first.kind<second.kind
		return first.name<second.name)
	if not State.inventory.has(ui.selected): ui.selected=str(ids[0]) if not ids.is_empty() else ""
	for id in ids:
		var item: Dictionary=State.items[id]
		var matches: bool=ui.category=="All" or {"Tools":"tool","Weapons":"weapon","Armor":"armor","Consumables":"consumable","Materials":"material","Relics":"relic","Quest":"quest"}.get(ui.category,"")==item.kind
		if item.get("material_category","")==ui.category: matches=true
		if not matches: continue
		var slot:=ui.vbox(grid)
		var cell:=ui.button(slot,"",func(): ui.selected=id; ui.hud.rpg.selected=id; show(ui))
		cell.custom_minimum_size=Vector2(66,66); cell.icon=ui.icon(id); cell.expand_icon=true; cell.add_theme_constant_override("icon_max_width",50)
		cell.tooltip_text="%s · %s\n%s\n%s" % [item.name,item.rarity,item.description,ui.hud.rpg.stats_text(item)]
		ui.text(slot,("E · " if id in State.equipment.values() else "")+"×%d" % State.inventory[id],"Muted")
		var rarity:=ui.text(slot,item.rarity.substr(0,3).to_upper(),"Caption")
		rarity.add_theme_color_override("font_color",Color(item.color))
	var details:=ui.scroll(columns); details.custom_minimum_size.x=250
	if not ui.selected.is_empty():
		var item: Dictionary=State.items[ui.selected]
		ui.picture(details,ui.icon(ui.selected),Vector2(88,88))
		ui.text(details,item.name,"Heading",true)
		var rarity:=ui.text(details,item.rarity.to_upper()+" / "+item.kind.to_upper(),"Caption",true)
		rarity.add_theme_color_override("font_color",Color(item.color))
		ui.text(details,item.description,"",true)
		ui.text(details,ui.hud.rpg.stats_text(item),"Muted",true)
		for affix in item.get("affixes",[]): ui.text(details,State.affix_data[affix].name+": "+State.affix_data[affix].description,"Muted",true)
		if item.has("slot"):
			var equipped: bool=State.equipment[item.slot]==ui.selected
			if not equipped:
				var loadout: Dictionary=State.equipment.duplicate(); loadout[item.slot]=ui.selected
				var before: Dictionary=State.stats(); var after: Dictionary=State.stats(loadout)
				ui.text(details,"IF EQUIPPED","Caption")
				for stat in after:
					var diff: float=float(after[stat])-float(before.get(stat,0))
					if absf(diff)<.001: continue
					ui.text(details,("%+.1f" % diff if stat in ["max_hp","attack","defense","move_speed"] else "%+d%%" % roundi(diff*100))+" "+stat.replace("_"," "),"Muted",true)
			ui.button(details,"Unequip" if equipped else "Equip to "+item.slot,func():
				if equipped: State.unequip(item.slot)
				else: State.equip(ui.selected)
				Feel.sound("equip",.3); show(ui))
		elif item.kind=="consumable": ui.button(details,"Use item",func(): ValeLife.use_item(ui.selected); show(ui))
		elif item.id.begins_with("seed_"): ui.button(details,"Choose for planting",func(): ui.game.cultivation.chosen_seed=item.id.trim_prefix("seed_"); ui.hud.close_modal())
		elif item.has("bait"): ui.button(details,"Select bait",func(): State.activities.bait=item.id; State.save_requested.emit(); ValeProfessionPages.show(ui,"Fishing"))
		elif item.id=="treasure_map": ui.button(details,"Read charts",func(): ValeProfessionPages.show(ui,"Exploration"))
	ui.text(details,"EQUIPMENT","Caption")
	for slot in State.equipment:
		var id: String=State.equipment[slot]
		ui.button(details,slot+" · "+State.items.get(id,{}).get("name","Empty"),func():
			if not id.is_empty(): ui.selected=id; show(ui),id.is_empty())
	var s: Dictionary=State.stats()
	ui.text(ui.body,"%s · Level %d · HP %d/%d · Attack %d · Defense %d · Crit %d%%" % [State.character_name,State.level,State.hp,State.max_hp,s.attack,s.defense,roundi(s.crit*100)],"Muted",true)
