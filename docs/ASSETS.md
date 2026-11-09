# Sique Application Assets & Provenance Catalog

## 1. Typography Assets

The application bundles static Open Font License (OFL) typeface files individually in `pubspec.yaml`:

| Asset File | Weight | Purpose | License |
|---|---|---|---|
| `assets/fonts/Inter-Regular.ttf` | 400 | Body, captions, default UI text | SIL Open Font License 1.1 (`docs/OFL.txt`) |
| `assets/fonts/Inter-Medium.ttf` | 500 | Form labels, button subtext | SIL Open Font License 1.1 (`docs/OFL.txt`) |
| `assets/fonts/Inter-SemiBold.ttf` | 600 | Headings, card titles, badges | SIL Open Font License 1.1 (`docs/OFL.txt`) |
| `assets/fonts/Inter-Bold.ttf` | 700 | Headline metrics, calorie ring numbers | SIL Open Font License 1.1 (`docs/OFL.txt`) |
| `assets/fonts/Inter-Black.ttf` | 900 | Heavy display numbers | SIL Open Font License 1.1 (`docs/OFL.txt`) |

Tabular figures (`FontFeature.tabularFigures()`) are programmatically applied to all numeric readouts to ensure uniform glyph advance widths.

## 2. Launcher & System Icon Assets

| Asset Resource | Type | Purpose | Status |
|---|---|---|---|
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | Adaptive Icon Resource | Android 8.0+ adaptive icon | Active |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml` | Adaptive Icon Resource | Circular launchers | Active |
| `android/app/src/main/res/drawable/ic_launcher_foreground.xml` | Vector Drawable | Geometric 'S' mark foreground | **Clean-Room Placeholder** |
| `android/app/src/main/res/drawable/ic_launcher_monochrome.xml` | Vector Drawable | Android 13+ themed icon silhouette | **Clean-Room Placeholder** |
| `android/app/src/main/res/values/colors.xml` | Color Resource | `ic_launcher_background` (`#0B0B0E`) | Active |

### Launcher Icon Clean-Room Placeholder Notice
The geometric 'S' mark vector asset is an original clean-room placeholder designed from scratch without reusing any legacy launcher art. It is safe-zone compliant with Android adaptive icon specifications and ready to be swapped with finalized production branding. See `docs/LAUNCHER_ICONS.md` for details.

## 3. Pruned Legacy Assets

The following unused animation assets were pruned to eliminate unnecessary binary bundle weight:
- Legacy AI demo animation (Pruned: 3.59 MB)
- Legacy loading spinner animation (Pruned: 6.4 KB)
- Legacy v2 loading animation (Pruned: 15.6 KB)

Total storage reclaimed: ~3.62 MB.
Zero runtime references to Rive dependencies remain in code.
