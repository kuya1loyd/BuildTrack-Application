# buildtrack

A Flutter construction-project app backed by a Neon Postgres database.

## Getting Started

The database connection string lives in `flutter/env.json` (git-ignored):

```json
{
  "NEON_DATABASE_URL": "postgresql://user:pass@host/db?sslmode=require",
  "API_BRIDGE_TOKEN": "<32 random bytes, hex>"
}
```

**Native (Windows desktop / Android / iOS):** connects to Neon directly.

```bash
flutter run --dart-define-from-file=env.json
```

**Web (Chrome):** browsers cannot open raw Postgres TCP sockets, so web runs
through the HTTP bridge in `server/`. Start both:

```bash
# terminal 1 - the bridge (reads the same env.json for credentials + token)
cd server && npm install && npm start

# terminal 2 - the app (env.json injects both the DB URL and the bridge token)
flutter run -d chrome --dart-define-from-file=env.json --dart-define=API_BASE_URL=http://127.0.0.1:8787
```

## Security notes

- Passwords are stored as PBKDF2-HMAC-SHA256 hashes (150k iterations, 16-byte
  salt) — the plaintext never leaves the device. Accounts created before this
  scheme are verified with their legacy salted SHA-256 hash and re-hashed to
  PBKDF2 on the next sign-in.
- **Web builds authenticate on the bridge** (`POST /auth/signin`,
  `POST /auth/signup`) instead of deriving the hash in the browser: 150k
  PBKDF2 iterations in Dart-compiled JS freeze the page (and the IDE hosting
  the preview) for seconds, while Node's native `crypto` does it in ~50ms.
  Native targets still hash locally, using the same formats, so accounts work
  across both paths.
- The bridge executes the SQL it is sent, so it requires the
  `API_BRIDGE_TOKEN` bearer token, listens on loopback only, and throttles
  repeated failed authentications. Treat it as a dev tool: add real
  authentication and serve it over TLS before exposing it anywhere.
- Never commit `flutter/env.json` — it holds the database password and the
  bridge token. It is listed in `.gitignore`; keep it that way.
- Session tokens live in platform storage (`shared_preferences`). Move them to
  `flutter_secure_storage` before shipping a production build.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and an full API reference.
