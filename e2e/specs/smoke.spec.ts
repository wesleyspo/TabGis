import { test, expect } from "@playwright/test";

test.describe("TabGis — fumo ponta-a-ponta", () => {
  test("mapa e API de traduções respondem (stack Docker)", async ({ page, request }) => {
    const tr = await request.get("/api/translations/pt");
    expect(tr.ok(), "GET /api/translations/pt deve retornar 200").toBeTruthy();
    const json = await tr.json();
    expect(typeof json).toBe("object");
    expect(Object.keys(json).length).toBeGreaterThan(0);

    await page.goto("/");
    await expect(page.locator("#map")).toBeVisible();
    await expect(page.locator("#status")).toBeVisible();

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
    await expect(dd.getByRole("button", { name: /Gerenciar Traduções|Traduções/i })).toBeVisible();
    await expect(dd.getByRole("button", { name: "Ajuda" })).toBeVisible();
  });

  test("painel de operação exibe todas as abas previstas", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: /Operação|Operation/i }).click();

    const tabBar = page.locator(".operacao-tab-bar");
    await expect(tabBar).toBeVisible();
    await expect(tabBar.getByRole("tab", { name: /OMS|Ordens/i })).toBeVisible();
    await expect(tabBar.getByRole("tab", { name: /MWM|Equipes|Equipas/i })).toBeVisible();
    await expect(tabBar.getByRole("tab", { name: /DMS|Telecomando/i })).toBeVisible();
    await expect(tabBar.getByRole("tab", { name: /IND|Indicadores/i })).toBeVisible();
    await expect(tabBar.getByRole("tab", { name: /SMT|telemetria/i })).toBeVisible();
    await expect(tabBar.getByRole("tab", { name: /ESQ|Esquemático|Schematic|unifilar/i })).toBeVisible();
    await expect(tabBar.getByRole("tab", { name: /TMP|Clima/i })).toBeVisible();
    await expect(tabBar.getByRole("tab", { name: /AUD|Auditoria/i })).toBeVisible();
  });

  test("atalho de clima navega para guia TMP", async ({ page }) => {
    await page.goto("/");
    await page.locator("#btn-top-weather").click();

    await expect(page.locator('.operacao-panel[data-panel="tmp"]')).toBeVisible();
    await expect(page.getByRole("heading", { name: /Clima/i })).toBeVisible();
  });

  test("camada de segmentos lineares da rede activa via toggle (WMS + API topologia)", async ({ page, request }) => {
    const meta = await request.get("/api/topology/meta");
    expect(meta.ok(), "GET /api/topology/meta").toBeTruthy();
    const m = await meta.json();
    if (!m.installed) {
      test.skip();
    }

    await page.goto("/");
    // O menu Camadas é um <details class="panel-section"> na topbar.
    await page
      .locator("details.panel-section summary", { hasText: /Camadas|Layers/i })
      .click();
    const toggle = page.locator("#network_span_layer");
    await expect(toggle).toBeAttached();

    const wmsRequest = page.waitForRequest(
      (r) => r.url().includes("v_network_span_wms"),
      { timeout: 15000 }
    );
    // O input é visualmente escondido pelo toggle-switch; clica-se na pista visível.
    await page.locator("label.toggle-switch:has(#network_span_layer) .toggle-track").click();
    await expect(toggle).toBeChecked();
    await wmsRequest;
  });

  test("guia ESQ carrega unifilar (API e escada)", async ({ page, request }) => {
    const v = await request.get("/api/schematic/views");
    expect(v.ok(), "GET /api/schematic/views").toBeTruthy();
    const list = await v.json();
    if (list.length === 0) {
      test.skip();
    }

    await page.goto("/");
    await page.getByRole("button", { name: /Operação|Operation/i }).click();
    await page.getByRole("tab", { name: /ESQ|Esquemático|Schematic|unifilar/i }).click();
    await expect(page.locator("#esq-view-select option")).toHaveCount(list.length, { timeout: 10000 });
    await expect(page.locator(".esq-ladder")).toBeVisible({ timeout: 15000 });
  });
});
