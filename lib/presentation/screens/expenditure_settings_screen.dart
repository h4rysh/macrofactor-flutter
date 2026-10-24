import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Screen for viewing and configuring the Bayesian Expenditure engine and Weight Trend smoother.
class ExpenditureSettingsScreen extends ConsumerStatefulWidget {
  const ExpenditureSettingsScreen({super.key});

  @override
  ConsumerState<ExpenditureSettingsScreen> createState() =>
      _ExpenditureSettingsScreenState();
}

class _ExpenditureSettingsScreenState
    extends ConsumerState<ExpenditureSettingsScreen> {
  late String _sensitivityMode;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);
    _sensitivityMode = db.getSetting('expenditure_sensitivity', 'Standard');
  }

  void _updateSensitivity(String mode) {
    ref.read(databaseProvider).setSetting('expenditure_sensitivity', mode);
    setState(() => _sensitivityMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final expenditureState = ref.watch(expenditureStateProvider);
    final trendPoint = ref.watch(latestTrendWeightProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Expenditure & Weight'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildLiveMetricsCard(
              expenditureState.expenditureKcal, trendPoint?.trendWeightKg),
          const SizedBox(height: 16),
          _buildBaselineSettingCard(profile),
          const SizedBox(height: 16),
          _buildSensitivityCard(),
          const SizedBox(height: 16),
          _buildAdherenceNeutralityCard(),
          const SizedBox(height: 16),
          _buildNoiseEnvelopeEducationCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLiveMetricsCard(double expenditureKcal, double? trendWeightKg) {
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
          const Text(
            'Live Algorithmic State',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.expenditure.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expenditure',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: AppTheme.expenditure,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${expenditureKcal.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Bayesian Kalman Estimate',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.trendWeight.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trend Weight',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: AppTheme.trendWeight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trendWeightKg != null
                            ? '${trendWeightKg.toStringAsFixed(1)} kg'
                            : 'No logs yet',
                        style: const TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Bidirectional Smoothed',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineSettingCard(UserProfile profile) {
    final baseline = profile.baselineExpenditureKcal;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Baseline Expenditure Prior',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${baseline.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.expenditure,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Initial mathematical prior used before sufficient longitudinal weight and intake observations are collected.',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.expenditure,
              inactiveTrackColor: AppTheme.cardBorder,
              thumbColor: AppTheme.expenditure,
              trackHeight: 4,
            ),
            child: Slider(
              value: baseline.clamp(1400.0, 3500.0),
              min: 1400.0,
              max: 3500.0,
              divisions: 84,
              onChanged: (val) {
                ref.read(userProfileProvider.notifier).updateProfile(
                      profile.copyWith(
                          baselineExpenditureKcal: val.roundToDouble()),
                    );
              },
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1,400 kcal',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: AppTheme.textMuted)),
              Text('3,500 kcal',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivityCard() {
    final modes = [
      {'name': 'Conservative', 'desc': 'Dampened updates, lower variance.'},
      {'name': 'Standard', 'desc': 'Authentic Sique Kalman response.'},
      {
        'name': 'Dynamic',
        'desc': 'Fast tracking for rapid training cycle shifts.'
      },
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
          const Text(
            'Kalman Filter Responsiveness',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...modes.map((item) {
            final name = item['name']!;
            final desc = item['desc']!;
            final isSelected = _sensitivityMode == name;
            return InkWell(
              onTap: () => _updateSensitivity(name),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.expenditure.withAlpha(25)
                      : AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.expenditure : AppTheme.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 18,
                      color: isSelected
                          ? AppTheme.expenditure
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            desc,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
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

  Widget _buildAdherenceNeutralityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 20, color: AppTheme.activeBlue),
              SizedBox(width: 8),
              Text(
                'Adherence Neutrality Guarantee',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Unlike legacy trackers that punish you with red alerts or arbitrary calorie drops when you overshoot targets, Sique treats your body as a thermodynamic system:\n\n'
            '• Overeating does not decrease your expenditure.\n'
            '• Missing days (<500 kcal logged) are excluded from Bayesian updates to prevent false metabolic drop-offs.\n'
            '• A hard ±150 kcal daily clamp prevents erratic spikes from temporary water weight or sodium retention.',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoiseEnvelopeEducationCard() {
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
          Icon(Icons.auto_graph_rounded, size: 22, color: AppTheme.trendWeight),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scale weight fluctuates up to ±2.5 kg daily due to glycogen hydration, fiber transit, and sodium. The Weight Trend algorithm filters this high-frequency noise using an exponential moving average with forward-backward passes.',
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
