class_name ValeResidents
extends RefCounted
## Persistent identities; routine positions are reconstructed from the global clock.
static var navigation: Dictionary={}

static func travel_route(actor: Node3D,goal: Vector3) -> PackedVector3Array:
	# Small transient grid follows the traveler. Never shares settlement grids across origin shifts.
	var game: Node=actor.get_tree().current_scene
	var space:=actor.get_world_3d().direct_space_state
	var ray:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3(0,.8,0),goal+Vector3(0,.8,0),1)
	if space.intersect_ray(ray).is_empty(): return PackedVector3Array([goal])
	var center:=Vector2i(roundi(actor.global_position.x),roundi(actor.global_position.z))
	var grid:=AStarGrid2D.new(); grid.region=Rect2i(center-Vector2i(13,13),Vector2i(27,27)); grid.cell_size=Vector2.ONE
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES; grid.update()
	var sphere:=SphereShape3D.new(); sphere.radius=.42
	var query:=PhysicsShapeQueryParameters3D.new(); query.shape=sphere; query.collision_mask=1
	for x in range(center.x-13,center.x+14):
		for z in range(center.y-13,center.y+14):
			var y: float=game.generator.landscape.height(Vector2(x,z)) if actor.global_position.x<900 else actor.global_position.y
			query.transform.origin=Vector3(x,y+.7,z)
			grid.set_point_solid(Vector2i(x,z),not space.intersect_shape(query,1).is_empty())
	var end:=Vector2i(clampi(roundi(goal.x),center.x-12,center.x+12),clampi(roundi(goal.z),center.y-12,center.y+12))
	grid.set_point_solid(center,false)
	var result:=PackedVector3Array()
	for p in grid.get_point_path(center,end,true): result.append(Vector3(p.x,actor.global_position.y,p.y))
	return result

static func bind(npc: ValeInteractable,id: String,settlement: String,home: String,work: String,tavern: String) -> void:
	if not State.residents.has(id):
		State.residents[id]={"id":id,"npc_id":npc.npc_id,"settlement":settlement,"home":home,"work":work,"tavern":tavern,"identity":State.npc_data[npc.npc_id].duplicate(true)}
	else: State.npc_data[npc.npc_id]=State.residents[id].identity.duplicate(true)
	npc.set_meta("resident",id)
	for child in npc.get_children():
		if child is ValeSchedule: child.block=""; child.initialized=false

static func destination(record: Dictionary) -> String:
	var hour: float=float(State.life_data.minute)/60
	if record.settlement=="player_camp":
		var worker: Dictionary=State.camp_data.get("workers",{}).get(record.id,{})
		if worker.is_empty() or worker.assignment!="": return ""
		return record.home if hour<6 or hour>=22 or State.life_data.weather=="Storm" else ""
	if State.life_data.weather=="Storm": return record.home
	if hour<6 or hour>=22: return record.home
	if hour>=18: return record.tavern
	if hour>=12 and hour<13: return ""
	if hour>=8: return record.work
	return ""

static func door(record: Dictionary,id: String) -> Dictionary:
	return State.life_data.settlements.get(record.settlement,{}).get("buildings",{}).get(id,{})

static func route(npc: Node3D,to: Vector3) -> PackedVector3Array:
	var parent: Node3D=npc.get_parent()
	var key: int=parent.get_instance_id()
	for old in navigation.keys():
		if not is_instance_valid(navigation[old].owner.get_ref()): navigation.erase(old)
	if not navigation.has(key):
		var grid:=AStarGrid2D.new(); grid.region=Rect2i(-28,-28,57,57); grid.cell_size=Vector2.ONE
		grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES; grid.update()
		var shape:=SphereShape3D.new(); shape.radius=.38
		var query:=PhysicsShapeQueryParameters3D.new(); query.shape=shape; query.collision_mask=1
		var space:=npc.get_world_3d().direct_space_state
		for x in range(-28,29):
			for z in range(-28,29):
				query.transform.origin=parent.to_global(Vector3(x,.7,z))
				if parent.name=="PlayerCamp":
					var position: Vector3=query.transform.origin
					query.transform.origin.y=npc.get_tree().current_scene.generator.landscape.height(Vector2(position.x,position.z))+.7
				grid.set_point_solid(Vector2i(x,z),not space.intersect_shape(query,1).is_empty())
		navigation[key]={"owner":weakref(parent),"grid":grid}
	var nav: AStarGrid2D=navigation[key].grid
	var a: Vector3=parent.to_local(npc.global_position); var b: Vector3=parent.to_local(to)
	var start:=Vector2i(roundi(a.x),roundi(a.z)); var end:=Vector2i(roundi(b.x),roundi(b.z))
	var points:=PackedVector3Array()
	if not nav.is_in_boundsv(start) or not nav.is_in_boundsv(end): return points
	var start_solid: bool=nav.is_point_solid(start); var end_solid: bool=nav.is_point_solid(end)
	nav.set_point_solid(start,false); nav.set_point_solid(end,false)
	for p in nav.get_point_path(start,end): points.append(parent.to_global(Vector3(p.x,0,p.y)))
	nav.set_point_solid(start,start_solid); nav.set_point_solid(end,end_solid)
	if not points.is_empty(): points.append(to)
	return points
