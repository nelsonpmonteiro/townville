extends Node2D

var world
var terrain_sprite: Sprite2D
var props_layer: Node2D
var buildings_layer: Node2D

func _ready() -> void:
	render_props()

func render_props() -> void:
	if world == null:
		return
	if props_layer == null:
		props_layer = Node2D.new()
		props_layer.name = "Props"
		props_layer.z_index = 3
		add_child(props_layer)
	var prop_list = world.get_world_props(world.id)
	for prop in prop_list:
		var tile: Vector2i = prop.get("tile", Vector2i(-1, -1))
		if tile.x < 0:
			continue
		var base_pos: Vector2 = Vector2(tile) * world.TILE_SIZE + Vector2.ONE * world.TILE_SIZE * 0.5
		var sprite := Sprite2D.new()
		sprite.name = "Prop_" + prop.id
		sprite.texture = load(prop.sprite_path) as Texture2D
		if sprite.texture == null:
			print("ERROR: Prop texture not found: " + prop.sprite_path)
			sprite.queue_free()
			continue
		sprite.position = base_pos
		sprite.z_index = 3
		props_layer.add_child(sprite)

func setup(world_data) -> void:
	world = world_data
	build_terrain()
	build_buildings()

func build_terrain() -> void:
	# Final map spec ships a single pre-composited raster (base terrain +
	# connector patches painted onto it) instead of a procedural tileset —
	# this guarantees pixel-exact match with the verified reference image.
	var texture := load(world.TERRAIN_TEXTURE) as Texture2D
	if texture == null:
		push_error("Failed to load " + world.TERRAIN_TEXTURE)
		return
	terrain_sprite = Sprite2D.new()
	terrain_sprite.name = "Terrain"
	terrain_sprite.texture = texture
	terrain_sprite.centered = false
	terrain_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	terrain_sprite.z_index = -10
	add_child(terrain_sprite)

func build_buildings() -> void:
	# renderRule (final map spec): scale image so height == renderHeightTiles*48px
	# preserving aspect ratio, center horizontally in footprint, bottom-align to
	# the footprint's bottom edge.
	buildings_layer = Node2D.new()
	buildings_layer.name = "Buildings"
	add_child(buildings_layer)
	for b in world.BUILDINGS:
		var texture := load(b.sprite) as Texture2D
		if texture == null:
			print("ERROR: Building texture not found: " + b.sprite)
			continue
		var target_height: float = b.renderHeightTiles * world.TILE_SIZE
		var aspect: float = float(texture.get_width()) / float(texture.get_height())
		var scaled_width: float = target_height * aspect

		var footprint_x: float = b.footprintCol * world.TILE_SIZE
		var footprint_y: float = b.footprintRow * world.TILE_SIZE
		var footprint_w: float = b.footprintW * world.TILE_SIZE
		var footprint_h: float = b.footprintH * world.TILE_SIZE

		var sprite := Sprite2D.new()
		sprite.name = "Building_" + b.id
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2(scaled_width / texture.get_width(), target_height / texture.get_height())
		sprite.position = Vector2(
			footprint_x + (footprint_w - scaled_width) / 2.0,
			footprint_y + footprint_h - target_height
		)
		sprite.z_index = 5
		buildings_layer.add_child(sprite)

		var label := Label.new()
		label.text = b.label
		label.position = sprite.position + Vector2(scaled_width / 2.0 - 30, -20)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.z_index = 6
		buildings_layer.add_child(label)
