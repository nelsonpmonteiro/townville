import { test, expect } from '@playwright/test';

 test('player swaps walk frames and returns to idle at a stable aspect ratio', async ({ page }) => {
  await page.goto('/');
  const player = page.locator('#protagonist-active img');
  await expect(player).toHaveCount(1);
  await expect.poll(() => player.evaluate((i: HTMLImageElement) => i.naturalHeight)).toBeGreaterThan(0);
  for (const [key, dir] of [['ArrowLeft', 'left'], ['ArrowRight', 'right'], ['ArrowDown', 'front'], ['ArrowUp', 'back']]) {
    // The vertical corridor is at x=16; x=20 below spawn is blocked.
    if (dir === 'front') {
      for (let i = 0; i < 4; i++) {
        await page.keyboard.press('ArrowLeft');
        await page.waitForTimeout(270);
      }
    }
    const frames = new Set<string>();
    // Repeated individual steps exercise the tile movement and the animation clock.
    for (let step = 0; step < 8; step++) {
      await page.keyboard.press(key);
      await page.waitForTimeout(60);
      const state = await player.evaluate((i: HTMLImageElement) => {
        const r = i.parentElement!.getBoundingClientRect();
        return { src: i.src, w: r.width, h: r.height, nw: i.naturalWidth, nh: i.naturalHeight };
      });
      if (state.src.includes(`boy-walk-${dir}-`)) {
        frames.add(state.src);
        if (state.nh > 0) expect(state.w / state.h).toBeCloseTo(state.nw / state.nh, 2);
      }
      await page.waitForTimeout(210);
    }
    expect(frames.size, `${dir} should animate through distinct frames`).toBeGreaterThan(1);
    await expect(player).toHaveAttribute('src', new RegExp(`boy-${dir}[.]`));
    const idle = await player.evaluate((i: HTMLImageElement) => {
      const r = i.parentElement!.getBoundingClientRect();
      return { ratio: r.width / r.height, nativeRatio: i.naturalWidth / i.naturalHeight };
    });
    expect(idle.ratio).toBeCloseTo(idle.nativeRatio, 2);
  }
});
