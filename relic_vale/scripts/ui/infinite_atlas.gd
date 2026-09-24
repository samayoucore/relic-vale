class_name ValeLegacyAtlas
extends Control
var hud: ValeHUD
var center_x: int
var center_z: int
var pan:=Vector2.ZERO
var zoom: float=35
var dragging: bool=false

func _ready() -> void:
	clip_contents=true
	custom_minimum_size=Vector2(200,180)
	var address: Dictionary=hud.world.generator.address(hud.player.position if hud.player.position.x<900 else State.dungeon_return)
	if State.interior_data.has("active"): address=State.interior_data.active.return
	center_x=int(address.x); center_z=int(address.z)
	resized.connect(queue_redraw)

func point(x: int,z: int,offset: Vector2=Vector2.ZERO) -> Vector2:
	return size*.5+pan+(Vector2(x-center_x,z-center_z)+offset/32)*zoom

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT: dragging=event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var old: float=zoom
			zoom=clampf(zoom*(1.2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.2),3,160)
			pan=event.position-size*.5-(event.position-size*.5-pan)*zoom/old
		accept_event(); queue_redraw()
	if event is InputEventMouseMotion and dragging:
		pan+=event.relative; accept_event(); queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("142d31"))
	var generator: ValeStreamingGenerator=hud.world.generator
	var colors: Dictionary={"Briar Meadow":Color("647957"),"Elderwood":Color("395b4a"),"Fallen March":Color("6e766b")}
	for key in generator.discovered:
		var coords: PackedStringArray=key.split(",")
		var x: int=int(coords[0]); var z: int=int(coords[1])
		# Subtract integer coordinates before converting into drawing floats.
		if absi(x-center_x)>100000 or absi(z-center_z)>100000: continue
		var at: Vector2=point(x,z)
		if not Rect2(-Vector2.ONE*zoom,size+Vector2.ONE*zoom*2).has_point(at): continue
		var data: Dictionary=generator.discovered[key]
		draw_rect(Rect2(at,Vector2.ONE*zoom),colors.get(data.get("biome",""),Color("4c6555")))
		for road in data.get("roads",[]):
			draw_line(point(x,z,Vector2(road[0],road[1])),point(x,z,Vector2(road[2],road[3])),Color("c6b185"),maxf(1,zoom*.045),true)
		for water in data.get("water",[]): draw_circle(point(x,z,Vector2(water[0],water[1])),maxf(1,zoom*.065),Color("7eafb3"))
		if not data.get("poi","").is_empty():
			var p: Vector2=at+Vector2.ONE*zoom*.5
			draw_circle(p,3,Color("e9c889"))
			if zoom>28: draw_string(hud.theme.default_font,p+Vector2(6,-4),data.get("title","Landmark"),HORIZONTAL_ALIGNMENT_LEFT,180,12,Color("f7edce"))
	var pos: Dictionary=generator.address(hud.player.position if hud.player.position.x<900 else State.dungeon_return)
	var marker: Vector2=point(int(pos.x),int(pos.z),Vector2(pos.local[0],pos.local[2]))
	draw_circle(marker,6,Color("102b30")); draw_circle(marker,3,Color("fff0c7"))
	for npc in get_tree().get_nodes_in_group("interactables"):
		if npc.kind!="npc": continue
		var relevant: bool=false
		for id in State.quest_progress:
			if State.completed_quests.has(id): continue
			var q: Dictionary=State.quest_data[id]
			if (int(State.quest_progress[id])>=int(q.count) and q.get("npc","rowan")==npc.npc_id) or (q.type=="talk" and q.target==npc.npc_id): relevant=true
		if not relevant: continue
		var address: Dictionary=generator.address(npc.global_position)
		if not generator.discovered.has(address.x+","+address.z): continue
		var at: Vector2=point(int(address.x),int(address.z),Vector2(address.local[0],address.local[2]))
		draw_string(hud.theme.default_font,at+Vector2(-3,-5),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("ffe19b"))
	draw_string(hud.theme.default_font,Vector2(14,24),"N ↑     Explored: %d areas" % generator.discovered.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("efe7ce"))
