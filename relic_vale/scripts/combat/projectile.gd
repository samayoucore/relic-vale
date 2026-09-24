class_name ValeProjectile
extends Node3D
var direction:=Vector3.FORWARD
var speed: float=12
var distance_left: float=12
var damage: int=10
var source: Node3D
var friendly: bool=true
var color:=Color("b3cfe0")
var info: Dictionary={}
var splash_radius: float=0
var sprite: Sprite3D

func _ready() -> void:
	add_to_group("projectiles")
	sprite=Sprite3D.new()
	sprite.texture=PixelArt.item_icon("bolt" if info.get("element","")=="physical" else "gem",color)
	sprite.pixel_size=.017
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if State.modal or State.paused: return
	var from: Vector3=global_position
	var to: Vector3=from+direction*speed*delta
	var query:=PhysicsRayQueryParameters3D.create(from,to,1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		Feel.burst(get_parent(),global_position-Vector3(0,.6,0),color,3)
		queue_free()
		return
	var targets: Array=get_tree().get_nodes_in_group("enemies" if friendly else "combat_allies")
	for target in targets:
		if target is ValeCompanionActor and target.downed: continue
		var center: Vector3=target.global_position+Vector3(0,.6,0)
		if Geometry3D.get_closest_point_to_segment(center,from,to).distance_to(center)>.6: continue
		if friendly:
			if is_instance_valid(source) and (source is ValePlayer or source is ValeCompanionActor):
				ValeCombat.hit(source,target,damage,info)
				if splash_radius>0:
					Feel.ring(get_parent(),target.global_position,splash_radius,color,.4)
					for other in targets:
						if other!=target and other.global_position.distance_to(target.global_position)<splash_radius: ValeCombat.hit(source,other,roundi(damage*.65),info)
		else:
			var before: int=State.hp if target is ValePlayer else target.hp
			target.take_damage(damage)
			if (State.hp if target is ValePlayer else target.hp)<before:
				if info.has("status"): target.statuses.apply(info.status,3,3 if info.status in ["burn","poison"] else .35)
				if is_instance_valid(source) and source is Mossling: source.successful_hit(target)
		Feel.burst(get_parent(),center-Vector3(0,.6,0),color,5)
		queue_free()
		return
	global_position=to
	distance_left-=speed*delta
	if distance_left<=0: queue_free()
