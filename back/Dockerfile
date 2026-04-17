# Build Stage
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci

COPY tsconfig*.json ./
COPY src/ src/
RUN npm run build

# Production Stage
FROM node:20-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci --only=production

COPY --from=builder /usr/src/app/dist ./dist

EXPOSE 3000

ENV NODE_ENV=production
CMD ["node", "dist/main.js"]
