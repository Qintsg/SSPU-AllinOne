# DESIGN.md — Material 3 Design Specification (Flutter)

> **Audience:** AI coding agents and developers building this Flutter project.
> **Purpose:** A prescriptive, machine-actionable specification. Every UI the agent
> produces MUST conform to the rules below. When a design choice is not specified
> here, follow Material Design 3 defaults — do not invent new patterns.

---

## How to Use This Document (Agent Instructions)

1. **Read [Hard Rules](#1-hard-rules) first.** These are non-negotiable and apply to every task.
2. Before writing UI code, locate the relevant section (color, typography, components, etc.) and apply its rules verbatim.
3. Prefer **copy-pasting the code templates** in [§14](#14-flutter-theme-implementation) over writing equivalents from scratch.
4. When a value is needed (spacing, radius, duration), use the **named token**, never a literal.
5. Before marking any UI task complete, run the [Definition of Done](#16-definition-of-done) checklist.
6. If a requirement here conflicts with a user instruction, surface the conflict instead of silently violating the spec.

### Normative Language

| Term | Meaning |
|------|---------|
| **MUST** / **MUST NOT** | Hard requirement. Violations are bugs and must be fixed. |
| **SHOULD** / **SHOULD NOT** | Strong default. Deviate only with an explicit, stated reason. |
| **MAY** | Optional, at the agent's discretion. |

---

## Table of Contents

1. [Hard Rules](#1-hard-rules)
2. [Design Principles](#2-design-principles)
3. [Design Tokens](#3-design-tokens)
4. [Color System](#4-color-system)
5. [Typography](#5-typography)
6. [Shape](#6-shape)
7. [Elevation & Layering](#7-elevation--layering)
8. [Spacing & Layout Grid](#8-spacing--layout-grid)
9. [Iconography & Imagery](#9-iconography--imagery)
10. [Components](#10-components)
11. [Motion](#11-motion)
12. [Responsive & Adaptive Design](#12-responsive--adaptive-design)
13. [Accessibility](#13-accessibility)
14. [Flutter Theme Implementation](#14-flutter-theme-implementation)
15. [Code Organization & Naming](#15-code-organization--naming)
16. [Definition of Done](#16-definition-of-done)
17. [References](#17-references)

---

## 1. Hard Rules

These apply to **every** UI change. They are the most common sources of spec violations.

- **R1.** MUST NOT hardcode color values (`Color(0x...)`, `Colors.blue`, etc.) in feature/widget code. Use `Theme.of(context).colorScheme.*`.
- **R2.** MUST NOT hardcode `fontSize` or text colors. Use `Theme.of(context).textTheme.*`.
- **R3.** MUST NOT hardcode spacing, radius, elevation, or motion durations as raw numbers. Use the tokens in [§3](#3-design-tokens).
- **R4.** Every screen MUST be implemented for **both light and dark themes**. No light-only screens.
- **R5.** Every screen MUST be usable across **Compact, Medium, and Expanded** window size classes ([§12](#12-responsive--adaptive-design)).
- **R6.** Every interactive element MUST have a touch target ≥ **48×48 dp** and an accessible label/tooltip ([§13](#13-accessibility)).
- **R7.** Information MUST NOT be conveyed by color alone. Pair color with text, icon, or shape.
- **R8.** MUST NOT lock text scaling (no forced `TextScaler.noScaling`). UI MUST survive 200% font scaling.
- **R9.** MUST set `useMaterial3: true` (Flutter ≥ 3.16 default) and MUST NOT use deprecated `ColorScheme` roles (`background`, `onBackground`, `surfaceVariant`).
- **R10.** Layout direction MUST use directional APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`), never hardcoded `left`/`right`, to keep RTL support viable.
- **R11.** MUST NOT use fixed pixel widths/heights for content containers where flexible sizing (`Expanded`, `Flexible`, constraints) is appropriate.
- **R12.** Reusable UI MUST be a shared component. MUST NOT copy-paste styled widgets across screens.

---

## 2. Design Principles

| Principle | Operational meaning for the agent |
|-----------|-----------------------------------|
| **Consistency** | Reuse existing components and tokens before creating new ones. Identical semantics → identical implementation. |
| **Clear hierarchy** | Use color roles, elevation, and the type scale to establish hierarchy. Limit competing emphasis. |
| **Adaptive by default** | Build for all window size classes from the start, not phone-first with retrofits. |
| **Accessibility built-in** | Contrast, target size, and semantics are decided while writing the widget, not patched later. |
| **Restrained motion** | Motion serves feedback and continuity. Respect "reduce motion". No decorative animation. |
| **Content first** | Whitespace is intentional. Decoration yields to content. |

---

## 3. Design Tokens

Tokens are the single source of truth shared between design and code. **Business code references tokens only — never literals** (see R1–R3).

Maintain tokens centrally:

```
lib/theme/
  app_theme.dart        // ThemeData construction (light + dark)
  app_colors.dart       // seed color, fixed brand colors
  app_spacing.dart      // spacing constants
  app_shapes.dart       // corner radius constants
  app_motion.dart       // durations + curves
  app_typography.dart   // optional font family overrides
```

Token layers:

| Layer | Description | Example |
|-------|-------------|---------|
| Reference | Raw palette / base values | seed color, brand palette |
| System | Semantic, theme-aware roles | `colorScheme.primary`, `textTheme.bodyLarge` |
| Component | Values consumed inside a component | a button's container = `colorScheme.primary` |

Feature code uses **System** and **Component** tokens only.

---

## 4. Color System

### 4.1 Color Roles

M3 uses a tonal role system, mapped in Flutter to `ColorScheme`. **Container/surface colors are always paired with their `on*` foreground color** — used together they guarantee contrast.

| Role group | Use for |
|------------|---------|
| `primary` / `onPrimary` | Primary action (`FilledButton`), key interactive elements |
| `primaryContainer` / `onPrimaryContainer` | Emphasized container that does not compete with the primary action |
| `secondary` / `secondaryContainer` | Secondary emphasis, filter chips |
| `tertiary` / `tertiaryContainer` | Balancing accent, contrast highlights |
| `error` / `errorContainer` | Errors, destructive actions, validation |
| `surface` / `onSurface` | Default background and text |
| `surfaceContainerLowest` … `surfaceContainerHighest` | Surfaces at different elevation levels ([§7](#7-elevation--layering)) |
| `onSurfaceVariant` | Secondary text, helper text, inactive icons |
| `outline` / `outlineVariant` | Borders, dividers |
| `inverseSurface` / `onInverseSurface` / `inversePrimary` | Inverted contexts (e.g. `SnackBar`) |
| `surfaceTint` | Elevation tint overlay |
| `scrim` | Modal scrim |

### 4.2 Rules

- **C1.** MUST generate the full `ColorScheme` from a single seed color via `ColorScheme.fromSeed`.
- **C2.** MUST use paired roles (`primary` + `onPrimary`, etc.). MUST NOT mix unrelated foreground/background colors.
- **C3.** MUST NOT use deprecated roles (`background`, `onBackground`, `surfaceVariant`).
- **C4.** Dark theme MUST be a first-class peer of light theme.
- **C5.** In dark theme, MUST NOT flood large areas with pure black (`#000000`); use `surface`. Express elevation via `surfaceContainer*` brightness + `surfaceTint`, not heavier shadows.
- **C6.** Fixed brand colors (e.g. logo) are reference tokens, kept separate, and MUST NOT change with theme.
- **C7.** Any custom color pair MUST be verified for contrast ([§13.2](#132-color--contrast)).

```dart
const Color kSeedColor = Color(0xFF4A6FA5); // replace with brand seed

ColorScheme lightScheme = ColorScheme.fromSeed(
  seedColor: kSeedColor,
  brightness: Brightness.light,
);
ColorScheme darkScheme = ColorScheme.fromSeed(
  seedColor: kSeedColor,
  brightness: Brightness.dark,
);
```

---

## 5. Typography

### 5.1 Type Scale

M3 defines 15 levels across 5 groups, mapped to Flutter's `TextTheme`.

| Group | Token | Size (sp) | Line height (sp) | Weight | Typical use |
|-------|-------|-----------|------------------|--------|-------------|
| Display | `displayLarge` | 57 | 64 | 400 | Hero text, onboarding |
| | `displayMedium` | 45 | 52 | 400 | |
| | `displaySmall` | 36 | 44 | 400 | |
| Headline | `headlineLarge` | 32 | 40 | 400 | Page-level titles |
| | `headlineMedium` | 28 | 36 | 400 | |
| | `headlineSmall` | 24 | 32 | 400 | |
| Title | `titleLarge` | 22 | 28 | 400 | App bar title, card title |
| | `titleMedium` | 16 | 24 | 500 | List item primary text |
| | `titleSmall` | 14 | 20 | 500 | |
| Body | `bodyLarge` | 16 | 24 | 400 | Primary body text |
| | `bodyMedium` | 14 | 20 | 400 | Default text |
| | `bodySmall` | 12 | 16 | 400 | Helper text |
| Label | `labelLarge` | 14 | 20 | 500 | Button text |
| | `labelMedium` | 12 | 16 | 500 | Small labels |
| | `labelSmall` | 11 | 16 | 500 | Smallest labels |

### 5.2 Rules

- **T1.** MUST reference `textTheme.*`. MUST NOT set raw `fontSize`.
- **T2.** A single screen SHOULD use ≤ 4 distinct type levels.
- **T3.** Body text line length SHOULD be 40–70 characters; constrain container width when wider.
- **T4.** Text SHOULD be left-aligned (LTR). MUST NOT use justified alignment.
- **T5.** MUST support system font scaling up to 200% (see R8, [§13.4](#134-dynamic-type--scaling)).

---

## 6. Shape

M3 corner radius scale, mapped to `BorderRadius` / `ShapeBorder`.

| Token | Radius | Typical components |
|-------|--------|--------------------|
| None | 0 dp | Full-bleed images |
| Extra small | 4 dp | Small chip elements, menus |
| Small | 8 dp | Text fields, small cards |
| Medium | 12 dp | Cards, dialog inner elements |
| Large | 16 dp | Cards, large containers |
| Extra large | 28 dp | Dialogs, bottom sheets, large FAB |
| Full | pill | Buttons, chips, FAB, search bar |

### 6.1 Rules

- **SH1.** MUST use the radius tokens below; MUST NOT use arbitrary radii.
- **SH2.** Members of the same component family MUST share a radius.

```dart
class AppShapes {
  static const xs = BorderRadius.all(Radius.circular(4));
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(28));
}
```

---

## 7. Elevation & Layering

M3 expresses elevation primarily via **surface tint/color**, not shadows — critically so in dark theme.

| Level | Elevation | Surface role | Typical components |
|-------|-----------|--------------|--------------------|
| 0 | 0 dp | `surface` | Page background, resting cards |
| 1 | 1 dp | `surfaceContainerLow` | Cards, `ElevatedButton` |
| 2 | 3 dp | `surfaceContainer` | App bar (scrolled), hovered chips |
| 3 | 6 dp | `surfaceContainerHigh` | FAB, dialogs, menus |
| 4 | 8 dp | `surfaceContainerHigh` | Navigation drawer |
| 5 | 12 dp | `surfaceContainerHighest` | Dragged elements |

### 7.1 Rules

- **E1.** Distinguish layers using surface container colors; use large shadows sparingly.
- **E2.** A single screen SHOULD show ≤ 3 elevation levels.
- **E3.** App bar MUST transition from Level 0 to Level 2 when content scrolls under it (`scrolledUnderElevation`).
- **E4.** In dark theme, higher elevation MUST mean a lighter surface, not a darker shadow.

---

## 8. Spacing & Layout Grid

### 8.1 Spacing Scale (4 dp base grid)

All spacing MUST be a multiple of 4.

| Token | Value | Use |
|-------|-------|-----|
| `xs` | 4 | Tight element gaps |
| `sm` | 8 | Intra-element spacing, icon padding |
| `md` | 16 | **Default page margin**, card padding |
| `lg` | 24 | Section spacing |
| `xl` | 32 | Large section spacing |
| `xxl` | 48 | Page-level partitioning |

```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
```

### 8.2 Page Margins

| Window class | Page margin |
|--------------|-------------|
| Compact | 16 dp |
| Medium | 24 dp |
| Expanded and above | 24 dp + max content width constraint |

### 8.3 Rules

- **SP1.** MUST use `AppSpacing` tokens; MUST NOT use raw spacing literals.
- **SP2.** Gutters: 16 dp (Compact) / 24 dp (larger).
- **SP3.** Long-form text and forms MUST set a max width (e.g. 640 dp) to avoid over-wide lines.

---

## 9. Iconography & Imagery

### 9.1 Rules — Icons

- **IC1.** MUST use Material Symbols (`Icons.*`) only. MUST NOT mix icon libraries.
- **IC2.** Standard icon size 24 dp; dense 20 dp; emphasis 40/48 dp.
- **IC3.** Inactive icons use `onSurfaceVariant`; active icons use `primary`.
- **IC4.** Every icon button MUST have a ≥ 48×48 dp touch target and a `tooltip` + semantic label (R6).

### 9.2 Rules — Imagery

- **IM1.** Thumbnails MUST use a consistent radius (typically Medium, 12 dp).
- **IM2.** Images MUST have a loading placeholder (skeleton / low-res preview) and an error fallback.
- **IM3.** Images MUST declare a fixed aspect ratio (e.g. 16:9, 1:1, 4:3) to prevent layout shift.
- **IM4.** Decorative images MUST be hidden from semantics; informative images MUST provide a text alternative ([§13.5](#135-semantics--screen-readers)).

---

## 10. Components

Use Flutter's built-in M3 components, wrapped into shared project components (R12).

### 10.1 Buttons

| Type | Flutter widget | Use | Per-screen guidance |
|------|----------------|-----|---------------------|
| Primary | `FilledButton` | The single most important action | ≤ 1 |
| Secondary | `FilledButton.tonal` | Important, not top-priority | Few |
| Emphasized outline | `OutlinedButton` | Alternative beside the primary | Few |
| Text | `TextButton` | Low-emphasis (e.g. "Cancel") | Unlimited |
| Icon | `IconButton` | Toolbars, compact actions | Unlimited |
| Floating | `FloatingActionButton` | Screen-level core action | ≤ 1 |

Rules:
- **B1.** Button labels MUST be concise verb phrases (e.g. "Save", "Retry").
- **B2.** Visual button height ~40 dp; touch target MUST be ≥ 48 dp.
- **B3.** While loading, a button MUST show progress and prevent duplicate taps.
- **B4.** Destructive actions MUST use the `error` role and MUST require confirmation.

### 10.2 Navigation Components

| Component | Window class | Notes |
|-----------|--------------|-------|
| `NavigationBar` (bottom) | Compact | 3–5 top-level destinations |
| `NavigationRail` | Medium / Expanded | Side navigation |
| `NavigationDrawer` | Expanded and above | Standard drawer; many destinations |
| `Drawer` (modal) | Compact | Temporary drawer when destinations exceed 5 |

See [§12.3](#123-adaptive-navigation).

### 10.3 Cards

- **CD1.** Use `Card` (Elevated/Filled/Outlined). A single list MUST use one variant only.
- **CD2.** Default card padding 16 dp; radius Large/Medium.
- **CD3.** A fully tappable card MUST make the whole card the touch target with an `InkWell` ripple.

### 10.4 Inputs & Forms

- **F1.** Text fields MUST use one consistent style (outlined or filled) project-wide.
- **F2.** Labels MUST be persistently visible. MUST NOT use placeholder text as the only label.
- **F3.** Required fields MUST be marked; validation errors MUST appear below the field with `error`-role text + icon.
- **F4.** On submit failure, focus MUST move to the first invalid field and the error MUST be announced to screen readers.

### 10.5 Feedback

| Scenario | Component | Notes |
|----------|-----------|-------|
| Lightweight notice | `SnackBar` | Brief, ≤ 1 action; never critical-only info |
| User decision needed | `Dialog` / `AlertDialog` | Blocking; use sparingly |
| Loading | `CircularProgressIndicator` / skeleton | Any wait > ~300 ms MUST show feedback |
| Empty state | Shared empty-state component | Illustration + text + optional action |
| Error | Shared error component | Cause + retry entry point |

### 10.6 Lists

- **L1.** Use `ListTile` for consistent row height and padding.
- **L2.** Long lists MUST use `ListView.builder` (lazy).
- **L3.** Separate rows with either `Divider` (`outlineVariant`) or whitespace — not both.

---

## 11. Motion

### 11.1 Duration

| Tier | Duration | Use |
|------|----------|-----|
| Short | 50–200 ms | Small state changes, ripple, toggles |
| Medium | 250–400 ms | Component enter/exit, expand/collapse |
| Long | 450–600 ms | Large transitions, page changes |
| Extra long | 700–1000 ms | Large expressive transitions (rare) |

### 11.2 Easing

| Curve | Flutter | Use |
|-------|---------|-----|
| Standard | `Curves.easeInOutCubicEmphasized` | Most standard transitions |
| Emphasized decelerate | `Curves.easeOutCubic` (approx.) | Elements entering the screen |
| Emphasized accelerate | `Curves.easeInCubic` (approx.) | Elements leaving the screen |
| Linear | `Curves.linear` | Progress, loops |

```dart
class AppMotion {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const long = Duration(milliseconds: 500);
  static const emphasized = Curves.easeInOutCubicEmphasized;
}
```

### 11.3 Rules

- **M1.** Motion MUST serve feedback, spatial continuity, or attention — never pure decoration.
- **M2.** Entering elements use a decelerate curve; leaving elements use an accelerate curve.
- **M3.** Page transitions MUST use a single shared route-animation wrapper.
- **M4.** MUST respect the system "reduce motion" setting:
  ```dart
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  // When true: use fade or instant swap; disable large translate/scale animations.
  ```

---

## 12. Responsive & Adaptive Design

> **Responsive:** layout scales/reflows continuously with size.
> **Adaptive:** layout switches structure/components at breakpoints (e.g. bottom nav → side rail).
> This project requires **both**.

### 12.1 Window Size Classes

Classified by **available window width** (not physical screen size).

| Class | Width (dp) | Typical |
|-------|------------|---------|
| **Compact** | 0–599 | Portrait phone, small window |
| **Medium** | 600–839 | Portrait tablet, unfolded foldable, large phone landscape |
| **Expanded** | 840–1199 | Landscape tablet, small desktop window |
| **Large** | 1200–1599 | Desktop |
| **Extra-large** | ≥ 1600 | Large/ultrawide desktop |

```dart
enum WindowSizeClass { compact, medium, expanded, large, extraLarge }

WindowSizeClass windowSizeClassOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return WindowSizeClass.compact;
  if (w < 840) return WindowSizeClass.medium;
  if (w < 1200) return WindowSizeClass.expanded;
  if (w < 1600) return WindowSizeClass.large;
  return WindowSizeClass.extraLarge;
}
```

### 12.2 Breakpoint Behavior

| Aspect | Compact | Medium | Expanded and above |
|--------|---------|--------|---------------------|
| Columns | 1 | 1–2 | Multi-column / list-detail side-by-side |
| Navigation | Bottom `NavigationBar` | `NavigationRail` | `NavigationRail` or `NavigationDrawer` |
| Page margin | 16 dp | 24 dp | 24 dp + max content width |
| FAB | Standard | Standard / Extended | Extended FAB, often atop the rail |
| Dialogs | Full-screen dialog / bottom sheet | Centered dialog | Centered dialog |

### 12.3 Adaptive Navigation

Navigation structure MUST switch with window class, and the **selected destination MUST persist across forms**.

- **Compact:** bottom `NavigationBar` (3–5 items). Overflow → "More" or modal `Drawer`.
- **Medium:** `NavigationRail` (collapsible).
- **Expanded and above:** expanded `NavigationRail`, or persistent `NavigationDrawer` when destinations are numerous.

Use `flutter_adaptive_scaffold`'s `AdaptiveScaffold`, or a shared `AppShell`:

```dart
Widget buildShell(BuildContext context, Widget body) {
  final size = windowSizeClassOf(context);
  switch (size) {
    case WindowSizeClass.compact:
      return Scaffold(
        body: body,
        bottomNavigationBar: const AppNavigationBar(),
      );
    case WindowSizeClass.medium:
    case WindowSizeClass.expanded:
      return Scaffold(
        body: Row(children: [
          AppNavigationRail(extended: size == WindowSizeClass.expanded),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    case WindowSizeClass.large:
    case WindowSizeClass.extraLarge:
      return Scaffold(
        body: Row(children: [
          const AppNavigationDrawer(),
          Expanded(child: body),
        ]),
      );
  }
}
```

### 12.4 Canonical Layouts

Apply one of M3's four canonical layouts before designing a custom one.

| Layout | Description | Compact | Expanded |
|--------|-------------|---------|----------|
| **List-Detail** | Master/detail | Two separate full-screen pages | List left + detail right |
| **Supporting Pane** | Main content + supporting info | Supporting content collapses to bottom sheet / tab | Main area + right supporting pane |
| **Feed** | Card grid | Single column | Multi-column grid; columns scale with width |
| **Single Column** | Forms, reading detail | Full width | Centered, max width (e.g. 640 dp) |

Implementation rules:
- **RD1.** Use `LayoutBuilder` / `MediaQuery.sizeOf` to choose structure; `Wrap`, `Flex`, `GridView` to reflow.
- **RD2.** List-Detail MUST keep the selected item when expanding to Expanded; when shrinking to Compact, fall back sensibly to list or detail.
- **RD3.** Grid column count MUST switch at breakpoints, not at arbitrary pixel values (e.g. 1 / 2 / 3 / 4 columns for Compact / Medium / Expanded / Large).

### 12.5 Input-Mode Adaptation

UI MUST adapt to input method, not only size.

- **Touch:** targets ≥ 48 dp; gestures (swipe, long-press) available.
- **Mouse:** hover states, appropriate cursors (`MouseRegion`), context menus where relevant.
- **Keyboard:** every interaction reachable and operable via Tab/arrow keys; visible focus ([§13.6](#136-keyboard--focus)).
- Desktop/Web MUST reflow live on window resize — no restart/refresh required.

### 12.6 Safe Areas & Non-Rectangular Screens

- **SA1.** MUST use `SafeArea` for notches, status bars, and gesture insets.
- **SA2.** Foldables: keep key content/actions off the hinge region; use `MediaQuery.displayFeatures` when needed.
- **SA3.** Orientation changes MUST preserve scroll position and user input.

### 12.7 Responsive Rules

- **RR1.** MUST NOT branch layout on device identity ("is iPad"). Branch on window size class.
- **RR2.** MUST NOT write per-device duplicate screens. One screen, breakpoint-conditional rendering.
- **RR3.** Every screen MUST render without horizontal overflow at a minimum width of **320 dp** (unless the region is intentionally horizontally scrollable).
- **RR4.** Use flexible sizing (`Expanded`, `Flexible`, `FractionallySizedBox`); avoid fixed dimensions (R11).

---

## 13. Accessibility

Accessibility is **mandatory**, targeting **WCAG 2.1 AA**. Every screen MUST satisfy this section before completion.

### 13.1 Principles

- Perceivable, Operable, Understandable, Robust.
- No information conveyed by a single channel (color, shape, position, sound) alone (R7).
- Accessibility is decided while writing the widget, then self-verified at PR time.

### 13.2 Color & Contrast

| Content type | Minimum contrast (AA) |
|--------------|------------------------|
| Body text (< 18.66 px regular / < 24 px) | **4.5 : 1** |
| Large text (≥ 18.66 px bold or ≥ 24 px) | **3 : 1** |
| UI component bounds, icons, non-text graphics | **3 : 1** |
| Decorative elements | None |

- **A1.** M3 `on*` roles meet contrast when used as pairs — using pairs satisfies this by default.
- **A2.** Any custom color pair MUST be verified with a contrast tool.
- **A3.** MUST NOT express "secondary" via low-contrast text; use size/weight instead.

### 13.3 Touch Target Size

- **A4.** Every interactive element MUST have a touch target ≥ **48×48 dp**, even if the visual is smaller.
- **A5.** Adjacent tappable elements MUST have ≥ 8 dp spacing.
- **A6.** Expand small icons' hit area via `IconButton`, `InkWell` + `SizedBox`, etc.
- **A7.** List rows SHOULD be fully tappable — do not require precise icon taps.

### 13.4 Dynamic Type & Scaling

- **A8.** MUST support system font scaling to **200%** without loss of content or function.
- **A9.** Layouts MUST be robust to large text: allow wrapping, expand containers, use `Flexible`/`Expanded` to prevent overflow.
- **A10.** MUST NOT force `TextScaler.noScaling` (R8). To bound extreme scaling, use `MediaQuery.withClampedTextScaling`, never a hard disable.
- **A11.** Touch target size MUST NOT shrink with font scaling.

### 13.5 Semantics & Screen Readers

Support TalkBack, VoiceOver, and desktop screen readers.

- **A12.** Every non-text interactive element MUST have a semantic label:
  ```dart
  IconButton(
    icon: const Icon(Icons.favorite),
    tooltip: 'Add to favorites', // serves as visible hint + semantics
    onPressed: _toggleFavorite,
  );

  Semantics(
    label: 'Profile photo, Jane Doe',
    image: true,
    child: avatarWidget,
  );
  ```
- **A13.** Decorative images MUST be hidden via `ExcludeSemantics` / `Semantics(excludeSemantics: true)`.
- **A14.** Use `MergeSemantics` to merge icon+text into one spoken unit.
- **A15.** Mark headings with `Semantics(header: true)`.
- **A16.** Announce dynamic changes (load complete, validation error, new message) via `SemanticsService.announce(...)`.
- **A17.** Semantic labels MUST NOT include the widget type word ("button", "image") — the type is conveyed by semantic flags.

### 13.6 Keyboard & Focus

For desktop, Web, and external keyboards.

- **A18.** Every interactive element MUST be reachable via Tab / Shift+Tab in visual reading order.
- **A19.** Focus state MUST be clearly visible — MUST NOT remove M3 focus highlights.
- **A20.** Use `FocusTraversalGroup` to order traversal in complex layouts.
- **A21.** Support common shortcuts (`Esc` closes dialogs, `Enter` submits) via `Shortcuts` + `Actions`.
- **A22.** Open modals MUST trap focus inside; on close, focus MUST return to the trigger element.
- **A23.** MUST NOT create keyboard traps — any region entered must be exitable via keyboard.

### 13.7 Form Accessibility

- **A24.** Each input MUST have a persistently visible label correctly associated with the control.
- **A25.** Errors MUST be conveyed by text + icon and announced to screen readers; focus moves to the first invalid field.
- **A26.** Required fields and format requirements MUST be visible before input.

### 13.8 Motion & Accessibility

- **A27.** MUST respect "reduce motion" (`MediaQuery.disableAnimationsOf(context)`).
- **A28.** MUST NOT flash content faster than 3 times per second (photosensitivity risk).
- **A29.** Autoplaying/carousel content MUST offer pause control and MUST NOT steal focus.

### 13.9 Content & Language

- **A30.** Copy MUST be clear and concise; avoid ambiguity and unexplained jargon.
- **A31.** Link/button text MUST be self-descriptive (avoid "click here").
- **A32.** Use directional layout APIs to keep RTL viable (R10).

### 13.10 Accessibility Testing

The agent MUST include automated accessibility assertions in widget tests:

```dart
testWidgets('home screen meets a11y guidelines', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(const App());

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

  handle.dispose();
});
```

Manual verification (when feasible): TalkBack/VoiceOver pass of key flows; keyboard-only completion of core tasks; regression at max system font size and with "reduce motion" enabled.

---

## 14. Flutter Theme Implementation

Copy these templates directly.

### 14.1 `app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'app_shapes.dart';

const Color kSeedColor = Color(0xFF4A6FA5); // replace with brand seed

ThemeData buildTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    // textTheme: ... // override here if using a custom font
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      scrolledUnderElevation: 3,
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppShapes.lg),
    ),
    // Centralize all component themes here.
  );
}
```

### 14.2 `main.dart`

```dart
MaterialApp(
  theme: buildTheme(Brightness.light),
  darkTheme: buildTheme(Brightness.dark),
  themeMode: ThemeMode.system,
  // ...
);
```

### 14.3 Token Reference Pattern

```dart
// CORRECT — reference theme tokens
final cs = Theme.of(context).colorScheme;
final tt = Theme.of(context).textTheme;

Text('Title', style: tt.titleLarge);
Container(color: cs.surfaceContainer);

// WRONG — hardcoded (violates R1, R2)
Text('Title', style: const TextStyle(fontSize: 22, color: Colors.black));
Container(color: const Color(0xFFEEEEEE));
```

### 14.4 Optional: Dynamic Color (Android 12+)

```dart
// Requires the `dynamic_color` package.
DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) {
    final light = lightDynamic ?? ColorScheme.fromSeed(seedColor: kSeedColor);
    final dark = darkDynamic ??
        ColorScheme.fromSeed(seedColor: kSeedColor, brightness: Brightness.dark);
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: light),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: dark),
    );
  },
);
```

### 14.5 Accessible Icon Button Pattern

```dart
// Reusable, spec-compliant icon button (R6, A4, A12).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String label;      // semantic label + tooltip
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon),
      tooltip: label,
      color: isActive ? cs.primary : cs.onSurfaceVariant,
      onPressed: onPressed,
      // IconButton already enforces a >= 48dp target by default.
    );
  }
}
```

---

## 15. Code Organization & Naming

### 15.1 Directory Structure

```
lib/
  theme/            // theme + tokens
  widgets/          // generic reusable components (wrapped M3 widgets)
  components/       // business components
  features/         // screens grouped by feature module
  l10n/             // localized strings
assets/
  images/
  icons/
  fonts/
```

### 15.2 Rules

- **O1.** Any UI used in more than one place MUST be a shared component (R12).
- **O2.** Components MUST expose semantic parameters, not style internals; colors/radii are resolved internally from tokens.
- **O3.** Every generic component MUST support light/dark themes, font scaling, and accessibility semantics.
- **O4.** Names describe purpose: `PrimaryActionButton`, `SectionCard`, `EmptyStateView`.
- **O5.** Token names are semantic and stable — `space16`, role names — never visual-appearance names like `blueColor`.
- **O6.** User-facing strings MUST go through `l10n`, never hardcoded inline.

---

## 16. Definition of Done

Run this checklist before marking any UI task complete. Every item MUST pass.

**Tokens & Theming**
- [ ] No hardcoded colors; all from `colorScheme` (R1, C-rules).
- [ ] No hardcoded `fontSize`/text color; all from `textTheme` (R2).
- [ ] No raw spacing/radius/elevation/duration literals; all from tokens (R3).
- [ ] Light and dark themes both implemented and verified (R4).

**Responsive / Adaptive**
- [ ] Usable in Compact, Medium, and Expanded (R5).
- [ ] Navigation structure switches by window class; selected state persists (12.3).
- [ ] No horizontal overflow at 320 dp width (RR3).
- [ ] Reflows live on desktop/Web window resize (12.5).
- [ ] An appropriate canonical layout is applied (12.4).

**Accessibility**
- [ ] Text contrast ≥ 4.5:1 (≥ 3:1 for large text) (13.2).
- [ ] All touch targets ≥ 48×48 dp (R6, A4).
- [ ] No color-only information (R7).
- [ ] No overflow/truncation at 200% font scale (R8, A8).
- [ ] All interactive elements have semantic labels / tooltips (A12).
- [ ] Core flow completable with keyboard only; focus visible (13.6).
- [ ] "Reduce motion" respected (A27).
- [ ] `meetsGuideline` accessibility tests added and passing (13.10).

**Structure**
- [ ] Reusable UI extracted into shared components (R12, O1).
- [ ] User-facing strings localized via `l10n` (O6).

---

## 17. References

- Material Design 3: https://m3.material.io
- Flutter Material 3 support: https://docs.flutter.dev/ui/design/material
- Flutter adaptive/responsive design: https://docs.flutter.dev/ui/adaptive-responsive
- Flutter accessibility: https://docs.flutter.dev/accessibility-and-localization/accessibility
- WCAG 2.1: https://www.w3.org/TR/WCAG21/
- Packages: `flutter_adaptive_scaffold`, `dynamic_color`

---

> Living document. Update as the project evolves. The seed color (`0xFF4A6FA5`)
> and font choices are placeholders — replace with real brand values before use.
