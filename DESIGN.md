---
name: NA-Academy
description: A warm, scholarly mobile learning sanctuary.
colors:
  primary: "#3F7D78"
  primary-soft: "#DDE9E6"
  primary-deep: "#2E5F5B"
  secondary: "#B06A43"
  secondary-soft: "#F1E0D2"
  neutral-bg: "#F4EFE5"
  neutral-surface: "#FBF8F1"
  neutral-sunken: "#EAE3D4"
  text-primary: "#1F1C16"
  text-secondary: "#6B6558"
  border-subtle: "#E0D8C6"
typography:
  display:
    fontFamily: "Fraunces, Georgia, serif"
    fontSize: "32px"
    fontWeight: 500
    lineHeight: 1.15
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Fraunces, Georgia, serif"
    fontSize: "24px"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "-0.015em"
  title:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.01em"
  body:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "0.04em"
rounded:
  sm: "12px"
  md: "18px"
  pill: "999px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.pill}"
    padding: "12px 24px"
  card-standard:
    backgroundColor: "{colors.neutral-surface}"
    rounded: "{rounded.md}"
    padding: "16px"
---

# Design System: NA-Academy

## 1. Overview

**Creative North Star: "The Scholarly Sanctuary"**

NA-Academy is designed to be a calm, focused place for deep study. It rejects the clinical, high-density interfaces of traditional administrative tools in favor of a warm, archival aesthetic. The system feels permanent and intentional—like a well-organized personal library.

**Key Characteristics:**
- **Parchment Canvas:** A warm off-white foundation that reduces eye strain.
- **Sophisticated Serifs:** Fraunces headings provide an intellectual, human touch.
- **Organic Shapes:** Soft radii and pill-shaped affordances that feel friendly and tactile.

## 2. Colors

The palette is anchored in nature and history, moving away from "SaaS Blue" toward organic tones.

### Primary
- **Sage-Teal** (#3F7D78): Used for primary actions, progress indicators, and key focus states. It represents growth and focus.

### Secondary
- **Clay** (#B06A43): Used for highlights, streaks, and secondary interactive elements. It provides a warm contrast to the teal.

### Neutral
- **Parchment Canvas** (#F4EFE5): The primary background for screens.
- **Ink Primary** (#1F1C16): The default text color, providing high contrast without the harshness of pure black.
- **Bone Border** (#E0D8C6): Subtle structural separation.

### Named Rules
**The Rarity Rule.** The primary Sage-Teal is used on ≤10% of any given screen. Its rarity makes it an effective signal for focus and progress.

## 3. Typography

**Display Font:** Fraunces (Serif)
**Body Font:** Inter (Sans)
**Label/Mono Font:** JetBrains Mono

### Hierarchy
- **Display** (500, 32px, 1.15): Hero titles and screen greetings.
- **Headline** (500, 24px, 1.2): Section headings.
- **Title** (600, 20px, 1.3): Item headers and important labels.
- **Body** (400, 15px, 1.5): Reading text and detailed descriptions.
- **Label** (500, 11px, 1.4, UPPERCASE): Meta-data and kickers.

## 4. Elevation

The system is primarily flat and structural, relying on tonal layering rather than dramatic shadows.

### Shadow Vocabulary
- **Card Shadow** (`0 1px 2px rgba(31,28,22,0.04), 0 0 0 1px var(--border-subtle)`): Used to provide subtle separation on surfaces.
- **Floating Shadow** (`0 8px 24px rgba(31,28,22,0.10)`): Used for elevated navigation and overlays.

## 5. Components

### Buttons
- **Shape:** Pill (999px)
- **Primary:** Sage-Teal background with white text. Tactile and confident.
- **Secondary:** Surface background with a subtle border and Ink text.

### Cards / Containers
- **Corner Style:** Large (18px)
- **Background:** White or neutral-surface.
- **Border:** Subtle bone border (#E0D8C6).

### Inputs / Fields
- **Style:** 12px radius with a light sunken background.
- **Focus:** Border shift to primary Sage-Teal.

## 6. Do's and Don'ts

### Do:
- **Do** use Fraunces for screen titles to establish the scholarly tone.
- **Do** maintain the Parchment-to-Ink contrast for long reading sessions.
- **Do** use large, tactile pill buttons for primary actions.

### Don't:
- **Don't** use pure black (#000) or pure white (#FFF) on large surfaces.
- **Don't** use high-vibrancy "SaaS Blue" or neon accents.
- **Don't** use sharp corners (radius < 8px) on interactive elements.
