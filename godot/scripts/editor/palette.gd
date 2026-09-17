extends RefCounted
class_name EditorPalette

const WorldData = preload("res://scripts/world_data.gd")

var npcs: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var terrain_sets: Array[Dictionary] = []

func _init() -> void:
	_build_npc_palette()
	_build_building_palette()
	_build_terrain_palette()

func _build_npc_palette() -> void:
	npcs.clear()
	for npc in WorldData.NPCS:
		npcs.append({
			"id": npc.id,
			"display_name": npc.display_name,
			"sprite_path": npc.sprite_path,
			"dialogue": npc.get("dialogue", "")
		})

func _build_building_palette() -> void:
	buildings.clear()
	for b in WorldData.BUILDINGS:
		buildings.append({
			"id": b.id,
			"sprite": b.sprite,
			"label": b.label,
			"footprintW": b.footprintW,
			"footprintH": b.footprintH
		})

func _build_terrain_palette() -> void:
	terrain_sets = [
		{"id": "grass_dirt", "name": "Grass / Dirt", "texture": "res://assets/terrain/tileset-grass-dirt.png", "wang_ids": range(16)},
		{"id": "water_grass", "name": "Water / Grass", "texture": "res://assets/terrain/tileset-water-grass.png", "wang_ids": range(16)}
	]

func get_npc(index: int) -> Dictionary:
	if index >= 0 and index < npcs.size():
		return npcs[index]
	return {}

func get_building(index: int) -> Dictionary:
	if index >= 0 and index < buildings.size():
		return buildings[index]
	return {}

func get_terrain_set(index: int) -> Dictionary:
	if index >= 0 and index < terrain_sets.size():
		return terrain_sets[index]
	return {}

func get_npc_count() -> int:
	return npcs.size()

func get_building_count() -> int:
	return buildings.size()

func get_terrain_set_count() -> int:
	return terrain_sets.size()
