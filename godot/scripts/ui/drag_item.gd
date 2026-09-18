extends TextureRect
## Draggable exercise item (egg / carrot / hay bale …). Uses Godot's native
## Control drag-and-drop: _get_drag_data returns the payload, the drop zone
## decides whether to accept it.

func _get_drag_data(_pos: Vector2) -> Variant:
	var preview := TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = Vector2(48, 48)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_drag_preview(preview)
	return {"item": true, "source_node": self}

# If a drop lands directly on top of another draggable item — unavoidable
# once a zone already has several items in it, and now common since basket
# items stay draggable (so the child can drag one back out to undo) —
# forward the drop to whichever drop-zone ancestor actually owns this item,
# instead of the drop being silently rejected right when a zone is full.
# Object.get() is safe on any node: returns null if the property doesn't
# exist, so this works for every DropZoneScript zone (basket, tray, source,
# array cell, share zone) without this script needing to know their names.
func _owning_zone() -> Node:
	var node: Node = get_parent()
	while node:
		if node.get("flow") != null:
			return node
		node = node.get_parent()
	return null

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("item", false) and _owning_zone() != null

func _drop_data(_pos: Vector2, data: Variant) -> void:
	var zone := _owning_zone()
	if zone:
		zone.flow.drop_into(zone.name, data.source_node as Control)
