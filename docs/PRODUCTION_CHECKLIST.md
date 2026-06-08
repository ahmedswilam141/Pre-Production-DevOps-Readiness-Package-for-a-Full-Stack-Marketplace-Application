# Production Deployment Checklist

Work through this checklist top-to-bottom before considering the deployment live.

---

## ⬜ Infrastructure
- [ ] VPS provisioned with Ubuntu 22.04 LTS (min 2 vCPUs, 4 GB RAM recommended).
- [ ] Docker and Docker Compose v2 installed (`docker compose version` to verify).
- [ ] UFW firewall enabled; ports 22, 80, and 443 open.
- [ ] Domain DNS A record pointed to the VPS IP address and propagated.

---

## ⬜ Configuration
- [ ] `backend/.env` created from `backend/.env.example` with real production secrets.
- [ ] `.env` created from `.env.example` with production DB credentials.
- [ ] `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` set and verified in Stripe Dashboard.
- [ ] `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_VERIFY_SID` set and verified.
- [ ] `APP_PASSWORD` (Gmail App Password) generated and tested.
- [ ] `SECRET` (JWT secret) replaced with a strong random value (`openssl rand -hex 64`).
- [ ] Firebase `VITE_FIREBASE_*` values set in `frontend/.env` (if Firebase features are required).
- [ ] `VITE_API_URL` set to `https://yourdomain.com/api` in `.env` — this is passed as a **build-time arg**; the frontend image must be (re)built after changing it.
- [ ] `deploy/nginx/tradespace.conf` updated with your real domain name.

---

## ⬜ Security
- [ ] SSL certificate obtained via Certbot: `sudo certbot certonly --standalone -d yourdomain.com`
- [ ] Nginx HTTPS redirect enabled in `tradespace.conf` (uncomment the SSL server block).
- [ ] `DB_PASSWORD` changed from any development placeholder to a strong unique string.
- [ ] Production image built with `docker-compose.prod.yml` (not the dev compose).

---

## ⬜ Database & Data
- [ ] Containers started: `docker compose -f docker-compose.prod.yml up -d --build`
- [ ] Initial database schema applied:
  ```bash
  docker compose -f docker-compose.prod.yml exec backend npx prisma db push
  ```
  *(Note: Prisma migration files are not included in this package. Use `prisma db push` for initial schema creation. See `docs/KNOWN_LIMITATIONS.md` for details.)*
- [ ] Database backup crontab scheduled (daily recommended):
  ```bash
  0 2 * * * /var/www/tradespace/deploy/scripts/backup-postgres.sh
  ```
- [ ] First manual backup verified: `./deploy/scripts/backup-postgres.sh`
- [ ] `backups/` directory permissions set so only the deployment user can read (chmod 700).

---

## ⬜ Final Validation
- [ ] Nginx accessible: `curl -I https://yourdomain.com` → 200 OK.
- [ ] Backend health: `curl https://yourdomain.com/api` → non-5xx response.
- [ ] Frontend loads in browser without console errors.
- [ ] User registration and login flow tested end-to-end.
- [ ] Payment flow verified in **Stripe Test Mode**.
- [ ] Phone verification flow tested via Twilio (if configured).
- [ ] AI moderation tested with a sample image upload (check backend logs for TF.js output).
