class_name ValeCartography
extends RefCounted
## Both atlas and minimap sample the same terrain planner; no second world or camera.
const LIMIT := 512
const MARKER_LIMIT := 32
const ICONS := ["Flag", "Home", "Danger", "Treasure", "Resource"]
var game: Node
var cache: Dictionary = {}
var order: Array[String] = []
var seed_id: int = -1
var frame_id: int=-1
var built_this_frame: int=0
var worst_tile_ms: float=0
var pending: Dictionary={}
var worker_tile_ms: float=0

func player_address() -> Dictionary:
	if State.interior_data.has("active"): return State.interior_data.active.return
	return game.generator.address(game.player.position if game.player.position.x < 900 else State.dungeon_return)

func tile(key: String) -> Texture2D:
	if frame_id!=Engine.get_process_frames(): frame_id=Engine.get_process_frames(); built_this_frame=0
	if seed_id != State.world_seed:
		forget_cache(); seed_id = State.world_seed
	if cache.has(key):
		order.erase(key); order.append(key); return cache[key]
	var began: int=Time.get_ticks_usec()
	for ready in pending.keys():
		if built_this_frame>=4 or not WorkerThreadPool.is_task_completed(pending[ready].task): continue
		WorkerThreadPool.wait_for_task_completion(pending[ready].task)
		var raster: ValeMapRaster=pending[ready].raster
		worker_tile_ms=maxf(worker_tile_ms,raster.elapsed_ms)
		cache[ready]=ImageTexture.create_from_image(Image.create_from_data(32,32,false,Image.FORMAT_RGB8,raster.pixels))
		order.erase(ready); order.append(ready); pending.erase(ready); built_this_frame+=1
		while order.size()>LIMIT: cache.erase(order.pop_front())
	if not cache.has(key) and not pending.has(key) and pending.size()<1:
		var raster:=ValeMapRaster.new(); raster.plan=game.generator.planner(key)
		pending[key]={"raster":raster,"task":WorkerThreadPool.add_task(raster.generate,false,"Atlas "+key)}
	worst_tile_ms=maxf(worst_tile_ms,(Time.get_ticks_usec()-began)/1000.0)
	return cache.get(key)

func add_marker(address: Dictionary, title: String="Trail marker", icon: String="Flag") -> Dictionary:
	if not ValeSave.valid_address(address) or not game.generator.discovered.has(address.x+","+address.z): return {}
	if State.map_data.markers.size()>=MARKER_LIMIT:
		State.notification.emit("Your atlas holds at most %d markers." % MARKER_LIMIT); return {}
	var id: String="marker_"+str(State.map_data.next_id)
	State.map_data.next_id+=1
	var marker: Dictionary={"id":id,"name":title.strip_edges().left(32),"icon":icon if icon in ICONS else "Flag","address":address.duplicate(true),"created":ValeCamp.now()}
	State.map_data.markers[id]=marker
	State.save_requested.emit()
	return marker

func markers() -> Array:
	var result: Array=State.map_data.markers.values().duplicate()
	if not State.camp_data.is_empty(): result.append({"id":"camp","name":State.camp_data.name,"icon":"Home","address":State.camp_data.address})
	return result

func forget_cache() -> void:
	for job in pending.values(): WorkerThreadPool.wait_for_task_completion(job.task)
	pending.clear()
	cache.clear(); order.clear()
