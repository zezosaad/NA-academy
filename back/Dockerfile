# syntax=docker/dockerfile:1.7
#
# Standalone NestJS backend image.
# Build context expected: the back/ directory (see docker-compose at the repo root).

ARG NODE_VERSION=20-alpine

# ──────────────────────────────────────────────────────────────────────
# Stage 1: build
# ──────────────────────────────────────────────────────────────────────
FROM node:${NODE_VERSION} AS builder
WORKDIR /usr/src/app

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY tsconfig*.json nest-cli.json ./
COPY src/ ./src/
RUN npm run build

# Strip dev deps from the resolved tree so we can copy them straight to runtime.
RUN npm prune --omit=dev && npm cache clean --force

# ──────────────────────────────────────────────────────────────────────
# Stage 2: runtime
# ──────────────────────────────────────────────────────────────────────
FROM node:${NODE_VERSION} AS runtime
WORKDIR /usr/src/app

ENV NODE_ENV=production \
    PORT=3000

# Run as the unprivileged node user that the official image ships with.
COPY --chown=node:node --from=builder /usr/src/app/dist          ./dist
COPY --chown=node:node --from=builder /usr/src/app/node_modules  ./node_modules
COPY --chown=node:node --from=builder /usr/src/app/package.json  ./package.json

USER node

EXPOSE 3000

CMD ["node", "dist/main.js"]
