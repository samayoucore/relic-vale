class_name ValeBoss
extends Node
## The existing crypt guardian gains a readable, locked-target two-phase attack sequence.
var actor: Mossling
var phase: int=1
var engaged: bool=false
var action: String=""
var timer: float=1.3
var sequence: int=0
var target_point:=Vector3.ZERO
var charge_direction:=Vector3.FORWARD
var markers: Array[Node3D]=[]
var gate: Node3D
var minions: Array[Node3D]=[]
var action_history: Array[String]=[]

func _ready() -> void:
	actor=get_parent()

func cleanup_markers() -> void:
	for node in markers:
		if is_instance_valid(node): node.queue_free()
	markers.clear()

func reset() -> void:
	engaged=false
	phase=1
	action=""
	timer=1.3
	sequence=0
	cleanup_markers()
	if is_instance_valid(gate): gate.queue_free()
	for node in minions:
		if is_instance_valid(node): node.queue_free()
	minions.clear()
	for node in get_tree().get_nodes_in_group("combat_hazards"): node.queue_free()
	actor.hp=actor.max_hp
	actor.global_position=actor.origin
	actor.statuses.clear()

func tick(delta: float) -> Vector3:
	var player: ValePlayer=actor.player
	var arena: Rect2=actor.get_meta("arena",Rect2(992,-49,16,17))
	var in_arena: bool=arena.has_point(Vector2(player.global_position.x,player.global_position.z))
	if not in_arena:
		if engaged: reset()
		return Vector3.ZERO
	if not engaged:
		engaged=true
		gate=Node3D.new()
		actor.get_parent().add_child(gate)
		var world: ValeWorld=get_tree().current_scene.world
		world.box(actor.get_meta("gate_position",Vector3(1000,1,-31)),actor.get_meta("gate_size",Vector3(4.5,2,.35)),"647f86",true,gate)
		State.notification.emit("THE HOLLOW KNIGHT  ·  Watch the ground, then strike.")
		Feel.sound("slam",.5)
	if phase==1 and actor.hp<=actor.max_hp/2:
		phase=2
		cleanup_markers()
		action=""
		timer=1.25
		State.notification.emit("The oath breaks  ·  Phase II")
		Feel.ring(actor.get_parent(),actor.global_position,5,Color("bc9cdb"),.8)
		Feel.sound("shrine",.8,.75)
		for offset in [-3.0,3.0]:
			var minion: Mossling=load("res://scenes/characters/Enemy.tscn").instantiate()
			minion.position=actor.origin+Vector3(offset,0,-4)
			minion.set_meta("archetype","skeleton")
			minion.set_meta("enemy_level",3)
			actor.get_parent().add_child(minion)
			minions.append(minion)
	timer-=delta
	if action=="charging":
		if actor.global_position.distance_to(player.global_position)<1.5: player.take_damage(int(actor.config.damage)*1.2)
		for ally in get_tree().get_nodes_in_group("combat_allies"):
			if ally is ValeCompanionActor and ally.global_position.distance_to(actor.global_position)<1.5: ally.take_damage(roundi(int(actor.config.damage)*1.2))
		if timer<=0:
			action=""
			timer=1.3
		return charge_direction*11
	if not action.is_empty():
		if timer<=0: resolve()
		return Vector3.ZERO
	var to_player: Vector3=player.global_position-actor.global_position
	if timer<=0:
		var attacks: Array=["slash","charge","slam"] if phase==1 else ["slash","shockwave","charge","hazard","slam"]
		var next: String=attacks[sequence%attacks.size()]
		if next=="slash" and to_player.length()>3:
			if timer> -1.3: return to_player.normalized()*float(actor.config.speed)
			next="charge"
		sequence+=1
		begin(next)
	return Vector3.ZERO

func begin(id: String) -> void:
	action=id
	action_history.append(id)
	target_point=actor.player.global_position
	target_point.y=.02
	charge_direction=(target_point-actor.global_position).normalized()
	charge_direction.y=0
	timer={"slash":.75,"charge":1.0,"slam":1.15,"shockwave":1.0,"hazard":1.25}[id]
	var warning:=Color(.9,.6,.34,.8) if phase==1 else Color(.74,.55,.9,.8)
	match id:
		"slash": markers.append(Feel.ring(actor.get_parent(),actor.global_position,2.8,warning,0))
		"charge":
			for i in range(1,9): markers.append(Feel.ring(actor.get_parent(),actor.global_position+charge_direction*i,.58,warning,0))
		"slam": markers.append(Feel.ring(actor.get_parent(),target_point,3.1,warning,0))
		"shockwave": markers.append(Feel.ring(actor.get_parent(),actor.global_position,1.9,warning,0))
		"hazard":
			for x in [-2.0,2.0]: markers.append(Feel.ring(actor.get_parent(),target_point+Vector3(x,0,0),1.8,warning,0))
	Feel.sound("draw",.35,.65)

func resolve() -> void:
	cleanup_markers()
	var id: String=action
	action=""
	timer=1.65 if phase==1 else 1.15
	var damage: int=int(actor.config.damage)
	match id:
		"slash":
			Feel.ring(actor.get_parent(),actor.global_position,2.8,Color("e0bc80"),.3)
			if actor.player.global_position.distance_to(actor.global_position)<3: actor.player.take_damage(damage)
			for ally in get_tree().get_nodes_in_group("combat_allies"):
				if ally is ValeCompanionActor and ally.global_position.distance_to(actor.global_position)<3: ally.take_damage(damage)
			Feel.sound("heavy",.7,.8)
		"charge":
			action="charging"
			timer=.65
			Feel.sound("heavy",.75,.6)
		"slam":
			Feel.ring(actor.get_parent(),target_point,3.1,Color("c9bc91"),.4,true)
			Feel.burst(actor.get_parent(),target_point,Color("d5c9a0"),12)
			if actor.player.global_position.distance_to(target_point)<3.1: actor.player.take_damage(roundi(damage*1.3))
			for ally in get_tree().get_nodes_in_group("combat_allies"):
				if ally is ValeCompanionActor and ally.global_position.distance_to(target_point)<3.1: ally.take_damage(roundi(damage*1.3))
			actor.player.camera_rig.impulse(.12)
			Feel.sound("slam",.7)
		"shockwave":
			for i in range(8):
				ValeCombat.projectile(actor.get_parent(),actor,Vector3(sin(i*TAU/8),0,cos(i*TAU/8)),damage,false,{"color":"c7a9dd","range":15,"projectile_speed":6,"element":"arcane"})
			Feel.sound("spell",.7,.65)
		"hazard":
			for x in [-2.0,2.0]:
				var hazard:=ValeHazard.new()
				hazard.position=target_point+Vector3(x,0,0)
				hazard.radius=1.8
				hazard.damage=12
				actor.get_parent().add_child(hazard)
			Feel.sound("spell",.65,.8)

func die() -> void:
	cleanup_markers()
	if is_instance_valid(gate): gate.queue_free()
	for node in minions:
		if is_instance_valid(node): node.queue_free()
	for node in get_tree().get_nodes_in_group("combat_hazards"): node.queue_free()
	Feel.ring(actor.get_parent(),actor.global_position,6,Color("ead093"),1.2)
	Feel.burst(actor.get_parent(),actor.global_position,Color("eed897"),14)
	Feel.sound("level",.9,.75)
	State.notification.emit("The Hollow Knight rests  ·  Its heart is yours.")
