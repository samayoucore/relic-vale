class_name ValeCameraAtmosphere
extends Node

var game: Node
var material: ShaderMaterial
var quad: MeshInstance3D
var fog_end: float=4.0

func _ready() -> void:
	game=get_tree().current_scene
	material=ShaderMaterial.new(); material.shader=preload("res://shaders/camera_atmosphere.gdshader")
	# Draw immediately after opaque scenery; particles and labels draw afterwards.
	material.render_priority=-120
	quad=MeshInstance3D.new(); quad.name="CameraAtmosphere"
	var mesh:=QuadMesh.new(); mesh.size=Vector2(2,2); quad.mesh=mesh
	quad.material_override=material; quad.extra_cull_margin=16384
	quad.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	game.rig.camera.add_child(quad); quad.position.z=-1
	update_effect(0)

func safe_radius() -> float:
	var gen: ValeStreamingGenerator=game.generator
	var point:=Vector2(game.player.position.x,game.player.position.z)
	var center: Vector2i=gen.coord_at(game.player.position)
	# A larger old window may still be retained after lowering draw distance.
	# Keep a finite cap even if every inspected tile is currently present.
	var nearest: float=float(gen.preload_radius*32)
	var radius: int=gen.preload_radius+1
	for x in range(-radius,radius+1):
		for z in range(-radius,radius+1):
			var coord: Vector2i=center+Vector2i(x,z)
			var chunk: Node3D=gen.active_chunks.get(gen.chunk_key(coord))
			if is_instance_valid(chunk) and chunk.visible: continue
			var start:=Vector2(coord)*32
			nearest=minf(nearest,point.distance_to(point.clamp(start,start+Vector2(32,32))))
	return maxf(4,nearest-5)

func update_effect(delta: float) -> void:
	var outside: bool=game.player.position.x<900
	var safe: float=safe_radius() if outside else 100.0
	# Moving inward is immediate so loading holes never become exposed. Revealing
	# newly built chunks is gradual. Floating-origin shifts leave this invariant.
	fog_end=safe if safe<fog_end or delta==0 else move_toward(fog_end,safe,delta*18)
	var hour: float=float(State.life_data.minute)/60
	var daylight: float=smoothstep(5,8,hour)*(1.0-smoothstep(17,21,hour))
	material.set_shader_parameter("outdoors",outside)
	material.set_shader_parameter("focus_position",game.player.global_position)
	material.set_shader_parameter("fog_end",fog_end)
	material.set_shader_parameter("fog_start",fog_end*(.28 if State.life_data.weather=="Fog" else .48))
	material.set_shader_parameter("horizon_color",Color("364f64").lerp(Color("b4cbd1"),daylight))
	material.set_shader_parameter("zenith_color",Color("172b47").lerp(Color("719dbd"),daylight))
	material.set_shader_parameter("focus_distance",game.rig.camera.position.length())
	material.set_shader_parameter("blur_strength",(1.0-smoothstep(22,42,game.rig.pitch)) if outside else 0.0)

func _process(delta: float) -> void: update_effect(delta)
