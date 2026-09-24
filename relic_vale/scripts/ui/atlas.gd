extends Control
var hud: ValeHUD

func point(pos: Vector2) -> Vector2:
	return (pos+Vector2(96,96))/224.0*390

func _draw() -> void:
	var generator: ValeGenerator=hud.world.generator
	var colors: Dictionary={"Briar Meadow":Color("829562"),"Elderwood":Color("506f53"),"Fallen March":Color("7c8473")}
	for data in generator.layout.values():
		draw_rect(Rect2(point(Vector2(data.coord)*32),Vector2.ONE*390/7.0),colors[data.biome])
	for road in generator.roads:
		for i in range(road.size()-1): draw_line(point(road[i]),point(road[i+1]),Color("d3b982"),2,true)
	for i in range(generator.landscape.stream.size()-1): draw_line(point(generator.landscape.stream[i]),point(generator.landscape.stream[i+1]),Color("85bec1"),4,true)
	for poi in generator.pois:
		var center:=point(poi.position)
		var color:=Color("e5d4a3") if State.discoveries.has(poi.id) else Color("afc3b4")
		draw_colored_polygon(PackedVector2Array([center+Vector2(0,-4),center+Vector2(4,0),center+Vector2(0,4),center+Vector2(-4,0)]),color)
		if poi.kind in ["settlement","mine","chapel","grove"]:
			draw_string(hud.theme.default_font,center+Vector2(6,4),poi.get("title",poi.kind.capitalize()),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f9edcc"))
	draw_rect(Rect2(point(Vector2(-12,-9)),Vector2(24,18)/224*390),Color("b89675"))
	var p: Vector3=hud.player.global_position if hud.player.global_position.x<900 else State.dungeon_return
	draw_circle(point(Vector2(p.x,p.z)),5,Color("142c30"))
	draw_circle(point(Vector2(p.x,p.z)),3,Color("fff2ce"))
	draw_rect(Rect2(0,0,390,390),Color("758671"),false,1)
