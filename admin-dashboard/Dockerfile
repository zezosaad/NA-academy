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

COPY package.json package-lock.json ./
RUN npm install --no-audit --no-fund

COPY . .
RUN npm run build

# ──────────────────────────────────────────────────────────────────────
# Stage 2: serve static assets with nginx, proxy /api and /socket.io
# ──────────────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /admin/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

RUN sed -i 's/listen 80 default_server/listen 8080 default_server/' /etc/nginx/nginx.conf

EXPOSE 8080
