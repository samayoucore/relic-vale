extends "res://tests/phase6_test.gd"
func run() -> void:
	game=get_tree().current_scene; await frames(40); game.player.god_mode=true
	game.active_save_path="user://phase6-validation.json"
	game.life.set_time(10); State.life_data.weather="Clear"
	var original: String=FileAccess.get_file_as_string("user://journey.json").sha256_text()
	var legacy: Dictionary=ValeSave.read("user://journey.json")
	check(not legacy.is_empty() and int(legacy.version)>=2 and int(legacy.version)<=ValeSave.VERSION,"Original user journey remains readable without rewriting it")
	for version in [2,3,4,5]:
		var migration: Dictionary=ValeSave.snapshot(game.player.position)
		migration.version=version
		for field in ["resource_states","residents","interior_data"]: migration.erase(field)
		migration.equipment.erase("Tool")
		var fixture: String="user://phase6-migration-"+str(version)+".json"
		var file:=FileAccess.open(fixture,FileAccess.WRITE); file.store_string(JSON.stringify(migration)); file.close()
		var old: Dictionary=ValeSave.read(fixture)
		check(not old.is_empty(),"Read a pre-gathering version "+str(version)+" save without new optional fields")
	var vendors: Array=["smith","merchant","willow_carpenter","willow_alchemist","willow_fisher","willow_farmer"]
	var arbitrage: bool=false
	for rep in [-40,0,30,70,100]:
		for faction in State.life_data.reputation: State.life_data.reputation[faction]=rep
		for buyer in vendors:
			for offer in State.merchant_data[ValeLife.category(buyer)].offers:
				if not State.items.has(offer[0]): continue
				for seller in vendors:
					arbitrage=arbitrage or ValeLife.item_price(seller,offer[0],true)>=ValeLife.item_price(buyer,offer[0])
	check(not arbitrage,"Merchant prices prevent purchase/resale arbitrage at every reputation tier")
	for faction in State.life_data.reputation: State.life_data.reputation[faction]=0
	var snapshot: Dictionary=ValeSave.snapshot(game.player.position)
	check(ValeSave.valid(snapshot),"Current v6 snapshot passes schema validation")
	for malformed in [{"resource_states":{"bad":{"hits":-1}}},{"residents":{"bad":{"identity":[]}}},{"interior_data":{"storage":{"bad":{"wood":"many"}}}},{"interior_data":{"active":{"return":{}}}}]:
		var bad: Dictionary=snapshot.duplicate(true); bad.merge(malformed,true)
		check(not ValeSave.valid(bad),"Reject malformed new save state: "+str(malformed.keys()[0]))
	var quest: String=""
	for id in State.items:
		if State.items[id].kind=="quest": quest=id; break
	State.add_item(quest)
	check(not ValeLife.trade("merchant",quest,true),"Generic selling protects quest items")
	State.equip("crude_axe")
	check(not ValeLife.trade("smith","crude_axe",true),"The only equipped tool is protected from selling")
	var settlement: ValeSettlement
	for node in game.generator.find_children("*","",true,false):
		if node is ValeSettlement: settlement=node; break
	check(settlement!=null,"Loaded world contains a generated settlement")
	if settlement:
		var id: String=settlement.definition.id
		var people: Dictionary={}
		for key in State.residents:
			if State.residents[key].settlement==id: people[key]=State.residents[key].duplicate(true)
		check(people.size()>=5,"Small generated settlements have at least five persistent residents")
		check(State.life_data.settlements[id].buildings.size()==4,"Generated settlement has shops, tavern and a home")
		var address: Dictionary=game.generator.address(settlement.global_position)
		game.generator.teleport_logical(int(address.x),int(address.z),ValeSave.vector(address.local)+Vector3(0,0,9)); await frames(15)
		var resource: ValeResource
		for node in get_tree().get_nodes_in_group("interactables"):
			if node is ValeResource and node.resource_id=="wood" and "/hub/" not in node.persistent_id: resource=node; break
		check(resource!=null,"Generated chunk has a physical tree")
		if resource:
			var tree_id: String=resource.persistent_id
			var tree_address: Dictionary=game.generator.address(resource.global_position)
			game.player.global_position=resource.global_position+Vector3(1.3,0,0); await frames(3)
			check(game.player.gathering.start(resource),"Strike generated tree using the equipped tool")
			await frames(55)
			var hits: int=resource.remaining()
			check(hits>0 and hits<resource.max_hits,"A partial harvest persists remaining hits")
			game.generator.teleport_logical(40,40); await frames(10)
			game.generator.teleport_logical(int(tree_address.x),int(tree_address.z),ValeSave.vector(tree_address.local)+Vector3(1.3,0,0)); await frames(15)
			resource=null
			for node in get_tree().get_nodes_in_group("interactables"):
				if node is ValeResource and node.persistent_id==tree_id: resource=node; break
			check(resource!=null and resource.remaining()==hits,"Partial tree damage survives chunk unloading and regeneration")
			if resource:
				for i in 8:
					if resource.remaining()==0: break
					resource.interact(game.player); await frames(58)
				check(resource.remaining()==0,"Finish harvesting the regenerated tree")
				game.generator.teleport_logical(40,40); await frames(8)
				game.generator.teleport_logical(int(tree_address.x),int(tree_address.z),ValeSave.vector(tree_address.local)+Vector3(1.3,0,0)); await frames(15)
				var depleted: bool=false
				for node in get_tree().get_nodes_in_group("interactables"):
					if node is ValeResource and node.persistent_id==tree_id: depleted=node.remaining()==0 and not node.model.visible and node.body.collision_layer==0
				check(depleted,"Reloaded harvested tree has a remnant and no intact model or trunk collision")
		game.generator.teleport_logical(int(address.x),int(address.z),ValeSave.vector(address.local)+Vector3(0,0,9)); await frames(10)
		var stable: bool=true
		for key in people: stable=stable and State.residents.get(key,{})==people[key]
		check(stable,"Generated resident identities, homes and workplaces survive unloading")
	check(game.save_game(false),"Persist generated resource and resident state")
	check(game.load_game(game.active_save_path),"Load the same v6 journey through the game entry point")
	check(FileAccess.get_file_as_string("user://journey.json").sha256_text()==original,"Original user journey remains byte-for-byte unchanged")
	print("PHASE6_VALIDATION_RESULT ",checks.size()," passed / ",failures.size()," failed")
	await Feel.shutdown(); get_tree().quit(0 if failures.is_empty() else 1)
