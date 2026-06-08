# ─── Stage 1: Builder ──────────────────────────────────────────
# Uses node:20-slim (Debian-based) instead of Alpine.
# Required because @tensorflow/tfjs-node ships pre-built native
# binaries linked against glibc. Alpine uses musl libc and is
# incompatible with these binaries. See docs/KNOWN_LIMITATIONS.md
FROM node:20-slim AS builder

WORKDIR /app

# System dependencies for Prisma binary engine
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Install all dependencies (including dev — needed for prisma generate)
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Generate Prisma client
COPY prisma ./prisma/
RUN npx prisma generate

# ─── Stage 2: Production runner ────────────────────────────────
FROM node:20-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Install all deps (ts-node is a prod dep — used as the runtime runner)
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy generated Prisma client from builder
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma/client ./node_modules/@prisma/client

# Copy Prisma schema (needed at runtime)
COPY --from=builder /app/prisma ./prisma/

# Copy source and TypeScript config
COPY src ./src
COPY tsconfig.json ./

# NOTE ON RUNTIME:
# tsconfig.json has emitDeclarationOnly:true — plain "tsc" produces only
# .d.ts declaration files, not executable .js. To run the application we
# use ts-node (already a production dependency) with --transpile-only,
# which skips type-checking and compiles TypeScript to CommonJS in-process.
# Type safety is validated by the CI pipeline on every push.

EXPOSE 3000

CMD ["node_modules/.bin/ts-node", "--transpile-only", "src/index.ts"]
