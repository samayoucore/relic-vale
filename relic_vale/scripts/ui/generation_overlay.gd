class_name ValeGenerationOverlay
extends MeshInstance3D
var gen: ValeGenerator
var mode: int=0

func rebuild(value: int) -> void:
	mode=value
	visible=value>0
	if value==0: mesh=null; return
	var surface:=SurfaceTool.new()
	var lines: bool=value>=4
	surface.begin(Mesh.PRIMITIVE_LINES if lines else Mesh.PRIMITIVE_TRIANGLES)
	if value in [5,6]:
		var networks: Array=gen.roads if value==5 else [gen.landscape.stream]
		for road in networks:
			for i in range(road.size()-1):
				for p in [road[i],road[i+1]]:
					surface.set_color(Color("e7c476") if value==5 else Color("77cde1"))
					surface.add_vertex(Vector3(p.x,gen.landscape.height(p)+.4,p.y))
	else:
		for key in gen.active_chunks:
			var data: Dictionary=gen.layout[key]
			var origin: Vector2=Vector2(data.coord)*32
			if value==4:
				for side in [[Vector2.ZERO,Vector2(32,0)],[Vector2(32,0),Vector2(32,32)],[Vector2(32,32),Vector2(0,32)],[Vector2(0,32),Vector2.ZERO]]:
					for p in side:
						surface.set_color(Color("ecc276"))
						surface.add_vertex(Vector3(origin.x+p.x,gen.landscape.height(origin+p)+.2,origin.y+p.y))
				continue
			for x in range(0,32,2):
				for z in range(0,32,2):
					var center:=origin+Vector2(x+1,z+1)
					var weights: Vector3=gen.landscape.weights(center)
					var color:=Color(weights.x,weights.y,weights.z,.65)
					if value==2: color=Color("b3594d").lerp(Color("7fbd73"),gen.density_noise.get_noise_2d(center.x,center.y)+.5)
					if value==3: color=Color("71b876") if gen.clear_for_prop(center,data.poi) else Color("cc7564")
					for offset in [Vector2.ZERO,Vector2(2,0),Vector2(0,2),Vector2(2,0),Vector2(2,2),Vector2(0,2)]:
						var p: Vector2=origin+Vector2(x,z)+offset
						surface.set_color(color)
						surface.add_vertex(Vector3(p.x,gen.landscape.height(p)+.12,p.y))
	mesh=surface.commit()
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material_override=material

