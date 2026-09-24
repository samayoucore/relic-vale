class_name ValePhase9Save
extends RefCounted

static func valid(root: Dictionary) -> bool:
	if not root.has("narrative"): return int(root.get("version",0))<9
	var n: Variant=root.narrative
	if not n is Dictionary: return false
	if not root.get("life",{}) is Dictionary or not root.get("generated_items",{}) is Dictionary: return false
	for key in ValeNarrative.defaults():
		if not n.has(key): return false
	for key in ["companions","flags","approval_flags","counters","locations","lore","seen"]:
		if not n[key] is Dictionary or n[key].size()>4096: return false
	if not n.active is String or not n.tracked is String: return false
	if n.command not in ["follow","wait"] or n.stance not in ["passive","defensive","aggressive"]: return false
	if not ValePhase8Save.number(n.event_serial,1,1e9) or not ValePhase8Save.number(n.event_last): return false
	if float(n.event_serial)!=floorf(float(n.event_serial)): return false
	for id in n.companions:
		var row: Variant=n.companions[id]
		if not ValeNarrative.companions.has(id) or not row is Dictionary: return false
		if not row.get("recruited") is bool or not ValePhase8Save.number(row.get("level"),1,100): return false
		if not ValePhase8Save.number(row.get("approval"),-100,100) or not ValePhase8Save.number(row.get("hp"),0,1e6): return false
		if row.get("state") not in ["waiting","traveling","downed"] or row.get("camp_state") not in ["Resting","By the fire","Keeping watch"]: return false
		if not row.get("address") is Dictionary or (not row.address.is_empty() and not ValeSave.valid_address(row.address)): return false
		if not row.get("equipment") is Dictionary or row.equipment.size()!=3: return false
		for slot in ["Weapon","Armor","Accessory"]:
			var item: Variant=row.equipment.get(slot)
			if not item is String: return false
			if item=="": continue
			var definition: Variant=root.get("generated_items",{}).get(item,State.items.get(item,{}))
			if not definition is Dictionary: return false
			if definition.has("base"): definition=State.base_items.get(definition.base,{})
			if definition.get("slot","")!=("Body" if slot=="Armor" else slot): return false
	if n.active!="" and not n.companions.get(n.active,{}).get("recruited",false): return false
	if n.tracked!="" and not State.quest_data.has(n.tracked): return false
	for key in ["approval_flags","lore","seen"]:
		for id in n[key]:
			if not (id is String or id is StringName) or not n[key][id] is bool: return false
	for id in n.flags:
		if not (id is String or id is StringName) or str(id).length()>160: return false
		var value: Variant=n.flags[id]
		if not (value is bool or (value is String and value.length()<=160) or ValePhase8Save.number(value,-1e6,1e6)): return false
	for id in n.counters:
		if not State.quest_data.has(id) or not ValePhase8Save.number(n.counters[id],0,1e6): return false
	if not root.get("quest_progress",{}) is Dictionary: return false
	for id in root.get("quest_progress",{}):
		if State.quest_data.get(id,{}).get("type","")!="narrative": continue
		var stage: Variant=root.quest_progress[id]
		if not ValePhase8Save.number(stage,0,State.quest_data[id].stages.size()) or float(stage)!=floorf(float(stage)): return false
	for id in n.locations:
		if not ValeNarrative.locations.has(id) or not ValeSave.valid_address(n.locations[id]): return false
	var events: Variant=root.get("life",{}).get("events",{})
	if not events is Dictionary: return false
	var count: int=0; var active: int=0
	for id in events:
		if not str(id).begins_with("encounter_"): continue
		count+=1
		var row: Variant=events[id]
		if not row is Dictionary or row.get("id")!=id or not ValeWorldEvents.definitions.has(row.get("kind","")): return false
		if row.get("state") not in ["active","completed","expired"] or not row.get("discovered") is bool: return false
		if row.state=="active": active+=1
		if not ValePhase8Save.number(row.get("stage"),0,2) or not ValePhase8Save.number(row.get("created")) or not ValePhase8Save.number(row.get("expires")): return false
		if float(row.stage)!=floorf(float(row.stage)): return false
		if float(row.expires)<float(row.created): return false
		for key in ["address","walker_address"]:
			if not ValeSave.valid_address(row.get(key)): return false
		if not row.get("destination") is Dictionary: return false
		if ValeWorldEvents.definitions[row.kind].get("escort",false) and not ValeSave.valid_address(row.destination): return false
		if not row.get("defeated") is Dictionary or row.defeated.size()>ValeWorldEvents.definitions[row.kind].enemies.size(): return false
		for enemy_id in row.defeated:
			if not enemy_id is String or not enemy_id.begins_with(str(id)+"/enemy/") or row.defeated[enemy_id]!=true: return false
			var index: String=enemy_id.trim_prefix(str(id)+"/enemy/")
			if not index.is_valid_int() or str(int(index))!=index or int(index)<0 or int(index)>=ValeWorldEvents.definitions[row.kind].enemies.size(): return false
	if count>64 or active>2: return false
	return true
