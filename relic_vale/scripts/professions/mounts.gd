class_name ValeMounts
extends Node
## The existing player physics owns mounted movement; unloaded horses are logical records.
var game: Node
var mounted: bool=false
var actor: ValeInteractable
var visual: ValeCreatureVisual
var clock: float=0
var stride: float=0
var camera_extra: float=0
var original_frames: SpriteFrames
var riding_frames: SpriteFrames
var stable_root: Node3D
var camp_instance: int=0

func _ready() -> void:
	game=get_tree().current_scene
	State.appearance_changed.connect(func(): if mounted: prepare_rider())

func record() -> Dictionary: return State.activities.mounts.get(State.activities.active_mount,{})
func own() -> bool: return not record().is_empty()

func acquire(free: bool=false) -> bool:
	if own(): return false
	if not free and (int(State.camp_data.get("tier",0))<3 or State.coins<180):
		State.notification.emit("A stable at camp tier 3 and 180 copper are required."); return false
	if not free: State.coins-=180
	var id: String="horse_1"
	State.activities.mounts[id]={"id":id,"name":"Bramble","species":"horse","address":{},"state":"stabled","owned":true}
	State.activities.active_mount=id
	State.changed.emit(); State.save_requested.emit()
	return true

func blocked() -> String:
	if game.player.position.x>900 or not State.interior_data.get("active",{}).is_empty(): return "Your horse waits outside."
	if game.player.attack_timer>0 or game.fishing.busy() or game.cultivation.busy(): return "Finish your current action first."
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_visible_in_tree() and enemy.global_position.distance_to(game.player.global_position)<10: return "Reach safe ground before mounting."
	return ""

func clear_spot(point: Vector3) -> bool:
	if game.generator.landscape.water_distance(Vector2(point.x,point.z))<.5: return false
	var shape:=CapsuleShape3D.new(); shape.radius=.55; shape.height=2.3
	var query:=PhysicsShapeQueryParameters3D.new(); query.shape=shape; query.transform=Transform3D(Basis.IDENTITY,point+Vector3(0,1.2,0)); query.collision_mask=1
	return game.player.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func call_mount() -> bool:
	if not own(): State.notification.emit("A horse can be purchased at your camp stable [P] → Mounts."); return false
	if mounted: return dismount()
	var reason: String=blocked()
	if not reason.is_empty(): State.notification.emit(reason); return false
	for i in 16:
		var p: Vector3=game.player.global_position+Vector3(sin(i*TAU/16),0,cos(i*TAU/16))*2.7
		p.y=game.generator.landscape.height(Vector2(p.x,p.z))+.04
		if not clear_spot(p): continue
		clear_actor(); record().address=game.generator.address(p); record().state="waiting"
		spawn(p); State.notification.emit("Bramble answers your call. Approach and press E.")
		State.save_requested.emit(); return true
	State.notification.emit("Your horse needs a little more open ground."); return false

func spawn(p: Vector3) -> void:
	actor=game.world.interactable("mount","Bramble",p,game.world); actor.set_meta("phase8_action","mount")
	visual=ValeCreatureVisual.new(); actor.add_child(visual); visual.setup("horse",1.8)
	visual.clips["trot"]="Walk"; visual.clips["gallop"]="Gallop"
	visual.animator.get_animation("Walk").loop_mode=Animation.LOOP_LINEAR
	visual.animator.get_animation("Gallop").loop_mode=Animation.LOOP_LINEAR

func mount() -> bool:
	if mounted or not own() or not is_instance_valid(actor) or actor.global_position.distance_to(game.player.global_position)>3.1: return false
	var reason: String=blocked()
	if not reason.is_empty(): State.notification.emit(reason); return false
	game.player.gathering.cancel()
	game.player.global_position=actor.global_position
	actor.reparent(game.player); actor.position=Vector3.ZERO
	actor.remove_from_group("interactables")
	mounted=true; record().state="ridden"; record().address=game.generator.address(game.player.global_position)
	var collision: CollisionShape3D=game.player.get_node("Collision")
	var shape:=CapsuleShape3D.new(); shape.radius=.55; shape.height=2.3; collision.shape=shape; collision.position.y=1.15
	prepare_rider()
	State.save_requested.emit(); return true

func prepare_rider() -> void:
	original_frames=PixelArt.character_frames(false,State.appearance)
	riding_frames=SpriteFrames.new()
	for d in 4:
		var source: Image=original_frames.get_frame_texture("idle_%d" % d,0).get_image()
		var pose:=Image.create(64,64,false,Image.FORMAT_RGBA8)
		# Preserve the chosen LPC layers and bend the legs into a compact seated pose.
		pose.blit_rect(source,Rect2i(0,0,64,43),Vector2i.ZERO)
		for y in range(43,61):
			for x in range(14,50):
				var color: Color=source.get_pixel(x,y)
				if color.a<.1: continue
				var dx: int=(3 if x>=32 else -3) if d in [0,2] else (3 if d==3 else -3)
				pose.set_pixel(clampi(x+dx,0,63),43+floori((y-43)*.55),color)
		var texture:=ImageTexture.create_from_image(pose)
		for anim in ["idle","walk","slash"]:
			var key: String="%s_%d" % [anim,d]; riding_frames.add_animation(key); riding_frames.add_frame(key,texture)
	game.player.sprite.sprite_frames=riding_frames

func dismount(park: bool=false) -> bool:
	if not mounted: return false
	var landing: Vector3=game.player.global_position
	var safe: bool=park
	for i in 12:
		var p: Vector3=game.player.global_position+Vector3(sin(i*TAU/12),0,cos(i*TAU/12))*1.5
		p.y=game.generator.landscape.height(Vector2(p.x,p.z))+.08
		if clear_spot(p): landing=p; safe=true; break
	if not safe: State.notification.emit("Ride to open ground to dismount."); return false
	mounted=false
	if is_instance_valid(actor): actor.reparent(game.world); actor.add_to_group("interactables"); record().address=game.generator.address(actor.global_position)
	game.player.global_position=landing; game.player.velocity=Vector3.ZERO
	var collision: CollisionShape3D=game.player.get_node("Collision")
	var shape:=CapsuleShape3D.new(); shape.radius=.28; shape.height=1.1; collision.shape=shape; collision.position.y=.55
	game.player.sprite.sprite_frames=PixelArt.character_frames(false,State.appearance); game.player.sprite.scale=Vector3.ONE
	record().state="stabled" if park else "waiting"
	if park: clear_actor()
	State.save_requested.emit(); return true

func park() -> void:
	if mounted: dismount(true)
	if own(): record().state="stabled"
	clear_actor()

func reset() -> void:
	# Loading has already applied the next save: reset presentation without mutating its records.
	mounted=false; clear_actor(); camp_instance=0
	game.player.sprite.sprite_frames=PixelArt.character_frames(false,State.appearance)
	var shape:=CapsuleShape3D.new(); shape.radius=.28; shape.height=1.1
	game.player.get_node("Collision").shape=shape; game.player.get_node("Collision").position.y=.55
	if own() and record().state=="ridden": record().state="stabled"

func clear_actor() -> void:
	if is_instance_valid(actor): actor.get_parent().remove_child(actor); actor.queue_free()
	actor=null; visual=null

func speed_multiplier(sprinting: bool) -> float: return 2.3 if sprinting else 1.5

func pose(delta: float) -> void:
	if not mounted or not is_instance_valid(visual): return
	var speed: float=Vector2(game.player.velocity.x,game.player.velocity.z).length()
	stride+=delta*speed
	visual.rotation.y=lerp_angle(visual.rotation.y,atan2(game.player.facing.x,game.player.facing.z),minf(1,delta*7))
	visual.play("gallop" if speed>8 else ("trot" if speed>.3 else "idle"))
	visual.animator.speed_scale=1.4 if speed>.3 and speed<=8 else 1
	game.player.sprite.position=Vector3(0,1.12+sin(stride*2)*(.028 if speed>.3 else 0),0)+game.rig.camera.global_basis.y*.40
	game.player.gathering.hand.visible=false; game.player.weapon_sprite.visible=false

func _process(delta: float) -> void:
	camera_extra=move_toward(camera_extra,3.5 if mounted else 0,delta*5)
	clock-=delta
	if clock>0: return
	clock=.5
	if mounted:
		if game.player.position.x>900: park()
		else: record().address=game.generator.address(game.player.global_position)
	elif own() and record().state=="waiting" and not record().address.is_empty():
		var a: Dictionary=record().address
		var near: bool=game.player.position.x<900 and absi(int(a.x)-game.generator.origin_x)<=2 and absi(int(a.z)-game.generator.origin_z)<=2
		if near and not is_instance_valid(actor): spawn(game.generator.position_of(a))
		elif near: actor.position=game.generator.position_of(a)
		elif not near: clear_actor()
	elif own() and record().state=="stabled":
		if game.camp.near_camp() and int(State.camp_data.tier)>=3:
			var p: Vector3=game.generator.position_of(State.camp_data.address)+Vector3(11,0,3)
			p.y=game.generator.landscape.height(Vector2(p.x,p.z))
			if not is_instance_valid(actor): spawn(p)
			else: actor.position=p
			record().address=game.generator.address(p)
		else: clear_actor()
	if not is_instance_valid(game.camp.visual): camp_instance=0; return
	if int(State.camp_data.tier)<3 or camp_instance==game.camp.visual.get_instance_id(): return
	camp_instance=game.camp.visual.get_instance_id()
	stable_root=Node3D.new(); stable_root.name="Stable"; game.camp.visual.add_child(stable_root)
	stable_root.position=Vector3(11,0,2)
	var base: Vector3=stable_root.global_position
	stable_root.position.y=game.generator.landscape.height(Vector2(base.x,base.z))-game.camp.visual.global_position.y
	game.world.place("res://assets/3d/phase8/farmbuildings/OpenBarn.glb",Vector3.ZERO,2.8,90,stable_root)
	game.world.place("res://assets/3d/phase7/barrel.glb",Vector3(1.2,0,1),.65,0,stable_root)
	var board: ValeInteractable=game.world.interactable("stable","Bramble's stable",Vector3(0,0,2.5),stable_root); board.set_meta("phase8_action","stable")
