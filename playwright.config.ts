import { defineConfig } from "@playwright/test";
export default defineConfig({
  testDir: "./e2e",
  use: {
    baseURL: process.env.TOWNVILLE_URL || "http://localhost:8082",
    viewport: { width: 1280, height: 960 },
  },
  timeout: 30000,
  workers: 1,
  webServer: process.env.TOWNVILLE_URL
    ? undefined
    : {
        command: "npm run web",
        url: "http://localhost:8082",
        reuseExistingServer: true,
        timeout: 180000,
      },
});
