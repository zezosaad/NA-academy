# Quickstart: Admin Dashboard

## Prerequisites

- Node.js 18+
- npm or pnpm
- Access to NestJS backend (running locally or via URL)

## Setup

1. **Create the project**:
   ```bash
   npm create vite@latest admin-dashboard -- --template react-ts
   cd admin-dashboard
   ```

2. **Install dependencies**:
   ```bash
   npm install
   npm install lucide-react class-variance-authority clsx tailwind-merge
   npm install -D tailwindcss postcss autoprefixer
   npx tailwindcss init -p
   ```

3. **Initialize shadcn/ui**:
   ```bash
   npx shadcn@latest init
   npx shadcn@latest add card table button badge loading-spinner
   ```

4. **Configure Tailwind**:
   Update `tailwind.config.js` with shadcn paths as per documentation.

5. **Configure environment**:
   Create `.env`:
   ```
   VITE_API_URL=http://localhost:3000
   ```

## Run

```bash
npm run dev
```

## Build

```bash
npm run build
```

## Connect to Backend

1. Ensure backend is running (`cd back && npm run start:dev`)
2. Login as admin user to obtain JWT token
3. Dashboard fetches data from `/admin/dashboard` with JWT auth
4. Token stored in localStorage or cookies

---

**Generated**: 2026-04-19