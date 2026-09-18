# Townville — Godot Web Prototype

A 2D side-scrolling educational game prototype built in **Godot 4.x** with web export. This project focuses on World 1 (Farm) with 8 NPCs, each presenting math exercises (addition, subtraction, multiplication, division).

## Run

```sh
cd /Users/nelsonmonteiro/Documents/Townville-Godot-POC
# Open in Godot Editor:
#   Godot.app → open project → godot/
# Or export to web via CLI:
GODOT=${GODOT:-/Users/nelsonmonteiro/Applications/Godot.app/Contents/MacOS/Godot}
"$GODOT" --headless --path godot --export-release "Web" dist/index.html
```

## Web Export

```sh
./scripts/deploy-web.sh          # build → dist/ → serve :8090 → probe
./scripts/deploy-web.sh --no-probe  # build only
```

Production web files in `dist/`:
- `index.html`, `index.js`, `index.wasm`, `index.pck`, `index.audio.worklet.js`

## Play

- Movement: WASD or arrows. Interact with NPCs: E or Space.
- Each NPC has 4 math exercises (addition, subtraction, multiplication, division).
- Response feedback: success (green) or error (red) with tier 1 and tier 2 hints.
- NPC dialogue appears in a bottom-center panel (640px max-width), only one state visible at a time.

## NPCs — World 1

| NPC | Location | Skill |
| --- | --- | --- |
| Mae | Henhouse (4,4) | Addition 2.OA.A.1 |
| Chester | Stable (14,4) | Addition 2.OA.A.1 |
| Farmer Joe | Barn (24,4) | Addition 2.OA.A.1 |
| Lily | Chicken Coop (4,7) | Addition 2.OA.A.1 |
| Dr. Vera | Clinic (24,7) | Addition 2.OA.A.1 |
| Grandma Rose | Garden (25,14) | Addition 2.OA.A.1 |
| Billy | Fence (15,10) | Addition 2.OA.A.1 |
| Old Mac | Farm Gate (15,19) | Addition 2.OA.A.1 — unlocks transition to Downtown |

## Architecture

- `godot/scripts/game.gd` — main controller: world build, HUD, dialogue, quest UI, input handling
- `godot/scripts/world_data.gd` — world data: NPCs (8), buildings (6), walkable matrix, props, clutter
- `godot/scripts/map_renderer.gd` — tilemap Wang autotiling, props, decals, clutter rendering
- `godot/scripts/player.gd` — player controller with animated sprite and follow camera
- `godot/scripts/player_movement.gd` — collision and movement logic
- `godot/scripts/ui/interaction_flow.gd` — NPC interaction flow
- `godot/scenes/main.tscn` — main scene (Node2D + game.gd script)
- `godot/tests/` — headless tests (test_runner.gd, etc.)

## Directory structure

```
godot/
├── scripts/          # gdscripts (game, world_data, map_renderer, player, etc.)
├── scenes/           # Godot scenes (.tscn)
├── tests/            # headless tests
├── assets/           # imported assets (buildings, characters, scenery, terrain)
├── artifacts/        # screenshots and debug artifacts
└── .gitignore        # ignores temp exports and editor artifacts
```

## Verify

```sh
# Headless tests (Godot CLI)
GODOT=/Users/nelsonmonteiro/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path godot --script godot/tests/test_runner.gd
```

## Current status

- [x] 8 NPCs with addition exercises (2.OA.A.1)
- [x] Dialogue without overlap (state machine: hide all panels before show)
- [x] Dialogue panel: bottom-center, 640px max-width
- [x] HUD instructions fixed at top (CanvasLayer layer 0)
- [x] 30x20 map with path network and building footprints
- [ ] Multiplication and division (exercises 3 and 4 for each NPC)
- [ ] Farm → Downtown transition after Old Mac
