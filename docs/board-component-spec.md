# ChessBoard — Component Specification v1

> **Widget:** `lib/core/widgets/chess_board.dart`  
> **Tokens:** `DesignTokens` in `lib/core/theme/design_tokens.dart`  
> **Constants:** migrate from `lib/core/constants/board_constants.dart`

---

## Purpose

Reusable 8×8 interactive board for Play, Analyze (read-only), Openings, Tactics, and Square Trainer. Supports drag-free tap-to-move (v1), legal move hints, last-move highlight, orientation flip, and themeable square colors.

---

## Anatomy

```
┌──────────────────────────────────────┐
│  a   b   c   d   e   f   g   h      │  ← coordinate row (optional)
│ ┌──────────────────────────────────┐ │
│8│ ░░ ▓▓ ░░ ▓▓ ░░ ▓▓ ░░ ▓▓          │8│
│7│ ▓▓ ░░ ▓▓ ░░ ▓▓ ░░ ▓▓ ░░          │7│
│ │  …                               │ │
│1│ ░░ ▓▓ ░░ ▓▓ ░░ ▓▓ ░░ ▓▓          │1│
│ └──────────────────────────────────┘ │
│  a   b   c   d   e   f   g   h      │
└──────────────────────────────────────┘
  AspectRatio 1:1 — width = parent constraint
```

### Layers (bottom → top)

1. **Square base** — themed light/dark alternating
2. **Highlight tint** — selected, last move, check (multiply/overlap)
3. **Legal target indicator** — dot (empty) or ring (capture)
4. **Piece** — unicode v1 → SVG neo-classical v2
5. **Coordinates** — labelSmall in square corners when enabled

---

## Board themes

| Theme ID | Label | Light square | Dark square | Notes |
|----------|-------|--------------|-------------|-------|
| `classic` | Classic | `#EEEED2` | `#769656` | Default walnut; high familiarity (Jakob's Law) |
| `midnight` | Midnight | `#8CA2AD` | `#4B6368` | Cool tones; pairs with dark app shell |
| `tournament` | Tournament | `#E8EDF9` | `#7FA650` | High contrast; broadcast-style |

All themes maintain **≥ 3:1** square-to-square contrast for piece legibility.

---

## Interaction overlays

| State | Visual | Token | Color-independent cue |
|-------|--------|-------|----------------------|
| **Selected** | Full square tint | `selectedSquare` `#BBFFFF00` | Strongest tint |
| **Last move** | From + to squares | `lastMoveHighlight` `#66FFFF00` | Pair of squares |
| **Legal target (empty)** | Center dot 28% cell | `legalTargetEmpty` | Filled circle |
| **Legal target (capture)** | Center ring 45% α | `legalTargetCapture` | Ring on occupied |
| **Check** | King square tint | `checkHighlight` `#99FF4444` | Pulsing optional Phase 2 |

**Selection precedence:** selected > check > last move > base.

Do **not** replace square base color for legal targets (current bug) — overlay only.

---

## Input model

### Tap-to-move (v1)

1. Tap friendly piece → select + show legal targets (< 150ms, Doherty Threshold)
2. Tap legal target → fire `onMove(from, to, promotion?)`
3. Tap elsewhere / enemy piece → deselect or reselect
4. Auto-queen promotion default; picker sheet Phase 2

### Props API

```dart
ChessBoard({
  required String fen,
  required MoveCallback onMove,
  BoardOrientation orientation = BoardOrientation.white,
  String? selectedSquare,
  Set<String> highlightSquares = {}, // last move, external
  Set<String> checkSquares = {},
  bool enabled = true,
  bool moveEnabled = true,
  bool showCoordinates = false,
  void Function(String square)? onSquareTap, // Square Trainer
  Color lightColor,
  Color darkColor,
})
```

---

## Piece rendering

### v1 (current): Unicode symbols

- Font size: `cellSize * 0.62`
- Shadow: `Shadow(blurRadius: 2, color: black26)` for depth on light squares
- Set: standard Unicode chess (`pieceSymbols` map)

### v2 (planned): SVG neo-classical

- Asset path: `assets/pieces/{theme}/{color}{piece}.svg`
- Same sizing; vector scales cleanly on tablet
- Settings: piece set picker (single bundled set in v1)

---

## Coordinates

When `showCoordinates == true` (Settings toggle):

- **Files** (a–h): bottom edge if white orientation, top if black
- **Ranks** (1–8): left edge if white, right if black
- Style: `labelSmall`; light squares → `coordinateDark`, dark → `coordinateLight`
- Position: 2px inset from corner; do not overlap piece center

Square Trainer always shows coordinates (training context).

---

## Layout & sizing

| Rule | Value |
|------|-------|
| Aspect ratio | 1:1 (`AspectRatio(aspectRatio: 1)`) |
| Max width (compact) | 100% of parent minus 32px horizontal padding |
| Max width (medium+) | 480px centered |
| Min cell size | 36px (288px board) — below this, scroll or scale down |
| Square tap target | Full cell (cell size ≥ 36px; aim 44px+ on phones) |

---

## Orientation

- `BoardOrientation.white` — rank 1 at bottom (default Play as White)
- `BoardOrientation.black` — rank 8 at bottom
- Flip anim: 250ms horizontal mirror (Phase 2); instant swap v1

---

## Accessibility

| Requirement | Implementation |
|-------------|----------------|
| Screen reader | Each square: Semantics label `"e4, white pawn"` or `"empty"` |
| Color independence | Legal moves use dots/rings, not hue alone |
| Reduced motion | Skip flip animation; instant highlight changes |
| Focus | Not keyboard-first mobile; desktop Phase 3 |

---

## Usage by surface

| Surface | `enabled` | `moveEnabled` | Highlights | Coordinates |
|---------|-----------|---------------|------------|-------------|
| Play | true | true | last move | user pref |
| Analyze | false | false | last move | user pref |
| Openings | true | true | last move, hint | user pref |
| Tactics | true | true | none until solved | user pref |
| Square Trainer | true | false | prompt square | always on |

---

## Acceptance criteria (CTO)

- [ ] Legal targets render as overlay dots/rings, not square recolor
- [ ] Last-move highlight uses `lastMoveHighlight` token on from+to
- [ ] Check highlight on king square when in check (Play)
- [ ] Coordinates render per spec when Settings enabled
- [ ] `boardColorsFor()` reads from `DesignTokens.boardThemes`
- [ ] Board respects `showCoordinates` from SettingsCubit
- [ ] Semantics labels on each square
- [ ] Piece shadow visible on all three themes
