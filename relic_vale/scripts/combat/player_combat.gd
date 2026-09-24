class_name ValeFighter
extends Node
## Timed extension of the existing primary attack: anticipation, one impact, recovery.
var actor: ValePlayer
var pending: bool=false
var windup: float=0
var profile: Dictionary={}
var roll: Dictionary={}
var direction:=Vector3.FORWARD

func _ready() -> void:
	actor=get_parent()

func start() -> void:
	if (is_instance_valid(actor.gathering) and actor.gathering.busy) or actor.attack_timer>0 or actor.statuses.has("stun") or State.modal or State.paused: return
	profile=State.weapon_profile().duplicate(true)
	var speed: float=maxf(.35,1.0+float(State.stats().attack_speed))
	actor.attack_timer=(float(profile.anticipation)+float(profile.impact)+float(profile.recovery))/speed
	windup=float(profile.anticipation)/speed
	direction=actor.facing
	roll=State.attack_roll()
	pending=true
	actor.sprite.play("slash_%d" % actor.camera_rig.screen_direction(direction))
	actor.sprite.speed_scale=1
	Feel.sound("draw",.25,1.1)

func cancel() -> void:
	pending=false
	windup=0

func _physics_process(delta: float) -> void:
	if not pending or State.modal or State.paused: return
	if actor.statuses.has("stun"):
		cancel()
		return
	windup-=delta
	if windup<=0:
		pending=false
		impact()

func impact() -> void:
	var info: Dictionary={"critical":roll.critical,"knockback":profile.knockback,"element":profile.get("element","physical")}
	var amount: int=maxi(1,roundi(float(roll.damage)*float(profile.damage_multiplier)))
	Feel.sound(profile.sfx,.65,randf_range(.94,1.05))
	if not str(profile.projectile_scene).is_empty():
		info.merge(profile,false)
		ValeCombat.projectile(actor.get_parent(),actor,direction,amount,true,info)
	else:
		var hit: bool=false
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var offset: Vector3=enemy.global_position-actor.global_position
			if offset.length()<float(profile.range) and (offset.normalized().dot(direction)>cos(deg_to_rad(float(profile.arc)*.5)) or offset.length()<.9):
				ValeCombat.hit(actor,enemy,amount,info)
				hit=true
		if hit:
			actor.hit_stop=.045
			if float(profile.knockback)>5: actor.camera_rig.impulse(.10)
		arc(float(profile.range),float(profile.arc),Color(profile.color))
	if roll.echo:
		Feel.ring(actor.get_parent(),actor.global_position,3.4,Color("c5a0e0"),.45)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(actor.global_position)<3.4: ValeCombat.hit(actor,enemy,ceili(State.damage_amount()*.5),{"secondary":true,"element":"arcane"})

func arc(radius: float, angle: float, color: Color) -> void:
	var mesh:=ImmediateMesh.new()
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color=color
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,material)
	var facing_angle: float=atan2(direction.x,direction.z)
	var span: float=deg_to_rad(angle)
	for i in 16:
		var a: float=facing_angle-span*.5+i/16.0*span
		var b: float=facing_angle-span*.5+(i+1)/16.0*span
		for p in [Vector3(sin(a),.35,cos(a))*radius*.65,Vector3(sin(b),.35,cos(b))*radius*.65,Vector3(sin(a),.35,cos(a))*radius*.9,Vector3(sin(b),.35,cos(b))*radius*.65,Vector3(sin(b),.35,cos(b))*radius*.9,Vector3(sin(a),.35,cos(a))*radius*.9]: mesh.surface_add_vertex(p)
	mesh.surface_end()
	var effect:=MeshInstance3D.new()
	effect.mesh=mesh
	actor.get_parent().add_child(effect)
	effect.global_position=actor.global_position
	var tween:=effect.create_tween()
	tween.tween_property(material,"albedo_color:a",0.0,.2)
	tween.parallel().tween_property(effect,"scale",Vector3(1.1,1,1.1),.2)
	tween.tween_callback(effect.queue_free)
