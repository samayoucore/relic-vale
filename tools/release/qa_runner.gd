extends SceneTree
## External developer harness; never packaged in player distributions.
func _initialize() -> void:
	start.call_deferred()
func start() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	current_scene=game
	root.add_child(game)
	var runner=Node.new()
	runner.set_script(load(OS.get_environment("VALE_QA_SCRIPT")))
	game.add_child(runner)
