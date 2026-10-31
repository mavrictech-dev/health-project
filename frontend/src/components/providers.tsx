'use client';
import { useEffect } from 'react';
import { useDemo } from '@/store/demo';
import { TooltipProvider } from '@/components/ui/tooltip';
import { SessionProvider } from './auth-session';

export function Providers({ children }: { children: React.ReactNode }) {
  const theme = useDemo(s => s.theme);
  useEffect(() => { void useDemo.persist.rehydrate(); }, []);
  useEffect(() => { document.documentElement.dataset.theme = theme; document.documentElement.classList.toggle('dark', theme !== 'light'); document.documentElement.style.colorScheme = theme === 'light' ? 'light' : 'dark'; }, [theme]);
  return <TooltipProvider><SessionProvider>{children}</SessionProvider></TooltipProvider>;
}
