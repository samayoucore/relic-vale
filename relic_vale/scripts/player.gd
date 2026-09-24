class_name ValePlayer
extends CharacterBody3D

var camera_rig: ValeCamera
var sprite: AnimatedSprite3D
var facing := Vector3(0,0,1)
var attack_timer: float = 0
var invulnerability: float = 0
var speed: float = 5.0
var spawn_position := Vector3(0,0,5)
var attack_effect: MeshInstance3D
var dash_timer: float = 0
var dash_cooldown: float = 0
var dash_direction := Vector3.FORWARD
var statuses: ValeStatus
var combat: ValeFighter
var abilities: ValeAbilities
var hit_stop: float=0
var dodge_bonus: float=0
var shield: int=0
var shield_time: float=0
var footstep_clock: float=0
var quiet_time: float=0
var mirror_cooldown: float=0
var weapon_sprite: Sprite3D
var god_mode: bool=false
var gathering: ValeGathering

func life_busy() -> bool:
	var game: Node=get_tree().current_scene
	return (is_instance_valid(game.fishing) and game.fishing.busy()) or (is_instance_valid(game.cultivation) and game.cultivation.busy())

func _ready() -> void:
	add_to_group("player")
	sprite=AnimatedSprite3D.new()
	sprite.sprite_frames=PixelArt.character_frames(false,State.appearance)
	sprite.pixel_size=.037
	sprite.position.y=1.04
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded=false
	add_child(sprite)
	PixelArt.add_shadow(self,.55)
	sprite.play("idle_2")
	State.cooldown_reset.connect(func(): attack_timer=0)
	statuses=ValeStatus.new()
	add_child(statuses)
	combat=ValeFighter.new()
	add_child(combat)
	abilities=ValeAbilities.new()
	add_child(abilities)
	State.cooldown_reset.connect(abilities.reset_one)
	State.enemy_defeated.connect(on_kill)
	weapon_sprite=Sprite3D.new()
	weapon_sprite.pixel_size=.012
	weapon_sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	weapon_sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(weapon_sprite)
	State.changed.connect(update_weapon_visual)
	update_weapon_visual()
	State.appearance_changed.connect(refresh_appearance)
	gathering=ValeGathering.new(); add_child(gathering)

func refresh_appearance() -> void:
	var animation: String=sprite.animation
	sprite.sprite_frames=PixelArt.character_frames(false,State.appearance)
	sprite.play(animation)

func update_weapon_visual() -> void:
	if not weapon_sprite: return
	var item: Dictionary=State.items.get(State.equipment.Weapon,{})
	weapon_sprite.visible=not item.is_empty()
	if not item.is_empty(): weapon_sprite.texture=PixelArt.item_icon(item.get("weapon_type","sword"),Color(item.color))

func _physics_process(delta: float) -> void:
	if State.modal or State.paused: delta=0
	attack_timer=maxf(0,attack_timer-delta)
	invulnerability=maxf(0,invulnerability-delta)
	dash_timer=maxf(0,dash_timer-delta)
	dash_cooldown=maxf(0,dash_cooldown-delta)
	hit_stop=maxf(0,hit_stop-delta)
	dodge_bonus=maxf(0,dodge_bonus-delta)
	shield_time=maxf(0,shield_time-delta)
	if shield_time<=0: shield=0
	mirror_cooldown=maxf(0,mirror_cooldown-delta)
	sprite.speed_scale=0 if hit_stop>0 else 1
	weapon_sprite.position=camera_rig.camera.global_basis.y*.85+camera_rig.camera.global_basis.x*.37
	weapon_sprite.rotation.z=-.8 if combat.pending else 0
	sprite.position=camera_rig.camera.global_basis.y*(30.0*sprite.pixel_size)+Vector3(0,.03,0)
	sprite.modulate=Color(1,.6,.55) if invulnerability>.1 and int(invulnerability*14)%2==0 else Color.WHITE
	var input: Vector2 = Vector2.ZERO if State.modal or State.paused else Input.get_vector("move_left","move_right","move_up","move_down")
	var direction:=Vector3(input.x,0,input.y).rotated(Vector3.UP,camera_rig.yaw)
	speed=float(State.stats().move_speed)
	var target_velocity: Vector3 = direction*speed*(1.35 if Input.is_action_pressed("sprint") else 1.0)
	var game: Node=get_tree().current_scene
	if is_instance_valid(game.mounts) and game.mounts.mounted: target_velocity=direction*speed*game.mounts.speed_multiplier(Input.is_action_pressed("sprint"))
	target_velocity*=statuses.move_multiplier()
	if attack_timer > .25: target_velocity*=.25
	if gathering.busy: target_velocity=Vector3.ZERO
	if dash_timer>0: target_velocity=dash_direction*14
	if life_busy(): target_velocity=Vector3.ZERO; direction=Vector3.ZERO
	if hit_stop>0 or statuses.has("stun"): target_velocity=Vector3.ZERO
	if State.modal or State.paused:
		dash_timer=0
		velocity.x=0
		velocity.z=0
		target_velocity=Vector3.ZERO
	velocity.x=move_toward(velocity.x,target_velocity.x,delta*30)
	velocity.z=move_toward(velocity.z,target_velocity.z,delta*30)
	if dash_timer>0 and not State.modal and not statuses.has("stun"):
		velocity.x=target_velocity.x
		velocity.z=target_velocity.z
	if not is_on_floor(): velocity.y-=20*delta
	else: velocity.y=0
	move_and_slide()
	footstep_clock-=delta
	if direction.length()>.2 and footstep_clock<=0 and not State.modal:
		Feel.sound("hoof" if is_instance_valid(game.mounts) and game.mounts.mounted else ("footstep_wood_01" if global_position.x>2900 else "step"),.22,randf_range(.9,1.1))
		footstep_clock=.3 if Input.is_action_pressed("sprint") else .43
	if direction.length()<.1 and State.relic_proc()=="thread":
		quiet_time+=delta
		if quiet_time>4:
			quiet_time=3
			restore_health(1)
	else: quiet_time=0
	if direction.length_squared()>.1: facing=direction.normalized()
	if attack_timer <= 0:
		var anim: String = "walk" if Vector2(velocity.x,velocity.z).length()>.25 else "idle"
		sprite.play("%s_%d" % [anim,camera_rig.screen_direction(facing)])
	if global_position.y < -8: respawn()
	if is_instance_valid(game.mounts): game.mounts.pose(delta)

func _unhandled_input(event: InputEvent) -> void:
	if State.modal or State.paused or gathering.busy or life_busy(): return
	if is_instance_valid(get_tree().current_scene.mounts) and get_tree().current_scene.mounts.mounted: return
	if event.is_action_pressed("attack"):
		if event is InputEventMouseButton: aim_at_mouse(event.position)
		attack()
	if event.is_action_pressed("ability_1"): abilities.use(0)
	if event.is_action_pressed("ability_2"): abilities.use(1)
	if event.is_action_pressed("heal"): State.drink_tonic()
	if event.is_action_pressed("dodge") and dash_cooldown<=0 and not statuses.has("stun"):
		dash_timer=.18
		dash_cooldown=1.15*(1.0-float(State.stats().dodge_reduction))
		dash_direction=facing
		invulnerability=maxf(invulnerability,.25)
		Feel.sound("dodge",.55)
		if State.relic_proc()=="windstep": dodge_bonus=3
		if State.relic_proc()=="acorn": grant_shield(5,3)

func aim_at_mouse(pos: Vector2) -> void:
	var native: Vector2=get_tree().current_scene.get_viewport().get_visible_rect().size
	var pixel: Vector2=pos/native*Vector2(get_viewport().size)
	var cam: Camera3D=camera_rig.camera
	var hit: Variant=Plane(Vector3.UP,global_position.y).intersects_ray(cam.project_ray_origin(pixel),cam.project_ray_normal(pixel))
	if hit is Vector3 and hit.distance_to(global_position)>.2:
		facing=(hit-global_position).normalized()
		facing.y=0

func attack() -> void:
	if life_busy() or get_tree().current_scene.mounts.mounted: return
	combat.start()

func take_damage(amount: int) -> void:
	if invulnerability>0 or State.modal or State.paused or (OS.is_debug_build() and god_mode): return
	invulnerability=1.0
	apply_hurt(maxi(1,amount-int(State.stats().defense)))

func apply_hurt(amount: int) -> void:
	quiet_time=0
	var absorbed: int=mini(amount,shield)
	shield-=absorbed
	State.hp=maxi(0,State.hp-(amount-absorbed))
	Feel.sound("hurt",.65)
	Feel.number(get_parent(),global_position,amount-absorbed)
	State.changed.emit()
	if State.hp==0: respawn()

func receive_status_damage(amount: int) -> void:
	if not (OS.is_debug_build() and god_mode): apply_hurt(amount)

func restore_health(amount: int) -> void:
	var restored: int=mini(amount,State.max_hp-State.hp)
	if State.relic_proc()=="overflow" and amount>restored: grant_shield(mini(30,amount-restored),6)
	State.hp+=restored
	if restored>0: Feel.number(get_parent(),global_position,restored,false,true)
	State.changed.emit()

func grant_shield(amount: int, duration: float) -> void:
	shield=mini(30,maxi(shield,amount))
	shield_time=maxf(shield_time,duration)
	Feel.ring(get_parent(),global_position,.8,Color("acd6e3"),.4)

func on_combat_hit(enemy: Mossling, info: Dictionary) -> void:
	match State.relic_proc():
		"serpent":
			if randf()<.2: enemy.statuses.apply("poison",5,2)
		"quartz":
			if info.get("critical",false) and enemy.archetype!="guardian": enemy.statuses.apply("stun",.45,1)
		"mirror":
			if info.get("critical",false) and mirror_cooldown<=0:
				mirror_cooldown=.3
				ValeCombat.projectile(get_parent(),self,facing,roundi(State.damage_amount()*.35),true,{"secondary":true,"element":"arcane","color":"c8aee8"})
		"ember_crown":
			if info.get("element","")=="fire": enemy.statuses.apply("burn",4,4)

func on_kill() -> void:
	if State.relic_proc()=="moss": restore_health(2)
	if State.relic_proc()=="hollow": statuses.apply("might",6,.25)

func respawn() -> void:
	var game: Node=get_tree().current_scene
	game.fishing.cancel(); game.cultivation.action={}; game.mounts.park()
	gathering.cancel()
	statuses.clear()
	combat.cancel()
	abilities.dash_pending=0
	shield=0
	get_tree().current_scene.generator.teleport_logical(0,0,spawn_position)
	velocity=Vector3.ZERO
	State.hp=State.max_hp
	invulnerability=2
	camera_rig.snap()
	State.changed.emit()
	State.notification.emit("The vale carries you home. Health restored; your belongings are safe.")
