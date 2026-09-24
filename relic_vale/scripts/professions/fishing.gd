class_name ValeFishing
extends Node
## An explicit cast/bite/reel state machine; simulation and presentation share the same catch.
var game: Node
var state: String="idle"
var elapsed: float=0
var wait_seconds: float=0
var fish_id: String=""
var water_kind: String="river"
var cast_address: Dictionary={}
var bank_address: Dictionary={}
var bobber: Node3D
var fish_model: Node3D
var line: MeshInstance3D
var panel: Control
var note: Label
var meter: Control
var progress: float=0
var zone: float=.5
var fish_position: float=.5
var tension: float=0
var roll: RandomNumberGenerator=RandomNumberGenerator.new()
var forced_fish: String=""
var latest: Dictionary={}

func _ready() -> void: game=get_tree().current_scene
func busy() -> bool: return state!="idle"
func equipped() -> bool: return State.items.get(State.equipment.get("Tool",""),{}).get("tool","")=="rod"

func water_at(point: Vector3) -> bool:
	var p:=Vector2(point.x,point.z)
	return game.generator.landscape.water_distance(p)<-.55 and game.generator.landscape.height(p)<-.28 and not game.generator.in_hub(p)

func bank_target(origin: Vector3,direction: Vector3) -> Dictionary:
	if origin.x>900 or game.generator.landscape.water_distance(Vector2(origin.x,origin.z))<.3: return {}
	direction.y=0; direction=direction.normalized()
	for distance in [2.5,3.5,4.5,5.5,6.5]:
		var point: Vector3=origin+direction*distance
		if not water_at(point): continue
		point.y=-.16
		var query:=PhysicsRayQueryParameters3D.create(origin+Vector3(0,1,0),point+Vector3(0,.25,0),1)
		if not game.player.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		var open_water: int=0
		for v in [Vector3(3,0,0),Vector3(-3,0,0),Vector3(0,0,3),Vector3(0,0,-3)]:
			if water_at(point+v): open_water+=1
		return {"position":point,"water":"lake" if open_water>=3 else "river"}
	return {}

func eligible(kind: String) -> Array[String]:
	var result: Array[String]=[]
	for id in ValeProfessions.fish:
		var fish: Dictionary=ValeProfessions.fish[id]
		if int(fish.min_level)>ValeProfessions.level("fishing"): continue
		if fish.water!="any" and fish.water!=kind: continue
		if not ValeProfessions.condition_ok(fish.time) or not ValeProfessions.condition_ok(fish.weather): continue
		result.append(id)
	return result

func choose_fish(kind: String,bait: Dictionary) -> String:
	var candidates: Array[String]=eligible(kind)
	var weights: Array[float]=[]; var total: float=0
	for id in candidates:
		var weight: float=catch_weight(id,bait)
		weights.append(weight); total+=weight
	var value: float=roll.randf()*total
	for i in candidates.size():
		value-=weights[i]
		if value<=0: return candidates[i]
	return "fish_minnow"

func catch_weight(id: String,bait: Dictionary) -> float:
	var fish: Dictionary=ValeProfessions.fish[id]
	var weight: float={"Common":1.0,"Uncommon":.4,"Rare":.16,"Epic":.045,"Legendary":.012}[fish.rarity]
	if fish.rarity!="Common": weight*=float(bait.rare)*(1+ValeProfessions.food_bonus("fishing_luck"))
	if bait.get("target_water","any")!="any" and fish.water==bait.target_water: weight*=1.25
	return weight

func cast() -> bool:
	if busy() or State.modal or State.paused or game.player.attack_timer>0 or game.player.gathering.busy: return false
	if not equipped(): State.notification.emit("Equip a fishing rod in your Tool slot."); return false
	if game.mounts.mounted: State.notification.emit("Dismount before fishing."); return false
	var target: Dictionary=bank_target(game.player.global_position,game.player.facing)
	if target.is_empty(): State.notification.emit("Stand on dry bank and face open water within 6 metres."); return false
	var bait_id: String=State.activities.bait
	var bait: Dictionary=State.items.get(bait_id,{}).get("bait",{})
	if bait.is_empty() or int(State.inventory.get(bait_id,0))<1: State.notification.emit("Choose bait in Professions [P] → Fishing."); return false
	if ValeProfessions.level("fishing")<int(bait.min_level): State.notification.emit("Fishing %d required for this bait." % bait.min_level); return false
	water_kind=target.water; cast_address=game.generator.address(target.position); bank_address=game.generator.address(game.player.global_position)
	State.activities.casts+=1
	roll.seed=(str(State.world_seed)+"/cast/"+str(State.activities.casts)).hash()
	fish_id=forced_fish if ValeProfessions.fish.has(forced_fish) else choose_fish(water_kind,bait)
	forced_fish=""
	wait_seconds=roll.randf_range(1.8,4.5)*float(bait.wait)
	ValeLife.consume(bait_id,1)
	state="casting"; elapsed=0; progress=.12; zone=.5; tension=0; latest={}
	game.player.velocity=Vector3.ZERO
	game.player.sprite.play("slash_%d" % game.rig.screen_direction(game.player.facing))
	bobber=game.world.place("res://assets/3d/phase8/cutefish/Lure_1.glb",target.position,.18,0,game.world)
	fish_model=Node3D.new(); game.world.add_child(fish_model); fish_model.position=target.position
	for i in 2:
		var fish: Node3D=game.world.place("res://assets/3d/phase8/cutefish/Tetra.glb",Vector3(i*.6-.3,-.20,i*.15),.14,90,fish_model)
		for animator in fish.find_children("*","AnimationPlayer",true,false):
			for clip in animator.get_animation_list():
				if "Swimming_Normal" in clip: animator.get_animation(clip).loop_mode=Animation.LOOP_LINEAR; animator.play(clip); break
	line=MeshInstance3D.new(); game.world.add_child(line)
	build_panel()
	State.save_requested.emit()
	return true

func build_panel() -> void:
	panel=PanelContainer.new(); panel.theme=game.hud.ui.theme; panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	game.hud.ui.chrome.add_child(panel)
	panel.size=Vector2(440,180)
	panel.position=Vector2((game.hud.ui.size.x-panel.size.x)*.5,maxf(110,game.hud.ui.size.y-345))
	var box: VBoxContainer=game.hud.ui.vbox(panel)
	note=game.hud.ui.text(box,"Casting into the "+water_kind,"Heading",true)
	meter=Control.new(); meter.custom_minimum_size=Vector2(420,62); meter.mouse_filter=Control.MOUSE_FILTER_IGNORE; box.add_child(meter)
	meter.draw.connect(draw_meter)
	game.hud.ui.text(box,"Hold Space / left mouse: move right\nRelease: left · Keep the fish inside · Esc: cancel","Muted",true)

func draw_meter() -> void:
	var w: float=meter.size.x-20; var h: float=22
	meter.draw_style_box(game.hud.ui.theme.get_stylebox("panel","PanelContainer"),Rect2(8,8,w,h))
	var size: float=zone_width()
	meter.draw_rect(Rect2(8+(zone-size*.5)*w,8,size*w,h),Color("769c83"))
	meter.draw_circle(Vector2(8+fish_position*w,19),7,Color("ebd59b"))
	meter.draw_rect(Rect2(8,42,w,8),Color("302f37"))
	meter.draw_rect(Rect2(8,42,w*progress,8),Color("c0d59d"))
	if tension>.3: meter.draw_rect(Rect2(8,54,w*tension,3),Color("d88a78"))

func zone_width() -> float:
	var tier: int=int(State.items.get(State.equipment.get("Tool",""),{}).get("tier",1))
	return .28+ValeProfessions.level("fishing")*.002+(tier-1)*.025

func input(event: InputEvent) -> bool:
	if not busy(): return false
	if event.is_action_pressed("pause"): cancel("Line reeled in."); return true
	if state=="bite" and event.is_action_pressed("attack"):
		state="reeling"; elapsed=0; Feel.sound("plant_pick",.35)
	return event.is_action("attack") or event.is_action("interact") or event.is_action("dodge") or event.is_action("ability_1") or event.is_action("ability_2")

func _process(delta: float) -> void:
	if not busy(): return
	if State.modal or State.paused or not equipped() or game.player.statuses.has("stun") or game.player.invulnerability>.8:
		cancel("Fishing interrupted."); return
	if game.player.global_position.distance_to(game.generator.position_of(bank_address))>1.5:
		cancel("The line was left behind."); return
	elapsed+=delta
	match state:
		"casting":
			note.text="Casting into the "+water_kind
			if elapsed>=.75: state="waiting"; elapsed=0
		"waiting":
			note.text="Watch the float…"
			if elapsed>=wait_seconds: state="bite"; elapsed=0; Feel.sound("plant_pick",.65)
		"bite":
			note.text="A bite! Tap Space / left mouse"
			if elapsed>2.2: cancel("The fish slipped off the hook.")
		"reeling":
			reel_step(delta,Input.is_action_pressed("attack"))
	if not busy(): return
	if is_instance_valid(meter): meter.queue_redraw()
	var p: Vector3=game.generator.position_of(cast_address)
	bobber.position=p+Vector3(0,sin(elapsed*(18 if state=="bite" else 3))*.035,0)
	if is_instance_valid(fish_model): fish_model.position=p+Vector3(sin(elapsed*.4)*.25,0,cos(elapsed*.4)*.20)
	update_line(p)
	game.player.weapon_sprite.visible=false

func reel_step(delta: float,held: bool) -> void:
	var difficulty: float=ValeProfessions.fish[fish_id].difficulty
	zone=clampf(zone+(1 if held else -1)*delta*.42,zone_width()*.5,1-zone_width()*.5)
	fish_position=.5+sin(elapsed*(.6+difficulty))* (.19+difficulty*.13)+sin(elapsed*(1.7+difficulty))*.045
	var inside: bool=absf(fish_position-zone)<zone_width()*.5
	progress=clampf(progress+delta*(.135/(1+difficulty*.8) if inside else -.05),0,1)
	tension=clampf(tension+delta*(-.3 if inside else .12),0,1)
	if is_instance_valid(note): note.text="Keep the fish in the green zone · %d%%" % roundi(progress*100)
	if progress>=1: land_catch()
	elif tension>=1 or elapsed>45: cancel("The fish broke free. Try following it with shorter taps.")

func land_catch() -> void:
	if state!="reeling": return
	var fish: Dictionary=ValeProfessions.fish[fish_id]
	var weight: float=snappedf(roll.randf_range(fish.weight_min,fish.weight_max),.01)
	var junk: bool=roll.randf()<.065
	if junk:
		var id: String="old_boot" if roll.randf()<.55 else "message_bottle"
		State.add_item(id); State.notification.emit("Caught: "+State.items[id].name)
		if id=="message_bottle": State.add_item("map_fragment")
		latest={"item":id,"weight":0}
	else:
		State.add_item(fish_id)
		var record: Dictionary=State.activities.fish_journal.get(fish_id,{"count":0,"best_weight":0,"best_size":0})
		record.count+=1; record.best_weight=maxf(weight,float(record.best_weight)); record.best_size=maxf(sqrt(weight)*34,float(record.best_size))
		record.address=cast_address.duplicate(true); record.water=water_kind; record.day=int(State.life_data.day)
		State.activities.fish_journal[fish_id]=record
		ValeProfessions.award("fishing",14+roundi(fish.difficulty*30))
		if roll.randf()<.10: State.add_item("map_fragment")
		if roll.randf()<.025: game.exploration.create_map()
		State.notification.emit("Caught %s · %.2f kg" % [fish.name,weight])
		latest={"item":fish_id,"weight":weight}
		Feel.burst(game.world,bobber.global_position,Color("b8d7d5"),7)
	cancel("")
	State.changed.emit(); State.save_requested.emit()

func update_line(end: Vector3) -> void:
	var mesh:=ImmediateMesh.new(); mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var start: Vector3=game.player.gathering.hand.global_position+Vector3(0,1.0,0)
	for i in 13:
		var t: float=i/12.0
		mesh.surface_add_vertex(start.lerp(end,t)+Vector3(0,sin(t*PI)*.15,0))
	mesh.surface_end(); line.mesh=mesh
	if not line.material_override:
		var material:=StandardMaterial3D.new(); material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; material.albedo_color=Color("b9b7a5"); line.material_override=material

func cancel(message: String="") -> void:
	state="idle"; elapsed=0
	for node in [bobber,line,panel,fish_model]:
		if is_instance_valid(node): node.queue_free()
	bobber=null; line=null; panel=null; fish_model=null
	if not message.is_empty(): State.notification.emit(message)
	if is_instance_valid(game): game.player.attack_timer=0
