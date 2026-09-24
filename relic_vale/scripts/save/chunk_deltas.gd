class_name ValeChunkDeltas
extends RefCounted
## Content-addressed records make the main save an atomic manifest. Unchanged base scenery is never saved.
const FIELDS=["opened_chests","gathered_resources","defeated_unique","discoveries","resource_states"]
static func bucket(id: String) -> String:
	var parts:=id.split("/")
	if parts.size()>=3 and parts[1] in ["resource","enemy","poi"]: return parts[2]
	if parts.size()>=3 and parts[1]=="region": return "region_"+parts[2]
	return "authored"
static func pack(data: Dictionary,path: String) -> bool:
	var records: Dictionary={}
	for field in FIELDS:
		for id in data.get(field,{}):
			var key: String=bucket(str(id))
			if not records.has(key): records[key]={}
			if not records[key].has(field): records[key][field]={}
			records[key][field][id]=data[field][id]
		data[field]={}
	for key in data.world.get("discovered",{}):
		if not records.has(key): records[key]={}
		records[key].map=data.world.discovered[key]
	data.world.discovered={}
	var directory: String=path+".chunks"
	if FileAccess.file_exists(directory.get_base_dir()): return false
	if DirAccess.make_dir_recursive_absolute(directory)!=OK: return false
	var manifest: Dictionary={}
	for key in records:
		var json: String=JSON.stringify(records[key],"",true)
		var name: String=json.sha256_text()+".json"
		var destination: String=directory+"/"+name
		if not FileAccess.file_exists(destination) or FileAccess.get_file_as_string(destination).sha256_text()!=name.trim_suffix(".json"):
			var file:=FileAccess.open(destination+".tmp",FileAccess.WRITE)
			if file==null: return false
			file.store_string(json); file.flush()
			var error: Error=file.get_error(); file.close()
			if error!=OK or FileAccess.get_file_as_string(destination+".tmp").sha256_text()!=name.trim_suffix(".json"): return false
			if DirAccess.rename_absolute(destination+".tmp",destination)!=OK: return false
		manifest[key]=name
	data.chunk_manifest=manifest
	return true
static func unpack(data: Dictionary,path: String) -> bool:
	if not data.get("chunk_manifest",{}) is Dictionary: return false
	if not data.has("world"): data.world={}
	if not data.world.has("discovered"): data.world.discovered={}
	for key in data.get("chunk_manifest",{}):
		var name: String=str(data.chunk_manifest[key])
		if name.length()!=69 or not name.ends_with(".json") or not name.trim_suffix(".json").is_valid_hex_number(): return false
		var file: String=path+".chunks/"+name
		if not FileAccess.file_exists(file): return false
		var json: String=FileAccess.get_file_as_string(file)
		if json.sha256_text()!=name.trim_suffix(".json"): return false
		var parser:=JSON.new()
		if parser.parse(json)!=OK: return false
		var record: Variant=parser.data
		if not record is Dictionary: return false
		for field in FIELDS:
			if not record.get(field,{}) is Dictionary: return false
			if not data.has(field): data[field]={}
			data[field].merge(record.get(field,{}))
		if record.has("map"):
			if not valid_map(record.map): return false
			data.world.discovered[key]=record.map
	return true

static func valid_map(record: Variant) -> bool:
	if not record is Dictionary: return false
	for field in ["biome","poi","title"]:
		if not record.get(field,"") is String: return false
	for field in ["roads","water"]:
		if not record.get(field,[]) is Array: return false
		for points in record.get(field,[]):
			if not points is Array or points.size()!=(4 if field=="roads" else 2): return false
			for value in points:
				if not (value is float or value is int) or not is_finite(float(value)): return false
	return true

static func prune(path: String) -> void:
	# Only generated hash records inside this slot's directory are eligible.
	# Keep both atomic manifests, including the previous recoverable save.
	var keep: Dictionary={}
	for manifest_path in [path,path+".bak"]:
		if not FileAccess.file_exists(manifest_path): continue
		var parser:=JSON.new()
		if parser.parse(FileAccess.get_file_as_string(manifest_path))!=OK: return
		var data: Variant=parser.data
		if not data is Dictionary or not data.get("chunk_manifest",{}) is Dictionary: return
		for name in data.get("chunk_manifest",{}).values(): keep[str(name)]=true
	var dir:=DirAccess.open(path+".chunks")
	if dir==null: return
	for name in dir.get_files():
		if name.length()==69 and name.ends_with(".json") and name.trim_suffix(".json").is_valid_hex_number() and not keep.has(name): dir.remove(name)
