class_name ValeGear
extends RefCounted
## Unique equipment instances are recipes: base ID, rarity and up to three affix IDs.
static func materialize(id: String, recipe: Dictionary) -> bool:
	if not id.begins_with("gear_") or State.base_items.has(id): return false
	var base_id: String=str(recipe.get("base",""))
	var rarity: String=str(recipe.get("rarity","Common"))
	if not State.base_items.has(base_id) or not State.RARITY_COLORS.has(rarity): return false
	if State.base_items[base_id].get("kind","") not in ["weapon","armor","accessory"]: return false
	if not recipe.get("affixes",[]) is Array: return false
	var item: Dictionary=State.base_items[base_id].duplicate(true)
	item.id=id
	item.base_id=base_id
	item.rarity=rarity
	item.color=State.RARITY_COLORS[rarity]
	var scale: float={"Common":1.0,"Uncommon":1.1,"Rare":1.2,"Epic":1.35,"Legendary":1.5}[rarity]
	for stat in item.get("stats",{}):
		if stat in ["attack","defense","max_hp"]: item.stats[stat]=roundi(float(item.stats[stat])*scale)
	var names: Array[String]=[]
	var affixes: Array=[]
	for affix in recipe.get("affixes",[]):
		if not State.affix_data.has(affix) or affixes.has(affix) or affixes.size()>=3: continue
		affixes.append(affix)
		names.append(State.affix_data[affix].name)
		for stat in State.affix_data[affix].modifiers: item.stats[stat]=float(item.stats.get(stat,0))+float(State.affix_data[affix].modifiers[stat])
	item.name=(" ".join(names)+" " if not names.is_empty() else "")+item.name
	item.affixes=affixes
	State.items[id]=item
	State.generated_items[id]={"base":base_id,"rarity":rarity,"affixes":affixes}
	return true

static func create(base_id: String, rarity: String = "", rng: RandomNumberGenerator = null) -> String:
	if not State.base_items.has(base_id): return base_id
	if rng==null:
		rng=RandomNumberGenerator.new()
		rng.randomize()
	if rarity.is_empty(): rarity=State.base_items[base_id].rarity
	var amount: int={"Common":0,"Uncommon":1,"Rare":1,"Epic":2,"Legendary":3}.get(rarity,0)
	var pool: Array=State.affix_data.keys()
	var affixes: Array=[]
	for i in amount:
		var index: int=rng.randi_range(0,pool.size()-1)
		affixes.append(pool[index])
		pool.remove_at(index)
	var id: String="gear_%07d" % State.next_item_id
	State.next_item_id+=1
	if materialize(id,{"base":base_id,"rarity":rarity,"affixes":affixes}): return id
	return base_id
