# Font Licensing, Static Weighing & OpenType Tabular Figures (`tnum`) Verification

**Document Version**: 2.0.0  
**Target Application**: Sique (`h4rysh/macrofactor-flutter`)  
**Verification Tooling**: Python `fontTools` v4.60.2 (`ttLib`, `varLib.instancer`)  
**Date**: 2026-11-09  

---

## 1. Executive Summary

As required by **Requirement R1** and **Requirement R2** of the Sique v2.0.0 Production Hardening specification:
1. **Unconfirmed & Proprietary Fonts Dropped**: Inspection of the metadata in `MacroSans-*.ttf` font files revealed proprietary in-house copyright restrictions (`Copyright (c) 2025 by MacroFactor`). Furthermore, `MacroSans` completely lacks OpenType `tnum` (tabular figures) support. `MacroSans` has been dropped from the design system and removed from `pubspec.yaml`.
2. **Open-Licensed Font Family Evaluated**: Both `DM Sans` and `Inter` were evaluated under the SIL Open Font License 1.1.
   - `DM Sans` (`DMSans-VariableFont_opsz,wght.ttf`) lacks the OpenType `tnum` feature in its `GSUB` table, exhibiting variable digit advance widths ('1' = 342 vs '0' = 656 font units).
   - `Inter` (`Inter-VariableFont_opsz,wght.ttf`) contains a fully populated `tnum` feature mapping digits 0–9 to tabular glyphs with a uniform advance width of **1328 font units**.
3. **Static Weights Instantiated for Deterministic Rendering**: To eliminate variable-font rendering discrepancies across Android and iOS skia/impeller text engines, static instances with explicit weights (400 Regular, 500 Medium, 600 SemiBold, 700 Bold, 900 Black) were generated using `fontTools.varLib.instancer` at optical size 14.0, preserving `tnum` support in each static weight file.
4. **Individual Asset Declarations**: The directory bundle `- assets/fonts/` in `pubspec.yaml` was replaced with individual explicit declarations.

---

## 2. Font Licensing Audit Table

| Font File | Declared Family | Copyright Holder | License Type | Commercial / Open Redistribution | Verdict |
|---|---|---|---|---|---|
| `MacroSans-*.ttf` | MacroSans | Reset Type Studio / Pentagram for MacroFactor | Proprietary In-House ("custom font only for in-house use") | **PROHIBITED** | **DROPPED** |
| `DMSans-*.ttf` | DM Sans | The DM Sans Project Authors | SIL Open Font License 1.1 | Permitted | Rejected (Lacks `tnum`) |
| `Inter-*.ttf` | Inter | The Inter Project Authors (Rasmus Andersson) | SIL Open Font License 1.1 | **PERMITTED** | **ADOPTED** |
| `NotoSansJP-*.ttf` | Noto Sans JP | Adobe Systems | SIL Open Font License 1.1 | Permitted | Pruned (Unused dead asset) |
| `CustomIcon.ttf` | MyFlutterApp | fluttericon.com | Open / Attribution | Permitted | Pruned (Unused dead asset) |

The complete SIL Open Font License 1.1 text for Inter is preserved in `docs/OFL.txt`.

---

## 3. OpenType `tnum` (Tabular Figures) & Advance Width Analysis

### 3.1 `fontTools` Inspection Methodology
Verification was executed via automated Python scripts using `fontTools.ttLib.TTFont` to parse:
1. The `GSUB` (Glyph Substitution) table `FeatureList` and `LookupList` for the `'tnum'` feature tag.
2. The `cmap` (Character to Glyph Index Mapping) table for ASCII digits `'0'` through `'9'`.
3. The `hmtx` (Horizontal Metrics) table for glyph advance widths.

### 3.2 Evaluation Results

#### A. `MacroSans-Regular.ttf`
- `GSUB` Feature Tags: `['aalt', 'ccmp', 'frac', 'locl', 'salt', 'sinf', 'ss01', 'subs', 'sups']`
- `tnum` Supported: **NO**
- Proportional Digit Advance Widths:
  - `'0'`: 961 font units
  - `'1'`: 689 font units (28% narrower than '0')
  - `'2'`: 821 font units
  - `'4'`: 847 font units
- Impact: Severe horizontal jitter when updating numerical counters (`AnimatedCountText`) and macro gauge calorie readouts.

#### B. `DMSans-VariableFont_opsz,wght.ttf`
- `GSUB` Feature Tags: `['aalt', 'calt', 'case', 'ccmp', 'dnom', 'frac', 'liga', 'locl', 'numr', 'ordn', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08', 'sups']`
- `tnum` Supported: **NO**
- Proportional Digit Advance Widths:
  - `'0'`: 656 font units
  - `'1'`: 342 font units (48% narrower than '0')
  - `'2'`: 589 font units
  - `'6'`: 624 font units
- Impact: Unsuitable for animated count-ups or tabular nutritional statistics.

#### C. `Inter` (Source Variable & Generated Static Instances)
- `GSUB` Feature Tags: 41 features, including **`'tnum'`** and `'pnum'`.
- `tnum` Supported: **YES**
- Glyph Substitution Mapping:
  - `zero`  (1292 font units) $\rightarrow$ `zero.tf`  (**1328 font units**)
  - `one`   (833 font units)  $\rightarrow$ `one.tf`   (**1328 font units**)
  - `two`   (1249 font units) $\rightarrow$ `two.tf`   (**1328 font units**)
  - `three` (1265 font units) $\rightarrow$ `three.tf` (**1328 font units**)
  - `four`  (1323 font units) $\rightarrow$ `four.tf`  (**1328 font units**)
  - `five`  (1215 font units) $\rightarrow$ `five.tf`  (**1328 font units**)
  - `six`   (1270 font units) $\rightarrow$ `six.tf`   (**1328 font units**)
  - `seven` (1159 font units) $\rightarrow$ `seven.tf` (**1328 font units**)
  - `eight` (1267 font units) $\rightarrow$ `eight.tf` (**1328 font units**)
  - `nine`  (1270 font units) $\rightarrow$ `nine.tf`  (**1328 font units**)
- Uniform Advance Width: **Exactly 1328 font units** across all 10 decimal digits.
- Impact: When `fontFeatures: [FontFeature.tabularFigures()]` is active, digits occupy identical horizontal boundaries, eliminating character jitter and layout shifts during count animations.

---

## 4. Static Font Weight Generation

Variable fonts can exhibit non-deterministic weight clamping or antialiasing artifacts across older Android API levels and certain Linux CI headless testing configurations. Static TTF instances were generated from `Inter-VariableFont_opsz,wght.ttf` using `fontTools.varLib.instancer` at optical size 14.0:

| Generated File | Weight | FontTools Verification | File Size |
|---|---|---|---|
| `assets/fonts/Inter-Regular.ttf` | 400 (Regular) | `tnum` verified $\rightarrow$ 1328 width | 340,556 bytes |
| `assets/fonts/Inter-Medium.ttf` | 500 (Medium) | `tnum` verified $\rightarrow$ 1328 width | 341,128 bytes |
| `assets/fonts/Inter-SemiBold.ttf` | 600 (SemiBold) | `tnum` verified $\rightarrow$ 1328 width | 341,796 bytes |
| `assets/fonts/Inter-Bold.ttf` | 700 (Bold) | `tnum` verified $\rightarrow$ 1328 width | 342,248 bytes |
| `assets/fonts/Inter-Black.ttf` | 900 (Black) | `tnum` verified $\rightarrow$ 1328 width | 342,992 bytes |

---

## 5. `pubspec.yaml` Specification

`pubspec.yaml` font asset configuration declares individual files with explicit weights:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/fonts/Inter-Regular.ttf
    - assets/fonts/Inter-Medium.ttf
    - assets/fonts/Inter-SemiBold.ttf
    - assets/fonts/Inter-Bold.ttf
    - assets/fonts/Inter-Black.ttf
    - assets/foods/
    - assets/animations/
    - assets/metadata/
    - assets/database/
    - assets/data/

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
        - asset: assets/fonts/Inter-Black.ttf
          weight: 900
```
