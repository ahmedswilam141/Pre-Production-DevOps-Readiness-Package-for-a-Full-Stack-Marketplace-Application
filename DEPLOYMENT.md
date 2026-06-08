# Deployment Guide — TradeSpace

This document covers deploying TradeSpace to a production VPS using Docker Compose.

---

## 1. Server Prerequisites

- **OS:** Ubuntu 22.04 LTS (recommended)
- **Hardware:** Minimum 2 vCPUs, 4 GB RAM (8 GB recommended if AI moderation is enabled)
- **Software:** Docker, Docker Compose v2, Git, UFW, Certbot

---

## 2. Initial Server Setup

### Install Docker
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in for the group change to take effect
```

### Configure firewall
```bash
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

### Clone the repository
```bash
sudo mkdir -p /var/www/tradespace
sudo chown $USER:$USER /var/www/tradespace
git clone <repo-url> /var/www/tradespace
cd /var/www/tradespace
```

---

## 3. Configuration

### 3.1 Environment variables

Create `.env` files from the provided examples and fill in production values:

```bash
# Root env (DB credentials, shared URLs)
cp .env.example .env

# Backend env (app secrets, API keys)
cp backend/.env.example backend/.env

# Frontend env (Firebase keys)
cp frontend/.env.example frontend/.env
```

Edit each file. At minimum, set:
- `DB_PASSWORD` — a strong unique password
- `SECRET` — a long random JWT secret (`openssl rand -hex 64`)
- `VITE_API_URL` — `https://yourdomain.com/api`
- Firebase, Stripe, Twilio credentials as applicable

> ⚠️ `VITE_API_URL` is a **build-time variable** — it is baked into the frontend bundle when the Docker image is built. You must set it in `.env` **before** running `docker compose up --build`.

### 3.2 Nginx configuration

Update the domain name in the Nginx config:
```bash
nano deploy/nginx/tradespace.conf
# Replace: server_name yourdomain.com;
# With your actual domain
```

### 3.3 SSL certificates

Obtain a free Let's Encrypt certificate:
```bash
sudo apt update && sudo apt install -y certbot
sudo certbot certonly --standalone -d yourdomain.com
```

Certificates will be at `/etc/letsencrypt/live/yourdomain.com/`.  
The production Compose file mounts `/etc/letsencrypt` read-only into the Nginx container.

---

## 4. Production Launch

Build and start all services:
```bash
docker compose -f docker-compose.prod.yml up -d --build
```

Verify containers are healthy:
```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs nginx
docker compose -f docker-compose.prod.yml logs backend
```

---

## 5. First-Run Database Setup

> ⚠️ **Required on first deployment.** Prisma migration files are not included in this package (see `docs/KNOWN_LIMITATIONS.md`). Use `prisma db push` to create the schema directly from `schema.prisma`:

```bash
docker compose -f docker-compose.prod.yml exec backend npx prisma db push
```

Verify the schema was applied:
```bash
docker compose -f docker-compose.prod.yml exec backend npx prisma studio
# Or connect with psql to inspect tables
```

> **For future schema changes:** Once the application moves to active development, generate proper migration files with `prisma migrate dev` and use `prisma migrate deploy` for incremental updates.

---

## 6. Post-Deployment Maintenance

### Automated database backups

Schedule the backup script via crontab:
```bash
crontab -e
# Add this line (daily at 2 AM):
0 2 * * * /var/www/tradespace/deploy/scripts/backup-postgres.sh >> /var/log/tradespace-backup.log 2>&1
```

Test the backup manually:
```bash
./deploy/scripts/backup-postgres.sh
ls -lh backups/
```

### Restore from backup
```bash
./deploy/scripts/restore-postgres.sh backups/tradespace_db_YYYYMMDD_HHMMSS.sql.gz
```

### Rolling deployment (zero-downtime)
```bash
git pull origin main
docker compose -f docker-compose.prod.yml up -d --build --no-deps backend
docker compose -f docker-compose.prod.yml up -d --build --no-deps frontend nginx
```

### Rollback
```bash
git checkout <previous-commit-hash>
docker compose -f docker-compose.prod.yml up -d --build
```

---

## 7. Validating the Deployment

```bash
# Check all services are healthy
docker compose -f docker-compose.prod.yml ps

# Test Nginx responds
curl -I https://yourdomain.com

# Test backend API responds
curl https://yourdomain.com/api

# Check backend logs for errors
docker compose -f docker-compose.prod.yml logs backend --tail 50
```

Then work through `docs/PRODUCTION_CHECKLIST.md` to verify all integrations.
