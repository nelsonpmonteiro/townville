// Smoke e2e for the CURRENT Townville build (40×30 map, WASD movement,
// dialogue/quest flow). Replaces the legacy prototype specs (star counter,
// "Talk to Mae" buttons, egg drag) that tested a UI that no longer exists.
import { test, expect } from "@playwright/test";

test("app boots clean: header renders, no console errors, no error overlay", async ({ page }) => {
  const errors: string[] = [];
  page.on("console", (msg) => {
    if (msg.type() === "error") errors.push(msg.text());
  });
  page.on("pageerror", (err) => errors.push(String(err)));

  await page.goto("/");
  // Game header shows lives/score — wait for the app shell
  await expect(page.locator("#root")).toBeVisible();
  await page.waitForTimeout(4000); // bundle eval + first render

  // Expo dev error overlay must not be present
  const overlay = page.locator("text=/Unhandled|Cannot read|is not a function/i");
  await expect(overlay).toHaveCount(0);

  // No console errors (RN Web deprecation warnings are type=warning, not error)
  const realErrors = errors.filter(
    (e) => !e.includes("Download the React DevTools")
  );
  expect(realErrors, `console errors:\n${realErrors.join("\n")}`).toHaveLength(0);
});

test("keyboard movement moves the protagonist across tiles", async ({ page }) => {
  await page.goto("/");
  await page.waitForTimeout(4000);

  // Protagonist is the only zIndex:45 animated image
  const before = await page.evaluate(() => {
    const imgs = Array.from(document.querySelectorAll("img"));
    const p = imgs.find((i) => {
      const z = getComputedStyle(i.parentElement ?? i).zIndex || getComputedStyle(i).zIndex;
      return z === "45";
    }) ?? imgs[imgs.length - 1];
    const r = p!.getBoundingClientRect();
    return { x: r.x, y: r.y };
  });

  // Spawn (20,7): row 7 corridor is walkable to the left
  for (let i = 0; i < 3; i++) {
    await page.keyboard.press("ArrowLeft");
    await page.waitForTimeout(260); // MOVEMENT_DURATION + margin
  }

  const after = await page.evaluate(() => {
    const imgs = Array.from(document.querySelectorAll("img"));
    const p = imgs.find((i) => {
      const z = getComputedStyle(i.parentElement ?? i).zIndex || getComputedStyle(i).zIndex;
      return z === "45";
    }) ?? imgs[imgs.length - 1];
    const r = p!.getBoundingClientRect();
    return { x: r.x, y: r.y };
  });

  // Camera-relative: either the sprite moved or the world scrolled under it.
  // Just assert SOMETHING changed in layout (movement pipeline alive).
  const moved = before.x !== after.x || before.y !== after.y;
  expect(moved).toBe(true);
});
