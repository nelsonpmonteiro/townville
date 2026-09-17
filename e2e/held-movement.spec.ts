import { test, expect } from '@playwright/test';

test('releasing a blocked direction resumes the other held arrow', async ({ page }) => {
  await page.goto('/');
  const player = page.locator('#protagonist-active img');
  await expect(player).toHaveCount(1);
  await page.keyboard.down('ArrowLeft');
  await page.keyboard.down('ArrowDown');
  // Finish the left step, then encounter the blocked tile below x=19.
  await expect(player).toHaveAttribute('src', /boy-front[.]/);
  await page.keyboard.up('ArrowDown');
  await expect(player).toHaveAttribute('src', /boy-walk-left-/);
  await page.keyboard.up('ArrowLeft');
  await expect(player).toHaveAttribute('src', /boy-left[.]/);
});

test('OS key repeat cannot interrupt an active step; blur clears held input', async ({ page }) => {
  await page.goto('/');
  const player = page.locator('#protagonist-active img');
  await expect(player).toHaveCount(1);
  await page.keyboard.down('ArrowLeft');
  const samples = await page.evaluate(async () => {
    const sources: string[] = [];
    for (let i = 0; i < 25; i++) {
      window.dispatchEvent(new KeyboardEvent('keydown', {key: 'ArrowLeft', repeat: true}));
      await new Promise(resolve => setTimeout(resolve, 30));
      sources.push(document.querySelector<HTMLImageElement>('#protagonist-active img')!.src);
    }
    return sources;
  });
  expect(samples.filter(src => !src.includes('boy-walk-left-')).length).toBe(0);
  await page.evaluate(() => window.dispatchEvent(new Event('blur')));
  await expect(player).toHaveAttribute('src', /boy-left[.]/);
  const stopped = await player.evaluate(i => (i.closest('[data-testid=protagonist]') as HTMLElement).style.transform);
  await page.waitForTimeout(350);
  expect(await player.evaluate(i => (i.closest('[data-testid=protagonist]') as HTMLElement).style.transform)).toBe(stopped);
  await page.keyboard.up('ArrowLeft');
});

test('blocked held direction stays idle and editor toggle still returns to the game', async ({ page }) => {
  await page.goto('/');
  const player = page.locator('#protagonist-active img');
  await expect(player).toHaveCount(1);
  const start = await player.evaluate(i => (i.closest('[data-testid=protagonist]') as HTMLElement).style.transform);
  await page.keyboard.down('ArrowDown'); // blocked below the spawn
  await page.waitForTimeout(450);
  await expect(player).toHaveAttribute('src', /boy-front[.]/);
  expect(await player.evaluate(i => (i.closest('[data-testid=protagonist]') as HTMLElement).style.transform)).toBe(start);
  await page.keyboard.up('ArrowDown');
  await page.keyboard.press('e');
  await expect(player).toHaveCount(0);
  await page.keyboard.press('e');
  await expect(player).toHaveCount(1);
});

test('holding an arrow keeps walking without idle or blank frames until release', async ({ page }) => {
  await page.goto('/');
  const player = page.locator('#protagonist-active img');
  await expect(player).toHaveCount(1);
  await expect.poll(() => player.evaluate((i: HTMLImageElement) => i.naturalHeight)).toBeGreaterThan(0);
  await page.keyboard.down('ArrowLeft'); // one keydown, no OS repeat dependency
  const samples = await page.evaluate(async () => {
    const samples: {src: string; background: string; transform: string}[] = [];
    const until = performance.now() + 1100;
    while (performance.now() < until) {
      await new Promise(requestAnimationFrame);
      const img = document.querySelector<HTMLImageElement>('#protagonist-active img')!;
      samples.push({src: img.src, background: (img.parentElement!.firstElementChild as HTMLElement).style.backgroundImage,
        transform: (img.closest('[data-testid=protagonist]') as HTMLElement).style.transform});
    }
    return samples;
  });
  await page.keyboard.up('ArrowLeft');
  const steady = samples.slice(5);
  expect(steady.length).toBeGreaterThan(10);
  expect(steady.filter(s => !s.src.includes('boy-walk-left-')).length, 'no idle frames while held').toBe(0);
  expect(steady.filter(s => !s.background || s.background === 'none'), 'no blank sprite backgrounds').toEqual([]);
  expect(new Set(steady.map(s => s.src)).size).toBeGreaterThan(4);
  expect(new Set(steady.map(s => s.transform)).size).toBeGreaterThan(20);
  await expect(player).toHaveAttribute('src', /boy-left[.]/);
  const stopped = await player.evaluate(i => (i.closest('[data-testid=protagonist]') as HTMLElement).style.transform);
  await page.waitForTimeout(350);
  expect(await player.evaluate(i => (i.closest('[data-testid=protagonist]') as HTMLElement).style.transform)).toBe(stopped);
});
