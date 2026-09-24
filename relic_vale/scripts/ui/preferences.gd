extends Node
signal changed
const PATH="user://preferences.cfg"
const PRESETS={
	"Minimal":{"render_scale":.7,"shadows":0,"foliage":.4,"distance":0,"particles":.4,"water":0,"fog":0,"ao":false},
	"Medium":{"render_scale":.85,"shadows":1,"foliage":.7,"distance":1,"particles":.7,"water":1,"fog":1,"ao":false},
	"High":{"render_scale":1.0,"shadows":2,"foliage":.9,"distance":2,"particles":1.0,"water":2,"fog":2,"ao":true},
	"Ultra":{"render_scale":1.0,"shadows":3,"foliage":1.0,"distance":3,"particles":1.4,"water":3,"fog":3,"ao":true}}
var values: Dictionary={"preset":"Medium","pixelated":false,"pixel_strength":1,"resolution":Vector2i(1280,720),"display":"Windowed","vsync":true,"fps_limit":60,"ui_scale":1.0,"Master":.65,"Music":.3,"SFX":.7,"screen_shake":true,"damage_numbers":true}
var loaded: bool=false
var safe_mode: bool=false
var temporary: bool=false
func _ready() -> void:
	values.mount_key="V"
	values.merge(PRESETS.Medium,true)
	var cfg:=ConfigFile.new()
	if cfg.load(PATH)==OK:
		for key in values:
			var value: Variant=cfg.get_value("settings",key,values[key])
			if value is float and not is_finite(value): continue
			if typeof(value)==typeof(values[key]) or (value is int and values[key] is float): values[key]=value
	values.ui_scale=clampf(values.ui_scale,.8,1.5)
	if not values.mount_key in ["V","T","Y"]: values.mount_key="V"
	values.foliage=clampf(values.foliage,.3,1)
	values.render_scale=clampf(values.render_scale,.5,1.25)
	for key in ["shadows","distance","water","fog"]: values[key]=clampi(int(values[key]),0,3)
	values.pixel_strength=clampi(int(values.pixel_strength),0,2)
	values.particles=clampf(float(values.particles),.3,1.5)
	values.fps_limit=clampi(int(values.fps_limit),0,240)
	values.resolution=Vector2i(clampi(values.resolution.x,960,3840),clampi(values.resolution.y,540,2160))
	if not values.display in ["Windowed","Borderless","Fullscreen"]: values.display="Windowed"
	if not values.preset in ["Minimal","Medium","High","Ultra","Custom"]: values.preset="Medium"
	for key in ["Master","Music","SFX"]: values[key]=clampf(float(values[key]),0,1)
	safe_mode="--safe-mode" in OS.get_cmdline_user_args()
	if safe_mode:
		values.merge(PRESETS.Minimal,true); values.preset="Minimal"
		values.display="Windowed"; values.resolution=Vector2i(1280,720)
		values.ui_scale=1.0; values.pixelated=false; values.vsync=true; values.fps_limit=60
	loaded=true
func save() -> void:
	if temporary: return
	var args:=OS.get_cmdline_user_args().duplicate(); args.erase("--safe-mode")
	if OS.is_debug_build() and not args.is_empty(): return
	var cfg:=ConfigFile.new()
	for key in values: cfg.set_value("settings",key,values[key])
	if cfg.save(PATH+".tmp")==OK:
		var check:=ConfigFile.new()
		if check.load(PATH+".tmp")==OK: DirAccess.rename_absolute(PATH+".tmp",PATH)
func set_option(key: String,value: Variant,advanced: bool=false) -> void:
	if not values.has(key): return
	if value is float and not is_finite(value): return
	if typeof(value)!=typeof(values[key]) and not (value is int and values[key] is float): return
	values[key]=value
	if advanced: values.preset="Custom"
	changed.emit(); save()
func set_preset(value: String) -> void:
	if not PRESETS.has(value): return
	values.merge(PRESETS[value],true); values.preset=value
	changed.emit(); save()
