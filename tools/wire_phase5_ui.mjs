import fs from 'node:fs';
const base='relic_vale/';
function edit(path,fn){fs.writeFileSync(base+path,fn(fs.readFileSync(base+path,'utf8')));}
function method(source,name,body){const re=new RegExp(`^func ${name}\\([^]*?(?=^func |$(?![^]))`,'m'); if(!re.test(source))throw Error(name); return source.replace(re,body+'\n\n');}
edit('scripts/hud.gd',s=>{
 s=s.replace('var modal_panel: Panel','var modal_panel: Control');
 s=s.replace('var player: ValePlayer','var ui: ValeInterface\nvar player: ValePlayer');
 s=method(s,'_ready',`func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	theme=load("res://assets/ui/phase5/vale_theme.tres")
	rpg=ValeMenus.new(); rpg.hud=self; rpg.visible=false; add_child(rpg)
	ui=ValeInterface.new(); ui.hud=self; add_child(ui)
	State.changed.connect(refresh)
	State.appearance_changed.connect(refresh)
	State.notification.connect(show_toast)
	State.conversation.connect(show_dialogue)
	State.shrine_requested.connect(show_shrine)
	refresh()`);
 s=method(s,'style_button',`func style_button(button: Button) -> void:
	button.pressed.connect(func(): Feel.sound("click",.23))
	button.mouse_entered.connect(func(): Feel.sound("click",.06,1.3))
	button.focus_mode=Control.FOCUS_ALL`);
 s=method(s,'refresh',`func refresh() -> void:
	if not is_instance_valid(level_label): return
	title_label.text=State.character_name
	level_label.text="Level %02d · %s" % [State.level,State.weapon_profile().get("archetype","Wanderer")]
	health_label.text="%d / %d HP" % [State.hp,State.max_hp]
	xp_label.text="%d / %d XP" % [State.xp,State.level*60]
	coins_label.text="%d copper\n%d shards" % [State.coins,State.astral_shards]
	objective_label.text=State.objective()
	region_label.text=State.region` .replace('copper\n','copper\\n'));
 for(const [name,body] of Object.entries({
 open_modal:'func open_modal(kind: String,title: String,caption: String) -> void:\n\tui.page(kind,title,caption)',
 show_dialogue:'func show_dialogue(speaker: String,message: String) -> void:\n\tui.dialogue(speaker,message)',
 show_inventory:'func show_inventory() -> void:\n\tui.inventory_page()',
 populate_inventory:'func populate_inventory() -> void:\n\tui.inventory_page()',
 show_character:'func show_character() -> void:\n\tui.character_page()',
 show_pause:'func show_pause() -> void:\n\tui.pause_page()',
 show_new_world:'func show_new_world() -> void:\n\tValeMenuPages.new_world(ui)',
 show_quests:'func show_quests() -> void:\n\tui.journal_page()',
 show_abilities:'func show_abilities() -> void:\n\tui.abilities_page()',
 show_shrine:'func show_shrine() -> void:\n\tui.shrine_page()',
 show_map:'func show_map() -> void:\n\tui.map_page()',
 _process:'func _process(delta: float) -> void:\n\tif is_instance_valid(ui): ui.tick(delta)',
 close_modal:`func close_modal() -> void:
	if modal_kind=="loading": return
	if not get_tree().current_scene.gameplay_started:
		ui.main_menu()
		return
	if modal_kind=="character": State.appearance_confirmed=true
	ui.clear_body()
	State.modal=false; State.paused=false; modal_kind=""
	modal_panel.visible=false; modal_shade.visible=false; ui.chrome.visible=true
	set_prompt(current_prompt)`
 }))s=method(s,name,body);
 return s;
});
edit('scripts/ui/life_menus.gd',s=>{for(const [name,args,call]of[['open_shop','npc: String','shop_page(npc)'],['open_crafting','station: ValeInteractable','crafting_page(station)'],['open_journal','','journal_page()']]){
 const re=new RegExp(`^static func ${name}\\([^]*?(?=^static func |$(?![^]))`,'m');
 s=s.replace(re,`static func ${name}(hud: ValeHUD${args?', '+args:''}) -> void:\n\thud.ui.${call}\n\n`);
 }return s;});
edit('scripts/ui/rpg_menus.gd',s=>method(s,'add_trade_button','func add_trade_button(npc_id: String) -> void:\n\thud.ui.add_trade(npc_id)'));
edit('project.godot',s=>s.replace('Feel="*res://scripts/combat/feedback.gd"','Feel="*res://scripts/combat/feedback.gd"\nPreferences="*res://scripts/ui/preferences.gd"'));
edit('scripts/main.gd',s=>{
 s=s.replace('var viewport: SubViewport','var active_save_path: String=ValeSave.PATH\nvar gameplay_started: bool=false\nvar graphics: Node\nvar viewport: SubViewport');
 s=s.replace(/\tif not test_mode:\r?\n\t\tvar saved:[^]*?(?=\tif "--phase4-startup")/,'\tgameplay_started=test_mode\n');
 s=s.replace(/\tvar minimap:=Control.new\(\)[^]*?(?=\tdebug_panel=)/,'');
 s=s.replace('\tif not test_mode and not State.appearance_confirmed: hud.show_character.call_deferred()','\tif not test_mode:\n\t\tlife.set_time(18)\n\t\thud.ui.main_menu.call_deferred()');
 s=s.replace(',"pixels":[KEY_P]','');
 s=s.replace(/\tif event.is_action_pressed\("pixels"\):[^]*?(?=\t# A TextureRect)/,'');
 s=s.replace('func save_game(show_message: bool = true, path: String = ValeSave.PATH) -> bool:\n','func save_game(show_message: bool = true, path: String = "") -> bool:\n\tif not gameplay_started: return false\n\tif path.is_empty(): path=active_save_path\n');
 s=s.replace('func load_game(path: String = ValeSave.PATH) -> bool:\n','func load_game(path: String = "") -> bool:\n\tif path.is_empty(): path=active_save_path\n');
 s=s.replace('\tvar position:=ValeSave.apply(data)\n\thud.close_modal()','\tvar position:=ValeSave.apply(data)\n\tactive_save_path=path; gameplay_started=true\n\thud.modal_kind=""\n\thud.close_modal()');
 s=s.replace('func new_world(seed_value: int) -> void:\n\thud.close_modal()','func new_world(seed_value: int,world_name: String="The Lower Vale") -> void:\n\tgameplay_started=true\n\thud.modal_kind=""\n\thud.close_modal()');
 s=s.replace('\tState.reset_progress(seed_value)','\tState.reset_progress(seed_value)\n\tState.world_data.name=world_name if not world_name.is_empty() else "The Lower Vale"');
 s=s.replace('if not test_mode and not save_game(false):','if not test_mode and gameplay_started and not save_game(false):');
 return s;
});
edit('scripts/ui/interface.gd',s=>s.replace('\tclear_body()\n\thud.modal_kind','\tclear_body()\n\thud.modal_shade.color=Color(.015,.035,.04,.64)\n\thud.modal_kind'));
edit('scripts/ui/inventory_page.gd',s=>s.replace('\tui.page("inventory"','\tif not ui.category in ["All","Weapons","Armor","Consumables","Materials","Relics","Quest"]: ui.category="All"\n\tui.page("inventory"'));
edit('scripts/ui/menu_pages.gd',s=>s.replace('Q / R / right drag — orbit · Wheel — zoom · Home — reset camera','Q / R — orbit · Right drag — orbit & tilt · Wheel — zoom').replace('"F6 — save','"Page Up / Down — tilt (40–60°) · Home — reset camera","F6 — save'));
