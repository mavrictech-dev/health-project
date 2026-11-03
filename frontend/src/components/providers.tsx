'use client';
import { createContext,useContext,useEffect,useState } from 'react';
import { usePathname } from 'next/navigation';
import { useDemo } from '@/store/demo';
import { isMockMode } from '@/lib/app-mode';
import { readLiveTheme,writeLiveTheme,type VisualTheme } from '@/lib/live-preferences';
import { TooltipProvider } from '@/components/ui/tooltip';
import { SessionProvider } from './auth-session';
import '@/styles/live-shell.css';

const Visual=createContext<{theme:VisualTheme;setTheme:(theme:VisualTheme)=>void}>({theme:'light',setTheme:()=>{}});
const Presentation=createContext({demo:isMockMode,ready:isMockMode,leave:()=>{}});
export function useVisualPreferences(){return useContext(Visual);}
export function usePresentation(){return useContext(Presentation);}
function Theme({theme,children}:{theme:VisualTheme;children:React.ReactNode}){
  useEffect(()=>{document.documentElement.dataset.theme=theme;document.documentElement.classList.toggle('dark',theme!=='light');document.documentElement.style.colorScheme=theme==='light'?'light':'dark';},[theme]);
  return children;
}
function DemoVisual({children}:{children:React.ReactNode}){
  const theme=useDemo(s=>s.theme),setTheme=useDemo(s=>s.setTheme),[ready,setReady]=useState(false);
  useEffect(()=>{void Promise.resolve(useDemo.persist.rehydrate()).then(()=>setReady(true));},[]);
  return <Visual.Provider value={{theme,setTheme}}><Theme theme={theme}>{ready?children:<p className="boot-screen" role="status">Preparando la presentación…</p>}</Theme></Visual.Provider>;
}
function LiveVisual({children}:{children:React.ReactNode}){
  const [theme,setTheme]=useState<VisualTheme>('light');
  useEffect(()=>{try{setTheme(readLiveTheme(localStorage));}catch{/* Storage access may be disabled. */}},[]);
  function change(value:VisualTheme){setTheme(value);try{writeLiveTheme(localStorage,value);}catch{/* Keep the visual change in memory. */}}
  return <Visual.Provider value={{theme,setTheme:change}}><Theme theme={theme}>{children}</Theme></Visual.Provider>;
}
export function Providers({children}:{children:React.ReactNode}){
  const path=usePathname().replace(/\/$/,''),[demo,setDemo]=useState(isMockMode),[ready,setReady]=useState(isMockMode);
  useEffect(()=>{
    if(isMockMode)return;
    try{if(path==='/demo')sessionStorage.setItem('health-explicit-demo','1');setDemo(sessionStorage.getItem('health-explicit-demo')==='1');}
    catch{setDemo(active=>path==='/demo'||active);}
    setReady(true);
  },[path]);
  function leave(){try{sessionStorage.removeItem('health-explicit-demo');}catch{/* Presentation can still end without storage. */}setDemo(false);}
  const VisualProvider=demo?DemoVisual:LiveVisual;
  return <TooltipProvider><Presentation.Provider value={{demo,ready,leave}}><SessionProvider><VisualProvider>{children}</VisualProvider></SessionProvider></Presentation.Provider></TooltipProvider>;
}
