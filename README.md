# MacroFactor (Indian Edition) • 1:1 Clean-Room Flutter Reconstruction

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.7+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![CI](https://img.shields.io/github/actions/workflow/status/h4rysh/macrofactor-flutter/ci.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=CI)
![Tests](https://img.shields.io/badge/Tests-313%2F313%20Passed-2ea44f?style=for-the-badge&logo=githubactions&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Release](https://img.shields.io/badge/Release-v1.6.0-blueviolet?style=for-the-badge)

<br/>

**A clean-room 1:1 visual & UX reconstruction of MacroFactor for Android & iOS, featuring authentic Obsidian dark UI, Apple HIG tactile animations, Liquid Glass frosted surfaces, an adherence-neutral Strategy Coaching Engine, Google Sign-In, Health Connect Hevy workout sync, and a 2,500+ Indian food database (ICMR-NIN IFCT) with 1-tap cooking oil modifiers.**

<br/>

[📥 **Download Production APK (v1.6.0)**](https://github.com/h4rysh/macrofactor-flutter/releases/download/v1.6.0/app-release.apk) • [🏷️ **Releases & Changelog**](https://github.com/h4rysh/macrofactor-flutter/releases) • [📐 **Algorithm Formulations**](#-mathematical-formulations) • [🏛️ **Architecture Spec**](#️-system-architecture)

</div>

---

## 📱 Visual & UX Reconstruction (Liquid Glass & Apple HIG)

Engineered through systematic clean-room reverse engineering analysis of the authentic application topology, design tokens, and user experience patterns:

```
Obsidian Base:     #0B0B0E  (True deep OLED dark)
Elevated Cards:    #16161C  (Subtle elevated surface)
Hairline Borders:  #26262E  (1px translucent micro-dividers)
Macro Accents:     🔥 #FF5722 Cal  •  🍗 #FB923C Protein  •  🥑 #FACC15 Fat  •  🌾 #38BDF8 Carbs  •  ⚡ #0055E1 Expenditure
```

### Apple HIG Tactile Motion & Liquid Glass Surfaces (v1.6.0)
- 🪟 **Liquid Glass Frosted Docks**: `BackdropFilter` gaussian blurs (sigma 18–20) paired with specular translucent highlight borders on `PersistentSearchBar` and `ScaffoldWithNavBar`.
- ⚡ **Odometer Number Tweens (`AnimatedCountText`)**: Numerical count-ups for calories and macronutrients powered by `Curves.easeOutCubic`.
- 🌊 **Staggered Page Reveals (`AppleStaggeredEntrance`)**: Cascading slide-fade reveals on page loads across Dashboard, Strategy, and More screens.
- 🎯 **Tactile Micro-Interactions (`AppleBouncy`)**: Zero-delay spring scale-down on tap that participates directly in Flutter's gesture arena (`onTapDown`, `onTapUp`, `onTapCancel`), preventing false triggers or stickiness in scrollable views.
- ⭕ **Animated Macro Gauge Ring (`MacroGaugeRing`)**: Concentric radial progress sweep, over-target accent arcs, and centered calorie odometers.
- ⏱️ **Boot to Food Log**: Default startup launches directly into the hourly food timeline (Index 1) with quick return to Dashboard.

---

## 🧠 Philosophy: Adherence-Neutral Nutrition

Traditional nutrition applications punish the user with bright red "over-budget" rings, guilt-inducing alerts, and arbitrary calorie deductions. When life happens and a meal is over-eaten, traditional apps ask you to starve the next day—perpetuating the restrict-binge cycle.

**MacroFactor does not judge. MacroFactor calculates.**

```
Traditional Apps:      Calories Consumed > Target  ➜  Red Shame Screen  ➜  Cut Next Day Calories
MacroFactor Engine:    Calories Consumed > Target  ➜  Observe Weight    ➜  Update Metabolic Model
```

Every day is treated as an **informative data observation**. If you ate 3,500 kcal and did not gain weight, the algorithm recognizes your metabolic expenditure is higher than anticipated and adjusts your targets **up**, not down.

| Attribute | Traditional Apps (MyFitnessPal, LoseIt) | MacroFactor (Indian Edition) |
|---|---|---|
| **Goal Deviations** | Red warning badges, deficit penalties | Adherence-neutral mathematical calibration |
| **Expenditure Model** | Static formula calculated once (Harris-Benedict) | **Dynamic Bayesian Kalman Filter** continuously adapting |
| **Scale Weight** | Raw noisy scale readings cause panic | **Bidirectional Zero-Phase EMA** with noise envelopes |
| **Coaching Strategy** | Rigid, static calorie allotments | **Adaptive Bayesian Coaching Engine** with 7-day shifting |
| **Indian Nutrition** | Crowdsourced, inaccurate generic entries | Verified **ICMR-NIN IFCT standards** with katori & piece portions |
| **Cooking Fat** | Unaccounted or manual tedious oil entry | **1-Tap Oil Modifier** (+½ tsp, +1 tsp, +1 tbsp) |
| **Fitness Wearable Sync** | Fragmented, proprietary cloud sync | **Offline-first Google Health Connect + Hevy Sync** |

---

## 🎯 MacroFactor Strategy Coaching Engine & 7-Day Shifting

The Strategy system provides an adherence-neutral virtual coach that calibrates macro targets weekly based on observed scale weight trend and logged caloric intake:

### 1. Three Coaching Modes
- **Coached**: MacroFactor dynamically updates your calorie targets and macro splits every week based on metabolic expenditure.
- **Collaborative**: You set your preferred weekly calories; MacroFactor dynamically solves and distributes your daily macros.
- **Manual**: Complete sovereignty over daily targets while retaining expenditure and trend analytics.

### 2. Five Macronutrient Distribution Styles
- **Balanced**: Moderate carbohydrates, moderate fats, optimal protein ($1.6\text{--}2.2\text{ g/kg}$).
- **Low Fat**: Prioritizes complex carbohydrates while maintaining essential fatty acid minimums ($0.5\text{ g/kg}$).
- **Low Carb**: Restricted carbohydrate ceiling with elevated fats for sustained satiety.
- **Ketogenic**: Strict $<30\text{ g}$ net carbs with high healthy fats.
- **High Protein**: Elevated protein ceiling ($2.2\text{--}2.7\text{ g/kg}$) for athletic muscle retention.

### 3. Strict 7-Day Calorie Shifting Conservation
Allows users to allocate higher calories to heavy workout days or social weekends while reducing rest day targets, adhering to strict mathematical energy conservation:

$$\sum_{d=1}^7 \text{Calories}_d = 7 \times \text{DailyAverageCalories}$$

Day-shifted macro targets reactively propagate from `dayMacroTargetForSelectedDateProvider` directly to the active Dashboard!

---

## 🏋️ Google Sign-In, Health Connect & Hevy Sync

### Local-First Sovereign Authentication
- **Google OAuth Sign-In**: Seamless authentication linking Google Avatar, Name, and Email.
- **100% Offline Sovereignty**: Account sessions are cached locally in SQLite (`user_account_session`). The app functions completely offline, with one-tap sign-out returning to local guest mode without data loss.
- **Demo Athlete Mode**: Instant one-tap evaluation profile with pre-seeded metabolic logs and Hevy workout data.

### Google Health Connect Integration
- **Background Sync**: Quietly synchronizes on app launch and app resume.
- **Manual Sync**: Dedicated "Sync Now" button inside Settings to avoid UI clutter.
- **Hevy Workout Import**: Automatically ingests `ExerciseSessionRecord` events logged by Hevy in Health Connect, tracking session title, duration, active calories burned, and timestamps.
- **Smart Scale Ingestion**: Automatically reads scale weight recordings into the local `scale_weights` table.

### Account Profile & Training Dashboard
- Total workouts synced from Hevy.
- Total workout minutes and average duration per training session.
- Weekly workout consistency and frequency tracker.
- Total and average active calories burned per workout.
- Recent Hevy workout history feed with Apple Glass cards.

---

## 🍛 HealthifyMe-Grade Indian Food Database

### 2,500+ ICMR-NIN IFCT Food Items
- Embedded offline **SQLite FTS5 full-text search engine** containing **2,500+ Indian & Global food items**.
- Curated using the **National Institute of Nutrition (ICMR-NIN) Indian Food Composition Tables (IFCT)**.
- Authentic regional cuisine coverage:
  - **South Indian**: Dosa, Idli, Medu Vada, Sambar, Rasam, Pongal, Appam, Avial, Poriyal, Chettinad Chicken, Fish Curry.
  - **North Indian**: Paneer Butter Masala, Dal Makhani, Rajma, Chole, Palak Paneer, Roti, Naan, Paratha, Biryani, Pulao.
- Native portion units: *Katori (150 ml)*, *Roti / Chapati (count)*, *Dosa / Idli (piece)*, *Ladle (60 ml)*, *Grams*, *Cups*.

### 1-Tap Cooking Oil Modifier
Home-cooked Indian meals frequently vary in oil and ghee usage. Instead of breaking down a dish into its raw ingredients every time:
- Select any dish (e.g. *Bhindi Masala* or *Egg Curry*).
- Tap the **Oil Modifier**:
  - `No Extra Oil` (Base recipe)
  - `+½ tsp Oil / Ghee` (+22.5 kcal, +2.5g fat)
  - `+1 tsp Oil / Ghee` (+45.0 kcal, +5.0g fat)
  - `+1 tbsp Oil / Ghee` (+120.0 kcal, +14.0g fat)
- The nutrition aggregate updates instantaneously in memory.

---

## 📐 Mathematical Formulations

### A. Exponential Moving Average with Dynamic $\Delta t$ Interval Scaling
For consecutive scale weights $w_t$ sampled at non-uniform intervals $\Delta t$:

$$\alpha_{\text{scaled}} = 1 - (1 - \alpha_0)^{\Delta t}$$

$$\text{EMA}_t = \alpha_{\text{scaled}} \cdot w_t + (1 - \alpha_{\text{scaled}}) \cdot \text{EMA}_{t-1}$$

Zero-phase backward smoothing pass:

$$\text{Smoothed}_t = \frac{1}{2} \left( \text{EMA}_t^{\text{forward}} + \text{EMA}_t^{\text{backward}} \right)$$

### B. Bayesian Kalman State Estimation for TDEE (V3)
The latent state $x_k$ (Expenditure in kcal/day) is tracked through a transition and measurement model:

$$\text{Prior State}: \quad \hat{x}_{k|k-1} = \hat{x}_{k-1}$$

$$\text{Prior Covariance}: \quad P_{k|k-1} = P_{k-1} + Q_k$$

$$\text{Observed Expenditure}: \quad z_k = C_k - \kappa \cdot \Delta w_k \quad (\kappa = 7700\text{ kcal/kg})$$

$$\text{Kalman Gain}: \quad K_k = \frac{P_{k|k-1}}{P_{k|k-1} + R_k}$$

$$\text{Posterior Update}: \quad \hat{x}_k = \hat{x}_{k|k-1} + K_k (z_k - \hat{x}_{k|k-1})$$

$$\text{Flux Clamp}: \quad \Delta x_k = \text{clamp}(\hat{x}_k - \hat{x}_{k-1}, -150, +150)$$

---

## 🏛️ System Architecture

```mermaid
flowchart TD
    subgraph Presentation ["Presentation Layer (Flutter + Riverpod)"]
        Nav["ScaffoldWithNavBar (Frosted Dock + Center Action FAB)"]
        Dashboard["DashboardScreen (Staggered Cards + Odometers)"]
        FoodLog["FoodLogScreen (Hourly Timeline & Date Ribbon)"]
        Strategy["StrategyScreen (Coaching Hero, 7-Day Shifting, Check-ins)"]
        More["MoreScreen (Account Profile, Settings, Exports)"]
        Profile["AccountProfileScreen (Google User, Hevy Training Stats)"]
        Onboarding["OnboardingCoordinator (Welcome, Wizard, AuthGate)"]
        
        Widgets["Tactile Widgets (AnimatedCountText, AppleBouncy, AppleGlassCard)"]
    end

    subgraph State ["State Management (Riverpod Providers)"]
        AppProv["app_providers (User Profile, Daily Targets, Plate)"]
        StratProv["strategy_providers (Macro Program, 7-Day Shifting, Check-ins)"]
        AuthProv["auth_providers (Google Auth State, Offline Session)"]
        HealthProv["health_sync_providers (Health Connect, Hevy Workouts)"]
    end

    subgraph Domain ["Domain Layer (Pure Dart)"]
        TrendAlgo["WeightTrendV2Series Engine"]
        ExpAlgo["ExpenditureAlgorithmV3 Engine"]
        CoachAlgo["CoachingEngine (Check-in Calibration, Shifting)"]
        Models["Models (MacroProgram, WorkoutSession, FoodItem)"]
    end

    subgraph Data ["Data Layer (SQLite & External Services)"]
        DB[("AppDatabase (Drift SQLite)")]
        FTS[("FTS5 Full-Text Food Catalog")]
        GoogleAuth["GoogleAuthService (OAuth 2.0)"]
        HealthSync["HealthConnectSyncAdapter (Health Connect API)"]
    end

    Nav --> Dashboard & FoodLog & Strategy & More
    More --> Profile
    Onboarding --> Dashboard
    
    Dashboard & Strategy & FoodLog --> Widgets
    Presentation --> State
    
    State --> Domain
    State --> Data
    
    Domain --> Models
    Data --> DB
    DB --> FTS
    Data --> GoogleAuth & HealthSync
```

---

## 🧪 Verification & Quality Gates

Every commit passes automated local verification and GitHub Actions CI pipelines:

| Check | Tool / Standard | Result |
|---|---|---|
| **Static Code Analysis** | `flutter analyze` | **0 issues found** (Clean) |
| **Automated Test Suite** | `flutter test` | **313 / 313 Passed (100% Green)** |
| **Code Formatting** | `dart format .` | **Enforced in CI (`--set-exit-if-changed .`)** |
| **Modularity Ceiling** | Architectural Rule | **100% of files strictly $\le 800$ lines** |
| **Android Release Build** | `flutter build apk --release` | **Clean exit (`app-release.apk`, 83.8 MB)** |
| **CI Automation** | GitHub Actions (`Flutter CI`) | **All 10 steps green** |

---

## 🚀 Quick Start & Development

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.29.0 or higher
- Android SDK 34 / Java 17

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/h4rysh/macrofactor-flutter.git
cd macrofactor-flutter
flutter pub get
```

### 2. Verify Code Quality & Tests
```bash
# Verify formatting across all files
dart format --output=none --set-exit-if-changed .

# Run static analysis
flutter analyze

# Run all 313 unit, widget, and E2E journey tests
flutter test

# Run with test coverage report
flutter test --coverage
```

### 3. Run on Emulator / Physical Device
```bash
flutter run
```

### 4. Build Production Release APK
```bash
flutter build apk --release
```
The compiled release binary is output to `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

<div align="center">
<sub>Crafted with clean-room precision, adherence-neutral science, and deep reverse engineering fidelity.</sub>
</div>
