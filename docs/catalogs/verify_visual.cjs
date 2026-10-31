const fs = require('node:fs');
const { pathToFileURL } = require('node:url');
const { chromium } = require('playwright');

(async () => {
  const rootPath = 'C:/Users/maxmo/.codex/visualizations/2026/10/13/01a133e5-78cf-7462-ae45-f175e87523bd';
  const browser = await chromium.launch({headless: true,channel:'msedge'});
  const page = await browser.newPage({viewport: {width: 736, height: 1000}});
  const errors = [];
  page.on('pageerror', err => errors.push(err.message));
  await page.goto(pathToFileURL(rootPath + '/especialidades-preview.html').href);
  const frame = page.frameLocator('iframe');
  await frame.locator('#hp-map-name').waitFor();
  const selection = frame.locator('#hp-map-specialty');
  const options = await selection.locator('option').count();
  if (options !== 241) throw new Error('Conteo inesperado: ' + options);
  await selection.selectOption('V_CARDIO');
  if ((await frame.locator('#hp-map-name').innerText()) !== 'Cardiología veterinaria') throw new Error('No cambió la selección');
  await selection.selectOption('H_CARDIOLOGY');
  await frame.locator('#hp-specialty-map').evaluate(async () => { await document.fonts.ready; await new Promise(requestAnimationFrame); });
  await frame.locator('#hp-specialty-map').screenshot({path: rootPath + '/especialidades-preview-desktop.png'});
  for (const width of [736, 360]) {
    await page.setViewportSize({width,height:1000});
    const overflow = await frame.locator('#hp-specialty-map').evaluate(el => ({client:el.clientWidth,scroll:el.scrollWidth}));
    if (overflow.scroll > overflow.client + 2) throw new Error('Desborde a ' + width + ': ' + JSON.stringify(overflow));
  }
  await selection.selectOption('V_DENTAL');
  await frame.locator('#hp-specialty-map').evaluate(async () => { await document.fonts.ready; await new Promise(requestAnimationFrame); });
  await frame.locator('#hp-specialty-map').screenshot({path: rootPath + '/especialidades-preview-mobile.png'});
  const rect=await frame.locator('#hp-specialty-map').boundingBox();
  if (errors.length) throw new Error(errors.join('; '));
  console.log(JSON.stringify({options, selectionsChecked:['V_CARDIO','H_CARDIOLOGY','V_DENTAL'],widthsChecked:[736,360],rect,errors}));
  await browser.close();
})().catch(err => {console.error(err);process.exitCode=1;});
