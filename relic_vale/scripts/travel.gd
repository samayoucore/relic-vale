class_name ValeTravel
extends Node
var game: Node
var busy: bool=false
var last_error: String=""
var last_ready: Dictionary={}
var combat_until: float=0
var previous_hp: int=100

func _ready() -> void: game=get_tree().current_scene; previous_hp=State.hp
func _process(_delta: float) -> void:
	if State.hp<previous_hp or game.player.attack_timer>0: combat_until=Time.get_ticks_msec()/1000.0+8
	previous_hp=State.hp

func blocked() -> String:
	if busy or game.interiors.transitioning: return "A journey is already in progress."
	if State.interior_data.has("active"): return "Leave the building before traveling."
	if game.player.position.x>900: return "Return from the dungeon before traveling."
	if State.hp<=0: return "You cannot travel while defeated."
	if Time.get_ticks_msec()/1000.0<combat_until or game.player.attack_timer>0: return "Finish the fight before traveling."
	for enemy in get_tree().get_nodes_in_group("enemy_bodies"):
		if enemy.is_inside_tree() and enemy.is_visible_in_tree() and not enemy.dead and enemy.global_position.distance_to(game.player.position)<maxf(12,float(enemy.config.get("detect",10))): return "Enemies are too close to travel safely."
	return ""

func safe_spot(at: Vector3) -> Variant:
	var capsule:=CapsuleShape3D.new(); capsule.radius=.45; capsule.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new(); query.shape=capsule; query.collision_mask=1; query.exclude=[game.player.get_rid()]
	var space: PhysicsDirectSpaceState3D=game.world.get_world_3d().direct_space_state
	for radius in range(0,13,2):
		for angle in (1 if radius==0 else 16):
			var p: Vector3=at+Vector3(cos(angle*TAU/16)*radius,0,sin(angle*TAU/16)*radius)
			var address: Dictionary=game.generator.address(p)
			var plan: ValeRegionPlan=game.generator.planner(address.x+","+address.z)
			var local:=Vector2(address.local[0],address.local[2])
			if plan.water_distance(local)<.7 and plan.hub_distance(local)>1: continue
			var ground: float=game.generator.landscape.height(Vector2(p.x,p.z))
			var ray:=PhysicsRayQueryParameters3D.create(Vector3(p.x,ground+3,p.z),Vector3(p.x,ground-2,p.z),1,[game.player.get_rid()])
			var hit: Dictionary=space.intersect_ray(ray)
			if hit.is_empty() or hit.normal.y<.85 or absf(hit.position.y-ground)>.4: continue
			p.y=hit.position.y+.07; query.transform.origin=p+Vector3(0,.92,0)
			if not space.intersect_shape(query,1).is_empty(): continue
			var unsafe: bool=false
			for enemy in get_tree().get_nodes_in_group("enemy_bodies"):
				if enemy.is_inside_tree() and not enemy.dead and enemy.is_visible_in_tree() and enemy.global_position.distance_to(p)<12: unsafe=true; break
			if not unsafe: return p
	return null

func go(marker: Dictionary) -> bool:
	last_error=blocked()
	if not last_error.is_empty(): State.notification.emit(last_error); return false
	if not ValeSave.valid_address(marker.get("address",{})):
		last_error="This marker has no valid destination."; return false
	var address: Dictionary=marker.address
	if marker.get("id","")!="camp" and not game.generator.discovered.has(address.x+","+address.z):
		last_error="Explore this place before traveling to it."; State.notification.emit(last_error); return false
	busy=true; last_ready={}
	var previous: Dictionary=game.generator.address(game.player.position)
	game.player.combat.cancel(); game.player.gathering.cancel(); game.player.velocity=Vector3.ZERO
	game.camp.cancel_placement(); game.camp.clear_visual()
	await ValeMenuPages.loading(game.hud.ui)
	game.hud.modal_title.text="Traveling to "+str(marker.get("name","the trail"))
	await game.interiors.fade(1)
	game.generator.teleport_logical(int(address.x),int(address.z),ValeSave.vector(address.local))
	game.camp.sync_visual(true)
	await get_tree().physics_frame; await get_tree().physics_frame
	var spot: Variant=safe_spot(game.player.position)
	var success: bool=spot is Vector3
	if success:
		game.player.position=spot; game.player.velocity=Vector3.ZERO; game.player.invulnerability=2
		last_ready={"terrain":true,"collision":true,"chunks":game.generator.active_chunks.size(),"safe_position":game.generator.address(spot)}
	else:
		last_error="No safe landing nearby. You remain at your departure point."
		game.camp.clear_visual(); game.generator.teleport_logical(int(previous.x),int(previous.z),ValeSave.vector(previous.local)); game.camp.sync_visual(true)
		await get_tree().physics_frame; await get_tree().physics_frame
	game.rig.snap()
	game.hud.modal_kind="travel_complete"
	game.hud.close_modal(); await game.interiors.fade(0); busy=false
	State.notification.emit("Arrived at "+str(marker.get("name","the trail")) if success else last_error)
	if success: State.save_requested.emit()
	return success
