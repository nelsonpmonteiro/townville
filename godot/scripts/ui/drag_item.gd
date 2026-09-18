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

# Items placed in a fair-sharing group stay draggable. If another item is
# dropped directly over them, forward that drop to the surrounding group.
func _share_zone() -> Control:
	var node: Node = get_parent()
	while node:
		if node.name.begins_with("ShareZone_"):
			return node as Control
		node = node.get_parent()
	return null

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("item", false) and _share_zone() != null

func _drop_data(_pos: Vector2, data: Variant) -> void:
	var zone := _share_zone()
	if zone:
		zone.flow.drop_into(zone.name, data.source_node as Control)
