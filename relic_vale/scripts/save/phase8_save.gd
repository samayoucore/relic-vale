class_name ValePhase8Save
extends RefCounted

static func number(value: Variant,minimum: float=0,maximum: float=1e12) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and float(value)<=maximum

static func valid(root: Dictionary) -> bool:
	var progress: Variant=root.get("professions",{})
	var data: Variant=root.get("activities",{})
	if not progress is Dictionary or not data is Dictionary: return false
	for id in progress:
		if not ValeProfessions.definitions.has(id) or not progress[id] is Dictionary: return false
		var p: Dictionary=progress[id]
		if not number(p.get("level"),1,25) or not number(p.get("xp"),0,100000) or not p.get("unlocks") is Array: return false
		for unlock in p.unlocks:
			if not unlock is String: return false
	for key in ["fish_journal","farm","food","mounts","treasures","rare_notes","production"]:
		if not data.get(key,{}) is Dictionary: return false
	for key in ["casts","next_treasure"]:
		if not number(data.get(key,0),0,100000000): return false
	if not data.get("bait","bait_basic") in ["bait_basic","bait_insect","bait_rare"]: return false
	if not data.get("active_mount","") is String: return false
	if not data.get("weather_history",[]) is Array: return false
	for entry in data.get("weather_history",[]):
		if not entry is Dictionary or not number(entry.get("time")) or not entry.get("weather","") in ValeLife.WEATHER: return false
	for id in data.get("fish_journal",{}):
		var record: Variant=data.fish_journal[id]
		if not ValeProfessions.fish.has(id) or not record is Dictionary or not ValeSave.valid_address(record.get("address")): return false
		for key in ["count","best_weight","best_size","day"]:
			if not number(record.get(key)): return false
		if not record.get("water") is String: return false
	for id in data.get("farm",{}):
		var p: Variant=data.farm[id]
		if not id in ["0","1","2","3","4","5","6","7"] or not p is Dictionary: return false
		if not p.get("prepared") is bool or not p.get("crop") is String: return false
		if p.crop!="" and not ValeProfessions.crops.has(p.crop): return false
		if not ValeProfessions.crops.has(p.get("replant","")): return false
		for key in ["progress","planted","watered","moist_until","last","harvests"]:
			if not number(p.get(key)): return false
	var food: Dictionary=data.get("food",{})
	if not food.is_empty():
		if not food.get("stat") in ["max_hp","damage_percent","move_percent","profession_xp","gather_speed","fishing_luck"] or not number(food.get("value"),0,100) or not number(food.get("end")): return false
		if not State.items.get(food.get("item",""),{}).has("food"): return false
	for id in data.get("mounts",{}):
		var mount: Variant=data.mounts[id]
		if not mount is Dictionary or mount.get("id")!=id or not mount.get("name") is String or not mount.get("owned") is bool or mount.get("species")!="horse": return false
		if not mount.get("state") in ["waiting","ridden","stabled"] or not mount.get("address") is Dictionary: return false
		if not mount.address.is_empty() and not ValeSave.valid_address(mount.address): return false
	if data.get("active_mount","")!="" and not data.get("mounts",{}).has(data.active_mount): return false
	for id in data.get("treasures",{}):
		var chart: Variant=data.treasures[id]
		if not chart is Dictionary or chart.get("id")!=id or not chart.get("name") is String or not ValeSave.valid_address(chart.get("address")) or not ValeSave.valid_address(chart.get("area")): return false
		if not number(chart.get("radius"),1,32): return false
		for key in ["claimed","rewarded","revealed"]:
			if not chart.get(key) is bool: return false
	for record in data.get("rare_notes",{}).values():
		if not record is Dictionary or not record.get("name") is String or not State.resource_data.has(record.get("item","")) or not ValeSave.valid_address(record.get("address")): return false
	var production: Dictionary=data.get("production",{})
	if production.has("last") and not number(production.last): return false
	if production.has("fish_bank") and not ValeSave.valid_address(production.fish_bank): return false
	for worker in root.get("camp_data",{}).get("workers",{}).values():
		var role: Variant=worker.get("role","")
		if not role is String or (role!="" and not ValeCultivation.ROLES.has(role)): return false
		if role!="" and worker.assignment!="": return false
		for key in ["role_last","role_progress"]:
			if not number(worker.get(key,0)): return false
	return true
