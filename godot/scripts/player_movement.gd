class_name PlayerMovement
extends RefCounted

const SPEED := 180.0

func next_position(current: Vector2, direction: Vector2, delta: float, world) -> Vector2:
	if direction == Vector2.ZERO:
		return current
	var candidate := current + direction.normalized() * SPEED * delta
	var tile := Vector2i(floori(candidate.x / world.TILE_SIZE), floori(candidate.y / world.TILE_SIZE))
	return candidate if world.is_walkable(tile) else current
