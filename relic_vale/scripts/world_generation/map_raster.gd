class_name ValeMapRaster
extends RefCounted
## Pure pixels on one worker; ImageTexture creation remains on the main thread.
var plan: ValeRegionPlan
var pixels:=PackedByteArray()
var elapsed_ms: float=0
func generate() -> void:
	var begin: int=Time.get_ticks_usec()
	pixels.resize(32*32*3)
	for z in 32:
		for x in 32:
			var p:=Vector2(x+.5,z+.5)
			var w: Vector3=plan.weights(p)
			var color: Color=Color("91a879")*w.x+Color("496d51")*w.y+Color("918b7c")*w.z
			color=color.lightened(plan.noise(p,4,213)*.10)
			if plan.water_distance(p)<0 and plan.hub_distance(p)>1: color=Color("669ba7")
			if plan.road_distance(p)<1.3: color=Color("cfbc8a")
			var index: int=(z*32+x)*3
			pixels[index]=color.r8; pixels[index+1]=color.g8; pixels[index+2]=color.b8
	elapsed_ms=(Time.get_ticks_usec()-begin)/1000.0
