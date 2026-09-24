class_name ValeExploration
extends Node
## Additional resources use their own hash stream and IDs; legacy world generation stays stable.
var game: Node
var clock: float=0
var treasures: Dictionary={}
var decorated: Dictionary={}

func _ready() -> void: game=get_tree().current_scene

func decorate(key: String,chunk: Node3D) -> void:
	if decorated.get(key,0)==chunk.get_instance_id(): return
	decorated[key]=chunk.get_instance_id()
	var rng:=RandomNumberGenerator.new(); rng.seed=(str(State.world_seed)+"/profession/"+key).hash()
	var plan: ValeRegionPlan=game.generator.planner(key)
	var local:=Vector2(rng.randf_range(4,28),rng.randf_range(4,28))
	if not plan.clear(local,2.5): return
	var coord: Vector2i=game.generator.local_coord(key)
	var p: Vector3=Vector3(coord.x*32+local.x,plan.height_at(local),coord.y*32+local.y)
	if game.generator.camp_reserved(Vector2(p.x,p.z),20): return
	var weights: Vector3=plan.weights(local)
	var id: String=""
	if plan.water_distance(local)<10: id="river_herb" if rng.randf()<.7 else "night_bloom"
	elif weights.z>.4: id=["coal","silver_ore","star_ore"][rng.randi_range(0,2)]
	elif weights.y>.45: id=["hardwood","ancient_wood","healing_herb","night_bloom"][rng.randi_range(0,3)]
	else: id="healing_herb" if rng.randf()<.65 else "dawn_flower"
	if int(State.resource_data[id].min_level)>=15 and rng.randf()>.35: return
	var row: Dictionary=State.resource_data[id]
	var tree: bool=row.tool=="axe"
	var asset: String=game.world.NATURE+("tree_oak.glb" if tree else ("rock_largeA.glb" if row.tool=="pickaxe" else "plant_bush.glb"))
	var height: float=(5.8 if id=="ancient_wood" else 4.2) if tree else (1.35 if row.tool=="pickaxe" else .75)
	var node:=ValeResource.spawn(game.world,chunk,"%s/phase8/%s" % [key,id],id,chunk.to_local(p),asset,height,rng.randf()*360,tree)
	node.title=State.items[id].name; node.add_to_group("profession_resources")
	if not tree:
		for mesh in node.model.find_children("*","MeshInstance3D",true,false): mesh.material_override=game.world.mat(row.color)

func create_map() -> Dictionary:
	if game.player.position.x>900: return {}
	var active: int=0
	for chart in State.activities.treasures.values():
		if not chart.claimed: active+=1
	if active>=16: return {}
	for id in State.activities.treasures.keys():
		if State.activities.treasures.size()<=96: break
		if State.activities.treasures[id].claimed: State.activities.treasures.erase(id)
	var serial: int=State.activities.next_treasure
	var rng:=RandomNumberGenerator.new(); rng.seed=(str(State.world_seed)+"/treasure/"+str(serial)).hash()
	var keys: Array=game.generator.active_chunks.keys(); keys.sort()
	for attempt in 80:
		if keys.is_empty(): return {}
		var key: String=keys[rng.randi_range(0,keys.size()-1)]
		if not game.generator.discovered.has(key): continue
		var plan: ValeRegionPlan=game.generator.planner(key)
		var p:=Vector2(rng.randf_range(5,27),rng.randf_range(5,27))
		if not plan.clear(p,3) or plan.water_distance(p)<3: continue
		var coord: Vector2i=game.generator.local_coord(key)
		var pos:=Vector3(coord.x*32+p.x,plan.height_at(p),coord.y*32+p.y)
		if game.generator.camp_reserved(Vector2(pos.x,pos.z),21) or not game.mounts.clear_spot(pos): continue
		var id: String="map_"+str(serial)
		var center: Vector3=pos+Vector3(rng.randf_range(-7,7),0,rng.randf_range(-7,7))
		var record: Dictionary={"id":id,"name":"Weathered chart %d" % serial,"address":game.generator.address(pos),"area":game.generator.address(center),"radius":12.0,"claimed":false,"revealed":true,"rewarded":false}
		State.activities.treasures[id]=record; State.activities.next_treasure+=1
		State.add_item("treasure_map")
		State.notification.emit("A weathered chart reveals a search area on your atlas.")
		State.save_requested.emit(); return record
	return {}

func assemble() -> bool:
	if int(State.inventory.get("map_fragment",0))<3: return false
	var chart: Dictionary=create_map()
	if chart.is_empty(): State.notification.emit("Explore more safe ground before deciphering this chart."); return false
	ValeLife.consume("map_fragment",3); State.save_requested.emit(); return true

func claim(id: String) -> bool:
	if not State.activities.treasures.has(id): return false
	var record: Dictionary=State.activities.treasures[id]
	if record.claimed or record.rewarded or not treasures.has(id) or not is_instance_valid(treasures[id]): return false
	if game.player.global_position.distance_to(treasures[id].global_position)>2.4: return false
	record.claimed=true; record.rewarded=true
	State.coins+=40+int(id.trim_prefix("map_"))*2
	State.add_item("resin",2); State.add_item("bait_rare",2)
	if int(State.inventory.get("treasure_map",0))>0: ValeLife.consume("treasure_map",1)
	State.life_data.unlocks.cook_harvest_pie=true
	State.notification.emit("Cache found · copper, resin, moon bait and a harvest pie recipe")
	treasures[id].queue_free(); treasures.erase(id)
	State.changed.emit(); State.save_requested.emit(); return true

func reset() -> void:
	for node in treasures.values():
		if is_instance_valid(node): node.queue_free()
	treasures.clear(); decorated.clear()

func _process(delta: float) -> void:
	clock-=delta
	if clock>0: return
	clock=.8
	for key in game.generator.active_chunks:
		if game.generator.lifecycle.get(key,"")=="ACTIVE": decorate(key,game.generator.active_chunks[key])
	for key in decorated.keys():
		if not game.generator.active_chunks.has(key): decorated.erase(key)
	if game.player.position.x>900: return
	for node in get_tree().get_nodes_in_group("profession_resources"):
		if node.global_position.distance_to(game.player.global_position)<12 and not State.activities.rare_notes.has(node.persistent_id):
			State.activities.rare_notes[node.persistent_id]={"name":node.title,"address":game.generator.address(node.global_position),"item":node.resource_id}
	for id in State.activities.treasures:
		var record: Dictionary=State.activities.treasures[id]
		var a: Dictionary=record.address
		var near: bool=not record.claimed and absi(int(a.x)-game.generator.origin_x)<=2 and absi(int(a.z)-game.generator.origin_z)<=2
		if near: near=game.generator.position_of(a).distance_to(game.player.global_position)<9
		if not near:
			if treasures.has(id):
				if is_instance_valid(treasures[id]): treasures[id].queue_free()
				treasures.erase(id)
			continue
		if treasures.has(id) and is_instance_valid(treasures[id]): treasures[id].position=game.generator.position_of(a); continue
		var node: ValeInteractable=game.world.interactable("treasure","Buried traveler's chest",game.generator.position_of(a),game.world)
		node.set_meta("phase8_action","treasure"); node.set_meta("treasure",id)
		node.model=game.world.place("res://assets/3d/phase7/chest.glb",Vector3(0,-.12,0),.55,12,node)
		treasures[id]=node
