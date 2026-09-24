class_name ValeInterface
extends Control
var hud: ValeHUD
var game: Node
var body: VBoxContainer
var footer: HBoxContainer
var page_root: VBoxContainer
var chrome: Control
var health: ProgressBar
var xp: ProgressBar
var selected: String="rustic_sword"
var category: String="All"
var sort_mode: int=0
var quest_filter: String="Active"
var settings_tab: String="Graphics"
var shop_tab: String="Buy"
var busy: bool=false
var menu_clock: float=0
var company: Button

func _ready() -> void:
	game=get_tree().current_scene
	theme=load("res://assets/ui/phase5/vale_theme.tres")
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	build_hud()
	build_window()
	Preferences.changed.connect(rescale)
	get_parent().resized.connect(rescale)
	rescale()

func text(parent: Node,value: String,variant: String="",wrap: bool=false) -> Label:
	var node:=Label.new(); node.text=value; node.theme_type_variation=variant
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if wrap:
		node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(node)
	return node
func vbox(parent: Node,expand: bool=false) -> VBoxContainer:
	var box:=VBoxContainer.new(); parent.add_child(box)
	if expand: box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; box.size_flags_vertical=Control.SIZE_EXPAND_FILL
	return box
func row(parent: Node) -> HBoxContainer:
	var box:=HBoxContainer.new(); box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; parent.add_child(box); return box
func scroll(parent: Node) -> VBoxContainer:
	var scroller:=ScrollContainer.new(); scroller.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroller.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroller)
	return vbox(scroller,true)
func button(parent: Node,value: String,callback: Callable,disabled: bool=false) -> Button:
	var node:=Button.new(); node.text=value; node.custom_minimum_size.y=38; node.disabled=disabled
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL; parent.add_child(node)
	hud.style_button(node); node.pressed.connect(callback)
	return node
func option(parent: Node,choices: Array,current: int,callback: Callable) -> OptionButton:
	var node:=OptionButton.new(); node.custom_minimum_size.y=38; node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for choice in choices: node.add_item(str(choice))
	node.select(current); parent.add_child(node); hud.style_button(node); node.item_selected.connect(callback)
	return node
func picture(parent: Node,texture: Texture2D,extent: Vector2=Vector2(64,64)) -> TextureRect:
	var node:=TextureRect.new(); node.texture=texture; node.custom_minimum_size=extent
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(node); return node
func icon(id: String) -> Texture2D:
	var newer: String="res://assets/ui/phase8/icons/"+id.replace("seed_","crop_")+".png"
	if ResourceLoader.exists(newer): return load(newer)
	if id=="iron_ingot": id="iron_ore"
	if id=="charcoal": id="stone"
	var thumbnail: String="res://assets/ui/phase5/rendered/"+id+".png"
	if ResourceLoader.exists(thumbnail): return load(thumbnail)
	var item: Dictionary=State.items.get(id,State.ability_data.get(id,{}))
	var names: Dictionary={"sword":"sword","greatsword":"swordblood","daggers":"sword","bow":"crossbow","staff":"book","helm":"helmet","armor":"armor","potion":"potionred","gem":"ringmagic","ring":"ringmagic","coin":"goldcoins","leaf":"bag","bone":"book","shield":"shield","fire":"fireball","frost":"frostball","bolt":"aurared","heart":"bookholy"}
	var name: String=names.get(item.get("weapon_type",item.get("icon","")),"bag")
	if id in ["whirlwind","dash_strike"]: name="swordblood"
	if item.get("icon","")=="bottle": name="potionred"
	if item.get("icon","")=="hood": name="helmet"
	if id=="fireball": name="fireball"
	if id=="frost_nova": name="frostball"
	if id=="arcane_missiles": name="aurared"
	if id=="heal": name="bookholy"
	return load("res://assets/ui/phase5/icons/"+name+".png")

func build_hud() -> void:
	chrome=Control.new(); chrome.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(chrome)
	var top:=row(chrome); top.name="Top"
	var notes:=PanelContainer.new(); notes.custom_minimum_size.x=245; top.add_child(notes)
	var journal:=vbox(notes); text(journal,"FIELD NOTES","Caption")
	hud.objective_label=text(journal,"","",true); hud.objective_label.custom_minimum_size.x=210
	company=button(journal,"Company [O]",func():
		if is_instance_valid(game.party.active()): ValeNarrativeUI.commands(self)
		else: ValeNarrativeUI.roster(self))
	company.add_theme_font_size_override("font_size",12)
	var center:=vbox(top,true)
	hud.region_label=text(center,"Willowmere","Heading"); hud.region_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hud.region_subtitle=text(center,"","Muted"); hud.region_subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hud.toast_label=text(center,"","",true); hud.toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var links:=vbox(top); links.custom_minimum_size.x=138
	button(links,"Atlas  [Tab]",map_page)
	button(links,"Journal  [J]",journal_page)
	button(links,"Menu  [Esc]",pause_page)
	var bottom:=row(chrome); bottom.name="Bottom"; bottom.alignment=BoxContainer.ALIGNMENT_CENTER
	var backdrop:=Panel.new(); backdrop.name="BottomBackdrop"; backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	chrome.add_child(backdrop); chrome.move_child(backdrop,0)
	var stats:=vbox(bottom); stats.custom_minimum_size.x=205
	hud.title_label=text(stats,State.character_name,"Caption")
	hud.level_label=text(stats,"","Muted")
	health=ProgressBar.new(); health.custom_minimum_size.y=18; health.show_percentage=false; stats.add_child(health)
	hud.health_label=text(stats,"","Muted")
	xp=ProgressBar.new(); xp.custom_minimum_size.y=4; xp.show_percentage=false; stats.add_child(xp)
	hud.xp_label=Label.new(); hud.xp_label.visible=false; add_child(hud.xp_label)
	var hotbar:=row(bottom); hotbar.alignment=BoxContainer.ALIGNMENT_CENTER; hotbar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for i in 6:
		var slot:=vbox(hotbar)
		var action:=button(slot,["Space","1","2","E","I","H"][i],func(): hud.action_pressed(i))
		action.custom_minimum_size=Vector2(64,66)
		if i in [1,2]:
			action.text=""
			var art:=picture(action,icon(State.abilities[i-1]),Vector2(32,32)); art.name="Icon"; art.position=Vector2(16,5); art.size=Vector2(32,32)
			var key:=text(action,str(i)); key.name="Key"; key.position=Vector2(0,39); key.size=Vector2(64,22); key.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; key.add_theme_font_size_override("font_size",12)
			hud.ability_buttons.append(action)
		var caption:=text(slot,["Strike","Ability","Ability","Use","Pack","Tonic"][i],"Muted")
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; caption.add_theme_font_size_override("font_size",11)
		if i in [1,2]: hud.ability_labels.append(caption)
	var purse:=vbox(bottom); purse.custom_minimum_size.x=130
	hud.coins_label=text(purse,"","Muted")
	button(purse,"Professions [P]",func(): ValeProfessionPages.show(self))
	hud.prompt_label=text(chrome,"","Heading"); hud.prompt_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hud.atlas_portrait=TextureRect.new(); hud.atlas_portrait.visible=false; add_child(hud.atlas_portrait)

func build_window() -> void:
	hud.modal_shade=ColorRect.new(); hud.modal_shade.color=Color(0.015,.035,.04,.64); hud.modal_shade.visible=false; add_child(hud.modal_shade)
	hud.modal_panel=PanelContainer.new(); hud.modal_panel.visible=false; add_child(hud.modal_panel)
	page_root=vbox(hud.modal_panel,true)
	hud.modal_caption=text(page_root,"","Caption")
	hud.modal_title=text(page_root,"","Heading")
	body=vbox(page_root,true)
	footer=row(page_root)
	hud.modal_button=button(footer,"Close  [Esc]",hud.close_modal)
	hud.modal_text=Label.new(); hud.modal_text.visible=false; add_child(hud.modal_text)

func rescale() -> void:
	var amount: float=float(Preferences.values.ui_scale)
	scale=Vector2.ONE*amount
	size=get_parent().size/amount
	chrome.size=size
	var top: Control=chrome.get_node("Top"); top.position=Vector2(22,22); top.size=Vector2(size.x-44,135)
	var bottom: Control=chrome.get_node("Bottom"); bottom.position=Vector2(22,size.y-130); bottom.size=Vector2(size.x-44,108)
	var backdrop: Control=chrome.get_node("BottomBackdrop"); backdrop.position=Vector2(10,size.y-142); backdrop.size=Vector2(size.x-20,132)
	hud.prompt_label.position=Vector2(0,size.y-181); hud.prompt_label.size=Vector2(size.x,40)
	hud.modal_shade.size=size
	hud.modal_panel.position=Vector2(30,30); hud.modal_panel.size=size-Vector2(60,60)
	if hud.modal_kind=="dialogue": hud.modal_panel.position=Vector2(40,size.y*.58); hud.modal_panel.size=Vector2(size.x-80,size.y*.38)
	if hud.modal_kind in ["main_menu","pause"]:
		hud.modal_panel.position=Vector2(36,36); hud.modal_panel.size=Vector2(minf(470,size.x-72),size.y-72)

func clear_body() -> void:
	for child in body.get_children(): body.remove_child(child); child.queue_free()
	for child in footer.get_children():
		if child!=hud.modal_button: footer.remove_child(child); child.queue_free()

func page(kind: String,title: String,caption: String="") -> VBoxContainer:
	clear_body()
	hud.modal_shade.color=Color(.015,.035,.04,.64)
	hud.modal_kind=kind; State.modal=true; State.paused=false
	hud.modal_title.text=title; hud.modal_caption.text=caption
	hud.modal_panel.visible=true; hud.modal_shade.visible=true
	hud.modal_button.text="Continue  [E]" if kind=="dialogue" else "Close  [Esc]"
	hud.modal_button.visible=true
	chrome.visible=kind not in ["main_menu","loading","new_world","saves","credits"]
	rescale(); Feel.sound("click",.18,.8)
	return body

func tick(delta: float) -> void:
	if is_instance_valid(game.party):
		var companion: ValeCompanionActor=game.party.active()
		company.text=("%s · %d/%d HP\n%s · %s [Z]" % [ValeNarrative.companions[companion.id].name,companion.hp,companion.max_hp,"Downed" if companion.downed else State.narrative.command.capitalize(),State.narrative.stance.capitalize()]) if is_instance_valid(companion) else "Company [O]"
	health.max_value=State.max_hp; health.value=State.hp
	xp.max_value=State.level*60; xp.value=State.xp
	hud.toast_timer=maxf(0,hud.toast_timer-delta); hud.toast_label.modulate.a=minf(1,hud.toast_timer)
	for i in 2:
		var id: String=State.abilities[i]; var remaining: float=hud.player.abilities.cooldowns.get(id,0)
		hud.ability_buttons[i].get_node("Key").text=str(i+1)+(" · %.1f" % remaining if remaining>0 else "")
		hud.ability_buttons[i].get_node("Icon").texture=icon(id)
		hud.ability_buttons[i].tooltip_text=State.ability_data[id].name+" — "+State.ability_data[id].description
		hud.ability_labels[i].text="Ready" if remaining<=0 else "Cooling down"
	if hud.modal_kind=="main_menu":
		menu_clock+=delta
		hud.rig.target_yaw=deg_to_rad(42)+sin(menu_clock*.04)*.12

func inventory_page() -> void: ValeInventoryPage.show(self)
func character_page() -> void: ValeJourneyPages.character(self)
func journal_page() -> void: ValeJourneyPages.journal(self)
func abilities_page() -> void: ValeJourneyPages.abilities(self)
func shrine_page(result: String="") -> void: ValeJourneyPages.shrine(self,result)
func shop_page(npc: String) -> void: ValeEconomyPages.shop(self,npc)
func crafting_page(station: ValeInteractable) -> void: ValeEconomyPages.crafting(self,station)
func pause_page() -> void: ValeMenuPages.pause_menu(self)
func main_menu() -> void: ValeMenuPages.main_menu(self)
func settings_page() -> void: ValeMenuPages.settings(self)
func map_page() -> void:
	page("map","The atlas","KNOWN ROADS / UNWRITTEN LANDS")
	var atlas:=ValeAtlas.new(); atlas.hud=hud; atlas.size_flags_vertical=Control.SIZE_EXPAND_FILL; atlas.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_child(atlas)
	var filters:=HFlowContainer.new(); filters.size_flags_horizontal=Control.SIZE_EXPAND_FILL; body.add_child(filters)
	for label in atlas.filters:
		var check:=CheckBox.new(); check.text=label; check.button_pressed=true; filters.add_child(check)
		check.toggled.connect(func(value): atlas.filters[label]=value; atlas.queue_redraw())
	button(footer,"Center player",atlas.center_player)
	button(footer,"Camp [G]",func(): ValeCampUI.show(self))
	text(body,"Drag: pan · Wheel: zoom · Right click explored ground: marker · Click icon: details / travel.","Muted",true)
func dialogue(speaker: String,message: String) -> void:
	page("dialogue",speaker,"TALES OF THE VALE")
	text(scroll(body),message,"",true)
func add_trade(npc: String) -> void: button(footer,"Trade",func(): shop_page(npc))
