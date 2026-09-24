class_name ValeFauna
extends Node3D
## Non-combat wildlife: explicit activities, home range, herds and simulation LOD.
var gen: ValeGenerator
var visual: ValeCreatureVisual
var origin: Vector2
var elapsed: float=0
var seed_phase: float=0
var species: String="deer"
var farm: bool=false
var state: String="Grazing"
var timer: float=0
var sound_clock: float=15
var target:=Vector2.ZERO
var flee_timer: float=0
var lod: String="near"
var group_id: String=""
var far_tick: float=0

func _ready() -> void:
	add_to_group("fauna")
	origin=Vector2(global_position.x,global_position.z); target=origin
	seed_phase=fposmod(origin.x+origin.y,TAU); timer=3+seed_phase
	visual=ValeCreatureVisual.new(); add_child(visual)
	visual.setup(species,{"fox":.7,"cow":1.4,"horse":1.8,"alpaca":1.3}.get(species,1.5))

func flee() -> void:
	flee_timer=4; state="Fleeing"

func shift_origin(delta: Vector3) -> void:
	var planar:=Vector2(delta.x,delta.z)
	origin-=planar; target-=planar

func _process(delta: float) -> void:
	if State.modal or State.paused or gen.player.position.x>900: return
	var distance: float=global_position.distance_to(gen.player.global_position)
	lod="sleep" if distance>65 else ("far" if distance>32 else "near")
	visual.animator.speed_scale=0 if lod=="sleep" else 1
	if lod=="sleep": return
	if lod=="far":
		far_tick+=delta
		if far_tick<.3: return
		delta=far_tick; far_tick=0
	elapsed+=delta; timer-=delta; sound_clock-=delta; flee_timer=maxf(0,flee_timer-delta)
	var p:=Vector2(global_position.x,global_position.z)
	var hour: float=float(State.life_data.minute)/60
	var sleeping: bool=hour>=22 or hour<5
	var alarm: bool=distance<(1.2 if farm else 3.8) or (distance<9 and gen.player.attack_timer>.15)
	if alarm: flee()
	if flee_timer>0:
		target=p+(p-Vector2(gen.player.position.x,gen.player.position.z)).normalized()*3
		state="Fleeing"
	elif sleeping or State.life_data.weather=="Storm":
		target=origin; state="Returning home" if p.distance_to(origin)>.6 else "Sleeping"
	elif timer<=0:
		timer=4+fposmod(elapsed+seed_phase,5)
		state=["Idle","Wandering","Grazing","Following herd"][int(elapsed+seed_phase)%4]
		target=origin+Vector2(sin(elapsed*.2+seed_phase),cos(elapsed*.17+seed_phase))*(2.5 if farm else 5)
		if state=="Following herd":
			for other in get_tree().get_nodes_in_group("fauna"):
				if other!=self and other.group_id==group_id and other.get_instance_id()<get_instance_id() and other.global_position.distance_to(global_position)<12:
					target=Vector2(other.global_position.x,other.global_position.z)+Vector2(1.5,1); break
	var move:=Vector2.ZERO
	if state in ["Wandering","Following herd","Returning home","Fleeing"] and p.distance_to(target)>.25: move=(target-p).normalized()*(2.8 if state=="Fleeing" else .6)
	var next: Vector2=p+move*delta
	var clear: bool=gen.landscape.water_distance(next)>1
	if clear and next.distance_to(origin)<(3.5 if farm else 12):
		var query:=PhysicsRayQueryParameters3D.create(global_position+Vector3(0,.5,0),Vector3(next.x,global_position.y+.5,next.y)+Vector3(move.x,0,move.y).normalized()*.45,1)
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): global_position=Vector3(next.x,gen.landscape.height(next),next.y)
	if state=="Grazing": visual.play("eat")
	elif state=="Sleeping": visual.play("sleep")
	else: visual.tick(delta,Vector3(move.x,0,move.y),false,false)
	visual.scale.y=.82 if state=="Sleeping" else 1
	if sound_clock<=0 and distance<15 and state!="Sleeping":
		sound_clock=25+seed_phase*4
		if species=="cow": Feel.sound("animal_cow",.15*(1-distance/15))
		elif move.length()>.1: Feel.sound("hoof" if species!="fox" else "plant_pick",(.1 if farm else .06)*(1-distance/15))
