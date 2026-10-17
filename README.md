# MacroFactor (Indian Edition)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.29.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.7.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Tests](https://img.shields.io/badge/Tests-27%2F27%20Passed-2ea44f?style=for-the-badge&logo=githubactions&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Release](https://img.shields.io/badge/Release-v1.0.0-blueviolet?style=for-the-badge)

<br/>

**A clean-room, adherence-neutral macro tracking and metabolic expenditure application for Android & iOS, featuring an authentic 2,500+ Indian food database (ICMR-NIN IFCT), 1-tap oil modifiers, and dynamic Bayesian energy balance algorithms.**

[Download Production APK (v1.0.0)](https://github.com/h4rysh/macrofactor-flutter/releases/download/v1.0.0/app-release.apk) • [View Architecture](docs/ARCHITECTURE.md) • [Algorithm Specifications](docs/ALGORITHMS.md)

</div>

---

## 📖 Table of Contents
- [Philosophy: Adherence-Neutral Nutrition](#-philosophy-adherence-neutral-nutrition)
- [Key Features](#-key-features)
  - [1. Dynamic Expenditure Engine (Kalman Filter V3)](#1-dynamic-expenditure-engine-kalman-filter-v3)
  - [2. Weight Trend Smoothing (EMA V2 + Noise Envelope)](#2-weight-trend-smoothing-ema-v2--noise-envelope)
  - [3. HealthifyMe-Grade Indian Food Database](#3-healthifyme-grade-indian-food-database)
  - [4. 1-Tap Cooking Oil Modifier](#4-1-tap-cooking-oil-modifier)
  - [5. Dark High-Contrast UI & Custom Macro Gauges](#5-dark-high-contrast-ui--custom-macro-gauges)
- [Mathematical Formulations](#-mathematical-formulations)
- [System Architecture](#-system-architecture)
- [Verification & Quality Gate](#-verification--quality-gate)
- [Quick Start & Development](#-quick-start--development)
- [License](#-license)

---

## 🧠 Philosophy: Adherence-Neutral Nutrition

Traditional nutrition applications punish the user with bright red "over-budget" rings, guilt-inducing alerts, and arbitrary calorie deductions. When life happens and a meal is over-eaten, traditional apps ask you to starve the next day—leading to the all-too-common restrict-binge cycle.

**MacroFactor does not judge. MacroFactor calculates.**

```
Traditional Apps:      Calories Consumed > Target  ➜  Red Shame Screen  ➜  Cut Next Day Calories
MacroFactor Engine:    Calories Consumed > Target  ➜  Observe Weight    ➜  Update Metabolic Model
```

Whether you eat under, on, or over your target, the app's algorithms simply treat every day as an **informative data observation**. If you ate 3,500 kcal and did not gain weight, the algorithm recognizes your metabolic rate is higher than anticipated and adjusts your expenditure **up**, not down.

| Attribute | Traditional Apps (MyFitnessPal, LoseIt) | MacroFactor (Indian Edition) |
|---|---|---|
| **Goal Deviations** | Red warning badges, deficit penalties | Adherence-neutral mathematical calibration |
| **Expenditure Model** | Static formula calculated once (Harris-Benedict) | **Dynamic Bayesian Kalman Filter** continuously adapting |
| **Scale Weight** | Raw noisy scale readings cause panic | **Bidirectional Zero-Phase EMA** with noise envelopes |
| **Indian Nutrition** | Crowdsourced, inaccurate generic entries | Verified **ICMR-NIN IFCT standards** with katori & piece portions |
| **Cooking Fat** | Unaccounted or manual tedious oil entry | **1-Tap Oil Modifier** (+½ tsp, +1 tsp, +1 tbsp) |

---

## ✨ Key Features

### 1. Dynamic Expenditure Engine (Kalman Filter V3)
- Models the human body as an energy balance dynamic system.
- Continuously calculates your **Total Daily Energy Expenditure (TDEE)** from daily caloric intake and change in trend weight.
- **$\pm 150\text{ kcal}$ Daily Flux Clamp**: Dampens measurement noise and prevents runaway targets caused by acute fluid retention.
- **Graceful Missing-Day Handling**: Up to 3 days of missing logs expand prior covariance without distorting mean; long breaks pause adjustments safely without penalizing the user.

### 2. Weight Trend Smoothing (EMA V2 + Noise Envelope)
- Isolates true tissue changes (fat and muscle) from erratic daily water fluctuations (glycogen replenishment, sodium, hydration).
- Bidirectional zero-phase smoothing eliminates phase lag.
- Bilateral biological noise envelope ($2.5\times$ rolling Median Absolute Deviation).
- Forward trajectory projection based on thermodynamic deficit ($7,700\text{ kcal/kg}$).

### 3. HealthifyMe-Grade Indian Food Database
- Embedded offline **SQLite FTS5 full-text search engine** containing **2,500+ Indian & Global food items**.
- Curated using the **National Institute of Nutrition (ICMR-NIN) Indian Food Composition Tables (IFCT)**.
- Authentic regional Indian cuisine representation:
  - **South Indian**: Dosa, Idli, Medu Vada, Sambar, Rasam, Pongal, Appam, Avial, Poriyal, Chettinad Chicken, Fish Curry.
  - **North Indian**: Paneer Butter Masala, Dal Makhani, Rajma, Chole, Palak Paneer, Roti, Naan, Paratha, Biryani, Pulao.
- Native portion units: *Katori (150 ml)*, *Roti / Chapati (count)*, *Dosa / Idli (piece)*, *Ladle (60 ml)*, *Grams*, *Cups*.

### 4. 1-Tap Cooking Oil Modifier
Home-cooked Indian meals frequently vary in oil and ghee usage. Instead of breaking down a dish into its raw ingredients every time you cook:
- Select any dish (e.g. *Bhindi Masala* or *Egg Curry*).
- Tap the **Oil Modifier**:
  - `No Extra Oil` (Base recipe)
  - `+½ tsp Oil / Ghee` (+22.5 kcal, +2.5g fat)
  - `+1 tsp Oil / Ghee` (+45.0 kcal, +5.0g fat)
  - `+1 tbsp Oil / Ghee` (+120.0 kcal, +14.0g fat)
- The nutrition aggregate updates instantaneously in memory.

### 5. Dark High-Contrast UI & Custom Macro Gauges
- Tailored for OLED displays with `#121620` background and `#1A1F2C` elevated cards.
- **Concentric Multi-Ring Gauge**: Custom-drawn canvas rings displaying calories, protein, carbs, and fat progress simultaneously without visual clutter.
- Bottom sheet Quick Log modal for breakfast, lunch, dinner, snacks, and scale weights.

---

## 📐 Mathematical Formulations

### A. Exponential Moving Average with Dynamic $\Delta t$ Interval Scaling
For consecutive scale weights $w_t$ sampled at non-uniform intervals $\Delta t$:

$$\alpha_{\text{scaled}} = 1 - (1 - \alpha_0)^{\Delta t}$$

$$\text{EMA}_t = \alpha_{\text{scaled}} \cdot w_t + (1 - \alpha_{\text{scaled}}) \cdot \text{EMA}_{t-1}$$

Zero-phase backward smoothing pass:

$$\text{Smoothed}_t = \frac{1}{2} \left( \text{EMA}_t^{\text{forward}} + \text{EMA}_t^{\text{backward}} \right)$$

### B. Bayesian Kalman State Estimation for TDEE
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
        UI[Dashboard / Strategy Screens]
        Gauges[Custom Concentric MacroGaugeRing]
        Cards[DynamicExpenditureCard & WeightTrendCard]
        Providers[App State & Stream Providers]
    end

    subgraph Domain ["Domain Layer (Pure Dart)"]
        TrendAlgo[WeightTrendV2Series Engine]
        ExpAlgo[ExpenditureAlgorithmV3 Engine]
        Entities[User Profile, Macro Targets, Observations]
    end

    subgraph Data ["Data Layer (SQLite & FTS5)"]
        DB[AppDatabase Engine]
        FTS[FTS5 Full-Text Food Index]
        Tables[(Foods, PortionUnits, WeightLogs, DailyFoodLogs)]
    end

    UI --> Providers
    Cards --> Providers
    Gauges --> Providers
    Providers --> TrendAlgo
    Providers --> ExpAlgo
    Providers --> DB
    DB --> FTS
    DB --> Tables
```

---

## 🧪 Verification & Quality Gate

Every release passes automated verification pipelines:

| Check | Tool | Result |
|---|---|---|
| **Static Code Analysis** | `flutter analyze` | **0 issues, 0 warnings** |
| **Unit & Algorithm Tests** | `flutter test` | **27 / 27 Passed (100%)** |
| **Code Formatting** | `dart format` | **Clean (80-char wrap)** |
| **Production Compilation** | `flutter build apk --release` | **Clean exit (code 0)** |
| **Binary Output** | `app-release.apk` | **76.5 MB (Universal APK)** |

---

## 🚀 Quick Start & Development

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.29.0 or higher
- Android SDK 34 / Java 17

### 1. Clone & Install
```bash
git clone https://github.com/h4rysh/macrofactor-flutter.git
cd macrofactor-flutter
flutter pub get
```

### 2. Run Tests
```bash
# Run all unit, algorithm, and widget tests
flutter test

# Run with code coverage
flutter test --coverage
```

### 3. Run on Device / Emulator
```bash
flutter run
```

### 4. Build Release APK
```bash
flutter build apk --release
```
The compiled binary will be placed at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
<sub>Crafted with clean-room precision and adherence-neutral science.</sub>
</div>
