import data from '@/data/spec.json';
import saasScreens from '@/data/saas-screens.json';
import type { ActionSpec, ScreenSpec } from './types';
export const screens = [...data.screens, ...saasScreens] as ScreenSpec[];
export const actions = data.actions as ActionSpec[];
export const flows = data.flows;
export const specialties = data.specialties;
export const families = data.families;
export const actors = [...data.actors, { id: 'SAD', name: 'Administrador general SaaS', scope: 'Clientes, planes y suscripciones de la plataforma.' }];
export const actionById = Object.fromEntries(actions.map(a => [a.id, a]));
export const flowById = Object.fromEntries(flows.map(f => [f.id, f]));
export function getScreen(path: string, query = ''): ScreenSpec {
  const params = new URLSearchParams(query);
  if (path === '/' || path === '/app/inicio') return screens.find(s => s.id === 'S17')!;
  if (path === '/app/pacientes' && params.has('paciente')) return screens.find(s => s.id === (params.get('tab') === 'historia' ? 'S19' : params.get('tab') === 'vinculos' ? 'S32' : params.get('dominio') === 'animal' ? 'S11' : 'S10'))!;
  if (path === '/app/atencion' && params.get('tab') === 'medicacion') return screens.find(s => s.id === 'S25')!;
  return screens.find(s => s.routes.some(r => r.split('?')[0] === path)) || screens.find(s => s.id === 'S17')!;
}
