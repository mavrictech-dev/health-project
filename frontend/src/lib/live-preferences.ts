export type VisualTheme = 'light' | 'dark' | 'navy';
export const LIVE_PREFERENCES_KEY = 'health-project-live-preferences-v1';
type StorageLike = Pick<Storage, 'getItem' | 'setItem'>;
export function readLiveTheme(storage: StorageLike): VisualTheme {
  try { const value = JSON.parse(storage.getItem(LIVE_PREFERENCES_KEY) || '{}').theme; return value === 'dark' || value === 'navy' ? value : 'light'; }
  catch { return 'light'; }
}
export function writeLiveTheme(storage: StorageLike, theme: VisualTheme) {
  try { storage.setItem(LIVE_PREFERENCES_KEY, JSON.stringify({ theme })); } catch { /* Theme still works for this page when storage is unavailable. */ }
}
