import { test, expect } from "@playwright/test";

test.describe("TabGis POC — fumo ponta-a-ponta", () => {
  test("mapa e API de traduções respondem (stack Docker)", async ({ page, request }) => {
    const tr = await request.get("/api/translations/pt");
    expect(tr.ok(), "GET /api/translations/pt deve retornar 200").toBeTruthy();
    const json = await tr.json();
    expect(typeof json).toBe("object");
    expect(Object.keys(json).length).toBeGreaterThan(0);

    await page.goto("/");
    await expect(page.locator("#map")).toBeVisible();
    await expect(page.locator("#map .leaflet-container")).toBeVisible({ timeout: 30_000 });

    await expect(page.getByRole("button", { name: /Operação|Operation/i })).toBeVisible();
    await expect(page.locator(".config-dropdown summary")).toBeVisible();
  });

  test("configurações abre e lista opções de gestão", async ({ page }) => {
    await page.goto("/");
    await page.locator(".config-dropdown summary").click();
    const dd = page.locator(".config-dropdown");
    await expect(dd.getByRole("button", { name: /Gerenciar visualização|visualização/i })).toBeVisible();
    await expect(dd.getByRole("button", { name: "Gerenciar utilizadores" })).toBeVisible();
    await expect(dd.getByRole("button", { name: "Tipos de domínio (ref)" })).toBeVisible();
  });
});
