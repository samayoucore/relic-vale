class_name PixelArt
extends RefCounted
## LPC layers are composited at original resolution. Original slime/VFX use tiny code-drawn textures.
static var frames_cache: Dictionary = {}
static var icon_cache: Dictionary = {}

static func item_icon(kind: String, color: Color) -> Texture2D:
	var key: String=kind+color.to_html()
	if icon_cache.has(key): return icon_cache[key]
	var img:=Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in range(3,29):
		for x in range(3,29):
			var fill: bool=false
			match kind:
				"sword","greatsword","daggers": fill=abs(x+y-29)<(4 if kind=="greatsword" else 2) and x>9 and y<24 or (x>=7 and x<=18 and y>=20 and y<=22) or (x>=8 and x<=11 and y>=22 and y<29)
				"bow": fill=(abs(Vector2(x-10,y-16).length()-11)<2 and x>10) or (x==11 and y>5 and y<28)
				"staff": fill=(x>=14 and x<=16 and y>=10) or abs(x-15)+abs(y-8)<6
				"bottle": fill=(x>=11 and x<=20 and y>=13 and y<=26) or (x>=14 and x<=17 and y>=6 and y<=13) or (x>=12 and x<=19 and y>=5 and y<=7)
				"ring": fill=Vector2(x-16,y-18).length()>6 and Vector2(x-16,y-18).length()<9 or abs(x-16)+abs(y-8)<5
				"coin": fill=Vector2(x-16,y-16).length()<10
				"hood": fill=(Vector2(x-16,y-16).length()<11 and y<25) and not (x>=11 and x<=20 and y>=13 and y<24)
				"armor": fill=(x>=10 and x<=22 and y>=9 and y<=27) or (y>=8 and y<15 and x>=5 and x<=27)
				"leaf": fill=pow((x-16.0+(y-16)*.35)/7,2)+pow((y-16.0)/12,2)<1
				"heart": fill=(Vector2(x-11,y-12).length()<6 or Vector2(x-21,y-12).length()<6 or abs(x-16)<(27-y)*.75 and y>=12 and y<27)
				"bolt": fill=Geometry2D.is_point_in_polygon(Vector2(x,y),PackedVector2Array([Vector2(17,3),Vector2(8,18),Vector2(15,18),Vector2(12,29),Vector2(25,12),Vector2(18,12)]))
				_: fill=abs(x-16)*.8+abs(y-16)*.6<8
			if fill:
				var tint: Color=color.lightened(.25) if x<15 and y<17 else color.darkened(.2 if x>19 else 0)
				img.set_pixel(x,y,tint)
	icon_cache[key]=ImageTexture.create_from_image(img)
	return icon_cache[key]

static func enemy_frames(kind: String) -> SpriteFrames:
	if kind=="slime": return slime_frames()
	if frames_cache.has(kind): return frames_cache[kind]
	var frames:=SpriteFrames.new()
	frames.set_animation_speed("default",7 if kind=="wolf" else 5)
	for f in range(4):
		var img:=Image.create(40,36,false,Image.FORMAT_RGBA8)
		var step: int=1 if f%2==0 else -1
		if kind=="bat":
			img.fill_rect(Rect2i(16,15,9,11),Color("797697"))
			img.fill_rect(Rect2i(17,12,2,5),Color("aba1ba"))
			img.fill_rect(Rect2i(23,12,2,5),Color("aba1ba"))
			for x in range(4,36):
				var wing: int=absi(x-20)/3
				img.fill_rect(Rect2i(x,16+step*wing,1,4),Color("858399"))
			img.fill_rect(Rect2i(18,19,2,2),Color("eed195"))
			img.fill_rect(Rect2i(23,19,2,2),Color("eed195"))
		elif kind=="mimic":
			img.fill_rect(Rect2i(5,13,31,18),Color("614b39"))
			img.fill_rect(Rect2i(7,11,27,8),Color("a48657"))
			img.fill_rect(Rect2i(7,21,27,7),Color("302f34"))
			for x in range(9,33,5): img.fill_rect(Rect2i(x,20,3,4+(1 if f%2 else 0)),Color("d8d3b5"))
			img.fill_rect(Rect2i(7,28,27,3),Color("b3925f"))
			img.fill_rect(Rect2i(18,12,4,8),Color("e3c783"))
		elif kind=="wolf":
			# Original side-on woodland wolf: angular ears, muzzle, four stepping legs.
			img.fill_rect(Rect2i(6,15,24,10),Color("576778"))
			img.fill_rect(Rect2i(10,13,18,9),Color("8b9ba5"))
			img.fill_rect(Rect2i(25,10,9,13),Color("a5b2b1"))
			img.fill_rect(Rect2i(31,17,7,6),Color("cbd0bd"))
			img.fill_rect(Rect2i(26,5,3,8),Color("5b6d7a"))
			img.fill_rect(Rect2i(31,7,3,5),Color("71828b"))
			img.fill_rect(Rect2i(2,12,6,5),Color("71828b"))
			for x in [9,15,24,29]: img.fill_rect(Rect2i(x+step*(1 if x%2 else -1),23,3,9),Color("657789"))
			img.fill_rect(Rect2i(30,14,2,2),Color("e9c47b"))
			img.fill_rect(Rect2i(36,17,2,3),Color("273c43"))
		else:
			var bone:=Color("d7d3b5") if kind!="elite" else Color("b6ce9a")
			var armor:=Color("677b89") if kind!="guardian" else Color("a99c68")
			img.fill_rect(Rect2i(15,3,11,10),bone)
			img.fill_rect(Rect2i(16,13,9,12),armor)
			for y in [15,18,21]: img.fill_rect(Rect2i(17,y,7,1),bone)
			img.fill_rect(Rect2i(19,13,2,11),bone)
			img.fill_rect(Rect2i(11,14+step,3,10),bone)
			img.fill_rect(Rect2i(27,14-step,3,10),bone)
			img.fill_rect(Rect2i(16,25,3,7+step),bone)
			img.fill_rect(Rect2i(23,25,3,7-step),bone)
			img.fill_rect(Rect2i(16,7,3,3),Color("314650"))
			img.fill_rect(Rect2i(22,7,3,3),Color("314650"))
			img.fill_rect(Rect2i(30,9,2,15),Color("c8d9d3"))
			img.fill_rect(Rect2i(28,24,6,2),armor)
			if kind=="guardian":
				img.fill_rect(Rect2i(10,14,7,5),Color("9b9774"))
				img.fill_rect(Rect2i(24,14,8,5),Color("9b9774"))
				img.fill_rect(Rect2i(12,19,3,12),Color("756784"))
				img.fill_rect(Rect2i(26,19,3,12),Color("756784"))
				img.fill_rect(Rect2i(14,2,13,3),Color("d9bd76"))
				for x in [14,19,25]: img.fill_rect(Rect2i(x,0,2,3),Color("e5cd8c"))
			if kind=="archer":
				img.fill_rect(Rect2i(28,7,3,22),Color("a9916d"))
				img.fill_rect(Rect2i(33,11,1,14),Color("d8d9c1"))
			if kind=="witch":
				img.fill_rect(Rect2i(12,16,16,16),Color("8b7b9d"))
				img.fill_rect(Rect2i(11,6,18,3),Color("6b6583"))
				img.fill_rect(Rect2i(17,1,7,6),Color("7e7292"))
		frames.add_frame("default",ImageTexture.create_from_image(img))
	frames_cache[kind]=frames
	return frames

const SKINS: Array[String]=["e0b990","b98461","825840","efcdb1","573e35"]
const HAIR: Array[String]=["805333","d1b879","373644","b36e52","c6c7b2"]
const OUTFITS: Array[String]=["386c79","62734f","9b5751","786a9a","b09a61"]

static func clean_appearance(raw: Dictionary) -> Dictionary:
	var result: Dictionary={"skin":0,"hair":0,"outfit":0,"cape":bool(raw.get("cape",true))}
	for key in ["skin","hair","outfit"]:
		if raw.get(key,0) is int or raw.get(key,0) is float: result[key]=clampi(int(raw.get(key,0)),0,4)
	return result

static func character_frames(keeper: bool = false, appearance: Dictionary = {}) -> SpriteFrames:
	var look:=clean_appearance(appearance)
	var key: String = "keeper" if keeper else "hero"+JSON.stringify(look)
	if frames_cache.has(key): return frames_cache[key]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim in ["idle", "walk", "slash"]:
		var layers: Array[Image] = []
		for i in range(6):
			var source: Texture2D=load("res://assets/2d/lpc/%d_%s.png" % [i, anim])
			var img: Image=source.get_image()
			img.convert(Image.FORMAT_RGBA8)
			if i in [1,2,3,5] or (i in [0,4] and not keeper):
				var tint: Color = Color(OUTFITS[look.outfit]) if not keeper else Color("92664b")
				if i in [0,4]: tint=Color(SKINS[look.skin])
				if i == 2: tint = Color("3e4754")
				if i == 1: tint = Color("624633")
				if i == 5: tint = Color(HAIR[look.hair]) if not keeper else Color("c6c7b2")
				for y in img.get_height():
					for x in img.get_width():
						var c := img.get_pixel(x,y)
						if c.a < 0.01: continue
						# Preserve the eye whites/iris and outline in the modular head layer.
						if i==4 and (c.b>c.r*.95 or c.r<.25): continue
						var lightness: float = maxf(maxf(c.r,c.g),c.b)
						var color: Color = tint * (0.35 + lightness * 0.85)
						color.a = c.a
						img.set_pixel(x,y,color)
			layers.append(img)
		var canvas := Image.create(layers[0].get_width(),256,false,Image.FORMAT_RGBA8)
		if not keeper and look.cape: draw_cloak(canvas,anim,false)
		for layer in layers: canvas.blend_rect(layer,Rect2i(Vector2i.ZERO,layer.get_size()),Vector2i.ZERO)
		if not keeper and look.cape: draw_cloak(canvas,anim,true)
		var texture := ImageTexture.create_from_image(canvas)
		for dir in range(4):
			var name: String = "%s_%d" % [anim,dir]
			frames.add_animation(name)
			frames.set_animation_speed(name, 16.0 if anim=="slash" else (10.0 if anim=="walk" else 2.0))
			frames.set_animation_loop(name, anim != "slash")
			for column in (9 if anim == "walk" else (6 if anim == "slash" else 2)):
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(column*64,dir*64,64,64)
				frames.add_frame(name,atlas)
	# Keep preview randomization bounded; existing sprites retain their frame resources.
	for old_key in frames_cache.keys():
		if str(old_key).begins_with("hero") and old_key!=key: frames_cache.erase(old_key)
	frames_cache[key] = frames
	return frames

static func draw_cloak(canvas: Image, anim: String, back_only: bool) -> void:
	# Original simple traveling cloak, aligned to the licensed LPC poses.
	for direction in range(4):
		if back_only and direction!=0: continue
		for frame in int(canvas.get_width()/64):
			var sway: int=1 if anim=="walk" and frame%4>=2 else 0
			for y in range(31,53):
				var left: int=23-(y-31)/5+sway
				var right: int=40+(y-31)/6+sway
				if direction==1: left=34
				if direction==3: right=29
				for x in range(left,right):
					var c:=Color("a77447")
					if x==left or x==right-1 or y==52: c=Color("534332")
					elif x<left+3: c=Color("76503a")
					elif y<34: c=Color("d2aa66")
					canvas.set_pixel(frame*64+x,direction*64+y,c)

static func slime_frames() -> SpriteFrames:
	if frames_cache.has("slime"): return frames_cache.slime
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default",5)
	for f in range(4):
		var img := Image.create(40,36,false,Image.FORMAT_RGBA8)
		for y in range(36):
			for x in range(40):
				var v := Vector2((x-20.0)/(15.0+sin(f*PI/2.0)),(y-23.0)/(10.0-sin(f*PI/2.0)))
				var d: float = v.length()
				if d > 1.0: continue
				var c := Color("294c45")
				if d < .87: c = Color("669978") if y > 22 else Color("97c596")
				if d < .6 and y < 20: c = Color("c0dfac")
				if y >= 21 and y <= 24 and (x==15 or x==16 or x==24 or x==25): c=Color("233d39")
				if y==27 and x>=19 and x<=21: c=Color("436a56")
				img.set_pixel(x,y,c)
		for y in range(7,15):
			for x in range(19,24):
				if x-19 < (y-7)/2+1: img.set_pixel(x,y,Color("d9ca80"))
		frames.add_frame("default",ImageTexture.create_from_image(img))
	frames_cache.slime=frames
	return frames

static func shadow_texture() -> ImageTexture:
	var img := Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d: float = Vector2(x-15.5,y-15.5).length()/16.0
			img.set_pixel(x,y,Color(0.06,0.10,0.10,clampf((1.0-d)*0.6,0,.38)))
	return ImageTexture.create_from_image(img)

static func add_shadow(parent: Node3D, radius: float = .65) -> Sprite3D:
	var shadow := Sprite3D.new()
	shadow.texture = shadow_texture()
	shadow.pixel_size = radius/16.0
	shadow.rotation_degrees.x = -90
	shadow.position.y = .035
	shadow.shaded = false
	parent.add_child(shadow)
	return shadow
