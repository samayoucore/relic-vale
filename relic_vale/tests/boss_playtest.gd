extends "res://tests/phase2_test.gd"
## Timed normal-damage encounter; no forced HP changes or invulnerability.
func run() -> void:
	game=get_tree().current_scene
	await frames(20)
	var boss: Mossling
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"):
		if enemy.archetype=="guardian": boss=enemy
		else: enemy.set_physics_process(false)
	State.level=3
	State.recalculate()
	State.hp=State.max_hp
	State.add_item("iron_sword")
	State.add_item("leather_vest")
	State.equip("iron_sword")
	State.equip("leather_vest")
	State.set_ability(0,"fireball")
	State.set_ability(1,"heal")
	game.player.position=Vector3(1000,0,-34)
	game.rig.snap()
	var elapsed: float=0
	var lowest_hp: int=State.hp
	var phase_two: bool=false
	var captured: bool=false
	while elapsed<180 and not boss.dead and game.player.position.x>900:
		elapsed+=1.0/60
		lowest_hp=mini(lowest_hp,State.hp)
		phase_two=phase_two or boss.boss.phase==2
		var target: Mossling=boss
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy!=boss and enemy.position.distance_to(game.player.position)<3: target=enemy; break
		var to_enemy: Vector3=target.position-game.player.position
		to_enemy.y=0
		var move: Vector3=to_enemy.normalized() if to_enemy.length()>1.9 else Vector3.ZERO
		var danger: bool=boss.boss.action in ["slash","slam","charge","charging","hazard"]
		if danger:
			if boss.boss.action in ["charge","charging"]: move=Vector3(-boss.boss.charge_direction.z,0,boss.boss.charge_direction.x)
			elif game.player.position.distance_to(boss.boss.target_point)<3.8: move=(game.player.position-boss.boss.target_point).normalized()
			if move.length()<.1: move=Vector3.RIGHT
		if game.player.position.x<994: move.x=maxf(.5,move.x)
		if game.player.position.x>1006: move.x=minf(-.5,move.x)
		if game.player.position.z> -34: move.z=minf(-.5,move.z)
		if game.player.position.z< -47: move.z=maxf(.5,move.z)
		var input_dir:=move.rotated(Vector3.UP,-game.rig.yaw)
		Input.action_press("move_right",maxf(0,input_dir.x))
		Input.action_press("move_left",maxf(0,-input_dir.x))
		Input.action_press("move_down",maxf(0,input_dir.z))
		Input.action_press("move_up",maxf(0,-input_dir.z))
		if danger and game.player.dash_cooldown<=0 and boss.boss.timer<.5:
			game.player.facing=move.normalized()
			var dodge:=InputEventAction.new()
			dodge.action="dodge"
			dodge.pressed=true
			game.player._unhandled_input(dodge)
		game.player.facing=to_enemy.normalized()
		if not danger and to_enemy.length()<2.4 and game.player.attack_timer<=0: game.player.attack()
		if not danger and game.player.abilities.cooldowns.fireball<=0: game.player.abilities.use(0)
		if State.hp<State.max_hp*.65: game.player.abilities.use(1)
		if State.hp<38 and State.inventory.get("trail_tonic",0)>0: State.drink_tonic()
		if phase_two and not captured and boss.boss.action=="slam" and DisplayServer.get_name()!="headless":
			captured=true
			await frames(3)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase3-boss-playtest.png")
		await frames(1)
	for action in ["move_up","move_down","move_left","move_right"]: Input.action_release(action)
	print("BOSS_PLAYTEST: seconds=%.1f boss_hp=%d hero_hp=%d lowest_hp=%d phase_two=%s defeated=%s" % [elapsed,boss.hp,State.hp,lowest_hp,phase_two,boss.dead])
	check(boss.dead and phase_two,"Level 3 sword/fireball/heal build defeats both boss phases with normal damage")
	check(elapsed>=60 and elapsed<=180,"Encounter duration falls within the intended one-to-three minute range")
	FileAccess.open("res://docs/BOSS_PLAYTEST.md",FileAccess.WRITE).store_string("# Boss playtest\n\nGodot %s · %s. Level 3, iron sword, leather vest, Fireball and Mending Light. Normal incoming damage; movement and dodge input, no HP override or god mode.\n\nElapsed %.1f simulation seconds. Lowest HP %d. Boss HP remaining %d. Phase II reached: %s. Defeated: %s.\n\nThis controller checks one build and does not replace broad human balance testing.\n" % [Engine.get_version_info().string,DisplayServer.get_name(),elapsed,lowest_hp,boss.hp,phase_two,boss.dead])
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)
