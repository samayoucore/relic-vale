extends Control
## Project world positions to a native-resolution canvas so text stays crisp above pixel art.
var game: Node
var font: Font

func _ready() -> void:
	var body:=FontVariation.new(); body.base_font=load("res://assets/ui/phase5/Rubik.ttf"); body.variation_opentype={"wght":400.0}; font=body

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game) or State.modal: return
	for node in get_tree().get_nodes_in_group("interactables"):
		if not node.is_visible_in_tree(): continue
		if node.has_meta("plot") and node!=game.nearest: continue
		var distance: float=game.player.global_position.distance_to(node.global_position)
		if node.kind=="resource" and distance>3: continue
		if distance>10.5: continue
		var text: String=node.marker.text
		if node.kind=="npc": text=node.title
		write_name(node.global_position+node.marker.position,text,Color("f0e5bc"))
	for node in get_tree().get_nodes_in_group("enemies"):
		if node.boss and node.boss.engaged:
			draw_boss(node)
			continue
		if node.global_position.distance_to(game.player.global_position)>5.5: continue
		var offset: Vector3=node.global_position-game.player.global_position
		if node.hp==node.max_hp and offset.normalized().dot(game.player.facing)<.75: continue
		if node.archetype=="mimic" and node.mind and not node.mind.awake:
			write_name(node.global_position+Vector3(0,1.2,0),"Weathered coffer",Color("dfcca1"))
			continue
		var pos: Vector3=node.global_position+Vector3(0,1.85 if node.unique else 1.65,0)
		write_name(pos,"%s  ·  Lv %d" % [node.display_name,node.enemy_level],Color("e8c580") if node.unique else Color("dce6bb"))
		var p: Vector2=game.rig.camera.unproject_position(pos)*get_viewport_rect().size/Vector2(game.viewport.size)
		if p.y<145 or p.y>530: continue
		draw_rect(Rect2(p.x-37,p.y+4,74,5),Color("223a3b"))
		draw_rect(Rect2(p.x-36,p.y+5,72*float(node.hp)/node.max_hp,3),Color("c89a78"))
		if not node.statuses.effects.is_empty(): draw_string(font,p+Vector2(-37,22)," · ".join(node.statuses.effects.keys()).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("a9cfd8"))

func draw_boss(boss: Mossling) -> void:
	var caption: String="THE HOLLOW KNIGHT   ·   PHASE %s" % ("II" if boss.boss.phase==2 else "I")
	var width: float=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
	draw_string_outline(font,Vector2(640-width*.5,119),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,15,4,Color("172a30"))
	draw_string(font,Vector2(640-width*.5,119),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("e7cc8d"))
	draw_rect(Rect2(427,127,426,12),Color("20363b"))
	draw_rect(Rect2(429,129,422*float(boss.hp)/boss.max_hp,8),Color("a47c9b") if boss.boss.phase==2 else Color("b38d67"))
	var hp: String="%d / %d" % [boss.hp,boss.max_hp]
	draw_string(font,Vector2(615,153),hp,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e3dabc"))

func write_name(pos: Vector3, text: String, color: Color) -> void:
	if game.rig.camera.is_position_behind(pos): return
	var projected: Vector2=game.rig.camera.unproject_position(pos)
	var scale_factor: Vector2=get_viewport_rect().size/Vector2(game.viewport.size)
	projected*=scale_factor
	if projected.x<20 or projected.x>get_viewport_rect().size.x-20 or projected.y<145 or projected.y>530: return
	var width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	projected.x-=width*.5
	draw_string_outline(font,projected,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,4,Color(.06,.13,.14,.85))
	draw_string(font,projected,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
