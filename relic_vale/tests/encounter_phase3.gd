extends "res://tests/smoke_test.gd"
var boss: Mossling

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase3-"+name+".png")

func run() -> void:
	game=get_tree().current_scene
	await frames(20)
	game.player.god_mode=true
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"):
		if enemy.archetype=="guardian": boss=enemy
		else: enemy.set_physics_process(false)
	game.player.position=Vector3(1000,0,-36)
	game.rig.snap()
	await frames(120)
	check(boss.boss.engaged and is_instance_valid(boss.boss.gate),"Crypt arena seals when the boss encounter starts")
	check(boss.boss.phase==1,"Boss begins in phase I")
	for i in 3:
		boss.boss.begin(["slash","charge","slam"][i])
		await frames(20)
		check(not boss.boss.markers.is_empty(),"Boss attack has a visible anticipation marker")
		if i==2: await shot("boss-slam")
		await frames(120)
	check(boss.boss.action_history.has("slash") and boss.boss.action_history.has("charge") and boss.boss.action_history.has("slam"),"Phase I uses slash, charge and ground slam")
	boss.take_damage(ceili(boss.max_hp*.51),Vector3.ZERO,{"secondary":true})
	await frames(15)
	check(boss.boss.phase==2 and boss.boss.minions.size()==2,"At half health the boss enters phase II and summons two sentinels")
	boss.boss.begin("shockwave")
	await frames(70)
	check(get_tree().get_nodes_in_group("projectiles").size()>0,"Phase II releases radial shockwave projectiles")
	await shot("boss-phase-two")
	boss.boss.begin("hazard")
	await frames(85)
	check(get_tree().get_nodes_in_group("combat_hazards").size()==2,"Phase II creates two telegraphed hazard zones")
	game.player.position=Vector3(1000,0,-20)
	await frames(5)
	check(not boss.boss.engaged and boss.hp==boss.max_hp,"Leaving the arena resets the encounter safely")
	game.player.position=Vector3(1000,0,-36)
	await frames(5)
	boss.take_damage(99999)
	await frames(50)
	game.player.position=boss.global_position
	await frames(35)
	check(boss.dead and State.defeated_unique.has("crypt/warden") and State.inventory.has("hollow_heart"),"Boss death unlocks its unique legendary reward")
	check(not is_instance_valid(boss.boss.gate) and get_tree().get_nodes_in_group("combat_hazards").is_empty(),"Boss death removes gate and hazards")
	for kind in ["wolf","archer","witch","bat","mimic","elite"]:
		var enemy: Mossling=load("res://scenes/characters/Enemy.tscn").instantiate()
		enemy.set_meta("archetype",kind)
		enemy.set_meta("enemy_level",3)
		enemy.position=Vector3(1000,0,-2)
		game.world.add_child(enemy)
		game.player.position=Vector3(1000,0,2 if kind!="mimic" else -.2)
		enemy.spawn_grace=0
		enemy.cooldown=0
		await frames(140)
		check(enemy.mind!=null or not enemy.elite_modifier.is_empty(),"Distinct behavior attached: "+kind)
		if kind=="mimic": check(enemy.mind.awake,"Mimic wakes when approached")
		if kind in ["archer","witch"]: check(enemy.cooldown>0 or enemy.windup>0,"Ranged enemy performs a cast: "+kind)
		enemy.queue_free()
		await frames(5)
	await frames(80)
	print("ENCOUNTER3_RESULT: %d passed, %d failed" % [checks.size(),failures.size()])
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)
