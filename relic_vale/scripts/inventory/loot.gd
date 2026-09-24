class_name ValeLoot
extends RefCounted

static func roll(table_id: String, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng==null:
		rng=RandomNumberGenerator.new()
		rng.randomize()
	var table: Dictionary=State.loot_tables.get(table_id,{})
	var copper: Array=table.get("coins",[0,0])
	var result: Dictionary={"coins":rng.randi_range(copper[0],copper[1]),"items":{}}
	for drop in table.get("drops",[]):
		if rng.randf()<float(drop.chance): result.items[drop.id]=int(drop.get("count",1))
	return result

static func grant(bundle: Dictionary) -> String:
	State.coins+=int(bundle.get("coins",0))
	var names: Array[String]=["%d copper" % int(bundle.get("coins",0))]
	for id in bundle.get("items",{}):
		var count: int=int(bundle.items[id])
		if id=="astral_shard":
			State.astral_shards+=count
			names.append("%d Astral Shard" % count)
		else:
			if not State.items.has(id): continue
			State.add_item(id,count)
			names.append("%s ×%d" % [State.items[id].name,count])
	State.changed.emit()
	return ", ".join(names)

static func prepare(bundle: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng==null:
		rng=RandomNumberGenerator.new()
		rng.randomize()
	var result: Dictionary={"coins":bundle.get("coins",0),"items":{}}
	for id in bundle.get("items",{}):
		if State.items.get(id,{}).get("kind","") in ["weapon","armor","accessory"] and not State.generated_items.has(id):
			for i in int(bundle.items[id]):
				var rarity: String=State.items[id].rarity
				var roll: float=rng.randf()
				if roll<.015: rarity="Legendary"
				elif roll<.07 and rarity not in ["Legendary"]: rarity="Epic"
				elif roll<.22 and rarity in ["Common","Uncommon"]: rarity="Rare"
				elif rarity=="Common": rarity="Uncommon"
				result.items[ValeGear.create(id,rarity,rng)]=1
		else: result.items[id]=bundle.items[id]
	return result
