import { test, expect } from "@playwright/test";
test("audio does not play before gesture; mute and background pause it", async ({
  page,
}) => {
  await page.addInitScript(() => {
    const w = window as any;
    w.audioCalls = { play: 0, pause: 0 };
    const play = HTMLMediaElement.prototype.play,
      pause = HTMLMediaElement.prototype.pause;
    HTMLMediaElement.prototype.play = function () {
      w.audioCalls.play++;
      return play.call(this);
    };
    HTMLMediaElement.prototype.pause = function () {
      w.audioCalls.pause++;
      return pause.call(this);
    };
  });
  await page.goto("/");
  await expect(page.getByText("0 stars")).toBeVisible();
  expect(await page.evaluate(() => (window as any).audioCalls.play)).toBe(0);
  await page.getByRole("button", { name: "Help Mae", exact: true }).click();
  expect(
    await page.evaluate(() => (window as any).audioCalls.play),
  ).toBeGreaterThan(0);
  const pauses = await page.evaluate(() => (window as any).audioCalls.pause);
  await page.evaluate(() => {
    Object.defineProperty(document, "hidden", {
      configurable: true,
      get: () => true,
    });
    document.dispatchEvent(new Event("visibilitychange"));
  });
  expect(
    await page.evaluate(() => (window as any).audioCalls.pause),
  ).toBeGreaterThan(pauses);
  await page.evaluate(() => {
    Object.defineProperty(document, "hidden", {
      configurable: true,
      get: () => false,
    });
    document.dispatchEvent(new Event("visibilitychange"));
  });
  await page.getByRole("button", { name: "Back to exploring" }).click();
  await page.getByRole("button", { name: "Sound on", exact: true }).click();
  const plays = await page.evaluate(() => (window as any).audioCalls.play);
  await page.getByRole("button", { name: "Help Mae", exact: true }).click();
  expect(await page.evaluate(() => (window as any).audioCalls.play)).toBe(
    plays,
  );
});
test("malformed persistence does not prevent play", async ({ page }) => {
  await page.addInitScript(() =>
    localStorage.setItem("townville.save.v1", "{broken"),
  );
  await page.goto("/");
  await expect(page.getByText("0 stars")).toBeVisible();
  await page.getByRole("button", { name: "Help Mae", exact: true }).click();
  await expect(page.getByText("Move 3 eggs to the basket.")).toBeVisible();
});
