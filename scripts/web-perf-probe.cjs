// Real-browser acceptance probe for the Godot web export at localhost:8090.
// Verifies: FPS, movement, grid hidden, F1, and the full NPC loop with REAL
// mouse drag-and-drop across all four Mae phases: basket add/remove,
// multiplication arrays, and fair-sharing division. Engine state comes from the JS bridge
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
// BFS on the live walkable grid, then walk tile by tile with arrow keys.
function bfs(rows, from, to) {
  const H = rows.length, W = rows[0].length, key = t => t[0] + ',' + t[1];
  const prev = new Map([[key(from), null]]); const q = [from];
  while (q.length) {
    const c = q.shift(); if (c[0] === to[0] && c[1] === to[1]) break;
    for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
      const n = [c[0]+dx, c[1]+dy];
      if (n[0]<0||n[1]<0||n[0]>=W||n[1]>=H||rows[n[1]][n[0]]!=='.'||prev.has(key(n))) continue;
      prev.set(key(n), c); q.push(n);
    }
  }
  if (!prev.has(key(to))) return null;
  const path = []; for (let c = to; c; c = prev.get(key(c))) path.unshift(c); return path;
}
async function walkTo(page, target) {
  const st = await state(page);
  const path = bfs(st.walkable, st.tile, target);
  if (!path) throw new Error(`no path ${st.tile} -> ${target}`);
  for (let i = 1; i < path.length; i++) {
    const [dx, dy] = [path[i][0]-path[i-1][0], path[i][1]-path[i-1][1]];
    const k = dx > 0 ? 'ArrowRight' : dx < 0 ? 'ArrowLeft' : dy > 0 ? 'ArrowDown' : 'ArrowUp';
    await page.keyboard.down(k);
    for (let t = 0; t < 30; t++) { await sleep(40); const s = await state(page); if (s.tile[0] === path[i][0] && s.tile[1] === path[i][1]) break; }
    await page.keyboard.up(k); await sleep(60);
  }
  return state(page);
}
// Nearest walkable tile Chebyshev-adjacent to an NPC.
function adjacentTile(rows, npc) {
  for (const [dx, dy] of [[0,1],[0,-1],[1,0],[-1,0],[1,1],[-1,1],[1,-1],[-1,-1]]) {
    const t = [npc[0]+dx, npc[1]+dy];
    if (rows[t[1]] && rows[t[1]][t[0]] === '.') return t;
  }
  return null;
}
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
  check('movement blocked under onboarding (Right advances)', s.tile[0] === t0[0] && s.tile[1] === t0[1] && s.onboarding.step === 0);
  check('card 1 visual movement prompt', /these keys/.test(s.onboarding.card_text));
  await page.screenshot({ path: '/tmp/tv-onboard-card1.png' });
  await page.keyboard.press('ArrowLeft'); await sleep(250); s = await state(page);
  check('Left goes back to title', s.onboarding.title_visible && s.onboarding.step === -1);
  await page.keyboard.press('ArrowRight'); await sleep(250);
  await page.keyboard.press('ArrowRight'); await sleep(250); s = await state(page);
  check('Right → card 2 interaction', /press E/.test(s.onboarding.card_text));
  await page.screenshot({ path: '/tmp/tv-onboard-card2.png' });
  await page.keyboard.press('Space'); await sleep(900); s = await state(page);
  check('final card → fade → map, flag saved', !s.onboarding.active && s.seen_onboarding && s.flow.state === 'map');
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
  const t0m = s.tile.slice();
  await hold(page, 'ArrowRight', 400);
  s = await state(page);
  check('ArrowRight moves player', s.tile[0] > t0m[0], `tile=${s.tile}`);
  R.fps_moving = +(await rafFps(page, 2)).toFixed(1);

  // Walk to Mae wherever the (user-edited) map put her: BFS on the live grid.
  // Pick the first NPC reachable from where we stand (the map is user-edited
  // and may leave some NPCs disconnected from spawn — that is a map issue,
  // not a game bug, so the probe reports it and continues with another NPC).
  let mae = null, goal = null, npcName = null;
  for (const [name, t] of Object.entries(s.npcs)) {
    const g = adjacentTile(s.walkable, t);
    if (g && bfs(s.walkable, s.tile, g)) { mae = t; goal = g; npcName = name; break; }
  }
  const unreachable = Object.entries(s.npcs).filter(([n, t]) => { const g = adjacentTile(s.walkable, t); return !(g && bfs(s.walkable, s.tile, g)); }).map(([n]) => n);
  if (unreachable.length) console.log('WARN: NPCs not reachable from spawn on this map:', unreachable.join(', '));
  check('at least one NPC reachable from spawn', !!mae, npcName ? `using ${npcName}` : '');
  s = await walkTo(page, goal);
  check('walked next to NPC', Math.max(Math.abs(s.tile[0] - mae[0]), Math.abs(s.tile[1] - mae[1])) === 1, `tile=${s.tile} mae=${mae}`);
  await page.screenshot({ path: '/tmp/tv-map-prompt.png' });

  // ---------- Phase 1: basket_in, REAL mouse drags ----------
  await page.keyboard.press('KeyE'); await sleep(300);
  s = await waitState(page, s => s.flow.state === 'dialogue', 3000, 'dialogue');
  check('E → DIALOGUE (typewriter running)', s.flow.is_typing === true || s.flow.dialogue_text.length > 0);
  await page.keyboard.press('Escape'); await sleep(250); s = await state(page);
  check('Escape closes dialogue', s.flow.state === 'map');
  await page.keyboard.press('KeyE'); await sleep(300);
  s = await waitState(page, s => s.flow.state === 'dialogue', 3000, 'dialogue reopened');
  await page.screenshot({ path: '/tmp/tv-dialogue.png' });
  const tileBefore = s.tile.slice();
  await hold(page, 'ArrowRight', 500);
  s = await state(page);
  check('movement locked during dialogue', s.tile[0] === tileBefore[0] && s.tile[1] === tileBefore[1], `tile=${s.tile}`);
  let rr = await rects(page);
  await clickRect(page, rr.dialogue_box);            // click while typing → full text
  await sleep(200); s = await state(page);
  check('click while typing → full text', s.flow.is_typing === false);
  await page.screenshot({ path: '/tmp/tv-dialogue-complete.png' });
  await clickRect(page, rr.dialogue_box);            // click again → exercise
  s = await waitState(page, s => s.flow.state === 'exercise', 3000, 'exercise');
  const ex1 = { a: s.flow.basket_count, b: s.flow.target - s.flow.basket_count };
  check('dialogue dismissed -> EXERCISE basket_in', s.flow.mode === 'basket_in' && ex1.a > 0 && ex1.b > 0, JSON.stringify(ex1));
  await page.screenshot({ path: '/tmp/tv-ex-basket-in.png' });
  for (let i = 0; i < ex1.b; i++) {
    rr = await rects(page);
    if (!rr.item0) break;
    await realDrag(page, rr.item0, rr.basket);
  }
  s = await state(page);
  check(`${ex1.b} REAL mouse drags into basket -> ${s.flow.target}`, s.flow.basket_count === s.flow.target, `basket=${s.flow.basket_count} target=${s.flow.target} left=${s.flow.source_left}`);
  rr = await rects(page); await clickRect(page, rr.done);
  s = await waitState(page, s => s.flow.state === 'feedback', 3000, 'feedback');
  check('Done → FEEDBACK correct', s.flow.last_correct === true, s.flow.result_text);
  await page.screenshot({ path: '/tmp/tv-feedback.png' });
  s = await waitState(page, s => s.flow.state === 'map', 4000, 'back to map');
  check('feedback auto-dismiss → MAP, phase 2 unlocked', s.phases[npcName] === 1, `phases=${JSON.stringify(s.phases)}`);

  // ---------- Phase 2: basket_out, wrong first (hint tier 1), then right ----------
  await page.keyboard.press('KeyE'); await sleep(300);
  await waitState(page, s => s.flow.state === 'dialogue', 3000);
  await page.keyboard.press('KeyE'); await sleep(150); await page.keyboard.press('KeyE');
  s = await waitState(page, s => s.flow.state === 'exercise', 3000, 'phase2');
  const ex2 = { start: s.flow.basket_count };
  check('phase 2 basket_out', s.flow.mode === 'basket_out' && ex2.start > 0, JSON.stringify(ex2));
  rr = await rects(page); await realDrag(page, rr.item0, rr.tray);          // 1 out (wrong for every NPC: remove >= 2)
  rr = await rects(page); await clickRect(page, rr.done);
  s = await waitState(page, s => s.flow.state === 'feedback', 3000);
  check('1 out → wrong feedback', s.flow.last_correct === false);
  s = await waitState(page, s => s.flow.state === 'exercise', 4000, 'retry');
  check('wrong → SAME exercise + tier-1 hint', s.flow.mode === 'basket_out' && s.flow.hint_visible && s.flow.hint_text.length > 5, s.flow.hint_text);
  await page.screenshot({ path: '/tmp/tv-ex-basket-out-hint.png' });
  // remove = start - answer; answer isn't exposed, so drag until Done says correct: try 2..6
  let ok2 = false;
  for (let n = 2; n <= 6 && !ok2; n++) {
    for (let k = (await state(page)).flow.tray_count; k < n; k++) { rr = await rects(page); await realDrag(page, rr.item0, rr.tray); }
    rr = await rects(page); await clickRect(page, rr.done);
    s = await waitState(page, s => s.flow.state === 'feedback', 3000);
    ok2 = s.flow.last_correct === true;
    if (!ok2) await waitState(page, s => s.flow.state === 'exercise', 4000);
  }
  check('REAL drags out until correct', ok2);
  s = await waitState(page, s => s.flow.state === 'map', 4000);
  check('phase 3 unlocked', s.phases[npcName] === 2);

  // ---------- Phase 3: multiplication array, filled with real drags ----------
  await page.keyboard.press('KeyE'); await sleep(300);
  await waitState(page, s => s.flow.state === 'dialogue', 3000);
  await page.keyboard.press('KeyE'); await sleep(150); await page.keyboard.press('KeyE');
  s = await waitState(page, s => s.flow.state === 'exercise', 3000, 'phase3');
  check('phase 3 → visual array mode', s.flow.mode === 'array' && s.flow.visual_cells > 0);
  const arrayCount = s.flow.visual_cells;
  for (let i = 0; i < arrayCount; i++) {
    rr = await rects(page);
    await realDrag(page, rr.item0, rr[`array${i}`]);
  }
  s = await state(page);
  check('REAL drags fill every multiplication cell', s.flow.visual_source_left === 0);
  await page.screenshot({ path: '/tmp/tv-ex-array.png' });
  rr = await rects(page); await clickRect(page, rr.done);
  s = await waitState(page, s => s.flow.state === 'feedback', 3000);
  check('completed array → correct', s.flow.last_correct === true, s.flow.result_text);
  s = await waitState(page, s => s.flow.state === 'map', 4000);
  check('phase 4 unlocked', s.phases[npcName] === 3);

  // ---------- Phase 4: fair sharing, no punitive failure ----------
  await page.keyboard.press('KeyE'); await sleep(300);
  await waitState(page, s => s.flow.state === 'dialogue', 3000);
  await page.keyboard.press('KeyE'); await sleep(150); await page.keyboard.press('KeyE');
  s = await waitState(page, s => s.flow.state === 'exercise', 3000, 'phase4');
  check('phase 4 → visual share mode', s.flow.mode === 'share' && s.flow.share_groups > 1);
  const groups = s.flow.share_groups;
  const perGroup = s.flow.target;
  rr = await rects(page); await realDrag(page, rr.item0, rr.share0);
  rr = await rects(page); await clickRect(page, rr.done); await sleep(250); s = await state(page);
  check('unequal share stays editable with a hint', s.flow.state === 'exercise' && s.flow.hint_visible);
  for (let group = 0; group < groups; group++) {
    const already = group === 0 ? 1 : 0;
    for (let n = already; n < perGroup; n++) {
      rr = await rects(page);
      await realDrag(page, rr.item0, rr[`share${group}`]);
    }
  }
  s = await state(page);
  check('REAL drags distribute the full collection equally', s.flow.visual_source_left === 0);
  await page.screenshot({ path: '/tmp/tv-ex-share.png' });
  rr = await rects(page); await clickRect(page, rr.done);
  s = await waitState(page, s => s.flow.state === 'feedback', 3000);
  check('equal sharing → correct', s.flow.last_correct === true, s.flow.result_text);
  s = await waitState(page, s => s.flow.state === 'map', 4000);
  check('NPC completed, back on map, movement free', s.phases[npcName] === 4 && s.flow.state === 'map');
  {
    const nb = [['ArrowRight',1,0],['ArrowLeft',-1,0],['ArrowDown',0,1],['ArrowUp',0,-1]].find(([,dx,dy]) => (s.walkable[s.tile[1]+dy]||'')[s.tile[0]+dx] === '.');
    await hold(page, nb[0], 400);
  }
  const s2 = await state(page);
  check('player moves again after loop', s2.tile[0] !== s.tile[0] || s2.tile[1] !== s.tile[1], `${s.tile}→${s2.tile}`);
  await page.screenshot({ path: '/tmp/tv-after-loop.png' });

  // ---------- F1 editor still works ----------
  await page.keyboard.press('F1'); await sleep(400); s = await state(page);
  check('F1 → editor + grid', s.edit_mode && s.grid_visible);
  await page.screenshot({ path: '/tmp/tv-editor.png' });
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
