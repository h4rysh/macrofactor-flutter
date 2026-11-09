# Intended Visual Changes Specification

**Document Version**: 2.0.0  
**Target Application**: Sique (`h4rysh/macrofactor-flutter`)  
**Scope**: Visual Styling, Color Contrast Hardening & Typography Transition  
**Date**: 2026-11-09  

---

## 1. Overview & Purpose

This document establishes the authoritative specification for all intentional visual styling modifications made during the production hardening of the Sique application. Every visual variation observed during visual regression testing, automated token contrast evaluation, and subsequent baseline golden tests must map directly to one of the documented changes listed below.

---

## 2. Inventory of Intended Visual Changes

### 2.1 Font Family Transition: Dropping `MacroSans` $\rightarrow$ Adopting `Inter`
- **Previous Implementation**: Custom `MacroSans` in-house font files bundled previously, supplemented by `DM Sans` for body text. Neither font supported the OpenType `tnum` (tabular figures) feature.
- **New Implementation**: Standardized on the open-licensed `Inter` typeface family across all 15 Material 3 typography scale roles (`AppTypography`). Static weights (Regular 400, Medium 500, SemiBold 600, Bold 700, Black 900) are declared with explicit weights in `pubspec.yaml`.
- **Visual Impact**: Clean, modern humanist-grotesque letterforms with consistent vertical alignment across screen headers, card titles, and body content. Numeric readouts use `FontFeature.tabularFigures()`, eliminating character jitter on dynamic counters.
- **Justification**: Licensing compliance under the SIL Open Font License 1.1 (`docs/OFL.txt`) and technical necessity for jitter-free count-up animations (`docs/FONT_VERIFICATION.md`).

---

### 2.2 `textMuted` Contrast Hardening: `#63636E` $\rightarrow$ `#8E8E9A`
- **Previous Color**: `#63636E` (Dark Slate Gray)
  - Contrast on `cardElevated` (`#1F1F26`): **2.76:1** (FAILED WCAG AA normal text requirement $\ge$ 4.5:1)
  - Contrast on `cardSurface` (`#16161C`): **3.04:1** (FAILED)
  - Contrast on `surface` (`#141418`): **3.10:1** (FAILED)
  - Contrast on `background` (`#0B0B0E`): **3.31:1** (FAILED)
- **New Color**: `#8E8E9A` (Balanced Neutral Gray)
  - Contrast on `cardElevated` (`#1F1F26`): **5.06:1** (PASSED $\ge$ 4.5:1)
  - Contrast on `cardSurface` (`#16161C`): **5.56:1** (PASSED $\ge$ 4.5:1)
  - Contrast on `surface` (`#141418`): **5.67:1** (PASSED $\ge$ 4.5:1)
  - Contrast on `background` (`#0B0B0E`): **6.07:1** (PASSED $\ge$ 4.5:1)
  - Contrast on `cardBorder` (`#26262E`): **4.64:1** (PASSED $\ge$ 4.5:1)
- **Visual Impact**: Captions, timestamps, and placeholder labels appear slightly brighter, improving legibility on OLED dark backgrounds without losing subtle hierarchy.
- **Justification**: Strict adherence to WCAG 2.1 AA minimum contrast (4.5:1 for normal text < 18px). Disallowance of large-text exceptions for 12px captions.

---

### 2.3 Protein Semantic Color Shift: Warm Peach (`#FB923C`) $\rightarrow$ Rose / Crimson (`#F43F5E`)
- **Previous Color**: `#FB923C` (Warm Peach / Coral, Hue 28°)
  - Hue delta from `calories` (`#FF5722`, Hue 14°): **only 14°**
  - Defect: Calories and protein were both warm orange hues, creating perceptual confusion in multi-segment rings (`macro_gauge_ring.dart`) and mini progress bars.
- **New Color**: `#F43F5E` (Rose / Crimson, Hue 350°)
  - Hue delta from `calories` (`#FF5722`, Hue 14°): **66°**
  - Perceptual distinction: Clean separation between Flame Orange (energy/calories), Rose Crimson (muscle/protein), Cyan Aqua (carbohydrates), and Lavender (fats).
  - Contrast on `cardElevated` (`#1F1F26`): **4.46:1** (exceeds 3.0:1 non-text requirement)
  - Contrast on `cardSurface` (`#16161C`): **4.91:1**
- **Visual Impact**: The protein arc in the dashboard macro ring, timeline badges, and nutrition summary pills now displays a distinct vibrant rose hue clearly distinguishable from orange calories.
- **Justification**: Requirement R2 explicit mandate: "assign protein a color visually distinct from calories (avoiding nearly identical warm hues)".

---

### 2.4 Elevated Button Foreground Text: White (`#FFFFFF`) $\rightarrow$ Dark Obsidian (`#0B0B0E`)
- **Previous Implementation**: Ad-hoc button styles frequently relied on white text (`#FFFFFF`) on `#FF5722` (Flame Orange) buttons.
  - Contrast ratio: **3.19:1** (FAILED WCAG AA 4.5:1 normal text contrast).
- **New Implementation**: Standardized in `ElevatedButtonThemeData` with `backgroundColor: AppColors.calories` (`#FF5722`) and `foregroundColor: AppColors.buttonForeground` (`#0B0B0E`).
  - Contrast ratio: **6.21:1** (PASSED WCAG AA 4.5:1 requirement).
- **Visual Impact**: Primary action buttons throughout the app (modal confirmations, setup flows, activation buttons) feature sharp, crisp dark typography on vibrant orange button surfaces.
- **Justification**: Mathematical WCAG AA contrast compliance on primary CTA surfaces.

---

### 2.5 Active Accent & Focus Ring: Sapphire (`#0055E1`) $\rightarrow$ Electric Blue (`#3B82F6`)
- **Previous Color**: `#0055E1` (Deep Sapphire Blue)
  - Contrast on `cardElevated` (`#1F1F26`): **2.64:1** (FAILED WCAG non-text graphic contrast 3.0:1)
  - Contrast on `cardSurface` (`#16161C`): **2.91:1** (FAILED)
  - Contrast on `cardBorder` (`#26262E`): **2.43:1** (FAILED)
- **New Color**: `#3B82F6` (Electric Blue)
  - Contrast on `cardBorder` (`#26262E`): **4.08:1** (PASSED $\ge$ 3.0:1)
  - Contrast on `cardElevated` (`#1F1F26`): **4.45:1** (PASSED $\ge$ 3.0:1)
  - Contrast on `cardSurface` (`#16161C`): **4.90:1** (PASSED $\ge$ 3.0:1)
  - Contrast on `surface` (`#141418`): **5.00:1** (PASSED $\ge$ 3.0:1)
  - Contrast on `background` (`#0B0B0E`): **5.34:1** (PASSED $\ge$ 3.0:1)
- **Visual Impact**: Active radio indicators, input focus borders, and slider active tracks appear crisp and clearly defined against dark container backgrounds.
- **Justification**: WCAG 2.1 Success Criterion 1.4.11 (Non-text Contrast $\ge$ 3.0:1).

---

## 3. Contrast Compliance Verification Matrix

| Foreground Token | Background Surface | Contrast Ratio | Required Ratio | WCAG 2.1 Level | Status |
|---|---|---|---|---|---|
| `textPrimary` (`#F5F5F7`) | `cardElevated` (`#1F1F26`) | 15.04:1 | 4.5:1 | Level AA / AAA | **PASS** |
| `textPrimary` (`#F5F5F7`) | `cardSurface` (`#16161C`) | 16.55:1 | 4.5:1 | Level AA / AAA | **PASS** |
| `textPrimary` (`#F5F5F7`) | `surface` (`#141418`) | 16.87:1 | 4.5:1 | Level AA / AAA | **PASS** |
| `textPrimary` (`#F5F5F7`) | `background` (`#0B0B0E`) | 18.05:1 | 4.5:1 | Level AA / AAA | **PASS** |
| `textSecondary` (`#A1A1AA`) | `cardElevated` (`#1F1F26`) | 6.39:1 | 4.5:1 | Level AA | **PASS** |
| `textSecondary` (`#A1A1AA`) | `cardSurface` (`#16161C`) | 7.03:1 | 4.5:1 | Level AA | **PASS** |
| `textSecondary` (`#A1A1AA`) | `background` (`#0B0B0E`) | 7.67:1 | 4.5:1 | Level AA | **PASS** |
| `textMuted` (`#8E8E9A`) | `cardBorder` (`#26262E`) | 4.64:1 | 4.5:1 | Level AA | **PASS** |
| `textMuted` (`#8E8E9A`) | `cardElevated` (`#1F1F26`) | 5.06:1 | 4.5:1 | Level AA | **PASS** |
| `textMuted` (`#8E8E9A`) | `cardSurface` (`#16161C`) | 5.56:1 | 4.5:1 | Level AA | **PASS** |
| `textMuted` (`#8E8E9A`) | `background` (`#0B0B0E`) | 6.07:1 | 4.5:1 | Level AA | **PASS** |
| `buttonForeground` (`#0B0B0E`) | `calories` (`#FF5722`) | 6.21:1 | 4.5:1 | Level AA | **PASS** |
| `calories` (`#FF5722`) | `cardElevated` (`#1F1F26`) | 5.18:1 | 3.0:1 | Non-text Graphics | **PASS** |
| `protein` (`#F43F5E`) | `cardElevated` (`#1F1F26`) | 4.46:1 | 3.0:1 | Non-text Graphics | **PASS** |
| `carbs` (`#38BDF8`) | `cardElevated` (`#1F1F26`) | 7.64:1 | 3.0:1 | Non-text Graphics | **PASS** |
| `fat` (`#A78BFA`) | `cardElevated` (`#1F1F26`) | 6.02:1 | 3.0:1 | Non-text Graphics | **PASS** |
| `expenditure` (`#34D399`) | `cardElevated` (`#1F1F26`) | 8.52:1 | 3.0:1 | Non-text Graphics | **PASS** |
| `trendWeight` (`#C084FC`) | `cardElevated` (`#1F1F26`) | 6.20:1 | 3.0:1 | Non-text Graphics | **PASS** |
| `activeBlue` (`#3B82F6`) | `cardBorder` (`#26262E`) | 4.08:1 | 3.0:1 | Non-text Graphics | **PASS** |
| `activeBlue` (`#3B82F6`) | `cardElevated` (`#1F1F26`) | 4.45:1 | 3.0:1 | Non-text Graphics | **PASS** |
