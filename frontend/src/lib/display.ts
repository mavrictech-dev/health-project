import { anatomyAtlases } from '@/data/anatomy-atlases';
import { getSaas } from './saas';
import { getOrganizations } from '@/mocks/fixtures';
import type { DemoData } from './types';
export function structureLabel(value: string) {
  const [atlas, region] = value.split(':');
  if (/^\d+$/.test(value)) return `Pieza ${value}`;
  if (anatomyAtlases[atlas]?.regions.some(r => r.id === region)) return anatomyAtlases[atlas].regions.find(r => r.id === region)!.label;
  if (/^\d+$/.test(atlas)) return `Pieza ${atlas} · ${region?.replaceAll('-', ' ') || ''}`;
  return value.replaceAll(':', ' · ').replaceAll('-', ' ');
}
export function displayValue(value: string | number | boolean, data: DemoData) {
  if (typeof value === 'boolean') return value ? 'Sí' : 'No';
  if (typeof value === 'number') return String(value);
  return data.patients.find(p => p.id === value)?.name || getSaas(data).professionals.find(p => p.id === value)?.name || getOrganizations(data).find(o => o.id === value)?.name || getOrganizations(data).flatMap(o => o.branches).find(b => b.id === value)?.name || data.documents.find(d => d.id === value)?.title || data.stock.find(s => s.id === value)?.name || data.beds.find(b => b.id === value)?.name || data.records.find(r => r.id === value)?.title || data.jobs.find(j => j.id === value)?.label || data.movements.find(m => m.id === value)?.title || value;
}
