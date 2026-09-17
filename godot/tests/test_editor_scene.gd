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
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		print("  - ", child.name, " (", child.get_class(), ")")
	quit(0)
