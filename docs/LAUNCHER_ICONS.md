# Android Launcher Icons & Adaptive Icon Specification

## Overview

Sique v2.0.0 ships with standard Android adaptive icons (`mipmap-anydpi-v26`) and Android 13+ themed icon support (`<monochrome>`).

## Asset Inventory

| File Path | Type | Role | Dimensions | Color |
|---|---|---|---|---|
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | Adaptive Icon Resource | Root definition | N/A | References layers |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml` | Adaptive Icon Resource | Circular launchers | N/A | References layers |
| `android/app/src/main/res/drawable/ic_launcher_foreground.xml` | Vector Drawable | Foreground mark | 108dp x 108dp | `#FF5722`, `#F43F5E`, glow `#33FF5722` |
| `android/app/src/main/res/drawable/ic_launcher_monochrome.xml` | Vector Drawable | Android 13+ Themed Icons | 108dp x 108dp | `#FFFFFF` (system tinted) |
| `android/app/src/main/res/values/colors.xml` | Color Resource | `ic_launcher_background` | N/A | Obsidian `#0B0B0E` |

## Adaptive Icon Safe Zone Compliance

Under Google's Android Adaptive Icon specification:
- **Total Viewport**: 108dp x 108dp.
- **Safe Zone**: Centered circle of diameter 66dp (radius 33dp centered at $x=54, y=54$).
- **Bleed Zone**: Outer 18dp on all four edges reserved for OEM masks (squircle, round, teardrop) and launcher parallax effects.
- **Sique Geometric 'S' Mark Geometry**:
  - Continuous dynamic Bézier curve representing energy balance and metabolic expenditure.
  - Coordinate bounds: $X \in [36, 72]$, $Y \in [28, 94]$.
  - Maximum radial extent from $(54, 54)$ is $27.2\text{dp} \le 33.0\text{dp}$, strictly inside the safe zone.
  - Zero clipping across Samsung One UI, Google Pixel Launcher, and OEM squircle masks.

## Clean-Room Placeholder Status Flag

> **IMPORTANT NOTICE: CLEAN-ROOM PLACEHOLDER**
>
> The geometric 'S' mark vector asset is a **clean-room placeholder** designed from first principles.
> Zero legacy art or external third-party proprietary artwork was reused.
> Prior to public release on app distribution stores, this asset can be updated with the finalized production brand mark by updating `ic_launcher_foreground.xml` and `ic_launcher_monochrome.xml`.
