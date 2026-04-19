# Tasks: Admin Dashboard with shadcn

**Feature**: Admin Dashboard with shadcn | **Branch**: 002-admin-dashboard
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Summary

Build a standalone web admin dashboard using React + shadcn/ui + Vite that connects to the existing NestJS backend. Dashboard displays platform metrics and allows admins to review security flags.

## Implementation Strategy

**MVP Scope**: User Story 1 (Platform Overview Dashboard) - Provides immediate value with core metrics display.

**Incremental Delivery**:
- Phase 1: Setup (T001-T005) - Project initialization and dependencies
- Phase 2: Foundational (T006-T010) - Types, API client, utilities
- Phase 3: US1 - Dashboard Overview (T011-T020) - Core metrics display
- Phase 4: US2 - Recent Activations (T021-T025) - Activation list
- Phase 5: US3 - Security Alerts (T026-T030) - Security flags with dismiss
- Phase 6: US4 - Auto-Refresh (T031-T033) - Auto-refresh functionality
- Phase 7: Polish (T034-T036) - Edge cases and final polish

---

## Phase 1: Setup

Goal: Initialize project and install dependencies

- [X] T001 Create new Vite + React + TypeScript project at admin-dashboard/
- [X] T002 Install core dependencies (react, react-dom)
- [X] T003 Install dev dependencies (typescript, vite, @types/react)
- [X] T004 Install and configure Tailwind CSS
- [X] T005 Initialize shadcn/ui and install base components (card, button, badge, table, loading-spinner)

---

## Phase 2: Foundational

Goal: Create types, API client, and utility functions (blocking prerequisites for all user stories)

Dependent on: Phase 1

- [X] T006 [P] Define TypeScript types for DashboardResponse, Activation, SecurityFlag in admin-dashboard/src/types/index.ts
- [X] T007 [P] Create API client service with fetch wrapper in admin-dashboard/src/services/api.ts
- [X] T008 [P] Create authentication helper (getToken, clearToken, isAuthenticated) in admin-dashboard/src/lib/auth.ts
- [X] T009 [P] Create utility functions (cn helper for classnames) in admin-dashboard/src/lib/utils.ts
- [X] T010 Create dashboard data hook in admin-dashboard/src/hooks/useDashboard.ts

---

## Phase 3: User Story 1 - Dashboard Overview

Goal: Display platform overview dashboard with four key metrics

Dependent on: Phase 2

**Independent Test**: Load dashboard, verify 4 metric cards display within 3 seconds

- [X] T011 [US1] Create DashboardCard component in admin-dashboard/src/components/DashboardCard.tsx
- [X] T012 [US1] Create StatsGrid component to display metrics in admin-dashboard/src/components/StatsGrid.tsx
- [X] T013 [US1] Implement useDashboard hook to fetch data from /admin/dashboard in admin-dashboard/src/hooks/useDashboard.ts
- [X] T014 [US1] Create loading state component in admin-dashboard/src/components/LoadingState.tsx
- [X] T015 [US1] Create error state component in admin-dashboard/src/components/ErrorState.tsx
- [X] T016 [US1] Build main Dashboard component in admin-dashboard/src/components/Dashboard.tsx
- [X] T017 [US1] Create empty state component in admin-dashboard/src/components/EmptyState.tsx
- [X] T018 [US1] Add refresh button to manual refresh in admin-dashboard/src/components/Dashboard.tsx
- [X] T019 [US1] Integrate all components in App.tsx
- [X] T020 [US1] Test dashboard loads with metrics (manual verification)

---

## Phase 4: User Story 2 - Recent Activations

Goal: Display list of recently activated codes

Dependent on: Phase 2 (can parallel with Phase 3)

**Independent Test**: Navigate to activations section, verify list displays with student info

- [X] T021 [P] [US2] Create ActivationList component in admin-dashboard/src/components/ActivationList.tsx
- [X] T022 [P] [US2] Implement table with shadcn Table component in admin-dashboard/src/components/ActivationList.tsx
- [X] T023 [P] [US2] Format timestamps for display in admin-dashboard/src/components/ActivationList.tsx
- [X] T024 [P] [US2] Add empty state for no activations in admin-dashboard/src/components/ActivationList.tsx
- [X] T025 [P] [US2] Integrate ActivationList in Dashboard component

---

## Phase 5: User Story 3 - Security Alerts

Goal: Display and dismiss security flags

Dependent on: Phase 2 (can parallel with Phase 3)

**Independent Test**: View security flags, click dismiss, verify flag status updates

- [X] T026 [P] [US3] Create SecurityFlagList component in admin-dashboard/src/components/SecurityFlagList.tsx
- [X] T027 [P] [US3] Implement security flag table with actions in admin-dashboard/src/components/SecurityFlagList.tsx
- [X] T028 [P] [US3] Add dismiss button to mark flag as reviewed in admin-dashboard/src/components/SecurityFlagList.tsx
- [X] T029 [P] [US3] Add API call to update flag status in admin-dashboard/src/services/api.ts (already done in Phase 2)
- [X] T030 [P] [US3] Integrate SecurityFlagList in Dashboard component

---

## Phase 6: User Story 4 - Auto-Refresh

Goal: Auto-refresh dashboard data every 60 seconds

Dependent on: Phase 3 (US1 must be working first)

**Independent Test**: Leave dashboard open, verify data refreshes every 60 seconds

- [X] T031 [US4] Implement setInterval auto-refresh in useDashboard hook
- [X] T032 [US4] Add refresh status indicator (last updated timestamp)
- [X] T033 [US4] Handle refresh queue when user clicks during auto-refresh

---

## Phase 7: Polish

Goal: Handle edge cases and final polish

- [X] T034 [P] Handle API unreachable (show error state gracefully)
- [X] T035 [P] Handle authentication failure (redirect to login)
- [X] T036 [P] Handle large numbers formatting (1,000+ displays correctly)

---

## Dependencies

```
Phase 1 (Setup)
  └── Phase 2 (Foundational)
       ├── Phase 3 (US1 - Dashboard Overview) ← MVP
       ├── Phase 4 (US2 - Recent Activations)
       └── Phase 5 (US3 - Security Alerts)
            └── Phase 6 (US4 - Auto-Refresh)
                 └── Phase 7 (Polish)
```

## Parallel Opportunities

| Tasks | Why They Can Run in Parallel |
|-------|------------------------------|
| T006-T010 (Foundational) | No dependencies between them |
| T021-T025 (US2) | Independent from US1, depends only on Phase 2 |
| T026-T030 (US3) | Independent from US1, depends only on Phase 2 |
| T034-T036 (Polish) | Edge case handlers can be added incrementally |

## Task Count Summary

| Phase | User Story | Task Count |
|-------|------------|------------|
| Phase 1 | Setup | 5 |
| Phase 2 | Foundational | 5 |
| Phase 3 | US1 - Dashboard Overview | 10 |
| Phase 4 | US2 - Recent Activations | 5 |
| Phase 5 | US3 - Security Alerts | 5 |
| Phase 6 | US4 - Auto-Refresh | 3 |
| Phase 7 | Polish | 3 |
| **Total** | | **36** |

---

**Generated**: 2026-04-19
