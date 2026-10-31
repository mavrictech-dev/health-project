import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const plan = JSON.parse(readFileSync(resolve(root, '../docs/frontend-demo/Plan_Frontend.json'), 'utf8'));
const catalog = JSON.parse(readFileSync(resolve(root, '../docs/catalogs/Catalogo_Especialidades_Health_Project.json'), 'utf8'));
const design = JSON.parse(readFileSync(resolve(root, '../docs/diseno/Trazabilidad_Diseno.json'), 'utf8'));
mkdirSync(resolve(root, 'src/data'), { recursive: true });
const spec = {
  screens: plan.screenPlan.map(s => ({ id: s.id, name: s.name, area: s.area, roles: s.actors, routes: s.routes, feature: s.feature, contents: s.contents, flows: s.flows })),
  flows: plan.flowContracts.map(f => ({ id: f.flowId, name: f.name, resource: f.stateResource, fields: f.fieldNames, guard: f.domainGuard, end: f.expectedEnd, steps: design.flows.find(d => d.id === f.flowId).steps })),
  actions: plan.actionPlan.map(a => ({ id: a.id, label: a.label, flow: a.flowId, screens: a.screenIds, roles: a.demoRoles, pattern: a.interactionPattern, operation: a.mockOperation, resource: a.stateResource, effect: a.expectedVisibleResult })),
  actors: plan.actors.filter(a => !['SYS', 'EXT'].includes(a.id)),
  specialties: catalog.entries.map(e => ({ code: e.code, name: e.name, domain: e.catalogDomain, patientDomain: e.patientDomain, capture: e.capture, components: e.components, families: e.componentFamilies, group: e.group })),
  families: catalog.componentFamilies.map(f => ({ code: f.code, name: f.name })),
};
writeFileSync(resolve(root, 'src/data/spec.json'), JSON.stringify(spec));
const saasScreens = JSON.parse(readFileSync(resolve(root, 'src/data/saas-screens.json'), 'utf8'));
const routes = [...new Set([...spec.screens, ...saasScreens].flatMap(s => s.routes).filter(r => r.startsWith('/')).map(r => r.split('?')[0]))];
writeFileSync(resolve(root, 'src/data/routes.json'), JSON.stringify(routes));
console.log(`Spec: ${spec.screens.length} pantallas, ${spec.actions.length} acciones, ${spec.specialties.length} perfiles, ${routes.length} rutas`);
