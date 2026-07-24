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

  test("desenho de segmento no mapa cria via POST /api/topology/spans", async ({ page, request }) => {
    const meta = await request.get("/api/topology/meta");
    expect(meta.ok(), "GET /api/topology/meta").toBeTruthy();
    if (!(await meta.json()).installed) {
      test.skip();
    }

    await page.goto("/");
    await page.locator("#map .leaflet-tile-pane").waitFor({ state: "attached" });
    await expect(page.locator("#status")).toContainText(/carregado|loaded/i, { timeout: 15000 });

    const layersSummary = page.locator("details.panel-section summary", {
      hasText: /Camadas|Layers/i,
    });
    await layersSummary.click();
    await page.locator("#network_span_draw_btn").click();
    // Modo activo: o botão muda para «Cancelar desenho».
    await expect(page.locator("#network_span_draw_btn")).toContainText(/Cancelar|Cancel/i);
    // Fecha o painel de camadas para não interceptar cliques no mapa.
    await layersSummary.click();

    const map = page.locator("#map");
    const box = await map.boundingBox();
    expect(box).not.toBeNull();

    const postResponse = page.waitForResponse(
      (r) =>
        r.url().includes("/api/topology/spans") &&
        r.request().method() === "POST" &&
        !r.url().includes("maintenance"),
      { timeout: 20000 }
    );

    // Cliques relativos ao contentor do mapa (Leaflet recebe eventos no contentor).
    await map.click({ position: { x: box!.width * 0.4, y: box!.height * 0.45 } });
    await map.click({ position: { x: box!.width * 0.6, y: box!.height * 0.55 } });
    await page.keyboard.press("Enter");

    const res = await postResponse;
    expect(res.status(), "POST deve devolver 201").toBe(201);
    const body = await res.json();
    expect(body.span?.code).toMatch(/^SEG_\d{8}_\d{9}$/);
    expect(body.span?.has_topo_geom).toBe(true);

    const del = await request.delete(`/api/topology/spans/${body.span.id}`);
    expect(del.ok(), "DELETE do segmento de teste").toBeTruthy();
    const prune = await request.post("/api/topology/maintenance/prune", { data: {} });
    expect(prune.ok(), "prune pós-teste").toBeTruthy();
  });

  test("API MWM team-routes 48h e displacements respondem", async ({ request }) => {
    const routes = await request.get("/api/mwm/team-routes?hours=48");
    expect(routes.ok(), "GET /api/mwm/team-routes").toBeTruthy();
    const body = await routes.json();
    expect(body.hours).toBe(48);
    expect(typeof body.count).toBe("number");
    expect(Array.isArray(body.routes)).toBeTruthy();
    if (body.count > 0) {
      expect(body.routes[0].route_geojson).toBeTruthy();
      expect(body.routes[0].team_code).toBeTruthy();
    }

    const bad = await request.get("/api/mwm/team-routes?hours=999");
    expect(bad.status()).toBe(400);

    const disp = await request.get("/api/mwm/displacements?limit=10");
    expect(disp.ok(), "GET /api/mwm/displacements").toBeTruthy();
    expect(Array.isArray(await disp.json())).toBeTruthy();
  });

  test("aba MWM mostra resumo de rotas 48h", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: /Operação|Operation/i }).click();
    await page.getByRole("tab", { name: /MWM|Equipes|Equipas/i }).click();
    await expect(page.locator("#mwm-routes-48h-summary")).toContainText(/48|rota|route|traza|percors/i, {
      timeout: 10000,
    });
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
