class_name Mossling
extends CharacterBody3D

var hp: int = 42
var max_hp: int = 42
var origin: Vector3
var sprite: AnimatedSprite3D
var visual: ValeCreatureVisual
var hp_label: Label3D
var death_tween: Tween
var player: ValePlayer
var combat_target: Node3D
var aggro_clock: float=0
var time: float = 0
var windup: float = 0
var cooldown: float = 1
var dead: bool = false
var respawn_timer: float = 0
var hit_flash: float = 0
var knockback := Vector3.ZERO
var archetype: String="slime"
var display_name: String="Mossling slime"
var config: Dictionary={}
var persistent_id: String=""
var unique: bool=false
var statuses: ValeStatus
var hit_stop: float=0
var telegraph: MeshInstance3D
var mind: ValeEnemyMind
var boss: ValeBoss
var enemy_level: int=1
var elite_modifier: String=""
var aura: MeshInstance3D
var spawn_grace: float=1.2

func _ready() -> void:
	add_to_group("enemy_bodies")
	archetype=get_meta("archetype","slime")
	config=State.enemy_data.get(archetype,State.enemy_data.slime).duplicate(true)
	if get_meta("narrative_enemy",false): config.respawn=0
	enemy_level=clampi(int(get_meta("enemy_level",1)),1,10)
	if archetype!="guardian":
		config.hp=roundi(float(config.hp)*(1+.12*(enemy_level-1)))
		config.damage=roundi(float(config.damage)*(1+.07*(enemy_level-1)))
		config.xp=roundi(float(config.xp)*(1+.18*(enemy_level-1)))
	statuses=ValeStatus.new()
	add_child(statuses)
	persistent_id=get_meta("persistent_id","")
	unique=int(config.respawn)==0
	display_name=config.name
	max_hp=int(config.hp)
	hp=max_hp
	add_to_group("enemies")
	origin=global_position
	sprite=AnimatedSprite3D.new()
	sprite.sprite_frames=PixelArt.enemy_frames(archetype)
	sprite.pixel_size=.065 if archetype=="guardian" else .045
	sprite.position.y=.67
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	add_child(sprite)
	sprite.play("default")
	sprite.visible=false
	visual=ValeCreatureVisual.new()
	add_child(visual)
	visual.setup(archetype,2.7 if archetype=="guardian" else (1.8 if archetype=="elite" else (.85 if archetype in ["slime","mimic","bat"] else 1.5)))
	PixelArt.add_shadow(self,.56)
	hp_label=Label3D.new()
	hp_label.text="MOSSLING  ·  42"
	hp_label.font_size=32
	hp_label.pixel_size=.012
	hp_label.position.y=1.5
	hp_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.modulate=Color("dfd8ad")
	add_child(hp_label)
	hp_label.visible=false
	if config.get("behavior","") in ["leap","ranged","caster","circle","dormant"]:
		mind=ValeEnemyMind.new()
		add_child(mind)
	if archetype=="guardian":
		boss=ValeBoss.new()
		add_child(boss)
	if archetype=="elite":
		var modifiers: Array[String]=["burning","frozen","vampiric","explosive","swift"]
		elite_modifier=get_meta("elite_modifier",modifiers[absi(persistent_id.hash())%modifiers.size()])
		display_name=elite_modifier.capitalize()+" "+display_name
		if elite_modifier=="swift": config.speed*=1.3
		aura=Feel.ring(self,global_position,.7,Color(.8,.65,.35,.75),0)
	if unique:
		sprite.pixel_size=.072 if archetype=="guardian" else .06
		if State.defeated_unique.has(persistent_id):
			dead=true
			visible=false
			remove_from_group("enemies")

func _physics_process(delta: float) -> void:
	if State.modal or State.paused: return
	spawn_grace=maxf(0,spawn_grace-delta)
	if dead:
		if unique: return
		respawn_timer-=delta
		if respawn_timer<=0: revive()
		return
	if not is_instance_valid(player): player=get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player): return
	sprite.position=player.camera_rig.camera.global_basis.y*(15.0*sprite.pixel_size)+Vector3(0,.03,0)
	if archetype=="bat": sprite.position.y+=.45+sin(time*5)*.12
	time+=delta
	cooldown=maxf(0,cooldown-delta)
	hit_flash=maxf(0,hit_flash-delta)
	hit_stop=maxf(0,hit_stop-delta)
	aggro_clock=maxf(0,aggro_clock-delta)
	if not is_instance_valid(combat_target) or (combat_target is ValeCompanionActor and combat_target.downed) or aggro_clock<=0:
		combat_target=player
		for ally in get_tree().get_nodes_in_group("combat_allies"):
			if ally is ValeCompanionActor and not ally.downed and global_position.distance_to(ally.global_position)+1<global_position.distance_to(combat_target.global_position): combat_target=ally
		aggro_clock=.7
	var to_player: Vector3 = combat_target.global_position-global_position
	var direction:=Vector3.ZERO
	if statuses.has("stun") or hit_stop>0 or spawn_grace>0:
		if statuses.has("stun"):
			windup=0
			if is_instance_valid(telegraph): telegraph.queue_free()
	elif boss:
		direction=boss.tick(delta)
	elif mind:
		direction=mind.tick(delta,to_player)
	elif windup>0:
		windup-=delta
		if windup<=0:
			if is_instance_valid(telegraph): telegraph.queue_free()
			if to_player.length()<float(config.range)+.3: deal_damage(int(config.damage))
			cooldown=float(config.cooldown)
	elif to_player.length()<float(config.range) and cooldown<=0:
		windup=float(config.windup)
		telegraph=Feel.ring(get_parent(),global_position,float(config.range),Color(.9,.52,.33,.65),0)
	elif to_player.length()<float(config.detect) and global_position.distance_to(origin)<11:
		direction=to_player.normalized()*float(config.speed)
	else:
		var wander_target: Vector3 = origin+Vector3(sin(time*.45),0,cos(time*.4))*1.3
		direction=(wander_target-global_position).normalized()*.65
	knockback=knockback.move_toward(Vector3.ZERO,delta*18)
	velocity.x=direction.x*statuses.move_multiplier()+knockback.x
	velocity.z=direction.z*statuses.move_multiplier()+knockback.z
	if not is_on_floor(): velocity.y-=20*delta
	else: velocity.y=0
	move_and_slide()
	visual.tick(delta,Vector3(velocity.x,0,velocity.z) if windup<=0 else to_player,windup>0,hit_flash>0)
	if elite_modifier=="frozen" and to_player.length()<2.5: combat_target.statuses.apply("slow",.3,.15)
	if archetype=="wolf": sprite.flip_h=to_player.rotated(Vector3.UP,-player.camera_rig.yaw).x<0
	sprite.modulate=Color(1.8,1.8,1.8) if hit_flash>0 else (Color("ef9179") if windup>0 else (Color("aacfe3") if statuses.has("slow") else Color.WHITE))
	sprite.speed_scale=0 if hit_stop>0 else 1
	sprite.scale=Vector3(1.16,.82,1) if windup>0 else Vector3.ONE
	hp_label.visible=false # Drawn by the native-resolution nameplate layer.

func take_damage(amount: int, direction: Vector3 = Vector3.ZERO, info: Dictionary = {}) -> void:
	if dead: return
	hp=maxi(0,hp-amount)
	hit_flash=.18
	hit_stop=.045 if not info.get("dot",false) else 0
	knockback=direction*float(info.get("knockback",4))*(.25 if archetype=="guardian" else 1.0)
	hp_label.text="MOSSLING  ·  %d" % hp
	Feel.number(get_parent(),global_position,amount,info.get("critical",false))
	Feel.burst(get_parent(),global_position,Color("f2d991") if info.get("critical",false) else Color("e3d5ab"),8 if info.get("critical",false) else 4)
	Feel.sound("critical" if info.get("critical",false) else "hit",.5 if not info.get("dot",false) else .18,randf_range(.94,1.06))
	if hp==0:
		dead=true
		visual.play("death")
		if boss: boss.die()
		if is_instance_valid(aura): aura.visible=false
		if elite_modifier=="explosive":
			var hazard:=ValeHazard.new()
			hazard.position=global_position
			hazard.duration=1.4
			hazard.tick=.9
			hazard.radius=2.4
			hazard.damage=25
			get_tree().current_scene.world.add_child(hazard)
		if is_instance_valid(telegraph): telegraph.queue_free()
		Feel.sound("death",.65)
		death_tween=create_tween()
		death_tween.tween_property(sprite,"modulate:a",0.0,.65)
		death_tween.parallel().tween_property(sprite,"scale",Vector3(1.25,.15,1),.65)
		death_tween.tween_callback(func(): visible=false)
		remove_from_group("enemies")
		State.enemy_killed(archetype,persistent_id if unique and not get_meta("event_enemy",false) else "",int(config.xp))
		if not persistent_id.is_empty(): State.quest_event("defeat",persistent_id)
		var bundle:=ValeLoot.roll(config.loot)
		get_tree().current_scene.loot_manager.drop(bundle,global_position)
		State.notification.emit("%s  ·  +%d XP\nLoot rests nearby." % [display_name,int(config.xp)])
		loot_spark()
		respawn_timer=float(config.respawn)

func deal_damage(amount: int) -> void:
	var recipient: Node3D=combat_target if is_instance_valid(combat_target) else player
	if not is_instance_valid(recipient): return
	var hp_before: int=State.hp if recipient is ValePlayer else recipient.hp
	recipient.take_damage(amount)
	if (State.hp if recipient is ValePlayer else recipient.hp)<hp_before: successful_hit(recipient)

func successful_hit(recipient: Node3D=null) -> void:
	if not is_instance_valid(recipient): recipient=player
	if elite_modifier=="burning" and is_instance_valid(recipient): recipient.statuses.apply("burn",3,3)
	if elite_modifier=="vampiric": restore_health(8)

func receive_status_damage(amount: int) -> void:
	take_damage(amount,Vector3.ZERO,{"dot":true,"knockback":0})

func restore_health(amount: int) -> void:
	if dead: return
	hp=mini(max_hp,hp+amount)
	Feel.number(get_parent(),global_position,amount,false,true)

func loot_spark() -> void:
	for i in range(5):
		var spark:=Sprite3D.new()
		spark.texture=PixelArt.item_icon("gem",Color("e7c77e"))
		spark.pixel_size=.008
		spark.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		spark.no_depth_test=true
		get_parent().add_child(spark)
		spark.global_position=global_position+Vector3(randf_range(-.5,.5),.6,randf_range(-.5,.5))
		var tween:=spark.create_tween()
		tween.tween_property(spark,"position:y",spark.position.y+1.2,.6)
		tween.parallel().tween_property(spark,"modulate:a",0.0,.6)
		tween.tween_callback(spark.queue_free)

func revive() -> void:
	if death_tween and death_tween.is_valid(): death_tween.kill()
	if boss: boss.reset()
	if mind:
		mind.awake=false
		mind.leap_time=0
	if is_instance_valid(telegraph): telegraph.queue_free()
	if is_instance_valid(aura): aura.visible=true
	statuses.clear()
	global_position=origin
	hp=max_hp
	dead=false
	windup=0
	cooldown=1
	visible=true
	sprite.modulate=Color.WHITE
	sprite.scale=Vector3.ONE
	hp_label.text="MOSSLING  ·  %d" % hp
	add_to_group("enemies")
