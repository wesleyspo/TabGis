import { defineConfig, devices } from "@playwright/test";

/**
 * Base URL: serviço nginx da POC (ver infra/docker-compose.yml, porta 8088).
 * Sobrescrever: PLAYWRIGHT_BASE_URL=http://homeserver:8088 npm test
 */
export default defineConfig({
  testDir: "./specs",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [["list"]],
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:8088",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
});
