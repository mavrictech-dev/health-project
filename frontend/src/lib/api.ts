import { isMockMode } from './app-mode';

export class ApiError extends Error {
  constructor(message: string, public status: number, public requestId = '') { super(message); }
}
export function isAbort(error: unknown) { return error instanceof Error && error.name === 'AbortError'; }
export function errorMessage(error: unknown) {
  const message = error instanceof Error ? error.message : 'No se pudo completar la solicitud.';
  const reference = error instanceof ApiError ? error.requestId.replace(/[^a-zA-Z0-9_.:-]/g, '').slice(0, 100) : '';
  return message + (reference ? ` Referencia: ${reference}` : '');
}
let csrfToken = '';
let csrfRevision = 0;
export function setCsrf(value: string) { csrfToken = value; csrfRevision++; }
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
  options.signal?.throwIfAborted();
  const requestRevision = csrfRevision;
  const method = (options.method || 'GET').toUpperCase();
  let response: Response;
  try {
    response = await fetch(`/api${path}`, {
      method, credentials: 'same-origin', cache: 'no-store', signal: options.signal,
      headers: { 'Content-Type': 'application/json', ...(csrfToken && !['GET','HEAD','OPTIONS'].includes(method) ? { 'X-CSRF-Token': csrfToken } : {}) },
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
    });
  } catch (error) {
    if (isAbort(error) || options.signal?.aborted) throw error;
    throw new ApiError('No se pudo conectar con el servicio. Comprueba la conexión y vuelve a intentarlo.', 0);
  }
  options.signal?.throwIfAborted();
  const expireIfCurrent = () => {
    if (response.status !== 401 || requestRevision !== csrfRevision || options.signal?.aborted) return;
    setCsrf('');
    if (!path.includes('/login') && path !== '/auth/browser/session' && typeof window !== 'undefined') window.dispatchEvent(new CustomEvent('health:session-expired',{detail:{requestId:response.headers.get('X-Request-Id')||''}}));
  };
  let text: string;
  try { text = await response.text(); }
  catch(error) {
    if(isAbort(error)||options.signal?.aborted)throw error;
    expireIfCurrent();
    throw new ApiError('Se interrumpió la respuesta del servicio. Vuelve a intentarlo.',response.status===401?401:0,response.headers.get('X-Request-Id')||'');
  }
  options.signal?.throwIfAborted();
  expireIfCurrent();
  let data: Record<string, unknown> = {};
  try { if (text) data = JSON.parse(text) ?? {}; } catch { throw new ApiError('El servicio devolvió una respuesta no válida. Vuelve a intentarlo desde el gateway.', response.status, response.headers.get('X-Request-Id') || ''); }
  if (!response.ok) {
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
