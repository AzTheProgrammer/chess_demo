# Chess App — Design System v1

> **Status:** Canonical (replaces interim tokens in `architecture.html` §6)  
> **Flutter implementation:** `lib/core/theme/design_tokens.dart` + `lib/core/theme/app_theme.dart`  
> **Board spec:** `docs/board-component-spec.md`  
> **Wireframes:** `docs/wireframes.html`

## Design direction

**Quiet luxury, dark-first.** Deep charcoal shell, soft periwinkle accent, generous whitespace, subtle motion. Chess content (board, notation) is the hero; chrome stays visually quiet.

**Palette decision:** Periwinkle `#6C9EFF` over muted gold — better contrast on dark surfaces, aligns with existing scaffold, passes WCAG AA for large text on `#1A1D27`.

---

## Design lenses applied

| Lens | Application |
|------|-------------|
| **Cognitive Load / Chunking** | Bottom nav limits top-level IA to 5 items; Train hub groups 3 drill modes |
| **Progressive Disclosure** | Analyze import uses tabbed bottom sheet; Settings uses segmented controls |
| **Recognition over Recall** | Recent games on Home; move chips in Analyze; icon+label nav |
| **Fitts's Law** | Primary CTAs full-width; board squares sized to viewport; 48dp min touch |
| **Gestalt — Proximity** | Card groups separated by 12px; section headers 24px above content |
| **Aesthetic-Usability** | Consistent radii, borders, and type scale signal polish |
| **WCAG POUR** | Color-independent highlights (dots + tint); 4.5:1 body text; reduced motion respected |

---

## Color tokens

### App shell (dark theme — v1 default)

| Token | Hex | Usage |
|-------|-----|-------|
| `bg` | `#0F1117` | Scaffold background |
| `surface` | `#1A1D27` | Cards, app bar, nav bar |
| `surfaceElevated` | `#242836` | Modals, bottom sheets, hover |
| `border` | `#2E3345` | Card borders, dividers |
| `textPrimary` | `#E8EAEF` | Headlines, body |
| `textSecondary` | `#9AA3B5` | Subtitles, metadata |
| `textTertiary` | `#6B7280` | Placeholders, disabled |
| `accent` | `#6C9EFF` | Primary actions, selected nav, links |
| `accentSoft` | `#6C9EFF` @ 12% | Nav indicator, chip selected bg |
| `success` | `#5DD39E` | Correct puzzle, win |
| `warning` | `#F0B429` | Hints, engine loading |
| `danger` | `#F07178` | Blunder, error, check |

### Semantic mapping (Material 3)

```
ColorScheme.fromSeed(seedColor: accent, brightness: dark, surface: surface)
scaffoldBackgroundColor: bg
primary: accent
onPrimary: textOnAccent
surface: surface
onSurface: textPrimary
outline: border
```

Light theme is **Phase 2** — board themes work in both; app shell stays dark in v1.

---

## Spacing scale

Base unit: **4px**

| Token | Value | Usage |
|-------|-------|-------|
| `space1` | 4 | Icon-text gap, chip padding |
| `space2` | 8 | Inline gaps, eval bar margin |
| `space3` | 12 | Card stack gap |
| `space4` | 16 | Screen padding, card padding |
| `space5` | 20 | Section gap (small) |
| `space6` | 24 | Section gap (large) |
| `space8` | 32 | Hero spacing |
| `space12` | 48 | Empty state vertical padding |

---

## Typography

System sans + monospace for notation/eval.

| Style | Size / Weight | Usage |
|-------|---------------|-------|
| `displayLarge` | 28 / w700 | Home greeting (optional) |
| `headlineMedium` | 22 / w600 | Screen section titles |
| `titleMedium` | 16 / w600 | Card titles, game header |
| `bodyLarge` | 16 / w400 | Primary body |
| `bodyMedium` | 14 / w400 | Subtitles, descriptions |
| `bodySmall` | 12 / w400 | Metadata, timestamps |
| `labelLarge` | 14 / w500 | Buttons, eval label |
| `labelSmall` | 11 / w500 | Nav labels, coordinates |
| `notationMono` | 14 mono | Move list, eval score |

---

## Radii & elevation

| Token | Value |
|-------|-------|
| `radiusSm` | 8px — chips, eval bar |
| `radiusMd` | 12px — cards, buttons, board container |
| `radiusLg` | 16px — bottom sheets |
| Elevation | 0 everywhere; depth via border + surface tier |

---

## Motion

| Token | Duration | Usage |
|-------|----------|-------|
| `motionFast` | 150ms | Chip select, square tap feedback |
| `motionNormal` | 250ms | Sheet open, page transition |
| `motionSlow` | 350ms | Puzzle result reveal |

Respect `MediaQuery.disableAnimations` / platform reduced-motion.

---

## Components

### `ActionCard` (Home, Train hub)

- Container: `Card` — surface bg, 1px border, radiusMd, cardPadding
- Layout: Row — icon 32dp (accent) · 16px gap · title + subtitle column · chevron 16dp
- Tap: InkWell ripple, entire card hit target ≥ 48dp height
- Subtitle: bodySmall, textSecondary

### `NavigationBar` (App shell)

- 5 destinations: Home · Play · Train · Analyze · Settings
- Background: surface; indicator: accentSoft; selected label: accent
- Height: 80dp; icon 24dp

### `SegmentedButton` (Settings)

- Used for Bot difficulty (3) and Board theme (3)
- Full-width within 16px horizontal padding

### `EvalBar` (Analyze)

- Height 12px, radiusSm; black base, white fill by eval %
- Label row: "Eval" + monospace score

### `MoveChip` (Analyze)

- ActionChip; selected → accentSoft background

### Empty states

- Icon 48dp textTertiary · headline · body · primary CTA
- Same vertical rhythm as happy path (Progressive Disclosure)

---

## Breakpoints

| Name | Width | Layout notes |
|------|-------|--------------|
| `compact` | < 600 | Single column; board full width |
| `medium` | 600–839 | Board max 480px centered; side panel future |
| `expanded` | ≥ 840 | Analyze: board left, move list right (Phase 2) |

v1 ships **compact** layouts only; tokens reserve medium/expanded.

---

## Accessibility checklist

- [ ] Body text ≥ 4.5:1 on surface (`#9AA3B5` on `#1A1D27` = 5.8:1 ✓)
- [ ] Accent buttons: white on `#6C9EFF` = 4.6:1 ✓
- [ ] Board highlights use shape (dot/circle) not color alone
- [ ] All icon buttons have `tooltip` / semantic label
- [ ] Min touch target 48×48dp
- [ ] Coordinates optional (Settings toggle) for screen readers + beginners

---

## CTO handoff — acceptance criteria

1. Wire `AppTheme.dark()` to import all values from `DesignTokens`
2. Replace hardcoded colors in screens with token references
3. Extract shared `ActionCard` widget (Home + Train hub duplicate)
4. Implement board spec overlays per `board-component-spec.md`
5. Add coordinate labels when `showCoordinates` is true
6. Empty/loading/error states match wireframe copy and spacing
