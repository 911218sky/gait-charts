/**
 * 超簡易靜態檔案 server（for Flutter build/web preview）。
 *
 * 用法：
 *   node scripts/web/server.js <port> <webDir>
 *
 * 功能：
 * - 支援 WASM MIME：application/wasm
 * - 自動加 COOP/COEP headers（WASM / SharedArrayBuffer 常見需求）
 * - SPA fallback：找不到檔案且 URL 沒副檔名時回 index.html
 */
const http = require('http');
const fs = require('fs');
const path = require('path');

function usageAndExit() {
  // eslint-disable-next-line no-console
  console.log('Usage: node scripts/web/server.js <port> <webDir>');
  process.exit(2);
}

const portRaw = process.argv[2];
const webDirRaw = process.argv[3];
if (!portRaw || !webDirRaw) usageAndExit();

const port = Number(portRaw);
if (!Number.isFinite(port) || port <= 0) usageAndExit();

const webDir = path.resolve(webDirRaw);
if (!fs.existsSync(webDir) || !fs.statSync(webDir).isDirectory()) {
  // eslint-disable-next-line no-console
  console.error(`[ERROR] webDir not found or not a directory: ${webDir}`);
  process.exit(1);
}

/** @param {string} filePath */
function contentTypeFor(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  switch (ext) {
    case '.html':
      return 'text/html; charset=utf-8';
    case '.js':
      return 'application/javascript; charset=utf-8';
    case '.mjs':
      return 'application/javascript; charset=utf-8';
    case '.css':
      return 'text/css; charset=utf-8';
    case '.json':
      return 'application/json; charset=utf-8';
    case '.wasm':
      return 'application/wasm';
    case '.svg':
      return 'image/svg+xml';
    case '.png':
      return 'image/png';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    case '.ico':
      return 'image/x-icon';
    case '.txt':
      return 'text/plain; charset=utf-8';
    case '.map':
      return 'application/json; charset=utf-8';
    default:
      return 'application/octet-stream';
  }
}

/**
 * @param {string} urlPath
 * @returns {string} absolute file path (under webDir)
 */
function resolveSafePath(urlPath) {
  // 去掉 query/hash，只處理 path 部分
  const clean = urlPath.split('?')[0].split('#')[0];
  const decoded = decodeURIComponent(clean);
  const relative = decoded.replace(/^\//, '');
  const abs = path.resolve(webDir, relative);

  // 避免 directory traversal
  const relToRoot = path.relative(webDir, abs);
  if (relToRoot.startsWith('..') || path.isAbsolute(relToRoot)) {
    return path.join(webDir, 'index.html');
  }
  return abs;
}

const server = http.createServer((req, res) => {
  try {
    const reqUrl = req.url || '/';
    let filePath = resolveSafePath(reqUrl);

    // root -> index.html
    if (reqUrl === '/' || reqUrl === '') {
      filePath = path.join(webDir, 'index.html');
    }

    // 如果是資料夾，補 index.html
    if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }

    // SPA fallback：沒副檔名且不存在 => index.html
    const hasExt = path.extname(filePath) !== '';
    if (!fs.existsSync(filePath) && !hasExt) {
      filePath = path.join(webDir, 'index.html');
    }

    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
      res.statusCode = 404;
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      res.end('Not Found');
      return;
    }

    res.statusCode = 200;
    res.setHeader('Content-Type', contentTypeFor(filePath));

    // Flutter Web / WASM preview 常用 headers
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.setHeader('Access-Control-Allow-Origin', '*');

    // 預覽用途：避免奇怪 cache 造成更新看不到
    res.setHeader('Cache-Control', 'no-cache');

    fs.createReadStream(filePath).pipe(res);
  } catch (e) {
    res.statusCode = 500;
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.end('Internal Server Error');
  }
});

server.listen(port, '127.0.0.1', () => {
  // eslint-disable-next-line no-console
  console.log(`[OK] Static server running: http://127.0.0.1:${port}`);
  // eslint-disable-next-line no-console
  console.log(`[OK] Serving dir: ${webDir}`);
});


