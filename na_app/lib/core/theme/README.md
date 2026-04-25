# Scholarly Sanctuary — Theme System

## Tokens

All visual decisions are encoded in `core/theme/`:

| File | Purpose |
|------|---------|
| `app_colors.dart` | Colour palette (light + dark) |
| `app_typography.dart` | Type scale (Fraunces, Inter, JetBrains Mono) |
| `app_shapes.dart` | Border radii, card/pill/input shapes |
| `app_motion.dart` | Duration helpers with `MediaQuery.disableAnimations` support |
| `app_theme.dart` | Assembled `ThemeData` (light + dark) |

## Principle I — Scholarly Warmth by Default

- **No raw `Color(0x…)` or `Colors.*` in feature code** (`lib/features/`).
- All colour references go through `AppColors.*` tokens.
- Enforced by `custom_lint` in `analysis_options.yaml`.

## The Rarity Rule (FR-030)

> Sage-teal (`AppColors.accent` / `#3F7D78`) must occupy **≤10% of any screen's visible area**.

### Verification checklist (per screen)

Walk each screen and confirm:

1. **Primary background** is parchment (`bgCanvas` / `bgSurface`), NOT sage-teal.
2. **Card surfaces** are `bgSurface` or `bgElevated`, NOT sage-teal.
3. **Sage-teal appears only on**: CTA buttons, active tab pills, progress rings, link text, small icons, selected-state borders.
4. **Sage-teal must NOT appear as**: full-width banners, large hero backgrounds, or any area >10% of the viewport.
5. **Dark mode** uses `darkAccent` (`#5AA39E`) which follows the same rule.

### Current screen audit (Phase 8)

| Screen | Accent usage | Status |
|--------|-------------|--------|
| Splash | Logo icon, loader | PASS |
| Onboarding | Slide icons, CTA button | PASS |
| Login / Register | CTA button, links, strength meter | PASS |
| Today | Greeting settings icon (indirect), "See all" link, refresh indicator | PASS |
| Subjects grid | Code entry card border, lock icon, "Enter code" CTA | PASS |
| Subject detail | Progress ring, active lesson icon | PASS |
| Code entry / unlocking | Progress step indicators | PASS |
| Exams list | Category badge accent | PASS |
| Take exam | Timer, progress bar, Next CTA | PASS |
| Exam result | Done button | PASS |
| Chat list | Unread badge, counterparty name | PASS |
| Chat thread | Send button, read receipts, typing dots | PASS |
| Profile | Role badge, settings gear icon border | PASS |
| Settings | Radio check mark, switch active color | PASS |

All screens pass the Rarity Rule.

## Reduced motion (FR-036)

`AppMotion.shouldReduceMotion(context)` gates:

- Onboarding page slide transitions
- Code unlocking 3-step animation (degrades to instant state swap)
- Chat typing indicator dots
- Greeting header fade-in
- Streak card fade-in

All animated widgets use `AppMotion.motionAwareDuration()` or check `shouldReduceMotion()` directly.

## Dynamic type (FR-037)

All 5 core screens wrap their `Scaffold` in `MaxTextScale(maxScale: 1.3)` which clamps `TextScaler` to 1.3x without affecting layout below that threshold.

## Touch targets (FR-035)

All interactive elements meet or exceed 44dp minimum tap target:

- IconButtons use default 48dp
- Tab pills have explicit 44dp height
- CTA buttons have 14dp vertical padding (well above 44dp)
- TextButtons specify `minimumSize: Size(44, 44)`
- Settings rows use full-width `ListTile` (well above 44dp)
