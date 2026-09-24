class_name ValePhase7Save
extends RefCounted
static func number(value: Variant) -> bool: return (value is int or value is float) and is_finite(float(value)) and float(value)>=0 and float(value)<1e15
static func valid(root: Dictionary) -> bool:
	var map: Variant=root.get("map_data",{"markers":{},"next_id":1})
	if not map is Dictionary or not map.get("markers") is Dictionary or not number(map.get("next_id")): return false
	if map.markers.size()>32: return false
	for id in map.markers:
		var m: Variant=map.markers[id]
		if not m is Dictionary or m.get("id")!=id or not m.get("name") is String or not m.get("icon") in ValeCartography.ICONS or not ValeSave.valid_address(m.get("address")): return false
	var camp: Variant=root.get("camp_data",{})
	if not camp is Dictionary: return false
	if camp.is_empty(): return true
	if not ValeSave.valid_address(camp.get("address")) or not camp.get("name") is String or not camp.get("upgrade_pending") is bool: return false
	for key in ["level","tier","xp","food","materials","gold","next_worker","next_traveler","cycle","next_job","founded"]:
		if not number(camp.get(key)): return false
	if int(camp.level)<1 or int(camp.level)>5 or int(camp.tier)!=int(camp.level): return false
	for key in ["workers","candidate","active","contributions","buildings"]:
		if not camp.get(key) is Dictionary: return false
	if not camp.get("offers") is Array or not camp.get("completed") is Array or camp.workers.size()>10 or camp.active.size()>4 or camp.offers.size()>15: return false
	var people: Array=camp.workers.values().duplicate()
	if not camp.candidate.is_empty(): people.append(camp.candidate)
	for p in people:
		if not p is Dictionary: return false
		for key in ["id","name","assignment","activity","residence","trait"]:
			if not p.get(key) is String: return false
		for key in ["level","xp","joined"]:
			if not number(p.get(key)): return false
		if not p.get("skills") is Dictionary or not p.get("appearance") is Dictionary: return false
		for skill in ["gathering","mining","hunting","trading","scouting"]:
			if not number(p.skills.get(skill)): return false
	var used: Dictionary={}
	for id in camp.active:
		var mission: Variant=camp.active[id]
		if not mission is Dictionary or mission.get("id")!=id or not number(mission.get("start")) or not number(mission.get("end")) or not mission.get("workers") is Array or not task(mission.get("task")): return false
		for worker in mission.workers:
			if not camp.workers.has(worker) or used.has(worker) or camp.workers[worker].assignment!=id: return false
			used[worker]=true
	for worker in camp.workers.values():
		if worker.assignment!="" and not used.has(worker.id): return false
	for offer in camp.offers:
		if not task(offer): return false
	return true

static func task(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["id","name","category","skill","contract"]:
		if not value.get(key) is String: return false
	for key in ["level","workers","worker_level","skill_level","minutes"]:
		if not number(value.get(key)): return false
	if not value.get("facilities") is Array or not value.get("cost") is Dictionary or not value.get("rewards") is Dictionary: return false
	for key in ["xp","food","materials","gold","worker_xp"]:
		if not number(value.rewards.get(key)): return false
	for key in value.cost:
		if key not in ["food","materials","gold"] or not number(value.cost[key]): return false
	return true
