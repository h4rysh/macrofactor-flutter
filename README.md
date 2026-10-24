# Sique • Intelligent Adherence-Neutral Nutritional Coaching

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.7+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Tests](https://img.shields.io/badge/Tests-520%2B%20Passing-2ea44f?style=for-the-badge&logo=githubactions&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

<br/>

**Sique is an original adherence-neutral nutritional coaching platform for Android and iOS. Featuring an Obsidian OLED dark interface, joint-state Kalman expenditure modeling (V4), bidirectional zero-phase weight trend filtering, dynamic 7-day caloric shifting, Google Health Connect smart scale synchronization, and a curated Indian food catalog with cooking oil adjustment modifiers.**

</div>

---

## 📑 Table of Contents
- [✨ Core Highlights](#-core-highlights)
- [🧠 Philosophy: Adherence-Neutral Nutrition](#-philosophy-adherence-neutral-nutrition)
- [📈 Joint-State Kalman Expenditure Filter V4](#-joint-state-kalman-expenditure-filter-v4)
- [🎯 Dynamic Coaching Engine & 7-Day Shifting](#-dynamic-coaching-engine--7-day-shifting)
- [🍛 Curated Food Catalog & Oil Modifiers](#-curated-food-catalog--oil-modifiers)
- [🔒 Data Sovereignty & Offline Architecture](#-data-sovereignty--offline-architecture)
- [🏛️ System Architecture](#️-system-architecture)
- [🧪 Testing & Verification](#-testing--verification)

---

## ✨ Core Highlights

| Feature Area | Architectural Implementation |
|---|---|
| **🎨 Obsidian UI Design** | Deep OLED dark palette (`#0B0B0E`), tactile card interactions, concentric radial macro progress gauges, and numerical odometer tweens. |
| **🧠 Adherence-Neutral Coaching** | Thermodynamic calibration without red warning banners or calorie guilt. 3 Coaching Modes (Coached, Collaborative, Manual), 5 Macronutrient Styles, and 7-day energy conservation. |
| **📈 Kalman Filter V4** | 2D joint-state tracker ($[W_t, E_t]^T$) with Huber $3\sigma$ innovation clipping, 14-day rolling mean intake imputation, and logging gap protection. |
| **⚖️ Dual-Pass Weight Smoothing** | Causal forward pass + zero-phase backward pass EWMA with dynamic $\Delta t$ scaling and biological noise envelopes. |
| **🍛 Indian Food Catalog** | Curated Indian staple nutrition database with SQLite FTS5 search and 1-tap oil modifiers (+½ tsp, +1 tsp, +1 tbsp ghee/oil). |
| **🔒 Data Sovereignty** | 100% on-device SQLite storage for all meals, body weights, and metabolic history. Zero cloud tracking of personal health data. |

---

## 🧠 Philosophy: Adherence-Neutral Nutrition
Traditional diet applications shame users when they exceed target calories with red warning banners, negative reinforcement, or arbitrary punishment penalties. Sique models the human body strictly as an open thermodynamic system. Whether you eat over or under target, Sique analyzes the mathematical relationship between logged intake and weight trends to calculate your true metabolic expenditure without judgment.

---

## 📈 Joint-State Kalman Expenditure Filter V4
Sique implements a discrete-time 2D Kalman filter:
- **State Vector**: $x_t = [W_t, E_t]^T$ where $W_t$ is true weight (kg) and $E_t$ is daily expenditure (kcal/day).
- **Thermodynamic Transition**: $W_{t+1} = W_t + (I_t - E_t)/7700$, $E_{t+1} = E_t + w_t$.
- **Huber 3σ Clipping**: Clips innovation residuals exceeding $3\sqrt{S_t}$ to absorb acute water weight spikes.
- **Unlogged Imputation**: Uses 14-day rolling mean intake with increased process noise when logs are missing.
- **Regularity Guard**: Automatically pauses metabolic updates when fewer than 4 of the last 7 days are logged.

---

## 🎯 Dynamic Coaching Engine & 7-Day Shifting
- **5 Nutritional Styles**: Balanced, Low Fat, Low Carb, Ketogenic, and High Protein.
- **7-Day Caloric Allocation**:
  - *Even Allocation*: Equal daily caloric distribution across the week.
  - *Shifted Workout Days*: Provides $+9\%$ surplus ($\approx 150 - 300\text{ kcal}$) on training days, conserved across rest days while strictly preserving physiological calorie floors.
  - *Weekend Shift*: Provides extra budget for social weekend meals balanced by lighter weekdays.
- **Dynamic Propagation**: Updating user profile attributes (goal, weight, weekly rate, protein preference) regenerates active weekly targets immediately without application restart.

---

## 🔒 Data Sovereignty & Offline Architecture
Sique guarantees complete privacy:
- All food records, scale weights, and profile settings are stored strictly in local SQLite.
- External cloud synchronization of health records is deliberately excluded.
- Authentication utilizes Firebase Authentication via the abstract `AuthRepository` interface.
- Complete data export (JSON/CSV) and one-tap total local data erasure.

---

## 🏛️ System Architecture
The application follows Clean Architecture principles:
- **Domain Layer (`lib/domain/`)**: Pure Dart mathematical engines, models, and interfaces.
- **Data Layer (`lib/data/`)**: SQLite persistence, DAOs, schema definitions, and hardware sync adapters.
- **Presentation Layer (`lib/presentation/`)**: Flutter Riverpod reactive state management and design tokens.

---

## 🧪 Testing & Verification
Sique maintains a comprehensive test suite including Monte Carlo Kalman simulations, adversarial stress tests, and end-to-end user journeys:
```bash
flutter analyze
flutter test
```
