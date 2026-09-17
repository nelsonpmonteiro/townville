# Legacy e2e specs (pre-rework prototype)

These specs tested the ORIGINAL 20×15 prototype UI: star counter,
"Talk to Mae" buttons, egg drag-and-drop collection. That UI was
replaced by the 40×30 chunk-rendered world with WASD movement,
DialogueBox and QuestUI (see git history from commit 8ac1600 onward).

They are kept (renamed `*.spec.legacy` so Playwright ignores them) as
reference for the interaction patterns they exercised — full session
journeys, audio gating, malformed-save recovery. Port those scenarios
to the current UI as it stabilizes, then delete this folder.

Current suite: `e2e/smoke.spec.ts` (boot without console errors +
keyboard movement).
