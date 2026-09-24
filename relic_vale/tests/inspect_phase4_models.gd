extends SceneTree
func _initialize() -> void:
	for file in ["monsters/Slime.fbx","monsters/Bat.fbx","monsters/Skeleton.fbx","animals/Wolf.gltf","animals/Deer.gltf","adventurers/Mage.glb","adventurers/Knight.glb","adventurers/Rig_Medium_General.glb","adventurers/Rig_Medium_MovementBasic.glb"]:
		var model: Node=load("res://assets/3d/phase4/"+file).instantiate()
		root.add_child(model)
		print("MODEL ",file)
		for node in model.find_children("*","AnimationPlayer",true,false):
			print(" ANIMS ",node.get_path()," root=",node.root_node," ",node.get_animation_list())
			if node.get_animation_list().size()>0:
				var anim: Animation=node.get_animation(node.get_animation_list()[-1])
				print(" TRACK ",anim.track_get_path(0))
		for node in model.find_children("*","Skeleton3D",true,false): print(" RIG ",node.get_path())
		model.free()
	quit()
