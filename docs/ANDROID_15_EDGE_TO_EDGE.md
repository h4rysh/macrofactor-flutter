# Android 15 Edge-to-Edge System UI Verification Protocol

## 1. Overview & Architectural Context

Starting with Android 15 (API 35), edge-to-edge window drawing is enforced by the operating system. Application content draws behind transparent status and gesture navigation bars by default.
Sique v2.0.0 is configured with:
1. `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`
2. `SystemChrome.setSystemUIOverlayStyle(...)` with `systemNavigationBarContrastEnforced: false` and `systemStatusBarContrastEnforced: false`
3. Transparent status and navigation bars with `Brightness.light` foreground icon brightness to match the dark Obsidian theme (`#0B0B0E`).
4. `ScaffoldWithNavBar` with `extendBody: true` allowing content to scroll smoothly beneath the frosted liquid glass navigation bar.

---

## 2. Physical Device Verification Protocol (10-Point Checklist)

To verify behavior on a physical Android device or emulator running Android 14/15:

### Test Environment Setup
- **OS Version**: Android 15 (API 35) or Android 14 (API 34)
- **Navigation Modes**: Test under both Gesture Navigation and 3-Button Navigation modes
- **Theme Modes**: Test under both System Dark and System Light modes

### 10-Point Verification Matrix

| Test ID | Area | Scenario | Expected Behavior | Status |
|---|---|---|---|---|
| E2E-01 | Cold Launch Splash | Device set to System Light Mode; kill process; cold launch | Window background is Obsidian (#0B0B0E); ZERO white or light flashes; seamless transition to Flutter UI | Ready |
| E2E-02 | Gesture Navigation Bar | Mode A (Gesture Navigation); inspect bottom navigation bar | Content/frosted glass dock extends completely behind the horizontal gesture pill; navigation bar is 100% transparent; no grey scrim | Ready |
| E2E-03 | Bottom Bar Touch Ergonomics | Mode A; tap bottom navigation icons and center action (+) button | Bottom items have sufficient padding (SafeArea); taps do not conflict with or accidentally trigger Android home swipe | Ready |
| E2E-04 | 3-Button Navigation | Mode B (3-Button Navigation); inspect navigation bar | 3-button icons (Back, Home, Overview) render in light/white; no collision or clipping with Scaffold navigation bar items | Ready |
| E2E-05 | Soft Keyboard (IME) Inset | Open food search or profile target input; tap to summon IME | Soft keyboard animates up smoothly (`adjustResize`); input and Save CTA remain fully visible above keyboard; no layout overflow | Ready |
| E2E-06 | Keyboard Dismissal | Dismiss IME via Android back gesture or tap outside | UI transitions smoothly back to resting layout without black bars, white flashes, or viewport stutter | Ready |
| E2E-07 | Status Bar Scroll Bleed | Scroll timeline in Food Log or Dashboard | Status bar icons (clock, battery, Wi-Fi) remain clearly legible (light brightness); content scrolls seamlessly beneath status bar | Ready |
| E2E-08 | Notch & Cutout Handling | Rotate or test on device with display cutout / punch-hole camera | Header content respects safe top padding; no clipping into camera cutout | Ready |
| E2E-09 | Predictive Back Gesture | Navigate to sub-screen; perform slow edge swipe from left/right | Android 14/15 predictive back animation displays smoothly without letterbox glitches; completing/cancelling swipe behaves predictably | Ready |
| E2E-10 | Dynamic Theme Switch | Toggle OS between Light and Dark in Android Quick Settings | Sique maintains Obsidian dark theme; status bar and nav bar icons remain light; no color inversion occurs | Ready |

---

## 3. Emulation & CI Note
Full gesture navigation and hardware display cutout verification require testing on physical hardware or an Android 15 system image with Google APIs. Automated widget and unit tests verify the programmatic system UI overlay and edge-to-edge configuration.
