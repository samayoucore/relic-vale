extends "res://tests/smoke_test.gd"
var dummy: Mossling

func prepare(distance: float = 1.3) -> void:
	dummy.hp=200
	dummy.max_hp=200
	dummy.dead=false
	dummy.position=Vector3(1000,0,0)
	dummy.statuses.clear()
	game.player.position=Vector3(1000,0,distance)
	game.player.velocity=Vector3.ZERO
	game.player.facing=Vector3.FORWARD
	game.player.attack_timer=0
	game.player.combat.cancel()
	game.player.abilities.global_cooldown=0
	for id in game.player.abilities.cooldowns: game.player.abilities.cooldowns[id]=0
	for projectile in get_tree().get_nodes_in_group("projectiles"): projectile.queue_free()
	await frames(3)

func run() -> void:
	game=get_tree().current_scene
	await frames(15)
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"): enemy.set_physics_process(false)
	dummy=preload("res://scenes/characters/Enemy.tscn").instantiate()
	dummy.position=Vector3(1000,0,0)
	game.world.add_child(dummy)
	dummy.set_physics_process(false)
	await prepare()
	game.player.attack()
	await frames(3)
	check(dummy.hp==200 and game.player.combat.pending,"Sword anticipation precedes its damage frame")
	await frames(7)
	check(dummy.hp<200 and not game.player.combat.pending,"Sword impact lands after anticipation")
	var hp: int=dummy.hp
	game.player.attack()
	await frames(3)
	check(dummy.hp==hp,"Attack recovery prevents immediate repeated damage")
	var times: Array[float]=[]
	for id in ["rustic_sword","iron_greatsword","twin_daggers","apprentice_staff","oak_bow"]:
		State.add_item(id)
		State.equip(id)
		await prepare(5 if id in ["apprentice_staff","oak_bow"] else 1.3)
		game.player.attack()
		times.append(game.player.attack_timer)
		await frames(60)
		check(dummy.hp<200,"Weapon produces a working hit: "+id)
	check(times[1]>times[0] and times[2]<times[0],"Greatsword and daggers have distinct timing")
	State.equip("rustic_sword")
	for id in ["whirlwind","fireball","frost_nova","arcane_missiles"]:
		State.set_ability(0,id)
		await prepare(4 if id in ["fireball","arcane_missiles"] else 1.3)
		await key(KEY_1)
		await frames(65)
		check(dummy.hp<200 and game.player.abilities.cooldowns[id]>0,"Ability damages enemies and enters cooldown: "+id)
		if id=="frost_nova": check(dummy.statuses.has("slow"),"Frost Nova applies shared Slow")
		if id=="fireball": check(dummy.statuses.has("burn"),"Fireball applies shared Burn")
	State.set_ability(0,"dash_strike")
	await prepare(4)
	var old: Vector3=game.player.position
	game.player.abilities.use(0)
	await frames(30)
	check(game.player.position.distance_to(old)>1 and dummy.hp<200,"Dash Strike moves, then damages nearby enemies")
	State.set_ability(0,"heal")
	await prepare()
	State.hp=30
	game.player.abilities.use(0)
	await frames(65)
	check(State.hp>55 and game.player.statuses.has("regeneration"),"Mending Light heals and regenerates")
	await prepare()
	dummy.statuses.apply("poison",3,5)
	await frames(65)
	check(dummy.hp<=195,"Poison deals damage over time")
	dummy.statuses.apply("stun",.5,1)
	check(dummy.statuses.move_multiplier()==0,"Stun blocks movement through the shared status component")
	await frames(40)
	check(not dummy.statuses.has("stun"),"Statuses expire cleanly")
	check(Feel.voices.size()==16 and Feel.samples.size()>=18 and Feel.music.playing,"Bounded SFX voices and music are active")
	print("COMBAT3_RESULT: %d passed, %d failed" % [checks.size(),failures.size()])
	await frames(75)
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)
