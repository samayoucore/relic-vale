extends Node
## Injected only into instrumented QA exports by build_qa.ps1.
func _ready() -> void:
	await get_tree().process_frame
	print("PHASE10_QA_LAUNCH")
	var runner:=Node.new()
	runner.set_script(load("res://tests/phase10_active.gd"))
	get_tree().current_scene.add_child(runner)
