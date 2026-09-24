class_name ValeHUD
extends Control

const INK := Color("142c30")
const PAPER := Color("efe7ce")
const GOLD := Color("d7b575")
const MUTED := Color("a4b8af")
var ui: ValeInterface
var player: ValePlayer
var rig: ValeCamera
var title_label: Label
var health_label: Label
var xp_label: Label
var level_label: Label
var coins_label: Label
var objective_label: Label
var region_label: Label
var region_subtitle: Label
var prompt_label: Label
var toast_label: Label
var toast_timer: float = 0
var modal_panel: Control
var modal_title: Label
var modal_text: Label
var modal_caption: Label
var inventory_rows: VBoxContainer
var modal_button: Button
var modal_kind: String = ""
var modal_shade: ColorRect
var pause_buttons: Array[Button] = []
var current_prompt: String = ""
var world: ValeWorld
var sharp_pixels: bool = true
var atlas_portrait: TextureRect
var minimap_clock: float = 0
var rpg: ValeMenus
var ability_buttons: Array[Button]=[]
var ability_labels: Array[Label]=[]

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	theme=load("res://assets/ui/phase5/vale_theme.tres")
	rpg=ValeMenus.new(); rpg.hud=self; rpg.visible=false; add_child(rpg)
	ui=ValeInterface.new(); ui.hud=self; add_child(ui)
	State.changed.connect(refresh)
	State.appearance_changed.connect(refresh)
	State.notification.connect(show_toast)
	State.conversation.connect(show_dialogue)
	State.shrine_requested.connect(show_shrine)
	refresh()

func label(text: String, pos: Vector2, size: Vector2, font_size: int, color: Color, parent: Node = self) -> Label:
	var node:=Label.new()
	node.text=text
	node.position=pos
	node.size=size
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	node.add_theme_color_override("font_shadow_color",Color(0.03,.08,.09,.65))
	node.add_theme_constant_override("shadow_offset_y",1)
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func style(bg: Color = Color("182f32"), border: Color = Color("5c6c5d")) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=bg
	s.border_color=border
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left=14
	s.content_margin_right=14
	s.shadow_color=Color(0,.02,.03,.2)
	s.shadow_size=6
	return s

func panel(rect: Rect2) -> Panel:
	var p:=Panel.new()
	p.position=rect.position
	p.size=rect.size
	p.add_theme_stylebox_override("panel",style(Color(.07,.15,.16,.94)))
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(p)
	return p

func style_button(button: Button) -> void:
	button.pressed.connect(func(): Feel.sound("click",.23))
	button.mouse_entered.connect(func(): Feel.sound("click",.06,1.3))
	button.focus_mode=Control.FOCUS_ALL

func build_modal() -> void:
	modal_shade=ColorRect.new()
	modal_shade.color=Color(.025,.06,.07,.7)
	modal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal_shade)
	modal_panel=panel(Rect2(330,178,620,364))
	modal_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	modal_title=label("",Vector2(30,30),Vector2(560,44),27,PAPER,modal_panel)
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Georgia","Times New Roman"])
	modal_title.add_theme_font_override("font",font)
	modal_caption=label("",Vector2(30,10),Vector2(560,18),10,GOLD,modal_panel)
	modal_text=label("",Vector2(30,89),Vector2(560,208),17,PAPER,modal_panel)
	modal_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	inventory_rows=VBoxContainer.new()
	inventory_rows.position=Vector2(30,85)
	inventory_rows.size=Vector2(560,235)
	inventory_rows.add_theme_constant_override("separation",10)
	modal_panel.add_child(inventory_rows)
	modal_button=Button.new()
	modal_button.position=Vector2(420,308)
	modal_button.size=Vector2(170,36)
	style_button(modal_button)
	modal_panel.add_child(modal_button)
	modal_button.pressed.connect(close_modal)
	modal_panel.visible=false
	modal_shade.visible=false

func refresh() -> void:
	if not is_instance_valid(level_label): return
	title_label.text=State.character_name
	level_label.text="Level %02d · %s" % [State.level,State.weapon_profile().get("archetype","Wanderer")]
	health_label.text="%d / %d HP" % [State.hp,State.max_hp]
	xp_label.text="%d / %d XP" % [State.xp,State.level*60]
	coins_label.text="%d copper\n%d shards" % [State.coins,State.astral_shards]
	objective_label.text=State.objective()
	region_label.text=State.region

func show_toast(message: String) -> void:
	toast_label.text=message
	toast_timer=4.5
	toast_label.modulate.a=1

func set_prompt(text: String) -> void:
	current_prompt=text
	prompt_label.text="[ E ]   "+text if not text.is_empty() and not State.modal else ""

func open_modal(kind: String,title: String,caption: String) -> void:
	ui.page(kind,title,caption)

func show_dialogue(speaker: String,message: String) -> void:
	ui.dialogue(speaker,message)

func show_inventory() -> void:
	ui.inventory_page()

func populate_inventory() -> void:
	ui.inventory_page()

func show_character() -> void:
	ui.character_page()

func show_pause() -> void:
	ui.pause_page()

func show_new_world() -> void:
	ValeMenuPages.new_world(ui)

func show_quests() -> void:
	ui.journal_page()

func show_abilities() -> void:
	ui.abilities_page()

func show_shrine() -> void:
	ui.shrine_page()

func show_map() -> void:
	ui.map_page()

func close_modal() -> void:
	if modal_kind=="loading": return
	if not get_tree().current_scene.gameplay_started:
		ui.main_menu()
		return
	if modal_kind=="character": State.appearance_confirmed=true
	ui.clear_body()
	State.modal=false; State.paused=false; modal_kind=""
	modal_panel.visible=false; modal_shade.visible=false; ui.chrome.visible=true
	set_prompt(current_prompt)

func action_pressed(index: int) -> void:
	if State.modal: return
	match index:
		0: player.attack()
		1: player.abilities.use(0)
		2: player.abilities.use(1)
		3: get_tree().current_scene.try_interact()
		4: show_inventory()
		5: State.drink_tonic()

func _process(delta: float) -> void:
	if is_instance_valid(ui): ui.tick(delta)

func map_point(p: Vector3) -> Vector2:
	return Vector2(1090+(p.x+96)/224.0*156,85+(p.z+96)/224.0*91)

func draw_stats(canvas: Control) -> void:
	# These bars and markers sit under the native text and controls.
	canvas.draw_style_box(style(Color("224345"),Color("536962")),Rect2(36,42,53,67))
	canvas.draw_rect(Rect2(95,91,174,15),Color("37463e"))
	canvas.draw_rect(Rect2(96,92,172*float(State.hp)/State.max_hp,13),Color("b37a63"))
	canvas.draw_rect(Rect2(95,111,174,3),Color("37463e"))
	canvas.draw_rect(Rect2(95,111,174*float(State.xp)/(State.level*60),3),GOLD)
	canvas.draw_line(Vector2(579,95),Vector2(701,95),Color(.8,.74,.57,.6),1)
	canvas.draw_circle(Vector2(640,95),2,GOLD)
	# Minimap is redrawn above the small panel by a dedicated child canvas.

func draw_map(canvas: Control) -> void:
	canvas.draw_rect(Rect2(1090,85,156,91),Color("28443e"))
	if not is_instance_valid(world): return
	if "Crypt" in State.region:
		for i in range(3): canvas.draw_rect(Rect2(1145,91+i*27,45,24),Color("687e83"),false,2)
		if is_instance_valid(player):
			canvas.draw_circle(Vector2(1145+(player.position.x-992)/16*45,91+(player.position.z+49)/59*78),3,PAPER)
		return
	if is_instance_valid(world.generator):
		var colors: Dictionary={"Briar Meadow":Color("6b8359"),"Elderwood":Color("3e634c"),"Fallen March":Color("71796a")}
		for data in world.generator.layout.values():
			canvas.draw_rect(Rect2(map_point(Vector3(data.coord.x*32,0,data.coord.y*32)),Vector2(156.0/7,91.0/7)),colors[data.biome])
		for road in world.generator.roads:
			for i in range(road.size()-1): canvas.draw_line(map_point(Vector3(road[i].x,0,road[i].y)),map_point(Vector3(road[i+1].x,0,road[i+1].y)),GOLD,1,true)
		for poi in world.generator.pois: canvas.draw_circle(map_point(Vector3(poi.position.x,0,poi.position.y)),1.8,MUTED)
	for i in range(world.path_points.size()-1):
		var a: Vector2=world.path_points[i]
		var b: Vector2=world.path_points[i+1]
		canvas.draw_line(map_point(Vector3(a.x,0,a.y)),map_point(Vector3(b.x,0,b.y)),GOLD,2,true)
	for p in [Vector3(-8,0,-5),Vector3(7,0,-7.5),Vector3(-14,0,3),Vector3(10,0,7.5),Vector3(.2,0,-10.5)]:
		canvas.draw_rect(Rect2(map_point(p)-Vector2(3,2),Vector2(6,5)),Color("b28c73"))
	canvas.draw_circle(map_point(Vector3(-2.5,0,1)),2.5,GOLD)
	canvas.draw_circle(map_point(Vector3(38,0,-22)),3,Color("9fcbd0"))
	if is_instance_valid(player):
		var p: Vector2=map_point(player.global_position)
		canvas.draw_circle(p,3,PAPER)
		var forward:=Vector2(sin(rig.yaw),cos(rig.yaw))*7
		canvas.draw_line(p,p+forward,Color("bddfd1"),1.5,true)
