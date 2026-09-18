# Townville Godot POC — implementation notes

Development guide for the Godot 4.x prototype of Townville (World 1: Farm).

## Commands

- `./scripts/deploy-web.sh` — export to web, verify, serve locally, and probe
- `GODOT --headless --path godot --script godot/tests/test_runner.gd` — run headless tests

## Invariants

- **Dialogue:** only one panel visible at a time. `set_state()` hides all panels before showing the new one.
- **CanvasLayer separation:** HUD (layer 0), dialogue (layer 10+), building labels as children of Node2D (world-space, not screen-space).
- **Dialogue panel:** bottom-anchored, max-width 640px, fixed size.
- **NPC curriculum:** all 8 World 1 NPCs with addition exercises (2.OA.A.1).
- **Grid:** 30x20, TILE_SIZE=48. Walkable path network + building footprints.

## Key files

- `godot/scripts/game.gd` — game controller: build world, HUD, dialogue, quest UI, input
- `godot/scripts/world_data.gd` — NPCs, buildings, walkable matrix, props
- `godot/scripts/map_renderer.gd` — tilemap rendering, props, decals
- `godot/scripts/player.gd` — player controller + camera
- `godot/scripts/player_movement.gd` — movement + collision
- `godot/scripts/ui/interaction_flow.gd` — NPC interaction flow
- `godot/scenes/main.tscn` — main scene

## NPCs (World 1)

All in `godot/scripts/world_data.gd`, constant `NPCS`:

| id | display_name | tile | skill |
|---|---|---|---|
| mae | Mae | (4,4) | Addition |
| chester | Chester | (14,4) | Addition |
| farmer-joe | Farmer Joe | (24,4) | Addition |
| lily | Lily | (4,7) | Addition |
| vera | Dr. Vera | (24,7) | Addition |
| grandma-rose | Grandma Rose | (25,14) | Addition |
| billy | Billy | (15,10) | Addition |
| old-mac | Old Mac | (15,19) | Addition (gatekeeper) |

## Buildings (World 1)

In `godot/scripts/world_data.gd`, constant `BUILDINGS`:

| id | label | footprint | scale |
|---|---|---|---|
| henhouse | HENHOUSE | (3,2) 2x2 | 1.0 |
| stable | STABLE | (13,2) 2x2 | 1.5 |
| barn | BARN | (23,2) 2x2 | 2.0 |
| coop | COOP | (3,8) 2x2 | 1.0 |
| clinic | CLINIC | (23,8) 2x2 | 1.5 |
| garden | GARDEN | (26,14) 2x2 | 1.0 |

## Walkable path network

30x20 matrix in `world_data.gd:_build_walkable_matrix()`. Paths:
- Horizontal spine + branch clearings
- Central vertical trunk
- Garden connector
- South yards for Coop, Clinic, and Garden

## Follow-up priorities

1. Multiplication and division for all 8 NPCs (exercises 3 and 4)
2. Farm → Downtown transition after Old Mac
3. Exercise scripts for pillar verification
4. Godot web export verification (scripts/deploy-web.sh)

## Before committing script changes

- Verify GDScript syntax with the file open in Godot editor
- Test web export with `./scripts/deploy-web.sh --no-probe`
