class_name ValeAtlas
extends Control
var hud: ValeHUD
var center_x: int=0
var center_z: int=0
var pan:=Vector2.ZERO
var zoom: float=80
var dragging: bool=false
var minimap: bool=false
var filters: Dictionary={"Settlement":true,"Dungeon":true,"Landmark":true,"Quest":true,"Markers":true,"Camp":true,"Events":true}
var hits: Array=[]
var labels: Array[Rect2]=[]
var refresh: float=0

func _ready() -> void:
	clip_contents=true; custom_minimum_size=Vector2(160,130); texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	center_player(); resized.connect(queue_redraw)
	if minimap: zoom=100

func center_player() -> void:
	var address: Dictionary=hud.get_tree().current_scene.cartography.player_address()
	center_x=int(address.x); center_z=int(address.z); pan=-Vector2(address.local[0],address.local[2])*zoom/32; queue_redraw()

func point(x: int,z: int,offset: Vector2=Vector2.ZERO) -> Vector2:
	if absi(x-center_x)>100000 or absi(z-center_z)>100000: return Vector2(-100000,-100000)
	return size*.5+pan+(Vector2(x-center_x,z-center_z)+offset/32)*zoom

func address_at(pixel: Vector2) -> Dictionary:
	var position_in_chunks: Vector2=(pixel-size*.5-pan)/zoom
	var dx: int=floori(position_in_chunks.x); var dz: int=floori(position_in_chunks.y)
	return {"x":str(center_x+dx),"z":str(center_z+dz),"local":[fposmod(position_in_chunks.x,1)*32,0,fposmod(position_in_chunks.y,1)*32]}

func _process(delta: float) -> void:
	if minimap:
		var ui: ValeInterface=hud.ui
		size=Vector2(190,minf(170,ui.size.y-345)); position=Vector2(ui.size.x-size.x-24,167)
		visible=not State.modal and ui.size.y>=475 and hud.get_tree().current_scene.gameplay_started
	refresh-=delta
	if refresh<=0:
		refresh=.3
		if minimap: center_player()
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			dragging=event.pressed and not minimap
			if event.pressed:
				for entry in hits:
					if event.position.distance_to(entry.p)<11:
						if entry.data.has("address"): ValeCampUI.marker(hud.ui,entry.data)
						else: hud.show_toast(entry.data.name+" · "+entry.data.type)
						dragging=false; break
		if event.pressed and event.button_index==MOUSE_BUTTON_RIGHT and not minimap:
			var marker: Dictionary=hud.get_tree().current_scene.cartography.add_marker(address_at(event.position))
			if not marker.is_empty(): ValeCampUI.marker(hud.ui,marker)
			else: hud.show_toast("Place markers on explored ground.")
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var old: float=zoom; zoom=clampf(zoom*(2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .5),50 if minimap else 20,200 if minimap else 320)
			pan=event.position-size*.5-(event.position-size*.5-pan)*zoom/old
		accept_event(); queue_redraw()
	if event is InputEventMouseMotion:
		if dragging:
			pan+=event.relative
			# Rebase panning into integer chunks to keep float precision bounded.
			var dx: int=floori(pan.x/zoom); var dz: int=floori(pan.y/zoom)
			center_x-=dx; center_z-=dz; pan-=Vector2(dx,dz)*zoom
		tooltip_text=""
		for entry in hits:
			if event.position.distance_to(entry.p)<12: tooltip_text=entry.data.get("name","")+" · "+entry.data.get("type",entry.data.get("icon","Marker")); break
		accept_event(); queue_redraw()

func symbol(p: Vector2,kind: String,title: String,data: Dictionary={}) -> void:
	if not Rect2(Vector2.ZERO,size).has_point(p): return
	var color:=Color("f4dc9a")
	draw_circle(p,6,Color("263d35"))
	match kind:
		"Camp":
			draw_arc(p,8,0,TAU,16,Color("ffa95f"),2,true)
			draw_colored_polygon(PackedVector2Array([p+Vector2(-4,4),p+Vector2(0,-5),p+Vector2(4,4)]),Color("fff2c5"))
		"Home","Settlement":
			draw_colored_polygon(PackedVector2Array([p+Vector2(-5,1),p+Vector2(0,-5),p+Vector2(5,1)]),color); draw_rect(Rect2(p+Vector2(-3,0),Vector2(6,5)),color)
		"Resource": draw_colored_polygon(PackedVector2Array([p+Vector2(-4,0),p+Vector2(0,-5),p+Vector2(4,0),p+Vector2(0,5)]),Color("a8d48a"))
		"Treasure": draw_rect(Rect2(p-Vector2(5,3),Vector2(10,7)),Color("e6b76e")); draw_line(p+Vector2(0,-3),p+Vector2(0,4),Color("654c39"),2)
		"Danger","Dungeon": draw_colored_polygon(PackedVector2Array([p+Vector2(-4,4),p+Vector2(0,-5),p+Vector2(4,4)]),Color("dd9b87"))
		"Quest": draw_string(hud.theme.default_font,p+Vector2(-3,5),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,17,color)
		_: draw_line(p+Vector2(-2,5),p+Vector2(-2,-5),color,2); draw_rect(Rect2(p+Vector2(-2,-5),Vector2(6,4)),color)
	if not minimap and zoom>=80:
		var extent:=Rect2(p+Vector2(8,-20),Vector2(minf(170,hud.theme.default_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)+5,19))
		var overlaps: bool=false
		for occupied in labels:
			if occupied.intersects(extent): overlaps=true; break
		if not overlaps:
			labels.append(extent); draw_string(hud.theme.default_font,p+Vector2(9,-6),title,HORIZONTAL_ALIGNMENT_LEFT,170,12,Color("fff3d1"))
	if not data.is_empty(): hits.append({"p":p,"data":data})

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("203833")); hits.clear(); labels.clear()
	var game: Node=hud.get_tree().current_scene
	var first: Dictionary=address_at(Vector2.ZERO); var last: Dictionary=address_at(size)
	for x in range(int(first.x),int(last.x)+1):
		for z in range(int(first.z),int(last.z)+1):
			var key: String=ValeRegionPlan.key(x,z)
			if not game.generator.discovered.has(key): continue
			var at: Vector2=point(x,z)
			var colors: Dictionary={"Briar Meadow":Color("91a879"),"Elderwood":Color("496d51"),"Fallen March":Color("918b7c")}
			var record: Dictionary=game.generator.discovered[key]
			draw_rect(Rect2(at,Vector2.ONE*zoom),colors.get(record.get("biome",""),Color("718865")))
			var texture: Texture2D=null
			if absf(at.x-size.x*.5)<zoom*10 and absf(at.y-size.y*.5)<zoom*10: texture=game.cartography.tile(key)
			if texture: draw_texture_rect(texture,Rect2(at,Vector2.ONE*zoom),false)
			else:
				for road in record.get("roads",[]): draw_line(point(x,z,Vector2(road[0],road[1])),point(x,z,Vector2(road[2],road[3])),Color("cfbc8a"),1)
				for water in record.get("water",[]): draw_circle(point(x,z,Vector2(water[0],water[1])),maxf(1,zoom*.06),Color("669ba7"))
			var plan: ValeRegionPlan=game.generator.planner(key)
			for poi in plan.pois:
				if not Rect2(0,0,32,32).has_point(poi.position): continue
				var kind: String="Settlement" if poi.kind=="settlement" else ("Dungeon" if poi.kind in ["ruin","mine","chapel"] else "Landmark")
				if not filters[kind]: continue
				var title: String=poi.get("title",str(poi.kind).capitalize())
				symbol(point(x,z,poi.position),kind,title,{"name":title,"type":kind+(" · homes, trade, crafts" if kind=="Settlement" else "")})
	for settlement in State.life_data.settlements.values():
		if not filters.Settlement: break
		for building in settlement.get("buildings",{}).values():
			var a: Dictionary=building.door
			if game.generator.discovered.has(a.x+","+a.z): symbol(point(int(a.x),int(a.z),Vector2(a.local[0],a.local[2])),"Home",building.title,{"name":building.title,"type":building.template})
	for marker in game.cartography.markers():
		if not filters["Camp" if marker.id=="camp" else "Markers"]: continue
		var a: Dictionary=marker.address
		symbol(point(int(a.x),int(a.z),Vector2(a.local[0],a.local[2])),"Camp" if marker.id=="camp" else marker.icon,marker.name,marker)
	if filters.Quest:
		for id in State.quest_progress:
			if State.quest_data.get(id,{}).get("type","")!="narrative": continue
			if id!=State.narrative.tracked: continue
			var a: Dictionary=game.narrative.objective_address(id)
			if not a.is_empty(): symbol(point(int(a.x),int(a.z),Vector2(a.local[0],a.local[2])),"Quest",State.quest_data[id].name,{"name":State.quest_data[id].name,"type":"Current objective"})
		for npc in get_tree().get_nodes_in_group("interactables"):
			if npc.kind!="npc" or not npc.is_visible_in_tree(): continue
			var relevant: bool=false
			for id in State.quest_progress:
				if State.completed_quests.has(id): continue
				var q: Dictionary=State.quest_data[id]
				if q.type=="narrative": continue
				if q.get("npc","rowan")==npc.npc_id or (q.type=="talk" and q.target==npc.npc_id): relevant=true
			if relevant:
				var a: Dictionary=game.generator.address(npc.global_position)
				if game.generator.discovered.has(a.x+","+a.z): symbol(point(int(a.x),int(a.z),Vector2(a.local[0],a.local[2])),"Quest","Quest",{"name":npc.title,"type":"Quest"})
	var address: Dictionary=game.cartography.player_address()
	if filters.Events:
		for row in game.world_events.records().values():
			if row.state!="active" or not row.discovered: continue
			var a: Dictionary=row.destination if int(row.stage)==1 else row.address
			symbol(point(int(a.x),int(a.z),Vector2(a.local[0],a.local[2])),"Quest",game.world_events.data_name(row),{"name":game.world_events.data_name(row),"type":"Temporary road encounter"})
	if filters.Markers:
		for record in State.activities.rare_notes.values():
			var a: Dictionary=record.address
			symbol(point(int(a.x),int(a.z),Vector2(a.local[0],a.local[2])),"Resource",record.name,{"name":record.name,"type":"Rare gathering site"})
		for record in State.activities.treasures.values():
			if record.claimed: continue
			var a: Dictionary=record.area
			var p: Vector2=point(int(a.x),int(a.z),Vector2(a.local[0],a.local[2]))
			draw_circle(p,float(record.radius)*zoom/32,Color(.86,.68,.36,.15))
			draw_arc(p,float(record.radius)*zoom/32,0,TAU,32,Color("deb66f"),1.5,true)
			if not minimap: draw_string(hud.theme.default_font,p,record.name,HORIZONTAL_ALIGNMENT_LEFT,150,12,Color("f1d49b"))
	var player: Vector2=point(int(address.x),int(address.z),Vector2(address.local[0],address.local[2]))
	draw_circle(player,6,Color("183933")); draw_circle(player,3,Color("ffffff"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("cfbc8a"),false,2)
	draw_string(hud.theme.default_font,Vector2(10,20),"N ↑" if minimap else "N ↑   ·   %d explored areas" % game.generator.discovered.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff3d1"))
