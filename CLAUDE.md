# Townville implementation handoff

This is the actual implemented local prototype, not the unavailable historical CLAUDE.md.

## Commands
- `npm run web`: Expo web at port **8082**. Never confuse with the unrelated project serving 8081.
- `npm test`; `npm run typecheck`; `npm run test:e2e`.
- `npm run build`: static web `dist/`; `npx expo export --platform all`: also iOS/Android bundles.
- `TOWNVILLE_URL=http://127.0.0.1:8083 npm run test:e2e`: verify a separately served production export.

## Invariants
- React Native/Expo architecture. Keep platform pointer/gesture adapters separate, domain rules pure.
- 20×15 map, 48px cells. Movement blocks world bounds, buildings and NPC tiles. Camera follows the player, including after asynchronous save hydration.
- Quest IDs are an ordered prefix of q1…q5; a correct next quest awards exactly 100 once. Errors and hints never deduct progress or streak. All reward values derive from completion IDs on restore.
- Save key `townville.save.v1`, schema `version:1`. Do not silently change the schema. Unknown/malformed saves recover safely.
- Audio must remain gesture-gated, mute-persistent and background-paused. No microphone permission is requested.
- Do not add timers, pressure mechanics, monetization, child identity collection or invented integration claims.
- Existing WAVs and IDEA.md must remain intact. See `assets/manifest.json` for asset replacement points.
- Only Mae, Chester and Lily have activities. Five other NPC names and roadmap world names are provisional. README contains the exact temporary counting sequence. This is one persisted session, not an endless curriculum.

## Files
`src/core.ts` domain + save codec; `src/Art.tsx` vector placeholders; `src/Collection{,.web}.tsx` gestures; `src/drop.ts` geometry; `src/sound.ts` policy; `src/useFarmAudio.ts` Expo integration; `App.tsx` shell/game orchestration; `tests/` pure tests; `e2e/` complete journeys.

## Follow-up priorities
1. Replace placeholder art without changing collision anchors. Obtain final NPC/curriculum specification before broadening content.
2. Native device QA for PanResponder, audio and screen reader interaction. Native exports alone are not device validation.
3. Modal focus trapping and full accessibility audit.
4. Plan a compatible Expo dependency/security upgrade: npm audit reports 16 remaining advisory entries. Do not force-upgrade without rerunning all builds/tests.
5. Design repeat sessions independently from permanent city progress, with explicit save migration.

Use real RED→GREEN vertical slices. Read README's testing-provenance caveat: the first broad UI red used an occupied port and cannot be counted as target-app TDD evidence.
