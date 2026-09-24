class_name ValeStatus
extends Node
## Shared player/enemy status clock. Refreshes duration rather than stacking unbounded timers.
var effects: Dictionary={}
var actor: Node3D

func _ready() -> void:
	actor=get_parent()

func apply(id: String, duration: float, power: float = 1.0) -> void:
	if id not in ["burn","slow","poison","stun","regeneration","might","shield","haste"]: return
	var previous: Dictionary=effects.get(id,{})
	effects[id]={"remaining":maxf(duration,previous.get("remaining",0)),"power":maxf(power,previous.get("power",0)),"tick":previous.get("tick",1.0)}

func has(id: String) -> bool:
	return effects.has(id)

func move_multiplier() -> float:
	if has("stun"): return 0
	return clampf(1.0-float(effects.slow.power),.2,1) if has("slow") else (1.0+float(effects.haste.power) if has("haste") else 1.0)

func clear() -> void:
	effects.clear()

func _physics_process(delta: float) -> void:
	if State.modal or State.paused: return
	if actor is Mossling and actor.dead:
		clear()
		return
	for id in effects.keys():
		if not effects.has(id): continue
		var effect: Dictionary=effects[id]
		effect.remaining-=delta
		effect.tick-=delta
		if effect.tick<=0 and effect.remaining>=-.05:
			effect.tick+=1.0
			if id in ["burn","poison"]: actor.receive_status_damage(maxi(1,roundi(effect.power)))
			elif id=="regeneration": actor.restore_health(maxi(1,roundi(effect.power)))
		if effect.remaining<=0: effects.erase(id)
