'use client';
import { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { api, ApiError, setCsrf } from '@/lib/api';
import { isMockMode } from '@/lib/app-mode';
import { useDemo } from '@/store/demo';
export interface SessionUser { id: string; name: string; email: string; roles: string[]; tenantId?: string | null; }
export interface HostContext { platform: boolean; id?: string; name?: string; slug?: string; kind?: string; domain?: string; baseDomain?: string; hostname?: string; }
interface Session { user: SessionUser; csrfToken: string; expiresAt: string; }
interface AuthState { user: SessionUser | null; host: HostContext | null; loading: boolean; error: string; refresh: () => Promise<void>; login: (email: string, password: string) => Promise<SessionUser>; logout: () => Promise<void>; }
const Auth = createContext<AuthState | null>(null);
export function SessionProvider({ children }: { children: React.ReactNode }) {
  const mockContext = useDemo(s => isMockMode ? s.context : null);
  const [user, setUser] = useState<SessionUser | null>(null), [host, setHost] = useState<HostContext | null>(null), [loading, setLoading] = useState(true), [error, setError] = useState('');
  const refresh = useCallback(async () => {
    setLoading(true); setError('');
    try { setHost(await api<HostContext>('/public/context')); try { const session = await api<Session>('/auth/browser/session'); setCsrf(session.csrfToken); setUser(session.user); } catch (e) { if (!(e instanceof ApiError) || e.status !== 401) throw e; setUser(null); setCsrf(''); } }
    catch (e) { setError(e instanceof Error ? e.message : 'Servicio no disponible.'); } finally { setLoading(false); }
  }, []);
  useEffect(() => { void refresh(); const expire = () => { setUser(null); setCsrf(''); }; window.addEventListener('health:session-expired', expire); return () => window.removeEventListener('health:session-expired', expire); }, [refresh, mockContext]);
  async function login(email: string, password: string) { const session = await api<Session>('/auth/browser/login', { method: 'POST', body: { email, password } }); setCsrf(session.csrfToken); setUser(session.user); return session.user; }
  async function logout() { try { await api('/auth/browser/session', { method: 'DELETE' }); } finally { setUser(null); setCsrf(''); } }
  return <Auth.Provider value={{ user, host, loading, error, refresh, login, logout }}>{children}</Auth.Provider>;
}
export function useAuth() { const value = useContext(Auth); if (!value) throw new Error('SessionProvider is required'); return value; }
export function homeFor(user: SessionUser) { return user.roles.includes('SAD') || user.roles.includes('SOP') ? '/saas/inicio' : user.roles.some(role => ['PAC', 'RES'].includes(role)) ? '/portal/inicio' : '/app/inicio'; }
