class_name ValeEconomyPages
extends RefCounted

static func shop(ui: ValeInterface,npc: String) -> void:
	var merchant: Dictionary=State.merchant_data[ValeLife.category(npc)]
	ui.page("shop",State.npc_data[npc].name+"’s wares","TRADE / "+State.faction_data[merchant.faction].name.to_upper())
	var tabs:=ui.row(ui.body)
	for tab in ["Buy","Sell"]: ui.button(tabs,tab,func(): ui.shop_tab=tab; shop(ui,npc))
	ui.text(ui.body,"%d copper · %s (%d) · Stock returns each dawn" % [State.coins,ValeLife.tier(ValeLife.reputation(merchant.faction)),ValeLife.reputation(merchant.faction)],"Muted",true)
	var list:=ui.scroll(ui.body)
	var offers: Array=ValeLife.offers(npc) if ui.shop_tab=="Buy" else State.inventory.keys().map(func(id): return [id,10])
	for offer in offers:
		var id: String=offer[0]; var selling: bool=ui.shop_tab=="Sell"
		var item: Dictionary=State.items.get(id,{"name":"Astral shard" if id=="astral_shard" else "Pattern: "+id.trim_prefix("recipe:").capitalize(),"description":"Unlocks a new recipe at its crafting station.","rarity":"Rare"})
		if selling and item.get("kind","")=="quest": continue
		var base: int=int(offer[1])
		if selling:
			for original in ValeLife.offers(npc):
				if original[0]==id: base=int(original[1])
		var cost: int=ValeLife.item_price(npc,id,selling)
		var stock: int=int(State.inventory.get(id,0)) if selling else 8-int(State.life_data.stock.get("%d/%s/%s" % [State.life_data.day,npc,id],0))
		var line:=ui.row(list); ui.picture(line,ui.icon(id),Vector2(52,52))
		var description:=ui.vbox(line,true)
		ui.text(description,item.name+" · ×%d" % stock,"Heading",true)
		ui.text(description,item.rarity+" · "+item.description,"Muted",true)
		if item.has("stats"): ui.text(description,ui.hud.rpg.stats_text(item),"Muted",true)
		if item.has("slot"):
			var before: Dictionary=State.stats(); var loadout: Dictionary=State.equipment.duplicate(); loadout[item.slot]=id
			var after: Dictionary=State.stats(loadout); var changes: PackedStringArray=[]
			for stat in after:
				var diff: float=float(after[stat])-float(before.get(stat,0))
				if absf(diff)>.001: changes.append("%+.1f %s" % [diff,stat.replace("_"," ")])
			if not changes.is_empty(): ui.text(description,"Compared with worn gear: "+", ".join(changes),"Muted",true)
		var learned: bool=id.begins_with("recipe:") and State.life_data.unlocks.has(State.crafting_data[id.trim_prefix("recipe:")].get("unlock",""))
		var disabled: bool=ValeLife.reputation(merchant.faction)<=-50 or stock<=0 or learned or (State.coins<cost and not selling) or (selling and id in State.equipment.values() and stock<=1)
		ui.button(description,"Pattern learned" if learned else ("Sell" if selling else "Buy")+" · %d copper" % cost,func(): ValeLife.trade(npc,id,selling); shop(ui,npc),disabled)

static func crafting(ui: ValeInterface,station: ValeInteractable) -> void:
	ui.page("crafting",station.title,"CRAFTING / MATERIALS BECOME EQUIPMENT")
	ui.text(ui.body,"%d copper · %s recipes" % [State.coins,str(station.get_meta("station")).capitalize()],"Muted")
	var filters:=ui.row(ui.body)
	for category in ["All","Equipment","Supplies"]:
		ui.button(filters,category,func(): ui.category=category; crafting(ui,station))
	var list:=ui.scroll(ui.body)
	for id in State.crafting_data:
		var recipe: Dictionary=State.crafting_data[id]
		if recipe.station!=station.get_meta("station",""): continue
		var equipment: bool=State.items[recipe.output].has("slot")
		if ui.category=="Equipment" and not equipment: continue
		if ui.category=="Supplies" and equipment: continue
		var line:=ui.row(list); ui.picture(line,ui.icon(recipe.output),Vector2(64,64))
		var details:=ui.vbox(line,true)
		ui.text(details,recipe.name+" → "+State.items[recipe.output].name+" ×%d" % recipe.count,"Heading",true)
		var ingredients: PackedStringArray=[]
		var consumed: Dictionary=ValeLife.crafting_inputs(recipe)
		for item in consumed: ingredients.append("%s %d/%d" % [State.items[item].name,State.inventory.get(item,0),consumed[item]])
		if id=="cook_grilled_fish": ui.text(details,"Any fresh fish; uses the least valuable species carried.","Muted",true)
		if recipe.get("profession","")=="cooking": ui.text(details,State.items[recipe.output].description,"",true)
		ui.text(details," · ".join(ingredients)+" · %d copper" % recipe.cost,"Muted",true)
		var error: String=ValeLife.craft_error(id,station)
		ui.button(details,"Craft" if error.is_empty() else error,func(): ValeLife.craft(id,station); crafting(ui,station),not error.is_empty())
