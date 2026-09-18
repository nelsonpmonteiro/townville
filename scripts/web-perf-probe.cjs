// Real-browser acceptance probe for the Godot web export at localhost:8090.
// Verifies: FPS, movement, grid hidden, F1, and the full NPC loop with REAL
// mouse drag-and-drop (Mae phase 1 basket_in, phase 2 basket_out) plus the
// text-input phase 3 with hint tiers. Engine state comes from the JS bridge
// in game.gd (window.__townville_state / __townville_cmd / __townville_rects).
const { chromium } = require('playwright');

const sleep = ms => new Promise(r => setTimeout(r, ms));
async function rafFps(page, secs) {
  return page.evaluate(s => new Promise(res => {
    let n = 0; const t0 = performance.now();
    (function f(){ n++; if (performance.now() - t0 < s * 1000) requestAnimationFrame(f); else res(n / s); })();
  }), secs);
}
const state = page => page.evaluate(() => window.__townville_state || null);
const cmd = (page, c) => page.evaluate(c => { window.__townville_cmd = c; }, c);
async function rects(page) {
  await page.evaluate(() => { window.__townville_rects = null; });
  await cmd(page, 'rects');
  await sleep(250);
  return page.evaluate(() => window.__townville_rects);
}
async function waitState(page, pred, ms = 6000, label = '') {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) { const s = await state(page); if (s && pred(s)) return s; await sleep(120); }
  const s = await state(page);
  throw new Error(`waitState timeout ${label}: ${JSON.stringify(s && s.flow)}`);
}
// Canvas is CSS-scaled; map engine coords (960x640 viewport) to page pixels.
async function toPage(page, x, y) {
  const b = await page.$eval('canvas', c => { const r = c.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height }; });
  return { x: b.x + x * b.w / 960, y: b.y + y * b.h / 640 };
}
async function realDrag(page, from, to) {
  const a = await toPage(page, from[0] + from[2] / 2, from[1] + from[3] / 2);
  const b = await toPage(page, to[0] + to[2] / 2, to[1] + to[3] / 2);
  await page.mouse.move(a.x, a.y); await page.mouse.down();
  for (let i = 1; i <= 12; i++) { await page.mouse.move(a.x + (b.x - a.x) * i / 12, a.y + (b.y - a.y) * i / 12); await sleep(16); }
  await page.mouse.up(); await sleep(150);
}
async function clickRect(page, r) { const p = await toPage(page, r[0] + r[2] / 2, r[1] + r[3] / 2); await page.mouse.click(p.x, p.y); await sleep(150); }
async function hold(page, key, ms) { await page.keyboard.down(key); await sleep(ms); await page.keyboard.up(key); await sleep(120); }

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 960, height: 640 } });
  const logs = [];
  page.on('console', m => logs.push(`[${m.type()}] ${m.text()}`));
  page.on('pageerror', e => logs.push(`[pageerror] ${e.message}`));
  const R = {};
  const check = (name, ok, extra = '') => { R[name] = ok; console.log((ok ? 'PASS' : 'FAIL') + ': ' + name + (extra ? '  ' + extra : '')); };

  // ---------- Onboarding on a genuinely fresh state (?reset=1 deletes user://save_data.cfg) ----------
  await page.goto('http://localhost:8090/index.html?reset=1', { waitUntil: 'load' });
  await page.waitForTimeout(12000);
  let s = await state(page);
  check('fresh load → onboarding title screen', s.onboarding.active && s.onboarding.title_visible && !s.seen_onboarding);
  await page.screenshot({ path: '/tmp/tv-onboard-title.png' });
  const t0 = s.tile.slice();
  await hold(page, 'ArrowRight', 500); s = await state(page);
  check('movement blocked under onboarding (key consumed as "advance")', s.tile[0] === t0[0] && s.tile[1] === t0[1] && s.onboarding.step === 0);
  check('card 1 movement', /arrow keys/.test(s.onboarding.card_text));
  await page.mouse.click(480, 320); await sleep(250); s = await state(page);
  check('tap → card 2 interaction', /press E/.test(s.onboarding.card_text));
  await page.screenshot({ path: '/tmp/tv-onboard-card2.png' });
  await page.keyboard.press('Space'); await sleep(250); s = await state(page);
  check('any key → card 3 goal', /unlock the whole farm/.test(s.onboarding.card_text));
  await page.mouse.click(480, 320); await sleep(900); s = await state(page);
  check('card 3 tap → fade → map, flag saved', !s.onboarding.active && s.seen_onboarding && s.flow.state === 'map');
  await hold(page, 'ArrowRight', 400); s = await state(page);
  check('player at spawn moves after onboarding', s.tile[0] > t0[0], `${t0}→${s.tile}`);

  // ---------- Repeat visit: no ?reset → straight to map ----------
  await page.goto('http://localhost:8090/index.html', { waitUntil: 'load' });
  await page.waitForTimeout(12000);
  s = await state(page);
  check('repeat launch skips onboarding', !s.onboarding.active && s.seen_onboarding && s.flow.state === 'map');

  R.fps_idle = +(await rafFps(page, 3)).toFixed(1);
  s = await state(page);
  check('boot in MAP, grid hidden', s.flow.state === 'map' && !s.grid_visible, `tile=${s.tile}`);
  await page.$('canvas').then(c => c.click({ position: { x: 480, y: 320 } }));
  await hold(page, 'ArrowRight', 700);
  s = await state(page);
  check('ArrowRight moves player', s.tile[0] === 16 && s.tile[1] === 6, `tile=${s.tile}`);
  R.fps_moving = +(await rafFps(page, 2)).toFixed(1);

  // Walk to Mae (4,4): stand at (4,5) or (5,4). From (16,6): up to row 5, left to col 4.
  await hold(page, 'ArrowUp', 450);
  await hold(page, 'ArrowLeft', 3600);
  s = await state(page);
  check('walked next to Mae', Math.abs(s.tile[0] - 4) + Math.abs(s.tile[1] - 4) === 1, `tile=${s.tile}`);

  // ---------- Phase 1: basket_in, REAL mouse drags ----------
  await page.keyboard.press('KeyE'); await sleep(300);
  s = await waitState(page, s => s.flow.state === 'dialogue', 3000, 'dialogue');
  check('E → DIALOGUE (typewriter running)', s.flow.is_typing === true || s.flow.dialogue_text.length > 0);
  const tileBefore = s.tile.slice();
  await hold(page, 'ArrowRight', 500);
  s = await state(page);
  check('movement locked during dialogue', s.tile[0] === tileBefore[0] && s.tile[1] === tileBefore[1], `tile=${s.tile}`);
  let rr = await rects(page);
  await clickRect(page, rr.dialogue_box);            // click while typing → full text
  await sleep(200); s = await state(page);
  check('click while typing → full text', s.flow.is_typing === false);
  await clickRect(page, rr.dialogue_box);            // click again → exercise
  s = await waitState(page, s => s.flow.state === 'exercise', 3000, 'exercise');
  check('dialogue dismissed → EXERCISE basket_in', s.flow.mode === 'basket_in' && s.flow.basket_count === 4 && s.flow.source_left === 3);
  await page.screenshot({ path: '/tmp/tv-ex-basket-in.png' });
  for (let i = 0; i < 3; i++) {
    rr = await rects(page);
    if (!rr.item0) break;
    await realDrag(page, rr.item0, rr.basket);
  }
  s = await state(page);
  check('3 REAL mouse drags into basket → 7', s.flow.basket_count === 7 && s.flow.source_left === 0, `basket=${s.flow.basket_count} left=${s.flow.source_left}`);
  rr = await rects(page); await clickRect(page, rr.done);
  s = await waitState(page, s => s.flow.state === 'feedback', 3000, 'feedback');
  check('Done → FEEDBACK correct', s.flow.last_correct === true && /Seven eggs/.test(s.flow.result_text), s.flow.result_text);
  await page.screenshot({ path: '/tmp/tv-feedback.png' });
  s = await waitState(page, s => s.flow.state === 'map', 4000, 'back to map');
  check('feedback auto-dismiss → MAP, phase 2 unlocked', s.phases.mae === 1, `phases=${JSON.stringify(s.phases)}`);

  // ---------- Phase 2: basket_out, wrong first (hint tier 1), then right ----------
  await page.keyboard.press('KeyE'); await sleep(300);
  await waitState(page, s => s.flow.state === 'dialogue', 3000);
  await page.keyboard.press('KeyE'); await sleep(150); await page.keyboard.press('KeyE');
  s = await waitState(page, s => s.flow.state === 'exercise', 3000, 'phase2');
  check('phase 2 basket_out: 9 in basket', s.flow.mode === 'basket_out' && s.flow.basket_count === 9);
  rr = await rects(page); await realDrag(page, rr.item0, rr.tray);          // 1 out (wrong)
  rr = await rects(page); await clickRect(page, rr.done);
  s = await waitState(page, s => s.flow.state === 'feedback', 3000);
  check('1 out → wrong feedback', s.flow.last_correct === false);
  s = await waitState(page, s => s.flow.state === 'exercise', 4000, 'retry');
  check('wrong → SAME exercise + tier-1 hint', s.flow.mode === 'basket_out' && s.flow.hint_visible && /one egg out/.test(s.flow.hint_text), s.flow.hint_text);
  await page.screenshot({ path: '/tmp/tv-ex-basket-out-hint.png' });
  rr = await rects(page); await realDrag(page, rr.item0, rr.tray);
  rr = await rects(page); await realDrag(page, rr.item0, rr.tray);
  s = await state(page);
  check('2 REAL drags out → 7', s.flow.basket_count === 7 && s.flow.tray_count === 2);
  rr = await rects(page); await clickRect(page, rr.done);
  s = await waitState(page, s => s.flow.state === 'feedback', 3000);
  check('Done → correct', s.flow.last_correct === true);
  s = await waitState(page, s => s.flow.state === 'map', 4000);
  check('phase 3 unlocked', s.phases.mae === 2);

  // ---------- Phase 3: text, typed via real keyboard, 2 wrong → grid hint ----------
  await page.keyboard.press('KeyE'); await sleep(300);
  await waitState(page, s => s.flow.state === 'dialogue', 3000);
  await page.keyboard.press('KeyE'); await sleep(150); await page.keyboard.press('KeyE');
  s = await waitState(page, s => s.flow.state === 'exercise', 3000, 'phase3');
  check('phase 3 → text mode', s.flow.mode === 'text');
  rr = await rects(page); await clickRect(page, rr.input);
  await page.keyboard.type('1a1'); await page.keyboard.press('Enter');
  s = await waitState(page, s => s.flow.state === 'feedback', 3000);
  check('typed "1a1" → filtered to 11 → wrong', s.flow.last_correct === false);
  s = await waitState(page, s => s.flow.state === 'exercise', 4000);
  check('tier-1 hint "4 + 4 + 4"', /4 \+ 4 \+ 4/.test(s.flow.hint_text), s.flow.hint_text);
  rr = await rects(page); await clickRect(page, rr.input);
  await page.keyboard.type('10'); await page.keyboard.press('Enter');
  await waitState(page, s => s.flow.state === 'feedback', 3000);
  s = await waitState(page, s => s.flow.state === 'exercise', 4000);
  check('tier-2 icon grid 3×4', s.flow.icon_grid_visible && s.flow.icon_grid_count === 12);
  await page.screenshot({ path: '/tmp/tv-ex-text-grid.png' });
  rr = await rects(page); await clickRect(page, rr.input);
  await page.keyboard.type('12'); rr = await rects(page); await clickRect(page, rr.submit);
  s = await waitState(page, s => s.flow.state === 'feedback', 3000);
  check('12 → correct', s.flow.last_correct === true && /Twelve eggs/.test(s.flow.result_text));
  s = await waitState(page, s => s.flow.state === 'map', 4000);
  check('phase 4 unlocked, back on map, movement free', s.phases.mae === 3 && s.flow.state === 'map');
  await hold(page, 'ArrowDown', 300);
  const s2 = await state(page);
  check('player moves again after loop', s2.tile[1] !== s.tile[1] || s2.tile[0] !== s.tile[0], `${s.tile}→${s2.tile}`);
  await page.screenshot({ path: '/tmp/tv-after-loop.png' });

  // ---------- F1 editor still works ----------
  await page.keyboard.press('F1'); await sleep(400); s = await state(page);
  check('F1 → editor + grid', s.edit_mode && s.grid_visible);
  await page.keyboard.press('F1'); await sleep(300); s = await state(page);
  check('F1 again → grid hidden', !s.edit_mode && !s.grid_visible);

  const errs = logs.filter(l => /error|pageerror/i.test(l) && !/GL Driver/.test(l));
  console.log(`FPS idle=${R.fps_idle} moving=${R.fps_moving}  console_errors=${errs.length}`);
  errs.slice(0, 10).forEach(l => console.log('  ', l));
  const fails = Object.entries(R).filter(([k, v]) => v === false).map(([k]) => k);
  console.log(fails.length ? `RESULT: ${fails.length} FAIL → ${fails.join(' | ')}` : 'RESULT: ALL PASS');
  await browser.close();
  process.exit(fails.length ? 1 : 0);
})().catch(e => { console.error('PROBE_ERROR', e.message); process.exit(1); });
