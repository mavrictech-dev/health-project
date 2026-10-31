import { Suspense } from 'react';
import routes from '@/data/routes.json';
import { HealthApp } from '@/components/health-app';
export const dynamicParams = false;
export function generateStaticParams() { return routes.map(route => ({ path: route.slice(1).split('/') })); }
export default function Page() { return <Suspense fallback={<div className="boot-screen">Preparando tu espacio…</div>}><HealthApp /></Suspense>; }
