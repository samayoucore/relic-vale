extends SceneTree
func _initialize() -> void:
	for size in [16,24,32,48,64,128,256]:
		var icon:=Image.new()
		icon.load_svg_from_string(FileAccess.get_file_as_string("res://assets/ui/relic_vale_icon.svg"),float(size)/512)
		icon.save_png("res://../tools/release/icon-"+str(size)+".png")
	var licenses:=FileAccess.open("res://docs/licenses/GODOT-THIRD-PARTY.txt",FileAccess.WRITE)
	licenses.store_string("Godot "+Engine.get_version_info().string+"\n\n"+Engine.get_license_text()+"\n\n"+JSON.stringify(Engine.get_copyright_info(),"\t")+"\n\n"+JSON.stringify(Engine.get_license_info(),"\t")); licenses.close()
	quit()
