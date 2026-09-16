# Townville — playable Farm core

A local-only educational game prototype built with **Expo SDK 54, React Native, React Native Web and TypeScript**. No authentication, analytics, backend, child profiles, deployment or Varsity Tutors integration. Existing `IDEA.md` and supplied WAV files are preserved.

## Run

```sh
cd /Users/nelsonmonteiro/Documents/Townville
export PATH="$HOME/.hermes/node/bin:$PATH" # only needed on this machine
npm ci
npm run web
```

Open **http://localhost:8082**. Port 8081 belongs to a different, pre-existing project at `/Users/nelsonmonteiro/townville`; it is not this application. The first Metro startup can take a while. `npm start` also opens Expo's native development workflow.

Production web files are in `dist/`:

```sh
npm run build
python3 -m http.server 8083 --bind 127.0.0.1 --directory dist
# http://127.0.0.1:8083
```

## Play

- Move with arrows/WASD or the on-screen D-pad. Buildings, NPC tiles and map boundaries block movement. Decorative vegetation does not.
- Stand one tile from a neighbour and press Enter/Space, tap the neighbour, or use the contextual Help button. You begin beside Mae.
- Move illustrated eggs to a basket, chicks to a pen and hay bales to a stable. **Real mouse/touch pointer dragging** is implemented on web. Native uses PanResponder. Select-then-target is the keyboard/tap/accessibility fallback.
- Check the exact collection. Extra objects are deliberate distractors; use **Return all** to start the collection over. Mistakes never deduct stars or permanent progress. Hints are optional and there are no timers.
- Each of five successful quests awards exactly 100 stars once. The first three visibly improve the hen house, stable and pen. A calm celebration leads back to the map; the fifth leads to a session summary.
- Mute is persistent. Ambient music starts only after a gesture; all audio pauses when hidden/backgrounded. Correct and session-complete sounds are wired in. Other supplied WAVs are retained but not yet used.

## Provisional content, not the missing final curriculum

The final curriculum/NPC specification was not available. These are explicit implementation choices, **not a reconstruction or claimed approved pedagogy**:

| Order | Neighbour | Activity | Target count | Prerequisite |
| --- | --- | --- | --- | --- |
| q1 | Mae | Eggs → basket | 3 | none |
| q2 | Chester | Chicks → pen | 4 | q1 |
| q3 | Lily | Hay → stable | 2 | q2 |
| q4 | Mae | Eggs → basket | 5 | q3 |
| q5 | Chester | Chicks → pen | 6 | q4 |

The eight map slots are Mae, Chester, Lily, **Oliver, June, Finn, Rosie and Theo**. The latter five names are provisional; they have honest coming-later dialogue, not invented complete curricula. Worlds 2–5 are disabled roadmap labels. Their Market/Harbour/Workshop/Observatory names are provisional too.

This release has **one persistent five-quest session**, not an infinite curriculum or a new daily session generator. Once finished, the farm remains explorable and progress remains intact. Clearing the local `townville.save.v1` storage key starts a fresh test game; there is intentionally no child-facing destructive reset.

## Architecture

- `src/core.ts`: pure grid collisions, quest prerequisites, exact scoring, idempotent completion and version-1 persistence codec.
- `App.tsx`: React Native shell, follow-camera, keyboard/D-pad movement, proximity interactions, quest UI, celebration and summary.
- `src/Collection.web.tsx`: browser pointer capture and visible dragged piece; semantic buttons for tap/keyboard fallback.
- `src/Collection.tsx`: native PanResponder/tap equivalent. `src/drop.ts` holds shared release hit testing.
- `src/Art.tsx`: original code-generated vector placeholder illustrations. All are replaceable; see `assets/manifest.json`.
- `src/sound.ts` and `src/useFarmAudio.ts`: tested gesture/mute/visibility policy and Expo Audio integration.
- AsyncStorage stores only version, ordered quest IDs, derived stars/help streak/upgrades and mute. No personal data. Wrong schema versions, malformed JSON, duplicate IDs and non-prefix quest histories recover to fresh state. Derived values are recomputed, not trusted. Storage rejection shows a notice. Position and unfinished collections are intentionally transient.

## Verify

```sh
npm test                         # 5 domain/lifecycle/geometry tests
npm run typecheck                # tsc --noEmit
npx playwright install chromium # first-time browser download
npm run test:e2e                 # 5 browser journeys; starts/reuses port 8082
npm run build                    # web export
npx expo export --platform all   # web + iOS + Android bundles
# Exercise the built export while the static server above is running:
TOWNVILLE_URL=http://127.0.0.1:8083 npm run test:e2e
```

Verified during implementation: **5 unit tests passed, 5 browser tests passed on both dev and production export, typecheck passed, and web/iOS/Android export passed**. The full browser journey walks between NPCs and completes all five quests, verifies score/summary/persistence, and observes no page errors. Mobile Chromium tests exercise an actual touch drag plus tap fallback and the initial following-camera position. Audio tests verify actual browser play/pause calls around gesture, mute and simulated visibility changes. Screenshots: `artifacts/farm.png`, `counting.png`, `mobile.png`, `summary.png`.

### Testing discipline and limitations

Observed RED→GREEN cycles cover collision, quest progression/scoring, persistence, audio gating, drop geometry and the mobile initial-camera bug. The initial broad UI RED accidentally hit the unrelated app on port 8081 before the conflict was identified; it is **not valid target-app TDD evidence**. The port was corrected to 8082 and the real journeys were exercised, but strict test-first provenance for that initial UI slice cannot be claimed. Later browser tests also add regression coverage to existing functionality.

Native JavaScript/Hermes bundles compile, but **no iOS simulator, Android emulator or physical-device interaction test was run**. Native drag, audio lifecycle and accessibility need device QA. Browser accessibility has labelled controls and live feedback, but is not a completed accessibility audit; modal focus trapping remains a follow-up. The map uses placeholder vector art, not final generated production illustrations.

`npm audit fix` was attempted without breaking upgrades. **16 advisories remain (7 moderate, 9 high)** in Expo's dependency tree, notably Metro/image-size, PostCSS and xcode/uuid; `artifacts/audit.json` has the exact report. npm proposes a breaking Expo SDK upgrade. This is a local prototype, not security-cleared for deployment. Do not use `npm audit fix --force` blindly.
