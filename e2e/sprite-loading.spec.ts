import { test, expect } from '@playwright/test';

test('cold-cache animation never replaces visible art with an undecoded frame', async ({ page }) => {
  await page.route('**/*', async route => {
    if (route.request().url().includes('boy-walk-')) await new Promise(r => setTimeout(r, 500));
    await route.continue();
  });
  await page.goto('/');
  const player = page.locator('#protagonist-active img');
  await expect.poll(() => player.evaluate((i: HTMLImageElement) => i.complete && i.naturalWidth > 0)).toBe(true);
  await page.keyboard.down('ArrowLeft');
  const result = await page.evaluate(async () => {
    let blank = 0, count = 0;
    const end = performance.now() + 1000;
    while (performance.now() < end) {
      await new Promise(requestAnimationFrame);
      const img = document.querySelector<HTMLImageElement>('#protagonist-active img');
      count++;
      if (!img || !img.complete || !img.naturalWidth) blank++;
    }
    return {blank, count};
  });
  await page.keyboard.up('ArrowLeft');
  expect(result.count).toBeGreaterThan(10);
  expect(result.blank, 'frames with missing/unloaded sprite pixels').toBe(0);
  await expect(player).toHaveAttribute('src', /boy-left[.]/);
});
