class_name ValeResource
extends ValeInteractable
## A harvestable owns its actual scenery, collision and depletion remnant.
var resource_id: String="wood"
var definition: Dictionary={}
var body: StaticBody3D
var remnant: Node3D
var max_hits: int=3
var original_scale:=Vector3.ONE
var refresh_clock: float=0
var shake: Tween

static func spawn(world: ValeWorld,parent: Node3D,id: String,item: String,pos: Vector3,asset: String,height: float,yaw: float=0,tree: bool=false) -> ValeResource:
	var node:=ValeResource.new()
	node.kind="resource"; node.persistent_id=id; node.resource_id=item
	node.set_meta("resource",item); node.set_meta("tree",tree)
	node.title=("Timber tree" if tree else State.items[item].name)
	node.position=pos; parent.add_child(node)
	node.definition=State.resource_data[item]
	node.max_hits=int(node.definition.hits)+(2 if tree and height>4 else 0)
	node.model=world.place(asset,Vector3.ZERO,height,yaw,node)
	node.original_scale=node.model.scale
	if item in ["iron_ore","crystal"]:
		for mesh in node.model.find_children("*","MeshInstance3D",true,false): mesh.material_override=world.mat("737a82" if item=="iron_ore" else "77b6c4")
		# Embedded chunks of the same imported rock family identify a natural deposit.
		for i in 3:
			var vein:=world.place(world.NATURE+"rock_smallA.glb",Vector3((i-1)*height*.2,height*(.38+.1*(i%2)),height*.22),height*.19,i*37,node.model)
			for mesh in vein.find_children("*","MeshInstance3D",true,false): mesh.material_override=world.mat("af9573" if item=="iron_ore" else "97c9cb")
	if tree or node.definition.tool=="pickaxe":
		node.body=world.solid(Vector3(0,.6,0),Vector3(.7,1.2,.7),node,node.model)
	if tree:
		node.remnant=world.place(world.NATURE+"log.glb",Vector3.ZERO,.35,90,node)
	elif node.definition.tool=="pickaxe":
		node.remnant=world.place(world.NATURE+"rock_smallA.glb",Vector3.ZERO,.16,yaw,node)
	node.synchronize()
	return node

func remaining() -> int:
	var record: Dictionary=State.resource_states.get(persistent_id,{})
	if record.is_empty() and State.gathered_resources.has(persistent_id): return 0
	if int(record.get("respawn_day",0))>0 and int(State.life_data.day)>=int(record.respawn_day):
		State.resource_states.erase(persistent_id); State.gathered_resources.erase(persistent_id)
		return max_hits
	return int(record.get("hits",max_hits))

func synchronize() -> void:
	if not is_instance_valid(model): return
	var depleted: bool=remaining()<=0
	# Keep the wrapper visible: the camera may temporarily hide only its model.
	model.visible=not depleted
	model.set_meta("depleted",depleted)
	if depleted: model.remove_from_group("camera_occluders")
	elif is_instance_valid(body): model.add_to_group("camera_occluders")
	if is_instance_valid(remnant): remnant.visible=depleted
	if is_instance_valid(body): body.collision_layer=0 if depleted else 1

func _process(delta: float) -> void:
	refresh_clock-=delta
	if refresh_clock<=0:
		refresh_clock=2
		if State.resource_states.has(persistent_id) and int(State.resource_states[persistent_id].get("respawn_day",0))>0 and int(State.life_data.day)>=int(State.resource_states[persistent_id].respawn_day): synchronize()

func prompt() -> String:
	if remaining()<=0: return title+" · depleted"
	var reason: String=ValeProfessions.gathering_error(definition,State.items.get(State.equipment.get("Tool",""),{}))
	if not reason.is_empty(): return title+" · "+reason
	return ("Chop " if definition.get("tool","")=="axe" else ("Mine " if definition.get("tool","")=="pickaxe" else "Gather "))+title+" · %d/%d · hold E" % [remaining(),max_hits]

func interact(player: ValePlayer) -> void:
	player.gathering.start(self)

func impact(tool: Dictionary) -> void:
	if remaining()<=0: return
	if not ValeProfessions.gathering_error(definition,tool).is_empty(): return
	var hits: int=maxi(0,remaining()-int(tool.get("gather_power",1)))
	State.resource_states[persistent_id]={"hits":hits,"respawn_day":int(State.life_data.day)+int(definition.respawn_days) if hits==0 and int(definition.respawn_days)>0 else 0}
	Feel.sound("wood_hit" if definition.tool=="axe" else ("stone_hit" if definition.tool=="pickaxe" else "plant_pick"),.55,randf_range(.92,1.08))
	Feel.burst(get_parent(),global_position+Vector3(0,.8,0),Color(definition.color),6)
	if shake and shake.is_running(): shake.kill()
	model.rotation.z=0
	shake=create_tween(); shake.tween_property(model,"rotation:z",.035,.06); shake.tween_property(model,"rotation:z",0.0,.16)
	if hits==0:
		State.gathered_resources[persistent_id]=true
		var rng:=RandomNumberGenerator.new(); rng.seed=(persistent_id+"/"+str(State.life_data.day)).hash()
		var amount: int=rng.randi_range(int(definition.yield_min),int(definition.yield_max))+int(tool.get("yield_bonus",0))
		amount+=ValeProfessions.yield_bonus(definition.profession,rng)
		State.add_item(resource_id,amount)
		if definition.profession=="woodcutting" and ValeProfessions.level("woodcutting")>=10 and rng.randf()<.12: State.add_item("resin")
		ValeProfessions.award(definition.profession,int(definition.xp))
		State.notification.emit("+%d %s" % [amount,State.items[resource_id].name])
		var label:=Label3D.new(); label.text="+%d %s" % [amount,State.items[resource_id].name]
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.font_size=32; label.pixel_size=.014; label.no_depth_test=true
		get_parent().add_child(label); label.position=position+Vector3(0,1.8,0)
		var rise:=label.create_tween(); rise.tween_property(label,"position:y",label.position.y+1,1.2); rise.tween_callback(label.queue_free)
		synchronize()
	State.save_requested.emit()
