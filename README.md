# TradeSpace — Pre-Production DevOps Readiness Package

> **Attribution:** This repository contains a **DevOps readiness package** applied to an existing full-stack marketplace application. The Docker infrastructure, CI/CD pipelines, environment management, Nginx configuration, backup scripts, and all documentation were authored as part of a freelance DevOps engagement. The underlying application code (React/Vite frontend, Node.js/Express backend) was provided by the client.

---

A professional full-stack online marketplace for securely buying and selling used products.

## Architecture

```
Browser → Nginx (port 80/443) → Frontend (React/Vite/Nginx) 
                              → Backend (Node/Express) → PostgreSQL
```

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Frontend | React + TypeScript + Vite | 18.2.0 / 5.1.6 / 4.4.5 |
| Backend | Node.js + Express + TypeScript | 20-slim (Debian) / 4.18.2 / 5.1.6 |
| Database | PostgreSQL | 15-alpine |
| Proxy | Nginx | Alpine |
| ORM | Prisma | 4.16.2 |
| AI Layer | TensorFlow.js / MobileNet | 4.10.0 |

## Project Status

| Component | Status | Notes |
|---|---|---|
| Frontend Container | ✅ Builds | Correct multi-stage Dockerfile; context fixed |
| Backend Container | ✅ Builds | node:20-slim for TF.js glibc compatibility |
| Database | ✅ Configured | Schema defined; persistent named volume; healthcheck |
| Nginx Proxy | ✅ Configured | Reverse proxy with AI timeout; SSL-ready |
| AI Moderation | ⚠️ Risk | TF.js glibc fix applied; runtime not validated — see `docs/KNOWN_LIMITATIONS.md` |
| External Services | ⚠️ Pending | Require real credentials (Stripe, Twilio, Firebase) |
| Prisma Migrations | ⚠️ Missing | Use `prisma db push` on first deploy — see `docs/KNOWN_LIMITATIONS.md` |

## Quick Start (Local Development)

### Prerequisites
- Docker and Docker Compose v2
- Git

### 1. Clone the repository
```bash
git clone (https://github.com/ahmedswilam141/Pre-Production-DevOps-Readiness-Package-for-a-Full-Stack-Marketplace-Application.git)
cd TradeSpace
```

### 2. Set up environment variables
```bash
cp .env.example .env
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```

Open each `.env` file and fill in the values. At minimum, set a strong `DB_PASSWORD` and `SECRET`.

> **Stripe, Twilio, and Firebase** require real credentials for those features to work. The application will start without them — those specific features will return errors.

### 3. Build and start all services
```bash
docker compose up -d --build
```

### 4. Apply the database schema (first run only)
```bash
docker compose exec backend npx prisma db push
```

### 5. Access the application
- Frontend: [http://localhost](http://localhost) (via Nginx)
- Backend API: [http://localhost:3000](http://localhost:3000) (direct)
- Database: `localhost:5432`

---

## Environment Variables

### Root `.env`
| Variable | Required | Description |
|---|---|---|
| `DB_USER` | Yes | PostgreSQL username |
| `DB_PASSWORD` | Yes | PostgreSQL password — **change from default** |
| `DB_NAME` | Yes | PostgreSQL database name |
| `VITE_API_URL` | Yes | Frontend API URL — build-time, must rebuild image to change |

### `backend/.env`
| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | Full PostgreSQL connection string |
| `SECRET` | Yes | JWT secret key — use `openssl rand -hex 64` |
| `PORT` | Yes | Backend port (default: 3000) |
| `ENABLE_TRADESPACE_AI` | Yes | `true` / `false` — enable AI moderation |
| `STRIPE_SECRET_KEY` | No | Stripe API key |
| `TWILIO_ACCOUNT_SID` | No | Twilio account identifier |
| `TWILIO_AUTH_TOKEN` | No | Twilio auth token |
| `TWILIO_VERIFY_SID` | No | Twilio Verify service SID |
| `APP_PASSWORD` | No | Gmail App Password for email notifications |

### `frontend/.env`
| Variable | Required | Description |
|---|---|---|
| `VITE_API_URL` | Yes | Backend API base URL (baked at build time) |
| `VITE_FIREBASE_API_KEY` | No | Firebase project API key |
| `VITE_FIREBASE_*` | No | Remaining Firebase configuration keys |

> ⚠️ `VITE_*` variables are **build-time only** — changing them requires rebuilding the frontend image (`docker compose up --build`).

---

## Useful Commands

| Action | Command |
|---|---|
| Start all services | `docker compose up -d` |
| Rebuild and start | `docker compose up -d --build` |
| Stop all services | `docker compose down` |
| View all logs | `docker compose logs -f` |
| Backend logs | `docker compose logs backend -f` |
| Frontend logs | `docker compose logs frontend -f` |
| Apply DB schema | `docker compose exec backend npx prisma db push` |
| Run DB migrations | `docker compose exec backend npx prisma migrate deploy` |
| Backup database | `./deploy/scripts/backup-postgres.sh` |
| Restore database | `./deploy/scripts/restore-postgres.sh backups/<file>.sql.gz` |
| Reset database (⚠️ deletes data) | `docker compose down -v` |
| Production deploy | `docker compose -f docker-compose.prod.yml up -d --build` |

---

## Deployment

Full VPS deployment instructions: `DEPLOYMENT.md`  
Pre-go-live checklist: `docs/PRODUCTION_CHECKLIST.md`

---

## Known Limitations

See `docs/KNOWN_LIMITATIONS.md` for a full classified list. Key items:

- **External services** (Stripe, Firebase, Twilio, Email) require real API credentials.
- **TF.js runtime** risk addressed by switching to Debian base — not fully validated in live Docker environment.
- **Prisma migrations** not included — use `prisma db push` on first deploy.
- **Frontend TypeScript** — documented source-level fixes applied.

---

## Project Structure

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yml           # Build validation pipeline
│       └── security.yml     # Gitleaks + Trivy security scan
├── backend/
│   ├── Dockerfile           # node:20-slim multi-stage build
│   ├── .dockerignore
│   └── .env.example         # Backend environment variable template
├── frontend/
│   ├── Dockerfile           # Node build → nginx:alpine serve
│   ├── nginx.conf           # SPA routing config for frontend container
│   ├── .dockerignore
│   └── .env.example         # Frontend / Firebase environment template
├── deploy/
│   ├── nginx/
│   │   └── tradespace.conf  # Nginx reverse proxy config
│   └── scripts/
│       ├── backup-postgres.sh   # Automated PostgreSQL dump (gzip)
│       └── restore-postgres.sh  # Safe restore with confirmation prompt
├── docs/
│   ├── CURRENT_STATE.md     # Full environment and stack audit
│   ├── HANDOFF.md           # Client handoff summary
│   ├── KNOWN_LIMITATIONS.md # Classified issue registry
│   ├── PRODUCTION_CHECKLIST.md  # Pre-go-live checklist
│   └── TEST_RESULTS.md      # Validation results and notes
├── .env.example             # Root environment variable template
├── .dockerignore            # Root build context exclusions
├── docker-compose.yml       # Local development orchestration
├── docker-compose.prod.yml  # Production orchestration
├── CHANGELOG.md
├── DEPLOYMENT.md            # VPS deployment guide
└── SECURITY.md              # Security policy and secret management
```

## Security

Detailed guidelines: `SECURITY.md`

Key points:
- No real credentials are committed anywhere in this repository.
- Secrets are managed via `.env` files (excluded by `.gitignore`).
- Automated scanning: Gitleaks (secrets) + Trivy (CVEs) on every push.
