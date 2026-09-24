class_name ValeSchedule
extends Node
var npc: ValeInteractable
var home: Vector3
var work: Vector3
var square: Vector3
var nav:=AStar3D.new()
var route:=PackedVector3Array()
var block: String=""
var activity: String="Working"
var initialized: bool=false
var timer: float=0
var phase: float=0
var greeting: float=0
var destination_id: String=""

func clear_step(point: Vector3) -> bool:
	var shape:=SphereShape3D.new(); shape.radius=.3
	var query:=PhysicsShapeQueryParameters3D.new(); query.shape=shape; query.collision_mask=1
	query.transform.origin=point+Vector3(0,.7,0)
	return npc.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func avoid_people(direction: Vector3,player: Node3D) -> Vector3:
	var steering:=direction
	var people: Array[Node3D]=[player]
	for other in npc.get_parent().get_children():
		if other is ValeInteractable and other.kind=="npc" and other!=npc and other.visible: people.append(other)
	for other in people:
		var away: Vector3=npc.global_position-other.global_position; away.y=0
		var distance: float=away.length()
		if distance<1.15 and away.dot(direction)<.3:
			# Pass a stationary person instead of waiting indefinitely at the doorway.
			var side:=Vector3(-direction.z,0,direction.x)
			if side.dot(away)<0: side=-side
			steering+=side*(1.4-distance)+away.normalized()*maxf(0,1-distance)*2
	return steering.normalized()

static func attach(actor: ValeInteractable,workplace: Vector3,plaza: Vector3) -> void:
	var controller:=ValeSchedule.new(); controller.npc=actor; controller.work=workplace
	controller.home=workplace+Vector3(0,0,-1); controller.square=plaza
	actor.set_meta("schedule",true); actor.add_child(controller)

func shift_origin(delta: Vector3) -> void:
	home-=delta; work-=delta; square-=delta
	for i in route.size(): route[i]-=delta

func _process(delta: float) -> void:
	if State.modal or State.paused: return
	var game: Node=get_tree().current_scene
	if game.player.position.x>900: return
	phase+=delta; timer-=delta; greeting=maxf(0,greeting-delta)
	var near: float=npc.global_position.distance_to(game.player.global_position)
	var record: Dictionary=State.residents.get(npc.get_meta("resident",""),{})
	if timer<=0:
		timer=.3 if near<35 else 2.0
		var hour: float=float(State.life_data.minute)/60
		var next: String=ValeResidents.destination(record) if not record.is_empty() else ("home" if hour<6 or hour>=22 else "work")
		if next!=block or not initialized:
			var first: bool=not initialized; initialized=true; block=next; destination_id=next
			npc.visible=true
			var goal: Vector3=work if next.is_empty() and hour>=8 and hour<18 and not (hour>=12 and hour<13) else square
			if not record.is_empty() and not next.is_empty():
				var building: Dictionary=ValeResidents.door(record,next)
				if not building.is_empty(): goal=game.generator.position_of(building.door)
			if first and not next.is_empty() and not record.is_empty():
				npc.global_position=goal; npc.visible=false; route.clear()
			else: route=ValeResidents.route(npc,goal)
			activity="Walking to "+("the square" if next.is_empty() else ("home" if next==record.get("home","") else "work / tavern"))
	if not npc.visible: return
	# Doors are interaction zones: enter when within reach instead of crowding one exact point.
	if not destination_id.is_empty() and not route.is_empty() and npc.global_position.distance_to(route[-1])<1.35:
		route.clear(); npc.visible=false; activity="Inside"; return
	if near>55:
		if not route.is_empty(): npc.global_position=route[-1]; route.clear()
		return
	var camera: ValeCamera=game.rig
	if near<3 and game.player.attack_timer>.25 and not game.player.gathering.busy:
		activity="Startled"; npc.sprite.scale.y=.92
		npc.sprite.play("idle_%d" % camera.screen_direction(game.player.global_position-npc.global_position))
		return
	npc.sprite.scale.y=1
	if near<2.6 and greeting<=0:
		greeting=35
		if npc.npc_id!="rowan": State.notification.emit(State.npc_data[npc.npc_id].name+": "+("Good to see you again." if ValeLife.reputation("hearth")>=30 else "Good day, traveler."))
	if not route.is_empty():
		var offset: Vector3=route[0]-npc.global_position
		if offset.length()<.15: route.remove_at(0)
		else:
			var direction: Vector3=avoid_people(offset.normalized(),game.player)
			var step: float=delta*1.25
			var next: Vector3=npc.global_position+direction*minf(offset.length(),step)
			if clear_step(next): npc.global_position=next
			npc.sprite.play("walk_%d" % camera.screen_direction(direction))
	else:
		if not destination_id.is_empty(): npc.visible=false; activity="Inside"; return
		var direction:=Vector3.BACK
		if near<3: direction=game.player.global_position-npc.global_position
		else:
			for other in npc.get_parent().get_children():
				if other is ValeInteractable and other.kind=="npc" and other!=npc and other.visible and other.position.distance_to(npc.position)<4:
					direction=other.position-npc.position; break
		activity="Talking" if int(phase+abs(npc.npc_id.hash()%7))%14<7 else "Watching the square"
		if npc.npc_id=="willow_carpenter": activity="Working timber"
		npc.sprite.play(("slash_" if activity=="Working timber" else "idle_")+str(camera.screen_direction(direction)))
		npc.sprite.rotation.z=sin(phase*2)*.025 if activity=="Talking" else 0.0
