const { chromium } = require(process.env.HEALTH_PLAYWRIGHT_MODULE || 'playwright');
const { readFileSync, mkdirSync, writeFileSync } = require('node:fs');
const { profiles } = JSON.parse(readFileSync('src/data/specialty-profiles.json', 'utf8'));
const spec = JSON.parse(readFileSync('src/data/spec.json', 'utf8'));
const base = process.env.HEALTH_PREVIEW_URL || 'http://127.0.0.1:3000';
(async () => {
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1050 }, reducedMotion: 'reduce' });
  const page = await context.newPage(); page.setDefaultTimeout(60000); const errors = []; const reviewed = []; const families = new Set();
  page.on('pageerror', error => errors.push(error.message));
  try {
    await page.goto(base, { waitUntil: 'domcontentloaded', timeout: 120000 });
    await page.getByRole('heading', { name: 'Buen día, Dr. Mateo' }).waitFor();
    await page.getByRole('button', { name: 'Tema blanco', exact: true }).click();
    const baseline = await page.evaluate(() => JSON.parse(localStorage.getItem('health-project-demo-v1')));
    for (const domain of ['HUMAN', 'ANIMAL']) {
      const state = structuredClone(baseline); const vet = domain === 'ANIMAL';
      // Broad QA fixture: activate all compatible profiles without changing user demo data.
      const tenant = state.state.data.saas.tenants.find(t => t.id === (vet ? 'org-vet' : 'org-human'));
      tenant.specialties = profiles.filter(p => p.patientDomain === domain).map(p => p.code);
      tenant.subscription.specialtyQuota = tenant.specialties.length;
      state.state.data.saas.memberships.filter(m => m.tenantId === tenant.id).forEach(m => { m.specialties = [...tenant.specialties]; });
      state.state.context = { ...state.state.context, role: 'PRO', org: vet ? 'org-vet' : 'org-human', branch: vet ? 'vet-centro' : 'miraflores', patient: vet ? 'p-luna' : 'p-lucia', encounter: vet ? 'e-vet' : 'e-1', specialty: vet ? 'V_GENERAL' : 'H_GENERAL_MEDICINE' };
      await page.evaluate(value => localStorage.setItem('health-project-demo-v1', JSON.stringify(value)), state);
      await page.goto(base + '/app/atencion/', { waitUntil: 'domcontentloaded', timeout: 120000 });
      await page.getByRole('heading', { name: 'Un espacio para cuidar' }).waitFor();
      for (const profile of profiles.filter(p => p.patientDomain === domain)) {
        await page.getByLabel('Especialidad de la atención').selectOption(profile.code);
        await page.getByRole('tab', { name: 'Evaluación', exact: true }).click();
        await page.getByRole('heading', { name: `Evaluación de ${profile.name}`, exact: true }).waitFor();
        const fields = await page.locator('[id^="capture-"]').count();
        if (fields < profile.fields.length) throw new Error(`${profile.code}: campos ${fields}/${profile.fields.length}`);
        await page.getByRole('tab', { name: 'Gráficos', exact: true }).click();
        const options = await page.locator('#graphic-family option').evaluateAll(nodes => nodes.map(n => n.value));
        for (const family of options) {
          if (families.has(family)) continue;
          await page.locator('#graphic-family').selectOption(family);
          await page.locator('.graph-panel').waitFor();
          if (!(await page.locator('.graph-panel').innerText()).trim()) throw new Error(`Familia vacía: ${family}`);
          families.add(family);
        }
        reviewed.push({ profile: profile.code, fields, families: options });
      }
      console.log(`${domain}: perfiles y gráficos revisados`);
    }
    // Feline Triadan and mixed human dentition keep separate selectable structures.
    await page.getByLabel('Paciente de la atención').selectOption('p-milo');
    await page.getByLabel('Especialidad de la atención').selectOption(profiles.find(p => p.patientDomain === 'ANIMAL' && p.componentFamilies.includes('VET_DENTAL')).code);
    await page.getByRole('tab', { name: 'Gráficos', exact: true }).click();
    await page.locator('#graphic-family').selectOption('VET_DENTAL');
    const felineTeeth = await page.locator('.tooth-button').evaluateAll(nodes => nodes.map(n => n.textContent.trim()));
    if (felineTeeth.length !== 30 || felineTeeth.includes('105') || !felineTeeth.includes('109') || !felineTeeth.includes('309')) throw new Error('Numeración felina inesperada.');
    // Unsaved input survives the exit review; Ctrl+K cannot replace an open form.
    const human = structuredClone(baseline);
    await page.evaluate(value => localStorage.setItem('health-project-demo-v1', JSON.stringify(value)), human);
    await page.goto(base, { waitUntil: 'domcontentloaded', timeout: 120000 });
    await page.getByRole('button', { name: 'Nueva cita', exact: true }).click();
    const reason = page.getByLabel('Motivo', { exact: true });
    await reason.fill('Texto ficticio conservado para la revisión');
    await page.keyboard.press('Control+k');
    await page.getByRole('heading', { name: 'Nueva cita', exact: true }).waitFor();
    await page.getByRole('button', { name: 'Cerrar panel', exact: true }).click();
    await page.getByRole('heading', { name: 'Hay cambios sin guardar' }).waitFor();
    await page.getByRole('button', { name: 'Seguir editando', exact: true }).click();
    if ((await reason.inputValue()) !== 'Texto ficticio conservado para la revisión') throw new Error('Se perdió la captura al volver a editar.');
    await page.getByRole('button', { name: 'Cerrar panel', exact: true }).click();
    await page.getByRole('button', { name: 'Descartar y cerrar', exact: true }).click();
    await page.locator('.account-button').click();
    await page.locator('.role-option').filter({ has: page.getByText('PAC', { exact: true }) }).click();
    await page.waitForURL(/portal\/inicio/);
    await page.locator('.portal-welcome').waitFor();
    await page.locator('.global-search').click();
    const portalPatients = await page.locator('.search-result:has(.person-avatar) strong').allTextContents();
    if (!portalPatients.length || portalPatients.some(name => !['Lucía Fernández', 'Nicolás Castro'].includes(name))) throw new Error('El portal mostró pacientes sin vínculo en su búsqueda.');
    await page.getByRole('button', { name: 'Cerrar panel', exact: true }).click();
    await page.goto(base + '/portal/inicio/?paciente=p-diego', { waitUntil: 'domcontentloaded', timeout: 120000 });
    await page.locator('.portal-welcome').waitFor();
    const portalPatient = await page.evaluate(() => JSON.parse(localStorage.getItem('health-project-demo-v1')).state.context.patient);
    if (portalPatient === 'p-diego') throw new Error('El portal aceptó un paciente sin vínculo desde la URL.');
    await page.locator('.account-button').click();
    await page.locator('.role-option').filter({ has: page.getByText('SOP', { exact: true }) }).click();
    await page.waitForURL(/operacion\/inicio/);
    await page.locator('.global-search').click();
    const supportPatients = await page.locator('.search-result:has(.person-avatar)').count();
    if (supportPatients !== 0) throw new Error('La búsqueda del operador mostró pacientes clínicos.');
    const missing = spec.families.map(f => f.code).filter(f => !families.has(f));
    const report = { base, profiles: reviewed.length, families: families.size, missing, felineTeeth, unsavedCapturePreserved: true, portalPatients, portalPatient, supportPatients, errors, reviewed };
    mkdirSync('test-results', { recursive: true });
    writeFileSync('test-results/specialties-qa.json', JSON.stringify(report, null, 2));
    console.log(JSON.stringify({ profiles: reviewed.length, families: families.size, missing, felineTeeth: felineTeeth.length, unsavedCapturePreserved: true, portalPatients, portalPatient, supportPatients, errors }));
    if (errors.length || missing.length || reviewed.length !== 241) throw new Error('La revisión de especialidades no está completa.');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
