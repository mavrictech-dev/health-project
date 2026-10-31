import type { NextConfig } from 'next';
const nextConfig: NextConfig = {
  output: 'export', trailingSlash: true, images: { unoptimized: true }, devIndicators: false,
  ...(process.env.NEXT_PUBLIC_APP_MODE === 'mock' ? { distDir: 'out-demo' } : {}),
  turbopack: { rules: { '*.css': { loaders: ['@tailwindcss/turbopack'], as: '*.css' } } },
};
export default nextConfig;
