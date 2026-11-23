# NTIZA upload Worker (Cloudflare R2)

Receives an image from the app, checks the Firebase ID token and stores it in R2.

```bash
cd worker
npx wrangler r2 bucket create ntiza-app
# In the dashboard: R2 > ntiza-app > Settings > enable the public r2.dev URL
# (or attach a custom domain) and put that URL in PUBLIC_BASE_URL in wrangler.toml.
npx wrangler deploy
```

Run the app against it:

```bash
flutter run --dart-define=UPLOAD_URL=https://ntiza-app.<account>.workers.dev
```

Local development (Auth emulator tokens are unsigned, so enable
`ALLOW_EMULATOR_TOKENS=true` in `wrangler.toml` for `wrangler dev` only):

```bash
npx wrangler dev --port 8787
flutter run --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=192.168.240.1 \
  --dart-define=UPLOAD_URL=http://192.168.240.1:8787
```
