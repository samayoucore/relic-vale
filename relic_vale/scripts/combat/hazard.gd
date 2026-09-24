class_name ValeHazard
extends Node3D
var radius: float=2
var damage: int=8
var duration: float=4
var tick: float=.6
var color:=Color(.85,.46,.3,.4)

func _ready() -> void:
	add_to_group("combat_hazards")
	Feel.ring(self,global_position,radius,color,0,true)
	Feel.ring(self,global_position,radius,Color(color, .8),0)

func _physics_process(delta: float) -> void:
	if State.modal or State.paused: return
	duration-=delta
	tick-=delta
	if tick<=0:
		tick=1
		for player in get_tree().get_nodes_in_group("combat_allies"):
			if player.global_position.distance_to(global_position)<radius:
				player.take_damage(damage)
				player.statuses.apply("burn",2,2)
	if duration<=0: queue_free()
