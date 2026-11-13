'use client';
import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { api, ApiError, errorMessage, isAbort, setCsrf } from '@/lib/api';
import { isMockMode } from '@/lib/app-mode';
import { liveBase, sessionMatchesHost } from '@/lib/live-routes';
import { useDemo } from '@/store/demo';
export interface SessionUser { id: string; name: string; email: string; roles: string[]; tenantId?: string | null; requiresBranchSelection?: boolean; }
export interface HostContext { platform: boolean; id?: string; name?: string; slug?: string; kind?: string; domain?: string; baseDomain?: string; hostname?: string; ruc?:string; }
interface Session { user: SessionUser; csrfToken: string; expiresAt: string; branchId?:string|null; }
export interface LoginBranch {id:string;name:string;address?:string;}
interface AuthState { user: SessionUser | null; host: HostContext | null; loading: boolean; error: string; refresh: () => Promise<void>; login: (email: string, password: string,ruc?:string) => Promise<SessionUser>; logout: () => Promise<boolean>; logoutError: string; loggingOut: boolean; branchId:string|null; branches:LoginBranch[]; selectBranch:(id:string)=>Promise<void>; }
const Auth = createContext<AuthState | null>(null);
export function SessionProvider({ children }: { children: React.ReactNode }) {
  return isMockMode ? <MockSessionBridge>{children}</MockSessionBridge> : <SessionState>{children}</SessionState>;
}
function MockSessionBridge({ children }: { children: React.ReactNode }) {
  const context = useDemo(s => s.context);
  return <SessionState mockContext={context}>{children}</SessionState>;
}
function SessionState({ children, mockContext }: { children: React.ReactNode; mockContext?: unknown }) {
  const [state,setState]=useState<{user:SessionUser|null;host:HostContext|null;loading:boolean;error:string}>({user:null,host:null,loading:true,error:''});
  const [logoutError,setLogoutError]=useState(''),[loggingOut,setLoggingOut]=useState(false);
  const [branchId,setBranchId]=useState<string|null>(null),[branches,setBranches]=useState<LoginBranch[]>([]);
  const generation=useRef(0),controller=useRef<AbortController|null>(null);
  const refresh=useCallback(async()=>{
    controller.current?.abort();const active=new AbortController();controller.current=active;const revision=++generation.current;
    setCsrf('');setState({user:null,host:null,loading:true,error:''});
    try {
      const host=await api<HostContext>('/public/context',{signal:active.signal});let session:Session|null=null;
      try{session=await api<Session>('/auth/browser/session',{signal:active.signal});}catch(error){if(!(error instanceof ApiError)||error.status!==401)throw error;}
      if(active.signal.aborted||revision!==generation.current)return;
      if(session&&!isMockMode&&!sessionMatchesHost(session.user,host))throw new ApiError('La sesión no corresponde a este espacio. Revisa el acceso.',401);
      setCsrf(session?.csrfToken||'');setBranchId(session?.branchId||null);setState({host,user:session?.user||null,loading:false,error:''});
      if(session&&!host.platform&&host.ruc){const choices=await api<LoginBranch[]>('/v1/negocios/'+host.ruc+'/sucursales',{signal:active.signal});if(!active.signal.aborted&&revision===generation.current){setBranches(choices);if(!isMockMode&&!session.branchId&&choices.length>1)setState(value=>({...value,user:value.user?{...value.user,requiresBranchSelection:true}:null}));}}else setBranches([]);
    }catch(error){if(active.signal.aborted||revision!==generation.current||isAbort(error))return;setCsrf('');setState({user:null,host:null,loading:false,error:errorMessage(error)});}
  },[]);
  useEffect(()=>{
    void refresh();
    const expire=(event:Event)=>{controller.current?.abort();generation.current++;setCsrf('');const reference=(event as CustomEvent<{requestId?:string}>).detail?.requestId;setState({user:null,host:null,loading:false,error:errorMessage(new ApiError('Tu sesión venció o fue revocada. Vuelve a comprobar el acceso.',401,typeof reference==='string'?reference:''))});};
    window.addEventListener('health:session-expired',expire);
    return()=>{controller.current?.abort();generation.current++;window.removeEventListener('health:session-expired',expire);};
  },[refresh,mockContext]);
  async function login(email:string,password:string,ruc?:string){
    controller.current?.abort();const revision=++generation.current;setCsrf('');setState(value=>({...value,user:null}));
    try{
      const result=state.host?.platform?await api<Session>('/auth/browser/login',{method:'POST',body:{email,password}}):await api<Session&{branches:LoginBranch[];requiresBranchSelection:boolean}>('/v1/auth/login',{method:'POST',body:{ruc,email,password}});
      const host=await api<HostContext>('/public/context'),session=await api<Session>('/auth/browser/session');
      if(revision!==generation.current)throw new ApiError('El acceso cambió. Vuelve a comprobar la sesión.',401);
      if(!isMockMode&&!sessionMatchesHost(session.user,host))throw new ApiError('La sesión no corresponde a este espacio.',401);
      const choices='branches' in result?result.branches as LoginBranch[]:[];
      setBranches(choices);setBranchId(session.branchId||null);
      const user={...session.user,requiresBranchSelection:!host.platform&&choices.length>1&&!session.branchId};
      setCsrf(session.csrfToken);setState({host,user,loading:false,error:''});setLogoutError('');return user;
    }catch(error){if(revision===generation.current){setCsrf('');setState(value=>({...value,user:null}));}throw error;}
  }
  async function selectBranch(id:string){await api('/v1/auth/sucursal',{method:'POST',body:{branchId:id}});await refresh();}
  async function logout(){
    setLoggingOut(true);setLogoutError('');
    try{await api('/auth/browser/session',{method:'DELETE'});await refresh();return true;}
    catch(error){setLogoutError('No se confirmó el cierre de sesión. Puedes volver a intentarlo. '+errorMessage(error));return false;}
    finally{setLoggingOut(false);}
  }
  return <Auth.Provider value={{...state,refresh,login,logout,logoutError,loggingOut,branchId,branches,selectBranch}}>{children}</Auth.Provider>;
}
export function useAuth(){const value=useContext(Auth);if(!value)throw new Error('SessionProvider is required');return value;}
export function homeFor(user:SessionUser){return liveBase(user)+'/inicio';}
