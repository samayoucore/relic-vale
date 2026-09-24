extends Node
## End-to-end checks inside the real Godot scene/physics/input pipeline.
var game: Node
var checks: Array[String] = []
var failures: Array[String] = []

func _ready() -> void:
	run.call_deferred()

func check(condition: bool, description: String) -> void:
	if condition:
		checks.append(description)
		print("PASS: "+description)
	else:
		failures.append(description)
		push_error("FAIL: "+description)

func frames(count: int = 2) -> void:
	for i in count: await get_tree().physics_frame

func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await frames()
	event=InputEventKey.new()
	event.physical_keycode=code
	event.pressed=false
	Input.parse_input_event(event)
	await frames()

func object(kind: String) -> ValeInteractable:
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.kind==kind: return node
	return null

func approach(kind: String, offset: Vector3 = Vector3(0,0,1.3)) -> void:
	game.player.position=object(kind).position+offset
	game.player.velocity=Vector3.ZERO
	await frames(12)

func walk_to(target: Vector3) -> bool:
	for i in 380:
		var difference: Vector3=target-game.player.position
		difference.y=0
		if difference.length()<.55:
			for action in ["move_up","move_down","move_left","move_right"]: Input.action_release(action)
			await frames(10)
			return true
		var direction: Vector3=difference.normalized().rotated(Vector3.UP,-game.rig.yaw)
		Input.action_press("move_right",maxf(0,direction.x))
		Input.action_press("move_left",maxf(0,-direction.x))
		Input.action_press("move_down",maxf(0,direction.z))
		Input.action_press("move_up",maxf(0,-direction.z))
		await frames(1)
	for action in ["move_up","move_down","move_left","move_right"]: Input.action_release(action)
	return false

func run() -> void:
	game=get_tree().current_scene
	await frames(20)
	check(game.player.is_on_floor(),"Player spawns on solid ground")
	check(game.player.sprite is AnimatedSprite3D and game.player.sprite.sprite_frames.get_frame_count("walk_2")==9,"Animated LPC billboard pipeline")
	var origin: Vector3=game.player.position
	Input.action_press("move_down")
	await frames(30)
	Input.action_release("move_down")
	await frames(12)
	check(game.player.position.distance_to(origin)>1.5,"WASD movement advances the CharacterBody3D")
	var yaw: float=game.rig.yaw
	Input.action_press("rotate_left")
	await frames(25)
	Input.action_release("rotate_left")
	check(absf(game.rig.yaw-yaw)>.35,"Q rotates the camera during play")
	var zoom: float=game.rig.target_zoom
	var wheel:=InputEventMouseButton.new()
	wheel.button_index=MOUSE_BUTTON_WHEEL_UP
	wheel.pressed=true
	Input.parse_input_event(wheel)
	await frames(4)
	check(game.rig.target_zoom<zoom,"Mouse wheel zoom reaches the SubViewport camera")
	var rotation_before: float=game.rig.target_yaw
	var right_click:=InputEventMouseButton.new()
	right_click.button_index=MOUSE_BUTTON_RIGHT
	right_click.position=Vector2(640,360)
	right_click.pressed=true
	Input.parse_input_event(right_click)
	var motion:=InputEventMouseMotion.new()
	motion.relative=Vector2(50,0)
	motion.position=Vector2(690,360)
	motion.button_mask=MOUSE_BUTTON_MASK_RIGHT
	Input.parse_input_event(motion)
	await frames(3)
	right_click.pressed=false
	Input.parse_input_event(right_click)
	check(absf(game.rig.target_yaw-rotation_before)>.1,"Right-mouse drag orbits the camera")
	await key(KEY_P)
	check(game.viewport.size==Vector2i(1280,720),"P switches to crisp internal rendering")
	await key(KEY_P)
	check(game.viewport.size==Vector2i(768,432),"P restores pixel internal rendering")
	game.rig.yaw=0
	game.rig.target_yaw=0
	game.player.position=Vector3(-8,0,-1)
	game.player.velocity=Vector3.ZERO
	Input.action_press("move_up")
	await frames(65)
	Input.action_release("move_up")
	check(game.player.position.z>-2.95,"Building collision stops movement through a house")
	await key(KEY_I)
	check(State.modal and game.hud.modal_kind=="inventory","I opens the inventory through real key dispatch")
	await frames(12)
	origin=game.player.position
	Input.action_press("move_down")
	await frames(25)
	Input.action_release("move_down")
	check(game.player.position.distance_to(origin)<.1,"Inventory blocks world movement")
	await key(KEY_I)
	check(not State.modal,"I closes the inventory")
	await approach("npc")
	await key(KEY_E)
	check(State.flags.met_rowan and game.hud.modal_kind=="dialogue","E starts Rowan's quest and opens dialogue")
	await key(KEY_E)
	check(not State.modal,"E dismisses dialogue without retriggering interaction")
	await approach("chest",Vector3(0,0,1.8))
	await key(KEY_E)
	check(State.flags.chest and int(State.inventory.trail_tonic)==4 and State.coins==25,"Chest grants inventory items and copper")
	game.hud.close_modal()
	await key(KEY_E)
	check(int(State.inventory.trail_tonic)==4 and State.coins==25,"Chest rewards cannot be duplicated")
	State.hp=40
	await key(KEY_H)
	check(State.hp==85 and int(State.inventory.trail_tonic)==3,"H consumes a tonic and restores health")
	await approach("shrine")
	await key(KEY_E)
	check(State.flags.shrine and State.hp==State.max_hp and State.damage_amount()>15,"Free shrine relic increases damage and heals")
	game.hud.close_modal()
	var count: int=State.inventory.size()
	await key(KEY_E)
	check(State.inventory.size()==count,"Shrine grants one relic per journey")
	var enemy: Mossling=get_tree().get_nodes_in_group("enemies")[0]
	enemy.set_physics_process(false)
	game.player.position=enemy.position+Vector3(0,0,1.5)
	game.player.facing=Vector3(0,0,-1)
	game.player.velocity=Vector3.ZERO
	await frames(10)
	var expected: int=maxi(0,42-State.damage_amount())
	await key(KEY_SPACE)
	check(enemy.hp==expected,"Space attack hits once with the current relic damage")
	await key(KEY_SPACE)
	check(enemy.hp==expected,"Attack cooldown prevents immediate repeated damage")
	await frames(32)
	await key(KEY_SPACE)
	await frames(32)
	await key(KEY_SPACE)
	check(enemy.dead and State.kills==1 and State.xp==35,"Enemy death awards XP exactly once")
	var coins: int=State.coins
	enemy.take_damage(100)
	check(State.coins==coins,"Dead enemies cannot be farmed for duplicate rewards")
	enemy.revive()
	enemy.set_physics_process(true)
	game.player.position=enemy.position+Vector3(0,0,1.1)
	game.player.velocity=Vector3.ZERO
	game.player.invulnerability=0
	State.hp=100
	await frames(130) # Includes the initial cooldown plus the .65 s telegraph.
	check(State.hp<100,"Enemy telegraphs and lands a contact attack")
	await key(KEY_ESCAPE)
	var hp: int=State.hp
	await frames(90)
	check(State.hp==hp and State.paused,"Pause freezes enemy damage")
	await key(KEY_ESCAPE)
	for foe in get_tree().get_nodes_in_group("enemies"): foe.set_physics_process(false)
	game.player.position=Vector3(5,0,2.7)
	game.player.velocity=Vector3.ZERO
	var route_ok: bool=true
	for point in [Vector3(12,0,.5),Vector3(18,0,-2.6),Vector3(25,0,-7),Vector3(31,0,-12),Vector3(37.5,0,-19)]:
		if not await walk_to(point):
			route_ok=false
			break
	check(route_ok,"Village-to-crypt route is physically traversable with movement input")
	await approach("entrance",Vector3(0,0,1.3))
	await key(KEY_E)
	await frames(15)
	check(game.player.position.x>100 and State.region=="Oldroot Crypt","Crypt entrance transitions to the playable interior")
	check(await walk_to(Vector3(110,0,-5)),"Crypt corridor reaches the moonseed pedestal")
	await approach("moonseed",Vector3(0,0,1.5))
	await key(KEY_E)
	check(State.flags.moonseed and State.inventory.has("moonseed"),"Moonseed pickup is stored in inventory")
	game.hud.close_modal()
	await approach("exit",Vector3(0,0,-1.5))
	await key(KEY_E)
	check(game.player.position.x<80,"Stairway returns the player to the forest")
	await approach("npc")
	await key(KEY_E)
	check(State.flags.returned and not State.inventory.has("moonseed") and State.level==2,"Returning the moonseed completes the quest and levels up")
	game.hud.close_modal()
	game.player.take_damage(1000)
	check(game.player.position.distance_to(game.player.spawn_position)<.1 and State.hp==State.max_hp,"Defeat safely respawns the player in the village")
	var report: String="# Godot integration verification\n\nEngine: %s\n\n%d passed; %d failed.\n\n" % [Engine.get_version_info().string,checks.size(),failures.size()]
	for entry in checks: report+="- PASS: "+entry+"\n"
	for entry in failures: report+="- FAIL: "+entry+"\n"
	FileAccess.open("res://docs/TEST_RESULTS.md",FileAccess.WRITE).store_string(report)
	print("SMOKE_RESULT: %d passed, %d failed" % [checks.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
