class_name ValeMenuPages
extends RefCounted
const SLOTS=["user://journey.json","user://journey-slot2.json","user://journey-slot3.json"]

static func main_menu(ui: ValeInterface) -> void:
	ui.page("main_menu","RELIC VALE","A ROAD STILL UNWRITTEN")
	ui.hud.modal_shade.color=Color(.015,.035,.04,.25)
	ui.hud.modal_button.visible=false
	var column:=ui.scroll(ui.body)
	ui.text(column,"Quiet roads. Ancient oaths. A world beyond the next hill.","Heading",true)
	ui.button(column,"Continue",func(): load_journey(ui,ui.game.active_save_path),not FileAccess.file_exists(ui.game.active_save_path) and not FileAccess.file_exists(ui.game.active_save_path+".bak"))
	ui.button(column,"New Game",func(): new_world(ui))
	ui.button(column,"Load Game",func(): saves(ui))
	ui.button(column,"Settings",ui.settings_page)
	ui.button(column,"Credits",func(): credits(ui))
	ui.button(column,"Help & Support",func(): support(ui))
	ui.button(column,"Quit",ui.game.quit_game)
	ui.text(column,"Version "+str(ProjectSettings.get_setting("application/config/version","0.10.0")),"Muted")

static func pause_menu(ui: ValeInterface) -> void:
	ui.page("pause","A moment by the road","JOURNEY PAUSED")
	State.paused=true
	var column:=ui.scroll(ui.body)
	ui.text(column,State.world_data.name+" · "+State.character_name+" · Level %d" % State.level,"Heading",true)
	ui.button(column,"Resume",ui.hud.close_modal)
	ui.button(column,"Inventory",ui.inventory_page)
	ui.button(column,"Settings",ui.settings_page)
	ui.button(column,"How to play",func(): onboarding(ui))
	ui.button(column,"Save Game",func(): ui.game.save_game())
	ui.button(column,"Load Game",func(): saves(ui))
	ui.button(column,"Return to Main Menu",func():
		if ui.game.gameplay_started and not ui.game.save_game(false): return
		ui.game.gameplay_started=false
		ui.game.generator.teleport_logical(0,0,Vector3(0,0,4)); ui.game.life.set_time(18); main_menu(ui))
	ui.button(column,"Save & Quit",ui.game.quit_game)

static func loading(ui: ValeInterface) -> void:
	ui.page("loading","Following the lanterns","A JOURNEY TAKES SHAPE")
	ui.hud.modal_button.visible=false
	ui.text(ui.body,"The road continues beyond what you can see.","Heading",true)
	var progress:=ProgressBar.new(); progress.indeterminate=true; progress.custom_minimum_size.y=14; ui.body.add_child(progress)
	ui.text(ui.body,"Tip: different weapons change how your primary attack behaves.","Muted",true)
	await ui.get_tree().process_frame
	if DisplayServer.get_name()!="headless": RenderingServer.force_draw(false)

static func load_journey(ui: ValeInterface,path: String) -> void:
	await loading(ui)
	if ui.game.load_game(path):
		ui.game.active_save_path=path; ui.game.gameplay_started=true
		ui.hud.close_modal()
	else: saves(ui)

static func new_world(ui: ValeInterface) -> void:
	ui.page("new_world","A road yet unwritten","NEW WORLD")
	var fields:=ui.scroll(ui.body)
	ui.text(fields,"World name","Caption")
	var name:=LineEdit.new(); name.text="The Lower Vale"; name.max_length=36; name.custom_minimum_size.y=40; fields.add_child(name)
	ui.text(fields,"World seed","Caption")
	var seed_row:=ui.row(fields)
	var seed:=LineEdit.new(); seed.text=str(randi_range(1,2147483000)); seed.size_flags_horizontal=Control.SIZE_EXPAND_FILL; seed_row.add_child(seed)
	ui.button(seed_row,"Randomize",func(): seed.text=str(randi_range(1,2147483000)))
	ui.text(fields,"Save slot","Caption")
	var slot:=ui.option(fields,["Journey 1","Journey 2","Journey 3"],0,func(_i): pass)
	ui.text(fields,"Starting here replaces the chosen slot. Its previous save remains available as a backup.","Muted",true)
	ui.button(ui.footer,"Begin journey",func():
		if not seed.text.is_valid_int() or seed.text.length()>10 or absf(float(seed.text))>2147483646: ui.hud.show_toast("Enter a whole-number seed between -2147483646 and 2147483646."); return
		var world_name: String=name.text.strip_edges(); var world_seed: int=int(seed.text); var path: String=SLOTS[slot.selected]
		await loading(ui)
		ui.game.active_save_path=path; ui.game.gameplay_started=true
		ui.game.new_world(world_seed,world_name))

static func saves(ui: ValeInterface) -> void:
	ui.page("saves","Journeys remembered","LOAD GAME")
	var list:=ui.scroll(ui.body)
	for i in SLOTS.size():
		var data: Dictionary=ValeSave.read(SLOTS[i])
		ui.text(list,"JOURNEY %d" % (i+1),"Caption")
		if data.is_empty():
			ui.text(list,ValeSave.last_error if FileAccess.file_exists(SLOTS[i]) or FileAccess.file_exists(SLOTS[i]+".bak") else "An unwritten page","Muted",true)
			continue
		if not ValeSave.last_error.is_empty(): ui.text(list,ValeSave.last_error,"Muted",true)
		if FileAccess.file_exists(SLOTS[i]+".png"):
			var preview:=Image.new()
			if preview.load(SLOTS[i]+".png")==OK: ui.picture(list,ImageTexture.create_from_image(preview),Vector2(256,144))
		var world: Dictionary=data.get("world",{})
		ui.text(list,world.get("name","The Lower Vale"),"Heading",true)
		ui.text(list,"%s · Level %d · %d minutes played\nLast played %s · Seed %d" % [data.get("character_name","Traveler"),data.level,int(float(world.get("playtime",0))/60),data.saved_at,data.world_seed],"Muted",true)
		ui.button(list,"Continue journey %d" % (i+1),func(): load_journey(ui,SLOTS[i]))

static func credits(ui: ValeInterface) -> void:
	ui.page("credits","Made along the road","CREDITS & LICENSES")
	var list:=ui.scroll(ui.body)
	ui.text(list,"Relic Vale · "+str(ProjectSettings.get_setting("application/config/version"))+"\nA single-player fantasy journey built with Godot.","Heading",true)
	ui.text(list,"Tools, furniture and animated animals: Quaternius (CC0). Foley: rubberduck, 100 CC0 SFX #2. Hoofbeats: EZduzziteh (CC0). Cow recording: Secretlondon, Mudchute Farm, via OpenGameArt (CC BY-SA 3.0); unmodified audio. License text and original source links are included in THIRD_PARTY_LICENSES.txt.","",true)
	ui.text(list,"World art: Kenney, Quaternius, Kay Lousberg. Pixel traveler: LPC assets, with the original credits retained in THIRD_PARTY_LICENSES.txt.\n\nInterface: Kenney UI Pack RPG Expansion (CC0). Icons: Fantasy RPG Icons by Drummyfish (CC0). Fonts: Rubik and Press Start 2P (SIL Open Font License).\n\nProcedural world, shaders, interface code and synthesized audio were created for this project. Full source links, asset selections and licenses are bundled with the game.","",true)
	ui.button(list,"Full acknowledgements & licenses",func():
		ui.page("licenses","The people behind the road","ACKNOWLEDGEMENTS")
		ui.text(ui.scroll(ui.body),FileAccess.get_file_as_string("res://THIRD_PARTY_LICENSES.txt"),"",true))

static func onboarding(ui: ValeInterface) -> void:
	ui.page("help","Your first steps","WELCOME TO WILLOWMERE")
	var list:=ui.scroll(ui.body)
	ui.text(list,"Speak with Rowan beside the village well to find your first task.","Heading",true)
	for line in ["WASD / arrows — move. Hold Shift to run.","Approach a person or object, then press E when its prompt appears.","Space / left click — attack. Ctrl — dodge. H — drink a tonic.","I — open inventory and equip your weapon. 1 / 2 — abilities.","Tab — open the atlas. J — read and track quests.","Q / R — orbit the camera. Right drag — orbit and tilt. Wheel — zoom.","Esc — pause, settings and this guide. F6 — save; F9 — reload."]:
		ui.text(list,line,"",true)
	ui.text(list,"Later: P opens professions, fishing and mounts; G manages your camp; O opens company. At camp tier 3, buy a horse for 180 copper in P → Mounts. Press "+Preferences.values.mount_key+" to call it, approach and press E to mount. Press "+Preferences.values.mount_key+" again to dismount on open ground.","Muted",true)
	ui.button(ui.footer,"Follow the road",ui.hud.close_modal)

static func support(ui: ValeInterface) -> void:
	ui.page("support","Help along the road","SUPPORT")
	var list:=ui.scroll(ui.body)
	var details: String="Relic Vale %s\n%s %s\nGodot %s · %s\nGPU: %s\nPreset: %s · Save format: %d\nData folder: %s" % [ProjectSettings.get_setting("application/config/version"),OS.get_name(),OS.get_version(),Engine.get_version_info().string,RenderingServer.get_current_rendering_method(),RenderingServer.get_video_adapter_name(),Preferences.values.preset,ValeSave.VERSION,OS.get_user_data_dir()]
	ui.text(list,details,"",true)
	ui.button(list,"Copy support information",func(): DisplayServer.clipboard_set(details); ui.hud.show_toast("Support information copied."))
	ui.button(list,"Open save folder",func(): OS.shell_open(OS.get_user_data_dir()))
	ui.button(list,"Open log folder",func(): OS.shell_open(OS.get_user_data_dir()+"/logs"))
	ui.text(list,"For graphics trouble, use the Safe Mode shortcut. It starts in a 1280 × 720 window with Minimal graphics. Your worlds remain available. If a save is damaged, the previous valid backup is loaded automatically.","Muted",true)
	ui.button(list,"How to play",func(): onboarding(ui))

static func setting(ui: ValeInterface,parent: Node,title: String,choices: Array,index: int,callback: Callable,hint: String="") -> void:
	var line:=ui.row(parent)
	var label:=ui.text(line,title,"",true); label.custom_minimum_size.x=205
	var control:=ui.option(line,choices,index,callback); control.custom_minimum_size.x=185; control.tooltip_text=hint
	if not hint.is_empty(): ui.text(parent,hint,"Muted",true)

static func settings(ui: ValeInterface) -> void:
	ui.page("settings","Make yourself at home","SETTINGS")
	var tabs:=ui.row(ui.body)
	for tab in ["Gameplay","Graphics","Audio","Controls","Interface"]: ui.button(tabs,tab,func(): ui.settings_tab=tab; settings(ui))
	var list:=ui.scroll(ui.body)
	var prefs: Dictionary=Preferences.values
	match ui.settings_tab:
		"Graphics":
			setting(ui,list,"Quality preset",["Minimal","Medium","High","Ultra","Custom"],["Minimal","Medium","High","Ultra","Custom"].find(prefs.preset),func(i): Preferences.set_preset(["Minimal","Medium","High","Ultra","Custom"][i]); settings(ui),"Balances detail, shadows, particles and rendering cost.")
			setting(ui,list,"Pixelated Render",["Off","On"],int(prefs.pixelated),func(i): Preferences.set_option("pixelated",i==1),"An independent art style. Interface text stays sharp at every quality level.")
			setting(ui,list,"Pixel strength",["Subtle","Medium","Strong"],prefs.pixel_strength,func(i): Preferences.set_option("pixel_strength",i))
			var resolutions: Array=[Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]
			setting(ui,list,"Resolution",["1280 × 720","1920 × 1080","2560 × 1440","3840 × 2160"],maxi(0,resolutions.find(prefs.resolution)),func(i): Preferences.set_option("resolution",resolutions[i]))
			setting(ui,list,"Display mode",["Windowed","Borderless","Fullscreen"],["Windowed","Borderless","Fullscreen"].find(prefs.display),func(i): Preferences.set_option("display",["Windowed","Borderless","Fullscreen"][i]))
			setting(ui,list,"VSync",["Off","On"],int(prefs.vsync),func(i): Preferences.set_option("vsync",i==1))
			setting(ui,list,"FPS limit",["30","60","90","120","Unlimited"],[30,60,90,120,0].find(prefs.fps_limit),func(i): Preferences.set_option("fps_limit",[30,60,90,120,0][i]))
			ui_scale(ui,list)
			ui.text(list,"ADVANCED","Caption")
			setting(ui,list,"Shadows",["Low","Medium","High","Ultra"],prefs.shadows,func(i): Preferences.set_option("shadows",i,true); settings(ui),"Higher settings sharpen shadows from buildings, trees and characters.")
			setting(ui,list,"Foliage density",["40%","70%","90%","100%"],maxi(0,[.4,.7,.9,1.0].find(prefs.foliage)),func(i): Preferences.set_option("foliage",[.4,.7,.9,1.0][i],true); settings(ui),"Changes decorative ground cover. Nearby landmarks and resources remain.")
			setting(ui,list,"View distance",["Near","Standard","Far","Farthest"],prefs.distance,func(i): Preferences.set_option("distance",i,true); settings(ui),"Coordinates decoration range and chunk preload distance.")
			setting(ui,list,"Particle detail",["Minimal","Medium","High","Ultra"],maxi(0,[.4,.7,1.0,1.4].find(prefs.particles)),func(i): Preferences.set_option("particles",[.4,.7,1.0,1.4][i],true); settings(ui),"Scales cosmetic sparks and weather. Attack telegraphs remain visible.")
			setting(ui,list,"Render scale",["70%","85%","100%","125%"],maxi(0,[.7,.85,1.0,1.25].find(prefs.render_scale)),func(i): Preferences.set_option("render_scale",[.7,.85,1.0,1.25][i],true); settings(ui),"Trades 3D sharpness for performance; interface resolution is unchanged.")
			setting(ui,list,"Atmosphere / water",["Simple","Standard","Detailed","Rich"],prefs.water,func(i): Preferences.set_option("water",i,true); Preferences.set_option("fog",i,true); settings(ui))
			ui.text(list,"OpenGL Compatibility: distance haze is always active. Screen-space occlusion, SSR, SSIL and volumetric fog require a different renderer and are unavailable here.","Muted",true)
		"Audio":
			for bus in ["Master","Music","SFX"]:
				var line:=ui.row(list); ui.text(line,bus)
				var slider:=HSlider.new(); slider.min_value=0; slider.max_value=1; slider.step=.01; slider.value=prefs[bus]; slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL; line.add_child(slider)
				var value:=ui.text(line,"%d%%" % roundi(slider.value*100),"Muted")
				slider.value_changed.connect(func(v): Preferences.set_option(bus,v); Feel.volume(bus,v); value.text="%d%%" % roundi(v*100))
		"Interface":
			ui_scale(ui,list)
			setting(ui,list,"Damage numbers",["Off","On"],int(prefs.damage_numbers),func(i): Preferences.set_option("damage_numbers",i==1))
			ui.text(list,"Rarity uses written labels as well as color. Buttons support keyboard focus, Tab and Enter.","Muted",true)
		"Gameplay":
			setting(ui,list,"Camera shake",["Off","On"],int(prefs.screen_shake),func(i): Preferences.set_option("screen_shake",i==1))
			ui.text(list,"Progress saves after important discoveries and transactions. F6 saves at any time during play; F9 restores the current journey.","Muted",true)
		"Controls":
			setting(ui,list,"Call / dismiss mount",["V","T","Y"],["V","T","Y"].find(prefs.mount_key),func(i): Preferences.set_option("mount_key",["V","T","Y"][i]))
			ui.text(list,"P — professions, fishing journal, seeds and mounts · G — camp · O — company","",true)
			for line in ["WASD / arrows — move · Shift — run · Ctrl — dodge","Space / left click — attack · 1 / 2 — abilities","E — interact · H — tonic","I — inventory · C — appearance · B — abilities","J — journal · Tab — atlas","Q / R — orbit · Right drag — orbit & tilt · Wheel — zoom","Page Up / Down — tilt (18–60°) · Home — reset camera","F6 — save · F9 — load · Esc — menu"]: ui.text(list,line,"",true)

static func ui_scale(ui: ValeInterface,list: Node) -> void:
	setting(ui,list,"UI scale",["80%","90%","100%","110%","125%","150%"],[.8,.9,1.0,1.1,1.25,1.5].find(Preferences.values.ui_scale),func(i): Preferences.set_option("ui_scale",[.8,.9,1.0,1.1,1.25,1.5][i]))
