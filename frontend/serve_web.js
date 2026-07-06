// Static server for the built Flutter web app (build/web) with SPA fallback,
// AND a reverse proxy: /v1, /health, /docs → the NestJS backend on localhost:3000.
// This lets the app call its own origin (same-origin), so a single public tunnel URL
// stays stable even when the backend restarts.
const http = require('http');
const fs = require('fs');
const path = require('path');

const BACKEND = { host: 'localhost', port: 3000 };
const root = path.join(__dirname, 'build', 'web');
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.wasm': 'application/wasm',
  '.bin': 'application/octet-stream',
  '.map': 'application/json',
};

function isApi(p) {
  return p.startsWith('/v1') || p === '/health' || p.startsWith('/docs');
}

http
  .createServer((req, res) => {
    const p = decodeURIComponent((req.url || '/').split('?')[0]);

    if (isApi(p)) {
      const proxyReq = http.request(
        { host: BACKEND.host, port: BACKEND.port, path: req.url, method: req.method, headers: req.headers },
        (proxyRes) => {
          res.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
          proxyRes.pipe(res);
        },
      );
      proxyReq.on('error', () => {
        res.writeHead(502);
        res.end('backend unavailable');
      });
      req.pipe(proxyReq);
      return;
    }

    let file = path.join(root, p === '/' ? '/index.html' : p);
    if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
      file = path.join(root, 'index.html');
    }
    const ext = path.extname(file).toLowerCase();
    const base = path.basename(file);
    // Files that must never be cached: they decide which version everything else is.
    // Everything else may be cached but MUST be revalidated (no-cache -> 304 when unchanged),
    // so testers are never stranded on a stale build yet large assets stay fast.
    const neverCache = base === 'index.html' || base === 'flutter_bootstrap.js' || base === 'flutter_service_worker.js';
    let stat;
    try {
      stat = fs.statSync(file);
    } catch (_) {
      res.writeHead(404);
      res.end('not found');
      return;
    }
    const lastMod = stat.mtime.toUTCString();
    if (!neverCache && req.headers['if-modified-since'] === lastMod) {
      res.writeHead(304);
      res.end();
      return;
    }
    fs.readFile(file, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('not found');
        return;
      }
      const headers = { 'Content-Type': types[ext] || 'application/octet-stream' };
      if (neverCache) {
        headers['Cache-Control'] = 'no-store, must-revalidate';
      } else {
        headers['Cache-Control'] = 'no-cache';
        headers['Last-Modified'] = lastMod;
      }
      res.writeHead(200, headers);
      res.end(data);
    });
  })
  .listen(8080, () => console.log('FluentAI web + API proxy on http://localhost:8080'));
