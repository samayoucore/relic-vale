class_name ValeGraphics
extends Node
var game: Node
var last: Dictionary={}
var count_clock: float=0
var foliage_instances: int=0
var particle_count: int=0

func _ready() -> void:
	game=get_tree().current_scene
	Preferences.changed.connect(apply)
	get_tree().node_added.connect(func(node):
		if node is GeometryInstance3D or node is CPUParticles3D: prepare_added.call_deferred(weakref(node)))
	get_viewport().size_changed.connect(apply_resolution)
	apply()

func apply_resolution() -> void:
	var p: Dictionary=Preferences.values
	var actual: Vector2i=DisplayServer.window_get_size()
	if DisplayServer.get_name()=="headless": actual=p.resolution
	var factor: float=p.render_scale
	if p.pixelated: factor=minf(factor,[.6,.45,.3][int(p.pixel_strength)])
	game.viewport.size=Vector2i(maxi(320,roundi(actual.x*factor)),maxi(180,roundi(actual.y*factor)))
	game.viewport.msaa_3d=Viewport.MSAA_DISABLED if p.pixelated or int(p.shadows)==0 else (Viewport.MSAA_4X if int(p.shadows)>1 else Viewport.MSAA_2X)
	game.screen.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST if p.pixelated else CanvasItem.TEXTURE_FILTER_LINEAR
	game.pixel_mode=p.pixelated

func apply() -> void:
	var p: Dictionary=Preferences.values
	if DisplayServer.get_name()!="headless":
		if last.get("display","")!=p.display:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if p.display=="Fullscreen" else DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,p.display=="Borderless")
		if last.get("resolution",Vector2i.ZERO)!=p.resolution and p.display!="Fullscreen": DisplayServer.window_set_size(p.resolution)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if p.vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=int(p.fps_limit)
	apply_resolution()
	RenderingServer.directional_shadow_atlas_set_size([1024,2048,4096,8192][int(p.shadows)],true)
	# Everything beyond this distance is fully hidden by streaming haze.
	game.world.sun.directional_shadow_max_distance=[60.0,64.0,92.0,96.0][int(p.distance)]
	game.world.sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if int(p.shadows)<2 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	var environment: Environment=game.world.environment
	environment.fog_enabled=true
	environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	environment.tonemap_exposure=1.0
	# These effects are not supported in the bundled OpenGL Compatibility renderer.
	var forward: bool=RenderingServer.get_current_rendering_method()=="forward_plus"
	environment.ssao_enabled=forward and p.ao
	environment.ssil_enabled=forward and int(p.shadows)>2
	environment.ssr_enabled=forward and int(p.water)>1
	environment.volumetric_fog_enabled=forward and int(p.fog)>1
	RenderingServer.global_shader_parameter_set("vale_quality",float(p.water))
	game.generator.preload_radius=3 if int(p.distance)>1 else 2
	game.generator.unload_radius=game.generator.preload_radius+1
	game.generator.last_center=""
	for node in game.world.find_children("*","GeometryInstance3D",true,false): prepare_node(node)
	for node in game.world.find_children("*","CPUParticles3D",true,false): prepare_node(node)
	for bus in ["Master","Music","SFX"]: Feel.volume(bus,float(p[bus]))
	last=p.duplicate(true)

func prepare_added(reference: WeakRef) -> void:
	var node: Node=reference.get_ref()
	if is_instance_valid(node): prepare_node(node)

func prepare_node(node: Node) -> void:
	if not is_instance_valid(node): return
	var p: Dictionary=Preferences.values
	if node is MultiMeshInstance3D and node.multimesh:
		if not node.has_meta("decorative_foliage"): return
		node.multimesh.visible_instance_count=maxi(1,roundi(node.multimesh.instance_count*float(p.foliage)))
		node.visibility_range_end=[118.0,135.0,155.0,175.0][int(p.distance)]
		node.visibility_range_end_margin=10
	if node is CPUParticles3D:
		node.add_to_group("vale_particles")
		if not node.has_meta("base_amount"): node.set_meta("base_amount",node.amount)
		node.amount=maxi(4,roundi(int(node.get_meta("base_amount"))*float(p.particles)))
	if node is MeshInstance3D and node.is_in_group("camera_occluders"):
		node.visibility_range_end=[150.0,170.0,190.0,210.0][int(p.distance)]

func _process(delta: float) -> void:
	var origin:=Vector3((game.generator.origin_x%32)*32,0,(game.generator.origin_z%32)*32)
	RenderingServer.global_shader_parameter_set("vale_origin",origin)
	RenderingServer.global_shader_parameter_set("vale_player",game.player.global_position)
	RenderingServer.global_shader_parameter_set("vale_wetness",game.life.blend if game.player.position.x<900 else 0.0)
	RenderingServer.global_shader_parameter_set("vale_wind",2.0 if State.life_data.weather=="Storm" else 1.0)
	count_clock-=delta
	if not OS.is_debug_build(): return
	if count_clock>0: return
	count_clock=1
	foliage_instances=0; particle_count=0
	for node in get_tree().get_nodes_in_group("foliage_batches"):
		if is_instance_valid(node) and node.is_visible_in_tree(): foliage_instances+=node.multimesh.visible_instance_count
	for node in get_tree().get_nodes_in_group("vale_particles"):
		if node.emitting: particle_count+=node.amount
