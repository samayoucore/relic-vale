extends Node
## Repeatable transparent item thumbnails from the same imported meshes used in the world.
var view: SubViewport
var stage: Node3D
var camera: Camera3D
var helper: ValeWorld
func _ready() -> void: render.call_deferred()
func render() -> void:
	view=SubViewport.new(); view.size=Vector2i(256,256); view.transparent_bg=true; view.own_world_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	view.msaa_3d=Viewport.MSAA_4X; add_child(view)
	stage=Node3D.new(); view.add_child(stage)
	var env:=WorldEnvironment.new(); var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR; environment.background_color=Color(0,0,0,0)
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; environment.ambient_light_color=Color("dce4d2"); environment.ambient_light_energy=.7
	env.environment=environment; stage.add_child(env)
	var light:=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-45,-25,0); light.light_energy=1.1; stage.add_child(light)
	camera=Camera3D.new(); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=2.3
	stage.add_child(camera); camera.position=Vector3(2,1.6,2.5); camera.look_at(Vector3(0,.5,0)); camera.current=true
	helper=ValeWorld.new()
	DirAccess.make_dir_recursive_absolute("res://assets/ui/phase5/rendered")
	var items: Dictionary={"wood":"res://assets/3d/nature/log.glb","stone":"res://assets/3d/nature/rock_smallA.glb","iron_ore":"res://assets/3d/nature/rock_largeB.glb","wild_herb":"res://assets/3d/phase4/nature/Plant_7.gltf","fiber":"res://assets/3d/phase4/nature/Grass_Common_Short.gltf","mushroom":"res://assets/3d/nature/mushroom_redGroup.glb","crystal":"res://assets/3d/nature/rock_tallA.glb"}
	for id in State.items:
		if State.items[id].kind=="tool": items[id]=State.items[id].model
	for id in items:
		var holder:=Node3D.new(); stage.add_child(holder)
		var model: Node3D=helper.place(items[id],Vector3.ZERO,1.2,15,holder)
		if id=="crystal" or id=="iron_ore":
			for mesh in model.find_children("*","MeshInstance3D",true,false):
				mesh.material_override=helper.mat("7baaba" if id=="crystal" else "777c80")
		var bounds: AABB=helper.bounds(model)
		camera.size=maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))*1.55
		camera.position=Vector3(2,1.8,2.5)+bounds.get_center(); camera.look_at(bounds.get_center())
		for i in 5: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image:=view.get_texture().get_image()
		var used: Rect2i=image.get_used_rect()
		var extent: int=maxi(used.size.x,used.size.y)+16
		var fitted:=Image.create(extent,extent,false,Image.FORMAT_RGBA8)
		fitted.fill(Color.TRANSPARENT); fitted.blit_rect(image,used,Vector2i((extent-used.size.x)/2,(extent-used.size.y)/2))
		fitted.resize(128,128,Image.INTERPOLATE_LANCZOS); image=fitted
		if image.get_used_rect().size==Vector2i.ZERO: push_error("Empty item icon: "+id)
		image.save_png("res://assets/ui/phase5/rendered/"+id+".png")
		print("ICON_RENDERED ",id)
		holder.queue_free(); await get_tree().process_frame
	helper.free()
	await Feel.shutdown()
	get_tree().quit()
