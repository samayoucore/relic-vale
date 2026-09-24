class_name ValeGathering
extends Node3D
## LPC hand adapter: an imported tool follows the directional sprite's hand through a timed swing.
var actor: ValePlayer
var hand: Node3D
var tool_model: Node3D
var equipped_id: String=""
var target: ValeResource
var busy: bool=false
var elapsed: float=0
var struck: bool=false
var selected_tool: Dictionary={}
const DURATION: float=.85
const IMPACT: float=.42

func _ready() -> void:
	actor=get_parent()
	hand=Node3D.new(); add_child(hand)
	State.changed.connect(refresh_tool)
	refresh_tool()

func refresh_tool() -> void:
	var id: String=State.equipment.get("Tool","")
	if id==equipped_id: return
	cancel(); equipped_id=id
	if is_instance_valid(tool_model): tool_model.queue_free(); tool_model=null
	if id.is_empty(): return
	var item: Dictionary=State.items[id]
	tool_model=load(item.model).instantiate(); hand.add_child(tool_model)
	var bounds: AABB=get_tree().current_scene.world.bounds(tool_model)
	var height: float=1.75 if item.get("tool","")=="rod" else (.55 if item.get("tool","")=="watering" else 1.08)
	var ratio: float=height/maxf(bounds.size.y,.01)
	tool_model.scale=Vector3.ONE*ratio
	tool_model.position=-Vector3(bounds.get_center().x,bounds.position.y+bounds.size.y*.24,bounds.get_center().z)*ratio
	# Tier colour is a material tint on the original imported mesh, never replacement geometry.
	if int(item.tier)>1:
		for mesh in tool_model.find_children("*","MeshInstance3D",true,false):
			for i in mesh.mesh.get_surface_count():
				var source: Material=mesh.get_active_material(i)
				if source is StandardMaterial3D:
					var material: StandardMaterial3D=source.duplicate(); material.albedo_color=Color("afc3ca") if int(item.tier)==3 else Color("999eac"); mesh.set_surface_override_material(i,material)

func start(node: ValeResource) -> bool:
	if actor.life_busy() or get_tree().current_scene.mounts.mounted: return false
	if busy or actor.attack_timer>0 or State.modal or State.paused or actor.statuses.has("stun") or not is_instance_valid(node) or node.remaining()<=0: return false
	if actor.global_position.distance_to(node.global_position)>2.4: return false
	selected_tool=State.items.get(State.equipment.get("Tool",""),{}).duplicate()
	var required: String=node.definition.get("tool","")
	if not required.is_empty() and selected_tool.get("tool","")!=required:
		State.notification.emit("Equip an "+required+" in your satchel (I). Bram sells gathering tools.")
		return false
	if required.is_empty(): selected_tool={}
	var reason: String=ValeProfessions.gathering_error(node.definition,selected_tool)
	if not reason.is_empty(): State.notification.emit(reason); return false
	target=node; busy=true; elapsed=0; struck=false
	actor.facing=(node.global_position-actor.global_position).normalized(); actor.facing.y=0
	actor.attack_timer=DURATION
	actor.sprite.play("slash_%d" % actor.camera_rig.screen_direction(actor.facing)); actor.sprite.speed_scale=.8
	return true

func cancel() -> void:
	busy=false; target=null; elapsed=0
	if is_instance_valid(actor): actor.attack_timer=0; actor.sprite.speed_scale=1

func _process(delta: float) -> void:
	if not is_instance_valid(actor.camera_rig): return
	var camera: Camera3D=actor.camera_rig.camera
	var side: float=-1 if actor.camera_rig.screen_direction(actor.facing)==1 else 1
	var angle: float=-.25
	if busy:
		if State.modal or State.paused or actor.statuses.has("stun") or not is_instance_valid(target) or actor.global_position.distance_to(target.global_position)>2.6:
			cancel()
		else:
			elapsed+=delta*ValeProfessions.gather_speed(target.definition.profession)
			angle=lerpf(-.25,.9,elapsed/.3) if elapsed<.3 else (lerpf(.9,-1.5,(elapsed-.3)/.12) if elapsed<IMPACT else lerpf(-1.5,-.25,clampf((elapsed-IMPACT)/(DURATION-IMPACT),0,1)))
			if elapsed>=IMPACT and not struck: struck=true; target.impact(selected_tool)
			if elapsed>=DURATION:
				var next: ValeResource=target; cancel()
				if Input.is_action_pressed("interact") and is_instance_valid(next): start(next)
	global_basis=camera.global_basis
	global_position=actor.global_position+camera.global_basis.y*.87+camera.global_basis.x*(.31*side)+camera.global_basis.z*.08
	hand.rotation.z=angle*side
	hand.visible=not equipped_id.is_empty() and actor.attack_timer<=0 or busy and not selected_tool.is_empty()
	var game: Node=get_tree().current_scene
	if is_instance_valid(game.mounts) and game.mounts.mounted: hand.visible=false
	elif is_instance_valid(game.cultivation) and game.cultivation.busy():
		var task: Dictionary=game.cultivation.action
		var clip: String={"water":"Farm_Watering","plant":"Farm_PlantSeed","harvest":"Farm_Harvest","prepare":"Farm_Harvest"}[task.id]
		hand.rotation.z=ValeProfessions.tool_motion(clip,game.cultivation.action_elapsed/1.2)*side
		hand.visible=task.id=="water"
	elif is_instance_valid(game.fishing) and game.fishing.busy():
		hand.visible=true
		hand.rotation.z=(ValeProfessions.tool_motion("OverhandThrow",game.fishing.elapsed/.75) if game.fishing.state=="casting" else -.45+sin(game.fishing.elapsed*4)*.04)*side
	if is_instance_valid(actor.weapon_sprite): actor.weapon_sprite.visible=not hand.visible and not busy and not actor.life_busy() and not game.mounts.mounted and not State.equipment.Weapon.is_empty()
