class_name WorldPack
extends RefCounted

const ACTIVE_MANIFEST := "manifest.json"
const CONTRACT_VERSION := 1
const WORLD_ID := "world1"
const TILE_SIZE := 48
const COLS := 32
const ROWS := 24
const WIDTH_PX := COLS * TILE_SIZE
const HEIGHT_PX := ROWS * TILE_SIZE

static func failure(message: String) -> Dictionary:
	return {"valid": false, "fallback": true, "error": message}

static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "required file is absent: " + path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "cannot read file: " + path}
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK or not json.data is Dictionary:
		return {"ok": false, "error": "invalid JSON object: " + path}
	return {"ok": true, "data": json.data}

static func safe_file(directory: String, relative_path: Variant) -> Dictionary:
	if not relative_path is String or relative_path.is_empty() or relative_path.is_absolute_path() or ".." in relative_path.replace("\\", "/").split("/"):
		return {"ok": false, "error": "file path must be a safe relative path"}
	var path := directory.path_join(relative_path)
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "required file is absent: " + relative_path}
	return {"ok": true, "path": path}

static func valid_tile(value: Variant) -> bool:
	return value is Array and value.size() == 2 and value[0] is float and value[1] is float and value[0] == floor(value[0]) and value[1] == floor(value[1]) and value[0] >= 0 and value[0] < COLS and value[1] >= 0 and value[1] < ROWS

static func load_from_directory(directory: String) -> Dictionary:
	var manifest_result := read_json(directory.path_join(ACTIVE_MANIFEST))
	if not manifest_result.ok:
		return failure(manifest_result.error)
	var manifest: Dictionary = manifest_result.data
	for field in ["contract_version", "world_id", "version", "tile_size", "cols", "rows", "width_px", "height_px", "art", "collision", "anchors"]:
		if not manifest.has(field):
			return failure("manifest field is required: " + field)
	if manifest.contract_version != CONTRACT_VERSION:
		return failure("unsupported contract_version")
	if manifest.world_id != WORLD_ID:
		return failure("world_id must be " + WORLD_ID)
	if not manifest.version is String or manifest.version.strip_edges().is_empty():
		return failure("version must be a non-empty string")
	if manifest.tile_size != TILE_SIZE or manifest.cols != COLS or manifest.rows != ROWS:
		return failure("logical dimensions must be 32x24 tiles at 48 pixels")
	if manifest.width_px != manifest.cols * manifest.tile_size or manifest.height_px != manifest.rows * manifest.tile_size:
		return failure("pixel dimensions do not match tile dimensions")
	if manifest.width_px != WIDTH_PX or manifest.height_px != HEIGHT_PX:
		return failure("world pixel dimensions must be 1536x1152")
	if not manifest.art is Dictionary or not manifest.collision is Dictionary or not manifest.anchors is Dictionary:
		return failure("art, collision, and anchors must be objects")

	var art: Dictionary = manifest.art
	if art.get("mode") != "single":
		return failure("art mode must be single")
	var art_file := safe_file(directory, art.get("file"))
	if not art_file.ok:
		return failure(art_file.error)
	var image := Image.new()
	if image.load(art_file.path) != OK:
		return failure("art file is not a readable image")
	if image.get_width() != WIDTH_PX or image.get_height() != HEIGHT_PX:
		return failure("single image dimensions must be 1536x1152")
	art["resolved_file"] = art_file.path

	var collision_file := safe_file(directory, manifest.collision.get("file"))
	if not collision_file.ok:
		return failure(collision_file.error)
	var collision_result := read_json(collision_file.path)
	if not collision_result.ok:
		return failure(collision_result.error)
	var collision: Dictionary = collision_result.data
	var walkable: Variant = collision.get("walkable")
	if not walkable is Array or walkable.size() != ROWS:
		return failure("collision must contain exactly 24 rows")
	for row in walkable:
		if not row is Array or row.size() != COLS:
			return failure("each collision row must contain exactly 32 cells")
		for cell in row:
			if cell != 0 and cell != 1 and cell != false and cell != true:
				return failure("collision cells must be 0/1 or booleans")

	var anchors_file := safe_file(directory, manifest.anchors.get("file"))
	if not anchors_file.ok:
		return failure(anchors_file.error)
	var anchors_result := read_json(anchors_file.path)
	if not anchors_result.ok:
		return failure(anchors_result.error)
	var anchors: Dictionary = anchors_result.data
	if not anchors.get("spawn") is Dictionary or not valid_tile(anchors.spawn.get("tile")):
		return failure("spawn anchor must contain an in-bounds tile")
	if not anchors.get("npcs") is Array or not anchors.get("buildings") is Array:
		return failure("anchors must contain npc and building arrays")
	for npc in anchors.npcs:
		if not npc is Dictionary or not npc.get("id") is String or npc.id.is_empty() or not valid_tile(npc.get("tile")):
			return failure("each NPC anchor requires id and in-bounds tile")
	for building in anchors.buildings:
		if not building is Dictionary or not building.get("id") is String or building.id.is_empty() or not valid_tile(building.get("tile")):
			return failure("each building anchor requires id and in-bounds tile")

	return {
		"valid": true,
		"fallback": false,
		"error": "",
		"directory": directory,
		"manifest": manifest,
		"art": art,
		"collision": collision,
		"anchors": anchors,
	}
