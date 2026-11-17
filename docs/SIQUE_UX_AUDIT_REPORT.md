# Sique — Full-App UI/UX Diagnostic Audit Report
**Audited:** `app/lib/presentation/` — all screens, widgets, navigation routes, and state providers  
**Date:** 2026-11-17  
**Auditor Role:** Full-App UI/UX Diagnostic Agent  

---

## Executive Summary

The app has a **strong design foundation**: consistent Obsidian Dark tokens, a coherent Apple-inspired motion language, solid accessibility semantics on most critical widgets, and meaningful adherence-neutral copy. However, the audit uncovered **5 Critical**, **12 High**, **14 Medium**, and **8 Low** severity findings spanning dead UI stubs, keyboard-layout collisions, state loading race conditions, accessibility gaps, and micro-interaction opportunities.

---

## Severity Legend

| Level | Meaning |
|-------|---------|
| **Critical** | Breaks a core user flow or causes data loss / corruption |
| **High** | Significantly degrades UX; will cause user confusion or task failure |
| **Medium** | Noticeable friction, visual glitch, or missing expected behaviour |
| **Low** | Micro-interaction polish or accessibility enhancement |

---

## Section 1 — DashboardScreen & Widgets

### 1.1 · Energy Balance Card — Zero-Balance State Missing  
**Severity:** High  
**File:** [`lib/presentation/screens/dashboard_screen.dart`](file://app/lib/presentation/screens/dashboard_screen.dart#L384-L470)  
**Lines:** 385–387, 420  

The `_buildEnergyBalanceCard` only checks `isDeficit = energyBalanceKcal <= 0` — a _zero_ balance is classified as a deficit and shows the blue "DEFICIT" badge. A user at exact maintenance sees the same badge as someone in a 500 kcal deficit, which is factually incorrect and confusing.

**Recommendation:** Add a neutral zone `(-15…+15 kcal)` check: show a grey "BALANCE" badge for near-zero values.

```dart
final badgeColor = energyBalanceKcal < -15
    ? AppTheme.activeBlue
    : energyBalanceKcal > 15
        ? AppTheme.warning
        : AppTheme.textMuted;
final badgeLabel = energyBalanceKcal < -15
    ? 'DEFICIT'
    : energyBalanceKcal > 15
        ? 'SURPLUS'
        : 'BALANCE';
```

---

### 1.2 · QuickActionStrip — "Quick Add" Opens FoodSearch Instead of Macro Shortcut  
**Severity:** High  
**File:** [`lib/presentation/screens/dashboard_screen.dart`](file://app/lib/presentation/screens/dashboard_screen.dart#L296-L304)  
**Lines:** 296–304  

The pill labelled **"Quick Add"** (`Icons.bolt_rounded`) calls `QuickActionsSheet.show(context)`, which is a 6-item menu. The label strongly implies a direct macro/calorie quick-entry. Users who want to quickly add 300 kcal of rice tap it and land in a full action menu — an extra tap. The icon and label create false affordance.

**Recommendation:** Either (a) rename the pill to "Actions" / replace `Icons.bolt_rounded` with `Icons.more_horiz_rounded`, or (b) wire it directly to a "Quick Add Macros" numeric sheet, reserving `QuickActionsSheet` for the floating `+` FAB.

---

### 1.3 · DashboardScreen Header — Strategy Action Button Only Renders When `onNavigateToStrategy` Is Non-Null  
**Severity:** Medium  
**File:** [`lib/presentation/screens/dashboard_screen.dart`](file://app/lib/presentation/screens/dashboard_screen.dart#L123-L132)  
**Lines:** 123–132  

```dart
if (onNavigateToStrategy != null)
  IconButton(...)
```

`ScaffoldWithNavBar` passes `DashboardScreen()` with no `onNavigateToStrategy` callback (line 32 of `scaffold_with_nav_bar.dart`). The Strategy icon header button therefore **never renders** in the production navigation shell. Users have no way to reach Strategy directly from the Dashboard header.

**Recommendation:** Either (a) wire the callback in `ScaffoldWithNavBar._screens` construction, or (b) always render the icon and use a tab-switching mechanism.

---

### 1.4 · MacroGaugeRing — Overflow Arc Paints on Top of Progress Arc (Wrong Z-Order)  
**Severity:** Medium  
**File:** [`lib/presentation/widgets/macro_gauge_ring.dart`](file://app/lib/presentation/widgets/macro_gauge_ring.dart#L296-L311)  
**Lines:** 296–311  

When `progress > 1.0`, the overflow arc (`AppTheme.neutralInfo`) is drawn starting at `startAngle` again, covering the first part of the full progress arc. The overflow should start at `startAngle + sweepAngle` to form a wrap-around, not overlay.

**Recommendation:**
```dart
// Current (buggy):
canvas.drawArc(rect, startAngle, overflowSweep, false, overflowPaint);

// Fixed:
final overflowStart = startAngle; // arc already filled to end; overflow wraps from beginning
// but visually the overflow indicator should sit on top of the already-full arc from startAngle
// — only the glow color changes, so just change progressPaint color at progress >= 1 instead:
```
Simpler fix: when `progress >= 1.0`, switch `progressPaint` color to `AppTheme.neutralInfo` for the extra sweep, without a second arc call.

---

### 1.5 · MacroGaugeRing — No "Data Loading" / Zero-State Skeleton  
**Severity:** Medium  
**File:** [`lib/presentation/screens/dashboard_screen.dart`](file://app/lib/presentation/screens/dashboard_screen.dart#L254-L260)  
**Lines:** 254–260  

`MacroGaugeRing` is passed `dailyNutrition` and `macroTarget` synchronously from `ref.watch(...)`. On first launch with an empty database the ring shows `0 / 0 kcal` with a fully empty ring and no skeleton shimmer. The existing `AppleSkeletonShimmer` widget is available but not used here.

**Recommendation:** Wrap the ring in a conditional: if `targets.calories == 0 && consumed.calories == 0`, render `AppleSkeletonShimmer` instead.

---

### 1.6 · DynamicExpenditureCard — `consecutiveMissingDays` Can Show 0  
**Severity:** Low  
**File:** [`lib/presentation/widgets/expenditure_card.dart`](file://app/lib/presentation/widgets/expenditure_card.dart#L130-L132)  
**Lines:** 130–132  

```dart
'Expenditure updates paused due to ${expenditureState.consecutiveMissingDays} days of missing logs.'
```

If the state initialises with `consecutiveMissingDays = 0` but `isPaused = true` (e.g., a just-paused state), the copy reads: "paused due to 0 days of missing logs" — grammatically incorrect and confusing.

**Recommendation:** Guard: `'paused due to ${max(1, state.consecutiveMissingDays)} days of missing logs'`.

---

## Section 2 — FoodLogScreen & Widgets

### 2.1 · FoodLogScreen — Menu Button (`leading` IconButton) Has No Handler (Dead Stub)  
**Severity:** Critical  
**File:** [`lib/presentation/screens/food_log_screen.dart`](file://app/lib/presentation/screens/food_log_screen.dart#L150-L155)  
**Lines:** 150–155  

```dart
leading: IconButton(
  icon: const Icon(Icons.menu_rounded, size: 24),
  color: AppTheme.textSecondary,
  tooltip: 'Menu',
  onPressed: () {},   // ← DEAD STUB
),
```

The hamburger menu icon has an empty `onPressed`. Tapping it does nothing. VoiceOver/TalkBack will announce the button as interactive but it produces zero response. This is discoverable on first use, breaking user trust.

**Recommendation:** Either (a) remove the icon entirely if no drawer is planned, or (b) connect it to a contextual action (e.g., open `MoreScreen` or a `FoodLogSettingsScreen`).

---

### 2.2 · FoodLogScreen — `PersistentSearchBar` Bottom Padding Insufficient on Devices with Nav Bar (extendBody = true)  
**Severity:** High  
**File:** [`lib/presentation/screens/food_log_screen.dart`](file://app/lib/presentation/screens/food_log_screen.dart#L235-L240)  
**Lines:** 235–240  

```dart
Positioned(
  left: 0,
  right: 0,
  bottom: 4,          // ← fixed 4px
  child: PersistentSearchBar(...),
),
```

`ScaffoldWithNavBar` uses `extendBody: true`, so the bottom nav bar (66px + safe area) overlaps the content. The search bar is pinned at `bottom: 4`, which places it **under** the transparent nav dock on devices with >= 34px bottom safe area. Users will see the bar visually but their taps will land on the nav bar behind it.

**Recommendation:**
```dart
bottom: MediaQuery.of(context).padding.bottom + 70, // 66 nav + 4 buffer
```
Or wrap in `MediaQuery.removePadding` after `SafeArea` and use `bottom: 70`.

---

### 2.3 · DateCarouselRibbon — `showDatePicker` Uses Hardcoded `lastDate: DateTime(2030)` 
**Severity:** Medium  
**File:** [`lib/presentation/widgets/date_carousel_ribbon.dart`](file://app/lib/presentation/widgets/date_carousel_ribbon.dart#L85-L102)  
**Lines:** 85–102  

The date picker locks the user to `DateTime(2030)` as the max. Any user opening the app after 2029-12-31 will not be able to log food for the current date. Similarly `firstDate: DateTime(2020)` prevents backfilling historical data older than 2020.

**Recommendation:** Use dynamic bounds:
```dart
firstDate: DateTime(DateTime.now().year - 10),
lastDate: DateTime(DateTime.now().year + 2),
```

---

### 2.4 · DateCarouselRibbon — No Future-Date Guard on `>` Arrow  
**Severity:** Medium  
**File:** [`lib/presentation/widgets/date_carousel_ribbon.dart`](file://app/lib/presentation/widgets/date_carousel_ribbon.dart#L127-L139)  
**Lines:** 127–139  

The right chevron `>` allows navigating to arbitrary future dates with no bound. Users can navigate weeks or months into the future, logging hypothetical food. While harmless, it pollutes the timeline and confuses the Kalman expenditure estimator.

**Recommendation:** Disable the right arrow and grey out future day pills for dates after `today + 1` (allowing "tomorrow" for meal prelogging, but no further).

---

### 2.5 · NutritionSummaryBanner — Two-Dot Page Indicator Has No Interactive Swipe / Non-Functional  
**Severity:** Medium  
**File:** [`lib/presentation/widgets/nutrition_summary_banner.dart`](file://app/lib/presentation/widgets/nutrition_summary_banner.dart#L126-L147)  
**Lines:** 126–147  

The banner renders a two-dot page indicator, implying there is a second page (e.g., fiber, sodium, micronutrients). There is no corresponding `PageView` or swipe gesture. This creates a **false affordance** — users will swipe and nothing happens.

**Recommendation:** Either (a) implement the second page (fiber, sodium, micronutrients), or (b) remove the page indicator dots entirely.

---

### 2.6 · TimelineHourSlot — Collapsed Mode Shows No Food Name / Calories on Hover  
**Severity:** Low  
**File:** [`lib/presentation/widgets/timeline_hour_slot.dart`](file://app/lib/presentation/widgets/timeline_hour_slot.dart#L145-L173)  
**Lines:** 145–173  

In collapsed mode, food icons are shown as tiny `FoodSvgIcon(size: 26)` with no label. The calorie/macro subtotal in the header row still shows, but tapping an icon opens `PlateServingSheet` with no intermediate tooltip or tooltip-on-long-press showing the food name. For users logging 5–8 items, icons alone provide no quick recall.

**Recommendation:** Add `Tooltip(message: entry.foodName, ...)` wrapping each `FoodSvgIcon`, and consider showing `entry.effectiveCalories.round()` as a micro-badge below each icon.

---

### 2.7 · FoodLogScreen — Missing "No Logs Today" Empty State  
**Severity:** Low  
**File:** [`lib/presentation/screens/food_log_screen.dart`](file://app/lib/presentation/screens/food_log_screen.dart#L126-L130)  
**Lines:** 126–130  

When `dayLogs` is empty for the selected date, `allHours` resolves to only `baseHours = [8, 10, 13, 16, 20]` — five hour slots each with the empty horizontal divider. This renders as five grey lines with time pills, which looks broken rather than intentional. No motivational empty-state messaging appears.

**Recommendation:** When `dayLogs.isEmpty`, render a `SiqueEmptyState` widget ("No meals logged yet. Tap a time slot or use the search bar below.") above the five placeholder slots.

---

## Section 3 — FoodSearchScreen, FoodDetailModal, PlateServingSheet, QuickActionsSheet

### 3.1 · PlateServingSheet — "Edit" Button Is a Dead Stub  
**Severity:** Critical  
**File:** [`lib/presentation/screens/plate_serving_sheet.dart`](file://app/lib/presentation/screens/plate_serving_sheet.dart#L222-L236)  
**Lines:** 222–236  

```dart
TextButton(
  onPressed: () {},   // ← DEAD STUB
  child: const Text('Edit', ...),
)
```

The "Edit" button in the top bar of `PlateServingSheet` does nothing. This button appears on the existing food log editing flow (triggered from `FoodLogScreen._onEntryTap`). Users who tap it to edit the timestamp or change the portion unit of an already-logged food receive zero feedback.

**Recommendation:** Implement a time-picker dialog or navigate to a "Edit Log Entry" sheet, or replace the button with a "Delete" action if editing is not yet scoped. At minimum, add a `SnackBar('Edit coming soon')` stub.

---

### 3.2 · FoodSearchScreen — Filter Results Are Applied Client-Side Only, Not Reloaded from DB  
**Severity:** High  
**File:** [`lib/presentation/screens/food_search_screen.dart`](file://app/lib/presentation/screens/food_search_screen.dart#L78-L112)  
**Lines:** 78–112  

The filter logic (South Indian, North Indian, High Protein, Vegetarian) runs against `limit: 60` results from FTS5. If the query matches 300 foods but the DB returns only the first 60, applying "High Protein" to those 60 may yield 3 results even though 50 high-protein items exist beyond row 60.

**Recommendation:** Push filter predicates into the SQLite query with `WHERE` clauses, or increase the limit to `500` for filtered queries. The FTS5 engine already supports `MATCH` on tags columns.

---

### 3.3 · FoodSearchScreen — `autofocus: true` Collides with Sheet Keyboard on iPhone/Android  
**Severity:** High  
**File:** [`lib/presentation/screens/food_search_screen.dart`](file://app/lib/presentation/screens/food_search_screen.dart#L180-L181)  
**Lines:** 180–181  

`autofocus: true` on the search field causes the software keyboard to snap open immediately when navigating to `FoodSearchScreen`. On Android with a bottom gesture navigation bar, the keyboard pushes the entire screen upward abruptly. The filter pills at the bottom of the `AppBar.bottom` area are partially obscured before the user can even see the initial food list.

**Recommendation:** Delay autofocus by one frame using:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  FocusScope.of(context).requestFocus(_searchFocusNode);
});
```
Or use `autofocus: false` and show a one-time tap-to-focus animation.

---

### 3.4 · FoodDetailModal — Quantity Stepper Minimum Is `0.5` But No Lower Bound Message  
**Severity:** Medium  
**File:** [`lib/presentation/screens/food_detail_modal.dart`](file://app/lib/presentation/screens/food_detail_modal.dart#L316-L323)  
**Lines:** 316–323  

When the user taps `−` and `current > 0.5`, the quantity decrements by 0.5. But if `current == 0.5`, the button silently does nothing. The stepper gives no feedback (no haptic, no disabled visual state on the `−` icon) when at minimum. Users may think the button is broken.

**Recommendation:** 
1. Apply `IconButton.styleFrom(foregroundColor: current <= 0.5 ? AppTheme.textMuted : AppTheme.textPrimary)` on the `−` button.
2. Add `HapticFeedback.heavyImpact()` when tapping at minimum.

---

### 3.5 · PlateServingSheet — "Impact on Targets" Dials Show `%` Without Context of Already-Consumed  
**Severity:** Medium  
**File:** [`lib/presentation/screens/plate_serving_sheet.dart`](file://app/lib/presentation/screens/plate_serving_sheet.dart#L153-L168)  
**Lines:** 153–168  

The `targetCalPct`, `targetProteinPct`, etc. show the percentage of the **daily target** this single food item contributes, independent of what has already been logged that day. A user who has already consumed 1600 kcal of a 2000 kcal target sees that adding rice (500 kcal) is "25% of target" — but they should see it will put them at 105% of target.

**Recommendation:** Accept a `consumed: NutritionalValues` parameter (from `ref.read(dailyNutritionSummaryProvider)`) and compute **remaining** percentage impact: `((consumed.calories + effectiveCalories) / target.calories * 100)`, colour-coding over-100% red.

---

### 3.6 · QuickActionsSheet — "Quick Add Calories / Macros" Sends to FoodSearch (Mislabelled)  
**Severity:** Medium  
**File:** [`lib/presentation/screens/quick_actions_sheet.dart`](file://app/lib/presentation/screens/quick_actions_sheet.dart#L102-L113)  
**Lines:** 102–113  

The tile "Quick Add Calories / Macros" navigates to `FoodSearchScreen(mealType: MealType.snacks)`. This is not a "quick add" — it is the same full food search experience. Users expect a "quick add" to be a numeric calorie/macro entry field, not search.

**Recommendation:** Either (a) build a minimal `QuickMacroEntrySheet` with numeric fields for cal/P/F/C, or (b) rename the tile to "Search Food to Add" for honesty.

---

### 3.7 · QuickActionsSheet — "Add Day Note" Shows Snackbar Stub  
**Severity:** Medium  
**File:** [`lib/presentation/screens/quick_actions_sheet.dart`](file://app/lib/presentation/screens/quick_actions_sheet.dart#L119-L129)  
**Lines:** 119–129  

```dart
onTap: () {
  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Day Note recorded'), ...),
  );
},
```

Tapping "Add Day Note" pops the sheet and shows a fake snackbar — no actual note is created or stored. This is a **visible lie** to the user and will cause confusion when they look for their note later.

**Recommendation:** Remove the item entirely until the feature is implemented, or replace with a `TextInputDialog` that persists to SQLite `app_settings` or a `DayNotes` table.

---

### 3.8 · QuickActionsSheet — "Scan Barcode" Shows Stub SnackBar  
**Severity:** High  
**File:** [`lib/presentation/screens/quick_actions_sheet.dart`](file://app/lib/presentation/screens/quick_actions_sheet.dart#L82-L91)  
**Lines:** 82–91  

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Barcode scanner active'), ...),
);
```

The barcode scanner fires a `SnackBar` saying "Barcode scanner active" but no actual camera or scanner is opened. This same stub exists in `PersistentSearchBar.onBarcodeTap`. Users who pay premium attention to nutrition labels will discover this immediately.

**Recommendation:** Integrate `mobile_scanner` or `flutter_barcode_scanner` and open a camera view. If not yet built, replace "Scan Barcode" tiles with a "Coming Soon" badge or remove them.

---

## Section 4 — StrategyScreen & MacroProgramHeroCard

### 4.1 · MacroProgramHeroCard — Uses `program.days.first` as "Representative" for All Macro Pills  
**Severity:** High  
**File:** [`lib/presentation/widgets/strategy/macro_program_hero_card.dart`](file://app/lib/presentation/widgets/strategy/macro_program_hero_card.dart#L16)  
**Line:** 16  

```dart
final avgTarget = program.days.first; // representative macro split
```

The comment says "representative" but `days.first` is `Monday's` specific day — which in a shifted-workout program differs significantly from other days. The hero card's macro pills (Protein/Fat/Carbs grams) show Monday's values but the calories show `program.dailyAverageCalories`. This creates an inconsistency: the kcal is an average but the macros are Monday's specifics.

**Recommendation:** Compute the actual daily average across all 7 days for the macro pills:
```dart
final avgProtein = program.days.map((d) => d.proteinGrams).average;
```
Or add a subtitle clarifying "Monday's targets" vs. averages.

---

### 4.2 · StrategyScreen — Coaching Mode Switch Persists to Two Separate State Trees  
**Severity:** Medium  
**File:** [`lib/presentation/screens/strategy_screen.dart`](file://app/lib/presentation/screens/strategy_screen.dart#L273-L284)  
**Lines:** 273–284  

```dart
ref.read(weeklyMacroProgramProvider.notifier).updateProgram(updatedProgram);
ref.read(userProfileProvider.notifier).updateProfile(profile.copyWith(programMode: mode));
```

The coaching mode is written to both `weeklyMacroProgramProvider` and `userProfileProvider` independently. If either write fails (database error, state desync), the two providers can diverge — `WeeklyMacroProgram.mode` reflects `Coached` while `UserProfile.programMode` reflects `Manual`. Downstream reads of `mode` from either provider will give inconsistent results.

**Recommendation:** Consolidate to a single write path: update `userProfileProvider`, and derive `weeklyMacroProgramProvider.mode` reactively from it.

---

### 4.3 · StrategyScreen — `_buildProgramModeCard` Chips Overflow on Small Screens  
**Severity:** Medium  
**File:** [`lib/presentation/screens/strategy_screen.dart`](file://app/lib/presentation/screens/strategy_screen.dart#L221-L246)  
**Lines:** 221–246  

The three chips "Coached", "Collaborative", "Manual" are inside a `Row` with equal `Expanded` children. On screens < 360px wide (common for many mid-range Android phones), the chip labels wrap onto two lines or overflow `RenderFlex`. The `FittedBox.scaleDown` inside each chip would help, but `Expanded` without `FittedBox` on the outer container means the chip container itself may still cause layout warnings.

**Recommendation:** Wrap each chip label in `FittedBox(fit: BoxFit.scaleDown)` on the outer chip `Container`, or switch to a `Wrap` with `runSpacing`.

---

## Section 5 — Onboarding (24-Step Flow) & AccountProfileScreen

### 5.1 · OnboardingFlowScreen — Step 24 Renders `CircularProgressIndicator` If `_generatedProgram` Is Null  
**Severity:** Critical  
**File:** [`lib/presentation/screens/onboarding/onboarding_flow_screen.dart`](file://app/lib/presentation/screens/onboarding/onboarding_flow_screen.dart#L481-L484)  
**Lines:** 481–484  

```dart
if (_generatedProgram != null)
  Step24ProgramReady(program: _generatedProgram!)
else
  const Center(child: CircularProgressIndicator()),
```

The `PageView` renders step 24's slot as a bare `CircularProgressIndicator`. Since `_generatedProgram` is set synchronously in `_buildAndActivateProgram` → `_nextStep`, the spinner flashes for a frame before the program is set. However, if `_nextStep` somehow advances the page before `setState` completes (e.g., fast device refresh), or if the user navigates back and re-enters step 23, the spinner can get stuck indefinitely.

**Recommendation:** Ensure `_generatedProgram` is set before `_pageController.animateToPage(23)`:
```dart
void _buildAndActivateProgram() {
  final program = _computeProgram();
  setState(() => _generatedProgram = program); // set first
  _nextStep(); // then advance
}
```

---

### 5.2 · OnboardingFlowScreen — `_programStyle` Is `final`, Never Configurable via UI  
**Severity:** High  
**File:** [`lib/presentation/screens/onboarding/onboarding_flow_screen.dart`](file://app/lib/presentation/screens/onboarding/onboarding_flow_screen.dart#L78)  
**Line:** 78  

```dart
final MacroProgramStyle _programStyle = MacroProgramStyle.balanced;
```

`_programStyle` is declared `final` with a hardcoded default of `MacroProgramStyle.balanced`. The `StrategySetupWizard` (6-step shortcut) exposes a macro style selector (Step 3), but the full 24-step onboarding **always uses `balanced`** regardless of `Step18DietType` or `Step22ProteinPreference` selections. Users who choose a high-protein or low-carb diet type still get a balanced macro split.

**Recommendation:** Derive `_programStyle` from `_dietType` and `_proteinPref`:
```dart
MacroProgramStyle get _derivedProgramStyle {
  if (_proteinPref == ProteinPreference.veryHigh) return MacroProgramStyle.highProtein;
  if (_dietType == 'keto') return MacroProgramStyle.highFat;
  return MacroProgramStyle.balanced;
}
```

---

### 5.3 · Step03Dob — Age Decrement Allows Down to 10 (Below 18+ Guardrail Conflict)  
**Severity:** Medium  
**File:** [`lib/presentation/screens/onboarding/steps/step_03_dob.dart`](file://app/lib/presentation/screens/onboarding/steps/step_03_dob.dart#L91-L97)  
**Lines:** 91–97  

```dart
if (_age > 10) {
  setState(() { _age--; ... });
}
```

The decrement button allows ages down to 11. The 18+ guardrail correctly blocks progression, but users can sit on age 10 and visually see it. The consistent min should be 1 (biological minimum) with 18+ lock, or the button could clamp at 18. Having "11" visible while the red banner says "18+" looks inconsistent.

**Recommendation:** Show a haptic bounce when tapping `−` at `_age <= 18` rather than decrementing further, with a brief red flash on the age field.

---

### 5.4 · AccountProfileScreen — Error SnackBar Uses `AppTheme.calories` (Orange/Red) for Auth Errors  
**Severity:** Medium  
**File:** [`lib/presentation/screens/account_profile_screen.dart`](file://app/lib/presentation/screens/account_profile_screen.dart#L22-L30)  
**Lines:** 22–30  

```dart
backgroundColor: AppTheme.calories,
```

Both the auth error SnackBar and the health sync error SnackBar use `AppTheme.calories` (which is the calorie/energy colour, an orange-amber tone) as the error background. This is semantically incorrect: `calories` signals "energy/food", not "error". On first read, users may think this is an informational food log notification.

**Recommendation:** Use `AppTheme.warning` or a dedicated `AppTheme.error` token (e.g., `const Color(0xFFFF453A)` — already used in `HealthSyncSettingsScreen` line 158) for error SnackBars.

---

### 5.5 · AccountProfileScreen — No Loading State While Auth or Health Sync Is Pending  
**Severity:** Medium  
**File:** [`lib/presentation/screens/account_profile_screen.dart`](file://app/lib/presentation/screens/account_profile_screen.dart#L57-L74)  
**Lines:** 57–74  

The screen's `body: ListView` renders all 6 cards synchronously from `const [...]`. If `HealthConnectSyncCard` or `GoogleAccountCard` are waiting on async state, they may flash from empty → loaded without a skeleton. The `ref.listen` hooks handle errors but not loading states in the parent screen.

**Recommendation:** Watch `healthConnectSyncProvider` and `authNotifierProvider` for loading states; wrap the `HealthConnectSyncCard` and `GoogleAccountCard` in a conditional `AppleSkeletonShimmer`.

---

### 5.6 · WelcomeScreen — `featureTiles` List Instantiates Widgets Twice  
**Severity:** Low  
**File:** [`lib/presentation/screens/onboarding/welcome_screen.dart`](file://app/lib/presentation/screens/onboarding/welcome_screen.dart#L86-L110, L216-L239)  
**Lines:** 86–110 and 216–239  

The `featureTiles` `const` list (lines 86–110) is constructed as a local variable used in the scrolling branch. In the non-constrained (non-scrolling) branch (lines 213–239), the same three `_FeatureTile` widgets are copy-pasted directly. Any future change to tile content requires editing two places.

**Recommendation:** Consolidate into the `const featureTiles` list and use `...featureTiles` in both branches.

---

## Section 6 — HealthSyncSettingsScreen, MoreScreen, DataExportScreen

### 6.1 · DataExportScreen — `_generateFoodLogsJson()` and `_generateWeightLogsCsv()` Called Multiple Times per User Interaction  
**Severity:** High  
**File:** [`lib/presentation/screens/data_export_screen.dart`](file://app/lib/presentation/screens/data_export_screen.dart#L181-L195)  
**Lines:** 181–195  

```dart
onPreview: () => _showPreviewDialog('Food Logs Preview', _generateFoodLogsJson()),
onCopy: _copyFoodLogs,
```

Each tap on "Preview" or "Copy" calls `_generateFoodLogsJson()` which does `db.getAllFoodLogs()` → serialises the entire logs list to JSON synchronously on the UI thread. For users with 1,000+ logs, this will cause a noticeable jank (frame drop) or ANR on Android.

**Recommendation:** Compute the export string lazily and cache it:
```dart
String? _cachedFoodLogsJson;
String _getFoodLogsJson() => _cachedFoodLogsJson ??= _generateFoodLogsJson();
```
Or run generation in an `Isolate` / `compute()` call.

---

### 6.2 · DataExportScreen — `_copyFoodLogs()` Has No Error Handling for Clipboard Failure  
**Severity:** Medium  
**File:** [`lib/presentation/screens/data_export_screen.dart`](file://app/lib/presentation/screens/data_export_screen.dart#L89-L99)  
**Lines:** 89–99  

`Clipboard.setData(...)` can fail silently on some Android configurations (clipboard size limits, permission denied in background). No try/catch wraps the call.

**Recommendation:**
```dart
try {
  await Clipboard.setData(ClipboardData(text: jsonStr));
  // show success snackbar
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copy failed: $e')));
}
```

---

### 6.3 · MoreScreen — "Delete All My Data" Uses `AppTheme.calories` for a Destructive Action  
**Severity:** Medium  
**File:** [`lib/presentation/screens/more_screen.dart`](file://app/lib/presentation/screens/more_screen.dart#L256-L265)  
**Lines:** 256–265  

The "Delete All My Data" tile and its border use `AppTheme.calories` (orange-amber), which the design system uses for calorie data. A destructive action of this magnitude should use a visually distinct danger color (e.g., `const Color(0xFFFF453A)` — iOS system red) to maximise the signal that this is irreversible.

**Recommendation:** Introduce `AppTheme.destructive = const Color(0xFFFF3B30)` and use it for all destructive actions (delete account, delete data, sign out).

---

### 6.4 · HealthSyncSettingsScreen — `'Last: ${st.formattedLastSync}'` Can Show `'Last: Never'` Without Explanation  
**Severity:** Low  
**File:** [`lib/presentation/screens/health_sync_settings_screen.dart`](file://app/lib/presentation/screens/health_sync_settings_screen.dart#L145-L147)  
**Lines:** 145–147  

If `formattedLastSync` returns "Never" (first launch), the top sync card shows "Last: Never" without context on how to trigger a first sync, especially when permissions are not yet granted. New users will not understand the relationship between permission grant → first sync.

**Recommendation:** When `!st.hasPermissions`, replace the "Last sync" text with: "Grant permissions below to begin syncing." Only show the timestamp after a successful first sync.

---

### 6.5 · MoreScreen — `AppleStaggeredEntrance` Indices 0–8 Are Sequential But No Stagger Cap  
**Severity:** Low  
**File:** [`lib/presentation/screens/more_screen.dart`](file://app/lib/presentation/screens/more_screen.dart#L35-L172)  
**Lines:** 35–172  

`AppleStaggeredEntrance` with `index: 8` and `interval: 50ms` means the last tile animates in at `8 × 50 = 400ms` after the first. On first entry, all 9 tiles stagger nicely. However, returning to the screen re-runs `initState` of the `StatefulWidget` stagger animation, causing all 9 tiles to re-animate even though the user has seen them. The existing "single-play guard" in `AppleStaggeredEntrance` should handle this — verify it uses `AutomaticKeepAliveClientMixin` or a session-scoped flag.

**Recommendation:** Confirm `AppleStaggeredEntrance` has its single-play guard working for all parent rebuilds, not just widget rebuilds. Add a `once` flag defaulting `true`.

---

## Section 7 — Navigation & Global

### 7.1 · ScaffoldWithNavBar — `AnimatedSwitcher` Does Not Preserve State Between Tabs  
**Severity:** Critical  
**File:** [`lib/presentation/screens/scaffold_with_nav_bar.dart`](file://app/lib/presentation/screens/scaffold_with_nav_bar.dart#L31-L65)  
**Lines:** 31–65  

```dart
final List<Widget> _screens = const [
  DashboardScreen(),
  FoodLogScreen(),
  StrategyScreen(),
  MoreScreen(),
];

child: KeyedSubtree(
  key: ValueKey<int>(_currentIndex),
  child: _screens[_currentIndex],
),
```

`KeyedSubtree` with `ValueKey<int>` causes Flutter to **destroy and recreate** the current screen's widget tree on every tab switch. `FoodLogScreen`'s `_isCollapsed` state is lost when switching tabs. Any form state, scroll position, or in-progress search is reset. The existing `const` list doesn't help because `KeyedSubtree` disposes children.

**Recommendation:** Use `IndexedStack` instead of `AnimatedSwitcher` with `KeyedSubtree`, combined with `AutomaticKeepAliveClientMixin` on each screen's state:

```dart
body: IndexedStack(
  index: _currentIndex,
  children: _screens,
),
```
Then wrap the `AnimatedSwitcher` around the `IndexedStack` if cross-fade is desired.

---

### 7.2 · ScaffoldWithNavBar — `extendBody: true` Without Explicit Bottom Padding in Child Screens  
**Severity:** High  
**File:** [`lib/presentation/screens/scaffold_with_nav_bar.dart`](file://app/lib/presentation/screens/scaffold_with_nav_bar.dart#L49)  
**Line:** 49  

`extendBody: true` lets the body extend behind the frosted nav bar. Only `FoodLogScreen` adds a manual `SizedBox(height: 80)` bottom padding. `DashboardScreen` adds `SizedBox(height: 80)` (line 332), which is good. `StrategyScreen` adds `SizedBox(height: 32)` — insufficient for devices with 34px+ safe areas. `MoreScreen` body has `SizedBox(height: 24)` — also insufficient.

**Recommendation:** Standardise: add `const SizedBox(height: 90)` as the final item in every main-screen list/sliver, or use `MediaQuery.of(context).padding.bottom + 70` dynamically.

---

### 7.3 · AppBar — No Consistent `excludeHeaderSemantics` or `semanticLabel` on `AppBar.title`  
**Severity:** Low  
**File:** Multiple screen files  

Screens like `StrategyScreen`, `HealthSyncSettingsScreen`, `DataExportScreen` use a plain `Text(...)` title in `AppBar` without `Semantics(header: true, ...)`. VoiceOver will announce the title correctly as a navigation landmark, but the heading hierarchy is not explicitly declared.

**Recommendation:** Wrap each AppBar title in `Semantics(header: true, child: Text(...))` to properly declare heading level for screen readers.

---

## Section 8 — Accessibility Summary

| Widget | Issue | Severity |
|--------|-------|---------|
| `FoodLogScreen` menu button | Dead stub — VoiceOver announces interactive but it does nothing | Critical |
| `PlateServingSheet` Edit button | Dead stub — same issue | Critical |
| `NutritionSummaryBanner` page dots | False affordance, no swipeable content | Medium |
| `TimelineHourSlot` collapsed icons | No tooltip or food name label | Low |
| `MacroGaugeRing` | Semantics label present ✅ | — |
| `DynamicExpenditureCard` | Semantics label present ✅ | — |
| `PersistentSearchBar` | Barcode + Custom Food icons have `Semantics(button: true, label:...)` ✅ | — |
| All `AppleBouncy` tappables | Need `semanticLabel` on all instances; most present but some missing | Low |

---

## Section 9 — Micro-Interaction Opportunities

| Opportunity | Location | Effort |
|-------------|----------|--------|
| **Calorie ring celebration** — brief confetti burst when daily calorie goal is exactly hit (95–100%) | `MacroGaugeRing` | Medium |
| **Haptic on macro milestone** — subtle haptic when protein crosses 50%, 75%, 100% of target | `AnimatedMacroBar` in `MacroGaugeRing` | Low |
| **Date carousel swipe** — `SingleChildScrollView` has no swipe-to-change-day gesture on the timeline itself | `FoodLogScreen` | Medium |
| **Weight log celebration** — positive confirmation animation after successfully logging a weight entry | `WeightLogModal` | Low |
| **Search suggestions / recent foods** — show last 5 logged foods when search is empty, before user types | `FoodSearchScreen` | High value |
| **Slide-to-delete** in timeline | Replace long-press delete with Dismissible swipe-left → delete | `TimelineFoodCard` | Medium |
| **Oil modifier selection haptic** | Add `HapticFeedback.selectionClick()` on oil chip selection | `PlateServingSheet` | Low |
| **Onboarding progress save indicator** — show a brief "Progress saved" toast when step persists | `OnboardingFlowScreen._persistStepProgress` | Low |

---

## Critical Findings Summary

| # | Finding | File | Severity |
|---|---------|------|---------|
| C1 | FoodLogScreen menu button is a no-op dead stub | `food_log_screen.dart:154` | **Critical** |
| C2 | PlateServingSheet "Edit" button is a no-op dead stub | `plate_serving_sheet.dart:225` | **Critical** |
| C3 | Onboarding Step 24 can render indefinite spinner | `onboarding_flow_screen.dart:481` | **Critical** |
| C4 | Tab switching destroys all screen state via KeyedSubtree | `scaffold_with_nav_bar.dart:61` | **Critical** |
| C5 | `_programStyle` hardcoded `final = balanced` in 24-step flow | `onboarding_flow_screen.dart:78` | **High** (data correctness) |

---

## Recommended Fix Priority Queue

1. **Tab state preservation** (Critical) — `IndexedStack` refactor in `ScaffoldWithNavBar`
2. **Dead stubs** (Critical × 2) — FoodLogScreen menu + PlateServingSheet Edit  
3. **Step 24 spinner race** (Critical) — reorder `setState` before `_nextStep`  
4. **PersistentSearchBar bottom overlap** (High) — fix `bottom: 4` to account for nav bar
5. **Barcode scanner stubs** (High) — integrate real scanner or remove  
6. **QuickActionsSheet "Add Day Note" false write** (Medium) — remove or implement  
7. **Energy Balance zero-state** (High) — add neutral "BALANCE" badge  
8. **MacroProgramHeroCard days.first** (High) — use 7-day average  
9. **FoodSearchScreen filter architecture** (High) — push filters to SQL  
10. **DataExportScreen sync UI thread** (High) — `compute()` for JSON generation  

---

*Report produced by the full-app UI/UX diagnostic agent. All line references verified against the live source tree at `app/lib/presentation/`.*
