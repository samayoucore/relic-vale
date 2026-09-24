extends Node
func _ready() -> void: render.call_deferred()
func render() -> void:
	var game: Node=get_tree().current_scene
	var viewport:=SubViewport.new(); viewport.size=Vector2i(96,96); viewport.own_world_3d=true; viewport.transparent_bg=true; viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; viewport.msaa_3d=Viewport.MSAA_4X; add_child(viewport)
	var root:=Node3D.new(); viewport.add_child(root)
	var camera:=Camera3D.new(); root.add_child(camera); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=2.0; camera.position=Vector3(2,1.2,3); camera.look_at(Vector3.ZERO); camera.current=true
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-40,-30,0); sun.light_energy=1.25; root.add_child(sun)
	var fill:=DirectionalLight3D.new(); fill.rotation_degrees=Vector3(-25,140,0); fill.light_energy=.5; root.add_child(fill)
	var environment:=WorldEnvironment.new(); var env:=Environment.new(); env.background_mode=Environment.BG_COLOR; env.background_color=Color(0,0,0,0); env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("ddd9c6"); env.ambient_light_energy=.55; environment.environment=env; root.add_child(environment)
	DirAccess.make_dir_recursive_absolute("res://assets/ui/phase8/icons")
	var count: int=0
	for id in State.items:
		var path: String=State.items[id].get("model","")
		if not "phase8" in path: continue
		var model: Node3D=load(path).instantiate(); root.add_child(model)
		for animator in model.find_children("*","AnimationPlayer",true,false):
			for clip in animator.get_animation_list():
				if "Swimming_Normal" in clip: animator.play(clip); animator.advance(.1); break
		var bounds: AABB=game.world.bounds(model)
		var ratio: float=1.5/maxf(.001,maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z)))
		model.scale=Vector3.ONE*ratio; model.position=-bounds.get_center()*ratio
		for i in 3: await get_tree().process_frame
		RenderingServer.force_draw(false)
		viewport.get_texture().get_image().save_png("res://assets/ui/phase8/icons/"+id+".png")
		root.remove_child(model); model.queue_free(); count+=1
	print("PHASE8_ICONS ",count)
	await Feel.shutdown(); get_tree().quit()
