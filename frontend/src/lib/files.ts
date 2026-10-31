import type { DemoData, DocumentItem } from './types';
const cachedFiles = new Map<string, File>();
export const cacheFile = (id: string, file: File) => cachedFiles.set(id, file);
export const getFile = (id: string) => cachedFiles.get(id);
export const clearFiles = () => { cachedFiles.clear(); importPreview = null; };
export function downloadBlob(name: string, content: Blob | string, type = 'text/plain;charset=utf-8') {
  const blob = typeof content === 'string' ? new Blob([content], { type }) : content;
  const url = URL.createObjectURL(blob); const anchor = document.createElement('a'); anchor.href = url; anchor.download = name; anchor.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
}
const escape = (value: string) => value.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
export function documentHtml(doc: DocumentItem, data: DemoData) {
  const patient = data.patients.find(p => p.id === doc.patient);
  return `<!doctype html><html lang="es"><meta charset="utf-8"><title>${escape(doc.title)}</title><style>body{font:14px system-ui;max-width:760px;margin:60px auto;color:#202731;padding:25px}h1{font-size:26px}pre{white-space:pre-wrap;font:14px/1.8 system-ui}footer{margin-top:50px;border-top:1px solid #ddd;padding-top:15px;color:#64748b;font-size:11px}</style><h3>Health Project · Documento de demostración</h3><h1>${escape(doc.title)}</h1><p>${escape(patient?.name || '')} · ${escape(doc.date)} · Versión ${doc.version}</p><pre>${escape(doc.content)}</pre><footer>${escape(doc.status)} · ${escape(doc.signed || 'Sin firma')}<br>Material ficticio preparado para presentación.</footer></html>`;
}
export function csvText(rows: Record<string, unknown>[]) { if (!rows.length) return 'sin_registros\n'; const keys = [...new Set(rows.flatMap(row => Object.keys(row)))]; const cell = (v: unknown) => '"' + String(v ?? '').replaceAll('"', '""') + '"'; return '\uFEFF' + [keys.map(cell).join(','), ...rows.map(row => keys.map(key => cell(row[key])).join(','))].join('\r\n'); }
export interface ImportPreview { name: string; schema: string; rows: Record<string, string>[]; errors: string[]; hash: string; }
let importPreview: ImportPreview | null = null;
export const getImport = () => importPreview;
export function parseCsv(content: string): Record<string, string>[] {
  const matrix: string[][] = []; let row: string[] = []; let cell = ''; let quoted = false;
  const cleaned = content.replace(/^\uFEFF/, '');
  for (let i = 0; i < cleaned.length; i++) { const c = cleaned[i]; if (c === '"') { if (quoted && cleaned[i + 1] === '"') { cell += '"'; i++; } else quoted = !quoted; } else if (c === ',' && !quoted) { row.push(cell); cell = ''; } else if (c === '\n' && !quoted) { row.push(cell.replace(/\r$/, '')); if (row.some(Boolean)) matrix.push(row); row = []; cell = ''; } else cell += c; }
  if (quoted) throw new Error('El CSV contiene comillas sin cerrar.');
  if (cell || row.length) { row.push(cell.replace(/\r$/, '')); matrix.push(row); }
  const headers = matrix.shift()?.map(h => h.trim()) || [];
  if (!headers.length) throw new Error('El archivo está vacío.');
  return matrix.map(values => Object.fromEntries(headers.map((h, i) => [h, values[i] || ''])));
}
export async function prepareImport(file: File, schema: string) {
  if (file.size > 5 * 1024 * 1024) throw new Error('El ejemplo debe pesar menos de 5 MB.');
  const content = await file.text(); const raw = file.name.endsWith('.json') ? JSON.parse(content) : parseCsv(content);
  if (!Array.isArray(raw) || raw.some(r => !r || typeof r !== 'object' || Array.isArray(r))) throw new Error('Usa una lista de registros en JSON o un CSV con cabecera.');
  const errors: string[] = []; const rows = raw.map(r => Object.fromEntries(Object.entries(r).map(([k, v]) => [k, String(v ?? '')])));
  rows.forEach((row, i) => { if (schema === 'Pacientes' && !(row.nombre || row.name)) errors.push(`Fila ${i + 1}: falta nombre.`); if (schema === 'Inventario' && (!(row.nombre || row.name) || !Number.isFinite(Number(row.cantidad)) || Number(row.cantidad) < 0)) errors.push(`Fila ${i + 1}: nombre o cantidad inválidos.`); if (schema === 'Citas' && (!row.paciente || !row.fecha || !row.hora)) errors.push(`Fila ${i + 1}: faltan paciente, fecha u hora.`); });
  let hash = 0; for (const c of content) hash = ((hash << 5) - hash + c.charCodeAt(0)) | 0;
  importPreview = { name: file.name, schema, rows, errors, hash: String(hash) }; return importPreview;
}
