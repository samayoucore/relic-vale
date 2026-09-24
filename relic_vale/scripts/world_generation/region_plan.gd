class_name ValeRegionPlan
extends RefCounted
## Pure data worker. All positions are relative to a logical chunk; never create scene nodes here.
const BIOMES=["Briar Meadow","Elderwood","Fallen March"]
var seed_value: int
var cx: int
var cz: int
var starter: Dictionary
var starter_roads: Array
var starter_pois: Array
var roads: Array=[]
var pois: Array=[]
var result: Dictionary={}
var terrain_noise:=FastNoiseLite.new()
var biome_noise:=FastNoiseLite.new()

static func key(x: int,z: int) -> String: return "%d,%d" % [x,z]
static func divide(value: int, divisor: int) -> int:
	@warning_ignore("integer_division")
	var q: int=value/divisor
	return q-1 if value<0 and value%divisor!=0 else q
func hash_at(x: int,z: int,salt: int=0) -> int: return (str(seed_value)+"/"+key(x,z)+"/"+str(salt)).hash()
func roll(x: int,z: int,salt: int=0) -> float: return float(hash_at(x,z,salt)%100000)/100000.0

func setup(seed_id: int,x: int,z: int,base: Dictionary,paths: Array,features: Array) -> void:
	seed_value=seed_id; cx=x; cz=z
	starter=base; starter_roads=paths; starter_pois=features
	terrain_noise.seed=seed_value+3101; terrain_noise.frequency=.024; terrain_noise.fractal_octaves=2
	biome_noise.seed=seed_value; biome_noise.frequency=.012; biome_noise.fractal_octaves=3
	context()

func region(rx: int,rz: int) -> Dictionary:
	var origin:=Vector2((rx*8-4-cx)*32,(rz*8-4-cz)*32)
	var west:=origin+Vector2(0,64+roll(rx,rz,20)*112)
	var east:=origin+Vector2(256,64+roll(rx+1,rz,20)*112)
	var north:=origin+Vector2(64+roll(rx,rz,21)*112,0)
	var south:=origin+Vector2(64+roll(rx,rz+1,21)*112,256)
	var center:=origin+Vector2(112+roll(rx,rz,22)*32,112+roll(rx,rz,23)*32)
	var routes: Array=[]
	var features: Array=[]
	if rx==0 and rz==0:
		var offset:=Vector2(cx*32,cz*32)
		for road in starter_roads:
			var copy: Array=[]
			for p in road: copy.append(p-offset)
			routes.append(copy)
		for poi in starter_pois:
			var copy: Dictionary=poi.duplicate(true)
			copy.position-=offset; copy.access-=offset
			features.append(copy)
		for edge in [west,east,north,south]:
			var closest: Vector2=features[0].access
			for feature in features:
				if feature.access.distance_squared_to(edge)<closest.distance_squared_to(edge): closest=feature.access
			routes.append([edge,closest])
	else:
		for edge in [west,east,north,south]: routes.append([edge,center])
		var local_chunk:=Vector2i(3+hash_at(rx,rz,3)%2,3+hash_at(rx,rz,4)%2)
		var p: Vector2=origin+Vector2(local_chunk)*32+Vector2(16,16)
		var chance: float=roll(rx,rz,7)
		var kind: String="settlement" if chance<.3 else (["grove","ruin","circle","mine","chapel","pond"][hash_at(rx,rz,8)%6])
		var feature: Dictionary={"kind":kind,"position":p,"access":p+Vector2(0,12 if kind=="settlement" else 6),"radius":13.0 if kind=="settlement" else 8.0,"id":"%d/region/%s/landmark" % [seed_value,key(rx,rz)]}
		if kind=="settlement":
			feature.settlement=["forest","mining","trading"][hash_at(rx,rz,9)%3]
			feature.title=["Alder","Copper","Lantern","Willow","Mist","Stone"][hash_at(rx,rz,10)%6]+["stead","hollow","cross","watch"][hash_at(rx,rz,11)%4]
		features.append(feature)
		routes.append([center,feature.access])
		# Small roadside discoveries between rare major settlements.
		for i in 2:
			var small: Vector2=origin+Vector2(40+roll(rx,rz,30+i)*175,40+roll(rx,rz,40+i)*175)
			if small.distance_to(p)<42: continue
			var cell:=Vector2(floor(small.x/32)*32+16,floor(small.y/32)*32+16)
			features.append({"kind":["camp","wagon","hunter","well","lumber","graveyard"][hash_at(rx,rz,50+i)%6],"position":cell,"access":cell+Vector2(0,6),"id":"%d/region/%s/poi/%d" % [seed_value,key(rx,rz),i]})
	return {"roads":routes,"pois":features}

func context() -> void:
	roads.clear(); pois.clear()
	var rx: int=divide(cx+4,8); var rz: int=divide(cz+4,8)
	for x in range(rx-1,rx+2):
		for z in range(rz-1,rz+2):
			var plan: Dictionary=region(x,z)
			for road in plan.roads:
				for i in range(road.size()-1):
					if Rect2(Vector2(-12,-12),Vector2(56,56)).intersects(Rect2(road[i],Vector2.ZERO).expand(road[i+1]).grow(4)):
						roads.append([road[i],road[i+1]])
			for poi in plan.pois:
				if Rect2(Vector2(-30,-30),Vector2(92,92)).has_point(poi.position): pois.append(poi)

func noise(p: Vector2,cell_size: int,salt: int) -> float:
	var gx: int=cx*32+floori(p.x); var gz: int=cz*32+floori(p.y)
	var x: int=divide(gx,cell_size); var z: int=divide(gz,cell_size)
	var fx: float=(float(gx-x*cell_size)+fposmod(p.x,1))/cell_size
	var fz: float=(float(gz-z*cell_size)+fposmod(p.y,1))/cell_size
	fx=fx*fx*(3-2*fx); fz=fz*fz*(3-2*fz)
	return lerpf(lerpf(roll(x,z,salt),roll(x+1,z,salt),fx),lerpf(roll(x,z+1,salt),roll(x+1,z+1,salt),fx),fz)*2-1

func near_start() -> bool: return absi(cx)<12 and absi(cz)<12
func hub_distance(p: Vector2) -> float:
	if not near_start(): return 10000
	var world_p: Vector2=p+Vector2(cx*32,cz*32)
	return world_p.distance_to(world_p.clamp(Vector2(-25,-36),Vector2(49,26)))
func raw_height(p: Vector2) -> float:
	var value: float=noise(p,64,3101)*3+noise(p,128,711)*2
	if near_start():
		var global_p:=p+Vector2(cx*32,cz*32)
		var legacy: float=terrain_noise.get_noise_2d(global_p.x,global_p.y)*3.8+.45
		value=lerpf(legacy,value,smoothstep(110,230,maxf(absf(global_p.x),absf(global_p.y))))
	return value*smoothstep(0,12,hub_distance(p))
func weights(p: Vector2) -> Vector3:
	var n: float=noise(p,128,307)*.42+noise(p,64,306)*.12
	if near_start():
		var global_p:=p+Vector2(cx*32,cz*32)
		n=lerpf(biome_noise.get_noise_2d(global_p.x,global_p.y),n,smoothstep(110,230,maxf(absf(global_p.x),absf(global_p.y))))
	var a: float=1-smoothstep(-.25,.03,n); var c: float=smoothstep(.07,.3,n)
	return Vector3(a,maxf(0,1-a-c),c)
func water_distance(p: Vector2) -> float:
	var stripe: int=divide(cx+4,8)
	var z: float=float(cz*32)+p.y
	var d: float=INF
	for strip in range(stripe-1,stripe+2):
		var river_x: float=float(strip*256-cx*32)+62+sin(z*.035+float(seed_value%19)*.04)*8+sin(z*.087)*2
		d=minf(d,absf(p.x-river_x)-1.8)
		for row in range(divide(cz+4,8)-1,divide(cz+4,8)+2):
			var lake_z: float=float((row*8+2-cz)*32)+19
			var lake_x: float=float(strip*256-cx*32)+65+sin((float(cz*32)+lake_z)*.035+float(seed_value%19)*.04)*8+sin((float(cz*32)+lake_z)*.087)*2
			d=minf(d,p.distance_to(Vector2(lake_x,lake_z))-9)
	return d
func road_distance(p: Vector2) -> float:
	var d: float=INF
	for road in roads: d=minf(d,p.distance_to(Geometry2D.get_closest_point_to_segment(p,road[0],road[1])))
	return d
func height_at(p: Vector2) -> float:
	var h: float=raw_height(p)
	for poi in pois:
		var distance: float=p.distance_to(poi.position); var radius: float=poi.get("radius",7.0)
		if distance<radius+7: h=lerpf(raw_height(poi.position),h,smoothstep(radius,radius+7,distance))
	var wet: float=water_distance(p)
	if hub_distance(p)>1 and wet<4:
		h=lerpf(-.65,h,smoothstep(-.5,4,wet))
		var rd: float=road_distance(p)
		if rd<3: h=lerpf(.1,h,smoothstep(1.8,3,rd))
	if hub_distance(p)==0: h=-.04
	return h
func clear(p: Vector2,padding: float=2.1) -> bool:
	if hub_distance(p)<1 or road_distance(p)<padding or water_distance(p)<.7: return false
	for poi in pois:
		if p.distance_to(poi.position)<float(poi.get("radius",7)): return false
	return true

func ground_color(p: Vector2) -> Color:
	var n: float=(noise(p,4,213)+1)*.5
	var w: Vector3=weights(p)
	var a:=Color("788957").lerp(Color("839362"),n)
	var b:=Color("5e795b").lerp(Color("70845a"),n)
	var c:=Color("7e8861").lerp(Color("919373"),n)
	var mixed: Color=a*w.x+b*w.y+c*w.z
	if near_start(): mixed=a.lerp(b,smoothstep(10,22,float(cx*32)+p.x)).lerp(mixed,smoothstep(0,22,hub_distance(p)))
	var wet: float=water_distance(p)
	if wet<3 and hub_distance(p)>1: mixed=Color("a69b73").lerp(mixed,smoothstep(0,3,wet))
	mixed.a=1
	return mixed

func grid_height(p: Vector2,grid: Dictionary) -> float:
	var a:=Vector2(floor(p.x/2)*2,floor(p.y/2)*2); var f: Vector2=(p-a)/2
	if not grid.has(a) or not grid.has(a+Vector2(2,2)): return height_at(p)
	var b: float=grid[a+Vector2(2,0)]; var c: float=grid[a+Vector2(0,2)]
	if f.x+f.y<=1: return grid[a]*(1-f.x-f.y)+b*f.x+c*f.y
	return grid[a+Vector2(2,2)]*(f.x+f.y-1)+b*(1-f.y)+c*(1-f.x)

func geometry(data: Dictionary) -> void:
	var ground:=PackedVector3Array(); var normals:=PackedVector3Array(); var colors:=PackedColorArray()
	var road_vertices:=PackedVector3Array(); var water:=PackedVector3Array(); var uv:=PackedVector2Array()
	var water_colors:=PackedColorArray()
	for x in range(0,32,2):
		for z in range(0,32,2):
			var a:=Vector2(x,z); var color: Color=ground_color(a+Vector2.ONE)
			for offset in [Vector2.ZERO,Vector2(2,0),Vector2(0,2),Vector2(2,0),Vector2(2,2),Vector2(0,2)]:
				var p: Vector2=a+offset
				ground.append(Vector3(p.x,data.grid[p],p.y)); colors.append(color)
				normals.append(Vector3(data.grid[p-Vector2(2,0)]-data.grid[p+Vector2(2,0)],4,data.grid[p-Vector2(0,2)]-data.grid[p+Vector2(0,2)]).normalized())
			for road in roads:
				if a.distance_to(Geometry2D.get_closest_point_to_segment(a,road[0],road[1]))>5: continue
				var side: Vector2=(road[1]-road[0]).normalized().orthogonal()*1.55
				var ribbon:=PackedVector2Array([road[0]-side,road[1]-side,road[1]+side,road[0]+side])
				for tri in [[a,a+Vector2(2,0),a+Vector2(0,2)],[a+Vector2(2,0),a+Vector2(2,2),a+Vector2(0,2)]]:
					for polygon in Geometry2D.intersect_polygons(ribbon,PackedVector2Array(tri)):
						for j in range(1,polygon.size()-1):
							for p in [polygon[0],polygon[j],polygon[j+1]]: road_vertices.append(Vector3(p.x,grid_height(p,data.grid)+.06,p.y))
	data.bridges=[]
	for road in roads:
		var steps: int=ceili(road[0].distance_to(road[1]))
		for step in steps:
			var p: Vector2=road[0].lerp(road[1],float(step)/steps)
			if Rect2(0,0,32,32).has_point(p) and water_distance(p)<2: data.bridges.append({"p":p,"yaw":-atan2((road[1]-road[0]).y,(road[1]-road[0]).x)+PI/2})
	for x in 32:
		for z in 32:
			var a:=Vector2(x,z)
			if water_distance(a+Vector2(.5,.5))>.3: continue
			for o in [Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]:
				water.append(Vector3(a.x+o.x,-.18,a.y+o.y)); uv.append((a+o)*.2)
				water_colors.append(Color(clampf(-water_distance(a+o)/3,0,1),0,0,1))
	data.terrain_vertices=ground; data.terrain_normals=normals; data.terrain_colors=colors
	data.road_vertices=road_vertices; data.water_vertices=water; data.water_uv=uv
	data.water_colors=water_colors
	for prop in data.props: prop.y=grid_height(prop.p,data.grid)
	for asset in data.cover:
		for prop in data.cover[asset]: prop.y=grid_height(prop.p,data.grid)

func natural_clearing(p: Vector2,padding: float=19) -> bool:
	# Sparse, deterministic meadow openings leave usable homestead sites in every region.
	var center:=Vector2((divide(cx,4)*4+2-cx)*32+16,(divide(cz,4)*4+2-cz)*32+16)
	return absf(p.x-center.x)<padding and absf(p.y-center.y)<padding

func generate() -> void:
	var began: int=Time.get_ticks_usec()
	var rng:=RandomNumberGenerator.new(); rng.seed=hash_at(cx,cz,327)
	var w: Vector3=weights(Vector2(16,16))
	var biome: String=BIOMES[0] if w.x>w.y and w.x>w.z else (BIOMES[1] if w.y>w.z else BIOMES[2])
	var data: Dictionary={"x":cx,"z":cz,"biome":biome,"props":[],"enemies":[],"poi":{},"cover":{},"grid":{},"roads":roads.duplicate(true),"features":pois.duplicate(true)}
	for poi in pois:
		if Rect2(0,0,32,32).has_point(poi.position): data.poi=poi.duplicate(true); break
	if starter.has(key(cx,cz)):
		var old: Dictionary=starter[key(cx,cz)]
		data.biome=old.biome
		for prop in old.props:
			var copy: Dictionary=prop.duplicate(true); copy.p-=Vector2(cx*32,cz*32); data.props.append(copy)
		for enemy in old.enemies:
			var copy: Dictionary=enemy.duplicate(true); copy.p-=Vector2(cx*32,cz*32); data.enemies.append(copy)
	else:
		var desired: int=10 if biome==BIOMES[0] else (24 if biome==BIOMES[1] else 13)
		var trees: Array=[]
		for i in desired*4:
			if trees.size()>=desired: break
			var p:=Vector2(rng.randf()*32,rng.randf()*32)
			if not clear(p,3): continue
			var blocked: bool=false
			for tree in trees:
				if tree.distance_to(p)<4: blocked=true
			if blocked: continue
			trees.append(p)
			data.props.append({"asset":"tree_pineTallA" if biome==BIOMES[1] and i%3 else "tree_oak","p":p,"h":rng.randf_range(4.5,6.7),"yaw":rng.randf()*360,"solid":true})
			for j in 7:
				var under: Vector2=p+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(1.2,2.2)
				if clear(under): data.props.append({"asset":["plant_bushSmall","rock_smallA","log","mushroom_redGroup"][j%4],"p":under,"h":rng.randf_range(.3,.7),"yaw":rng.randf()*360,"solid":false})
		for i in 2:
			var p:=Vector2(rng.randf_range(4,28),rng.randf_range(4,28))
			if clear(p): data.enemies.append({"p":p,"id":"%d/enemy/%s/%d" % [seed_value,key(cx,cz),i],"kind":(["slime","wolf"] if biome==BIOMES[0] else (["wolf","bat","witch"] if biome==BIOMES[1] else ["skeleton","archer","witch"]))[rng.randi()%2],"level":clampi(2+absi(cx)/10+absi(cz)/10,2,12)})
	for x in range(-2,35,2):
		for z in range(-2,35,2): data.grid[Vector2(x,z)]=height_at(Vector2(x,z))
	for i in 1600:
		var p:=Vector2(rng.randf()*32,rng.randf()*32)
		if not clear(p,1.75) or rng.randf()>.72+noise(p,8,55)*.3: continue
		var asset: String="Grass_Common_Short" if i%3 else "Grass_Wispy_Short"
		if i%21==0: asset="Fern_1" if w.y>.35 else "Clover_1"
		if i%37==0: asset="Flower_3_Group"
		if i%43==0: asset="Pebble_Round_1"
		if i%61==0: asset="Mushroom_Common"
		if not data.cover.has(asset): data.cover[asset]=[]
		data.cover[asset].append({"p":p,"h":rng.randf_range(.4,.72) if "Grass" in asset else rng.randf_range(.22,.5),"yaw":rng.randf()*360,"tint":Color("93a772").lerp(Color("b1b783"),rng.randf()*.6)})
	geometry(data)
	data.generation_ms=(Time.get_ticks_usec()-began)/1000.0
	result=data
