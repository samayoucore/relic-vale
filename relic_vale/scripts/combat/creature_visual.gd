class_name ValeCreatureVisual
extends Node3D
## Presentation adapter: imported skinning and authored clips; combat remains on Mossling.
const ROOT="res://assets/3d/phase4/"
const MODELS={"slime":"monsters/Slime.fbx","mimic":"monsters/Slime.fbx","bat":"monsters/Bat.fbx","skeleton":"monsters/Skeleton.fbx","archer":"monsters/Skeleton.fbx","wolf":"animals/Wolf.gltf","witch":"adventurers/Mage.glb","elite":"adventurers/Knight.glb","guardian":"adventurers/Knight.glb","deer":"animals/Deer.gltf","stag":"animals/Stag.gltf","fox":"../phase6/animals/Fox.gltf","cow":"../phase6/animals/Cow.gltf","horse":"../phase6/animals/Horse.gltf","alpaca":"../phase6/animals/Alpaca.gltf"}
var model: Node3D
var animator: AnimationPlayer
var clips: Dictionary={}
var kind: String
var materials: Array[StandardMaterial3D]=[]
var state: String=""

func setup(archetype: String, height: float = 1.55, asset: String="") -> void:
	kind=archetype
	model=load(asset if not asset.is_empty() else ROOT+MODELS[kind]).instantiate()
	add_child(model)
	var bounds: AABB=get_tree().current_scene.world.bounds(model)
	var ratio: float=height/maxf(.01,bounds.size.y)
	model.scale=Vector3.ONE*ratio
	model.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*ratio
	if kind=="bat": position.y=.7
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var source: Material=mesh.get_active_material(i)
			if source is StandardMaterial3D:
				var material: StandardMaterial3D=source.duplicate()
				material.metallic=0
				material.roughness=.9
				if kind=="mimic": material.albedo_color=Color("b17c4e")
				if kind=="guardian": material.albedo_color=Color("b2c0ac")
				mesh.set_surface_override_material(i,material)
				materials.append(material)
	var players: Array=model.find_children("*","AnimationPlayer",true,false)
	if not players.is_empty(): animator=players[0]
	else:
		animator=AnimationPlayer.new()
		model.add_child(animator)
		var rig: Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0]
		var library:=AnimationLibrary.new()
		var packs: Array=[ROOT+"adventurers/Rig_Medium_General.glb",ROOT+"adventurers/Rig_Medium_MovementBasic.glb"]
		if kind=="companion":
			for pack in ["CombatMelee","CombatRanged","Simulation"]: packs.append("res://assets/3d/phase9/animations/Rig_Medium_"+pack+".glb")
		for pack in packs:
			var source: Node=load(pack).instantiate()
			var ap: AnimationPlayer=source.find_children("*","AnimationPlayer",true,false)[0]
			for name in ap.get_animation_list():
				if library.has_animation(name): continue
				var clip: Animation=ap.get_animation(name).duplicate()
				for track in clip.get_track_count():
					var old: NodePath=clip.track_get_path(track)
					clip.track_set_path(track,NodePath(str(model.get_path_to(rig))+":"+str(old.get_subname(0))))
				library.add_animation(name,clip)
			source.free()
		animator.add_animation_library("",library)
	for name in animator.get_animation_list():
		var lower: String=name.to_lower()
		for pair in [["idle",["idle_a","_idle","idle","flying"]],["walk",["walk","running","gallop","flying"]],["attack",["attack","throw","interact"]],["hit",["hit"]],["death",["death_a","death"]],["eat",["eating"]],["sleep",["sleep","lay"]]]:
			if clips.has(pair[0]): continue
			for term in pair[1]:
				if term in lower:
					clips[pair[0]]=name
					if pair[0] in ["idle","walk","eat"]: animator.get_animation(name).loop_mode=Animation.LOOP_LINEAR
					break
	play("idle")

func companion_role(role: String) -> void:
	var animation: String="Melee_1H_Attack_Chop"
	if role=="ranged": animation="Ranged_Bow_Release"
	elif role in ["mage","support"]: animation="Ranged_Magic_Spellcasting"
	if animator.has_animation(animation): clips.attack=animation
	for pair in [["block","Melee_Block"],["rest","Sit_Floor_Idle"],["sleep","Lie_Idle"]]:
		if animator.has_animation(pair[1]): clips[pair[0]]=pair[1]
	for key in ["rest","sleep"]:
		if clips.has(key): animator.get_animation(clips[key]).loop_mode=Animation.LOOP_LINEAR
	var rig: Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0]
	for pair in ([["bow","handslot.l"]] if role=="ranged" else ([["staff","handslot.r"]] if role in ["mage","support"] else [["sword_1handed","handslot.r"],["shield_badge","handslot.l"]])):
		var attachment:=BoneAttachment3D.new(); attachment.bone_name=pair[1]; rig.add_child(attachment)
		var prop: Node3D=load("res://assets/3d/phase9/equipment/"+pair[0]+".gltf").instantiate(); attachment.add_child(prop)

func play(next: String) -> void:
	if next==state: return
	state=next
	var clip: String=clips.get(next,clips.get("idle",""))
	if not clip.is_empty(): animator.play(clip,.12)

func tick(delta: float, moving: Vector3, attack: bool, hit: bool) -> void:
	if moving.length()>.1: rotation.y=lerp_angle(rotation.y,atan2(moving.x,moving.z),minf(1,delta*9))
	play("hit" if hit and clips.has("hit") else ("attack" if attack else ("walk" if moving.length()>.2 else "idle")))
	for material in materials:
		material.emission_enabled=hit
		material.emission=Color("edbca0")
		material.emission_energy_multiplier=.5
