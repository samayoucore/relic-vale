extends Control
var hud: ValeHUD
func _draw() -> void:
	if is_instance_valid(hud): hud.draw_stats(self)
func _process(_delta: float) -> void:
	queue_redraw()
