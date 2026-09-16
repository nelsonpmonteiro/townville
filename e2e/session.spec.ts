import { test, expect } from "@playwright/test";
test("complete the whole five-quest session by walking between neighbours", async ({
  page,
}) => {
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await page.goto("/");
  await expect(page.getByText("0 stars")).toBeVisible();
  await page.getByRole("button", { name: "Talk to Lily", exact: true }).click();
  await expect(
    page.getByText("Walk closer to Lily to say hello."),
  ).toBeVisible();
  const solve = async (
    npc: string,
    kind: string,
    target: string,
    count: number,
  ) => {
    await page
      .getByRole("button", { name: `Help ${npc}`, exact: true })
      .click();
    for (let i = 1; i <= count; i++) {
      await page
        .getByRole("button", { name: `${kind} ${i}`, exact: true })
        .click();
      await page.getByRole("button", { name: target, exact: true }).click();
    }
    await page.getByRole("button", { name: "Check my collection" }).click();
    await expect(page.getByText("You helped the farm grow!")).toBeVisible();
    await page.getByRole("button", { name: "Back to the farm" }).click();
  };
  const walk = async (key: string, n: number) => {
    for (let i = 0; i < n; i++) await page.keyboard.press(key);
  };
  await solve("Mae", "egg", "basket", 3);
  await walk("ArrowLeft", 3);
  await walk("ArrowUp", 2);
  await solve("Chester", "chick", "pen", 4);
  await walk("ArrowDown", 2);
  await walk("ArrowRight", 9);
  await solve("Lily", "hay", "stable", 2);
  await walk("ArrowLeft", 6);
  await solve("Mae", "egg", "basket", 5);
  await walk("ArrowLeft", 3);
  await walk("ArrowUp", 2);
  await solve("Chester", "chick", "pen", 6);
  await expect(
    page.getByText("5 helping hands. A happier farm."),
  ).toBeVisible();
  await page.screenshot({ path: "artifacts/summary.png", fullPage: true });
  await page.getByRole("button", { name: "Keep exploring" }).click();
  await page.getByRole("button", { name: "Sound on", exact: true }).click();
  await page.reload();
  await expect(page.getByText("500 stars")).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Sound off", exact: true }),
  ).toBeVisible();
  expect(errors).toEqual([]);
});
test("mobile camera starts on the player and touch can collect an egg", async ({
  browser,
}) => {
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    isMobile: true,
    hasTouch: true,
  });
  const page = await context.newPage();
  await page.goto("/");
  await expect(page.getByText("0 stars")).toBeVisible();
  await expect(page.getByTestId("player")).toBeInViewport();
  await page.getByRole("button", { name: "Talk to Mae", exact: true }).tap();
  const eggBox = await page
    .getByRole("button", { name: "egg 1", exact: true })
    .boundingBox();
  const targetBox = await page
    .getByRole("button", { name: "basket", exact: true })
    .boundingBox();
  const cdp = await context.newCDPSession(page);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: eggBox!.x + 30, y: eggBox!.y + 30 }],
  });
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [{ x: targetBox!.x + 40, y: targetBox!.y + 40 }],
  });
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  await expect(page.getByText("Collected: 1")).toBeVisible();
  await page.getByRole("button", { name: "egg 2", exact: true }).tap();
  await page.getByRole("button", { name: "basket", exact: true }).tap();
  await expect(page.getByText("Collected: 2")).toBeVisible();
  await page.screenshot({ path: "artifacts/mobile.png", fullPage: true });
  await context.close();
});
