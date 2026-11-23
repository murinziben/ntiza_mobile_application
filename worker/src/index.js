// NTIZA upload service: the app sends an image with its Firebase ID token, this
// Worker checks the token and stores the file in Cloudflare R2. R2 keys never
// reach the mobile app.
//
//   PUT /upload?kind=equipment|avatar   (Authorization: Bearer <Firebase ID token>)
//   body = image bytes (image/jpeg | image/png | image/webp, max 5 MB)
//   -> 200 { "url": "<PUBLIC_BASE_URL>/<kind>/<uid>/<id>.<ext>" }

const MAX_BYTES = 5 * 1024 * 1024;
const KINDS = new Set(['equipment', 'avatar']);
const TYPES = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

const b64urlToBytes = (s) => {
  const b = atob(s.replace(/-/g, '+').replace(/_/g, '/'));
  return Uint8Array.from(b, (c) => c.charCodeAt(0));
};
const b64urlToJson = (s) => JSON.parse(new TextDecoder().decode(b64urlToBytes(s)));

/** Returns the Firebase uid of a valid ID token, or null. */
async function verifyToken(token, env) {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  let header, payload;
  try {
    header = b64urlToJson(parts[0]);
    payload = b64urlToJson(parts[1]);
  } catch {
    return null;
  }
  const now = Math.floor(Date.now() / 1000);
  const project = env.FIREBASE_PROJECT_ID;
  if (payload.aud !== project || payload.iss !== `https://securetoken.google.com/${project}`)
    return null;
  if (!payload.sub || payload.exp < now || payload.iat > now + 300) return null;

  // The Auth emulator issues unsigned tokens; accept them only when explicitly enabled.
  if (header.alg === 'none') return env.ALLOW_EMULATOR_TOKENS === 'true' ? payload.sub : null;
  if (header.alg !== 'RS256') return null;

  const res = await fetch(JWKS_URL, { cf: { cacheTtl: 3600, cacheEverything: true } });
  if (!res.ok) return null;
  const jwk = (await res.json()).keys.find((k) => k.kid === header.kid);
  if (!jwk) return null;
  const key = await crypto.subtle.importKey(
    'jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5', key, b64urlToBytes(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`));
  return ok ? payload.sub : null;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname !== '/upload') return json({ error: 'Not found' }, 404);
    if (request.method !== 'PUT') return json({ error: 'Use PUT' }, 405);

    const auth = request.headers.get('authorization') ?? '';
    const uid = auth.startsWith('Bearer ') ? await verifyToken(auth.slice(7), env) : null;
    if (!uid) return json({ error: 'Please log in again.' }, 401);

    const kind = url.searchParams.get('kind') ?? '';
    if (!KINDS.has(kind)) return json({ error: 'Unknown upload kind.' }, 400);

    const type = (request.headers.get('content-type') ?? '').split(';')[0].trim();
    const ext = TYPES[type];
    if (!ext) return json({ error: 'Only JPEG, PNG or WebP images are allowed.' }, 415);

    const length = Number(request.headers.get('content-length') ?? 0);
    if (length > MAX_BYTES) return json({ error: 'Image is larger than 5 MB.' }, 413);
    const bytes = await request.arrayBuffer();
    if (bytes.byteLength === 0 || bytes.byteLength > MAX_BYTES)
      return json({ error: 'Image must be between 1 byte and 5 MB.' }, 413);

    const key = `${kind}/${uid}/${crypto.randomUUID()}.${ext}`;
    await env.BUCKET.put(key, bytes, {
      httpMetadata: { contentType: type, cacheControl: 'public, max-age=31536000, immutable' },
    });
    return json({ url: `${env.PUBLIC_BASE_URL}/${key}` });
  },
};
