import fs from 'node:fs';
const edit=(p,fn)=>fs.writeFileSync('relic_vale/'+p,fn(fs.readFileSync('relic_vale/'+p,'utf8').replaceAll('\r\n','\n')));
fs.writeFileSync('relic_vale/scripts/world_generation/npc_schedule.gd',`class_name ValeSchedule
extends Node
var npc: ValeInteractable
var home: Vector3
var work: Vector3
var square: Vector3
var nav:=AStar3D.new()
var route:=PackedVector3Array()
var block: String=""
var activity: String="Working"
var initialized: bool=false
var timer: float=0
var phase: float=0
var greeting: float=0
var destination_id: String=""

static func attach(actor: ValeInteractable,workplace: Vector3,plaza: Vector3) -> void:
\tvar controller:=ValeSchedule.new(); controller.npc=actor; controller.work=workplace
\tcontroller.home=workplace+Vector3(0,0,-1); controller.square=plaza
\tactor.set_meta("schedule",true); actor.add_child(controller)

func shift_origin(delta: Vector3) -> void:
\thome-=delta; work-=delta; square-=delta
\tfor i in route.size(): route[i]-=delta

func _process(delta: float) -> void:
\tif State.modal or State.paused: return
\tvar game: Node=get_tree().current_scene
\tif game.player.position.x>900: return
\tphase+=delta; timer-=delta; greeting=maxf(0,greeting-delta)
\tvar near: float=npc.global_position.distance_to(game.player.global_position)
\tvar record: Dictionary=State.residents.get(npc.get_meta("resident",""),{})
\tif timer<=0:
\t\ttimer=.3 if near<35 else 2.0
\t\tvar hour: float=float(State.life_data.minute)/60
\t\tvar next: String=ValeResidents.destination(record) if not record.is_empty() else ("home" if hour<6 or hour>=22 else "work")
\t\tif next!=block or not initialized:
\t\t\tvar first: bool=not initialized; initialized=true; block=next; destination_id=next
\t\t\tnpc.visible=true
\t\t\tvar goal: Vector3=work if next.is_empty() and hour>=8 and hour<18 and not (hour>=12 and hour<13) else square
\t\t\tif not record.is_empty() and not next.is_empty():
\t\t\t\tvar building: Dictionary=ValeResidents.door(record,next)
\t\t\t\tif not building.is_empty(): goal=game.generator.position_of(building.door)
\t\t\tif first and not next.is_empty() and not record.is_empty():
\t\t\t\tnpc.global_position=goal; npc.visible=false; route.clear()
\t\t\telse: route=ValeResidents.route(npc,goal)
\t\t\tactivity="Walking to "+("the square" if next.is_empty() else ("home" if next==record.get("home","") else "work / tavern"))
\tif not npc.visible: return
\tif near>55:
\t\tif not route.is_empty(): npc.global_position=route[-1]; route.clear()
\t\treturn
\tvar camera: ValeCamera=game.rig
\tif near<2.6 and greeting<=0:
\t\tgreeting=35
\t\tif npc.npc_id!="rowan": State.notification.emit(State.npc_data[npc.npc_id].name+": "+("Good to see you again." if ValeLife.reputation("hearth")>=30 else "Good day, traveler."))
\tif not route.is_empty():
\t\tvar offset: Vector3=route[0]-npc.global_position
\t\tif offset.length()<.15: route.remove_at(0)
\t\telse:
\t\t\tvar direction: Vector3=offset.normalized()
\t\t\tvar step: float=delta*1.25
\t\t\tif near<.85: step=0; activity="Letting the traveler pass"
\t\t\tfor other in npc.get_parent().get_children():
\t\t\t\tif other is ValeInteractable and other.kind=="npc" and other!=npc and other.visible and other.get_instance_id()<npc.get_instance_id():
\t\t\t\t\tif other.position.distance_to(npc.position)<.7: step=0; break
\t\t\tnpc.global_position+=direction*minf(offset.length(),step)
\t\t\tnpc.sprite.play("walk_%d" % camera.screen_direction(direction))
\telse:
\t\tif not destination_id.is_empty(): npc.visible=false; activity="Inside"; return
\t\tvar direction:=Vector3.BACK
\t\tif near<3: direction=game.player.global_position-npc.global_position
\t\telse:
\t\t\tfor other in npc.get_parent().get_children():
\t\t\t\tif other is ValeInteractable and other.kind=="npc" and other!=npc and other.visible and other.position.distance_to(npc.position)<4:
\t\t\t\t\tdirection=other.position-npc.position; break
\t\tactivity="Talking" if int(phase+abs(npc.npc_id.hash()%7))%14<7 else "Watching the square"
\t\tif npc.npc_id=="willow_carpenter": activity="Working timber"
\t\tnpc.sprite.play(("slash_" if activity=="Working timber" else "idle_")+str(camera.screen_direction(direction)))
\t\tnpc.sprite.rotation.z=sin(phase*2)*.025 if activity=="Talking" else 0.0
`);
fs.writeFileSync('relic_vale/scripts/world_generation/fauna.gd',`class_name ValeFauna
extends Node3D
## Non-combat wildlife: explicit activities, home range, herds and simulation LOD.
var gen: ValeGenerator
var visual: ValeCreatureVisual
var origin: Vector2
var elapsed: float=0
var seed_phase: float=0
var species: String="deer"
var farm: bool=false
var state: String="Grazing"
var timer: float=0
var sound_clock: float=15
var target:=Vector2.ZERO
var flee_timer: float=0
var lod: String="near"
var group_id: String=""

func _ready() -> void:
\tadd_to_group("fauna")
\torigin=Vector2(global_position.x,global_position.z); target=origin
\tseed_phase=fposmod(origin.x+origin.y,TAU); timer=3+seed_phase
\tvisual=ValeCreatureVisual.new(); add_child(visual)
\tvisual.setup(species,{"fox":.7,"cow":1.4,"horse":1.8,"alpaca":1.3}.get(species,1.5))

func flee() -> void:
\tflee_timer=4; state="Fleeing"

func _process(delta: float) -> void:
\tif State.modal or State.paused or gen.player.position.x>900: return
\tvar distance: float=global_position.distance_to(gen.player.global_position)
\tlod="sleep" if distance>65 else ("far" if distance>32 else "near")
\tvisual.animator.speed_scale=0 if lod=="sleep" else 1
\tif lod=="sleep": return
\telapsed+=delta; timer-=delta; sound_clock-=delta; flee_timer=maxf(0,flee_timer-delta)
\tvar p:=Vector2(global_position.x,global_position.z)
\tvar hour: float=float(State.life_data.minute)/60
\tvar sleeping: bool=hour>=22 or hour<5
\tvar alarm: bool=distance<(1.2 if farm else 3.8) or (distance<9 and gen.player.attack_timer>.15)
\tif alarm: flee()
\tif flee_timer>0:
\t\ttarget=p+(p-Vector2(gen.player.position.x,gen.player.position.z)).normalized()*3
\t\tstate="Fleeing"
\telif sleeping or State.life_data.weather=="Storm":
\t\ttarget=origin; state="Returning home" if p.distance_to(origin)>.6 else "Sleeping"
\telif timer<=0:
\t\ttimer=4+fposmod(elapsed+seed_phase,5)
\t\tstate=["Idle","Wandering","Grazing","Following herd"][int(elapsed+seed_phase)%4]
\t\ttarget=origin+Vector2(sin(elapsed*.2+seed_phase),cos(elapsed*.17+seed_phase))*(2.5 if farm else 5)
\t\tif state=="Following herd":
\t\t\tfor other in get_tree().get_nodes_in_group("fauna"):
\t\t\t\tif other!=self and other.group_id==group_id and other.get_instance_id()<get_instance_id() and other.global_position.distance_to(global_position)<12:
\t\t\t\t\ttarget=Vector2(other.global_position.x,other.global_position.z)+Vector2(1.5,1); break
\tvar move:=Vector2.ZERO
\tif state in ["Wandering","Following herd","Returning home","Fleeing"] and p.distance_to(target)>.25: move=(target-p).normalized()*(2.8 if state=="Fleeing" else .6)
\tvar next: Vector2=p+move*delta
\tvar clear: bool=gen.landscape.water_distance(next)>1 and (farm or gen.clear_for_prop(next,{},.4))
\tif clear and next.distance_to(origin)<(3.5 if farm else 12):
\t\tvar query:=PhysicsRayQueryParameters3D.create(global_position+Vector3(0,.5,0),Vector3(next.x,global_position.y+.5,next.y)+Vector3(move.x,0,move.y).normalized()*.45,1)
\t\tif get_world_3d().direct_space_state.intersect_ray(query).is_empty(): global_position=Vector3(next.x,gen.landscape.height(next),next.y)
\tvisual.tick(delta,Vector3(move.x,0,move.y),false,false)
\tif state=="Grazing": visual.play("eat")
\tif state=="Sleeping": visual.play("sleep"); visual.scale.y=.82
\telse: visual.scale.y=1
\tif sound_clock<=0 and distance<15:
\t\tsound_clock=25+seed_phase*4
\t\tFeel.sound("animal_"+species,(.1 if farm else .06)*(1-distance/15))
`);
edit('scripts/combat/creature_visual.gd',s=>s.replace('"stag":"animals/Stag.gltf"','"stag":"animals/Stag.gltf","fox":"../phase6/animals/Fox.gltf","cow":"../phase6/animals/Cow.gltf","horse":"../phase6/animals/Horse.gltf","alpaca":"../phase6/animals/Alpaca.gltf"').replace('["eat",["eating"]]','["eat",["eating"]],["sleep",["sleep","lay"]]'));
edit('scripts/main.gd',s=>s.replace('var expedition: ValeExpedition','var interiors: ValeInteriors\nvar expedition: ValeExpedition').replace('\tlife=ValeLife.new()','\tinteriors=ValeInteriors.new(); world.add_child(interiors); interiors.setup_hub()\n\tlife=ValeLife.new()').replace('func restore_world(position: Vector3) -> void:\n','func restore_world(position: Vector3) -> void:\n\tinteriors.reset()\n\tplayer.gathering.cancel()\n').replace('\texpedition.clear()','\tinteriors.setup_hub()\n\tfor npc in world.hub_root.get_children():\n\t\tif npc is ValeInteractable and npc.kind=="npc" and not npc.has_meta("schedule"): ValeSchedule.attach(npc,npc.global_position,world.hub_root.to_global(Vector3(0,0,5.5)))\n\texpedition.clear()').replace('if position.x>1500 and','if position.x>1500 and position.x<2900 and').replace('\tState.appearance_changed.emit()','\tif position.x>2900 and State.interior_data.has("active"): interiors.enter.call_deferred(State.interior_data.active.building,true)\n\tState.appearance_changed.emit()'));
edit('scripts/save/save_system.gd',s=>s.replace('static func safe_position(pos: Vector3) -> Vector3:\n','static func safe_position(pos: Vector3) -> Vector3:\n\tif pos.x>=2993 and pos.x<=3007 and absf(pos.z)<=6: return Vector3(pos.x,clampf(pos.y,0,2),pos.z)\n'));
edit('scripts/interactable.gd',s=>s.replace('\t\t"npc": return','\t\t"building": return "Enter "+title\n\t\t"building_exit": return "Leave the building"\n\t\t"storage": return "Open household storage"\n\t\t"npc": return').replace('func interact(player: ValePlayer) -> void:\n\tmatch kind:','func interact(player: ValePlayer) -> void:\n\tmatch kind:\n\t\t"building": get_tree().current_scene.interiors.enter(get_meta("building"))\n\t\t"building_exit": get_tree().current_scene.interiors.leave()\n\t\t"storage": ValeStorage.show(get_tree().current_scene.hud.ui,persistent_id)'));
edit('scripts/world.gd',s=>s.replace('\tif State.region!=new_region:','\tif player.position.x>2900 and not get_tree().current_scene.interiors.active.is_empty(): new_region=get_tree().current_scene.interiors.active.title\n\tif State.region!=new_region:'));
edit('scripts/world_generation/world_generator.gd',s=>s.replace('if data.biome!=BIOMES[2] and not data.props.is_empty():','if data.biome!=BIOMES[2] and not data.props.is_empty() and absi(key.hash())%5==0:').replace('\t\tanimal.gen=self','\t\tanimal.gen=self\n\t\tanimal.species="fox" if absi(key.hash())%3==0 else ("deer" if absi(key.hash())%2==0 else "stag")\n\t\tanimal.group_id=key').replace('\t\telif false:\n\t\t\tvar model:=world.place(world.NATURE+prop.asset+".glb",p,prop.h,prop.yaw,chunk)\n\t\t\tworld.solid(p+Vector3(0,1,0),Vector3(.65,2,.65),chunk,model)\n',''));
edit('scripts/world_generation/settlement.gd',s=>s.replace('\tfor i in 3:\n','\tvar buildings: Array=[]\n\tfor i in 3:\n').replace('\t\tfor x in [-2.0,2.0]:','\t\tbuildings.append(ValeInteriors.register(world,self,definition.id,i,"tavern" if i==2 else ("shop" if i==0 else ("blacksmith" if kind=="mining" else "alchemist")),p+Vector3(0,0,2.6),definition.title+" · "+(["Provisions","Forge" if kind=="mining" else "Apothecary","Tavern"][i])))\n\t\tfor x in [-2.0,2.0]:').replace('\t\tvar id: String=npc_ids[i]','\t\tvar id: String=npc_ids[i]\n\t\tif "/region/" in definition.id:\n\t\t\tvar source: Dictionary=State.npc_data[id].duplicate(true)\n\t\t\tid=definition.id+"/resident/"+str(i)\n\t\t\tsource.name=["Alden","Bria","Cora","Dain","Edda","Finn","Greta","Hale"][absi(id.hash())%8]+" "+["Reed","Moss","Vale","Brook"][absi((id+"surname").hash())%4]\n\t\t\tState.npc_data[id]=source').replace('\t\tValeSchedule.attach(npc,npc.global_position,to_global(Vector3(i*1.5,0,4)))','\t\tValeResidents.bind(npc,definition.id+"/resident/"+str(i),definition.id,buildings[2].id,buildings[1 if kind=="mining" or i==1 else 0].id,buildings[2].id)\n\t\tValeSchedule.attach(npc,npc.global_position,to_global(Vector3(i*1.5,0,4)))').replace('\tvar stations: Array=',`\tfor i in 2:
\t\tvar id: String=definition.id+"/villager/"+str(i)
\t\tState.npc_data[id]={"name":"Innkeeper "+["Robin","Ash","Nell","Wren"][absi(id.hash())%4] if i==0 else "Farmer "+["Perrin","Rosa","Hollis","Meryl"][absi(id.hash())%4],"role":"Innkeeper" if i==0 else "Farmer","category":"general","shop":i==0,"dialogue":"The hearth is warm. Travelers are welcome here."}
\t\tvar npc:=world.interactable("npc",State.npc_data[id].name,Vector3(i*2,0,5),self); npc.npc_id=id
\t\tValeResidents.bind(npc,id,definition.id,buildings[2].id,buildings[2].id if i==0 else "",buildings[2].id)
\t\tValeSchedule.attach(npc,npc.global_position,to_global(Vector3(i*2,0,5)))
\tif kind=="forest":
\t\tfor i in 2:
\t\t\tvar animal:=ValeFauna.new(); animal.gen=world.generator; animal.species="cow" if i==0 else "alpaca"; animal.farm=true; animal.group_id=definition.id; animal.position=Vector3(11+i*2,0,7); add_child(animal)
\tvar stations: Array=`).replace('State.life_data.settlements[definition.id]={"name":definition.title,"position":[global_position.x,global_position.y,global_position.z],"kind":kind}','State.life_data.settlements[definition.id].merge({"name":definition.title,"position":[global_position.x,global_position.y,global_position.z],"address":world.generator.address(global_position),"kind":kind},true)'));
edit('scripts/camera_rig.gd',s=>s.replaceAll('if is_instance_valid(visual): visual.visible=record.visible','if is_instance_valid(visual): visual.visible=record.visible and not visual.get_meta("depleted",false)'));
edit('scripts/gathering/resource_node.gd',s=>s.replace('model.visible=not depleted','model.visible=not depleted\n\tmodel.set_meta("depleted",depleted)'));
edit('scripts/interiors/indoor_activity.gd',s=>s.replace('choose.call_deferred()','await get_tree().physics_frame\n\tchoose()'));
console.log('Phase 6 interiors and residents wired');
