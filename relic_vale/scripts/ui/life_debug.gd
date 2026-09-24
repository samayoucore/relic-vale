class_name ValeLifeDebug
extends Panel
var game: Node
var info: Label
var overlay: ValeGenerationOverlay
var poi_choice: OptionButton
var points: Array[Dictionary]=[]
func _ready() -> void:
	position=Vector2(-880,0)
	size=Vector2(346,560)
	add_theme_stylebox_override("panel",game.hud.style())
	game.hud.label("LIVING WORLD · DEVELOPMENT",Vector2(18,15),Vector2(312,25),16,game.hud.GOLD,self)
	info=game.hud.label("",Vector2(18,49),Vector2(310,112),13,game.hud.PAPER,self)
	choice(["06:00 Dawn","09:00 Morning","13:00 Afternoon","18:00 Sunset","23:00 Night"],Vector2(18,170),func(i): game.life.set_time([6,9,13,18,23][i]))
	choice(ValeLife.WEATHER,Vector2(18,211),func(i): State.life_data.weather=ValeLife.WEATHER[i])
	poi_choice=choice(["Select destination"],Vector2(18,252),func(i): if i>0 and i<=points.size(): teleport(points[i-1].position))
	button("Nearby ridge",Vector2(18,298),func(): teleport(Vector2(114,105)))
	button("Rebuild chunk",Vector2(178,298),rebuild)
	button("+20 resources",Vector2(18,339),func():
		for id in ["wood","stone","iron_ore","wild_herb","mushroom","crystal","wolf_pelt","slime_gel","ancient_bone"]: State.add_item(id,20)
		State.coins+=200; State.changed.emit())
	button("Gathering & homes (F4)",Vector2(178,339),func(): game.debug_panel.toggle(); ValePhase6Debug.show(game.hud.ui))
	button("Crypt graph",Vector2(18,380),func(): game.expedition.enter("debug/crypt","crypt"))
	button("Mine graph",Vector2(178,380),func(): game.expedition.enter("debug/mine","mine"))
	choice(["No overlay","Biome influences","Density field","POI / road exclusions","Chunk boundaries","Road graph","River graph"],Vector2(18,422),func(i): overlay.rebuild(i))
	button("+20 reputation",Vector2(18,466),func():
		for id in State.faction_data: State.life_data.reputation[id]=mini(100,ValeLife.reputation(id)+20))
	button("Road event",Vector2(178,466),func(): game.life.spawn_event())
	overlay=ValeGenerationOverlay.new()
	overlay.gen=game.generator
	game.world.add_child(overlay)
	refresh_points()

func refresh_points() -> void:
	points=game.generator.pois.duplicate()
	poi_choice.clear()
	poi_choice.add_item("Teleport to settlement / POI")
	for p in points: poi_choice.add_item(p.get("title",p.kind.capitalize())+"  "+str(p.position))

func choice(values: Array, pos: Vector2, callback: Callable) -> OptionButton:
	var node:=OptionButton.new()
	node.position=pos
	node.size=Vector2(310,33)
	for value in values: node.add_item(str(value))
	game.hud.style_button(node)
	add_child(node)
	node.item_selected.connect(callback)
	return node

func button(value: String, pos: Vector2, callback: Callable) -> void:
	var node:=Button.new()
	node.text=value
	node.position=pos
	node.size=Vector2(150,33)
	game.hud.style_button(node)
	add_child(node)
	node.pressed.connect(callback)

func teleport(p: Vector2) -> void:
	game.player.position=Vector3(p.x,game.generator.landscape.height(p)+.2,p.y+4)
	game.player.velocity=Vector3.ZERO
	game.generator.update_streaming(true)
	game.rig.snap()
	overlay.rebuild(overlay.mode)

func rebuild() -> void:
	var key: String=game.generator.chunk_key(game.generator.coord_at(game.player.position))
	if not game.generator.active_chunks.has(key): return
	var chunk: Node=game.generator.active_chunks[key]
	game.generator.remove_child(chunk)
	chunk.queue_free()
	game.generator.active_chunks.erase(key)
	game.generator.build_chunk(game.generator.coord_at(game.player.position))
	overlay.rebuild(overlay.mode)

func _process(_delta: float) -> void:
	if not is_visible_in_tree(): return
	var p:=Vector2(game.player.position.x,game.player.position.z)
	var weights: Vector3=game.generator.landscape.weights(p)
	info.text="Day %d · %02d:%02d · %s\nBiome weights %.2f / %.2f / %.2f\nDensity %.2f · ground cover 1900 candidates/chunk\nReputation: %d / %d / %d\n20 recipes · %d POIs · 8-room expeditions" % [int(State.life_data.day),int(State.life_data.minute/60),int(State.life_data.minute)%60,State.life_data.weather,weights.x,weights.y,weights.z,game.generator.density_noise.get_noise_2d(p.x,p.y),ValeLife.reputation("hearth"),ValeLife.reputation("bough"),ValeLife.reputation("veil"),game.generator.pois.size()]
