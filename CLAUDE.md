# Townville implementation handoff

This is the actual implemented local prototype, not the unavailable historical CLAUDE.md.

## Commands
- `npm run web`: Expo web at port **8082**. Never confuse with the unrelated project serving 8081.
- `npm test`; `npm run typecheck`; `npm run test:e2e`.
- `npm run build`: static web `dist/`; `npx expo export --platform all`: also iOS/Android bundles.
- `TOWNVILLE_URL=http://127.0.0.1:8083 npm run test:e2e`: verify a separately served production export.

## Invariants
- React Native/Expo architecture. Keep platform pointer/gesture adapters separate, domain rules pure.
- **Layered architecture (enforced by tests — see `tests/`):**
  - `src/config.ts` — ALL game constants (TILE_SIZE, grid, lives, scoring). Never redefine locally.
  - `src/core.ts` — pure save/scoring/collision rules. No React, no I/O.
  - `src/engine/gameFlow.ts` — pure interaction state machine (idle→dialogue→quest→result). No React, no I/O. ALL interaction transitions go through `reduce()`.
  - `src/content/registry.ts` — the ONLY wiring point for NPC dialogues/quests. Adding content = 1 import + 1 CONTENT entry; App.tsx never imports dialogue/quest files directly.
  - `App.tsx` — thin shell: rendering, keyboard, animation, persistence. Dispatches FlowEvents; never implements game rules inline.
- 40×30 grid, 48px tiles (`src/config.ts`). Movement blocks via `walkableMap` (includes building footprints). Camera follows player with clamped interpolation.
- Scoring: exactly 100 once per `npcId:phase`; errors NEVER deduct score/streak; 3rd error on a point costs 1 life; session = 5 events; maxAttempts=3 then failure dialogue → retry with fresh attempts.
- Save key `townville.save.v1`, schema `version:1`. Do not silently change the schema. Unknown/malformed saves recover safely.
- Audio must remain gesture-gated, mute-persistent and background-paused. No microphone permission is requested.
- Do not add timers, pressure mechanics, monetization, child identity collection or invented integration claims.
- Existing WAVs and IDEA.md must remain intact. See `assets/manifest.json` for asset replacement points.
- React Native Web: use `crossShadow()` from `src/utils/shadow.ts` (never raw `shadow*` props), `Animated` for animations (never CSS `animation`), and never `Image.resolveAssetSource` (web-safe fallback in `useAspectScaledSize`).
- **Before committing mechanics changes: `npm test` must stay green (25 tests lock core rules, flow transitions, and content integrity).**

## Files
`src/core.ts` domain + save codec; `src/Art.tsx` vector placeholders; `src/Collection{,.web}.tsx` gestures; `src/drop.ts` geometry; `src/sound.ts` policy; `src/useFarmAudio.ts` Expo integration; `App.tsx` shell/game orchestration; `tests/` pure tests; `e2e/` complete journeys.

## Follow-up priorities
1. Replace placeholder art without changing collision anchors. Obtain final NPC/curriculum specification before broadening content.
2. Native device QA for PanResponder, audio and screen reader interaction. Native exports alone are not device validation.
3. Modal focus trapping and full accessibility audit.
4. Plan a compatible Expo dependency/security upgrade: npm audit reports 16 remaining advisory entries. Do not force-upgrade without rerunning all builds/tests.
5. Design repeat sessions independently from permanent city progress, with explicit save migration.

Use real RED→GREEN vertical slices. Read README's testing-provenance caveat: the first broad UI red used an occupied port and cannot be counted as target-app TDD evidence.
