extends Panel
var game: Node
var info: Label
var seed_input: LineEdit
var note: Label
var enemy_choice: OptionButton
var metrics: Label
var logical_x: LineEdit
var logical_z: LineEdit

func _ready() -> void:
	position=Vector2(908,100)
	size=Vector2(346,560)
	add_theme_stylebox_override("panel",game.hud.style())
	game.hud.label("WORLD JOURNAL  ·  F3",Vector2(18,15),Vector2(310,24),17,game.hud.GOLD,self)
	info=game.hud.label("",Vector2(18,48),Vector2(310,125),14,game.hud.PAPER,self)
	seed_input=LineEdit.new()
	seed_input.position=Vector2(18,181)
	seed_input.size=Vector2(310,35)
	seed_input.text=str(State.world_seed)
	seed_input.placeholder_text="World seed (whole number)"
	add_child(seed_input)
	button("Generate seed",Vector2(18,230),Vector2(149,36),generate)
	button("Random seed",Vector2(179,230),Vector2(149,36),random_seed)
	button("Village",Vector2(18,275),Vector2(149,36),village)
	button("Clear enemies",Vector2(179,275),Vector2(149,36),clear_enemies)
	note=game.hud.label("Same seed, same terrain. Progress is kept.",Vector2(18,325),Vector2(310,25),11,game.hud.MUTED,self)
	button("+300 XP",Vector2(18,361),Vector2(149,34),func(): State.gain_xp(300))
	button("+10 shards",Vector2(179,361),Vector2(149,34),func(): State.astral_shards+=10; State.changed.emit())
	button("Legendary gear",Vector2(18,402),Vector2(149,34),func(): State.add_item(ValeGear.create("iron_greatsword","Legendary")))
	button("God mode",Vector2(179,402),Vector2(149,34),func(): game.player.god_mode=not game.player.god_mode; note.text="God mode: "+str(game.player.god_mode))
	enemy_choice=OptionButton.new()
	enemy_choice.position=Vector2(18,445)
	enemy_choice.size=Vector2(149,34)
	for kind in ["slime","wolf","skeleton","archer","witch","bat","mimic","elite"]: enemy_choice.add_item(kind)
	game.hud.style_button(enemy_choice)
	add_child(enemy_choice)
	button("Spawn enemy",Vector2(179,445),Vector2(149,34),spawn_enemy)
	button("Boss arena",Vector2(18,491),Vector2(149,34),boss_arena)
	button("Heal & cleanse",Vector2(179,491),Vector2(149,34),func(): State.hp=State.max_hp; game.player.statuses.clear(); State.changed.emit())
	visible=false
	var living:=ValeLifeDebug.new()
	living.game=game
	add_child(living)
	var panel:=PanelContainer.new(); panel.position=Vector2(-520,0); panel.size=Vector2(505,320); add_child(panel)
	var box:=VBoxContainer.new(); panel.add_child(box)
	metrics=Label.new(); metrics.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(metrics)
	var row:=HBoxContainer.new(); box.add_child(row)
	logical_x=LineEdit.new(); logical_x.text="10000"; logical_x.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(logical_x)
	logical_z=LineEdit.new(); logical_z.text="10000"; logical_z.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(logical_z)
	var teleport:=Button.new(); teleport.text="Teleport logical chunks"; game.hud.style_button(teleport); box.add_child(teleport)
	teleport.pressed.connect(func():
		if logical_x.text.is_valid_int() and logical_z.text.is_valid_int():
			game.generator.teleport_logical(int(logical_x.text),int(logical_z.text))
			game.hud.show_toast("Logical destination loaded."))

func spawn_enemy() -> void:
	var enemy: Mossling=load("res://scenes/characters/Enemy.tscn").instantiate()
	enemy.set_meta("archetype",enemy_choice.get_item_text(enemy_choice.selected))
	enemy.set_meta("enemy_level",State.level)
	enemy.position=game.player.position+game.player.facing*3
	game.world.add_child(enemy)
	note.text="Enemy spawned. Close F3 to fight."

func boss_arena() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"):
		if enemy.archetype=="guardian":
			State.defeated_unique.erase(enemy.persistent_id)
			enemy.revive()
	game.player.position=Vector3(1000,0,-34)
	game.player.velocity=Vector3.ZERO
	game.rig.snap()

func button(text: String, pos: Vector2, extent: Vector2, callback: Callable) -> void:
	var node:=Button.new()
	node.text=text
	node.position=pos
	node.size=extent
	game.hud.style_button(node)
	add_child(node)
	node.pressed.connect(callback)

func toggle() -> void:
	if not visible and State.modal: game.hud.close_modal()
	visible=not visible
	State.modal=visible
	if visible: seed_input.text=str(State.world_seed)
	else: seed_input.release_focus()

func generate() -> void:
	if not seed_input.text.is_valid_int():
		note.text="Enter a whole-number seed."
		return
	game.player.position=Vector3(0,0,3.6)
	game.generator.origin_x=0; game.generator.origin_z=0
	game.generator.sync_hub()
	game.player.velocity=Vector3.ZERO
	game.rig.snap()
	game.generator.regenerate(int(seed_input.text))
	seed_input.text=str(State.world_seed)
	note.text="World generated. Close F3 to explore."

func random_seed() -> void:
	seed_input.text=str(randi_range(1,2147483000))
	generate()

func village() -> void:
	game.player.respawn()
	game.generator.update_streaming(true)

func clear_enemies() -> void:
	var count: int=0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(game.player.global_position)<20:
			enemy.queue_free()
			count+=1
	note.text="Removed %d nearby enemies; no rewards granted." % count

func _process(_delta: float) -> void:
	if not visible: return
	var graphics: ValeGraphics=game.graphics
	var gen: ValeStreamingGenerator=game.generator
	metrics.text="STREAMING & RENDERING\n%d FPS · %.1f ms CPU frame · GPU time unavailable (OpenGL)\n%d draw calls · %d nodes · %d vegetation instances\n%d cosmetic particles · %d active chunks / %d blueprints\n%s · Pixelated %s · render scale %.0f%% · %s\nLogical origin %s,%s · %d shifts\nWorker %.1f ms · worst main stage %.1f ms\nPreload %d · unload %d · data cache %d\n" % [Engine.get_frames_per_second(),Performance.get_monitor(Performance.TIME_PROCESS)*1000,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.OBJECT_NODE_COUNT),graphics.foliage_instances,graphics.particle_count,gen.active_chunks.size(),gen.blueprints.size(),Preferences.values.preset,str(Preferences.values.pixelated),float(Preferences.values.render_scale)*100,str(game.viewport.size),str(gen.origin_x),str(gen.origin_z),gen.shifts,gen.generation_ms,gen.worst_build_ms,gen.preload_radius,gen.unload_radius,gen.cache_limit]
	var p: Vector3=game.player.global_position
	info.text="Seed  %d\nPosition  %.1f, %.1f  ·  Level %d\n%s  ·  Chunk %s\nFPS %d  ·  Chunks %d  ·  Drops %d\nEffects: %s" % [State.world_seed,p.x,p.z,State.level,State.region,str(game.generator.coord_at(p)),Engine.get_frames_per_second(),game.generator.active_chunks.size(),State.pending_loot.size(),", ".join(game.player.statuses.effects.keys())]
