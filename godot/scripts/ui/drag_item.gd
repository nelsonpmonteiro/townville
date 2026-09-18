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
