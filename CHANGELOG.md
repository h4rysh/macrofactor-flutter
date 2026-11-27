# Changelog

All notable changes to the **Sique** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [4.1.0] - 2026-11-27

### 🛡️ Reliability, Security & Domain Integrity Hardening (Waves 1–5)
- **Encrypted & Atomic Backup Pipeline**: Added authenticated backup validation (`BackupCodec` / `BackupCrypto`), CSV formula-injection escaping (`CsvSanitizer`), transactional SQLite restore with rollback, and post-restore Riverpod provider invalidation across units, food logs, settings, workouts, and challenges.
- **Database, DAO & Validation Safety**: Hardened parameterized queries, foreign/user-scoped isolation, DST-safe calendar arithmetic, single-source `DomainValidator` bounds on targets/weights/portions/custom micro goals, and `wave5_audit_regression_test.dart` coverage.
- **Algorithmic & Sync Correctness**: Hardened `ExpenditureKalmanV4` / `ExpenditureKalmanV5`, `WeightTrendV2`, `CoachingEngine`, `AnthropometricService`, `ChallengeGenerationService`, `HealthConnectSyncAdapter`, `OpenFoodFactsService`, and Android `SiqueMacroWidgetProvider` updates.

### ✨ UI/UX, Apple HIG & WCAG 2.1 AA Overhaul (Waves 1–4)
- **Design Tokens & Accessibility**: Added high-contrast text-role tokens (`activeBlueText`, `errorText`), aligned display typography weights to declared Inter font weights (`w400`–`w700`/`w900`), enforced `>= 44dp` interactive hit targets across chips/buttons/steppers/dock controls, and respected `MediaQuery.disableAnimationsOf(context)` across custom transitions and controls.
- **Dashboard, Charts & Strategy UX**: Added `MMM d` axis labels, Y-axis range bounds, target line labels, persistent touch scrub with `SemanticsService` announcements, ultra-compact (`320x568`) responsive layout fixes (`MetabolicCommandHeader`, `StrategySetupWizard`), confirmation dialogs for destructive resets/swaps (`WaterDialCard`, `FastingClockCard`, `WeeklyChallengeCard`), and unstacked sheet flows.
- **Food Diary, Modals & Biomarkers**: Fixed AM/PM timestamps and intuitive swipe-to-duplicate colors in `TimelineFoodCard`, added keyboard-safe scroll + `SafeArea` + inline validation + safe `StatefulWidget` controller disposal (`_DayNoteDialog`, `_DialogControllerScope`), added close/confirm controls in `BarcodeScannerSheet`, `BatchDiaryToolbar`, `StagingPlateSheet`, and `RecipeBuilderSheet`, and added empty/error states in `NutrientExplorerScreen`.
- **Onboarding, Auth & Export UX**: Persisted Card 2 unit toggles directly to `useImperialUnitsProvider`, fixed step progress math and `GoalQuestionnaireSheet` cancel/preservation semantics (`millet`, `poha_upma`, `heavy`, activity multiplier), surfaced Google Sign-In `AuthLoading`/`AuthError` feedback, and wired Health Connect & export busy-state indicators.

### ✅ Verification
- `dart format --output=none --set-exit-if-changed .` — **0** formatting issues (`291` files)
- `flutter analyze --fatal-infos` — **0** warnings/infos
- `flutter test` — **904 / 904** tests passing (including updated presentation goldens & `wave5_audit_regression_test.dart`)

---

## [4.0.1] - 2026-11-26

### 🔧 Fixes & UX Polish
- **Google Sign-In**: Registered debug and permanent release keystore SHA-1 certificates in Firebase (`sique-app-harrish`), populated `google-services.json` Android/Web OAuth clients, and replaced raw `PlatformException` details with a clean user-facing message.
- **Health Connect Auto-Sync**: Removed manual "Sync Now" buttons across Profile, Health Sync Settings, and Food Log Settings in favor of silent automatic background/app-open sync, and added a 1-line Google Fit → Health Connect setup tip when 0 workouts are detected.
- **Weight Log → Profile Sync**: Invalidated `userProfileProvider` immediately on weight log/delete and Health Connect weight sync so Profile & Targets and macro targets update right away.
- **UI Decluttering & Plain Language**:
  - Removed the AI Describe meal feature and all Gemini API key prompts.
  - Replaced user-facing technical jargon across all screens with clear, human-friendly copy.
  - Decluttered Dashboard (removed extra Water/Fasting strip) and Food Log (removed duplicate sticky macro bar and defaulted empty hourly slots to hidden).
  - Streamlined Strategy into a clean 3-tier layout with a first-run **Start Strategy Setup** prompt and moved secondary controls into a **Program & Goal Settings** sheet.
  - Added canonical **Best Match** ranking and a highlighted hero card with food artwork at the top of Food Search.

---

## [4.0.0] - 2026-11-26

### 🚀 Major Milestone: Sique v4 — Multi-Modal Intelligence, Diary Power-Tools & 36 Biomarkers
Version 4.0.0 introduces multi-modal Kalman V5 expenditure estimation, a redesigned 3-Tier Strategy Command Center, Schema v7 diary power-tools, a 36-biomarker Nutrient Explorer, an expanded 4,345-food catalog, and a native Android Home Screen Macro Widget.

### 🧠 Multi-Modal Strategy & Adaptive Intelligence
- **`ExpenditureKalmanV5`**: Fuses `WorkoutDao` 7d vs 21d training-volume drift ($\beta_{\text{comp}} = 0.60$, $\pm 120$ kcal clamp), heteroscedastic observation noise $R_t \in [0.36, 1.25]$ driven by hydration swings, lag-1 sodium spikes, and $\ge 18\text{h}$ fasts, plus Katch-McArdle + Mifflin-St Jeor BMR blending.
- **3-Band `GoalEtaCalculator`**: Projects `Optimistic`, `Expected`, and `Conservative` goal dates with singularity-guarded Recomp Waist-to-Goal ETA fallback.
- **Mid-Week Rebalancer & What-If Simulator**: Added `CoachingEngine.rebalanceRemainingWeek` and an interactive pace slider inside `CheckinReviewSheet`.
- **3-Tier Strategy Tab**: Refactored `StrategyScreen` around `MetabolicCommandHeader`, `WeeklyChallengesSection`, and `LifestyleTelemetryStrip`.
- **Closed-Loop Challenges V2 (`DeficitMiningV2`)**: 6-table deficit mining with $\ge 75\%$ sparse micronutrient coverage gating, cumulative protein targets, 7-day dot strips, "Foods that fix this", and Swap autonomy.

### ⚡ Diary Power-Tools & Schema v7
- **Database Schema v7 & `BackupCodec` v7**: Added `repeat_items`, `day_notes`, `micro_goals`, `cooked_weight_g` on `custom_recipes`, and 36 seeded `nutrient_definitions`.
- **Logging Speed**: Added inline Math Keyboard (`+ - * /`), Quick-Add Macros, 1-tap Daily Repeat Items (`+ Repeat`), Day Notes, Batch Copy/Move/Delete toolbar, Fasting-Window timeline pills, and Recipe Edit with cooked weight scaling.

### 🔬 36-Biomarker Explorer, Label OCR & 4,345-Food Catalog
- **Nutrient Explorer (`NutrientExplorerScreen`)**: Rolling `7d/14d/30d` averages, coverage transparency, top food contributors, and custom `micro_goals`.
- **Nutrition Label OCR (`NutritionLabelOcrParser`)**: Offline FSSAI/FDA label parser fallback in `BarcodeScannerSheet`.
- **Catalog Expansion**: Compiled `foods_master.db` to **4,345 foods**, **11,933 portion units**, **43,367 micronutrient facts**, and **77 pre-cached barcodes**.

### 📱 Android Home Widget, Two-Way Health Connect & Opt-In AI
- **Android Home Widget (`SiqueMacroWidgetProvider`)**: Live remaining-macros widget synced from today's diary totals.
- **Two-Way Health Connect**: Added Steps & Sleep reading and opt-in Nutrition write-back toggle in `HealthSyncSettingsScreen`.
- **Opt-In Gemini AI Describe**: Added `AiDescribeMealSheet` (user-supplied API key, excluded from backup exports).
- **Verified**: `0` analyzer issues (`--fatal-infos`), `896` passing tests, and signed/release APK verified.

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
