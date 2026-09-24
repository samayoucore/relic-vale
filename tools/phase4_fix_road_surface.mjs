import fs from 'node:fs';
const path='relic_vale/scripts/world_generation/world_generator.gd';
let s=fs.readFileSync(path,'utf8');
const a=s.indexOf('func build_roads('),b=s.indexOf('func collect_mesh_parts(',a);
s=s.slice(0,a)+`func build_roads(data: Dictionary, parent: Node3D) -> void:
	var origin: Vector2=Vector2(data.coord)*32
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int=0
	for road in roads:
		for segment in range(road.size()-1):
			var a: Vector2=road[segment]
			var b: Vector2=road[segment+1]
			var side: Vector2=(b-a).normalized().orthogonal()*1.55
			var ribbon:=PackedVector2Array([a-side,b-side,b+side,a+side])
			for x in range(0,32,2):
				for z in range(0,32,2):
					var p:=origin+Vector2(x,z)
					if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))>5: continue
					for tri in [[p,p+Vector2(2,0),p+Vector2(0,2)],[p+Vector2(2,0),p+Vector2(2,2),p+Vector2(0,2)]]:
						for polygon in Geometry2D.intersect_polygons(ribbon,PackedVector2Array(tri)):
							for j in range(1,polygon.size()-1):
								for v in [polygon[0],polygon[j],polygon[j+1]]:
									surface.set_normal(Vector3.UP)
									surface.add_vertex(Vector3(v.x,landscape.height(v)+.06,v.y))
									count+=1
			var steps: int=ceili(a.distance_to(b))
			for step in steps:
				var p: Vector2=a.lerp(b,float(step)/steps)
				if Rect2(origin,Vector2(32,32)).has_point(p) and landscape.water_distance(p)<2:
					var plank:=world.box(Vector3(p.x,.24,p.y),Vector3(3.7,.16,.92),"93785a",false,parent)
					plank.rotation.y=-atan2((b-a).y,(b-a).x)+PI/2
	if count==0: return
	var mesh:=MeshInstance3D.new()
	mesh.name="TerrainFollowingRoad"
	mesh.mesh=surface.commit()
	var material: StandardMaterial3D=world.mat("b7a07a").duplicate()
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=material
	parent.add_child(mesh)

`+s.slice(b);
s=s.replace('node.visibility_range_end=55 if "phase4/nature" in asset else 85','node.visibility_range_end=140 if "phase4/nature" in asset else 0');
fs.writeFileSync(path,s);
