import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/validation/domain_validator.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/utils/unit_formatter.dart';

/// Physical Stats card displaying weight, height, and age metrics with quick edit dialogs.
class PhysicalStatsCard extends StatelessWidget {
  const PhysicalStatsCard({
    super.key,
    required this.ref,
    required this.profile,
  });

  final WidgetRef ref;
  final UserProfile profile;

  static const double _lbsPerKg = 2.2046226218;

  @override
  Widget build(BuildContext context) {
    final useLbs = ref.watch(useImperialUnitsProvider);
    final unit = useLbs ? 'lbs' : 'kg';
    final currentDisp =
        useLbs ? profile.currentWeightKg * _lbsPerKg : profile.currentWeightKg;
    final targetDisp =
        useLbs ? profile.targetWeightKg * _lbsPerKg : profile.targetWeightKg;
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
            children: [
              const Icon(Icons.fitness_center_rounded,
                  size: 20, color: AppTheme.activeBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Physical Stats',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${profile.age} yrs • ${profile.isMale ? "Male" : "Female"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Current Weight',
                  value: '${currentDisp.toStringAsFixed(1)} $unit',
                  onTap: () => _showWeightDialog(context, useLbs: useLbs),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Target Weight',
                  value: '${targetDisp.toStringAsFixed(1)} $unit',
                  onTap: () => _showTargetWeightDialog(context, useLbs: useLbs),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Height',
                  value: '${profile.heightCm.toStringAsFixed(0)} cm',
                  onTap: () => _showHeightDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightDialog(BuildContext context, {required bool useLbs}) {
    final unit = useLbs ? 'lbs' : 'kg';
    final displayInit =
        useLbs ? profile.currentWeightKg * _lbsPerKg : profile.currentWeightKg;
    final controller =
        TextEditingController(text: displayInit.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Update Current Weight',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Current Weight ($unit)',
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            suffixText: unit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final raw = double.tryParse(controller.text);
              final valKg =
                  raw == null ? null : (useLbs ? raw / _lbsPerKg : raw);
              if (valKg != null && valKg > 20 && valKg < 300) {
                ref.read(userProfileProvider.notifier).updateProfile(
                      profile.copyWith(currentWeightKg: valKg),
                    );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save changes',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.activeBlue)),
          ),
        ],
      ),
    );
  }

  void _showTargetWeightDialog(BuildContext context, {required bool useLbs}) {
    final unit = useLbs ? 'lbs' : 'kg';
    final displayInit =
        useLbs ? profile.targetWeightKg * _lbsPerKg : profile.targetWeightKg;
    final controller =
        TextEditingController(text: displayInit.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Update Target Weight',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Target Weight ($unit)',
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            suffixText: unit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final raw = double.tryParse(controller.text);
              final valKg =
                  raw == null ? null : (useLbs ? raw / _lbsPerKg : raw);
              if (valKg != null) {
                final v = DomainValidator.validateTargetWeight(
                  targetWeightKg: valKg,
                  heightCm: profile.heightCm,
                  goalType: profile.goalType,
                );
                if (v.isValid) {
                  ref.read(userProfileProvider.notifier).updateProfile(
                        profile.copyWith(targetWeightKg: valKg),
                      );
                  Navigator.of(ctx).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(v.errorMessage ?? 'Invalid target weight'),
                      backgroundColor: AppTheme.calories,
                    ),
                  );
                }
              } else {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save changes',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.activeBlue)),
          ),
        ],
      ),
    );
  }

  void _showHeightDialog(BuildContext context) {
    final controller =
        TextEditingController(text: profile.heightCm.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Update Height',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: UnitFormatter.heightLabel(),
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            suffixText: UnitFormatter.heightUnit(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 80 && val < 260) {
                ref.read(userProfileProvider.notifier).updateProfile(
                      profile.copyWith(heightCm: val),
                    );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save changes',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.activeBlue)),
          ),
        ],
      ),
    );
  }
}
