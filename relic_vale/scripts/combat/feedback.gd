extends Node
## Shared, bounded audio and short-lived visual feedback; the established renderer stays intact.
var voices: Array[AudioStreamPlayer]=[]
var music: AudioStreamPlayer
var previous_music: AudioStreamPlayer
var music_transition: Tween
var voice_index: int=0
var tracks: Dictionary={}
var samples: Dictionary={}
var current_track: String=""
var clock: float=0
var shutting_down: bool=false

func shutdown() -> void:
	shutting_down=true
	var game=get_tree().current_scene
	if is_instance_valid(game) and is_instance_valid(game.get("life")): game.life.stop_audio()
	music.stop()
	music.stream=null
	previous_music.stop(); previous_music.stream=null
	for voice in voices:
		voice.stop()
		voice.stream=null
	# Give the audio mixer a complete buffer after stopping before resources are freed.
	await get_tree().process_frame
	OS.delay_msec(250)
	await get_tree().create_timer(.3).timeout

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream=null
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream=null
	samples.clear()
	tracks.clear()

func _ready() -> void:
	var limiter:=AudioEffectLimiter.new()
	limiter.ceiling_db=-.8
	AudioServer.add_bus_effect(0,limiter)
	for name in ["SFX","Music"]:
		if AudioServer.get_bus_index(name)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,name)
			AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")
	for i in 16:
		var voice:=AudioStreamPlayer.new()
		voice.bus="SFX"
		add_child(voice)
		voices.append(voice)
	music=AudioStreamPlayer.new()
	music.bus="Music"
	add_child(music)
	previous_music=AudioStreamPlayer.new(); previous_music.bus="Music"; add_child(previous_music)
	music.finished.connect(func():
		if not shutting_down: music.play())
	var mappings: Dictionary={"step":"footstep00.ogg","swing":"knifeSlice.ogg","heavy":"knifeSlice2.ogg","hit":"chop.ogg","draw":"drawKnife1.ogg","dodge":"cloth1.ogg","loot":"handleCoins.ogg","click":"metalClick.ogg","chest":"creak1.ogg","open":"bookOpen.ogg"}
	mappings.merge({"wood_hit":"chop.ogg","stone_hit":"metalClick.ogg","plant_pick":"cloth1.ogg"})
	for id in mappings: samples[id]=load("res://assets/audio/"+mappings[id])
	for id in ["wood_hit_01","wood_03","stones_01","metal_hit_01","glass_01","door_01","footstep_wood_01","loop_water_01","hoof"]: samples[id]=load("res://assets/audio/phase6/"+id+".ogg")
	samples.animal_cow=load("res://assets/audio/phase6/Mudchute_cow_1.ogg")
	samples.wood_hit=samples.wood_hit_01; samples.stone_hit=samples.stones_01
	for id in ["spell","bow","critical","heal","level","shrine","hurt","death","slam"]: samples[id]=load("res://assets/audio/"+id+".wav")
	for id in ["vale","crypt","boss"]: tracks[id]=load("res://assets/audio/"+id+"_music.wav")
	for bus in State.audio_settings: volume(bus,State.audio_settings[bus])

func volume(bus: String, value: float) -> void:
	State.audio_settings[bus]=clampf(value,0,1)
	var index: int=AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(index,linear_to_db(maxf(.0001,value)))
	AudioServer.set_bus_mute(index,value<=.001)

func sound(id: String, gain: float = 1.0, pitch: float = 1.0) -> void:
	if shutting_down: return
	if not samples.has(id): return
	var voice: AudioStreamPlayer=voices[voice_index]
	voice_index=(voice_index+1)%voices.size()
	voice.stream=samples[id]
	voice.volume_db=linear_to_db(maxf(.001,gain))
	voice.pitch_scale=pitch
	voice.play()

func _process(delta: float) -> void:
	if shutting_down: return
	clock-=delta
	if clock>0: return
	clock=.5
	var player:=get_tree().get_first_node_in_group("player") as ValePlayer
	if not player: return
	var desired: String="crypt" if player.position.x>900 and player.position.x<2900 else "vale"
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.archetype=="guardian" and enemy.global_position.distance_to(player.global_position)<15: desired="boss"
	if desired!=current_track:
		current_track=desired
		if music_transition and music_transition.is_valid(): music_transition.kill()
		previous_music.stop()
		if music.playing:
			previous_music.stream=music.stream; previous_music.volume_db=music.volume_db
			previous_music.play(music.get_playback_position())
		music.stream=tracks[desired]
		music.volume_db=-40
		music.play()
		music_transition=create_tween().set_parallel(true)
		music_transition.tween_property(music,"volume_db",0.0,1.2)
		music_transition.tween_property(previous_music,"volume_db",-40.0,1.2)
		music_transition.chain().tween_callback(previous_music.stop)

func ring(parent: Node3D, pos: Vector3, radius: float, color: Color, duration: float = .35, filled: bool = false) -> MeshInstance3D:
	var mesh:=ImmediateMesh.new()
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color=color
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,material)
	for i in 40:
		var a:=Vector3(sin(i*TAU/40),.03,cos(i*TAU/40))*radius
		var b:=Vector3(sin((i+1)*TAU/40),.03,cos((i+1)*TAU/40))*radius
		var inside: float=0 if filled else .92
		for point in [a,b,a*inside,b,b*inside,a*inside]: mesh.surface_add_vertex(point)
	mesh.surface_end()
	var node:=MeshInstance3D.new()
	node.mesh=mesh
	parent.add_child(node)
	node.global_position=pos+Vector3(0,.055,0)
	if duration>0:
		var tween:=node.create_tween()
		tween.tween_property(material,"albedo_color:a",0.0,duration)
		tween.tween_callback(node.queue_free)
	return node

func burst(parent: Node3D, pos: Vector3, color: Color, count: int = 7) -> void:
	var anchor:=Node3D.new(); parent.add_child(anchor); anchor.global_position=pos
	anchor.create_tween().tween_callback(anchor.queue_free).set_delay(.6)
	for i in maxi(2,mini(roundi(count*float(Preferences.values.particles)),20)):
		var spark:=Sprite3D.new()
		spark.texture=PixelArt.item_icon("gem",color)
		spark.pixel_size=.007
		spark.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		spark.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		anchor.add_child(spark)
		spark.position=Vector3(0,.7,0)
		var destination: Vector3=spark.position+Vector3(randf_range(-.6,.6),randf_range(.25,1),randf_range(-.6,.6))
		var tween:=spark.create_tween()
		tween.tween_property(spark,"position",destination,.35)
		tween.parallel().tween_property(spark,"modulate:a",0.0,.45)
		tween.tween_callback(spark.queue_free)

func number(parent: Node3D, pos: Vector3, amount: int, critical: bool = false, healing: bool = false) -> void:
	if not Preferences.values.damage_numbers: return
	var pop:=Label3D.new()
	pop.text=("+" if healing else "")+str(amount)+( "!" if critical else "")
	pop.font_size=44 if critical else 32
	pop.pixel_size=.012
	pop.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	pop.no_depth_test=true
	pop.modulate=Color("aee2ae") if healing else (Color("ffe091") if critical else Color("f1ebd6"))
	parent.add_child(pop)
	pop.global_position=pos+Vector3(randf_range(-.15,.15),1.5,0)
	var tween:=pop.create_tween()
	tween.tween_property(pop,"position:y",pop.position.y+1.1,.7)
	tween.parallel().tween_property(pop,"modulate:a",0.0,.7).set_delay(.12)
	tween.tween_callback(pop.queue_free)
