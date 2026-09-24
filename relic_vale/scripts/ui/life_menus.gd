class_name ValeLifeMenus
extends RefCounted

static func prepare(hud: ValeHUD, kind: String, title: String, caption: String) -> void:
	hud.open_modal(kind,title,caption)
	hud.modal_panel.position=Vector2(230,90)
	hud.modal_panel.size=Vector2(820,540)
	hud.modal_button.position=Vector2(620,486)
	hud.modal_text.visible=false

static func column(hud: ValeHUD, pos: Vector2, size: Vector2) -> VBoxContainer:
	var scroll:=ScrollContainer.new()
	scroll.position=pos
	scroll.size=size
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	hud.rpg.add_child(scroll)
	var box:=VBoxContainer.new()
	box.custom_minimum_size.x=size.x-18
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",12)
	scroll.add_child(box)
	return box

static func label(hud: ValeHUD, box: VBoxContainer, value: String, size: int=14, color: Color=Color("efe7ce")) -> Label:
	var node:=Label.new()
	node.text=value
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	box.add_child(node)
	return node

static func button(hud: ValeHUD, box: VBoxContainer, value: String, callback: Callable, disabled: bool=false) -> Button:
	var node:=Button.new()
	node.text=value
	node.custom_minimum_size=Vector2(0,34)
	node.disabled=disabled
	hud.style_button(node)
	node.pressed.connect(callback)
	box.add_child(node)
	return node

static func open_shop(hud: ValeHUD, npc: String) -> void:
	hud.ui.shop_page(npc)

static func open_crafting(hud: ValeHUD, station: ValeInteractable) -> void:
	hud.ui.crafting_page(station)

static func open_journal(hud: ValeHUD) -> void:
	hud.ui.journal_page()

