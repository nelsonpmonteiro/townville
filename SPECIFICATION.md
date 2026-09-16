# Townville - Game Specification

**Educational math game for K-4 students with exploration, hands-on problem solving, and persistent progress**

## Core Concept
Students control a protagonist exploring a top-down farm world, interacting with teaching NPCs who assign hands-on math activities. Correct answers physically change the farm (unlock buildings, grow crops). The game emphasizes:
- **Narrative fidelity**: drag eggs into baskets, not abstract number inputs
- **Persistent world**: completed quests visibly transform the environment  
- **Structured sessions**: 5 quests per session with celebration
- **Polished feedback**: sound, animation, character reactions
- **Curriculum alignment**: CCSS-M standards per NPC

## Current State (What Exists)
✅ React Native/Expo architecture  
✅ 20×15 tile map with collision detection  
✅ Arrow key/gesture movement with camera follow  
✅ Save/restore system (`townville.save.v1`)  
✅ 3 teaching NPCs (Mae, Chester, Lily) with 5 quests  
✅ Drag-and-drop collection mechanic (eggs→basket, chicks→pen, hay→stable)  
✅ Audio files ready (13 WAVs: music, SFX, farm ambience)  
✅ Basic UI shell with score/streak display

## What's Missing (Priority Order)

### P0 - Core Experience
1. **GameHeader component** - persistent header showing lives ❤️❤️❤️, score ⭐, streak 🔥, session progress bar
2. **Lives system** - 3 hearts per session, lose 1 on 3rd error in same quest, game over screen with retry
3. **Celebration screen** - between quest completion and farm return (1.8s): character animation, building preview, particles, sound
4. **Error feedback** - shake animation + red flash + heart break animation + buzzer sound  
5. **Session end screen** - after 5 quests: stats summary, total score, achievements, "Play Again" button
6. **Audio integration** - hook up the 13 WAV files to game events (correct, wrong, unlock, drag, drop, etc.)
7. **Farm background** - replace solid color with parallax sky, grass floor, decorative elements (generated via code or simple sprites)

### P1 - Polish & Depth  
8. **4 additional input types**:
   - `TapToCount`: tap objects to count them (for K students)
   - `TapScene`: tap the correct object in an illustrated scene
   - `DragArray`: arrange objects into rows/columns for multiplication concepts  
   - `ShadeFraction`: shade portions of shapes for fraction visualization
9. **Character expressions** - NPCs show idle/happy/surprised sprites based on interaction state
10. **Scaffold system** - 3 hint levels when student struggles:
    - Level 1: visual anchor (dots, number line)  
    - Level 2: strategy hint ("Try counting by 2s")  
    - Level 3: worked example with explanation
11. **Building unlock animations** - zoom, particle burst, NPC dialogue on first unlock
12. **Mobile D-pad** - virtual arrow buttons for touch devices

### P2 - Expansion (After Core is Solid)
13. **37 additional NPCs** with teaching arcs (Joe, Billy, Vera, Old Mac, + 4 more worlds)
14. **Worlds 2-5** (Downtown, Harbor, Factory, Heights) with distinct themes and curricula
15. **150 exercise templates** organized by CCSS standards across all 5 worlds  
16. **Adaptive difficulty** - adjust number ranges based on performance
17. **Parent dashboard** - progress tracking, time spent, mastery heatmap by skill
18. **Tutor integration** - session assignment, prescribed practice, completion reporting

## Technical Constraints
- **React Native + Expo** (cross-platform: web, iOS, Android)
- **TypeScript strict mode**
- **Pure domain logic** in `src/core.ts` (testable without React)
- **Save schema migration** required if changing `Save` type (never silent breakage)
- **Audio gesture-gated** (mobile requirements), mute-persistent, background-paused
- **No timers/pressure mechanics** for K-2 students (anxiety-free learning)
- **No child identity collection** (COPPA compliance)
- **Accessibility**: screen reader support, keyboard navigation, high contrast mode

## File Structure
```
src/
  core.ts          # Domain logic (quests, save, movement, collision)
  Art.tsx          # Vector placeholders (replace with sprites when ready)
  Collection.tsx   # Drag-and-drop gesture handler (React Native)
  Collection.web.tsx # Web-specific gesture override
  drop.ts          # Geometry helpers for drop zones
  sound.ts         # Audio policy (gesture-gate, mute, background)
  useFarmAudio.ts  # Expo Audio integration hook
  
App.tsx            # Main shell (farm view, quest dialogs, routing)

assets/
  audio/           # 13 WAV files (music, SFX)
  manifest.json    # Asset replacement registry
  
tests/             # Pure domain tests
e2e/               # Playwright browser journeys
```

## Design Tokens (from conversation)
```
Colors:
  Sky: #87CEEB (light blue)
  Grass: #7EC850 (spring green)  
  UI Primary: #7C3AED (purple, matches Varsity Tutors)
  UI Secondary: #2563EB (blue, VT CTA buttons)
  Success: #10B981 (green)
  Error: #EF4444 (red)
  Warning: #F59E0B (amber)
  
Typography:
  Headers: Inter 700-800
  Body: Inter 400-600
  NPC names: Cinzel (medieval fantasy flavor)
  
Spacing: 4px grid (8, 12, 16, 24, 32, 48)
Border radius: sm=4px, md=8px, lg=12px, xl=16px
```

## NPCs & Teaching Plan (World 1 - Farm)

| NPC | Standards | Concept | Quest Sequence |
|-----|-----------|---------|----------------|
| **Mae** | K.CC.B.5 | Count to answer "how many?" | Phase 1: Count 3 eggs → Phase 4: Count 5 eggs |
| **Chester** | K.CC.A.3 | Count objects in sequence | Phase 2: 4 chicks → Phase 5: 6 chicks |  
| **Lily** | K.OA.A.1 | Represent addition | Phase 3: 2 hay bales (combines two groups) |
| *Joe* | K.CC.C.6 | Compare numbers | "Which has more?" (visual comparison) |
| *Billy* | K.NBT.A.1 | Compose/decompose | "10 eggs = 1 basket + how many loose?" |
| *Vera* | K.G.A.2 | Identify shapes | Recognize triangles, circles, squares in scene |
| *Old Mac* | K.MD.B.3 | Classify objects | Sort animals by type (review gate for World 2) |

*(5 more NPCs TBD for complete 8-NPC structure)*

## Session Flow
1. **Farm exploration** - walk with arrows, approach NPC (within 1 tile)
2. **Quest dialog** - NPC explains task in narrative context
3. **Hands-on activity** - drag/tap/arrange objects (input type per quest)
4. **Immediate feedback** - correct: celebration + sound | wrong: shake + hint offer
5. **Building unlock** - 1.8s animation showing construction/growth
6. **Return to farm** - quest marker cleared, progress bar +1/5
7. **Repeat** until 5 quests done
8. **Session summary** - stats, achievements, "Play Again" to reset session

## Audio Manifest (13 files ready in `assets/audio/`)
- `music-farm-ambient.wav` (50s loop, flute + pad)
- `music-event.wav` (20s loop, slightly faster)  
- `sfx-correct.wav` (0.55s arpeggio)
- `sfx-wrong.wav` (0.35s buzzer)  
- `sfx-unlock.wav` (1.15s fanfare)
- `sfx-session-end.wav` (1.7s victory jingle)
- `sfx-drag.wav`, `sfx-drop.wav`, `sfx-tap.wav`, `sfx-hint.wav`
- `sfx-chicken.wav`, `sfx-horse.wav`, `sfx-birds.wav` (farm ambience)

## Next Steps (Implementation Order)
1. Create `src/GameHeader.tsx` - lives, score, streak, session bar (reusable component)
2. Add lives state to `Save` type + logic in `core.ts` (3 hearts, deduct on 3rd error)
3. Build `src/CelebrationScreen.tsx` - character animation + particles + unlock preview  
4. Integrate audio - create `src/AudioEngine.ts` using `useFarmAudio` pattern
5. Add error shake animation + heart break visual to quest dialog
6. Create `src/SessionSummary.tsx` - final stats + replay button
7. Replace `FarmArt` placeholders with parallax background layers
8. Test full session flow end-to-end

---

**Key principle from conversation**: "The input mechanic must be indistinguishable from the action the story describes." If Mae says "put eggs in the basket," the student drags eggs into a basket—not typing "3" into a number pad.
