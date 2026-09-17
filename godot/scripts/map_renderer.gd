extends Node2D

var world
var tilemap: TileMapLayer

const WANG_TILE_SIZE := 16

# Maps corner patterns [NW, NE, SW, SE] to Wang tile IDs 0-15
const CORNER_TO_WANG_ID := {
	["lower", "lower", "lower", "lower"]: 0,   # wang_0 - all dirt
	["lower", "lower", "lower", "upper"]: 1,   # wang_1
	["lower", "lower", "upper", "upper"]: 2,   # wang_3
	["lower", "upper", "lower", "lower"]: 3,   # wang_2
	["lower", "upper", "lower", "upper"]: 4,   # wang_5
	["lower", "upper", "upper", "lower"]: 5,   # wang_6
	["lower", "upper", "upper", "upper"]: 6,   # wang_7
	["upper", "lower", "lower", "lower"]: 7,   # wang_4
	["upper", "lower", "lower", "upper"]: 8,   # wang_9
	["upper", "lower", "upper", "lower"]: 9,   # wang_10
	["upper", "lower", "upper", "upper"]: 10,  # wang_11
	["upper", "upper", "lower", "lower"]: 11,  # wang_12
	["upper", "upper", "lower", "upper"]: 12,  # wang_13
	["upper", "upper", "upper", "lower"]: 13,  # wang_14
	["upper", "upper", "upper", "upper"]: 14,  # wang_15
}

func setup(world_data) -> void:
	world = world_data
	build_tilemap()

func build_tilemap() -> void:
	tilemap = TileMapLayer.new()
	tilemap.name = "PixelLabWorld"
	
	# Build tileset from PixelLab grass-dirt Wang sheet
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(WANG_TILE_SIZE, WANG_TILE_SIZE)
	
	var source := _build_tileset_source("res://assets/terrain/tileset-grass-dirt.png")
	if source == null:
		push_error("Failed to load tileset-grass-dirt.png")
		return
	
	tileset.add_source(source, 0)
	tilemap.tile_set = tileset
	
	# Load placements from PixelLab data
	var placements := _load_placements("res://assets/world1/placements.json")
	if placements.size() == 0:
		push_error("No placements loaded")
		return
	
	# Render each tile
	for p in placements:
		var corners: Array = p.corners
		var corner_key := [corners[0], corners[1], corners[2], corners[3]]
		var wang_id: int = CORNER_TO_WANG_ID.get(corner_key, 0)
		
		# Atlas coords: tileset is 4x4 grid of 16px tiles
		var atlas_col := wang_id % 4
		var atlas_row := wang_id / 4
		
		tilemap.set_cell(
			Vector2i(p.x, p.y),
			0,
			Vector2i(atlas_col, atlas_row)
		)
	
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

func _load_placements(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	
	var text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		return []
	
	return json.data
