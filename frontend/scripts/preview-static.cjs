const http = require('node:http');
const { createReadStream, existsSync, statSync } = require('node:fs');
const path = require('node:path');
const demo = process.argv.includes('--demo');
const root = path.resolve(__dirname, '..', demo ? 'out-demo' : 'out');
const port = Number(process.env.PORT || (demo ? 3002 : 3001));
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8', '.txt': 'text/plain; charset=utf-8', '.svg': 'image/svg+xml', '.png': 'image/png', '.woff2': 'font/woff2', '.ico': 'image/x-icon' };
if (!existsSync(path.join(root, 'index.html'))) throw new Error(`Ejecuta npm run ${demo ? 'build:demo' : 'build'} antes de presentar.`);
http.createServer((request, response) => {
  if (!['GET', 'HEAD'].includes(request.method)) { response.writeHead(405); response.end(); return; }
  let pathname;
  try { pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname); } catch { response.writeHead(400); response.end(); return; }
  let file = path.resolve(root, '.' + pathname);
  // Windows replaces ':' in static RSC segment files with directories.
  if (!existsSync(file) && /\/(__next\.[^/]+)\.txt$/.test(pathname)) {
    const match = pathname.match(/^(.*\/)(__next\.[^/]+)\.txt$/);
    const segment = match[2].lastIndexOf('.');
    if (segment > '__next.'.length) file = path.resolve(root, '.' + match[1], match[2].slice(0, segment), match[2].slice(segment + 1) + '.txt');
  }
  if (file !== root && !file.startsWith(root + path.sep)) { response.writeHead(403); response.end(); return; }
  if (existsSync(file) && statSync(file).isDirectory()) file = path.join(file, 'index.html');
  if (!existsSync(file) && !path.extname(file) && existsSync(path.join(file, 'index.html'))) file = path.join(file, 'index.html');
  if (!existsSync(file) || !statSync(file).isFile()) { response.statusCode = 404; file = path.join(root, '404.html'); }
  response.setHeader('Content-Type', types[path.extname(file)] || 'application/octet-stream');
  response.setHeader('Cache-Control', 'no-store');
  if (request.method === 'HEAD') { response.end(); return; }
  createReadStream(file).pipe(response);
}).listen(port, '127.0.0.1', () => console.log(`Health Project: http://127.0.0.1:${port} (exportación estática)`));
