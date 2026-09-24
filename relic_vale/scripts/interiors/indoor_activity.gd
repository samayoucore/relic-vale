class_name ValeIndoorActivity
extends Node
var manager: ValeInteriors
var npc: ValeInteractable
var record: Dictionary
var spot: Dictionary={}
var activity: String="Arriving"
var phase: float=0
var hand_prop: Node3D
var check_clock: float=0
var route:=PackedVector3Array()
var leaving: bool=false
var routine_key: String=""

func schedule_key() -> String:
	var hour: float=float(State.life_data.minute)/60
	return str(hour<6 or hour>=22)+"/"+str(hour>=8 and hour<18)+"/"+str(State.life_data.weather=="Storm")

func depart() -> void:
	if leaving: return
	leaving=true; activity="Leaving through the door"
	for old in manager.anchors:
		if old.resident==record.id: old.resident=""
	spot={"tag":"Door","position":manager.CENTER+Vector3(0,0,5),"facing":Vector3.BACK,"resident":record.id}
	route=ValeResidents.route(npc,spot.position)
	npc.sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED; npc.sprite.rotation=Vector3.ZERO; npc.sprite.scale=Vector3.ONE

func choose() -> void:
	routine_key=schedule_key()
	npc.sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED; npc.sprite.rotation=Vector3.ZERO; npc.sprite.scale=Vector3.ONE
	for old in manager.anchors:
		if old.resident==record.id: old.resident=""
	spot={}
	var hour: float=float(State.life_data.minute)/60
	var tag: String="Bed" if hour<6 or hour>=22 else ("TavernSeat" if manager.active.template=="tavern" else "Chair")
	if manager.active.id==record.work and hour>=8 and hour<18:
		tag={"blacksmith":"Forge","alchemist":"Workbench","shop":"Market","tavern":"Market"}.get(manager.active.template,"Bookshelf")
	for candidate in manager.anchors:
		if candidate.tag==tag and candidate.resident.is_empty(): spot=candidate; break
	if spot.is_empty():
		for candidate in manager.anchors:
			if candidate.resident.is_empty() and candidate.tag!="Door" and not (candidate.tag=="Bed" and hour>=6 and hour<22): spot=candidate; break
	if spot.is_empty(): return
	spot.resident=record.id
	npc.sprite.position.y=1.03
	activity={"Bed":"Sleeping","TavernSeat":"Eating / drinking","Forge":"Hammering","Workbench":"Preparing supplies","Market":"Serving customers","Bookshelf":"Reading","Chair":"Resting"}.get(spot.tag,"Resting")
	# Indoor residents use the same obstacle-aware grid as exterior residents.
	var goal: Vector3=spot.position; goal.y=0
	route=ValeResidents.route(npc,goal)
	if npc.get_meta("initial_activity",false):
		npc.global_position=spot.position; route.clear(); npc.set_meta("initial_activity",false)
	if is_instance_valid(hand_prop): hand_prop.queue_free()
	var asset: String="Mug" if spot.tag=="TavernSeat" else ("Book_5" if spot.tag=="Bookshelf" else ("Axe_Bronze" if spot.tag=="Forge" else "SmallBottles_1"))
	hand_prop=manager.game.world.place(manager.PROPS+asset+".gltf",Vector3.ZERO,.3 if spot.tag!="Forge" else .65,0,npc)
	if asset=="Book_5":
		var bounds: AABB=manager.game.world.bounds(hand_prop); hand_prop.scale*=.4/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
	hand_prop.visible=spot.tag in ["TavernSeat","Forge","Workbench","Bookshelf"]

func _ready() -> void:
	await get_tree().physics_frame
	choose()

func _process(delta: float) -> void:
	if State.modal or State.paused or spot.is_empty(): return
	if not leaving and routine_key!=schedule_key(): choose()
	phase+=delta; check_clock-=delta
	var cam: ValeCamera=manager.game.rig
	if not route.is_empty():
		var direction: Vector3=route[0]-npc.global_position
		if direction.length()<.12: route.remove_at(0)
		else:
			npc.global_position+=direction.normalized()*minf(direction.length(),delta*1.1)
			npc.sprite.play("walk_%d" % cam.screen_direction(direction))
	else:
		if leaving:
			manager.occupants.erase(record.id); npc.queue_free(); return
		npc.global_position=spot.position
		var direction: Vector3=spot.facing
		var player: ValePlayer=manager.game.player
		if player.global_position.distance_to(npc.global_position)<2.5 and spot.tag!="Bed": direction=player.global_position-npc.global_position
		npc.sprite.play(("slash_" if spot.tag in ["Forge","Workbench"] else "idle_")+str(cam.screen_direction(direction)))
		if spot.tag=="Bed":
			npc.sprite.billboard=BaseMaterial3D.BILLBOARD_DISABLED
			npc.sprite.global_basis=Basis(spot.facing.cross(Vector3.UP),spot.facing,Vector3.UP)
			npc.sprite.position=Vector3(0,.65,0)
		else:
			npc.sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED; npc.sprite.rotation=Vector3.ZERO
			npc.sprite.scale.y=.76 if spot.tag in ["Chair","TavernSeat"] else 1.0
		if spot.tag=="Forge" and check_clock<=0:
			check_clock=1.4; Feel.sound("stone_hit",.18); Feel.burst(manager.room,npc.global_position+Vector3(0,.8,-.5),Color("e6b56a"),3)
	if is_instance_valid(hand_prop):
		hand_prop.position=cam.camera.global_basis.y*(.8+sin(phase*2)*.09)+cam.camera.global_basis.x*.3
		hand_prop.rotation.z=sin(phase*4)*.65 if spot.tag=="Forge" else sin(phase*2)*.15

func _exit_tree() -> void:
	if is_instance_valid(manager):
		for old in manager.anchors:
			if old.resident==record.id: old.resident=""
