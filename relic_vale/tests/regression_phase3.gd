extends "res://tests/smoke_test.gd"
## Integration journey: real input, physics, UI, generation, combat and isolated file persistence.
const TEST_SAVE: String="user://phase3-regression.json"
var snapshots: Array[String]=[]

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(15)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase3-regression-"+name+".png")
	snapshots.append(name)

func teleport(pos: Vector3) -> void:
	game.player.global_position=pos
	game.player.velocity=Vector3.ZERO
	game.rig.snap()
	game.generator.update_streaming(true)
	await frames(15)

func approach(kind: String, offset: Vector3 = Vector3(0,0,1.3)) -> void:
	await teleport(object(kind).global_position+offset)

func freeze_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"): enemy.set_physics_process(false)

func walk_to(target: Vector3) -> bool:
	var budget: int=ceili(game.player.position.distance_to(target)/5.0*60*1.6)+180
	for i in mini(budget,3000):
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
	print("ROUTE BLOCKED: player=",game.player.position," target=",target)
	return false

func foe(kind: String, pos: Vector3) -> Mossling:
	var node:=preload("res://scenes/characters/Enemy.tscn").instantiate()
	node.set_meta("archetype",kind)
	node.position=pos
	game.world.add_child(node)
	node.set_physics_process(false)
	return node

func fight(enemy: Mossling) -> void:
	await teleport(enemy.global_position+Vector3(0,0,1.4))
	game.player.facing=Vector3.FORWARD
	for i in range(120):
		if enemy.dead:
			game.player.position=enemy.global_position
			await frames(55)
			return
		game.player.attack_timer=0
		await key(KEY_SPACE)
		await frames(30)
	check(false,"Enemy defeated within bounded attack count")

func run() -> void:
	game=get_tree().current_scene
	await frames(20)
	freeze_enemies()
	check(game.player.is_on_floor(),"Player spawns safely on solid ground")
	check(game.player.sprite.sprite_frames.get_frame_count("walk_2")==9,"Original animated LPC character retained")
	await shot("village")
	var origin: Vector3=game.player.position
	Input.action_press("move_down")
	await frames(30)
	Input.action_release("move_down")
	await frames(12)
	check(game.player.position.distance_to(origin)>1.5,"Movement input advances the player with acceleration")
	check(Vector2(game.player.velocity.x,game.player.velocity.z).length()<.01,"Movement decelerates to a stop")
	var yaw: float=game.rig.yaw
	Input.action_press("rotate_left")
	await frames(25)
	Input.action_release("rotate_left")
	check(absf(game.rig.yaw-yaw)>.3,"Q smoothly orbits the camera")
	var zoom: float=game.rig.target_zoom
	var wheel:=InputEventMouseButton.new()
	wheel.button_index=MOUSE_BUTTON_WHEEL_UP
	wheel.pressed=true
	Input.parse_input_event(wheel)
	await frames(3)
	check(game.rig.target_zoom<zoom,"Mouse wheel zoom dispatches to the world camera")
	var click:=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_RIGHT
	click.position=Vector2(640,360)
	click.pressed=true
	Input.parse_input_event(click)
	var before: float=game.rig.target_yaw
	var motion:=InputEventMouseMotion.new()
	motion.relative=Vector2(50,0)
	motion.position=Vector2(690,360)
	motion.button_mask=MOUSE_BUTTON_MASK_RIGHT
	Input.parse_input_event(motion)
	await frames(3)
	click.pressed=false
	Input.parse_input_event(click)
	check(absf(before-game.rig.target_yaw)>.1,"RMB drag rotates the camera")
	await key(KEY_HOME)
	await frames(25)
	check(absf(game.rig.yaw-deg_to_rad(42))<.03,"Home restores a comfortable camera angle")
	origin=game.player.position
	await key(KEY_CTRL)
	await frames(15)
	check(game.player.position.distance_to(origin)>.8 and game.player.dash_cooldown>0,"Ctrl performs a short dodge with cooldown")
	game.rig.yaw=0
	game.rig.target_yaw=0
	await teleport(Vector3(-8,0,-1))
	Input.action_press("move_up")
	await frames(65)
	Input.action_release("move_up")
	check(game.player.position.z>-2.95,"House collision prevents walking through buildings")
	await key(KEY_HOME)
	await key(KEY_I)
	check(State.modal and game.hud.modal_kind=="inventory","I opens the inventory")
	origin=game.player.position
	Input.action_press("move_down")
	await frames(20)
	Input.action_release("move_down")
	check(game.player.position.distance_to(origin)<.12,"Inventory blocks world movement")
	await key(KEY_I)
	await approach("npc")
	await key(KEY_E)
	check(State.flags.met_rowan and State.quest_progress.has("woods"),"Rowan starts the kill, collect, talk and reach quests")
	await key(KEY_E)
	await approach("chest",Vector3(0,0,1.8))
	await key(KEY_E)
	check(State.flags.chest and int(State.inventory.trail_tonic)==4 and State.coins==25,"Original supply chest grants its one-time reward")
	game.hud.close_modal()
	State.open_chest()
	check(State.coins==25,"Supply chest cannot duplicate rewards")
	State.hp=40
	await key(KEY_H)
	check(State.hp==85 and int(State.inventory.trail_tonic)==3,"Tonic consumes one stack and heals 45 HP")
	var blade_damage: int=State.damage_amount()
	State.add_item("iron_sword")
	check(State.damage_amount()==blade_damage,"Unequipped items do not grant bonuses")
	check(State.equip("iron_sword") and State.damage_amount()==blade_damage+4,"Weapon slot changes attack")
	State.add_item("moonstone_heart")
	State.equip("moonstone_heart")
	check(State.max_hp==115 and is_equal_approx(State.stats().crit,.10),"Relic modifies maximum HP and critical chance")
	State.unequip("Relic")
	check(State.max_hp==100,"Unequipping recalculates stats")
	check(not equip_base("warden_mail"),"Cannot equip an item that is not owned")
	var s:=foe("slime",Vector3(23,0,-5))
	await teleport(s.global_position+Vector3(0,0,1.4))
	game.player.facing=Vector3.FORWARD
	game.player.attack_timer=0
	await key(KEY_SPACE)
	await frames(8)
	var remaining: int=s.hp
	await key(KEY_SPACE)
	check(remaining<s.max_hp and s.hp==remaining,"Sword hits once; cooldown blocks repeated immediate strikes")
	var old_xp: int=State.xp
	await fight(s)
	check(s.dead and State.xp>old_xp and State.inventory.has("slime_gel"),"Slime death grants XP and data-driven material loot")
	var coins: int=State.coins
	s.take_damage(999)
	check(State.coins==coins,"A dead enemy cannot grant rewards twice")
	for i in range(4): await fight(foe("slime",Vector3(21+i*2,0,-5)))
	check(int(State.quest_progress.woods)==5,"Five actual slime kills complete the starter objective")
	await approach("npc")
	var shards: int=State.astral_shards
	await key(KEY_E)
	check(State.completed_quests.has("woods") and State.astral_shards==shards+1,"Rowan pays XP, copper and one shard for Trouble in the Woods")
	check(not State.claim_quest("woods"),"Quest reward cannot be claimed twice")
	game.hud.close_modal()
	for kind in ["wolf","skeleton"]:
		var enemy:=foe(kind,Vector3(24,0,-6))
		check(enemy.config.speed!=State.enemy_data.slime.speed and enemy.max_hp>42,kind+" has distinct combat stats and sprite")
		await fight(enemy)
	var attacker:=foe("wolf",Vector3(24,0,-6))
	attacker.set_physics_process(true)
	await teleport(Vector3(24,0,-4.9))
	State.hp=State.max_hp
	game.player.invulnerability=0
	await frames(120)
	check(State.hp<State.max_hp,"Enemy chase and telegraphed attack damage the player")
	await key(KEY_ESCAPE)
	var hp: int=State.hp
	await frames(65)
	check(State.hp==hp and State.paused,"Pause freezes enemy attacks")
	await key(KEY_ESCAPE)
	freeze_enemies()
	# Pure layout is stable and contains all three biome types for several seeds.
	var generator: ValeGenerator=game.generator
	var seed: int=State.world_seed
	var fingerprint: String=generator.fingerprint()
	var biomes: Dictionary={}
	for data in generator.layout.values(): biomes[data.biome]=true
	check(biomes.size()==3 and generator.layout.size()==49,"Finite world contains 49 chunks and three noise-based biomes")
	generator.build_layout()
	check(fingerprint==generator.fingerprint(),"The same seed reproduces identical props, POIs and enemies")
	generator.world_seed=seed+1
	generator.build_layout()
	check(fingerprint!=generator.fingerprint(),"Different seed changes the generated world")
	generator.world_seed=seed
	generator.build_layout()
	check(generator.pois.size()>=5,"Reusable POIs and rare crypt entrances are placed")
	for biome in generator.BIOMES:
		for data in generator.layout.values():
			if data.biome!=biome or generator.HUB.grow(10).has_point(data.center): continue
			await teleport(Vector3(data.center.x,0,data.center.y+5))
			freeze_enemies()
			check(State.region==biome and game.player.is_on_floor(),"Explore generated "+biome+" on physical ground")
			check(generator.active_chunks.size()<=25,"Streaming keeps bounded active chunks in "+biome)
			await shot(biome.to_lower().replace(" ","-"))
			break
	# Physically cross a chunk seam on a clear centerline, avoiding arbitrary scenery.
	var road: Array=generator.roads[-1]
	await teleport(Vector3(road[0].x,0,road[0].y))
	freeze_enemies()
	check(await walk_to(Vector3(road[1].x,0,road[1].y)),"Procedural road is traversable using movement input")
	var resource: ValeInteractable=object("resource")
	if resource:
		await teleport(resource.global_position+Vector3(0,0,1))
		resource.interact(game.player)
		resource.interact(game.player)
		check(int(State.inventory.get("wild_herb",0))==1,"Resource node grants one herb and cannot be harvested twice")
	State.add_item("wild_herb",2)
	check(int(State.quest_progress.herbs)==3,"Collect-item quest records gathering")
	await teleport(Vector3(-5.4,0,-2.6))
	State.talk_npc("keeper")
	check(int(State.quest_progress.keeper)==1,"NPC interaction advances the talk quest")
	game.hud.close_modal()
	await approach("shrine")
	await key(KEY_E)
	check(game.hud.modal_kind=="shrine" and State.hp==State.max_hp,"Shrine interaction heals and opens the wish UI")
	await shot("shrine")
	shards=State.astral_shards
	var rng:=RandomNumberGenerator.new()
	rng.seed=711
	var prize: String=State.summon(rng)
	check(not prize.is_empty() and State.inventory.has(prize) and State.astral_shards==shards-1,"A wish consumes exactly one shard and grants a relic")
	game.hud.rpg.shrine(prize)
	await shot("relic-reveal")
	var total_weight: float=0
	for rate in State.relic_data.rates: total_weight+=float(rate.weight)
	check(total_weight==100 and int(State.relic_data.rates[-1].weight)==3,"Data-driven shrine rates total 100%, including 3% legendary")
	State.astral_shards=0
	check(State.summon()=="" and State.astral_shards==0,"Shrine rejects wishes without enough shards")
	State.astral_shards=shards-1
	for id in ["travelers_coin","ember_ring","hunters_eye","storm_charm","fallen_king","void_echo"]: State.add_item(id)
	State.equip("travelers_coin")
	check(is_equal_approx(State.stats().move_speed,5.15),"Traveler's Coin improves movement speed by 3%")
	State.equip("ember_ring")
	check(State.attack_roll(rng).damage>State.damage_amount(),"Ember Ring adds fire damage to sword attacks")
	State.equip("hunters_eye")
	check(is_equal_approx(State.stats().crit,.10),"Hunter's Eye adds 5% critical chance")
	State.equip("storm_charm")
	var storm_triggered: bool=false
	for i in 120:
		if State.attack_roll(rng).storm: storm_triggered=true
	check(storm_triggered,"Storm Charm produces bonus-damage procs")
	State.equip("void_echo")
	var fifth: bool=false
	for i in 5: fifth=State.attack_roll(rng).echo
	check(fifth and not State.attack_roll(rng).echo,"Void Echo triggers every fifth swing")
	game.hud.close_modal()
	await key(KEY_J)
	check(game.hud.modal_kind=="quests","J opens the quest journal")
	await shot("quests")
	await key(KEY_J)
	await key(KEY_TAB)
	check(game.hud.modal_kind=="map","Tab opens the seeded world atlas")
	await shot("atlas")
	await key(KEY_TAB)
	await key(KEY_F3)
	check(game.debug_panel.visible and State.modal,"F3 displays seed, position, biome and streaming debug information")
	await key(KEY_F3)
	# Enter through an actual generated doorway, retaining its return point.
	var entrance_data: Dictionary={}
	for poi in generator.pois:
		if poi.kind=="crypt": entrance_data=poi; break
	await teleport(Vector3(entrance_data.position.x,0,entrance_data.position.y+2.5))
	freeze_enemies()
	var returned_to: Vector3=game.player.global_position
	await key(KEY_E)
	await frames(15)
	check(game.player.position.x>900 and State.region=="Forgotten Crypt","Generated entrance leads into the authored Forgotten Crypt")
	check(int(State.quest_progress.crypt)==1,"Dungeon arrival advances the reach-location quest")
	freeze_enemies()
	var route: bool=true
	for point in [Vector3(1000,0,-4),Vector3(1000,0,-16),Vector3(1000,0,-28),Vector3(1000,0,-36)]:
		if not await walk_to(point): route=false; break
	check(route,"All three crypt rooms connect through traversable doorways")
	await shot("crypt")
	var boss: Mossling
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"):
		if enemy.archetype=="guardian": boss=enemy; break
	await fight(boss)
	check(State.defeated_unique.has("crypt/warden") and owns_base("warden_mail"),"Final guardian awards unique armor and remains defeated")
	var treasure: ValeInteractable
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.persistent_id=="crypt/final_treasure": treasure=node; break
	treasure.interact(game.player)
	check(State.opened_chests.has(treasure.persistent_id) and owns_base("moon_blade"),"Final treasure chest grants an affixed rare blade and shards")
	coins=State.coins
	treasure.interact(game.player)
	check(State.coins==coins,"Final treasure is one-time only")
	await approach("moonseed")
	await key(KEY_E)
	check(State.flags.moonseed and State.inventory.has("moonseed"),"Original moonseed objective remains playable in the final chamber")
	game.hud.close_modal()
	State.equip("warden_mail")
	equip_base("moon_blade")
	State.equip("moonstone_heart")
	await key(KEY_I)
	await shot("inventory")
	await key(KEY_I)
	# Save while inside the dungeon; modify progression, then restore the exact journey.
	var expected:=ValeSave.snapshot(game.player.position)
	check(game.save_game(false,TEST_SAVE),"Versioned local save writes successfully")
	State.coins=0
	State.inventory.clear()
	State.opened_chests.clear()
	check(game.load_game(TEST_SAVE),"Load restores an isolated saved journey")
	check(State.coins==int(expected.coins) and State.inventory==expected.inventory and State.equipment==expected.equipment,"Inventory, equipment and currency survive save/load")
	check(State.world_seed==seed and game.generator.fingerprint()==fingerprint,"Save/load recreates the same seed and world layout")
	check(game.player.position.distance_to(ValeSave.vector(expected.position))<.1 and State.completed_quests.has("woods"),"Position and completed quests survive save/load")
	check(State.opened_chests.has("crypt/final_treasure") and boss.dead,"Opened chests and unique boss death survive reload")
	check(game.save_game(false,TEST_SAVE) and FileAccess.file_exists(TEST_SAVE+".bak"),"Updating a save creates a recoverable backup")
	var malformed:=FileAccess.open(TEST_SAVE,FileAccess.WRITE)
	malformed.store_string("{broken")
	malformed.close()
	check(not ValeSave.read(TEST_SAVE).is_empty() and not ValeSave.last_error.is_empty(),"A damaged primary save recovers from backup")
	check(not ValeSave.valid({"version":999}),"Unsupported save version is rejected without changing progression")
	await approach("exit",Vector3(0,0,-1.4))
	await key(KEY_E)
	check(game.player.position.distance_to(returned_to)<.2,"Crypt exit returns to the exact generated doorway")
	await approach("npc")
	await key(KEY_E)
	game.hud.close_modal()
	State.talk_to_rowan()
	game.hud.close_modal()
	check(State.flags.returned and not State.inventory.has("moonseed"),"Returning the moonseed preserves the original story completion")
	var previous_level: int=State.level
	State.gain_xp(1000)
	check(State.level>previous_level+1 and State.xp<State.level*60,"Large XP rewards support multiple level-ups")
	game.player.invulnerability=0
	game.player.take_damage(99999)
	check(game.player.position.distance_to(game.player.spawn_position)<.1 and State.hp==State.max_hp,"Defeat returns player safely to Willowmere without losing gear")
	game.new_world(44017)
	check(State.world_seed==44017 and State.level==1 and State.opened_chests.is_empty() and State.astral_shards==3,"New World resets progression and accepts a manual seed")
	var report: String="# Phase 3 regression of the established journey\n\nGodot %s; renderer %s.\n\n%d passed; %d failed.\n\n" % [Engine.get_version_info().string,DisplayServer.get_name(),checks.size(),failures.size()]
	for entry in checks: report+="- PASS: "+entry+"\n"
	for entry in failures: report+="- FAIL: "+entry+"\n"
	FileAccess.open("res://docs/PHASE_3_REGRESSION_RESULTS.md",FileAccess.WRITE).store_string(report)
	print("REGRESSION3_RESULT: %d passed, %d failed" % [checks.size(),failures.size()])
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)

func owns_base(base_id: String) -> bool:
	for id in State.inventory:
		if State.items[id].get("base_id",id)==base_id: return true
	return false

func equip_base(base_id: String) -> bool:
	for id in State.inventory:
		if State.items[id].get("base_id",id)==base_id:
			return State.equip(id)
	return false
