# Quickstart: NA-Academy Backend Platform

**Date**: 2026-04-17

---

## Prerequisites

- **Node.js** 20 LTS (`node -v` should show `v20.x.x`)
- **npm** 10+ or **pnpm** 8+
- **MongoDB** 7.x running locally or a connection string to a remote instance
- **Git**

---

## Initial Setup

```bash
# 1. Clone and enter the project
git clone <repository-url>
cd NA-Academy

# 2. Install dependencies
npm install

# 3. Copy environment template
cp .env.example .env
```

---

## Environment Configuration

Create a `.env` file in the project root with the following variables:

```env
# Application
PORT=3000
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb://localhost:27017/na-academy

# JWT
JWT_SECRET=your-secure-secret-key-min-32-chars
JWT_ACCESS_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d

# Exam Security
EXAM_HMAC_SECRET=your-exam-hmac-secret-min-32-chars

# File Upload Limits
MAX_VIDEO_SIZE_MB=2048
MAX_IMAGE_SIZE_MB=20

# Rate Limiting
ACTIVATION_RATE_LIMIT=5
ACTIVATION_RATE_WINDOW_MINUTES=15

# GridFS
GRIDFS_VIDEO_CHUNK_SIZE=1048576
GRIDFS_CHAT_CHUNK_SIZE=261120
```

---

## Running the Application

```bash
# Development (with hot reload)
npm run start:dev

# Production build
npm run build
npm run start:prod

# Run tests
npm run test          # unit tests
npm run test:e2e      # end-to-end tests
npm run test:cov      # coverage report
```

---

## API Documentation

Once the server is running, Swagger UI is available at:

```
http://localhost:3000/api/docs
```

All endpoints, DTOs, and response schemas are documented interactively.

---

## Key Development Workflows

### Creating an Admin User

On first run, seed an admin user manually or via a seed script:

```bash
npm run seed:admin -- --email admin@academy.com --password AdminPass123
```

### Generating Activation Codes

1. Log in as admin via `POST /api/v1/auth/login`
2. Create a subject via `POST /api/v1/subjects`
3. Generate codes via `POST /api/v1/activation-codes/subject/generate`
4. Export codes via `POST /api/v1/activation-codes/batch/:batchId/export?format=xlsx`

### Testing Video Streaming

1. Upload a video via `POST /api/v1/media/upload` (multipart)
2. Activate a subject code as a student
3. Stream via `GET /api/v1/media/:id/stream` with `Range` header

### Testing Real-Time Chat

1. Register a student and a teacher
2. Activate a subject code (student must have access to teacher's subject)
3. Connect to WebSocket namespace `/chat` with JWT
4. Send `send_message` event with `recipientId`

---

## Project Module Map

| Module | Purpose | Key Files |
|--------|---------|-----------|
| `auth` | Registration, login, JWT, sessions | `auth.controller.ts`, `jwt.strategy.ts` |
| `users` | User CRUD, role management | `users.controller.ts` |
| `subjects` | Subject + bundle CRUD | `subjects.controller.ts` |
| `exams` | Exam CRUD, question mgmt, submissions | `exams.controller.ts` |
| `activation-codes` | Code generation, activation, export | `activation-codes.service.ts` |
| `media` | GridFS upload/stream, byte-range | `media.controller.ts`, `media.service.ts` |
| `chat` | Socket.io gateway, messages | `chat.gateway.ts`, `chat.service.ts` |
| `analytics` | Aggregation pipelines, dashboards | `analytics.service.ts` |
| `devices` | Device registration, lock/reset | `devices.service.ts` |
| `security` | Flag reporting, session termination | `security.service.ts` |
| `admin` | Dashboard, monitoring endpoints | `admin.controller.ts` |

---

## Docker (Optional)

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
EXPOSE 3000
CMD ["node", "dist/main"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - MONGODB_URI=mongodb://mongo:27017/na-academy
    depends_on:
      - mongo

  mongo:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db

volumes:
  mongo-data:
```

```bash
docker-compose up -d
```
