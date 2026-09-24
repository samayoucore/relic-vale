class_name ValeParty
extends Node
## Named companions are separate from hired camp residents. Only one travels with the player.
var game: Node
var actors: Dictionary={}
var clock: float=0
var bark_clock: float=35
var context: String=""
var last_origin:=Vector2i.ZERO

func _ready() -> void:
	game=get_tree().current_scene
	game.player.add_to_group("combat_allies")

func active() -> ValeCompanionActor:
	return actors.get(State.narrative.active) as ValeCompanionActor

func recruit(id: String) -> bool:
	if not ValeNarrative.companions.has(id): return false
	var row: Dictionary=State.narrative.companions[id]
	if row.recruited: return false
	row.recruited=true; row.level=State.level; row.hp=stats(id).max_hp
	if actors.has(id): actors[id].queue_free(); actors.erase(id)
	State.quest_event("recruit",id)
	State.notification.emit(ValeNarrative.companions[id].name+" has joined your company.")
	if State.narrative.active.is_empty(): set_active(id)
	State.changed.emit(); State.save_requested.emit(); return true

func set_active(id: String) -> bool:
	if id!="" and not State.narrative.companions.get(id,{}).get("recruited",false): return false
	if not State.narrative.active.is_empty() and State.narrative.active!=id and enemies_near(game.player.position,10):
		State.notification.emit("Regroup after the fight."); return false
	State.narrative.active=id; State.narrative.command="follow"
	reset(); sync(); after_transition()
	State.changed.emit(); State.save_requested.emit(); return true

func stats(id: String) -> Dictionary:
	var row: Dictionary=State.narrative.companions[id]
	var level: int=maxi(State.level,int(row.level))
	var result: Dictionary={"max_hp":90+level*12,"attack":7+level*2,"defense":2+level,"crit":.05}
	for item in row.equipment.values():
		for stat in State.items.get(item,{}).get("stats",{}):
			if result.has(stat): result[stat]+=State.items[item].stats[stat]
	return result

func equip(id: String,slot: String,item: String) -> bool:
	if not State.narrative.companions.get(id,{}).get("recruited",false) or slot not in ["Weapon","Armor","Accessory"]: return false
	var row: Dictionary=State.narrative.companions[id]
	var previous: String=row.equipment[slot]
	if previous==item: return true
	if item!="" and (int(State.inventory.get(item,0))<1 or not accepts_equipment(id,slot,item)): return false
	if item!="" and item in State.equipment.values() and int(State.inventory.get(item,0))<=1:
		State.notification.emit("Unequip that item from your traveler first."); return false
	if item!="": ValeLife.consume(item,1)
	if previous!="": State.add_item(previous)
	row.equipment[slot]=item
	if actors.has(id): actors[id].refresh_stats()
	State.changed.emit(); State.save_requested.emit(); return true

func accepts_equipment(id: String,slot: String,item: String) -> bool:
	if State.items.get(item,{}).get("slot","")!=("Body" if slot=="Armor" else slot): return false
	if slot!="Weapon": return true
	var role: String=ValeNarrative.companions[id].role
	return State.items[item].get("weapon_type","sword")==("sword" if role=="melee" else ("bow" if role=="ranged" else "staff"))

func command(value: String) -> void:
	if value in ["follow","wait"]:
		State.narrative.command=value
		if is_instance_valid(active()): active().wait_position=active().global_position
	elif value in ["passive","defensive","aggressive"]: State.narrative.stance=value
	State.notification.emit("Company · "+value.capitalize()); State.changed.emit(); State.save_requested.emit()

func enemies_near(p: Vector3,radius: float) -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(p)<radius: return true
	return false

func safe_position(near: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D=game.player.get_world_3d().direct_space_state
	var shape:=CapsuleShape3D.new(); shape.radius=.4; shape.height=1.6
	var query:=PhysicsShapeQueryParameters3D.new(); query.shape=shape; query.collision_mask=1
	for radius in [2.3,3.2,4.5,1.4]:
		for n in 12:
			var p: Vector3=near+Vector3(cos(n*TAU/12),0,sin(n*TAU/12))*radius
			if p.x<900:
				p.y=game.generator.landscape.height(Vector2(p.x,p.z))+.1
				if absf(p.y-near.y)>1.6: continue
				var at: Dictionary=game.generator.address(p)
				if game.generator.planner(at.x+","+at.z).water_distance(Vector2(at.local[0],at.local[2]))<1: continue
			query.transform.origin=p+Vector3(0,.85,0)
			if space.intersect_shape(query,1).is_empty(): return p
	return near+Vector3(0,.15,0)

func after_transition() -> void:
	var actor:=active()
	if not is_instance_valid(actor): return
	actor.global_position=safe_position(game.player.global_position); actor.velocity=Vector3.ZERO
	actor.wait_position=actor.global_position; actor.path.clear(); actor.target=null
	actor.record_position()

func shift_paths(delta: Vector3) -> void:
	for actor in actors.values():
		actor.home-=delta; actor.wait_position-=delta; actor.path.clear()

func reset() -> void:
	for actor in actors.values():
		if is_instance_valid(actor):
			actor.remove_from_group("combat_allies"); actor.queue_free()
	actors.clear(); context=""; clock=0

func sync() -> void:
	for id in ValeNarrative.companions:
		var row: Dictionary=State.narrative.companions[id]; var definition: Dictionary=ValeNarrative.companions[id]
		row.level=maxi(State.level,int(row.level))
		var traveling: bool=State.narrative.active==id
		var desired: Vector3
		var present: bool=traveling
		if traveling:
			desired=safe_position(game.player.position)
			if State.narrative.command=="wait" and game.player.position.x<900 and ValeSave.valid_address(row.address):
				var saved: Vector3=game.generator.position_of(row.address)
				if saved.distance_to(game.player.position)<64: desired=saved
		else:
			var address: Dictionary=game.narrative.location_address(definition.location)
			var at_camp: bool=row.recruited and not State.camp_data.is_empty()
			if at_camp: address=State.camp_data.address
			present=game.player.position.x<900 and absi(int(address.x)-game.generator.origin_x)<=2 and absi(int(address.z)-game.generator.origin_z)<=2
			desired=game.generator.position_of(address)
			if at_camp:
				var hour: float=float(State.life_data.minute)/60
				row.camp_state="Resting" if hour<6 or hour>22 else ("By the fire" if hour>18 else "Keeping watch")
				desired+=ValeSave.vector(definition.camp_anchor) if row.camp_state!="By the fire" else Vector3(-3,0,2)+ValeSave.vector(definition.camp_anchor)*.4
			if present: desired.y=game.generator.landscape.height(Vector2(desired.x,desired.z))+.1
		if not present:
			if actors.has(id): actors[id].queue_free(); actors.erase(id)
			continue
		if not actors.has(id):
			var actor:=ValeCompanionActor.new(); actor.id=id; actor.party=self; actor.position=desired; actor.traveling=traveling
			game.world.add_child(actor); actors[id]=actor
		else:
			actors[id].refresh_stats()
			if not traveling: actors[id].home=desired

func _process(delta: float) -> void:
	if not game.gameplay_started or State.paused: return
	clock-=delta; bark_clock-=delta
	if clock>0: return
	clock=.6
	var next_context: String=str(game.generator.origin_x)+","+str(game.generator.origin_z)+"/"+("inside" if game.player.position.x>900 else "outside")
	var actor:=active()
	# Continuous origin shifts move world children themselves; discard only cached world-space paths.
	if context!="" and context!=next_context and is_instance_valid(actor):
		actor.path.clear()
		if (actor.position.x>900)!=(game.player.position.x>900) or actor.position.distance_to(game.player.position)>80: after_transition()
	context=next_context
	sync()
	actor=active()
	if not is_instance_valid(actor): return
	actor.record_position()
	if bark_clock<=0 and not State.modal and not actor.downed:
		bark_clock=70+randf()*45
		var lines: Dictionary=ValeNarrative.companions[actor.id].barks
		var topic: String="night" if float(State.life_data.minute)>1200 or float(State.life_data.minute)<360 else "forest"
		for poi in game.generator.pois:
			if Vector2(actor.position.x,actor.position.z).distance_to(poi.position)<18:
				if poi.kind=="settlement": topic="town"
				elif poi.kind in ["ruin","chapel","circle"]: topic="ruin"
		for quest_id in ValeNarrative.companions[actor.id].personal:
			var destination: Dictionary=game.narrative.objective_address(quest_id)
			if not destination.is_empty() and actor.position.distance_to(game.generator.position_of(destination))<12: topic="personal"
		if State.life_data.weather in ["Rain","Storm"]: topic="rain"
		if enemies_near(actor.position,9): topic="combat"
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.archetype=="guardian" and enemy.global_position.distance_to(actor.position)<12: topic="boss"; break
		if game.camp.near_camp(): topic="story" if State.narrative.flags.get("act1_complete",false) else "camp"
		State.notification.emit(ValeNarrative.companions[actor.id].name+": "+str(lines.get(topic,"")))
