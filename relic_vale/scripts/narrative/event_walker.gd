class_name ValeEventWalker
extends Node
var event_id: String
var clock: float=0
var path:=PackedVector3Array()
var origin_stamp: String=""
func _physics_process(delta: float) -> void:
	if State.modal or State.paused: return
	var game: Node=get_tree().current_scene
	var row: Dictionary=State.life_data.events.get(event_id,{})
	if int(row.get("stage",0))!=1 or row.state!="active": return
	var actor: ValeInteractable=get_parent()
	var goal: Vector3=game.player.position
	if actor.global_position.distance_to(goal)<2.4: actor.sprite.play("idle_2"); return
	var stamp: String=str(game.generator.origin_x)+","+str(game.generator.origin_z)
	clock-=delta
	if clock<=0 or origin_stamp!=stamp:
		path=ValeResidents.travel_route(actor,goal); clock=.9; origin_stamp=stamp
	while not path.is_empty() and actor.global_position.distance_to(path[0])<.7: path.remove_at(0)
	if path.is_empty(): return
	var motion: Vector3=path[0]-actor.global_position; motion.y=0
	actor.global_position+=motion.normalized()*minf(delta*3.3,motion.length())
	actor.global_position.y=game.generator.landscape.height(Vector2(actor.global_position.x,actor.global_position.z))
	actor.sprite.play("walk_2")
