<!--
SYNC IMPACT REPORT
==================
Version change: (none) → 1.0.0
Type: Initial ratification (MAJOR)

Modified principles: (none — first adoption)
Added sections:
  - Core Principles (I–V)
  - Technology & Quality Standards
  - Development Workflow
  - Governance
Removed sections: (none)

Templates reviewed for consistency:
  ✅ .specify/templates/plan-template.md — "Constitution Check" gate section is
     generic and will be instantiated per-feature against the five principles
     below. No edit needed.
  ✅ .specify/templates/spec-template.md — already enforces prioritized user
     stories, measurable Success Criteria, and acceptance scenarios, aligning
     with Principle II (Spec-Before-Code) and Principle III (Independent,
     Priority-Ordered Slices). No edit needed.
  ✅ .specify/templates/tasks-template.md — already groups tasks by user story
     with independent-MVP checkpoints, aligning with Principle III. No edit
     needed.
  ✅ .specify/templates/commands/* — not present as a directory; per-skill
     command files live under .claude/skills/. Reviewed speckit-constitution
     skill; no outdated agent-specific references requiring rewrite.
  ✅ AGENTS.md / runtime guidance — no stale principle references found.

Deferred TODOs: (none)
-->

# NA-Academy Constitution

NA-Academy is a mobile-first learning sanctuary comprising a NestJS API
(`back/`), an Expo/React Native flagship mobile app (`front/`), a Vite +
React + shadcn/ui admin dashboard (`admin-dashboard/`), and a Flutter
companion (`na_app/`). This constitution governs how features are specified,
designed, built, and reviewed across all surfaces.

## Core Principles

### I. Scholarly Warmth by Default (NON-NEGOTIABLE)

Every user-facing surface MUST conform to `DESIGN.md` and `DESIGN.json`:
the parchment palette, Fraunces serif for display/headline tiers, Inter for
body/label, pill-shaped primary buttons, 12–18px radii on interactive
surfaces, and the **Rarity Rule** — Sage-Teal (`#3F7D78`) on ≤10% of any
given screen. Pure black (`#000`) and pure white (`#FFF`) MUST NOT appear on
large surfaces. Generic-SaaS patterns (vibrant blue primaries, Inter-only
headings, sharp corners on CTAs, dense grey tables) are forbidden without
explicit justification in the plan's Complexity Tracking.

**Rationale:** The product's only real differentiation from competing
ed-tech is its calm, archival aesthetic. Drift from the design system is
not a cosmetic bug — it erodes the brand and the focus ergonomics the
product exists to provide.

### II. Spec-Before-Code

Every non-trivial feature MUST begin as a specification under
`specs/NNN-feature-name/spec.md` produced via the spec-kit flow
(`/speckit.specify` → `/speckit.clarify` → `/speckit.plan` →
`/speckit.tasks` → `/speckit.implement`). A spec is "non-trivial" when it
introduces new endpoints, new schemas, new screens, cross-surface state,
or behavioural changes visible to users. Typo fixes, dependency bumps, and
localized refactors are exempt. Implementation tasks MUST NOT be opened
before `plan.md` passes its Constitution Check.

**Rationale:** Traceability from user story → task → commit is the only
thing that keeps a four-surface codebase coherent. Skipping the spec makes
the MVP-first delivery model (see Principle III) impossible to enforce.

### III. Independent, Priority-Ordered Slices

User stories in every spec MUST be ordered P1..Pn where P1 alone is a
viable MVP and each subsequent priority adds value without regressing
earlier priorities. Tasks MUST be grouped by user story so each slice is
independently implementable, testable, and demoable. Cross-story coupling
that prevents independent delivery of any priority is a constitution
violation and MUST be documented and justified in the plan's Complexity
Tracking table.

**Rationale:** The spec-kit templates already enforce this structure; this
principle makes the intent binding. Independent slices let us ship
learning value incrementally instead of shipping half-working features
together.

### IV. Contract-Driven Multi-Surface Consistency

The NestJS API (`back/`) is the single source of truth for data shape and
behaviour. Every new or changed endpoint MUST (a) be expressed as a DTO
with `class-validator` rules, (b) appear in the Swagger document, and
(c) be the shape consumed by the mobile, admin, and Flutter clients —
clients MUST NOT define divergent ad-hoc types for the same resource.
Breaking contract changes (removed fields, changed types, renamed
endpoints) require a version bump on the API surface and a migration note
in the spec that introduces them.

**Rationale:** Four clients against one schema is the main source of
drift risk. A documented, validated contract is the cheapest way to keep
all surfaces truthful.

### V. Mobile-First, Accessible, Calm

The Expo mobile app is the flagship surface. Every user-facing feature
MUST be designed and validated on a mobile viewport first, with:
- touch targets ≥ 44×44 pt for interactive controls;
- `prefers-reduced-motion` honoured for non-essential transitions;
- Parchment-to-Ink contrast preserved (no low-contrast grey-on-grey body
  text) to support long reading sessions;
- one-handed reachability for primary actions on common phone sizes.

Desktop/admin layouts adapt from the mobile baseline, not the reverse.

**Rationale:** Students study on phones in fragmented sessions. A feature
that only works well on a laptop is a feature that fails the core user.

## Technology & Quality Standards

- **Backend (`back/`)**: NestJS 11, Node 20+, MongoDB via Mongoose, JWT
  auth (`@nestjs/jwt` + Passport), WebSocket chat via
  `@nestjs/platform-socket.io`, Swagger on all routes, rate limiting via
  `@nestjs/throttler`. `npm run lint` MUST pass before merge.
- **Mobile (`front/`)**: Expo SDK 54+, React 19, `expo-router` for
  navigation, `expo-secure-store` for auth tokens, `react-hook-form` +
  `zod` (via `@hookform/resolvers`) for forms. `npm run lint` MUST pass.
- **Admin (`admin-dashboard/`)**: Vite + React 19 + TypeScript, shadcn/ui
  on top of Tailwind + Radix primitives, `react-router-dom` v7. `tsc -b`
  and `npm run lint` MUST pass.
- **Flutter (`na_app/`)**: `flutter analyze` MUST pass before merge.
- **Secrets & config**: `.env` files MUST NOT be committed. Credentials,
  JWT signing keys, and DB connection strings live only in environment
  configuration.
- **Accessibility**: per Principle V, the mobile baseline is authoritative.
- **Data handling**: Mongoose schemas are the canonical model layer on the
  server; clients consume DTO shapes, never raw Mongoose documents.

## Development Workflow

- **Branching**: Feature branches cut from `main` via the spec-kit git
  hook. Branch names follow the `NNN-feature-name` convention emitted by
  `/speckit.specify`.
- **Spec-kit loop**: `/speckit.constitution` → `/speckit.specify` →
  `/speckit.clarify` (when requirements are ambiguous) → `/speckit.plan`
  → `/speckit.tasks` → `/speckit.implement`, with `/speckit.analyze`
  before opening a PR.
- **Constitution Check gate**: Every `plan.md` MUST include an explicit
  Constitution Check that enumerates the five principles above and marks
  each as PASS, PASS-WITH-NOTES, or VIOLATION (requiring a row in
  Complexity Tracking).
- **Design review**: UI-touching PRs MUST include a screenshot or short
  screen recording on a mobile viewport and reference the DESIGN.md
  tokens used. Reviewers verify conformance to Principle I.
- **Code review**: PRs require at least one review. Reviewers verify
  Constitution Check validity, contract alignment (Principle IV), and
  that tasks map back to user stories in the spec.
- **CI / pre-merge**: lint and type-check on all packages touched by the
  PR. Hooks (`--no-verify` bypass) MUST NOT be skipped without maintainer
  approval.

## Governance

This constitution supersedes ad-hoc conventions. When any document, habit,
or prior decision conflicts with a principle defined here, this document
wins.

**Amendment procedure.** Changes are proposed by editing
`.specify/memory/constitution.md` via the `/speckit.constitution` skill.
The resulting PR MUST contain (a) the edited constitution with an updated
Sync Impact Report at the top, (b) a version bump per the policy below,
and (c) any template updates the change triggers. Amendments merge under
the same review rules as any other PR.

**Versioning policy.**
- **MAJOR** — a principle is removed, renumbered, or redefined in a way
  that invalidates prior Constitution Checks.
- **MINOR** — a new principle or a new binding section is added, or an
  existing principle's scope materially expands.
- **PATCH** — wording, clarification, typo, or non-semantic refinement
  that preserves the meaning of every principle.

**Compliance review.** Every PR's Constitution Check is the compliance
moment; there is no separate audit. Violations recorded in Complexity
Tracking without a convincing justification are grounds to block merge.
Runtime agent guidance lives in `AGENTS.md` and per-surface READMEs; those
documents MUST defer to this constitution where they overlap.

**Version**: 1.0.0 | **Ratified**: 2026-04-24 | **Last Amended**: 2026-04-24
