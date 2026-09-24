class_name ValeLootManager
extends Node3D
var active: Dictionary={}
var clock: float=0

func drop(bundle: Dictionary, pos: Vector3) -> void:
	var id: String="drop_%07d" % State.next_loot_id
	State.next_loot_id+=1
	State.pending_loot[id]={"position":[pos.x,pos.y,pos.z],"bundle":ValeLoot.prepare(bundle)}
	var gen: ValeStreamingGenerator=get_tree().current_scene.generator
	State.pending_loot[id].interior=pos.x>900
	if pos.x<900: State.pending_loot[id].address=gen.address(pos)
	show_drop(id)

func show_drop(id: String) -> void:
	if active.has(id) and is_instance_valid(active[id]): return
	var record: Dictionary=State.pending_loot[id]
	var node:=ValeGroundLoot.new()
	node.loot_id=id
	node.record=record
	node.position=record_position(record)
	node.position-=global_position
	add_child(node)
	active[id]=node

func clear() -> void:
	for node in active.values():
		if is_instance_valid(node): node.queue_free()
	active.clear()
	position=Vector3.ZERO

func record_position(record: Dictionary) -> Vector3:
	if record.has("address"):
		var gen: ValeStreamingGenerator=get_tree().current_scene.generator
		var address: Dictionary=record.address
		if absi(int(address.x)-gen.origin_x)>8 or absi(int(address.z)-gen.origin_z)>8: return Vector3(9999,0,0)
		return gen.position_of(address)
	return Vector3(record.position[0],record.position[1],record.position[2])

func _process(delta: float) -> void:
	clock-=delta
	if clock>0: return
	clock=.5
	var player:=get_tree().get_first_node_in_group("player") as ValePlayer
	if not player: return
	for id in active.keys():
		if not is_instance_valid(active[id]):
			active.erase(id)
			continue
		var node: Node3D=active[id]
		if not State.pending_loot.has(id) or node.global_position.distance_to(player.global_position)>55:
			node.queue_free()
			active.erase(id)
	for id in State.pending_loot:
		if active.size()>=50: break
		var pos: Vector3=record_position(State.pending_loot[id])
		if player.global_position.distance_to(pos)<45: show_drop(id)
