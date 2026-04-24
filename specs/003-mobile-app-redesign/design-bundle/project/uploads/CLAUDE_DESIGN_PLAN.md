# NA-Academy Front — Claude-Inspired Redesign Plan

Target: rebuild `front/` (Expo + React Native + expo-router) with a Claude.ai-inspired visual language — warm, minimal, conversational, content-first.

Stack stays: **Expo 54 / React Native 0.81 / expo-router 6 / TypeScript / Zod / react-hook-form / socket.io-client**.

---

## 1. Design Language (Claude-Inspired)

### 1.1 Color Tokens

| Token               | Light            | Dark             | Purpose                         |
| ------------------- | ---------------- | ---------------- | ------------------------------- |
| `bg.canvas`         | `#FAF9F7`        | `#1F1E1D`        | App background (warm off-white) |
| `bg.surface`        | `#FFFFFF`        | `#262524`        | Cards, sheets                   |
| `bg.sunken`         | `#F5F4EF`        | `#191817`        | Input fields, chat bubbles (me) |
| `bg.elevated`       | `#FFFFFF`        | `#2E2D2B`        | Modals, popovers                |
| `border.subtle`     | `#E8E6DF`        | `#3A3937`        | Dividers, card edges            |
| `border.strong`     | `#C7C3B8`        | `#4E4C48`        | Focus rings, active inputs      |
| `text.primary`      | `#1F1E1D`        | `#F5F4EF`        | Body copy                       |
| `text.secondary`    | `#6B6A66`        | `#A8A69E`        | Meta, captions                  |
| `text.muted`        | `#8F8D87`        | `#77756F`        | Placeholders, timestamps        |
| `accent.primary`    | `#C96442`        | `#D97757`        | CTAs, active states (Claude coral) |
| `accent.primaryFg`  | `#FFFFFF`        | `#1F1E1D`        | Text on accent                  |
| `accent.soft`       | `#F4E4DB`        | `#3A2A22`        | Accent tints, highlighted rows  |
| `success`           | `#3F7D58`        | `#6FA585`        |                                 |
| `warning`           | `#B8860B`        | `#E4B23E`        |                                 |
| `danger`            | `#B5443A`        | `#E06C5E`        |                                 |

Expose via `constants/theme.ts` as `lightTheme` / `darkTheme`. Replace current ad-hoc `colors.primary` usage.

### 1.2 Typography

Use `expo-font` to load:

- **Display / Serif:** `Tiempos Headline` or free alt `Source Serif 4` — for H1/H2, auth hero, empty-state titles.
- **Body / Sans:** `Inter` — body, buttons, inputs.
- **Mono:** `JetBrains Mono` — code blocks in chat.

Scale (`constants/typography.ts`):

```
display-lg  32 / 40   serif   -0.4 tracking
display     26 / 34   serif   -0.3
h1          22 / 30   sans    600
h2          18 / 26   sans    600
body        16 / 24   sans    400
body-sm     14 / 20   sans    400
caption     12 / 16   sans    500  +0.2 tracking
mono        14 / 22   mono
```

### 1.3 Shape & Elevation

- Radius: `sm 8` / `md 12` / `lg 16` / `xl 24` / `pill 999`.
- Cards: `radius.lg`, 1px `border.subtle`, no shadow by default; subtle shadow `0 1 2 rgba(0,0,0,.04)` on elevated.
- Chat bubbles: `radius.lg` with one corner set to `sm` (tail side).
- Buttons: pill for primary CTA, `radius.md` for secondary.

### 1.4 Motion

- Use `react-native-reanimated` (already installed).
- Default easing: `Easing.bezier(0.2, 0.8, 0.2, 1)`, duration `180ms`.
- Page transitions: soft fade + 8px translateY.
- Chat message enter: opacity 0→1 + translateY 4px, `220ms`.
- Tab press: haptic light (`expo-haptics`) + 0.96 scale.

### 1.5 Voice & Copy

- Conversational, sentence case, short. "New chat" not "CREATE NEW CHAT".
- Empty states are warm: a serif headline + one helpful action.
- No emoji in UI.

---

## 2. Target Folder Structure

```
front/
├── app/                              # expo-router routes only
│   ├── _layout.tsx                   # Providers + root Stack
│   ├── +not-found.tsx
│   ├── (auth)/
│   │   ├── _layout.tsx
│   │   ├── onboarding.tsx
│   │   ├── login.tsx
│   │   ├── register.tsx
│   │   └── forgot-password.tsx       # NEW
│   └── (app)/                        # RENAMED from (tabs) — tabs live inside
│       ├── _layout.tsx               # Tab bar (Claude-style, label-less pill)
│       ├── (home)/
│       │   ├── _layout.tsx
│       │   └── index.tsx             # Dashboard / "Today"
│       ├── subjects/
│       │   ├── _layout.tsx
│       │   ├── index.tsx             # Subject grid
│       │   └── [id].tsx              # Subject detail + lessons
│       ├── exams/
│       │   ├── _layout.tsx
│       │   ├── index.tsx             # Exam list
│       │   ├── [id].tsx              # Take exam
│       │   └── result.tsx
│       ├── chat/
│       │   ├── _layout.tsx
│       │   ├── index.tsx             # Conversation list
│       │   └── [conversationId].tsx  # Thread (Claude-style bubbles)
│       └── profile/
│           ├── _layout.tsx
│           ├── index.tsx
│           ├── activate.tsx
│           ├── analytics.tsx
│           ├── settings.tsx          # NEW
│           └── admin/
│               └── index.tsx
│
├── src/                              # NEW — everything non-route here
│   ├── design-system/                # Claude-inspired primitives
│   │   ├── theme/
│   │   │   ├── colors.ts
│   │   │   ├── typography.ts
│   │   │   ├── spacing.ts            # 4pt grid: 0,4,8,12,16,20,24,32,40,56
│   │   │   ├── radius.ts
│   │   │   ├── elevation.ts
│   │   │   ├── motion.ts
│   │   │   ├── index.ts              # unified Theme type
│   │   │   └── ThemeProvider.tsx     # resolves light/dark via useColorScheme
│   │   ├── primitives/               # atoms
│   │   │   ├── Text.tsx              # variant="display|h1|body|caption"
│   │   │   ├── Box.tsx               # View + theme padding/bg helpers
│   │   │   ├── Stack.tsx             # VStack / HStack with gap
│   │   │   ├── Pressable.tsx         # haptic + pressed opacity
│   │   │   ├── Divider.tsx
│   │   │   └── Icon.tsx              # lucide wrapper (size/stroke from theme)
│   │   ├── components/               # molecules
│   │   │   ├── Button.tsx            # variants: primary|secondary|ghost|danger
│   │   │   ├── IconButton.tsx
│   │   │   ├── Input.tsx             # label + hint + error, autogrow
│   │   │   ├── TextArea.tsx
│   │   │   ├── Select.tsx
│   │   │   ├── Checkbox.tsx
│   │   │   ├── RadioGroup.tsx
│   │   │   ├── Switch.tsx
│   │   │   ├── Card.tsx
│   │   │   ├── ListRow.tsx           # settings/profile rows
│   │   │   ├── Badge.tsx
│   │   │   ├── Avatar.tsx
│   │   │   ├── Chip.tsx
│   │   │   ├── ProgressBar.tsx
│   │   │   ├── Skeleton.tsx
│   │   │   ├── Toast.tsx             # wraps react-native-toast-message
│   │   │   ├── BottomSheet.tsx
│   │   │   ├── Dialog.tsx
│   │   │   ├── Tabs.tsx              # segmented, Claude-style
│   │   │   ├── EmptyState.tsx
│   │   │   └── Header.tsx            # screen header w/ back + title
│   │   └── index.ts
│   │
│   ├── features/                     # domain-scoped, colocated
│   │   ├── auth/
│   │   │   ├── components/
│   │   │   │   ├── AuthHero.tsx
│   │   │   │   ├── OnboardingSlide.tsx
│   │   │   │   ├── LoginForm.tsx
│   │   │   │   └── RegisterForm.tsx
│   │   │   ├── hooks/
│   │   │   │   └── useAuth.ts        # moved from hooks/
│   │   │   ├── services/
│   │   │   │   ├── auth.service.ts
│   │   │   │   └── activation.service.ts
│   │   │   ├── validations/auth.validation.ts
│   │   │   └── types.ts
│   │   ├── chat/
│   │   │   ├── components/
│   │   │   │   ├── ChatBubble.tsx           # Claude bubble (user right, AI left w/ avatar)
│   │   │   │   ├── MessageComposer.tsx      # autogrow input + send + stop
│   │   │   │   ├── TypingIndicator.tsx      # 3-dot breathing
│   │   │   │   ├── ConversationRow.tsx
│   │   │   │   ├── MarkdownRenderer.tsx     # code blocks, lists, links
│   │   │   │   └── StreamingCursor.tsx
│   │   │   ├── hooks/useChat.ts
│   │   │   ├── services/chat.service.ts
│   │   │   ├── contexts/ChatContext.tsx
│   │   │   └── types.ts
│   │   ├── subjects/
│   │   │   ├── components/
│   │   │   │   ├── SubjectCard.tsx
│   │   │   │   ├── SubjectHeader.tsx
│   │   │   │   └── LessonItem.tsx
│   │   │   ├── hooks/useSubjects.ts
│   │   │   ├── services/subjects.service.ts
│   │   │   └── types.ts
│   │   ├── exams/
│   │   │   ├── components/
│   │   │   │   ├── ExamCard.tsx
│   │   │   │   ├── QuestionCard.tsx
│   │   │   │   ├── ExamTimer.tsx
│   │   │   │   ├── ExamProgressBar.tsx
│   │   │   │   └── ResultSummary.tsx
│   │   │   ├── hooks/useExams.ts
│   │   │   ├── services/exams.service.ts
│   │   │   └── types.ts
│   │   ├── media/
│   │   │   ├── components/VideoPlayer.tsx
│   │   │   └── services/media.service.ts
│   │   ├── analytics/
│   │   │   ├── components/
│   │   │   │   ├── StatTile.tsx
│   │   │   │   └── ProgressRing.tsx
│   │   │   └── services/analytics.service.ts
│   │   └── profile/
│   │       └── components/ProfileHeader.tsx
│   │
│   ├── shared/
│   │   ├── api/
│   │   │   ├── client.ts             # axios instance + interceptors (was services/api.ts)
│   │   │   ├── endpoints.ts          # typed endpoint map
│   │   │   └── errors.ts             # normalize error shape
│   │   ├── storage/
│   │   │   ├── secure.ts             # expo-secure-store wrapper
│   │   │   └── tokens.ts             # was utils/auth-token.ts
│   │   ├── hooks/
│   │   │   ├── useTheme.ts
│   │   │   ├── useHaptics.ts
│   │   │   ├── useKeyboard.ts
│   │   │   └── useDebounce.ts
│   │   ├── i18n/                     # optional ar/en, RTL aware
│   │   │   ├── index.ts
│   │   │   ├── ar.json
│   │   │   └── en.json
│   │   ├── contexts/
│   │   │   └── AppDialogContext.tsx
│   │   └── utils/
│   │       ├── date.ts
│   │       ├── format.ts
│   │       └── logger.ts
│   │
│   └── navigation/
│       ├── TabBar.tsx                # custom Claude-style tab bar
│       └── linking.ts
│
├── assets/
│   ├── fonts/                        # Inter, SourceSerif4, JetBrainsMono
│   ├── images/
│   └── lottie/
│
├── app.json
├── tsconfig.json                     # "@/*": "src/*", "@app/*": "app/*"
├── eslint.config.js
└── package.json
```

**Migration mapping (current → new):**

| Current                                     | New                                               |
| ------------------------------------------- | ------------------------------------------------- |
| `components/ChatBubble.tsx`                 | `src/features/chat/components/ChatBubble.tsx`     |
| `components/SubjectCard.tsx`                | `src/features/subjects/components/SubjectCard.tsx`|
| `components/ExamCard.tsx`, `QuestionCard`   | `src/features/exams/components/...`               |
| `components/VideoPlayer.tsx`                | `src/features/media/components/VideoPlayer.tsx`   |
| `components/CustomInput.tsx`                | `src/design-system/components/Input.tsx`          |
| `components/EmptyState.tsx`                 | `src/design-system/components/EmptyState.tsx`     |
| `components/ProgressBar.tsx`                | `src/design-system/components/ProgressBar.tsx`    |
| `components/SkeletonLoader.tsx`             | `src/design-system/components/Skeleton.tsx`       |
| `contexts/AuthContext.tsx`                  | `src/features/auth/contexts/AuthContext.tsx`      |
| `contexts/ChatContext.tsx`                  | `src/features/chat/contexts/ChatContext.tsx`      |
| `contexts/AppDialogContext.tsx`             | `src/shared/contexts/AppDialogContext.tsx`        |
| `hooks/*`                                   | Per-feature `src/features/*/hooks/`               |
| `services/*`                                | Per-feature `src/features/*/services/`            |
| `services/api.ts`                           | `src/shared/api/client.ts`                        |
| `utils/auth-token.ts`                       | `src/shared/storage/tokens.ts`                    |
| `validations/*`                             | Per-feature `src/features/*/validations/`         |
| `types/*`                                   | Per-feature `src/features/*/types.ts`             |
| `constants/helpers.ts`                      | Split into `src/design-system/theme/*`            |
| `sheets/*`                                  | Colocated with screens (`*.styles.ts` next to screen) |

---

## 3. Screen-by-Screen Redesign

### 3.1 Onboarding (`(auth)/onboarding.tsx`)
- 3-slide horizontal pager, warm off-white background.
- Each slide: a serif headline + one-line body + a single illustration (lottie or SVG).
- Bottom: pill primary "Get started", ghost "I have an account".
- Pagination dots in `accent.primary`.

### 3.2 Login / Register / Forgot
- Single-column, generous top padding.
- Serif `display` title ("Welcome back." / "Create your account.").
- `Input` with floating label, 1px `border.subtle`, focus → `border.strong`.
- Primary pill button full-width. Secondary as ghost text link.
- Inline error copy in `danger`, `caption` size.

### 3.3 Home / Today (`(app)/(home)/index.tsx`)
- Greeting header: serif "Good afternoon, {name}".
- Cards: "Continue learning" (last subject), "Today's exam", "Recent chats".
- Horizontal scroll of subject cards, 1.5-column peek.
- Quick action: floating "+ New chat" pill bottom-right.

### 3.4 Subjects list & detail
- Grid of `SubjectCard` (title, short description, progress ring, chip with lesson count).
- Detail: serif title, progress ring, list of lessons via `ListRow` with status dot (done/active/locked).

### 3.5 Exams
- List: grouped sections ("Available", "Completed"). `ExamCard` = title, duration, question count, subtle chip.
- Take exam: sticky top `ExamTimer` + `ExamProgressBar`, one `QuestionCard` per screen, swipe/next button.
- Result: serif score, `ProgressRing`, per-question review collapsible.

### 3.6 Chat (Claude-style, the star of the redesign)
- **List screen:** rows = avatar + title + last message preview + time. Empty state: "Start a conversation" with a big compose button.
- **Thread screen:**
  - Plain warm background, no bubbles for the AI — just left-indented text with a small avatar, like Claude.
  - User messages: right-aligned pill with `bg.sunken`.
  - AI messages: left-aligned, full-width text, supports markdown (headings, lists, code blocks in `mono`).
  - `StreamingCursor` (blinking block) while tokens arrive.
  - Composer: autogrow textarea pinned above keyboard, send icon becomes stop icon mid-stream, attachment button (future).
  - Haptic on send.

### 3.7 Profile
- Header: avatar, name (serif), email, role chip.
- `ListRow` items: Activate, Analytics, Settings, Admin (if role), Sign out (danger).
- Settings screen (NEW): theme (system/light/dark), language (en/ar), notifications, about.
- Analytics: stat tiles grid + progress rings for each subject.

### 3.8 Navigation chrome
- **Tab bar:** custom `TabBar.tsx` — floating pill at the bottom with 5 icon-only items, active item shows `accent.soft` background and `accent.primary` icon. No labels. Haptic on change.
- **Screen header:** minimal — back chevron left, optional title centered in `body` weight 600, optional right action. 44pt tall, hairline bottom border.

---

## 4. Form, Validation, Networking

- **Forms:** keep `react-hook-form` + `zod` via `@hookform/resolvers`. All schemas in `features/*/validations/`.
- **Errors:** every form field renders error via `Input`'s `error` prop; top-level submit errors go to `Toast`.
- **API:** `src/shared/api/client.ts` axios instance with:
  - request interceptor: inject token from `secure-store`.
  - response interceptor: normalize to `{ ok, data, error }`.
  - 401 → clear token + redirect `/auth/login`.
- **Realtime chat:** keep `socket.io-client`. Wrap in `ChatContext` with `onToken`, `onDone`, `onError`.

---

## 5. Accessibility & RTL

- All `Pressable` have `accessibilityRole` + `accessibilityLabel`.
- Hit slop min 44x44.
- Respect `useColorScheme()` + manual override from settings.
- Arabic RTL: `I18nManager.forceRTL` when `lang=ar`; mirror chevrons; serif font with Arabic support (`IBM Plex Sans Arabic` as fallback).
- Dynamic type: `Text` scales with `PixelRatio.getFontScale()` up to 1.3x.

---

## 6. Implementation Phases

**Phase 0 — Scaffolding (½ day)**
- Create `src/` tree, add `@/*` tsconfig path, install fonts.
- Port `constants/helpers.ts` into `src/design-system/theme/*`.
- Add `ThemeProvider` and wire in `app/_layout.tsx` (replace inline gradient/blur).

**Phase 1 — Design System (2 days)**
- Build primitives (`Text`, `Box`, `Stack`, `Pressable`, `Icon`).
- Build components (`Button`, `Input`, `Card`, `ListRow`, `Badge`, `Skeleton`, `Toast`, `BottomSheet`, `EmptyState`, `Header`).
- Storybook-style `app/_dev/design.tsx` route to visually verify (dev only).

**Phase 2 — Auth flow (1 day)**
- Move auth files into `src/features/auth/`.
- Rebuild Onboarding / Login / Register with new primitives.
- Add Forgot Password screen.

**Phase 3 — Shell & Tabs (½ day)**
- Rename `(tabs)` → `(app)`.
- Build custom `TabBar.tsx`, new `Header`.
- Add Home/Today dashboard screen.

**Phase 4 — Feature migrations (2 days)**
- Subjects → new cards + detail.
- Exams → take-exam flow polish (timer, progress, results).
- Profile + Settings + Analytics.

**Phase 5 — Chat redesign (1.5 days)**
- Claude-style thread UI, markdown renderer, streaming cursor, autogrow composer.
- Conversation list + empty state.

**Phase 6 — Polish (1 day)**
- Dark mode pass.
- Haptics + motion pass.
- RTL pass.
- Accessibility audit.

Total: ~8.5 working days.

---

## 7. Deletion / Cleanup Checklist

After each phase, delete the old mirror file to prevent drift — don't leave backwards-compat shims:

- [ ] `components/` (entire folder)
- [ ] `contexts/` (entire folder)
- [ ] `hooks/`
- [ ] `services/`
- [ ] `validations/`
- [ ] `types/`
- [ ] `utils/`
- [ ] `constants/helpers.ts`
- [ ] `sheets/` (styles colocated now)

Keep: `app/`, `assets/`, `app.json`, `tsconfig.json`, `package.json`, `eslint.config.js`.

---

## 8. Open Questions

1. Dark mode — ship at launch or phase 6 only?
2. i18n — Arabic required now, or English-only v1?
3. Fonts — can we ship Tiempos (licensed) or stick to Source Serif 4?
4. Illustrations for onboarding/empty states — commission or use open-source set (unDraw, Blush)?
5. Analytics dashboard scope — same as web admin or a cut-down mobile version?

---

*Plan version: 1.0 — 2026-04-24*
