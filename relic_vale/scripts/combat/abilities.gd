class_name ValeAbilities
extends Node
var actor: ValePlayer
var cooldowns: Dictionary={}
var global_cooldown: float=0
var dash_pending: float=0

func _ready() -> void:
	actor=get_parent()
	for id in State.ability_data: cooldowns[id]=0.0

func _physics_process(delta: float) -> void:
	if State.modal or State.paused: return
	global_cooldown=maxf(0,global_cooldown-delta)
	for id in cooldowns: cooldowns[id]=maxf(0,float(cooldowns[id])-delta)
	if dash_pending>0:
		dash_pending-=delta
		if dash_pending<=0: area("dash_strike")

func use(slot: int) -> bool:
	if actor.life_busy() or get_tree().current_scene.mounts.mounted: return false
	if slot<0 or slot>1 or State.modal or State.paused or actor.statuses.has("stun") or global_cooldown>0: return false
	var id: String=State.abilities[slot]
	if float(cooldowns.get(id,0))>0: return false
	var data: Dictionary=State.ability_data[id]
	cooldowns[id]=float(data.cooldown)*(1.0-clampf(float(State.stats().cooldown_reduction),0,.6))
	global_cooldown=.25
	actor.combat.cancel()
	actor.attack_timer=maxf(actor.attack_timer,.16)
	Feel.sound(data.sfx,.6)
	match id:
		"whirlwind","frost_nova": area(id)
		"dash_strike":
			actor.dash_timer=.24
			actor.dash_direction=actor.facing
			actor.invulnerability=maxf(actor.invulnerability,.3)
			dash_pending=.24
		"fireball","arcane_missiles":
			var count: int=3 if id=="arcane_missiles" else 1
			for i in count:
				var info: Dictionary={"element":data.element,"color":data.color,"range":14,"projectile_speed":13,"splash_radius":data.radius,"critical":randf()<float(State.stats().crit)}
				if data.has("status"): info.status=data.status
				var direction: Vector3=actor.facing.rotated(Vector3.UP,(i-1)*.13 if count==3 else 0)
				ValeCombat.projectile(actor.get_parent(),actor,direction,roundi(State.damage_amount()*float(data.multiplier)*(1.5 if info.critical else 1)),true,info)
		"heal":
			actor.restore_health(ceili(State.max_hp*.25))
			actor.statuses.apply("regeneration",3,ceili(State.max_hp*.04))
			Feel.ring(actor.get_parent(),actor.global_position,1.7,Color(data.color),.5)
	State.changed.emit()
	return true

func area(id: String) -> void:
	var data: Dictionary=State.ability_data[id]
	var radius: float=data.radius
	if id=="frost_nova" and State.relic_proc()=="winter": radius*=1.3
	Feel.ring(actor.get_parent(),actor.global_position,radius,Color(data.color),.5)
	Feel.burst(actor.get_parent(),actor.global_position,Color(data.color),10)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(actor.global_position)>radius: continue
		var info: Dictionary={"element":data.element,"critical":randf()<float(State.stats().crit),"knockback":6 if id=="dash_strike" else 3}
		if data.has("status"): info.status=data.status
		ValeCombat.hit(actor,enemy,roundi(State.damage_amount()*float(data.multiplier)*(1.5 if info.critical else 1)),info)
		if id=="frost_nova" and State.relic_proc()=="winter" and enemy.archetype!="guardian": enemy.statuses.apply("stun",.7,1)

func reset_one() -> void:
	for id in State.abilities:
		if float(cooldowns[id])>0:
			cooldowns[id]=0.0
			return
