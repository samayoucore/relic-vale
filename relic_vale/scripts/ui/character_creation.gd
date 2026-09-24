class_name ValeCreation
extends Control
var hud: ValeHUD
var look: Dictionary
var name_field: LineEdit
var preview: TextureRect
var choices: Dictionary={}
var cape: CheckBox
var frames: SpriteFrames
var elapsed: float=0

func _ready() -> void:
	look=State.appearance.duplicate(true)
	hud.rpg.text("A traveler, made your own",Vector2(30,88),Vector2(700,32),19,hud.GOLD)
	preview=hud.rpg.icon(null,Vector2(40,140),Vector2(240,240),self)
	hud.rpg.text("Your colors follow every step,\nswing and turn of the road.",Vector2(40,397),Vector2(255,50),14,hud.MUTED)
	name_field=LineEdit.new()
	name_field.position=Vector2(330,126)
	name_field.size=Vector2(415,40)
	name_field.max_length=20
	name_field.text=State.character_name
	name_field.placeholder_text="Traveler name"
	add_child(name_field)
	var labels: Dictionary={"skin":["Warm sand","Copper","Umber","Porcelain","Deep walnut"],"hair":["Chestnut","Flax","Raven","Auburn","Silver"],"outfit":["River teal","Sage","Rosewood","Heather","Wheat"]}
	var index: int=0
	for key in labels:
		var y: float=193+index*57
		hud.rpg.text(key.capitalize(),Vector2(330,y+5),Vector2(120,30),15)
		var choice:=OptionButton.new()
		choice.position=Vector2(455,y)
		choice.size=Vector2(290,37)
		hud.style_button(choice)
		for entry in labels[key]: choice.add_item(entry)
		choice.select(look[key])
		add_child(choice)
		choice.item_selected.connect(func(value: int): look[key]=value; refresh())
		choices[key]=choice
		index+=1
	cape=CheckBox.new()
	cape.text="Traveling cloak"
	cape.position=Vector2(330,370)
	cape.button_pressed=look.cape
	add_child(cape)
	cape.toggled.connect(func(value: bool): look.cape=value; refresh())
	hud.rpg.button("Randomize colors",Vector2(330,428),Vector2(195,37),randomize_look)
	hud.rpg.button("Confirm traveler",Vector2(545,428),Vector2(200,37),confirm)
	refresh()

func refresh() -> void:
	for key in choices: choices[key].select(look[key])
	cape.set_pressed_no_signal(look.cape)
	frames=PixelArt.character_frames(false,look)
	preview.texture=frames.get_frame_texture("walk_2",0)

func randomize_look() -> void:
	for key in choices:
		look[key]=randi_range(0,4)
		choices[key].select(look[key])
	look.cape=randf()>.3
	cape.set_pressed_no_signal(look.cape)
	refresh()

func confirm() -> void:
	var first_steps: bool=not State.appearance_confirmed
	State.character_name=name_field.text.strip_edges()
	if State.character_name.is_empty(): State.character_name="Traveler"
	State.appearance=look.duplicate(true)
	State.appearance_confirmed=true
	State.appearance_changed.emit()
	State.changed.emit()
	hud.close_modal()
	State.save_requested.emit()
	hud.show_toast("Welcome, %s. Rowan waits by the well.  I · weapons   B · abilities" % State.character_name)
	if first_steps: ValeMenuPages.onboarding(hud.ui)

func _process(delta: float) -> void:
	elapsed+=delta
	if frames: preview.texture=frames.get_frame_texture("walk_%d" % ([2,1,0,3][int(elapsed/3)%4]),int(elapsed*8)%9)
