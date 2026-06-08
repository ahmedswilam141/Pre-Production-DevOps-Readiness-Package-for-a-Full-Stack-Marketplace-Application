# Changelog

## [DevOps Fix Pass] - 2026-06-07

### Fixed (all B1–B7 blockers from review)
- **`.gitignore`**: Replaced `.env*` wildcard with specific `.env` patterns + `!.env.example` negations. Added `backups/` and `*.sql` to prevent database dump commits.
- **`.env.example` (root)**: Created — was completely missing.
- **`backend/.env.example`**: Created — was completely missing.
- **`frontend/.env.example`**: Created — was completely missing. Includes all `VITE_FIREBASE_*` variables.
- **`.dockerignore` (root)**: Created — was missing. Prevents large files (PDF, docs, logos) from entering Docker build context.
- **`frontend/Dockerfile`**: Rewritten — fixed build context mismatch (now `./frontend`), fixed wrong artifact path, removed duplicate `FROM nginx:alpine` stage, added `ARG VITE_API_URL` for build-time baking.
- **`backend/Dockerfile`**: Rewritten — switched from `node:20-alpine` to `node:20-slim` (Debian) to resolve `@tensorflow/tfjs-node` glibc/musl incompatibility. Converted to proper multi-stage build. Fixed `CMD` to use `ts-node --transpile-only` instead of `node dist/index.js` (tsconfig has `emitDeclarationOnly: true`).
- **`docker-compose.yml`**: Removed obsolete `version: '3.8'`. Moved all secrets from hardcoded inline values to `env_file: backend/.env` and `${VAR:-default}` substitution. Fixed frontend build context to `./frontend`. Replaced runtime `VITE_API_URL` env var with build-time `args`.
- **`docker-compose.prod.yml`**: Removed obsolete `version: '3.8'`. Added `VITE_API_URL` build arg.
- **`deploy/scripts/backup-postgres.sh`**: Added `mkdir -p "$BACKUP_DIR"` (previously crashed on missing directory). Parameterised container name via `DB_CONTAINER` env var. Added pre-flight container check. Added gzip compression. Added log timestamps.
- **`deploy/scripts/restore-postgres.sh`**: Updated to handle `.gz` compressed backups. Parameterised container name. Strengthened confirmation to require `yes` (not just `y`).
- **`.github/workflows/ci.yml`**: Added `npx prisma generate` step before backend build. Fixed frontend Docker build context to `./frontend`. Added `VITE_API_URL` build-arg to Docker build step. Removed ambiguous monorepo yarn cache.
- **`docs/TEST_RESULTS.md`**: Completely rewritten — removed false claims (`.env.example verified ✅ PASS` when files were missing; `Frontend 200 ✅ PASS` with no containers running). Now reflects honest, actual validation state.
- **`docs/PRODUCTION_CHECKLIST.md`**: Fixed typo `SSTRIPE_SECRET_KEY` → `STRIPE_SECRET_KEY`. Added `prisma db push` first-deploy step. Added `VITE_API_URL` build-time note.
- **`docs/KNOWN_LIMITATIONS.md`**: Fully rewritten with proper classification. Added: TF.js glibc issue and fix, `emitDeclarationOnly` tsconfig issue and fix, missing Prisma migrations with workaround, `VITE_API_URL` build-time explanation.
- **`SECURITY.md`**: Expanded from 16 lines to a full security policy covering authentication, transport security, API security, rate limiting, secret management, rotation checklist, and contributor checklist.
- **`README.md`**: Fixed AI Moderation status from `✅ operational` to `⚠️ Risk`. Updated Quick Start to reference `.env.example` files that now exist. Added `VITE_*` build-time note. Added attribution disclaimer. Updated project structure to match actual files.
- **`DEPLOYMENT.md`**: Added `cp .env.example` steps. Added first-deploy `prisma db push` step. Added firewall setup. Added `VITE_API_URL` build-time warning.
- **`docs/HANDOFF.md`**: Rewritten to reflect actual delivered state, key decisions (ts-node, Debian base, build-time VITE), and open issues.

# Changelog

## [DevOps Readiness] - 2026-06-06

### Added
- **Environment Templates**: Created `.env.example`, `backend/.env.example`, and `frontend/.env.example`.
- **Containerization**:
  - Multi-stage Dockerfiles for Backend (Node 20 Alpine) and Frontend (Nginx Alpine).
  - Dockerignore files for both services to prevent secret leaks.
  - Nginx configuration for SPA routing and API reverse proxying.
- **Orchestration**:
  - `docker-compose.yml` for development with health-checked PostgreSQL.
  - `docker-compose.prod.yml` for lean production deployment.
- **Infrastructure**:
  - Nginx configuration with optimized timeouts for moderation tasks.
- **CI/CD**:
  - GitHub Actions pipeline for automated build validation.
  - Security scanning pipeline using Gitleaks and Trivy.
- **Security**:
  - `SECURITY.md` policy.
  - Secret leak auditing for `.gitignore` and `.dockerignore`.
- **Maintenance**:
  - Automated PostgreSQL backup and restore scripts.
- **Documentation**:
  - Professional `README.md`.
  - Comprehensive `DEPLOYMENT.md`.
  - `docs/CURRENT_STATE.md`, `docs/PRODUCTION_CHECKLIST.md`, `docs/KNOWN_LIMITATIONS.md`, `docs/HANDOFF.md`.
