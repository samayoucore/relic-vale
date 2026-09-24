class_name ValeCompanionActor
extends CharacterBody3D
var id: String
var party: ValeParty
var traveling: bool=false
var visual: ValeCreatureVisual
var statuses: ValeStatus
var hp: int=100
var max_hp: int=100
var downed: bool=false
var home:=Vector3.ZERO
var wait_position:=Vector3.ZERO
var path:=PackedVector3Array()
var path_clock: float=0
var attack_clock: float=0
var pose_clock: float=0
var recover_clock: float=0
var cooldowns: Dictionary={"shield_rush":0.0,"hold_line":0.0}
var ability_uses: Dictionary={}
var target: Mossling
var route_origin:=Vector3.ZERO
var pending_hit: Dictionary={}
var impact_clock: float=0
var invulnerability: float=0
var rush_clock: float=0
var role: String="melee"
var decision_clock: float=0

func _ready() -> void:
	collision_layer=32; collision_mask=1; floor_snap_length=.6
	var shape:=CollisionShape3D.new(); var capsule:=CapsuleShape3D.new(); capsule.radius=.3; capsule.height=1.55
	shape.shape=capsule; shape.position.y=.8; add_child(shape)
	visual=ValeCreatureVisual.new(); add_child(visual); visual.setup("companion",1.85,ValeNarrative.companions[id].model)
	visual.companion_role(ValeNarrative.companions[id].role)
	role=ValeNarrative.companions[id].role; cooldowns.clear()
	for ability in ValeNarrative.companions[id].abilities: cooldowns[ability.id]=0.0
	statuses=ValeStatus.new(); add_child(statuses)
	home=global_position; wait_position=home
	var interaction:=ValeInteractable.new(); interaction.kind="companion"; interaction.title=ValeNarrative.companions[id].name; interaction.set_meta("companion",id); add_child(interaction)
	refresh_stats()
	var row: Dictionary=State.narrative.companions[id]
	downed=row.state=="downed"; hp=clampi(int(row.hp),0,max_hp) if row.recruited else max_hp
	if hp==0 and not downed: hp=max_hp
	if traveling: add_to_group("combat_allies")

func refresh_stats() -> void:
	max_hp=int(party.stats(id).max_hp); hp=mini(hp,max_hp)

func record_position() -> void:
	var row: Dictionary=State.narrative.companions[id]
	row.hp=hp; row.state="downed" if downed else ("traveling" if traveling else "waiting")
	if global_position.x<900: row.address=party.game.generator.address(global_position)

func take_damage(amount: int, _direction: Vector3=Vector3.ZERO, _info: Dictionary={}) -> void:
	if downed or not traveling or invulnerability>0: return
	invulnerability=.65
	hp=maxi(0,hp-maxi(1,amount-int(party.stats(id).defense)))
	visual.play("hit"); Feel.number(get_parent(),global_position,amount)
	if hp==0:
		downed=true; target=null; pending_hit.clear(); recover_clock=0; statuses.clear(); visual.play("death")
		State.notification.emit(ValeNarrative.companions[id].name+" is down. Stay close and help them up after the fight.")
	record_position(); State.changed.emit()

func receive_status_damage(amount: int) -> void:
	take_damage(amount)

func restore_health(amount: int) -> void:
	if downed: return
	hp=mini(max_hp,hp+amount); record_position()

func revive(automatic: bool=false) -> bool:
	if not downed or party.enemies_near(global_position,9): return false
	if not automatic and global_position.distance_to(party.game.player.global_position)>3: return false
	downed=false; hp=maxi(1,roundi(max_hp*.45)); recover_clock=0; visual.state=""; visual.play("idle"); record_position()
	State.notification.emit(ValeNarrative.companions[id].name+" is back on their feet."); return true

func select_target() -> Mossling:
	if not traveling or State.narrative.stance=="passive": return null
	var best: Mossling=null; var distance: float=13 if State.narrative.stance=="aggressive" else 6
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_inside_tree() or enemy.is_queued_for_deletion(): continue
		if State.narrative.command=="wait" and enemy.global_position.distance_to(wait_position)>4: continue
		var to_player: float=enemy.global_position.distance_to(party.game.player.global_position)
		var d: float=global_position.distance_to(enemy.global_position)
		if d<distance and to_player<16: best=enemy; distance=d
	return best

func strike(enemy: Mossling,multiplier: float=1) -> void:
	if not is_instance_valid(enemy) or not enemy.is_inside_tree() or enemy.dead: return
	var damage: int=roundi(float(party.stats(id).attack)*multiplier)
	if randf()<clampf(float(party.stats(id).crit),0,1): damage=roundi(damage*1.5)
	if id=="tarin" and State.narrative.flags.get("tarin_personal_complete",false): damage=roundi(damage*1.2)
	if role!="melee":
		ValeCombat.projectile(get_parent(),self,(enemy.global_position-global_position).normalized(),damage,true,{"element":"physical" if role=="ranged" else "arcane","color":"d5c08a" if role=="ranged" else "a5d3df","range":12,"projectile_speed":15})
		attack_clock=1.5; pose_clock=.7; visual.state=""; visual.play("attack"); return
	pending_hit={"target":weakref(enemy),"damage":damage}; impact_clock=.22
	attack_clock=1.2
	pose_clock=.55; visual.state=""; visual.play("attack")

func use_ability(key: String) -> void:
	for ability in ValeNarrative.companions[id].abilities:
		if ability.id==key: cooldowns[key]=float(ability.cooldown)
	ability_uses[key]=int(ability_uses.get(key,0))+1
	if key=="shield_rush":
		rush_clock=.5
		strike(target,1.5); impact_clock=.45; pending_hit.stun=1.2
		Feel.ring(get_parent(),global_position,1.8,Color("99c5db"),.4)
	elif key=="hold_line":
		party.game.player.shield=maxf(party.game.player.shield,22+State.level*2); party.game.player.shield_time=5
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(global_position)<6: enemy.combat_target=self; enemy.aggro_clock=5
		if State.narrative.flags.get("bren_personal_complete",false): restore_health(12)
		Feel.ring(get_parent(),global_position,3,Color("dfcc97"),.7)
	elif key=="pinning_shot":
		ValeCombat.projectile(get_parent(),self,(target.global_position-global_position).normalized(),int(party.stats(id).attack),true,{"element":"physical","color":"96ba8c","status":"slow","range":12})
	elif key=="split_fletching":
		var count: int=0
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(global_position)<9:
				ValeCombat.projectile(get_parent(),self,(enemy.global_position-global_position).normalized(),int(party.stats(id).attack),true,{"element":"physical","color":"dbc38e","range":12}); count+=1
				if count==3: break
	elif key=="frost_bind":
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(target.global_position)<3:
				enemy.statuses.apply("slow",4,.5); ValeCombat.hit(self,enemy,8,{"element":"frost"})
		Feel.ring(get_parent(),target.global_position,3,Color("9ddae0"),.6)
	elif key=="ember_mark":
		ValeCombat.projectile(get_parent(),self,(target.global_position-global_position).normalized(),int(party.stats(id).attack),true,{"element":"fire","color":"e4ad83","status":"burn","range":12})
	elif key=="field_dressing":
		var amount: int=22+State.level*3
		if float(State.hp)/State.max_hp<float(hp)/max_hp or State.narrative.flags.get("sera_personal_complete",false): party.game.player.restore_health(amount)
		else: restore_health(amount)
		if State.narrative.flags.get("sera_personal_complete",false): restore_health(amount)
		Feel.ring(get_parent(),global_position,3,Color("a7d7aa"),.6)
	elif key=="steady_hands":
		for ally in [self,party.game.player]:
			for effect in ["burn","poison","slow","stun"]: ally.statuses.effects.erase(effect)
			ally.statuses.apply("regeneration",5,4)
		Feel.ring(get_parent(),global_position,3,Color("e5dcaa"),.6)
	pose_clock=.7

func support_tick() -> void:
	if role!="support" or global_position.distance_to(party.game.player.global_position)>8: return
	if float(cooldowns.field_dressing)<=0 and (State.hp<State.max_hp*.75 or hp<max_hp*.7): use_ability("field_dressing")
	if float(cooldowns.steady_hands)<=0:
		for ally in [self,party.game.player]:
			for effect in ["burn","poison","slow","stun"]:
				if ally.statuses.has(effect): use_ability("steady_hands"); return

func move_toward_goal(goal: Vector3,delta: float,speed: float) -> Vector3:
	var direction: Vector3=goal-global_position; direction.y=0
	if direction.length()<.7: path.clear(); return Vector3.ZERO
	path_clock-=delta
	if path_clock<=0:
		path_clock=.85; path=ValeResidents.travel_route(self,goal)
	while not path.is_empty() and Vector2(path[0].x-global_position.x,path[0].z-global_position.z).length()<.55: path.remove_at(0)
	if not path.is_empty(): direction=path[0]-global_position; direction.y=0
	else: return Vector3.ZERO
	return direction.normalized()*speed

func _physics_process(delta: float) -> void:
	if State.modal or State.paused: return
	invulnerability=maxf(0,invulnerability-delta); rush_clock=maxf(0,rush_clock-delta)
	if downed:
		if not party.enemies_near(global_position,10): recover_clock+=delta
		else: recover_clock=0
		if recover_clock>12: revive(true)
		return
	attack_clock=maxf(0,attack_clock-delta); pose_clock=maxf(0,pose_clock-delta)
	if not pending_hit.is_empty():
		impact_clock-=delta
		if impact_clock<=0:
			var victim: Mossling=pending_hit.target.get_ref()
			if is_instance_valid(victim) and victim.is_inside_tree() and not victim.dead and victim.global_position.distance_to(global_position)<2.8:
				ValeCombat.hit(self,victim,int(pending_hit.damage),{"element":"physical","knockback":2})
				if pending_hit.has("stun") and not victim.dead: victim.statuses.apply("stun",float(pending_hit.stun))
			pending_hit.clear()
	for key in cooldowns: cooldowns[key]=maxf(0,float(cooldowns[key])-delta*(1.25 if id=="ilyra" and State.narrative.flags.get("ilyra_personal_complete",false) else 1.0))
	var goal: Vector3=home
	var speed: float=3.6
	if traveling:
		decision_clock-=delta
		if decision_clock<=0:
			decision_clock=.25; support_tick(); target=select_target()
		var player: ValePlayer=party.game.player
		var gap: float=global_position.distance_to(player.global_position)
		if State.narrative.command=="follow" and gap>26 and not party.game.rig.camera.is_position_in_frustum(global_position+Vector3.UP):
			global_position=party.safe_position(player.global_position); path.clear(); return
		var facing: Vector3=Vector3(player.velocity.x,0,player.velocity.z).normalized()
		if facing.length()<.1: facing=Vector3.FORWARD
		goal=player.global_position-facing*2.6+facing.cross(Vector3.UP)*1.3
		if State.narrative.command=="wait": goal=wait_position
		speed=7.5 if gap>7 else 5.2
		if State.narrative.stance=="passive" or (is_instance_valid(target) and (target.dead or not target.is_inside_tree() or target.is_queued_for_deletion())): target=null
		if is_instance_valid(target):
			goal=target.global_position
			if rush_clock>0: speed=11
			if role=="melee" and float(cooldowns.hold_line)<=0 and State.hp<State.max_hp*.7 and player.global_position.distance_to(global_position)<7: use_ability("hold_line")
			var distance: float=goal.distance_to(global_position)
			if role=="melee" and distance<5 and float(cooldowns.shield_rush)<=0 and attack_clock<=0:
				var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,target.global_position+Vector3.UP,1)
				if get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): use_ability("shield_rush")
			if role!="melee" and distance<7.5:
				goal=global_position
				if distance<3: goal=global_position+(global_position-target.global_position).normalized()*2
				if attack_clock<=0: strike(target)
				if role!="support":
					for key in cooldowns:
						if float(cooldowns[key])<=0: use_ability(key); break
			elif role=="melee" and distance<2:
				goal=global_position
				if attack_clock<=0: strike(target)
		else:
			recover_clock+=delta
			if recover_clock>3: restore_health(2); recover_clock=0
	var motion: Vector3=move_toward_goal(goal,delta,speed)*statuses.move_multiplier()
	velocity.x=motion.x; velocity.z=motion.z
	velocity.y=0 if is_on_floor() else velocity.y-20*delta
	move_and_slide()
	visual.tick(delta,motion,pose_clock>0,false)
	if pose_clock>0 and is_instance_valid(target): visual.rotation.y=lerp_angle(visual.rotation.y,atan2(target.global_position.x-global_position.x,target.global_position.z-global_position.z),minf(1,delta*12))
	if not traveling and motion.length()<.1 and State.narrative.companions[id].recruited:
		var rest: String=State.narrative.companions[id].camp_state
		if rest=="Resting": visual.play("sleep")
		elif rest=="By the fire": visual.play("rest")
