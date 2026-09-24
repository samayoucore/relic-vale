extends Node
var game: Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	game=get_tree().current_scene
	var generator: ValeGenerator=game.generator
	var original_seed: int=generator.world_seed
	var original_hash: String=generator.fingerprint()
	generator.build_layout()
	assert(original_hash==generator.fingerprint(),"Same seed must have the same layout")
	generator.world_seed+=19
	generator.build_layout()
	assert(original_hash!=generator.fingerprint(),"Different seed must change the layout")
	generator.regenerate(original_seed)
	var counts: Dictionary={}
	for data in generator.layout.values(): counts[data.biome]=int(counts.get(data.biome,0))+1
	assert(counts.size()==3,"All three biomes must exist")
	assert(generator.pois.size()>=5,"World must contain authored POIs")
	var prop_count: int=0
	for data in generator.layout.values(): prop_count+=data.props.size()
	assert(prop_count>100,"World must contain clustered scenery")
	print("GENERATION: ",counts,"; POIs=",generator.pois.size(),"; fingerprint=",original_hash)
	for biome in ValeGenerator.BIOMES:
		var choice: Dictionary={}
		for data in generator.layout.values():
			if data.biome==biome and not generator.HUB.grow(8).has_point(data.center):
				choice=data
				if not data.poi.is_empty(): break
		assert(not choice.is_empty())
		var p: Vector2=choice.center+Vector2(0,5)
		game.player.position=Vector3(p.x,0,p.y)
		game.player.velocity=Vector3.ZERO
		generator.update_streaming(true)
		game.rig.snap()
		for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
		await get_tree().create_timer(3).timeout
		await RenderingServer.frame_post_draw
		var file: String="res://docs/screenshots/phase2-"+biome.to_lower().replace(" ","-")+".png"
		get_viewport().get_texture().get_image().save_png(file)
		print("CAPTURED: ",biome,"; FPS=",Engine.get_frames_per_second(),"; chunks=",generator.active_chunks.size(),"; nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		assert(generator.active_chunks.size()<=25,"Streaming must bound active chunks")
	print("GENERATION_CHECK_PASS")
	get_tree().quit()
