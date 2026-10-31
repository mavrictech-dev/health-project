const { chromium } = require('playwright');
const { mkdirSync, writeFileSync } = require('node:fs');
const base = process.env.HEALTH_PREVIEW_URL || 'http://127.0.0.1:3000';
(async () => {
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1050 }, reducedMotion: 'reduce' });
  const page = await context.newPage(); page.setDefaultTimeout(45000);
  const errors = []; const results = []; page.on('pageerror', e => errors.push(e.message));
  mkdirSync('test-results', { recursive: true });
  const select = async (id, name) => { await page.locator(`#saas-${id}`).click(); await page.getByRole('option', { name, exact: true }).click(); };
  const submit = async () => { await page.getByRole('button', { name: 'Revisar configuración', exact: true }).click(); await page.getByRole('heading', { name: 'Revisa la configuración' }).waitFor(); await page.getByRole('button', { name: 'Confirmar configuración', exact: true }).click(); await page.getByRole('heading', { name: 'Configuración lista' }).waitFor(); };
  const close = async () => { await page.getByRole('button', { name: 'Volver a la pantalla', exact: true }).click(); await page.locator('[data-slot="sheet-content"]').waitFor({ state: 'hidden' }); };
  const data = () => page.evaluate(() => JSON.parse(localStorage.getItem('health-project-demo-v1')).state.data);
  try {
    await page.goto(base, { waitUntil: 'domcontentloaded', timeout: 120000 });
    await page.locator('.boot-screen').waitFor({ state: 'hidden' });
    await page.getByRole('button', { name: /Administración SaaS/ }).click();
    await page.getByRole('heading', { name: 'Una plataforma, muchos espacios' }).waitFor();
    await page.screenshot({ path: 'test-results/saas-home-light.png' });
    for (const theme of ['negro', 'navy']) { await page.getByRole('button', { name: `Tema ${theme}`, exact: true }).click(); await page.screenshot({ path: `test-results/saas-home-${theme}.png` }); }
    await page.getByRole('button', { name: 'Tema blanco', exact: true }).click();
    // Edit a published plan; accepted contracts retain their version and rate.
    await page.goto(base + '/saas/planes', { waitUntil: 'domcontentloaded' });
    const oldContract = (await data()).saas.tenants.find(t => t.id === 'org-human').subscription;
    await page.locator('.saas-plan-card').filter({ has: page.getByRole('heading', { name: 'Hospital', exact: true }) }).getByRole('button', { name: 'Configurar', exact: true }).click();
    await page.locator('#saas-basePrice').fill('999'); await submit(); await close();
    const editedState = await data();
    if (JSON.stringify(editedState.saas.tenants.find(t => t.id === 'org-human').subscription) !== JSON.stringify(oldContract)) throw new Error('La edición del catálogo alteró un contrato aceptado');
    await page.getByRole('button', { name: 'Crear plan', exact: true }).click(); await page.locator('#saas-name').fill('Red Clínica'); await submit(); await close();
    await page.screenshot({ path: 'test-results/saas-plans.png' });
    results.push({ flow: 'plan-create-edit-contract-snapshot' });
    await page.goto(base + '/saas/clientes?tenant=org-vet', { waitUntil: 'domcontentloaded' });
    await page.getByRole('tab', { name: 'Suscripción', exact: true }).click();
    await page.getByRole('button', { name: 'Registrar pago demo', exact: true }).click(); await submit(); await close();
    if ((await data()).saas.invoices.find(i => i.id === 'invoice-org-vet').status !== 'Pagado') throw new Error('Pago SaaS no reflejado');
    results.push({ flow: 'subscription-mock-payment' });
    await page.goto(base + '/saas/inicio', { waitUntil: 'domcontentloaded' });
    const created = [];
    for (const entry of [
      { name: 'Consultorio Ana', slug: 'consulta-ana-ui', owner: 'Dra. Ana Lima', kind: 'Profesional independiente', specialty: 'H_CARDIOLOGY', search: 'Cardiología' },
      { name: 'Veterinaria Brisa', slug: 'vet-brisa-ui', owner: 'Dra. Julia Sol', kind: 'Centro veterinario', specialty: 'V_GENERAL', search: '' },
      { name: 'Cardiolife', slug: 'cardiolife-ui', owner: 'María Pérez', kind: 'Centro de especialidad', specialty: 'H_CARDIOLOGY', search: 'Cardiología' },
    ]) {
      await page.getByRole('button', { name: 'Crear cliente / tenant', exact: true }).click();
      await page.locator('#saas-name').fill(entry.name); await page.locator('#saas-slug').fill(entry.slug);
      await select('kind', entry.kind); await page.locator('#saas-ownerName').fill(entry.owner); await page.locator('#saas-ownerEmail').fill(entry.slug + '@example.test');
      await page.getByRole('button', { name: 'Continuar', exact: true }).click();
      await page.locator('#saas-planId').waitFor();
      await page.getByRole('button', { name: 'Continuar', exact: true }).click();
      for (const checked of await page.locator('[data-specialty][aria-checked="true"]').all()) await checked.click();
      await page.getByLabel('Buscar especialidades disponibles').fill(entry.search);
      await page.locator(`[data-specialty="${entry.specialty}"]`).click();
      if (created.length === 0) {
        await page.screenshot({ path: 'test-results/saas-create-tenant.png' });
        const blur = await page.locator('[data-slot="sheet-overlay"]').evaluate(el => getComputedStyle(el).backdropFilter);
        if (blur !== 'blur(8px)') throw new Error('Panel sin desenfoque');
      }
      await submit(); await page.getByRole('button', { name: 'Ver cliente', exact: true }).click();
      await page.getByRole('heading', { name: entry.name, exact: true }).waitFor();
      const state = await data(); const tenant = state.saas.tenants.find(t => t.slug === entry.slug);
      if (!tenant || tenant.specialties[0] !== entry.specialty || state.patients.some(p => p.org === tenant.id)) throw new Error('Tenant o aislamiento inválido');
      created.push(tenant.id); results.push({ flow: 'create', kind: tenant.kind, plan: tenant.subscription.planId, tenant: tenant.id });
      await page.goto(base + '/saas/inicio', { waitUntil: 'domcontentloaded' });
      await page.getByRole('heading', { name: 'Una plataforma, muchos espacios' }).waitFor();
    }
    // Existing professional joins the specialty center with its own membership.
    await page.goto(base + '/saas/clientes?tenant=' + created[2], { waitUntil: 'domcontentloaded' });
    await page.getByRole('tab', { name: 'Profesionales', exact: true }).click();
    await page.getByRole('button', { name: 'Añadir profesional', exact: true }).click();
    await select('professionalId', 'Dr. Andrés Ríos'); await submit(); await close();
    await page.getByText('Dr. Andrés Ríos', { exact: true }).waitFor();
    const membershipState = await data();
    if (membershipState.saas.memberships.filter(m => m.professionalId === 'pro-andres').length !== 2) throw new Error('Identidad duplicada o membresía ausente');
    await page.getByRole('button', { name: 'Estado: Prueba', exact: true }).click(); await select('status', 'Suspendido'); await submit(); await close();
    await page.getByRole('button', { name: 'Estado: Suspendido', exact: true }).click(); await select('status', 'Activo'); await submit(); await close();
    results.push({ flow: 'suspend-and-reactivate-client', tenant: created[2] });
    // Contract limit, upgrade, a new branch, and a specialty area.
    await page.goto(base + '/saas/clientes?tenant=' + created[1], { waitUntil: 'domcontentloaded' });
    await page.getByRole('tab', { name: 'Sedes y áreas', exact: true }).click();
    await page.getByRole('button', { name: 'Añadir sede', exact: true }).click(); await page.locator('#saas-branchName').fill('Sede Norte');
    await page.getByRole('button', { name: 'Revisar configuración', exact: true }).click();
    await page.getByRole('alert').filter({ hasText: /sedes/ }).waitFor();
    if (await page.locator('#saas-branchName').inputValue() !== 'Sede Norte') throw new Error('Se perdió el formulario al superar la cuota');
    await page.getByRole('button', { name: 'Cerrar panel', exact: true }).click(); await page.getByRole('button', { name: 'Descartar y cerrar', exact: true }).click();
    await page.getByRole('tab', { name: 'Suscripción', exact: true }).click();
    await page.getByRole('button', { name: 'Modificar suscripción', exact: true }).click(); await page.locator('#saas-branchQuota').fill('2'); await submit(); await close();
    await page.getByRole('tab', { name: 'Sedes y áreas', exact: true }).click();
    await page.getByRole('button', { name: 'Añadir sede', exact: true }).click(); await page.locator('#saas-branchName').fill('Sede Norte'); await submit(); await close();
    const branchCard = page.locator('.saas-branch-card').filter({ has: page.getByRole('heading', { name: 'Sede Norte', exact: true }) });
    await branchCard.getByRole('button', { name: 'Crear área', exact: true }).click(); await page.locator('#saas-areaName').fill('Consulta general veterinaria'); await submit(); await close();
    await page.screenshot({ path: 'test-results/saas-branches-areas.png' });
    const branchState = await data(); const branch = branchState.organizations.find(o => o.id === created[1]).branches.find(b => b.name === 'Sede Norte');
    if (!branchState.saas.areas.some(a => a.branchId === branch.id && a.name === 'Consulta general veterinaria')) throw new Error('Área creada en la sede incorrecta');
    results.push({ flow: 'quota-upgrade-branch-area', tenant: created[1], branch: branch.id });
    // Open the created client's workspace; only its assigned professional appears.
    await page.goto(base + '/saas/clientes?tenant=' + created[2], { waitUntil: 'domcontentloaded' });
    await page.getByRole('button', { name: 'Abrir espacio demo', exact: true }).click();
    await page.locator('.saas-tenant-bar').filter({ hasText: 'Centro de especialidad' }).waitFor();
    await page.getByRole('button', { name: /Espacio de demostración/ }).click();
    await page.locator('.role-option').filter({ has: page.getByText('PRO', { exact: true }) }).click();
    await page.getByRole('link', { name: 'Agenda', exact: true }).click();
    await page.locator('.calendar-professional').waitFor();
    if (await page.locator('.calendar-professional').count() !== 1 || !(await page.locator('.calendar-professional').innerText()).includes('Andrés')) throw new Error('Agenda no respeta membresías');
    await page.goto(base + '/app/pacientes', { waitUntil: 'domcontentloaded' });
    if (await page.locator('.table-person').count()) throw new Error('Pacientes de otro cliente visibles');
    await page.reload({ waitUntil: 'domcontentloaded' });
    if (!(await data()).saas.tenants.some(t => t.id === created[2])) throw new Error('Se perdió la persistencia');
    results.push({ flow: 'open-client-isolated-agenda-persistence', tenant: created[2] });
    await page.getByRole('button', { name: /Administración SaaS/ }).click();
    await page.setViewportSize({ width: 390, height: 844 });
    for (const theme of ['blanco', 'negro', 'navy']) {
      await page.getByRole('button', { name: `Tema ${theme}`, exact: true }).click();
      const overflow = await page.evaluate(() => document.documentElement.scrollWidth > innerWidth);
      if (overflow) throw new Error(`Overflow móvil en ${theme}`);
    }
    await page.screenshot({ path: 'test-results/saas-mobile.png', fullPage: true });
    if (errors.length) throw new Error(errors.join('\n'));
    writeFileSync('test-results/saas-qa.json', JSON.stringify({ results, errors, mobile: '390px / 3 temas', blur: '8px' }, null, 2));
    console.log(JSON.stringify({ flows: results.length, createdTenants: created.length, errors, mobile: 'passed' }));
  } catch (error) { await page.screenshot({ path: 'test-results/saas-failure.png', fullPage: true }); throw error; }
  finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
