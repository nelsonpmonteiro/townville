import { test, expect } from "@playwright/test";
test("walk to Mae, count eggs by dragging and tapping, celebrate and persist", async ({
  page,
}) => {
  await page.goto("/");
  await expect(page.getByText("Little steps. A growing town.")).toBeVisible();
  await page.screenshot({ path: "artifacts/farm.png", fullPage: true });
  await page.getByRole("button", { name: "Talk to Mae", exact: true }).click();
  await expect(page.getByText("Move 3 eggs to the basket.")).toBeVisible();
  await page.getByRole("button", { name: "Check my collection" }).click();
  await expect(
    page.getByText("Not quite yet. Count together and try again."),
  ).toBeVisible();
  const egg = page.getByRole("button", { name: "egg 1", exact: true });
  const target = page.getByRole("button", { name: "basket", exact: true });
  const a = await egg.boundingBox(),
    b = await target.boundingBox();
  await page.mouse.move(a!.x + a!.width / 2, a!.y + a!.height / 2);
  await page.mouse.down();
  await page.mouse.move(b!.x + b!.width / 2, b!.y + b!.height / 2, {
    steps: 12,
  });
  await page.mouse.up();
  await expect(page.getByText("Collected: 1")).toBeVisible();
  for (const i of [2, 3]) {
    await page.getByRole("button", { name: `egg ${i}`, exact: true }).click();
    await target.click();
  }
  await page.screenshot({ path: "artifacts/counting.png", fullPage: true });
  await page.getByRole("button", { name: "Check my collection" }).click();
  await expect(page.getByText("You helped the farm grow!")).toBeVisible();
  await page.getByRole("button", { name: "Back to the farm" }).click();
  await expect(page.getByText("Hen house • Level 1")).toBeVisible();
  await page.reload();
  await expect(page.getByText("100 stars")).toBeVisible();
  await expect(page.getByText("1 / 5 helping hands")).toBeVisible();
});
