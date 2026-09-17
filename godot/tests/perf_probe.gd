extends SceneTree

var frames := 0
var t0 := 0.0

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var scene = packed.instantiate()
	root.add_child(scene)
	t0 = Time.get_ticks_msec()

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 60:
		print("FRAMES_60_MS: ", Time.get_ticks_msec() - t0)
	if frames == 240:
		var ms = Time.get_ticks_msec() - t0
		print("FPS_AVG: ", 240.0 / (ms / 1000.0))
		print("ENGINE_FPS: ", Engine.get_frames_per_second())
		print("NODE_COUNT: ", root.get_child(root.get_child_count()-1).get_tree().get_node_count())
		print("ORPHANS: ", Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		print("PROCESS_MS: ", Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		print("PHYSICS_MS: ", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		print("DRAW_CALLS: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		print("OBJECTS_IN_FRAME: ", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		quit(0)
	return false
