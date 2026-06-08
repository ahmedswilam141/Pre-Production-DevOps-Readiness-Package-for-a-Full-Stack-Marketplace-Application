# Known Limitations

This document classifies all known issues by type. See the issue classification key below.

**Classification:**
- 🔴 **DevOps Issue** — infrastructure configuration problem
- 🟡 **Missing Configuration** — requires real credentials or values to function
- 🔵 **External Service Limitation** — cannot test without live third-party account
- 🟣 **Application Bug / Dependency Issue** — existing application code concern, not DevOps scope

---

## 🟣 Backend Runtime: TF.js Native Binary Compatibility

**Severity:** High (backend may fail to start)

`@tensorflow/tfjs-node` ships pre-compiled native binaries linked against **glibc** (GNU C Library). The original Dockerfile used `node:20-alpine`, which uses **musl libc** — a different, incompatible C library. At container startup, Node.js would fail to load the TF.js native binding with an error similar to:

```
Error: /lib/x86_64-linux-gnu/libm.so.6: version 'GLIBC_2.29' not found
```

**Fix applied in this package:** The backend Dockerfile has been updated to use `node:20-slim` (Debian-based, ships with glibc). This resolves the binary incompatibility. Full runtime validation of the AI layer in a Docker environment was not completed as part of this engagement; however, the root cause has been addressed.

**If the AI layer still fails at runtime:** Set `ENABLE_TRADESPACE_AI=false` in `backend/.env` to disable the moderation pipeline and allow the rest of the backend to start normally.

---

## 🟣 Backend Build: TypeScript emitDeclarationOnly

**Severity:** Medium

`backend/tsconfig.json` has `"emitDeclarationOnly": true`. This means running `tsc` produces only `.d.ts` type-declaration files — **not executable JavaScript**. Running `node dist/index.js` would fail because no `.js` files are emitted.

**Fix applied in this package:** The backend Dockerfile uses `ts-node --transpile-only src/index.ts` as the runtime command instead of `node dist/index.js`. `ts-node` is already a production dependency and compiles TypeScript to CommonJS in-process at startup. Type safety is validated separately in the CI pipeline via `tsc`.

---

## 🟣 Prisma Migrations Not Included

**Severity:** Medium (blocks first production deploy without manual step)

The `backend/prisma/` directory contains `schema.prisma` (the schema definition) but **no `migrations/` folder**. Running `prisma migrate deploy` on a fresh database will fail because there are no migration files to apply.

**Workaround for first deployment:** Use `prisma db push` instead, which directly applies the schema to the database without requiring migration history:

```bash
docker compose exec backend npx prisma db push
```

**Note:** `prisma db push` is appropriate for initial setup but is not recommended for incremental production deployments where data must be preserved. Before the application goes live, the client's development team should run `prisma migrate dev --name init` locally to generate migration files and include them in source control.

---

## 🟣 Frontend TypeScript Compilation Errors

**Severity:** Medium (blocks `yarn build` without fixes)

The following TypeScript issues exist in the original application source:

- `frontend/src/pages/Home.page.tsx`: `navigate` call uses object form incompatible with react-router-dom v6 (TS2345). **Fixed** — updated to string path.
- `frontend/src/pages/GetAds.page.tsx`: Same issue. **Fixed.**
- `backend/src/TradeSpaceAI/index.ts`: Optional chaining missing on AI verdict properties when `is_sell_ad` is false (TS2339/TS2322). **Fixed** — added optional chaining.
- `frontend/src/components/Ads/AdDetails/AdDetails.tsx`: Non-null assertions on optional fields. **Fixed** — replaced with optional chaining and defaults.

These are **application code issues**, not DevOps scope. The fixes listed above were applied as part of making the build pipeline functional.

---

## 🟡 VITE_API_URL is a Build-Time Variable

**Severity:** Low — requires awareness

Vite bakes `VITE_*` environment variables into the JavaScript bundle **at build time**, not at runtime. This means:

- Passing `VITE_API_URL` as a Docker runtime environment variable (e.g. in `environment:`) has **no effect** on the running application.
- To change the API URL, you must pass it as a Docker **build argument** and rebuild the image:
  ```bash
  docker compose up -d --build
  # or explicitly:
  docker build --build-arg VITE_API_URL=https://yourdomain.com/api ./frontend
  ```
- Both Compose files now correctly pass `VITE_API_URL` as a build `args:` entry.

---

## 🔵 External Service Limitations

The following features require real third-party credentials and **cannot be fully tested** without them. This is expected and acceptable — these are external service limitations, not DevOps issues.

| Service | Feature | Required Credentials |
|---|---|---|
| **Stripe** | Payment processing, subscriptions | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` |
| **Twilio** | Phone number verification | `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_VERIFY_SID` |
| **Firebase** | File storage, authentication | All `VITE_FIREBASE_*` variables |
| **Gmail / SMTP** | Email notifications | `APP_PASSWORD`, `USER_EMAIL` |
| **Stripe Test Mode** | Can be partially tested | Use `sk_test_*` keys from Stripe Dashboard |

---

## 🟡 Database Credentials in Dev Compose

`docker-compose.yml` uses environment variable substitution (`${DB_PASSWORD:-change_me_dev_password}`) to read credentials from `.env`. The fallback value is intentionally weak and **must be overridden** via `.env` even in development. In production, use only `docker-compose.prod.yml` with real credentials in `backend/.env`.

---

## 🟣 No Backend Health Endpoint

The backend exposes a root route (`GET /`) that returns an HTML string. There is no dedicated `/health` or `/api/health` endpoint that returns a machine-readable response (e.g. `{"status":"ok"}`). This limits the ability to configure Nginx upstream health checks and Docker HEALTHCHECK directives. Adding a `/health` endpoint is recommended before production release.

---

## 🟣 AI Model Cold Start Latency

The first request that triggers AI moderation (image classification via MobileNet or NLP analysis) will experience a cold-start delay as TensorFlow loads the model into memory. Subsequent requests use the cached model. This is expected behaviour for TF.js. Ensure Nginx timeout settings are adequate (the `tradespace.conf` already sets `proxy_read_timeout 120s` for this reason).
