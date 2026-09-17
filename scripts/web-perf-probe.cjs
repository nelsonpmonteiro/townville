// Real-browser acceptance probe for the Godot web export at localhost:8090.
// Checks: FPS, arrow movement, E-interact, grid hidden in play mode, F1 editor.
const { chromium } = require('playwright');
const fs = require('fs');
const { PNG } = (() => { try { return require('pngjs'); } catch { return {}; } })();

async function rafFps(page, secs) {
  return page.evaluate(s => new Promise(res => {
    let n = 0; const t0 = performance.now();
    (function f(){ n++; if (performance.now() - t0 < s * 1000) requestAnimationFrame(f); else res(n / s); })();
  }), secs);
}

// Godot exposes nothing to JS; we read engine state via a tiny bridge we
// register from GDScript through JavaScriptBridge (see game.gd).
async function state(page) {
  return page.evaluate(() => window.__townville_state || null);
}

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 960, height: 640 } });
  const logs = [];
  page.on('console', m => logs.push(`[${m.type()}] ${m.text()}`));
  page.on('pageerror', e => logs.push(`[pageerror] ${e.message}`));
  await page.goto('http://localhost:8090/index.html', { waitUntil: 'load' });
  await page.waitForTimeout(12000);

  const results = {};
  results.fps_idle = +(await rafFps(page, 3)).toFixed(1);
  results.state_boot = await state(page);

  const canvas = await page.$('canvas');
  await canvas.click({ position: { x: 480, y: 320 } });
  await page.keyboard.down('ArrowRight');
  await page.waitForTimeout(700);
  await page.keyboard.up('ArrowRight');
  await page.waitForTimeout(300);
  results.state_after_right = await state(page);
  results.fps_moving = +(await rafFps(page, 2)).toFixed(1);

  // Walk to Chester: spawn (15,6); Chester at (14,4). Stand at (14,5) — the
  // spine tile directly below him (Manhattan distance 1 = adjacent).
  await page.keyboard.down('ArrowUp'); await page.waitForTimeout(450); await page.keyboard.up('ArrowUp');
  await page.waitForTimeout(150);
  await page.keyboard.down('ArrowLeft'); await page.waitForTimeout(520); await page.keyboard.up('ArrowLeft');
  await page.waitForTimeout(300);
  results.state_near_chester = await state(page);
  await page.keyboard.press('KeyE');
  await page.waitForTimeout(400);
  results.state_after_E = await state(page);
  await page.screenshot({ path: '/tmp/tv-play.png' });

  await page.keyboard.press('Escape');
  await page.keyboard.press('F1');
  await page.waitForTimeout(500);
  results.state_after_F1 = await state(page);
  await page.screenshot({ path: '/tmp/tv-editor.png' });
  await page.keyboard.press('F1');
  await page.waitForTimeout(300);
  results.state_after_F1_off = await state(page);

  console.log(JSON.stringify(results, null, 2));
  const errs = logs.filter(l => /error|pageerror/i.test(l) && !/GL Driver/.test(l));
  console.log('CONSOLE_TOTAL:', logs.length, 'ERRORS:', errs.length);
  errs.slice(0, 10).forEach(l => console.log('  ', l));
  await browser.close();
})().catch(e => { console.error('PROBE_ERROR', e.message); process.exit(1); });
