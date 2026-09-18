extends PanelContainer
## Drop target for exercise items (basket or side tray). Native Godot DnD:
## _can_drop_data / _drop_data. The InteractionFlow decides what the drop
## means (into basket = +1, out to tray = -1) and whether the answer is done.

var flow: CanvasLayer

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item")

func _drop_data(_pos: Vector2, data: Variant) -> void:
	if flow:
		flow.drop_into(name, data.source_node)
