# Technical Audit Remediation & Architecture Response

## Executive Summary
This document summarizes the architectural remediation and hardening implemented across the **Sique** codebase across Rounds 1–3 of the technical audit.

## Stage 1 Remediation

### 1. Joint-State Kalman Expenditure Filter (`ExpenditureKalmanV4`)
- Implemented state vector $x = [W_t, E_t]^T$ modeling true trend weight and daily caloric expenditure with thermodynamic conservation ($7700\text{ kcal/kg}$).
- Integrated $3\sigma$ Huber-clipped innovation variance ($S = HPH^T + R$) to prevent expenditure distortion from biological water shocks or scale measurement anomalies.
- Implemented 14-day rolling mean intake imputation for unlogged days with augmented process noise $((0.15 \times I)/7700)^2$.
- Added update pausing when more than 3 of the trailing 7 days lack food logs.
- Legacy V3 baseline frozen in `test/algorithms/legacy_v3_baseline_test.dart` and removed from production.
- Verified across 8 canonical Monte Carlo simulation scenarios (100+ runs each) in `test/algorithms/expenditure_kalman_simulation_test.dart`.

### 2. Domain Wiring, Target Reactivity & Input Controls
- **Health Connect Integration**: Updated `HealthSyncNotifier` to group multi-readings per day by local date (`.toLocal()`), calculate arithmetic averages, tag entries with `source: 'health_connect'`, and enforce SQLite conflict clauses protecting manual entries.
- **Single Source of Truth**: Standardized all nutritional calculations across food logging, plate serving sheet, search, and detail dialogs on `FoodItem.calculateNutrition`, enforcing linear quantity scaling and non-negative clamping for cooking oil modifiers.
- **Midnight Date Rollover**: Added periodic foreground timer in `AppLifecycleSyncObserver` advancing `selectedDate` only if the user was actively viewing today.
- **Dynamic Target Propagation**: Wired `userProfileProvider` to immediately regenerate and persist active 7-day macro programs via `CoachingEngine.buildWeeklyProgram` upon changes to `goalType`, `currentWeightKg`, `targetWeightKg`, `weeklyRateOfChangePct`, or `proteinPreference`.
- **Macro Solver Guardrails**: Enforced physiological `calorieFloor` on every day of shifted programs and reconciled macronutrient totals within integer rounding.
- **Direct Numeric Serving Input**: Created `PortionSelectorDialog` and added validated direct numeric `TextFormField` (> 0) alongside stepper controls in portion sheets and food logging views.

## Stage 2 Remediation

### 1. Brand Sovereignty & Clean Room Compliance
- Completed full rebrand to **Sique** across package name (`sique`), Android application ID and namespace (`com.h4rysh.sique`), Kotlin package structure, UI strings, theme tokens, and documentation.
- Zero references to legacy names in tracked code, comments, assets, or docs.

### 2. Database Architecture & Migrations
- Modularized database access into dedicated Schema, Migration, and DAO components.
- Implemented `PRAGMA user_version` migration framework with WAL mode and foreign keys enabled.
- Added new profile columns: `diet_type`, `calorie_floor_type`, `lifting_experience`, `cardio_experience`, `body_fat_range`, `weight_history_max`, `distribution_mode`.

### 3. Authentication & Security
- Isolated authentication operations behind an abstract `AuthRepository` interface.
- Provider-aware re-authentication distinguishing email/password and Google OAuth credentials.
- Safe graceful fallback when Firebase project configuration is absent.

### 4. Onboarding Redesign
- Implemented modular 23-step onboarding flow across Basics, Goal Direction, and Program Configuration.
- Guardrails enforcing age $\ge 18$ and BMI $\ge 18.5$.

### 5. Catalog Asset & Infrastructure
- Curated 500+ Indian staple catalog JSON asset with offline SQLite FTS5 search.
- Cleaned unused dependencies and configured GitHub Actions semver release workflow.
