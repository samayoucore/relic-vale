class_name ValeCombat
extends RefCounted

static func hit(player: Node3D, target: Mossling, amount: int, context: Dictionary = {}) -> void:
	if target.dead: return
	if player is ValeCompanionActor:
		target.take_damage(amount,(target.global_position-player.global_position).normalized(),context)
		if context.has("status"): target.statuses.apply(context.status,3,3 if context.status in ["burn","poison"] else .3)
		return
	var info: Dictionary=context.duplicate()
	var stats: Dictionary=State.stats()
	if info.get("element","")=="fire": amount=ceili(amount*(1.0+float(stats.fire_percent)))
	if player.statuses.has("might"): amount=ceili(amount*(1.0+float(player.statuses.effects.might.power)))
	if player.dodge_bonus>0:
		amount=ceili(amount*1.25)
		player.dodge_bonus=0
	target.take_damage(amount,(target.global_position-player.global_position).normalized(),info)
	if info.has("status"): target.statuses.apply(info.status,4,3 if info.status in ["burn","poison"] else .35)
	if randf()<float(stats.get("burn_chance",0)): target.statuses.apply("burn",3,3)
	if randf()<float(stats.get("slow_chance",0)): target.statuses.apply("slow",3,.35)
	if randf()<float(stats.get("vampiric",0)): player.restore_health(3)
	if not info.get("secondary",false): player.on_combat_hit(target,info)

static func projectile(parent: Node3D, source: Node3D, direction: Vector3, amount: int, friendly: bool, config: Dictionary) -> ValeProjectile:
	var node: ValeProjectile=load("res://scenes/combat/Projectile.tscn").instantiate()
	node.source=source
	node.direction=direction.normalized()
	node.damage=amount
	node.friendly=friendly
	node.info=config.duplicate()
	node.color=Color(config.get("color","b3cfe0"))
	node.speed=float(config.get("projectile_speed",12))
	node.distance_left=float(config.get("range",12))
	node.splash_radius=float(config.get("splash_radius",0))
	parent.add_child(node)
	node.global_position=source.global_position+Vector3(0,.6,0)+node.direction*.6
	return node
