import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';

/// Screen for configuring Food Log preferences and defaults.
/// Automatically persists each configuration change directly to the database.
class FoodLogSettingsScreen extends ConsumerStatefulWidget {
  const FoodLogSettingsScreen({super.key});

  @override
  ConsumerState<FoodLogSettingsScreen> createState() =>
      _FoodLogSettingsScreenState();
}

class _FoodLogSettingsScreenState extends ConsumerState<FoodLogSettingsScreen> {
  late String _defaultPortionUnit;
  late String _defaultOilModifier;
  late bool _showEmptyHours;
  late bool _autoExpandMeals;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);
    _defaultPortionUnit = db.getSetting('default_portion_unit', 'Grams (g)');
    _defaultOilModifier =
        db.getSetting('default_oil_modifier', 'Standard (1 tbsp oil/ghee)');
    _showEmptyHours = db.getSetting('show_empty_hours', 'true') == 'true';
    _autoExpandMeals = db.getSetting('auto_expand_meals', 'true') == 'true';
  }

  void _updateSetting(String key, String value, VoidCallback onUpdate) {
    ref.read(databaseProvider).setSetting(key, value);
    setState(onUpdate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Food Log Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildPortionUnitCard(),
          const SizedBox(height: 16),
          _buildOilModifierCard(),
          const SizedBox(height: 16),
          _buildTimelineDisplayCard(),
          const SizedBox(height: 16),
          _buildHealthConnectSyncCard(),
          const SizedBox(height: 16),
          _buildCultureContextCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPortionUnitCard() {
    final units = [
      'Grams (g)',
      'Katori (Standard Bowl, 150ml)',
      'Standard Piece / Roti / Idli',
      'Tablespoon (15ml)',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.scale_rounded, size: 20, color: AppTheme.activeBlue),
              SizedBox(width: 8),
              Text(
                'Default Portion Unit',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'The initial serving measurement selected when opening any food item.',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ...units.map((unit) {
            final isSelected = _defaultPortionUnit == unit;
            return InkWell(
              onTap: () => _updateSetting(
                'default_portion_unit',
                unit,
                () => _defaultPortionUnit = unit,
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.activeBlue.withAlpha(30)
                      : AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 18,
                      color:
                          isSelected ? AppTheme.activeBlue : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOilModifierCard() {
    final modifiers = [
      'Zero Oil (Raw / Boiled / Steamed)',
      'Low Oil (1 tsp, ~40 kcal)',
      'Standard (1 tbsp oil/ghee, ~120 kcal)',
      'Extra Ghee / Restaurant Style (2 tbsp, ~240 kcal)',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop_outlined, size: 20, color: AppTheme.fat),
              SizedBox(width: 8),
              Text(
                'Default Cooking Oil Modifier',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'In Indian cooking, hidden preparation fat (tadka, ghee) is the #1 source of calorie estimation error. This sets your default presumption.',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ...modifiers.map((mod) {
            final isSelected = _defaultOilModifier == mod;
            return InkWell(
              onTap: () => _updateSetting(
                'default_oil_modifier',
                mod,
                () => _defaultOilModifier = mod,
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.fat.withAlpha(25)
                      : AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.fat : AppTheme.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 18,
                      color: isSelected ? AppTheme.fat : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        mod,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineDisplayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.view_timeline_rounded,
                  size: 20, color: AppTheme.expenditure),
              SizedBox(width: 8),
              Text(
                'Timeline & Display',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Show Empty Hourly Slots',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Displays unoccupied hour slots on the Food Log timeline for fast chronological logging.',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              value: _showEmptyHours,
              activeThumbColor: AppTheme.expenditure,
              onChanged: (val) {
                _updateSetting(
                  'show_empty_hours',
                  val.toString(),
                  () => _showEmptyHours = val,
                );
              },
            ),
          ),
          const Divider(height: 16, color: AppTheme.cardBorder),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Auto-Expand Meal Sections',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Keep Breakfast, Lunch, Snack, and Dinner accordion lists open by default.',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              value: _autoExpandMeals,
              activeThumbColor: AppTheme.expenditure,
              onChanged: (val) {
                _updateSetting(
                  'auto_expand_meals',
                  val.toString(),
                  () => _autoExpandMeals = val,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthConnectSyncCard() {
    final syncState = ref.watch(healthConnectSyncProvider);

    return Container(
      key: const Key('settings_health_connect_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.activeBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sync_rounded,
                  color: AppTheme.activeBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Health Connect Sync',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (syncState.isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.activeBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Synchronize workout sessions and smart scale weigh-ins automatically or on demand.',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last synced: ${syncState.formattedLastSync}',
                key: const Key('settings_last_sync_text'),
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
              ElevatedButton.icon(
                key: const Key('settings_sync_now_btn'),
                onPressed: syncState.isSyncing
                    ? null
                    : () {
                        ref.read(healthConnectSyncProvider.notifier).syncNow();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.activeBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.cardElevated,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: syncState.isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  syncState.isSyncing ? 'Syncing...' : 'Sync Now',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCultureContextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 22, color: AppTheme.fat),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'All settings are instantly auto-saved to SQLite. Changes immediately adjust portion selectors across plate sheets and food search.',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
