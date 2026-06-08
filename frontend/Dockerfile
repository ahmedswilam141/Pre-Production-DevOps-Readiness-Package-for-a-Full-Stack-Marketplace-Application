# ─── Stage 1: Build ────────────────────────────────────────────
# Build context: ./frontend
FROM node:20-alpine AS build

WORKDIR /app

# Install dependencies first (layer cache — only re-runs if lockfile changes)
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy remaining source and build
COPY . .

# VITE_API_URL must be passed at build time — Vite bakes it into the bundle.
# Pass via: docker build --build-arg VITE_API_URL=http://yourdomain.com/api
# Default is appropriate for local Docker Compose (routed through Nginx)
ARG VITE_API_URL=http://localhost/api
ENV VITE_API_URL=$VITE_API_URL

RUN yarn build
# Output: /app/dist

# ─── Stage 2: Serve ────────────────────────────────────────────
FROM nginx:alpine

# Copy built assets from Stage 1
COPY --from=build /app/dist /usr/share/nginx/html

# Copy Nginx SPA routing config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
