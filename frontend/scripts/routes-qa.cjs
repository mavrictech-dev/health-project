const { chromium } = require(process.env.HEALTH_PLAYWRIGHT_MODULE || 'playwright');
const { readFileSync, mkdirSync, writeFileSync } = require('node:fs');
const spec = JSON.parse(readFileSync('src/data/spec.json', 'utf8'));
spec.screens.push(...JSON.parse(readFileSync('src/data/saas-screens.json', 'utf8')));
const base = process.env.HEALTH_PREVIEW_URL || 'http://127.0.0.1:3000';
(async () => {
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1050 }, reducedMotion: 'reduce' });
  const page = await context.newPage(); page.setDefaultTimeout(60000); const errors = []; const results = []; const reached = new Set();
  page.on('pageerror', error => errors.push({ url: page.url(), message: error.message }));
  try {
    await page.goto(base, { waitUntil: 'domcontentloaded', timeout: 120000 });
    await page.getByRole('heading', { name: 'Buen día, Dr. Mateo' }).waitFor();
    await page.getByRole('button', { name: 'Tema blanco', exact: true }).click();
    const baseline = await page.evaluate(() => JSON.parse(localStorage.getItem('health-project-demo-v1')));
    if (!baseline?.state?.data) throw new Error('La demo no se hidrató.');
    for (const screen of spec.screens) {
      const vet = ['S11', 'S13', 'S47'].includes(screen.id);
      const role = screen.roles.includes('PRO') ? 'PRO' : screen.roles[0];
      const state = structuredClone(baseline);
      state.state.context = { ...state.state.context, role, org: vet ? 'org-vet' : 'org-human', branch: vet ? 'vet-centro' : 'miraflores', patient: vet ? 'p-luna' : 'p-lucia', encounter: vet ? 'e-vet' : 'e-1', specialty: vet ? 'V_GENERAL' : 'H_GENERAL_MEDICINE' };
      await page.evaluate(value => localStorage.setItem('health-project-demo-v1', JSON.stringify(value)), state);
      const routes = screen.routes.filter(route => route.startsWith('/'));
      for (const route of routes.length ? routes : ['/app/inicio']) {
        const target = route.replace(/atencion=id/g, 'atencion=e-1').replace(/paciente=id/g, `paciente=${vet ? 'p-luna' : 'p-lucia'}`);
        const response = await page.goto(base + target, { waitUntil: 'domcontentloaded', timeout: 120000 });
        await page.locator('.boot-screen').waitFor({ state: 'hidden' });
        if (screen.id === 'S03') await page.getByRole('button', { name: /Clínica Aurora/ }).first().click();
        const blocked = await page.locator('.restricted-panel').count();
        const heading = await page.locator('h1,h2').first().innerText();
        const controls = await page.locator('[data-action]').evaluateAll(nodes => nodes.map(n => n.dataset.action));
        controls.forEach(id => reached.add(id));
        results.push({ screen: screen.id, route: target, role, http: response.status(), heading, blocked: Boolean(blocked), controls: [...new Set(controls)].length });
        if (response.status() !== 200 || blocked || !heading) throw new Error(`Pantalla ${screen.id}: ${response.status()} ${heading}, restricción=${blocked}`);
      }
      console.log(`${screen.id} ${screen.name}: revisada`);
    }
    const missing = spec.actions.map(a => a.id).filter(id => !reached.has(id));
    const report = { base, screens: spec.screens.length, visits: results.length, actionsInDOM: reached.size, missing, errors, results };
    mkdirSync('test-results', { recursive: true });
    writeFileSync('test-results/routes-qa.json', JSON.stringify(report, null, 2));
    console.log(JSON.stringify({ screens: report.screens, visits: report.visits, actionsInDOM: report.actionsInDOM, missing, errors }));
    if (errors.length || missing.length) throw new Error('Hay errores o acciones sin control en la revisión de rutas.');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
