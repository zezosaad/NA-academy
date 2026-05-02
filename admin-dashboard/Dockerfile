# syntax=docker/dockerfile:1.7
#
# Standalone admin dashboard image.
# Build context expected: the admin-dashboard/ directory.

ARG NODE_VERSION=20-alpine

# ──────────────────────────────────────────────────────────────────────
# Stage 1: build the Vite SPA
# ──────────────────────────────────────────────────────────────────────
FROM node:${NODE_VERSION} AS builder
WORKDIR /admin

# Public API origin for browser requests (no trailing slash). Required for Docker/production builds.
ARG VITE_API_URL=http://localhost:3000
ENV VITE_API_URL=${VITE_API_URL}

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY . .
RUN npm run build

# ──────────────────────────────────────────────────────────────────────
# Stage 2: serve static assets with nginx as a non-root user
# ──────────────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

# Static SPA assets.
RUN rm -rf /usr/share/nginx/html/*
COPY --chown=nginx:nginx --from=builder /admin/dist /usr/share/nginx/html
COPY --chown=nginx:nginx nginx.conf /etc/nginx/nginx.conf

# Make every directory nginx writes to owned by the unprivileged `nginx` user.
# /tmp holds the PID + temp paths (see nginx.conf), /var/cache/nginx is the proxy cache.
RUN chown -R nginx:nginx /var/cache/nginx /usr/share/nginx/html \
    && touch /tmp/nginx.pid \
    && chown nginx:nginx /tmp/nginx.pid

USER nginx

EXPOSE 8080
