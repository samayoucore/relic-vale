import fs from 'node:fs';
const path='relic_vale/scripts/world_generation/world_generator.gd';
let s=fs.readFileSync(path,'utf8').replaceAll('\r\n','\n');
function sub(a,b){if(!s.includes(a))throw Error('Missing '+a.slice(0,90));s=s.replace(a,b);}
sub('var discovery_clock: float=0','var discovery_clock: float=0\nvar landscape := ValeLandscape.new()');
const start=s.indexOf('\t# The entire world is bounded;');const end=s.indexOf('\tcurrent_chunk=Vector2i',start);
s=s.slice(0,start)+'\tlandscape.boundary()\n'+s.slice(end);
sub('\tvar sorted_noise: Array[Dictionary] = []','\tlandscape.setup(self)\n\tvar sorted_noise: Array[Dictionary] = []');
sub('if not HUB.grow(8).has_point(center): sorted_noise.append(data)','if not HUB.grow(8).has_point(center) and landscape.water_distance(center)>14: sorted_noise.append(data)');
sub('Vector2(37,-22)]','Vector2(31,25)]');
sub('if HUB.grow(2).has_point(p) or road_distance(p)<padding: return false','if HUB.grow(.8).has_point(p) or road_distance(p)<padding: return false\n\tif landscape.water_distance(p)<.7 or minf(minf(p.x+96,128-p.x),minf(p.y+96,128-p.y))<5: return false');
sub('var clusters: int=4 if data.biome==BIOMES[0] else (10 if data.biome==BIOMES[1] else 5)','var clusters: int=9 if data.biome==BIOMES[0] else (22 if data.biome==BIOMES[1] else 12)');
sub('clusters=15','clusters=28');
sub('range(3):\n\t\t\tvar angle','range(7):\n\t\t\tvar angle');
sub('"plant_bushSmall" if j<2 else "rock_smallA"','"plant_bushSmall" if j<4 else ("log" if j==4 else "rock_smallA")');
// Use an available fallen trunk from the existing village nature family.
s=s.replaceAll('"log" if j==4','"tree_logSmall" if j==4');
sub('var p: Vector3=Vector3(prop.p.x,-.04,prop.p.y)','var p: Vector3=Vector3(prop.p.x,landscape.height(prop.p),prop.p.y)');
sub('for asset in batches: batch_decoration(asset,batches[asset],chunk)','for asset in batches: batch_decoration(asset,batches[asset],chunk)\n\tlandscape.cover(data,chunk)\n\tlandscape.water(chunk,data)');
sub('Vector3(data.poi.position.x,0,data.poi.position.y)','Vector3(data.poi.position.x,landscape.height(data.poi.position),data.poi.position.y)');
sub('Vector3(spawn.p.x,0,spawn.p.y)','Vector3(spawn.p.x,landscape.height(spawn.p)+.1,spawn.p.y)');
s=s.replaceAll('Vector3(data.center.x,0,data.center.y+4)','Vector3(data.center.x,landscape.height(data.center),data.center.y+4)').replaceAll('Vector3(data.center.x+3,0,data.center.y+2)','Vector3(data.center.x+3,landscape.height(data.center),data.center.y+2)').replaceAll('Vector3(prop.p.x,0,prop.p.y)','Vector3(prop.p.x,landscape.height(prop.p),prop.p.y)');
const a=s.indexOf('func build_ground('),b=s.indexOf('func build_roads(',a);
s=s.slice(0,a)+`func build_ground(data: Dictionary, parent: Node3D) -> void:
	landscape.ground(data,parent)
	build_roads(data,parent)

func ground_color(p: Vector2) -> Color:
	return landscape.color_at(p)

`+s.slice(b);
// Roads are tessellated every metre so the path actually follows slopes and banks.
const c=s.indexOf('\t\t\tvar a: Vector2=road[i]',s.indexOf('func build_roads(')),d=s.indexOf('\tif count==0:',c);
s=s.slice(0,c)+`			var begin: Vector2=road[i]
			var finish: Vector2=road[i+1]
			var steps: int=ceili(begin.distance_to(finish))
			for step in steps:
				var a: Vector2=begin.lerp(finish,float(step)/steps)
				var b: Vector2=begin.lerp(finish,float(step+1)/steps)
				var side: Vector2=(b-a).normalized().orthogonal()*1.55
				for polygon in Geometry2D.intersect_polygons(PackedVector2Array([a-side,b-side,b+side,a+side]),clip):
					for j in range(1,polygon.size()-1):
						for p in [polygon[0],polygon[j],polygon[j+1]]:
							surface.set_normal(Vector3.UP)
							surface.add_vertex(Vector3(p.x,landscape.height(p)+.04,p.y))
							count+=1
				if Rect2(o,Vector2(32,32)).has_point(a) and landscape.water_distance(a)<2:
					var plank:=world.box(Vector3(a.x,.17,a.y),Vector3(3.7,.16,.85),"93785a",false,parent)
					plank.rotation.y=-atan2((b-a).y,(b-a).x)+PI/2
`+s.slice(d);
sub('world.mat("b1a07b")','world.mat("b7a07a")');
sub('var prototype:=world.place(world.NATURE+asset+".glb",Vector3.ZERO,1,0,self)','var prototype:=world.place(asset if asset.begins_with("res://") else world.NATURE+asset+".glb",Vector3.ZERO,1,0,self)');
sub('\t\tdecoration_cache[asset]=parts','\t\tif "Grass_" in asset:\n\t\t\tfor part in parts:\n\t\t\t\tfor i in part.mesh.get_surface_count():\n\t\t\t\t\tvar material:=ShaderMaterial.new()\n\t\t\t\t\tmaterial.shader=preload("res://shaders/ground_cover.gdshader")\n\t\t\t\t\tmaterial.set_shader_parameter("blade_texture",load("res://assets/3d/phase4/nature/Grass.png"))\n\t\t\t\t\tpart.mesh.surface_set_material(i,material)\n\t\tdecoration_cache[asset]=parts');
sub('\t\tmulti.mesh=part.mesh','\t\tmulti.use_colors=true\n\t\tmulti.mesh=part.mesh');
sub('Vector3(prop.p.x,-.04,prop.p.y)','Vector3(prop.p.x,prop.get("y",landscape.height(prop.p)),prop.p.y)');
sub('multi.set_instance_transform(i,transform*part.transform)','multi.set_instance_transform(i,transform*part.transform)\n\t\t\tmulti.set_instance_color(i,prop.get("tint",Color.WHITE))');
sub('\t\tnode.multimesh=multi','\t\tnode.multimesh=multi\n\t\tnode.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF\n\t\tnode.visibility_range_end=55 if "phase4/nature" in asset else 85');
fs.writeFileSync(path,s);
let w=fs.readFileSync('relic_vale/scripts/world.gd','utf8').replaceAll('\r\n','\n');
w=w.replace('var m:=StandardMaterial3D.new()\n\tm.vertex_color_use_as_albedo=true\n\tm.roughness=1','var m=preload("res://materials/master_terrain.tres")');
fs.writeFileSync('relic_vale/scripts/world.gd',w);
