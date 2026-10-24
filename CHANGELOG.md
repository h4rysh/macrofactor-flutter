# Changelog

All notable changes to the **Sique** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2026-10-25

### 🚀 Major Milestone: Sique Master Remediation & Autonomous Evolution
Version 2.0.0 represents a complete architectural transformation and rebrand into **Sique** (`com.h4rysh.sique`), establishing adherence-neutral metabolic intelligence, 100% on-device data sovereignty, and a production-grade cleanroom engineering standard.

### 🧠 Metabolic & Expenditure Intelligence
- **Joint-State Kalman Expenditure Filter V4 (`ExpenditureKalmanV4`)**:
  - Implemented 2D discrete-time state vector $\mathbf{x}_t = [W_t, E_t]^T$ simultaneously estimating true underlying trend weight ($W_t$ in kg) and daily Total Daily Energy Expenditure ($E_t$ in kcal/day).
  - Thermodynamic conservation matrix with human tissue energy density constant ($7700\text{ kcal/kg}$).
  - Robust Huber-clipped innovation variance ($S = H P H^T + R$) at $3\sigma$ ($k=3.0$), shielding expenditure estimates from biological water fluctuations and measurement noise.
  - 14-day rolling mean intake imputation with process noise augmentation $((0.15 \times \bar{I}_{14})/7700)^2$ for missing logging days.
  - Adaptive regularity guard pausing updates when $>3$ of trailing 7 days lack food records.
  - Frozen legacy V3 baseline in `test/algorithms/legacy_v3_baseline_test.dart` and removed V3 from production code.
  - Verified across 8 canonical Monte Carlo simulation scenarios (100 runs each) in `test/algorithms/expenditure_kalman_simulation_test.dart`.

### 🎯 Coaching Engine & Target Reactivity
- **Instant Target Propagation**: Wired `userProfileProvider` to immediately recompute and persist 7-day macro targets upon modifications to `goalType`, `currentWeightKg`, `targetWeightKg`, `weeklyRateOfChangePct`, or `proteinPreference`.
- **7-Day Dynamic Calorie Shifting**: Added support for *Even Allocation* and *Shifted Workout Days* ($+9\%$ energy surplus on training days, compensated on rest days) while strictly preserving physiological daily calorie floors.
- **Macronutrient Rebalancing**: Standardized calorie math to reconcile protein ($4\text{ kcal/g}$), carbohydrate ($4\text{ kcal/g}$), and dietary fat ($9\text{ kcal/g}$) within integer rounding bounds.

### 📱 User Interface & Onboarding Flow
- **23-Step Modular Onboarding**:
  - Implemented 23 decoupled step screens under `lib/presentation/screens/onboarding/steps/`, each strictly adhering to the $<800$ line maintainability ceiling.
  - Clinical and ethical guardrails: mandatory Age $\ge 18$ validation lock and BMI $\ge 18.5$ aggressive deficit warning.
  - Segmented progress bar, custom Apple-styled tactile cards, and intermediate SQLite auto-save.
- **Direct Numeric Serving Input**:
  - Created `PortionSelectorDialog` with a validated direct numeric `TextFormField` (> 0) alongside tactile steppers across all logging views.
- **SSOT Nutrition Math**:
  - Established `FoodItem.calculateNutrition` as the single source of truth across search, plate sheets, and detail modals.
  - Linear, non-negative scaling for cooking oil modifiers (`lowOil`, `standard`, `halfTsp`, `oneTsp`, `oneTbsp`).
- **Foreground Midnight Rollover**:
  - Added periodic foreground timer in `AppLifecycleSyncObserver` advancing `selectedDateProvider` only when actively viewing today.

### 🔒 Privacy, Security & Data Sovereignty
- **Dedicated Firebase Authentication**:
  - Provisioned dedicated Firebase project `sique-app-harrish` (`com.h4rysh.sique`).
  - Isolated authentication operations behind an abstract `AuthRepository` interface (`FirebaseAuthRepository` for production, `FakeAuthRepository` for testing).
  - Provider-aware re-authentication distinguishing Email/Password and Google OAuth tokens.
  - Provider badges: `Guest Mode` (Warning), `Google Account` (Active Blue), `Email Account` (Success Green).
  - Complete local data wipe on account deletion: `ProfileDao.clearAllData()` wipes user logs and settings, resets `sqlite_sequence`, clears `SharedPreferences`, preserves the food catalog, and reactively invalidates Riverpod caches.
  - Reusable `AuthLegalFooter` providing modal access to Privacy Policy and Medical Disclaimer dialogs.
- **100% On-Device Data Sovereignty**:
  - All dietary logs, body weights, and metabolic states stay strictly in local SQLite. Cloud sync of health data is excluded.

### 🍛 Food Catalog & Full-Text Search
- **500+ Indian Staple Nutrition Catalog**:
  - Compiled 514 verified Indian foods into `assets/data/indian_food_catalog.json` and SQLite database `assets/database/foods_master.db`.
  - 887 authentic regional portion units (*katori*, *roti*, *ladle*, *cups*, *pieces*) with ICMR-NIN IFCT nutritional grounding.
  - High-performance SQLite FTS5 search with prefix matching, operator escaping, and sub-millisecond execution.

### 🗄️ Database Architecture & Migrations
- **Modular Data Access Objects (DAOs)**:
  - Extracted `FoodDao`, `WeightDao`, `ProfileDao`, `WorkoutDao`, `ExpenditureDao`, and `SettingsDao` from monolithic storage classes.
  - Implemented atomic `PRAGMA user_version` migrations, SQLite WAL mode, foreign keys, and `busy_timeout = 5000;`.
  - Replaced silent error swallowing with typed exceptions (`SqliteException`, `FormatException`, `PlatformException`).

### 🛠️ Tooling, Dependencies & CI/CD
- **Dependency Optimization**: Pruned 37 obsolete dependencies (`drift`, `rive`, `uuid`, `http`, etc.).
- **Strict Static Analysis**: Enabled `strict-casts: true` and `strict-raw-types: true` in `analysis_options.yaml`.
- **Automated Testing Suite**: 577 / 577 tests passing with 0 analyzer warnings and clean formatting.
- **GitHub Actions Release Pipeline**: Configured tag-triggered release workflow (`v*`) generating signed release APKs and SHA-256 checksums.

---

## [1.7.0] - 2026-10-20
- Metabolic engine hardening and multi-day sparse weigh-in expenditure distribution.
- Bidirectional weight trend smoothing V2 with dynamic $\Delta t$ scaling.
- Source tracking (`manual` vs `health_connect`) with manual entry protection.

## [1.6.0] - 2026-10-18
- Apple HIG tactile micro-interactions and liquid glass frosted surfaces.
- Concentric radial macro gauges and numerical odometer tweens.

## [1.5.0] - 2026-10-18
- Strategy Coaching Engine with 3 coaching modes and 5 nutritional macro styles.
- Strict 7-day caloric conservation algorithms.
