extends "res://tests/ui_check.gd"
func run() -> void:
	game=get_tree().current_scene; await frames(20)
	game.player.god_mode=true
	for id in ["wood","stone","iron_ore","wild_herb","mushroom","crystal"]: State.add_item(id,10)
	for scale in [1.0,1.5]:
		Preferences.set_option("ui_scale",scale)
		await shot("phase5-final-hud-"+str(scale))
		check(game.hud.ui.chrome.get_node("Bottom").get_global_rect().end.x<=1281,"HUD fits at scale "+str(scale))
		game.hud.show_inventory(); await shot("phase5-final-materials-"+str(scale)); game.hud.close_modal()
	Preferences.set_option("ui_scale",1.0)
	for target in get_tree().get_nodes_in_group("interactables"):
		if target.kind=="station": game.hud.ui.crafting_page(target); await shot("phase5-final-crafting"); game.hud.close_modal(); break
	game.hud.ui.dialogue("Rowan","The lantern roads reach past every known hill. Return with what you find, and the village will remember.")
	await shot("phase5-final-dialogue"); game.hud.close_modal()
	State.quest_progress.keeper=1; game.generator.chart_chunk("0,0"); game.hud.show_map(); await shot("phase5-final-atlas"); game.hud.close_modal()
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]:
		Preferences.set_option("resolution",resolution); game.hud.show_inventory(); await frames(10)
		await RenderingServer.frame_post_draw
		var image:=get_viewport().get_texture().get_image()
		check(image.get_size()==resolution,"Actual rendered framebuffer matches "+str(resolution))
		image.save_png("res://docs/screenshots/phase5-native-"+str(resolution.x)+".png")
		game.hud.close_modal()
	Preferences.set_option("resolution",Vector2i(1280,720))
	print("UI5_FINAL_RESULT ",checks.size()," passed ",failures.size()," failed")
	await Feel.shutdown(); get_tree().quit(0 if failures.is_empty() else 1)
