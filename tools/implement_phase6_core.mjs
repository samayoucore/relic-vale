import fs from 'node:fs';
const root='relic_vale/';
const edit=(path,fn)=>fs.writeFileSync(root+path,fn(fs.readFileSync(root+path,'utf8').replaceAll('\r\n','\n')));
const json=(p)=>JSON.parse(fs.readFileSync(root+p)); const save=(p,v)=>fs.writeFileSync(root+p,JSON.stringify(v,null,2)+'\n');
const items=json('data/items.json');
for(const [tier,power,bonus,price] of [['crude',1,0,8],['iron',2,0,45],['steel',3,1,120]]) for(const kind of ['axe','pickaxe']) {
 const name=tier[0].toUpperCase()+tier.slice(1)+' '+kind;
 items[tier+'_'+kind]={name,kind:'tool',slot:'Tool',rarity:tier==='steel'?'Rare':tier==='iron'?'Uncommon':'Common',description:`${name}. Equip to ${kind==='axe'?'chop trees and logs':'mine stone and ore'}. Gathering power ${power}${bonus?', +1 material per deposit':''}.`,stats:{},tool:kind,gather_power:power,yield_bonus:bonus,tier:power,base_price:price,model:'res://assets/3d/phase6/props/'+(kind==='axe'?'Axe':'Pickaxe')+'_Bronze.gltf'};
}
const specs={wood:[3,3,6,3,'axe','ba8c59','Wood',5],stone:[3,2,4,5,'pickaxe','aeb6b9','Stone',5],iron_ore:[5,2,5,7,'pickaxe','a1b2c3','Ore',9],wild_herb:[1,2,4,2,'','83b586','Plants',6],fiber:[1,2,5,2,'','b2c17e','Plants',4],mushroom:[1,1,3,2,'','bc8275','Plants',7],crystal:[5,1,2,0,'pickaxe','87cede','Rare materials',24]};
const resources={};
items.fiber ??= {name:'Plant fiber',kind:'material',rarity:'Common',description:'Tough grass fibres used for cord and woven supplies.'};
for(const [id,[hits,min,max,days,tool,color,category,price]] of Object.entries(specs)) { resources[id]={hits,yield_min:min,yield_max:max,respawn_days:days,tool,color,category}; items[id].base_price=price;items[id].material_category=category; }
for(const [id,value] of Object.entries({charcoal:8,plank:10,iron_ingot:19,leather:9,wolf_pelt:12,ancient_bone:14})) if(items[id]) items[id].base_price=value;
save('data/items.json',items);save('data/resources.json',resources);
const merchants=json('data/merchants.json');
merchants.blacksmith.offers.push(...Object.keys(items).filter(id=>items[id].kind==='tool').map(id=>[id,items[id].base_price]));
merchants.carpenter={faction:'hearth',offers:[['wood',5],['plank',10],['crude_axe',8],['iron_axe',45]]};
for(const m of Object.values(merchants))m.offers=m.offers.filter(([id])=>id!=='crystal');
save('data/merchants.json',merchants);
edit('scripts/game_state.gd',s=>s.replace('var gathered_resources: Dictionary={}','var gathered_resources: Dictionary={}\nvar resource_states: Dictionary={}\nvar resource_data: Dictionary={}\nvar residents: Dictionary={}\nvar interior_data: Dictionary={}').replaceAll('"Relic":""','"Relic":"","Tool":""').replace('for values in [opened_chests','for values in [resource_states,residents,interior_data,opened_chests').replace('"oak_bow":1}','"oak_bow":1,"crude_axe":1,"crude_pickaxe":1}').replace('"oak_bow"]: inventory','"oak_bow","crude_axe","crude_pickaxe"]: inventory').replace('\tbase_items=items.duplicate(true)','\tresource_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/resources.json"))\n\tbase_items=items.duplicate(true)'));
edit('scripts/player.gd',s=>s.replace('var god_mode: bool=false','var god_mode: bool=false\nvar gathering: ValeGathering').replace('\tState.appearance_changed.connect(refresh_appearance)','\tState.appearance_changed.connect(refresh_appearance)\n\tgathering=ValeGathering.new(); add_child(gathering)').replace('if attack_timer > .25: target_velocity*=.25','if attack_timer > .25: target_velocity*=.25\n\tif gathering.busy: target_velocity=Vector3.ZERO').replace('if State.modal or State.paused: return\n\tif event','if State.modal or State.paused or gathering.busy: return\n\tif event').replace('func respawn() -> void:\n','func respawn() -> void:\n\tgathering.cancel()\n'));
edit('scripts/combat/player_combat.gd',s=>s.replace('if actor.attack_timer>0 or','if (is_instance_valid(actor.gathering) and actor.gathering.busy) or actor.attack_timer>0 or'));
edit('scripts/ui/inventory_page.gd',s=>s.replaceAll('"Materials","Relics"','"Materials","Tools","Wood","Stone","Ore","Plants","Rare materials","Relics"').replace('"Weapons":"weapon"','"Tools":"tool","Weapons":"weapon"').replace('if not matches: continue','if item.get("material_category","")==ui.category: matches=true\n\t\tif not matches: continue'));
edit('scripts/combat/feedback.gd',s=>s.replace('for id in mappings:','mappings.merge({"wood_hit":"chop.ogg","stone_hit":"metalClick.ogg","plant_pick":"cloth1.ogg"})\n\tfor id in mappings:'));
edit('scripts/save/chunk_deltas.gd',s=>s.replace('"defeated_unique","discoveries"','"defeated_unique","discoveries","resource_states"').replace('for id in data[field]:','for id in data.get(field,{}):').replace('data[field].merge(record.get(field,{}))','if not data.has(field): data[field]={}\n\t\t\tdata[field].merge(record.get(field,{}))').replace('for key in data.get("chunk_manifest",{}):','if not data.has("world"): data.world={}\n\tif not data.world.has("discovered"): data.world.discovered={}\n\tfor key in data.get("chunk_manifest",{}):'));
edit('scripts/save/save_system.gd',s=>s.replace('const VERSION: int=5','const VERSION: int=6').replace('return {"life":','return {"world":State.world_data.duplicate(true),"resource_states":State.resource_states.duplicate(true),"residents":State.residents.duplicate(true),"interior_data":State.interior_data.duplicate(true),"life":').replace('[2,3,4,VERSION]','[2,3,4,5,VERSION]').replace('"life","generated_items"','"resource_states","residents","interior_data","life","generated_items"').replace('int(json.data.version)==5','int(json.data.version)>=5').replace('State.world_data.merge(data.get("world",{}),true)','State.world_data.merge(data.get("world",{}),true)\n\tState.resource_states=data.get("resource_states",{}).duplicate(true)\n\tState.residents=data.get("residents",{}).duplicate(true)\n\tState.interior_data=data.get("interior_data",{}).duplicate(true)'));
edit('scripts/world_generation/living_world.gd',s=>{
 const index=s.indexOf('static func trade(');
 s=s.slice(0,index)+`static func item_price(npc_id: String,id: String,selling: bool=false) -> int:
\tvar merchant: Dictionary=State.merchant_data[category(npc_id)]
\tvar base: int=int(State.items.get(id,{}).get("base_price",10))
\tif not selling:
\t\tfor offer in merchant.offers:
\t\t\tif offer[0]==id: base=int(offer[1])
\tvar demand: float=1.0
\tif selling:
\t\tvar preferred: Dictionary={"blacksmith":["iron_ore","iron_ingot","stone","charcoal"],"carpenter":["wood","plank","fiber"],"alchemist":["wild_herb","mushroom","crystal"]}
\t\tif id in preferred.get(category(npc_id),[]): demand=1.65
\treturn maxi(1,roundi(price(npc_id,base,selling)*demand))

`+s.slice(index);
 return s.replace('State.coins+=price(npc_id,base,true)','State.coins+=item_price(npc_id,id,true)').replace('var cost: int=price(npc_id,base)','var cost: int=item_price(npc_id,id)');
});
edit('scripts/ui/economy_pages.gd',s=>s.replace('var cost: int=ValeLife.price(npc,base,selling)','var cost: int=ValeLife.item_price(npc,id,selling)'));
edit('tools/render_item_icons.gd',s=>s.replace('\tfor id in items:\n','\tfor id in State.items:\n\t\tif State.items[id].kind=="tool": items[id]=State.items[id].model\n\tfor id in items:\n'));
edit('scripts/world_generation/world_generator.gd',s=>{
 const start=s.indexOf('\t# Harvest the same recognizable'); const end=s.indexOf('\tif data.poi.get("kind","")=="camp"',start);
 s=s.slice(0,start)+s.slice(end);
 s=s.replace('\tstage_tag="trees"\n\tfor prop in data.props:',`\tstage_tag="trees"
\tvar resource_index: int=0
\tvar resource_counts: Dictionary={}
\tvar tree_index: int=0
\tfor prop in data.props:`);
 s=s.replace('\t\tif prop.solid:\n',`\t\tvar item: String="wood" if prop.asset=="log" else ("wild_herb" if prop.asset=="plant_bushSmall" else ("mushroom" if "mushroom" in prop.asset else ("stone" if "rock" in prop.asset else "")))
\t\tif item=="stone" and data.biome==BIOMES[2]: item="iron_ore" if resource_index%3 else "crystal"
\t\tvar harvest: bool=not item.is_empty() and resource_index<10 and int(resource_counts.get(item,0))<2
\t\tif prop.solid:
\t\t\tValeResource.spawn(world,chunk,"%d/resource/%s/tree_%d" % [world_seed,key,tree_index],"wood",p,world.NATURE+prop.asset+".glb",prop.h,prop.yaw,true)
\t\t\ttree_index+=1
\t\telif harvest:
\t\t\tresource_counts[item]=int(resource_counts.get(item,0))+1
\t\t\tValeResource.spawn(world,chunk,"%d/resource/%s/%d" % [world_seed,key,resource_index],item,p,world.NATURE+prop.asset+".glb",maxf(prop.h,.5),prop.yaw)
\t\t\tresource_index+=1
\t\telif false:
`);
 return s;
});
console.log('Phase 6 gathering, prices and save foundation applied');
