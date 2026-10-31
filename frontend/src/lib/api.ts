import { isMockMode } from './app-mode';

export class ApiError extends Error {
  constructor(message: string, public status: number, public requestId = '') { super(message); }
}
let csrfToken = '';
export function setCsrf(value: string) { csrfToken = value; }
export async function api<T = unknown>(path: string, options: { method?: string; body?: unknown; signal?: AbortSignal } = {}): Promise<T> {
  if (isMockMode) {
    options.signal?.throwIfAborted();
    const { mockApi } = await import('@/mocks/runtime-api');
    options.signal?.throwIfAborted();
    try { return structuredClone(await mockApi(path, options)) as T; }
    catch (error) {
      if (error instanceof Error && error.name === 'AbortError') throw error;
      throw new ApiError(error instanceof Error ? error.message : 'No se pudo completar la simulación.', Number((error as { status?: number })?.status || 400), 'demo-local');
    }
  }
  const response = await fetch(`/api${path}`, {
    method: options.method || 'GET', credentials: 'same-origin', cache: 'no-store', signal: options.signal,
    headers: { 'Content-Type': 'application/json', ...(csrfToken ? { 'X-CSRF-Token': csrfToken } : {}) },
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });
  const text = await response.text();
  let data: Record<string, unknown> = {};
  try { if (text) data = JSON.parse(text); } catch { throw new ApiError('No se pudo comunicar con la API. Abre Health Project desde el gateway Docker.', response.status); }
  if (!response.ok) {
    if (response.status === 401 && !path.includes('/login')) window.dispatchEvent(new Event('health:session-expired'));
    throw new ApiError(String(data.detail || 'No se pudo completar la solicitud.'), response.status, String(data.requestId || response.headers.get('X-Request-Id') || ''));
  }
  return data as T;
}
export function csvDownload(rows: Record<string, unknown>[], filename: string) {
  const keys = [...new Set(rows.flatMap(row => Object.keys(row)))];
  const cell = (v: unknown) => { let value = v == null ? '' : typeof v === 'object' ? JSON.stringify(v) : String(v); if (/^\s*[=+@\-]|^[\t\r]/.test(value)) value = `'${value}`; return `"${value.replaceAll('"', '""')}"`; };
  const blob = new Blob(['\uFEFF' + [keys.map(cell).join(','), ...rows.map(row => keys.map(key => cell(row[key])).join(','))].join('\r\n')], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob); const a = document.createElement('a'); a.href = url; a.download = filename; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
}
