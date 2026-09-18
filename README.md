# Townville — Farm (World 1)

An educational 2D game prototype for children (ages ~5–10) that teaches
addition, subtraction, multiplication and division through drag-and-drop
rather than typed answers. Built in **Godot 4** and exported to the web.

**Play it:** https://townville.vercel.app
(mirror: https://nelsonpmonteiro.github.io/townville/)

## The teaching idea

Every exercise is manipulated, never typed. The child moves real objects and
the quantity is something they build, not a number they read:

| Phase | Operation | Mechanic |
| --- | --- | --- |
| 1 | Addition | Drag items **into** the basket until it holds the target |
| 2 | Subtraction | Drag items **out** of the basket to a tray |
| 3 | Multiplication | Fill a rows × columns grid — 4 rows of 5 *is* 20 |
| 4 | Division | Deal every item into equal groups (fair sharing) |

Design rules that the tests enforce:

- **No numbers handed over.** Counts that would reveal the answer are hidden
  behind an opt-in Hint button, never printed on screen by default.
- **No punitive failure.** An unequal division stays editable with a nudge
  instead of a game over; wrong answers return to the same exercise with a hint.
- **One celebration per success.** A correct answer shows a single screen with
  the congratulation, the character's line and the equation together.
- **Real-time feedback.** Every item moved plays a "pop" and updates the scene.

## World 1 — the farm

Eight characters, each with the four phases above:

| Character | Building | Item |
| --- | --- | --- |
| Mae | Henhouse | eggs |
| Chester | Stable | carrots |
| Farmer Joe | Barn | hay bales |
| Lily | Chicken coop | chicks |
| Dr. Vera | Clinic | bandages |
| Grandma Rose | Garden | tomatoes |
| Billy | Fence | nails |
| Old Mac | Farm gate | keys — finishing him ends the demo |

## Running it

Requires Godot 4.x. Set `GODOT` if it is not on your `PATH`:

```sh
export GODOT=/Applications/Godot.app/Contents/MacOS/Godot   # adjust as needed

# Play / edit: open the godot/ folder as a project in the Godot editor.

# Full verification: headless suites → web export → static server → real browser
./scripts/deploy-web.sh

# Build only, no browser probe
./scripts/deploy-web.sh --no-probe
```

`scripts/deploy-web.sh` is the single entry point: it runs the nine headless
suites, exports to `dist/`, checks the MIME types a Godot web build needs, and
drives a real Chromium through the whole game loop (onboarding → walking →
dialogue → all four exercise types → volume → restart).

## Tests

```sh
"$GODOT" --headless --path godot --script tests/test_runner.gd
```

| Suite | Covers |
| --- | --- |
| `test_runner.gd` | Exercise flow, dialogue, map data, hints, scripted content |
| `test_success_screen.gd` | A correct answer is one screen, not two |
| `test_array_hint.gd` | The multiplication pool never gives away the answer |
| `test_ending.gd` | End-of-demo message reuses the dialogue box; world stays live |
| `test_audio.gd` | Music and SFX on independent buses and sliders |
| `test_restart.gd` | Restart asks first; Cancel changes nothing |
| `test_depth_order.gd` | Player draws in front of NPCs and buildings |
| `test_editor_move.gd` / `test_editor_delete.gd` | Map edits survive save/reload |

The browser probe lives in `scripts/web-perf-probe.cjs` and needs
`npm install` (Playwright) before `deploy-web.sh` can run its last step.

## Layout

```
godot/
├── scripts/
│   ├── game.gd              world build, HUD, input, JS bridge
│   ├── world_data.gd        NPCs, buildings, exercises, walkable grid
│   ├── map_renderer.gd      tilemap, props, decals
│   ├── player.gd            player controller and camera
│   ├── editor/              in-game map editor (F1)
│   └── ui/                  dialogue, exercises, onboarding, volume, restart
├── scenes/main.tscn         entry scene
├── tests/                   headless suites
├── assets/                  art, audio, item icons
└── artifacts/               authoritative map export (see below)
scripts/                     build, deploy and verification scripts
public/                      published web build (Vercel serves this)
```

### The map is data, not code

`godot/artifacts/townville_map_export.json` is the authoritative map: ground
painting, collision, and entity positions as exported from the in-game editor
(**F1** in play mode). `test_runner.gd` compares all 600 painted cells and all
600 collision cells against that file, so the map can be edited visually
without anyone hand-editing the grid in source.

## Debug shortcuts

| Key / URL | Effect |
| --- | --- |
| `F1` | Toggle the map editor and grid |
| `Home` | Toggle the FPS counter |
| `?reset=1` | Clear saved progress and replay the onboarding |
| `?ending=1` | Jump straight to the end-of-demo screen |

## Status

Implemented: all four operations for all eight characters, onboarding,
background music with separate music/SFX volume, restart confirmation, the
in-game map editor, and the end-of-demo message.

Not built: Downtown (World 2). Finishing Old Mac ends the demo and leaves the
player free to roam and replay any character.
