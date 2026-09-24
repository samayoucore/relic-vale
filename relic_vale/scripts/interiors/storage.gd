class_name ValeStorage
extends RefCounted
static func show(ui: ValeInterface,id: String) -> void:
	if not State.interior_data.has("storage"): State.interior_data.storage={}
	if not State.interior_data.storage.has(id): State.interior_data.storage[id]={}
	var inventory: Dictionary=State.interior_data.storage[id]
	ui.page("storage","Household storage","BELONGINGS / "+id.get_slice("/building/",1))
	var columns:=ui.row(ui.body); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var left:=ui.scroll(columns); var right:=ui.scroll(columns)
	ui.text(left,"SATCHEL","Heading"); ui.text(right,"CHEST","Heading")
	for item in State.inventory.keys():
		if State.items[item].kind=="quest" or item in State.equipment.values(): continue
		ui.button(left,"Store "+State.items[item].name+" ×%d" % State.inventory[item],func():
			inventory[item]=int(inventory.get(item,0))+1; ValeLife.consume(item,1); State.changed.emit(); State.save_requested.emit(); show(ui,id))
	for item in inventory.keys():
		ui.button(right,"Take "+State.items[item].name+" ×%d" % inventory[item],func():
			inventory[item]=int(inventory[item])-1
			if int(inventory[item])<=0: inventory.erase(item)
			State.add_item(item); State.save_requested.emit(); show(ui,id))
