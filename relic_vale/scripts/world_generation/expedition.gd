class_name ValeExpedition
extends Node3D
var game: Node
var content: Node3D
var plan: Dictionary={}
var active_id: String=""
var theme: String="crypt"
var boss_id: String=""

func _ready() -> void:
	game=get_tree().current_scene
	State.enemy_defeated.connect(check_completion)

func layout(id: String, style: String) -> Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=State.world_seed ^ id.hash()
	var side: int=-1 if rng.randf()<.5 else 1
	var cells: Array=[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(2,side),Vector2i(1,-side),Vector2i(2,-side)]
	var kinds: Array=["entrance","large_combat" if rng.randf()<.5 else "combat","crossroads","elite","boss","treasure","trap","shrine"]
	return {"id":id,"theme":style,"cells":cells,"kinds":kinds,"links":[[0,1],[1,2],[2,3],[3,4],[2,5],[1,6],[6,7],[7,2]]}

func enter(id: String, style: String) -> void:
	State.dungeon_return=game.player.global_position
	generate(id,style)
	game.player.global_position=Vector3(2000,.1,3)
	game.player.velocity=Vector3.ZERO
	game.rig.snap()
	State.notification.emit("VEILBOUND CRYPT" if style=="crypt" else "OLD IRONVEIN MINE")
	State.save_requested.emit()

func clear() -> void:
	if is_instance_valid(content): remove_child(content); content.queue_free()
	content=null
	active_id=""
	plan.clear()
	for hazard in get_tree().get_nodes_in_group("combat_hazards"):
		if hazard.has_meta("expedition"): hazard.queue_free()

func generate(id: String, style: String) -> void:
	clear()
	active_id=id
	theme=style
	boss_id=id+"/guardian"
	plan=layout(id,style)
	State.life_data.dungeons.active={"id":id,"theme":style}
	if not State.life_data.dungeons.has(id): State.life_data.dungeons[id]={"theme":style,"completed":false}
	content=Node3D.new()
	add_child(content)
	for i in plan.cells.size():
		var cell: Vector2i=plan.cells[i]
		var room: ValeDungeonRoom=load("res://scenes/dungeon_rooms/"+plan.kinds[i]+".tscn").instantiate()
		room.world=game.world
		room.theme=style
		room.position=Vector3(2000+cell.x*20,0,cell.y*20)
		for link in plan.links:
			if link[0]==i: room.doors.append(plan.cells[link[1]]-cell)
			elif link[1]==i: room.doors.append(plan.cells[link[0]]-cell)
		content.add_child(room)
		var p: Vector3=room.position
		if plan.kinds[i] in ["combat","large_combat","elite","boss"]:
			spawn("guardian" if plan.kinds[i]=="boss" else ("elite" if plan.kinds[i]=="elite" else ("skeleton" if style=="crypt" else "wolf")),p+Vector3(1,0,0),boss_id if plan.kinds[i]=="boss" else id+"/room/%d" % i,p)
		if plan.kinds[i] in ["treasure","boss"]:
			var chest: ValeInteractable=game.world.interactable("cache","Sealed work ledger" if style=="mine" else "Relic coffer",p+Vector3(0,0,-4),content)
			chest.persistent_id=id+"/treasure/%d" % i
			chest.set_meta("loot_table","crypt_treasure" if plan.kinds[i]=="boss" else "cache")
			if plan.kinds[i]=="boss": chest.set_meta("requires",boss_id)
			chest.model=game.world.place(game.world.DUNGEON+"chest.glb",Vector3.ZERO,.8,0,chest)
			chest.synchronize()
		if i in [0,4]: game.world.interactable("exit","Return to the surface",p+Vector3(0,0,5),content)
		if i in [1,5]:
			ValeResource.spawn(game.world,content,id+"/ore/%d" % i,"crystal" if style=="crypt" else "iron_ore",p+Vector3(5,0,4),game.world.NATURE+"rock_largeB.glb",1.1)
	for link in plan.links:
		var a: Vector2=Vector2(plan.cells[link[0]])*20
		var b: Vector2=Vector2(plan.cells[link[1]])*20
		var p:=Vector3(2000+(a.x+b.x)/2,-.3,(a.y+b.y)/2)
		var horizontal: bool=a.x!=b.x
		game.world.box(p,Vector3(5,.6,4) if horizontal else Vector3(4,.6,5),"596568" if style=="crypt" else "716653",true,content)
		for side in [-1.0,1.0]:
			game.world.box(p+Vector3(0,1.2,2.3*side) if horizontal else p+Vector3(2.3*side,1.2,0),Vector3(5,2.4,.6) if horizontal else Vector3(.6,2.4,5),"46585c",true,content)

func spawn(kind: String, p: Vector3, id: String, center: Vector3) -> void:
	var enemy: Mossling=load("res://scenes/characters/Enemy.tscn").instantiate()
	enemy.position=p
	enemy.set_meta("archetype",kind)
	enemy.set_meta("persistent_id",id)
	enemy.set_meta("enemy_level",3)
	if kind=="guardian":
		enemy.set_meta("arena",Rect2(center.x-7.8,center.z-7.8,15.6,15.6))
		enemy.set_meta("gate_position",center+Vector3(-8,1,0))
		enemy.set_meta("gate_size",Vector3(.35,2,4))
	content.add_child(enemy)

func check_completion() -> void:
	if active_id.is_empty() or not State.life_data.dungeons.has(active_id) or not State.defeated_unique.has(boss_id): return
	if State.life_data.dungeons[active_id].completed: return
	State.life_data.dungeons[active_id].completed=true
	State.quest_event("dungeon",theme)
	State.notification.emit("The oath is broken. Search the coffer and report to your patron.")
	State.save_requested.emit()
