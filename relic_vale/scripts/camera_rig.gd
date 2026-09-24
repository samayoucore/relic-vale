class_name ValeCamera
extends Node3D

var target: Node3D
var yaw: float = deg_to_rad(42.0)
var target_yaw: float = yaw
var zoom: float = 24.0
var target_zoom: float = 24.0
var pitch: float=50.0
var target_pitch: float=50.0
const MIN_PITCH: float=18.0
const MAX_PITCH: float=60.0
const FIELD_OF_VIEW: float=50.0
var camera: Camera3D
var obstruction_time: float = 0
var faded: Array[Dictionary] = []
var impulse_strength: float=0

func impulse(strength: float) -> void:
	if not Preferences.values.screen_shake: return
	impulse_strength=minf(.14,maxf(impulse_strength,strength))

func _ready() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = FIELD_OF_VIEW
	camera.near = .1
	camera.far = 360
	add_child(camera)
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if State.modal or State.paused: return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		target_yaw -= event.relative.x * .006
		target_pitch=clampf(target_pitch-event.relative.y*.1,MIN_PITCH,MAX_PITCH)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: target_zoom = clampf(target_zoom-1.5,12,32)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: target_zoom = clampf(target_zoom+1.5,12,32)
	if event.is_action_pressed("camera_reset"):
		target_yaw = deg_to_rad(42)
		target_zoom = 24
		target_pitch=50

func _process(delta: float) -> void:
	if not is_instance_valid(target): return
	if not State.modal and not State.paused:
		target_yaw += (Input.get_action_strength("rotate_left")-Input.get_action_strength("rotate_right"))*delta*1.6
		if Input.is_physical_key_pressed(KEY_ALT) and Input.is_physical_key_pressed(KEY_E): target_yaw-=delta*1.6
		var lift: float=float(Input.is_physical_key_pressed(KEY_PAGEUP))-float(Input.is_physical_key_pressed(KEY_PAGEDOWN))
		target_pitch=clampf(target_pitch+lift*delta*16,MIN_PITCH,MAX_PITCH)
	yaw = lerp(yaw,target_yaw,1.0-exp(-delta*12))
	zoom = lerp(zoom,target_zoom,1.0-exp(-delta*10))
	pitch=lerpf(pitch,target_pitch,1-exp(-delta*10))
	var focus: Vector3=target.global_position+Vector3(0,.65,0)
	if target.global_position.x>2900:
		focus=Vector3(clampf(focus.x,2998.5,3001.5),.65,clampf(focus.z,-1,1))
		target_zoom=clampf(target_zoom,12,18)
	global_position = global_position.lerp(focus,1.0-exp(-delta*9))
	rotation.y = yaw
	update_pose()
	impulse_strength=move_toward(impulse_strength,0,delta*.65)
	if impulse_strength>0: camera.position+=Vector3(sin(Time.get_ticks_msec()*.08),cos(Time.get_ticks_msec()*.07),0)*impulse_strength
	obstruction_time-=delta
	if obstruction_time<=0:
		obstruction_time=.12
		update_obstructions()

func update_pose() -> void:
	var mount_service: ValeMounts=get_tree().current_scene.mounts
	var framing: float=zoom+(mount_service.camera_extra if is_instance_valid(mount_service) else 0.0)
	# Preserve the world-space height of the old framing at the hero's focus plane.
	var distance: float=framing/(2*tan(deg_to_rad(FIELD_OF_VIEW*.5)))
	var view_pitch: float=maxf(pitch,40.0) if target.global_position.x>900 else pitch
	camera.position=Vector3(0,sin(deg_to_rad(view_pitch))*distance,cos(deg_to_rad(view_pitch))*distance)
	camera.rotation_degrees.x=-view_pitch

func update_obstructions() -> void:
	for record in faded:
		var visual: Node3D=record.node.get_ref()
		if is_instance_valid(visual): visual.visible=record.visible and not visual.get_meta("depleted",false)
	faded.clear()
	if not is_instance_valid(target): return
	var eye: Vector3=camera.global_position
	# Only the eye's containment matters. A tree in front of the hero remains
	# scenery; the depth effect softens the near foreground without hiding it.
	for visual in get_tree().get_nodes_in_group("camera_occluders"):
		if not visual is Node3D or not visual.is_visible_in_tree(): continue
		if visual.global_position.distance_squared_to(eye)>1600: continue
		if contains_eye(visual,eye): fade_visual(visual)
	if target is ValePlayer: target.sprite.no_depth_test=false

func contains_eye(node: Node3D, eye: Vector3) -> bool:
	if node is MeshInstance3D and node.mesh:
		var inverse: Transform3D=node.global_transform.affine_inverse()
		var local_eye: Vector3=inverse*eye
		if node.get_aabb().has_point(local_eye) and inside_surface(node,local_eye): return true
	for child in node.get_children():
		if child is Node3D and contains_eye(child,eye): return true
	return false

func inside_surface(node: MeshInstance3D, point: Vector3) -> bool:
	# Bounds are only a broad phase: canopy corners often contain empty air.
	# Odd ray crossings identify the mesh volume. Cache triangles on the visual
	# so unloaded chunks release them, and count shared triangle edges once.
	if not node.has_meta("camera_faces"): node.set_meta("camera_faces",node.mesh.get_faces())
	var faces: PackedVector3Array=node.get_meta("camera_faces")
	var direction:=Vector3(1,.371,.529).normalized()
	var crossings: Array[float]=[]
	for index in range(0,faces.size(),3):
		var hit: Variant=Geometry3D.ray_intersects_triangle(point,direction,faces[index],faces[index+1],faces[index+2])
		if hit==null: continue
		var distance: float=point.distance_to(hit)
		if distance<.0001: return true
		var duplicate: bool=false
		for previous in crossings:
			if absf(previous-distance)<.0001: duplicate=true; break
		if not duplicate: crossings.append(distance)
	return crossings.size()%2==1

func fade_visual(node: Node3D) -> void:
	for record in faded:
		if record.node.get_ref()==node: return
	if not node.visible: return
	faded.append({"node":weakref(node),"visible":node.visible})
	node.visible=false

func _exit_tree() -> void:
	for record in faded:
		var visual: Node3D=record.node.get_ref()
		if is_instance_valid(visual): visual.visible=record.visible and not visual.get_meta("depleted",false)

func snap() -> void:
	global_position = target.global_position + Vector3(0,.65,0)
	rotation.y=yaw
	update_pose()

func screen_direction(world_direction: Vector3) -> int:
	var relative: Vector3 = world_direction.rotated(Vector3.UP,-yaw)
	if absf(relative.x)>absf(relative.z): return 3 if relative.x>0 else 1
	return 2 if relative.z>0 else 0
