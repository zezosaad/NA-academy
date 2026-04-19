# Research: Admin Dashboard with shadcn

## Phase 0 Findings

### Technology: shadcn/ui

**Decision**: Use shadcn/ui with React + Vite + TypeScript

**Rationale**: 
- shadcn/ui is a React-only component library
- Existing frontend is Expo/React Native (mobile), not compatible with shadcn
- A new standalone web application is required per clarification
- Vite provides fast development experience

**Alternatives considered**:
- Next.js: More complex, not needed for admin dashboard
- Pure React + CRA: Deprecated, Vite is recommended replacement

---

### Integration: Backend Connection

**Decision**: Connect directly to existing NestJS REST API

**Rationale**:
- Existing `/admin/dashboard` endpoint returns all required data
- JWT authentication already implemented in backend
- No additional backend work needed

**Alternatives considered**:
- GraphQL: Overkill, REST sufficient
- WebSocket: Not needed for dashboard refresh (polling sufficient)

---

### Auto-Refresh Implementation

**Decision**: Polling with 60-second interval using useEffect

**Rationale**:
- Simple to implement
- Sufficient for admin dashboard use case
- SWR/React Query could provide auto-refresh but adds complexity

---

### Deployment

**Decision**: Static build deployed to web server (Vercel/Netlify/traffic)

**Rationale**:
- Vite produces static bundle
- Simple deployment, no server needed
- Can connect to backend via environment variable

---

**Generated**: 2026-04-19