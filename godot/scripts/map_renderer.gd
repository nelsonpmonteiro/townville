extends Node2D

var world
var tilemap: TileMapLayer
var props_layer: Node2D

const WANG_TILE_SIZE := 16
const TERRAIN_TEXTURE := "res://assets/terrain/tileset-grass-dirt-v3.png"

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
		# Clear existing props
		for child in props_layer.get_children():
			child.queue_free()
	
	var prop_list = world.get_world_props(world.id)
	for prop in prop_list:
		var sprite := Sprite2D.new()
		sprite.name = "Prop_" + prop.id
		sprite.texture = load(prop.sprite_path) as Texture2D
		if sprite.texture == null:
			print("ERROR: Prop texture not found: " + prop.sprite_path)
			sprite.queue_free()
			continue
		var tile: Vector2i = prop.get("tile", Vector2i(-1, -1))
		if tile.x >= 0:
			sprite.position = Vector2(tile) * world.TILE_SIZE + Vector2.ONE * world.TILE_SIZE * 0.5
			sprite.position.y -= 8
		else:
			sprite.position = Vector2(randf() * 1536, randf() * 1152)
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

	if world == null or world.path_mask.is_empty():
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

	# Scale: 16px tiles * 3 = 48px to match world.TILE_SIZE
	tilemap.scale = Vector2.ONE * 3.0
	tilemap.z_index = -10
	add_child(tilemap)

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
