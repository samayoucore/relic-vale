class_name ValeCultivation
extends Node
## Camp beds and ongoing occupations advance with the same world clock as missions.
const ROOT="res://assets/3d/phase8/"
const ROLES={"Farmer":{"tier":3,"skill":"gathering"},"Cook":{"tier":2,"skill":"gathering"},"Fisher":{"tier":3,"skill":"hunting"},"Forager":{"tier":2,"skill":"gathering"},"Woodworker":{"tier":3,"skill":"mining"}}
var game: Node
var clock: float=0
var farm_root: Node3D
var camp_instance: int=0
var plots: Dictionary={}
var action: Dictionary={}
var action_elapsed: float=0
var chosen_seed: String="carrot"
var weather: String=""

func _ready() -> void:
	game=get_tree().current_scene
	weather=State.life_data.weather
	record_weather()

func storehouse() -> Dictionary:
	if not State.interior_data.has("storage"): State.interior_data.storage={}
	if not State.interior_data.storage.has("camp_production"): State.interior_data.storage.camp_production={}
	return State.interior_data.storage.camp_production

func farm() -> Dictionary: return State.activities.farm
func unlocked() -> bool: return int(State.camp_data.get("tier",0))>=3
func busy() -> bool: return not action.is_empty()

func worker_activity(worker: Dictionary) -> Dictionary:
	var role: String=worker.get("role","")
	if role.is_empty(): return {}
	match role:
		"Farmer": return {"target":plot_position(absi(worker.id.hash())%8)+Vector3(0,0,1),"activity":"Tending the garden"}
		"Cook": return {"target":Vector3(-1.5,0,1.3),"activity":"Preparing meals"}
		"Woodworker": return {"target":Vector3(-5,0,6.5),"activity":"Processing timber"}
		"Forager": return {"target":Vector3(16,0,-3),"activity":"Foraging the camp edge"}
		"Fisher":
			var site: Dictionary=State.activities.production.get("fish_bank",{})
			if not site.is_empty() and is_instance_valid(game.camp.visual): return {"target":game.camp.visual.to_local(game.generator.position_of(site)),"activity":"Fishing at the bank"}
	return {}
func plot_position(index: int) -> Vector3: return Vector3(2.9+(index%4)*1.25,0,9.2+floori(index/4.0)*1.55)

func ensure() -> void:
	if not unlocked() or not farm().is_empty(): return
	for i in 8: farm()[str(i)]={"prepared":false,"crop":"","progress":0.0,"planted":0.0,"watered":0.0,"moist_until":0.0,"last":ValeCamp.now(),"replant":"carrot","harvests":0}

func record_weather() -> void:
	var history: Array=State.activities.weather_history
	var now: float=ValeCamp.now()
	if history.is_empty() or history.back().weather!=State.life_data.weather:
		history.append({"time":now,"weather":State.life_data.weather})
	State.activities.weather_last=now

func weather_at(time: float) -> String:
	var history: Array=State.activities.weather_history
	for i in range(history.size()-1,-1,-1):
		if time>=float(history[i].time): return history[i].weather
	var block: int=8+floori(time/180)
	var rng:=RandomNumberGenerator.new(); rng.seed=State.world_seed+block*197
	return ValeLife.WEATHER[[0,0,0,1,1,2,3,4][rng.randi_range(0,7)]]

func advance_plot(plot: Dictionary,end: float) -> void:
	var start: float=float(plot.last)
	if end<=start: return
	if plot.crop.is_empty(): plot.last=end; return
	var boundaries: Array[float]=[start,end]
	for entry in State.activities.weather_history:
		if float(entry.time)>start and float(entry.time)<end: boundaries.append(float(entry.time))
	boundaries.sort()
	for i in range(boundaries.size()-1):
		var a: float=boundaries[i]; var b: float=boundaries[i+1]
		if weather_at(a) in ["Rain","Storm"]:
			plot.watered=b; plot.moist_until=maxf(float(plot.moist_until),b+480)
		var moist: float=maxf(0,minf(b,float(plot.moist_until))-a)
		plot.progress=minf(float(ValeProfessions.crops[plot.crop].minutes),float(plot.progress)+moist)
	plot.last=end

func stage(plot: Dictionary) -> int:
	if plot.crop.is_empty(): return -1
	var ratio: float=float(plot.progress)/float(ValeProfessions.crops[plot.crop].minutes)
	if ratio>=1: return 4
	if ratio>=.7: return 3
	if ratio>=.38: return 2
	if ratio>=.12: return 1
	return 0

func role_reason(worker: Dictionary,role: String) -> String:
	if not role.is_empty() and not ROLES.has(role): return "Unknown occupation"
	if worker.assignment!="": return "Resident is away on a mission"
	if role.is_empty(): return ""
	if int(State.camp_data.tier)<int(ROLES[role].tier): return "Camp tier %d required" % ROLES[role].tier
	if role=="Fisher" and fishing_worksite().is_empty(): return "No safe fishing bank within 26 metres of camp"
	return ""

func assign_role(worker_id: String,role: String) -> bool:
	if not State.camp_data.get("workers",{}).has(worker_id): return false
	resolve()
	var worker: Dictionary=State.camp_data.workers[worker_id]
	var reason: String=role_reason(worker,role)
	if not reason.is_empty(): State.notification.emit(reason); return false
	worker.role=role; worker.role_last=ValeCamp.now(); worker.role_progress=0.0
	State.save_requested.emit(); State.changed.emit()
	return true

func fishing_worksite() -> Dictionary:
	if State.camp_data.is_empty(): return {}
	if State.activities.production.has("fish_bank"): return State.activities.production.fish_bank
	var center: Vector3=game.generator.position_of(State.camp_data.address)
	if State.interior_data.has("active") or game.player.position.x>900 or center.distance_to(game.player.position)>78: return {}
	for r in [20,24,26]:
		for i in 24:
			var p: Vector3=center+Vector3(sin(i*TAU/24),0,cos(i*TAU/24))*r
			p.y=game.generator.landscape.height(Vector2(p.x,p.z))+.05
			for d in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
				if not game.fishing.bank_target(p,d).is_empty():
					State.activities.production.fish_bank=game.generator.address(p); return State.activities.production.fish_bank
	return {}

func worker_xp(worker: Dictionary,amount: int) -> void:
	worker.xp+=amount
	while int(worker.xp)>=int(worker.level)*50:
		worker.xp-=int(worker.level)*50; worker.level+=1
		for skill in worker.skills: worker.skills[skill]+=1

func resolve() -> void:
	ensure()
	if State.camp_data.is_empty(): return
	var now: float=ValeCamp.now()
	var last: float=float(State.activities.production.get("last",now))
	# Work is bounded per frame but its remaining time is retained, never discarded.
	var until: float=minf(now,last+30*960)
	var time: float=last
	while time<until:
		var next: float=minf(until,time+30)
		for plot in farm().values(): advance_plot(plot,next)
		var daytime: bool=fposmod(time,1440)>=360 and fposmod(time,1440)<1200
		for worker in State.camp_data.workers.values():
			var role: String=worker.get("role","")
			if role.is_empty() or worker.assignment!="" or not daytime: continue
			var worked: float=maxf(0,next-maxf(time,float(worker.get("role_last",time))))
			if worked<=0: continue
			if role=="Farmer" and weather_at(time)!="Storm": tend(next,worker)
			var skill: String=ROLES[role].skill
			var efficiency: float=1.0+minf(.3,float(worker.skills.get(skill,0))*.01)
			worker.role_progress=float(worker.get("role_progress",0))+worked*efficiency
			while float(worker.role_progress)>=180:
				worker.role_progress-=180
				if produce(role): worker_xp(worker,6)
			worker.role_last=next
		time=next
	State.activities.production.last=until
	for plot in farm().values():
		if last==now: advance_plot(plot,now)
	# Completed intervals need no weather records; keep one anchor for future ticks.
	var history: Array=State.activities.weather_history
	while history.size()>2 and float(history[1].time)<=until: history.pop_front()

func produce(role: String) -> bool:
	var storage: Dictionary=storehouse()
	match role:
		"Forager": storage.wild_herb=int(storage.get("wild_herb",0))+1
		"Fisher":
			if not State.activities.production.has("fish_bank"): return false
			storage.fish_minnow=int(storage.get("fish_minnow",0))+1
		"Cook":
			for recipe_id in ["cook_grilled_fish","cook_roast_meat","cook_roast_carrot","cook_forest_bites"]:
				var recipe: Dictionary=State.crafting_data[recipe_id]; var enough: bool=true
				for id in recipe.input:
					if int(storage.get(id,0))<int(recipe.input[id]): enough=false
				if not enough: continue
				for id in recipe.input: take_storage(id,int(recipe.input[id]))
				storage[recipe.output]=int(storage.get(recipe.output,0))+1; return true
			return false
		"Woodworker":
			if int(storage.get("wood",0))<3: return false
			take_storage("wood",3); storage.plank=int(storage.get("plank",0))+1
		"Farmer": return false
	return true

func take_storage(id: String,amount: int) -> void:
	var storage: Dictionary=storehouse(); storage[id]=int(storage.get(id,0))-amount
	if int(storage[id])<=0: storage.erase(id)

func tend(time: float,worker: Dictionary) -> void:
	for plot in farm().values():
		if not plot.prepared: continue
		if stage(plot)==4:
			var crop: Dictionary=ValeProfessions.crops[plot.crop]
			storehouse()[crop.item]=int(storehouse().get(crop.item,0))+maxi(1,int(crop.yield)-1)
			plot.crop=""; plot.progress=0; plot.harvests+=1; worker_xp(worker,4)
		if plot.crop.is_empty():
			var crop: Dictionary=ValeProfessions.crops[plot.replant]
			# Residents grow staples. Rare cultivars and personal mastery remain the player's work.
			if int(crop.min_level)>5 or int(storehouse().get(crop.seed,0))<1: continue
			take_storage(crop.seed,1); plot.crop=crop.id; plot.planted=time; plot.progress=0; plot.last=time
		plot.watered=time; plot.moist_until=time+480

func start_action(id: String,index: String,crop_id: String="") -> bool:
	if busy() or State.paused or game.fishing.busy() or game.mounts.mounted or not unlocked() or not farm().has(index): return false
	var p: Vector3=game.generator.position_of(State.camp_data.address)+plot_position(int(index))
	p.y=game.generator.landscape.height(Vector2(p.x,p.z))
	if game.player.global_position.distance_to(p)>2.4: return false
	var plot: Dictionary=farm()[index]
	var reason: String=""
	if id=="prepare" and plot.prepared: return false
	if id=="plant":
		if not plot.prepared or not plot.crop.is_empty() or not ValeProfessions.crops.has(crop_id): return false
		var crop: Dictionary=ValeProfessions.crops[crop_id]
		if ValeProfessions.level("farming")<int(crop.min_level): reason="Farming %d required" % crop.min_level
		if int(State.inventory.get(crop.seed,0))<1: reason="No "+State.items[crop.seed].name
	if id=="water":
		if plot.crop.is_empty(): return false
		if State.equipment.Tool!="watering_can": reason="Equip your watering can in Tool."
	if id=="harvest" and stage(plot)!=4: return false
	if not reason.is_empty(): State.notification.emit(reason); return false
	game.hud.close_modal()
	game.player.gathering.cancel(); game.player.velocity=Vector3.ZERO
	game.player.facing=(p-game.player.global_position).normalized()
	action={"id":id,"plot":index,"crop":crop_id}; action_elapsed=0
	game.player.sprite.play("slash_%d" % game.rig.screen_direction(game.player.facing))
	return true

func finish_action() -> void:
	var plot: Dictionary=farm()[action.plot]
	match action.id:
		"prepare": plot.prepared=true
		"plant":
			var crop: Dictionary=ValeProfessions.crops[action.crop]
			if int(State.inventory.get(crop.seed,0))<1: action={}; return
			ValeLife.consume(crop.seed,1)
			plot.crop=crop.id; plot.replant=crop.id; plot.progress=0; plot.planted=ValeCamp.now(); plot.last=ValeCamp.now(); plot.moist_until=0
			ValeProfessions.award("farming",3)
		"water": plot.watered=ValeCamp.now(); plot.moist_until=ValeCamp.now()+480
		"harvest":
			var crop: Dictionary=ValeProfessions.crops[plot.crop]
			var rng:=RandomNumberGenerator.new(); rng.seed=(str(State.world_seed)+action.plot+str(plot.harvests)).hash()
			State.add_item(crop.item,int(crop.yield)+(1 if rng.randf()<(0.1 if ValeProfessions.level("farming")>=15 else 0) else 0))
			if rng.randf()<.30+(.15 if ValeProfessions.level("farming")>=20 else 0): State.add_item(crop.seed)
			ValeProfessions.award("farming",18+int(crop.min_level))
			plot.crop=""; plot.progress=0; plot.harvests+=1
	Feel.sound("plant_pick",.4)
	action={}; game.player.attack_timer=0
	State.changed.emit(); State.save_requested.emit(); sync_visual(true)

func prompt(index: String) -> String:
	var plot: Dictionary=farm()[index]
	if not plot.prepared: return "Prepare garden bed · E"
	if plot.crop.is_empty(): return "Plant "+ValeProfessions.crops[chosen_seed].name+" · E / choose seeds [P]"
	var crop: Dictionary=ValeProfessions.crops[plot.crop]
	if stage(plot)==4: return "Harvest "+crop.name+" · E"
	return "%s · %s · %s" % [crop.name,["Seed","Young","Growing","Mature","Harvestable"][stage(plot)],"moist" if float(plot.moist_until)>ValeCamp.now() else "needs water · E"]

func interact(index: String) -> void:
	var plot: Dictionary=farm()[index]
	if not plot.prepared: start_action("prepare",index)
	elif plot.crop.is_empty(): start_action("plant",index,chosen_seed)
	elif stage(plot)==4: start_action("harvest",index)
	else: start_action("water",index)

func sync_visual(force: bool=false) -> void:
	if not is_instance_valid(game.camp.visual): farm_root=null; plots.clear(); camp_instance=0; return
	if camp_instance!=game.camp.visual.get_instance_id():
		camp_instance=game.camp.visual.get_instance_id(); plots.clear()
		farm_root=Node3D.new(); farm_root.name="GardenAndKitchen"; game.camp.visual.add_child(farm_root)
		station("campfire",Vector3(1.2,0,0),"Campfire cooking")
		if int(State.camp_data.tier)>=2:
			game.world.place(ROOT+"ultimatefood/CookingPot.glb",Vector3(-1.5,.35,0),.55,0,farm_root)
			station("cooking_pot",Vector3(-1.5,0,.8),"Cooking pot")
		if int(State.camp_data.tier)>=4: station("kitchen",Vector3(-5.2,0,7),"Camp kitchen")
		if unlocked():
			game.world.place(ROOT+"tools/WateringCan.glb",Vector3(7.0,0,9.2),.45,25,farm_root)
			var storage: ValeInteractable=game.world.interactable("storage","Produce chest",Vector3(7,0,8.3),farm_root); storage.persistent_id="camp_production"
			game.world.place("res://assets/3d/phase7/chest.glb",Vector3(7,0,8.3),.6,0,farm_root)
		force=true
	if not unlocked(): return
	for id in farm():
		var plot: Dictionary=farm()[id]
		var revision: String=str(plot.prepared)+plot.crop+str(stage(plot))+str(float(plot.moist_until)>ValeCamp.now())
		if plots.has(id) and plots[id].get_meta("revision")==revision and not force: continue
		if plots.has(id): plots[id].queue_free()
		var p: Vector3=plot_position(int(id)); var base: Vector3=game.camp.visual.global_position+p
		p.y=game.generator.landscape.height(Vector2(base.x,base.z))-game.camp.visual.global_position.y+.025
		var node: ValeInteractable=game.world.interactable("garden","Garden bed",p,farm_root)
		node.set_meta("phase8_action","plot"); node.set_meta("plot",id); node.set_meta("revision",revision); plots[id]=node
		game.world.box(Vector3.ZERO,Vector3(1.1,.045,1.25),"584537" if float(plot.moist_until)>ValeCamp.now() else ("806045" if plot.prepared else "8a8062"),false,node)
		if not plot.crop.is_empty():
			var crop: Dictionary=ValeProfessions.crops[plot.crop]; var s: int=stage(plot)
			var model: String="Corn_Crop" if s==0 else str(crop.model)+"_"+str(s)
			var height: float=float(crop.height)*[.06,.18,.42,.72,1.0][s]
			game.world.place(ROOT+"ultimatecrops/"+model+".glb",Vector3(0,.035,0),height,0,node)

func station(kind: String,p: Vector3,title: String) -> void:
	var base: Vector3=game.camp.visual.global_position+p
	p.y=game.generator.landscape.height(Vector2(base.x,base.z))-game.camp.visual.global_position.y
	var node: ValeInteractable=game.world.interactable("station",title,p,farm_root); node.set_meta("station",kind)

func _process(delta: float) -> void:
	if busy():
		if State.modal or State.paused or game.player.statuses.has("stun") or game.player.invulnerability>.8: action={}; return
		action_elapsed+=delta
		game.player.attack_timer=.15
		if action_elapsed>=1.2: finish_action()
	clock-=delta
	if clock>0: return
	clock=.5
	record_weather(); resolve(); sync_visual()
	var food: Dictionary=State.activities.food
	if not food.is_empty() and float(food.end)<=ValeCamp.now(): State.activities.food={}; State.recalculate(); State.changed.emit()
