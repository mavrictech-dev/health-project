import { Suspense } from 'react';
import { HealthApp } from '@/components/health-app';
export default function Home() { return <Suspense fallback={<div className="boot-screen">Preparando tu espacio…</div>}><HealthApp /></Suspense>; }
