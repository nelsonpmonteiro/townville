extends SceneTree

func _init() -> void:
	var scene = load("res://scenes/editor/simple_editor.tscn")
	if scene == null:
		print("ERROR: failed to load scene")
		quit(1)
		return
	var node = scene.instantiate()
	if node == null:
		print("ERROR: failed to instantiate")
		quit(1)
		return
	print("OK: scene instantiated")
	print("Children: ", node.get_child_count())
	for i in node.get_child_count():
		print("  - ", node.get_child(i).name)
	quit(0)
