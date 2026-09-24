class_name ValeEnemyMind
extends Node
## Additional behaviors reuse the same enemy health, feedback, cooldown and death controller.
var actor: Mossling
var awake: bool=false
var locked_direction:=Vector3.FORWARD
var leap_time: float=0

func _ready() -> void:
	actor=get_parent()

func tick(delta: float, to_player: Vector3) -> Vector3:
	var behavior: String=actor.config.behavior
	var distance: float=to_player.length()
	var speed: float=actor.config.speed
	if behavior=="dormant" and not awake:
		actor.sprite.pause()
		actor.sprite.frame=0
		if distance<2.7 or actor.hp<actor.max_hp:
			awake=true
			actor.sprite.play("default")
			Feel.sound("chest",.65,.8)
			Feel.burst(actor.get_parent(),actor.global_position,Color("d7b56d"),8)
		else: return Vector3.ZERO
	if actor.global_position.distance_to(actor.origin)>12:
		return (actor.origin-actor.global_position).normalized()*speed
	if behavior=="leap" and leap_time>0:
		leap_time-=delta
		if distance<1.4: actor.deal_damage(int(actor.config.damage))
		return locked_direction*8
	if actor.windup>0:
		actor.windup-=delta
		if actor.windup<=0:
			if is_instance_valid(actor.telegraph): actor.telegraph.queue_free()
			actor.cooldown=float(actor.config.cooldown)
			if behavior in ["ranged","caster"]:
				var context: Dictionary={"element":actor.config.element,"color":actor.config.color,"range":13,"projectile_speed":actor.config.projectile_speed}
				if actor.config.has("status"): context.status=actor.config.status
				for i in (3 if behavior=="caster" else 1):
					ValeCombat.projectile(actor.get_parent(),actor,locked_direction.rotated(Vector3.UP,(i-1)*.15 if behavior=="caster" else 0),int(actor.config.damage),false,context)
				Feel.sound("spell" if behavior=="caster" else "bow",.45)
			elif behavior=="leap": leap_time=.35
			elif distance<float(actor.config.range)+.35: actor.deal_damage(int(actor.config.damage))
		return Vector3.ZERO
	var reach: float=4.5 if behavior=="leap" else float(actor.config.range)
	if distance<reach and actor.cooldown<=0:
		actor.windup=float(actor.config.windup)
		locked_direction=to_player.normalized()
		actor.telegraph=Feel.ring(actor.get_parent(),actor.combat_target.global_position if behavior in ["ranged","caster"] else actor.global_position,.8 if behavior in ["ranged","caster"] else reach,Color(.87,.59,.36,.7),0)
		return Vector3.ZERO
	if distance>float(actor.config.detect): return Vector3.ZERO
	if behavior in ["ranged","caster"]:
		if distance<4: return -to_player.normalized()*speed
		if distance>6.8: return to_player.normalized()*speed
		return to_player.normalized().cross(Vector3.UP)*speed*.35
	if behavior=="circle":
		if actor.cooldown<.4: return to_player.normalized()*speed
		return (to_player.normalized().cross(Vector3.UP)+to_player.normalized()*clampf(distance-2.3,-1,1)).normalized()*speed
	return to_player.normalized()*speed
