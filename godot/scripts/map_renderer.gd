extends Node2D

var world
var tilemap: TileMapLayer
var props_layer: Node2D

const WANG_TILE_SIZE := 16
const TERRAIN_TEXTURE := "res://assets/terrain/tileset-grass-dirt-v3.png"

func _ready() -> void:
	render_props()
	render_decals()
	render_clutter()

func render_decals() -> void:
	# Flat ground decals (cart tracks, footprints, puddles) sit just above the
	# tilemap, below every other layer — they read as marks pressed into the dirt.
	if world == null:
		return
	var decals_layer := Node2D.new()
	decals_layer.name = "PathDecals"
	decals_layer.z_index = 1
	add_child(decals_layer)
	for decal in world.WORLD1_PATH_DECALS:
		var sprite := Sprite2D.new()
		sprite.name = "Decal_" + decal.id
		sprite.texture = load(decal.sprite_path) as Texture2D
		if sprite.texture == null:
			print("ERROR: Decal texture not found: " + decal.sprite_path)
			sprite.queue_free()
			continue
		var tile: Vector2i = decal.tile
		sprite.position = Vector2(tile) * world.TILE_SIZE + Vector2.ONE * world.TILE_SIZE * 0.5
		sprite.z_index = 1
		decals_layer.add_child(sprite)

func render_clutter() -> void:
	# Grass and farmyard clutter (art brief §3-4): purely decorative, non-blocking,
	# each item gets an anchored shadow blob drawn first for grounding (art brief §5).
	if world == null:
		return
	var clutter_layer := Node2D.new()
	clutter_layer.name = "Clutter"
	add_child(clutter_layer)
	var all_clutter: Array = []
	all_clutter.append_array(world.WORLD1_GRASS_CLUTTER)
	all_clutter.append_array(world.WORLD1_FARM_CLUTTER)
	for item in all_clutter:
		var tile: Vector2i = item.tile
		var base_pos: Vector2 = Vector2(tile) * world.TILE_SIZE + Vector2.ONE * world.TILE_SIZE * 0.5
		var item_scale: float = item.get("scale", 1.0)

		var shadow := Sprite2D.new()
		shadow.texture = load(world.SHADOW_BLOB_SPRITE) as Texture2D
		if shadow.texture != null:
			shadow.position = base_pos + Vector2(3, 10) * item_scale
			shadow.scale = Vector2.ONE * item_scale * 0.8
			shadow.z_index = 3
			shadow.modulate.a = 0.45
			clutter_layer.add_child(shadow)

		var sprite := Sprite2D.new()
		sprite.name = "Clutter_" + item.id
		sprite.texture = load(item.sprite_path) as Texture2D
		if sprite.texture == null:
			print("ERROR: Clutter texture not found: " + item.sprite_path)
			sprite.queue_free()
			continue
		sprite.position = base_pos
		sprite.position.y -= 6
		sprite.scale = Vector2.ONE * item_scale
		sprite.z_index = 4
		clutter_layer.add_child(sprite)

	# Border framing (art brief §6): dense bushes ringing the map edge, no
	# shadow needed — they read as background mass, not focal props.
	for item in world.WORLD1_BORDER_CLUTTER:
		var tile: Vector2i = item.tile
		var base_pos: Vector2 = Vector2(tile) * world.TILE_SIZE + Vector2.ONE * world.TILE_SIZE * 0.5
		var sprite := Sprite2D.new()
		sprite.name = "Border_" + item.id
		sprite.texture = load(item.sprite_path) as Texture2D
		if sprite.texture == null:
			continue
		sprite.position = base_pos
		sprite.scale = Vector2.ONE * item.get("scale", 1.0)
		sprite.z_index = 4
		clutter_layer.add_child(sprite)

func render_props() -> void:
	if world == null:
		return
	if props_layer == null:
		props_layer = Node2D.new()
		props_layer.name = "Props"
		props_layer.z_index = 3
		add_child(props_layer)
		# Clear existing props
		for child in props_layer.get_children():
			child.queue_free()

	var prop_list = world.get_world_props(world.id)
	for prop in prop_list:
		var tile: Vector2i = prop.get("tile", Vector2i(-1, -1))
		var base_pos: Vector2
		if tile.x >= 0:
			base_pos = Vector2(tile) * world.TILE_SIZE + Vector2.ONE * world.TILE_SIZE * 0.5
		else:
			base_pos = Vector2(randf() * 1536, randf() * 1152)

		# Anchored shadow (art brief §5) for every vertical prop except flat ground
		# decorations that already read as flush with the ground (flower pots).
		if prop.id != "flower-pot":
			var shadow := Sprite2D.new()
			shadow.texture = load(world.SHADOW_BLOB_SPRITE) as Texture2D
			if shadow.texture != null:
				shadow.position = base_pos + Vector2(4, 12)
				shadow.scale = Vector2.ONE * 1.3
				shadow.z_index = 2
				shadow.modulate.a = 0.4
				props_layer.add_child(shadow)

		var sprite := Sprite2D.new()
		sprite.name = "Prop_" + prop.id
		sprite.texture = load(prop.sprite_path) as Texture2D
		if sprite.texture == null:
			print("ERROR: Prop texture not found: " + prop.sprite_path)
			sprite.queue_free()
			continue
		sprite.position = base_pos
		sprite.position.y -= 8
		sprite.z_index = 3
		props_layer.add_child(sprite)
		print("Prop rendered: " + prop.id)

func setup(world_data) -> void:
	world = world_data
	build_tilemap()

func build_tilemap() -> void:
	tilemap = TileMapLayer.new()
	tilemap.name = "PixelLabWorld"

	# Build tileset from the PixelLab v3 grass/dirt Wang sheet
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(WANG_TILE_SIZE, WANG_TILE_SIZE)

	var source := _build_tileset_source(TERRAIN_TEXTURE)
	if source == null:
		push_error("Failed to load " + TERRAIN_TEXTURE)
		return

	tileset.add_source(source, 0)
	tilemap.tile_set = tileset
	tilemap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Scale: 16px tiles * 3 = 48px to match world.TILE_SIZE
	tilemap.scale = Vector2.ONE * 3.0
	tilemap.z_index = -10
	add_child(tilemap)

	rebuild_tilemap()

# Recomputes the Wang-autotiled terrain from world.path_mask and repaints the
# real TileMapLayer cells. Call this again any time path_mask changes at
# runtime (e.g. from the in-game map editor's Paint tool) so painting
# actually swaps the ground tile, not just an overlay drawn on top of it.
func rebuild_tilemap() -> void:
	if world == null or world.path_mask.is_empty() or tilemap == null:
		push_error("World path_mask is unavailable; cannot derive terrain")
		return

	# Vertex-grid Wang autotiling (per PixelLab tileset guide): terrain is painted
	# on a (COLS+1)x(ROWS+1) vertex grid, and each cell reads its four corner vertices.
	# A vertex is "lower" (dirt/path) if ANY of its up-to-4 touching cells is on the
	# walkable path network — this makes dirt blend outward from paths/buildings/props
	# with soft rounded corners instead of a blocky per-cell stamp.
	var vcols: int = world.COLS + 1
	var vrows: int = world.ROWS + 1
	var vertex_dirt: Array = []
	vertex_dirt.resize(vrows)
	for vy in vrows:
		var vrow: Array = []
		vrow.resize(vcols)
		for vx in vcols:
			var dirt := false
			for cy in [vy - 1, vy]:
				for cx in [vx - 1, vx]:
					if cy >= 0 and cy < world.ROWS and cx >= 0 and cx < world.COLS and world.path_mask[cy][cx]:
						dirt = true
			vrow[vx] = dirt
		vertex_dirt[vy] = vrow

	for y in world.ROWS:
		for x in world.COLS:
			var nw: bool = vertex_dirt[y][x]
			var ne: bool = vertex_dirt[y][x + 1]
			var sw: bool = vertex_dirt[y + 1][x]
			var se: bool = vertex_dirt[y + 1][x + 1]
			var wang_id := 0
			if nw: wang_id += 8
			if ne: wang_id += 4
			if sw: wang_id += 2
			if se: wang_id += 1
			var atlas_col := wang_id % 4
			var atlas_row := wang_id / 4
			tilemap.set_cell(Vector2i(x, y), 0, Vector2i(atlas_col, atlas_row))

func _build_tileset_source(texture_path: String) -> TileSetAtlasSource:
	# Load through Godot's resource system
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Cannot load texture: " + texture_path)
		return null

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(WANG_TILE_SIZE, WANG_TILE_SIZE)
	source.margins = Vector2i(0, 0)
	source.separation = Vector2i(0, 0)

	for y in 4:
		for x in 4:
			source.create_tile(Vector2i(x, y))

	return source
