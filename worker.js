// Cloudflare Worker for Crystal Collecting Simulator.
// Serves the two pages from the static files in this repo and adds a few safe headers.
const ROUTES = {
  '/': '/crystalcsxmain.html',
  '/crystalcsxmain': '/crystalcsxmain.html',
  '/community': '/community.html',
};

// Files that live in the repo but should never be served to visitors.
const PRIVATE = /^\/(worker\.js|wrangler\.(toml|jsonc?)|\.assetsignore|supabase-setup\.sql|readme\.md)$/i;

export default {
  async fetch(request, env) {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method not allowed', { status: 405, headers: { Allow: 'GET, HEAD' } });
    }

    const url = new URL(request.url);
    const path = url.pathname.length > 1 ? url.pathname.replace(/\/+$/, '') : url.pathname;

    if (PRIVATE.test(path)) {
      return notFound();
    }

    const target = ROUTES[path.toLowerCase()];
    const assetRequest = target ? new Request(new URL(target, url), request) : request;
    const response = await env.ASSETS.fetch(assetRequest);

    if (response.status === 404) {
      return notFound();
    }
    return withHeaders(response);
  },
};

function withHeaders(response) {
  const r = new Response(response.body, response);
  r.headers.set('X-Content-Type-Options', 'nosniff');
  r.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  r.headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  return r;
}

function notFound() {
  const html = '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">' +
    '<title>Page not found</title><body style="font-family:system-ui,sans-serif;background:#1f1530;color:#fff;display:grid;place-items:center;min-height:100vh;margin:0;text-align:center">' +
    '<div><h1>Page not found</h1><p><a style="color:#ffc933" href="/">Back to Crystal Collecting Simulator</a></p></div>';
  return withHeaders(new Response(html, { status: 404, headers: { 'Content-Type': 'text/html; charset=utf-8' } }));
}
