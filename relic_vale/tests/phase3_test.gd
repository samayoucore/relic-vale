extends "res://tests/phase2_test.gd"
const SAVE3: String="user://phase3-test.json"

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/phase3-"+name+".png")

func click_button(prefix: String) -> void:
	for node in game.hud.rpg.find_children("*","Button",true,false):
		if node.text.begins_with(prefix):
			if DisplayServer.get_name()=="headless":
				node.pressed.emit()
				await frames(3)
				return
			var motion:=InputEventMouseMotion.new()
			motion.position=node.get_global_rect().get_center()
			Input.parse_input_event(motion)
			await frames(2)
			var event:=InputEventMouseButton.new()
			event.button_index=MOUSE_BUTTON_LEFT
			event.position=node.get_global_rect().get_center()
			event.pressed=true
			Input.parse_input_event(event)
			await frames(2)
			event.pressed=false
			Input.parse_input_event(event)
			await frames(3)
			return
	check(false,"UI button exists: "+prefix)

func run() -> void:
	game=get_tree().current_scene
	await frames(20)
	freeze_enemies()
	check(State.weapon_data.size()==5 and State.ability_data.size()==6,"Five weapon profiles and six abilities load from data")
	check(State.inventory.has("oak_bow") and State.inventory.has("apprentice_staff"),"A new traveler can try all five weapon styles immediately")
	await key(KEY_C)
	check(game.hud.modal_kind=="character","C opens character creation through input")
	var creator: ValeCreation
	for node in game.hud.rpg.get_children():
		if node is ValeCreation: creator=node
	creator.name_field.text="Aster"
	creator.look={"skin":2,"hair":4,"outfit":3,"cape":false}
	creator.refresh()
	await shot("character")
	await click_button("Confirm traveler")
	check(State.character_name=="Aster" and State.appearance.skin==2 and not State.appearance.cape and not State.modal,"Confirmation applies name, skin, hair, outfit and cloak")
	check(game.player.sprite.sprite_frames==PixelArt.character_frames(false,State.appearance),"In-world character uses the confirmed animated appearance")
	await key(KEY_B)
	await frames(5)
	check(game.hud.modal_kind=="abilities","B opens the ability loadout")
	State.set_ability(0,"fireball")
	State.set_ability(1,"frost_nova")
	game.hud.rpg.ability_menu()
	await shot("abilities")
	await key(KEY_B)
	check(State.abilities==["fireball","frost_nova"],"Two independently chosen active abilities are equipped")
	var counts: Array[int]=[]
	for rate in State.relic_data.rates: counts.append(rate.items.size())
	check(counts==[8,8,6,3],"Shrine pool contains 8 Common, 8 Rare, 6 Epic and 3 Legendary relics")
	var rng:=RandomNumberGenerator.new()
	rng.seed=42042
	var weapon: String=ValeGear.create("iron_greatsword","Legendary",rng)
	check(State.items[weapon].affixes.size()==3,"Legendary equipment rolls three distinct affixes")
	var second: String=ValeGear.create("oak_bow","Epic",rng)
	check(weapon!=second and State.items[second].affixes.size()==2,"Each generated item has a unique ID and rarity-scaled affix count")
	for affix in State.affix_data:
		var id: String="gear_%07d" % State.next_item_id
		State.next_item_id+=1
		check(ValeGear.materialize(id,{"base":"rustic_sword","rarity":"Rare","affixes":[affix]}),"Equipment materializes affix: "+affix)
		State.add_item(id)
		State.equip(id)
		for stat in State.affix_data[affix].modifiers:
			check(not is_zero_approx(float(State.stats()[stat])),"Affix contributes computed stat: "+stat)
	State.add_item(weapon)
	State.add_item(second)
	State.equip("rustic_sword")
	await key(KEY_I)
	game.hud.rpg.selected=weapon
	game.hud.rpg.inventory()
	await shot("affixes")
	await click_button("Equip to Weapon")
	check(State.equipment.Weapon==weapon and State.damage_amount()>20,"Inventory click equips affixed gear and changes damage")
	game.hud.close_modal()
	# A drop is persistent before collection, including a unique relic reward.
	await teleport(Vector3(1000,0,5))
	game.loot_manager.drop({"coins":17,"items":{second:1,"hollow_heart":1}},Vector3(1000,0,0))
	await frames(45)
	check(State.pending_loot.size()==1 and not State.inventory.has("hollow_heart"),"Ground loot waits for pickup and shows a rarity beam")
	await shot("loot")
	var before:=ValeSave.snapshot(game.player.position)
	check(game.save_game(false,SAVE3),"Version 3 save writes affixes, appearance and unclaimed loot")
	State.generated_items.clear()
	State.pending_loot.clear()
	State.abilities=["whirlwind","heal"]
	State.character_name="Changed"
	check(game.load_game(SAVE3),"Version 3 save reloads successfully")
	freeze_enemies()
	check(State.generated_items==before.generated_items and State.equipment==before.equipment,"Generated recipes reconstruct identical equipped items")
	check(State.pending_loot==before.pending_loot and State.abilities==before.abilities,"Unclaimed loot and both ability slots survive reload")
	check(State.character_name=="Aster" and State.appearance==before.appearance,"Name and palette appearance survive reload")
	await teleport(Vector3(1000,0,0))
	await frames(60)
	check(State.pending_loot.is_empty() and State.inventory.has("hollow_heart"),"Nearby pickup grants the saved legendary once")
	var owned: int=State.inventory.hollow_heart
	await frames(90)
	check(State.inventory.hollow_heart==owned and game.loot_manager.active.is_empty(),"Collected loot releases its scene and cannot duplicate rewards")
	# Migration uses actual v2 shape: only old base items and fields.
	var legacy:=before.duplicate(true)
	legacy.version=2
	for key in ["generated_items","pending_loot","abilities","character_name","appearance","appearance_confirmed","audio_settings"]: legacy.erase(key)
	legacy.inventory={"rustic_sword":1,"linen_hood":1,"trail_tonic":4}
	legacy.equipment={"Weapon":"rustic_sword","Head":"linen_hood","Body":"","Accessory":"","Relic":""}
	legacy.coins=123
	check(ValeSave.valid(legacy),"Old version 2 saves remain accepted")
	game.restore_world(ValeSave.apply(legacy))
	check(State.coins==123 and State.inventory.trail_tonic==4 and State.abilities==["whirlwind","heal"],"Migration preserves old progress and supplies new defaults")
	check(game.save_game(false,SAVE3),"A migrated journey can be written as version 3")
	freeze_enemies()
	# Healing, fire and mobility relic builds use the same combat/status components.
	State.add_item("overflowing_cup")
	State.equip("overflowing_cup")
	State.hp=State.max_hp
	game.player.restore_health(20)
	check(game.player.shield==20,"Overflowing Cup turns excess healing into a shield")
	State.add_item("winter_clock")
	State.equip("winter_clock")
	var target:=foe("skeleton",Vector3(1000,0,-2))
	await teleport(Vector3(1000,0,0))
	State.set_ability(0,"frost_nova")
	await key(KEY_1)
	await frames(2)
	check(target.statuses.has("slow") and target.statuses.has("stun"),"Winter Clock adds a stun to Frost Nova")
	State.add_item("ember_crown")
	State.equip("ember_crown")
	game.player.on_combat_hit(target,{"critical":false,"element":"fire"})
	check(target.statuses.has("burn") and State.stats().fire_percent>=.15,"Ember Crown supports a fire damage and burn build")
	target.queue_free()
	game.player.shield=0
	await teleport(Vector3(-3,0,-2.3))
	game.hud.show_shrine()
	var shards: int=State.astral_shards
	await click_button("Wish")
	check(game.hud.rpg.busy and State.astral_shards==shards-1,"Shrine click commits one shard before its cinematic reveal")
	await frames(80)
	check(game.hud.rpg.busy,"Shrine buildup lasts beyond one second")
	await shot("shrine-buildup")
	await click_button("Skip reveal")
	check(not game.hud.rpg.busy and State.astral_shards==shards-1,"Skip reveals the committed item without charging again")
	await shot("relic")
	game.hud.close_modal()
	await key(KEY_ESCAPE)
	check(State.paused and game.hud.modal_kind=="pause","Pause opens controls and audio settings")
	var sliders: Array=game.hud.rpg.find_children("*","HSlider",true,false)
	check(sliders.size()==3,"Master, Music and SFX have separate volume controls")
	sliders[1].value=.18
	check(is_equal_approx(State.audio_settings.Music,.18),"Music slider changes the live audio bus preference")
	await shot("audio")
	await key(KEY_ESCAPE)
	await key(KEY_F3)
	await shot("debug")
	await key(KEY_F3)
	await teleport(Vector3(0,0,3.6))
	await shot("village")
	var report: String="# Phase 3 systems verification\n\nGodot %s; renderer %s.\n\n%d passed; %d failed.\n\n" % [Engine.get_version_info().string,DisplayServer.get_name(),checks.size(),failures.size()]
	for entry in checks: report+="- PASS: "+entry+"\n"
	for entry in failures: report+="- FAIL: "+entry+"\n"
	FileAccess.open("res://docs/PHASE_3_TEST_RESULTS.md",FileAccess.WRITE).store_string(report)
	print("PHASE3_RESULT: %d passed, %d failed" % [checks.size(),failures.size()])
	await Feel.shutdown()
	get_tree().quit(0 if failures.is_empty() else 1)
