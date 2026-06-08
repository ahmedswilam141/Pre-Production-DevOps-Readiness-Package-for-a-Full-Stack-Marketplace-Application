# Security Policy — TradeSpace

## Reporting a Vulnerability

If you discover a security vulnerability in this project, **do not open a public GitHub issue**. Please report it privately by contacting the project maintainer directly. Include:
- A clear description of the vulnerability
- Steps to reproduce it
- Potential impact assessment

We aim to acknowledge reports within 48 hours and provide a resolution timeline within 7 days.

---

## Security Architecture Overview

### Authentication
- **JWT (JSON Web Tokens)** are used to secure all private API endpoints.
- Tokens are signed with a secret key (`SECRET` env var) and should have a short expiry in production.
- Passwords are hashed with **bcrypt** before storage — plain-text passwords are never persisted.
- Authentication is handled by **Passport.js** with the JWT strategy.

### Transport Security
- In production, all traffic must be served over **HTTPS** via Nginx + Let's Encrypt (Certbot).
- HTTP on port 80 should redirect to HTTPS — update `deploy/nginx/tradespace.conf` to enable this before going live.
- Cookies should be set with `Secure`, `HttpOnly`, and `SameSite=Strict` flags in production.

### API Security
- All user input is validated with **express-validator** before reaching business logic.
- **Helmet.js** is used to set secure HTTP headers (X-Content-Type-Options, HSTS, etc.).
- **CORS** is restricted to `CLIENT_URL` — do not set it to `*` in production.
- SQL injection is prevented via **Prisma's parameterised queries** — raw queries are not used.

### Payment Security
- Payments are processed through **Stripe** — card data never touches our servers.
- Stripe webhook signatures are verified using `STRIPE_WEBHOOK_SECRET` to prevent spoofed events.

### Content Moderation
- Uploaded content passes through the **TradeSpaceAI** layer (MobileNet + NLP) before being accepted.
- A profanity filter and harmful link detector scan text content.

### Rate Limiting
- Rate limiting is not currently implemented at the application layer.
- **Nginx** can provide basic rate limiting — configure `limit_req_zone` in production.
- For robust protection, place a CDN or WAF (e.g., Cloudflare) in front of the server.

---

## Secret Management

### Development
- Use `.env` files **only** on your local machine.
- Never commit `.env` files — they are excluded by `.gitignore`.
- Use `.env.example` files as the template; they contain only safe placeholder values.

### Production
- All secrets must be **rotated** from their development placeholders before going live.
- Store production secrets using one of the following methods (recommended in order):
  1. **Cloud Secret Manager** (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault)
  2. **HashiCorp Vault** (self-hosted)
  3. Encrypted `.env` files on the server, readable only by the deployment user (chmod 600)
- Never log secret values — review application logs before exposing them externally.

### Secret Rotation Checklist
| Secret | How to Rotate |
|---|---|
| `SECRET` (JWT) | Generate new: `openssl rand -hex 64` — triggers all users to re-login |
| `DB_PASSWORD` | Update in PostgreSQL + all `.env` files simultaneously |
| `STRIPE_SECRET_KEY` | Roll key in Stripe Dashboard |
| `STRIPE_WEBHOOK_SECRET` | Re-create webhook in Stripe Dashboard |
| `TWILIO_AUTH_TOKEN` | Rotate in Twilio Console |
| `APP_PASSWORD` (Gmail) | Revoke and re-generate in Google Account settings |
| Firebase credentials | Regenerate in Firebase Console → Project Settings |

---

## Dependency Security

- Dependencies are scanned by **Trivy** on every push via `.github/workflows/security.yml`.
- Secret scanning is performed by **Gitleaks** on every push.
- Run `yarn audit` regularly to check for known CVEs in dependencies.
- Keep `prisma`, `express`, `stripe`, and `passport` updated — these are security-critical packages.

---

## Security Checklist for Contributors

- [ ] Never commit `.env` files or any file containing real credentials.
- [ ] Never log secrets, tokens, or passwords — even in debug logs.
- [ ] Validate all user input using `express-validator` before processing.
- [ ] Use Prisma query methods (not raw SQL) for all database operations.
- [ ] Verify Stripe webhook signatures before processing payment events.
- [ ] Test with `yarn audit` and resolve critical/high CVEs before merging.
- [ ] Ensure any new environment variable is added to `.env.example` with a safe placeholder.
