class_name ValeInteractable
extends Node3D

@export var kind: String = "npc"
@export var title: String = "Rowan"
@export var persistent_id: String = ""
@export var npc_id: String="rowan"
var marker: Label3D
var model: Node3D
var opened: bool = false
var pulse: float = 0
var sprite: AnimatedSprite3D

func synchronize() -> void:
	opened=State.flags.chest if kind=="chest" else State.opened_chests.has(persistent_id)
	if is_instance_valid(model):
		if kind=="moonseed": model.visible=not State.flags.moonseed
		if kind=="resource" and model is Sprite3D: model.modulate=Color("7a8065") if State.gathered_resources.has(persistent_id) else Color.WHITE
		var lid:=model.find_child("chest_lid",true,false) as Node3D
		if lid: lid.rotation.x=deg_to_rad(-105) if opened else 0.0

func _ready() -> void:
	add_to_group("interactables")
	marker=Label3D.new()
	marker.text=title
	marker.position.y=2.9 if kind=="npc" else 1.65
	marker.font_size=40
	marker.pixel_size=.013
	marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	marker.outline_size=5
	marker.modulate=Color("ede1ba")
	add_child(marker)
	marker.visible=false # Crisp native-resolution nameplate is projected by Nameplates.
	if kind=="npc":
		sprite=AnimatedSprite3D.new()
		sprite.sprite_frames=PixelArt.character_frames(true)
		sprite.pixel_size=.037
		sprite.position.y=1.04
		sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
		add_child(sprite)
		sprite.play("idle_2")
		PixelArt.add_shadow(self,.5)

func _process(_delta: float) -> void:
	if not is_instance_valid(sprite): return
	var camera:=get_viewport().get_camera_3d()
	if camera: sprite.position=camera.global_basis.y*(30.0*sprite.pixel_size)+Vector3(0,.03,0)

func prompt() -> String:
	if has_meta("world_event"): return get_tree().current_scene.world_events.data_name(State.life_data.events[get_meta("world_event")])
	if has_meta("story_object"): return title
	if has_meta("companion"):
		return ("Help " if get_parent().downed else "Talk to ")+title
	if has_meta("phase8_action"):
		if get_meta("phase8_action")=="plot": return get_tree().current_scene.cultivation.prompt(get_meta("plot"))
		return "Mount Bramble · E" if get_meta("phase8_action")=="mount" else title+" · E"
	if has_meta("camp_action"): return "Meet "+title if kind=="npc" else title
	match kind:
		"building": return "Enter "+title
		"building_exit": return "Leave the building"
		"storage": return "Open household storage"
		"npc": return "Talk to "+State.npc_data.get(npc_id,{}).get("name",title)
		"chest": return "Search the chest" if not State.flags.chest else "Chest opened"
		"shrine": return "Touch the wishing stone"
		"entrance": return "Enter Forgotten Crypt"
		"exit": return "Return to Mossfall Wood"
		"moonseed": return "Take the moonseed" if not State.flags.moonseed else "An empty pedestal"
		"cache": return "Open explorer's cache" if not State.opened_chests.has(persistent_id) else "Cache opened"
		"resource": return "Gather "+title if not State.gathered_resources.has(persistent_id) else title+" gathered"
		"station": return "Use "+title
		"dungeon": return "Enter "+title
	return "Interact"

func interact(player: ValePlayer) -> void:
	if has_meta("world_event"):
		get_tree().current_scene.world_events.interact(get_meta("world_event")); return
	if has_meta("story_object"):
		get_tree().current_scene.narrative.inspect_object(get_meta("story_location"),get_meta("story_object")); return
	if has_meta("companion"):
		if get_parent().downed: get_parent().revive()
		else: State.talk_npc(get_meta("companion"))
		return
	if has_meta("phase8_action"):
		var game: Node=get_tree().current_scene
		match get_meta("phase8_action"):
			"plot": game.cultivation.interact(get_meta("plot"))
			"mount": game.mounts.mount()
			"stable": ValeProfessionPages.show(game.hud.ui,"Mounts")
			"treasure": game.exploration.claim(get_meta("treasure"))
		return
	if has_meta("camp_action"):
		var ui: ValeInterface=get_tree().current_scene.hud.ui
		if get_meta("camp_action")=="Candidate": ValeCampUI.candidate(ui)
		else: ValeCampUI.show(ui,get_meta("camp_action"))
		return
	match kind:
		"building": get_tree().current_scene.interiors.enter(get_meta("building"))
		"building_exit": get_tree().current_scene.interiors.leave()
		"storage": ValeStorage.show(get_tree().current_scene.hud.ui,persistent_id)
		"npc":
			State.talk_npc(npc_id)
			if State.npc_data.get(npc_id,{}).get("shop",false): get_tree().current_scene.hud.rpg.add_trade_button(npc_id)
		"station": ValeLifeMenus.open_crafting(get_tree().current_scene.hud,self)
		"dungeon": get_tree().current_scene.expedition.enter(persistent_id,get_meta("theme","crypt"))
		"chest":
			if State.open_chest():
				opened=true
				marker.text="Supplies claimed"
				if is_instance_valid(model):
					var lid:=model.find_child("chest_lid",true,false) as Node3D
					if lid: create_tween().tween_property(lid,"rotation:x",deg_to_rad(-105),.55).set_trans(Tween.TRANS_BACK)
		"shrine": State.visit_shrine()
		"entrance":
			State.flags.crypt=true
			State.quest_event("reach","crypt")
			State.dungeon_return=player.global_position
			player.global_position=Vector3(1000,0,6.3)
			player.velocity=Vector3.ZERO
			player.camera_rig.snap()
			State.notification.emit("FORGOTTEN CRYPT  ·  Three chambers beneath the roots.")
			State.changed.emit()
		"exit":
			player.global_position=State.dungeon_return
			get_tree().current_scene.generator.update_streaming(true)
			player.velocity=Vector3.ZERO
			player.camera_rig.snap()
		"moonseed":
			if State.flags.moonseed: return
			State.flags.moonseed=true
			State.add_item("moonseed")
			if is_instance_valid(model): model.visible=false
			marker.text="The light is yours"
			State.conversation.emit("A seed of silver light", "A small, impossible thing grows among the old stones. You tuck the moonseed safely into your satchel.\n\nReturn it to Rowan in Willowmere. The stairway behind you leads home.")
		"cache":
			if State.opened_chests.has(persistent_id):
				State.notification.emit("You have already searched this cache.")
				return
			if has_meta("requires") and not State.defeated_unique.has(get_meta("requires")):
				State.notification.emit("The Cryptwarden's oath still seals this chest.")
				return
			State.opened_chests[persistent_id]=true
			var rng:=RandomNumberGenerator.new()
			rng.seed=persistent_id.hash()
			State.notification.emit("Cache opened  ·  "+ValeLoot.grant(ValeLoot.prepare(ValeLoot.roll(get_meta("loot_table","cache"),rng),rng)))
			opened=true
			synchronize()
			State.save_requested.emit()
		"resource":
			if State.gathered_resources.has(persistent_id): return
			State.gathered_resources[persistent_id]=true
			var item: String=get_meta("resource","wild_herb")
			var amount: int=2 if item=="wild_herb" and State.life_data.weather=="Rain" else 1
			State.add_item(item,amount)
			State.notification.emit(title+" gathered  ·  +"+str(amount))
			if is_instance_valid(model): model.scale*=.65
			State.save_requested.emit()
			if model is Sprite3D: model.modulate=Color("7a8065")
