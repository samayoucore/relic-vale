import fs from 'node:fs';
let s=fs.readFileSync('relic_vale/scripts/world_generation/world_generator.gd','utf8');
const a=s.indexOf('\tpois.clear()\n\tfor data in layout.values():');
s=s.slice(0,a)+`	# More authored templates are selected from compatible geographic contexts.
	var extra: Array=["grove","graveyard","mine","cave","wagon","battlefield","chapel","circle","lumber","well","hunter"]
	for kind in extra:
		for data in sorted_noise:
			if not data.poi.is_empty(): continue
			if kind in ["graveyard","mine","cave","battlefield","chapel"] and data.biome!=BIOMES[2]: continue
			if kind in ["grove","hunter","lumber"] and data.biome==BIOMES[2]: continue
			add_poi(data,kind)
			break
	# Reserve three spacious, river-free footprints before vegetation planning.
	for def in [{"coord":Vector2i(-2,-1),"kind":"forest","title":"Fernwatch"},{"coord":Vector2i(-1,2),"kind":"mining","title":"Ironvein"},{"coord":Vector2i(2,-2),"kind":"trading","title":"Crossroads"}]:
		var data: Dictionary=layout[chunk_key(def.coord)]
		data.poi={"kind":"settlement","settlement":def.kind,"title":def.title,"position":data.center,"access":data.center+Vector2(0,12),"radius":13.0,"id":"%d/settlement/%s" % [world_seed,def.kind]}
		data.biome=BIOMES[1] if def.kind=="forest" else (BIOMES[2] if def.kind=="mining" else BIOMES[0])
`+s.slice(a);
s=s.replace('if not poi.is_empty() and p.distance_to(poi.position)<7: return false','for feature in pois:\n\t\tif p.distance_to(feature.position)<float(feature.get("radius",7)): return false');
const p=s.indexOf('\tif not data.poi.is_empty():\n\t\tvar poi: ValePOI=');const q=s.indexOf('\tfor spawn in data.enemies:',p);
s=s.slice(0,p)+`	if not data.poi.is_empty():
		var poi: Node3D
		if data.poi.kind=="settlement":
			poi=ValeSettlement.new()
			poi.definition=data.poi
		else:
			poi=POI_SCENES[data.poi.kind].instantiate() if POI_SCENES.has(data.poi.kind) else ValeStoryPOI.new()
			poi.kind=data.poi.kind
			poi.persistent_id=data.poi.id
		poi.world=world
		poi.position=Vector3(data.poi.position.x,landscape.height(data.poi.position),data.poi.position.y)
		chunk.add_child(poi)
`+s.slice(q);
const r=s.indexOf('\t# One harvestable cluster'),t=s.indexOf('\nfunc build_ground(',r);
s=s.slice(0,r)+`	# Harvest the same recognizable meshes used by the decoration families.
	var resource_index: int=0
	for prop in data.props:
		if resource_index>=7: break
		var item: String="wood" if prop.asset=="log" else ("wild_herb" if prop.asset=="plant_bushSmall" else ("mushroom" if "mushroom" in prop.asset else ("stone" if "rock" in prop.asset else "")))
		if item.is_empty(): continue
		if item=="stone" and data.biome==BIOMES[2]: item="iron_ore" if resource_index%3 else "crystal"
		var node:=world.interactable("resource",State.items[item].name,Vector3(prop.p.x,landscape.height(prop.p),prop.p.y),chunk)
		node.set_meta("resource",item)
		node.persistent_id="%d/resource/%s/%d" % [world_seed,key,resource_index]
		resource_index+=1
	if data.poi.get("kind","")=="camp": ValeSettlement.station(world,"campfire",Vector3(data.center.x+3,landscape.height(data.center),data.center.y+4),chunk)
`+s.slice(t);
s=s.replace('State.discover(poi.id,{"camp":"Abandoned camp","ruin":"Ruined tower","shrine":"Woodland shrine","pond":"Quiet pond","crypt":"Forgotten Crypt stairway"}[poi.kind])','State.discover(poi.id,poi.get("title",poi.kind.capitalize()))\n\t\t\t\tState.quest_event("discover",poi.kind)');
s=s.replace('Vector3(poi.position.x,0,poi.position.y)','Vector3(poi.position.x,landscape.height(poi.position),poi.position.y)');
fs.writeFileSync('relic_vale/scripts/world_generation/world_generator.gd',s);
console.log('Settlements and story POIs integrated');
