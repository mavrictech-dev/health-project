const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

(async () => {
  const base = 'D:/Mavric/Health Project/docs/diseno';
  const diagrams = fs.readdirSync(path.join(base,'diagramas')).filter(name => name.endsWith('.mmd')).map(name => ({name,source:fs.readFileSync(path.join(base,'diagramas',name),'utf8')}));
  const browser = await chromium.launch({headless:true,channel:'msedge'});
  try {
    const page = await browser.newPage({viewport:{width:1200,height:900}});
    await page.setContent('<!doctype html><html lang="es"><head><meta charset="utf-8"></head><body><div id="diagram"></div></body></html>');
    await page.addScriptTag({url:'https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.min.js'});
    await page.evaluate(() => mermaid.initialize({startOnLoad:false,securityLevel:'strict',flowchart:{htmlLabels:false}}));
    const errors=[];
    for (const d of diagrams) {
      const result = await page.evaluate(async ({source}) => {try { await mermaid.parse(source); return {ok:true}; } catch(error) { return {ok:false,message:String(error)}; }},d);
      if (!result.ok) errors.push({diagram:d.name,message:result.message});
    }
    if (errors.length) throw new Error(JSON.stringify(errors));
    for (const name of ['F21.mmd','F24.mmd','F79.mmd','ESTADOS_02.mmd']) {
      const d=diagrams.find(item => item.name===name);
      const render=await page.evaluate(async ({source}) => {const result=await mermaid.render('review_graph',source);document.getElementById('diagram').innerHTML=result.svg; const svg=document.querySelector('#diagram svg');return {viewBox:svg.getAttribute('viewBox')};},d);
      await page.locator('#diagram').screenshot({path:path.join(base,'diagramas',name.replace('.mmd','-preview.png'))});
      console.log(JSON.stringify({preview:name,...render}));
    }
    console.log(JSON.stringify({validatedDiagrams:diagrams.length,parser:'Mermaid 11.4.1',errors}));
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1;});
