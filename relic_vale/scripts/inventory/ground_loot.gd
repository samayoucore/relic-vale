class_name ValeGroundLoot
extends ValeInteractable
var loot_id: String
var record: Dictionary={}
var age: float=0
var loot_sprite: Sprite3D

func _ready() -> void:
	kind="loot"
	var best_id: String=""
	var best_rank: int=-1
	for id in record.bundle.items:
		if id=="astral_shard": continue
		var item: Dictionary=State.items.get(id,{})
		var rank: int=State.RARITY_COLORS.keys().find(item.get("rarity","Common"))
		if rank>best_rank:
			best_rank=rank
			best_id=id
	var item: Dictionary=State.items.get(best_id,{"name":"Roadside loot","icon":"coin","color":"d9c180"})
	title=item.name
	if record.bundle.items.size()>1: title+=" + supplies"
	super._ready()
	marker.position.y=1.3
	loot_sprite=Sprite3D.new()
	loot_sprite.texture=PixelArt.item_icon(item.icon,Color(item.color))
	loot_sprite.pixel_size=.025
	loot_sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	loot_sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(loot_sprite)
	if best_rank>=2:
		Feel.ring(self,global_position,.55,Color(item.color),0)
		var beam:=MeshInstance3D.new()
		var geometry:=CylinderMesh.new()
		geometry.top_radius=.04
		geometry.bottom_radius=.14
		geometry.height=2.5 if best_rank<4 else 3.5
		geometry.radial_segments=6
		var material:=StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color=Color(Color(item.color),.28)
		geometry.material=material
		beam.mesh=geometry
		beam.position.y=geometry.height*.5
		add_child(beam)
		if best_rank>=3: Feel.sound("shrine",.35,1.25 if best_rank==3 else .8)

func _process(delta: float) -> void:
	if State.modal or State.paused: return
	age+=delta
	loot_sprite.position.y=.45+absf(sin(age*6))*maxf(0,1-age)*.6+sin(age*2)*.04
	if age<.65: return
	var player:=get_tree().get_first_node_in_group("player") as ValePlayer
	if player and player.global_position.distance_to(global_position)<1.9: collect()

func prompt() -> String:
	return "Pick up "+title

func interact(_player: ValePlayer) -> void:
	collect()

func collect() -> void:
	if not State.pending_loot.has(loot_id): return
	State.pending_loot.erase(loot_id)
	var message: String=ValeLoot.grant(record.bundle)
	State.notification.emit("Collected  ·  "+message)
	Feel.sound("loot",.65)
	queue_free()
