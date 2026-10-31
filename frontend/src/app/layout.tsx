import type { Metadata, Viewport } from 'next';
import { GeistSans } from 'geist/font/sans';
import { Providers } from '@/components/providers';
import './globals.css';
import '@/styles/application.css';
import '@/styles/saas.css';
import '@/styles/runtime.css';
import '@/styles/review.css';
export const metadata: Metadata = { title: 'Health Project · Tu espacio clínico', description: 'Plataforma clínica para personas, profesionales y animales. Frontend de presentación con datos ficticios.' };
export const viewport: Viewport = { width: 'device-width', initialScale: 1 };
export default function RootLayout({ children }: { children: React.ReactNode }) { return <html lang="es" suppressHydrationWarning className={GeistSans.variable}><body><Providers>{children}</Providers></body></html>; }
