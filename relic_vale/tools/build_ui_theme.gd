extends SceneTree

func frame(file: String,tint: Color,margin: int=8) -> StyleBoxTexture:
	var style:=StyleBoxTexture.new()
	style.texture=load("res://assets/ui/phase5/"+file+".png")
	style.modulate_color=tint
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
		style.set_texture_margin(side,margin)
		style.set_content_margin(side,14 if side in [SIDE_LEFT,SIDE_RIGHT] else 9)
	return style
func flat(color: Color) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=color; s.set_corner_radius_all(3); return s
func _initialize() -> void:
	var t:=Theme.new()
	var body_font:=FontVariation.new(); body_font.base_font=load("res://assets/ui/phase5/Rubik.ttf"); body_font.variation_opentype={"wght":400.0}
	t.default_font=body_font
	t.default_font_size=16
	var panel:=frame("panel_blue",Color(.25,.38,.37))
	var inset:=frame("panelInset_blue",Color(.24,.37,.36))
	var normal:=frame("buttonLong_blue",Color(.43,.61,.56))
	var hover:=frame("buttonLong_blue",Color(.65,.78,.62))
	var pressed:=frame("buttonLong_blue_pressed",Color(.6,.72,.56))
	var focus:=StyleBoxFlat.new(); focus.bg_color=Color.TRANSPARENT; focus.border_color=Color("edcc87"); focus.set_border_width_all(2); focus.set_corner_radius_all(4)
	for type in ["Button","OptionButton","CheckBox","CheckButton","MenuButton"]:
		t.set_stylebox("normal",type,normal); t.set_stylebox("hover",type,hover); t.set_stylebox("pressed",type,pressed)
		t.set_stylebox("disabled",type,inset); t.set_stylebox("focus",type,focus)
		t.set_color("font_color",type,Color("f4edd8")); t.set_color("font_hover_color",type,Color.WHITE)
		t.set_color("font_disabled_color",type,Color("7f9790")); t.set_constant("h_separation",type,10)
	for type in ["Panel","PanelContainer","PopupPanel","PopupMenu","TooltipPanel"]: t.set_stylebox("panel",type,panel)
	for type in ["Label","RichTextLabel","TooltipLabel","LineEdit","PopupMenu"]:
		t.set_color("font_color",type,Color("f4edd8")); t.set_color("default_color",type,Color("f4edd8"))
	t.set_type_variation("Caption","Label")
	t.set_font("font","Caption",load("res://assets/ui/phase5/PressStart2P.ttf")); t.set_font_size("font_size","Caption",10)
	t.set_color("font_color","Caption",Color("dcc184"))
	t.set_type_variation("Heading","Label"); t.set_font_size("font_size","Heading",26)
	t.set_type_variation("Muted","Label"); t.set_color("font_color","Muted",Color("a5b8b0")); t.set_font_size("font_size","Muted",14)
	t.set_stylebox("normal","LineEdit",inset); t.set_stylebox("focus","LineEdit",focus)
	t.set_stylebox("background","ProgressBar",flat(Color("334d48"))); t.set_stylebox("fill","ProgressBar",flat(Color("b98068")))
	for type in ["HScrollBar","VScrollBar"]:
		t.set_stylebox("scroll",type,flat(Color("1b3030"))); t.set_stylebox("grabber",type,flat(Color("688b7c")))
		t.set_stylebox("grabber_highlight",type,flat(Color("bbbc8b")))
	for type in ["HSlider","VSlider"]:
		t.set_stylebox("slider",type,flat(Color("344b46"))); t.set_stylebox("grabber_area",type,flat(Color("a8b184")))
	t.set_icon("checked","CheckBox",load("res://assets/ui/phase5/iconCheck_beige.png"))
	t.set_icon("unchecked","CheckBox",load("res://assets/ui/phase5/iconCross_beige.png"))
	t.set_icon("arrow","OptionButton",load("res://assets/ui/phase5/arrowBeige_right.png"))
	for type in ["VBoxContainer","HBoxContainer","GridContainer"]: t.set_constant("separation",type,12)
	t.set_constant("h_separation","GridContainer",10); t.set_constant("v_separation","GridContainer",10)
	ResourceSaver.save(t,"res://assets/ui/phase5/vale_theme.tres")
	var body: Font=load("res://assets/ui/phase5/Rubik.ttf"); var display: Font=load("res://assets/ui/phase5/PressStart2P.ttf")
	for font in [body,display]:
		for ch in "АБВГДЕёжийПриветЯяHello0123456789!?":
			if not font.has_char(ch.unicode_at(0)): push_error("Missing font character: "+ch)
	print("THEME_SAVED; Latin/Cyrillic/numerals verified")
	quit()
