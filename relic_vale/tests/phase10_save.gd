extends Node
var passed: int=0
var failed: int=0
var checks: Array=[]
var game: Node
const SLOT="user://phase10-save-test.json"
func _ready() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"check":label})
	if ok: passed+=1
	else: failed+=1
	print("PHASE10_SAVE ","PASS " if ok else "FAIL ",label)
func write_text(path: String,value: String) -> void:
	var f:=FileAccess.open(path,FileAccess.WRITE); f.store_string(value); f.close()
func run() -> void:
	game=get_tree().current_scene
	game.test_mode=true; game.gameplay_started=true; game.hud.close_modal()
	game.new_world(20260907)
	var base: Dictionary=ValeSave.snapshot(Vector3(0,0,3.6))
	check(ValeSave.valid(base),"Fresh snapshot validates")
	for field in ["level","xp","hp","coins","astral_shards","world_seed","kills","attack_count"]:
		for bad in [NAN,INF,-INF,-1,"wrong",{},null,1.5]:
			var data: Dictionary=base.duplicate(true); data[field]=bad
			check(not ValeSave.valid(data),"Reject %s = %s" % [field,str(bad)])
	for bad in ["wrong",{},null,9.5,100]:
		var data: Dictionary=base.duplicate(true); data.version=bad
		check(not ValeSave.valid(data),"Reject invalid save version "+str(bad))
	for key in ["origin_x","origin_z"]:
		var data: Dictionary=base.duplicate(true); data.world[key]="999999999999999999999999"
		check(not ValeSave.valid(data),"Reject overflowing logical "+key)
	var nan: Dictionary=base.duplicate(true); nan.inventory.wood=NAN
	check(not ValeSave.valid(nan),"Reject nonfinite inventory")
	check(ValeSave.write(Vector3(0,0,3.6),SLOT),"Create atomic first save")
	State.coins=123
	check(ValeSave.write(Vector3(1,0,3.6),SLOT),"Replace with backup")
	check(int(ValeSave.read(SLOT).get("coins",-1))==123,"Read new snapshot")
	var original: String=FileAccess.get_file_as_string(SLOT)
	State.inventory.wood=-1
	check(not ValeSave.write(Vector3.ZERO,SLOT),"Invalid live state refuses save")
	check(FileAccess.get_file_as_string(SLOT)==original,"Failed validation preserves primary bytes")
	State.inventory.erase("wood")
	write_text(SLOT+".tmp","interrupted write")
	check(int(ValeSave.read(SLOT).get("coins",-1))==123,"Interrupted temporary write ignored")
	write_text(SLOT,"broken")
	check(not ValeSave.read(SLOT).is_empty() and ValeSave.last_error.contains("backup"),"Corrupt primary recovers backup")
	var backup: String=FileAccess.get_file_as_string(SLOT+".bak")
	check(ValeSave.write(Vector3.ZERO,SLOT),"Repair damaged primary")
	check(FileAccess.get_file_as_string(SLOT+".bak")==backup,"Repair preserves good backup")
	State.gathered_resources["20260907/resource/1,1/tree_0"]=true
	check(ValeSave.write(Vector3.ZERO,SLOT),"Write chunk delta")
	var packed: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SLOT))
	var filename: String=packed.chunk_manifest["1,1"]
	write_text(SLOT+".chunks/"+filename,"truncated")
	check(not ValeSave.read(SLOT).is_empty() and ValeSave.last_error.contains("backup"),"Corrupt chunk recovers intact backup")
	backup=FileAccess.get_file_as_string(SLOT+".bak")
	check(ValeSave.write(Vector3.ZERO,SLOT),"Rewriting heals corrupt content-addressed chunk")
	check(ValeSave.checked_read(SLOT,SLOT).get("gathered_resources",{}).has("20260907/resource/1,1/tree_0"),"Healed chunk passes digest and schema")
	packed=JSON.parse_string(FileAccess.get_file_as_string(SLOT)); packed.chunk_manifest["1,1"]="../journey.json"
	write_text(SLOT,JSON.stringify(packed))
	check(ValeSave.checked_read(SLOT,SLOT).is_empty(),"Manifest path traversal rejected")
	write_text(SLOT,"bad"); write_text(SLOT+".bak","bad")
	var coins: int=State.coins
	check(ValeSave.read(SLOT).is_empty() and State.coins==coins,"Two invalid copies leave live journey untouched")
	write_text("user://phase10-file-parent","This is a file, not a folder.")
	check(not ValeSave.write(Vector3.ZERO,"user://phase10-file-parent/slot.json"),"Unwritable slot reports failure")
	check(OS.get_user_data_dir().replace("\\","/").ends_with("Godot/app_userdata/RelicValePrototype"),"Version upgrade preserves original user-data directory")
	Preferences.temporary=true
	var volume: float=Preferences.values.Master
	Preferences.set_option("Master",NAN)
	check(Preferences.values.Master==volume,"Nonfinite settings ignored")
	check(Preferences.values.mount_key in ["V","T","Y"],"Mount binding remains valid")
	var large: Dictionary=base.duplicate(true); large.inventory.wood=120000; large.coins=12000000
	check(ValeSave.valid(large),"Large earned stacks remain representable")
	ValeSave.apply(large)
	check(State.inventory.get("wood")==120000 and State.coins==12000000,"Loading does not silently truncate validated stacks or currency")
	var file:=FileAccess.open("res://docs/PHASE_10_SAVE_TESTS.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":checks},"\t")); file.close()
	print("PHASE10_SAVE_RESULT ",passed," / ",failed)
	game.process_mode=Node.PROCESS_MODE_DISABLED
	await Feel.shutdown(); get_tree().quit(0 if failed==0 else 1)
