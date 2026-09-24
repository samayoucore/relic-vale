extends "res://tests/smoke_test.gd"
## Focused visual and pointer-driven checks after the final presentation pass.

func click_at(pos: Vector2) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.position=pos
	Input.parse_input_event(motion)
	await frames(2)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.position=pos
		event.pressed=pressed
		Input.parse_input_event(event)
		await frames(3)

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(10)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase2-"+name+".png")

func find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix): return node
	for child in node.get_children():
		var result:=find_button(child,prefix)
		if result: return result
	return null

func press(prefix: String) -> void:
	var button:=find_button(game.hud,prefix)
	if not button:
		check(false,"Button exists: "+prefix)
		return
	await click_at(button.get_global_rect().get_center())

func run() -> void:
	game=get_tree().current_scene
	await frames(20)
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"): enemy.set_physics_process(false)
	State.add_item("moon_blade")
	State.add_item("warden_mail")
	State.add_item("moonstone_heart")
	State.add_item("amber_band")
	await key(KEY_I)
	game.hud.rpg.selected="moon_blade"
	game.hud.populate_inventory()
	await press("Equip to Weapon")
	check(State.equipment.Weapon=="moon_blade","Inventory Equip button works with real mouse input")
	await press("Unequip")
	check(State.equipment.Weapon.is_empty(),"Inventory Unequip button updates the slot")
	await press("Equip to Weapon")
	State.equip("warden_mail")
	State.equip("moonstone_heart")
	State.equip("amber_band")
	await shot("inventory")
	await key(KEY_ESCAPE)
	State.visit_shrine()
	var shards: int=State.astral_shards
	await press("Wish")
	await press("Wish")
	check(State.astral_shards==shards-1,"Wish button blocks duplicate input during the reveal")
	await frames(65)
	check(not game.hud.rpg.busy and find_button(game.hud,"Equip relic")!=null,"Summon glow completes and reveals the item card")
	await shot("relic-reveal")
	await press("Equip relic")
	check(State.items[State.equipment.Relic].kind=="relic","Revealed relic can be equipped from its result card")
	await key(KEY_ESCAPE)
	State.coins=100
	game.hud.rpg.shop("smith")
	await press("Buy · 45")
	check(State.coins==55 and State.inventory.has("iron_sword"),"Blacksmith trade deducts copper and grants a blade")
	await key(KEY_ESCAPE)
	State.add_item("slime_gel",3)
	game.hud.rpg.shop("merchant")
	await press("Sell materials")
	check(State.coins==64 and not State.inventory.has("slime_gel"),"Merchant buys spare materials")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	await shot("pause")
	await press("New World")
	check(game.hud.modal_kind=="new_world","Pause opens the manual-seed New World screen")
	await shot("new-world")
	await key(KEY_ESCAPE)
	await key(KEY_F3)
	await shot("debug")
	await key(KEY_F3)
	var generator: ValeGenerator=game.generator
	for biome in generator.BIOMES:
		for data in generator.layout.values():
			if data.biome!=biome or data.poi.is_empty() or generator.HUB.grow(10).has_point(data.center): continue
			game.player.position=Vector3(data.center.x,0,data.center.y+5)
			game.player.velocity=Vector3.ZERO
			game.rig.snap()
			generator.update_streaming(true)
			for enemy in get_tree().get_nodes_in_group("enemy_bodies"): enemy.set_physics_process(false)
			await frames(30)
			await shot(biome.to_lower().replace(" ","-"))
			break
	var report: String="# Pointer and presentation verification\n\n%d passed; %d failed.\n\n" % [checks.size(),failures.size()]
	for entry in checks: report+="- PASS: "+entry+"\n"
	for entry in failures: report+="- FAIL: "+entry+"\n"
	FileAccess.open("res://docs/UI_TEST_RESULTS.md",FileAccess.WRITE).store_string(report)
	print("UI_RESULT: %d passed, %d failed" % [checks.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
