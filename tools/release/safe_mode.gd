extends Node
func _ready() -> void:
	await get_tree().process_frame
	var game=get_tree().current_scene
	var checks: Dictionary={"release_template":not OS.is_debug_build(),"developer_arguments_ignored":not game.test_mode and not game.gameplay_started,"safe_mode":Preferences.safe_mode,"minimal":Preferences.values.preset=="Minimal","windowed":Preferences.values.display=="Windowed","resolution":Preferences.values.resolution==Vector2i(1280,720),"finite_audio":is_finite(Preferences.values.Master)}
	Preferences.set_option("Master",.42)
	var file:=ConfigFile.new(); file.load(Preferences.PATH)
	checks.settings_persist_in_safe_mode=is_equal_approx(float(file.get_value("settings","Master",-1)),.42)
	ValeMenuPages.support(game.hud.ui)
	for i in 3: await get_tree().process_frame
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png(OS.get_environment("VALE_QA_DIR")+"/safe-mode-support.png")
	FileAccess.open(OS.get_environment("VALE_QA_DIR")+"/safe-mode.json",FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	print("SAFE_MODE_RESULT ",JSON.stringify(checks))
	await Feel.shutdown(); get_tree().quit(0 if not false in checks.values() else 1)
