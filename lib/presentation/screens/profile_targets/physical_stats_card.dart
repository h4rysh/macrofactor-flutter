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
                child: InkWell(
                  onTap: () => _showAgeSexDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppTheme.cardBorder, width: 0.6),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${profile.age} yrs • ${profile.isMale ? "Male" : "Female"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined,
                              size: 12, color: AppTheme.activeBlue),
                        ],
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
                  value: UnitFormatter.formatHeight(
                    profile.heightCm,
                    useImperial: useLbs,
                  ),
                  onTap: () => _showHeightDialog(context, useImperial: useLbs),
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
    String? errorText;
    showDialog<void>(
      context: context,
      builder: (ctx) => _DialogControllerScope(
        initialTexts: [displayInit.toStringAsFixed(1)],
        builder: (ctx, ctrls) {
          final controller = ctrls[0];
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              backgroundColor: AppTheme.cardSurface,
              title: const Text('Update Current Weight',
                  style: TextStyle(color: AppTheme.textPrimary)),
              content: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Current Weight ($unit)',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  suffixText: unit,
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final raw = double.tryParse(controller.text.trim());
                    final valKg =
                        raw == null ? null : (useLbs ? raw / _lbsPerKg : raw);
                    if (valKg == null || valKg <= 20 || valKg >= 300) {
                      setDialogState(() {
                        errorText = useLbs
                            ? 'Enter a weight between 45 and 660 lbs'
                            : 'Enter a weight between 21 and 299 kg';
                      });
                      return;
                    }
                    ref.read(userProfileProvider.notifier).updateProfile(
                          profile.copyWith(currentWeightKg: valKg),
                        );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save changes',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.activeBlueText)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTargetWeightDialog(BuildContext context, {required bool useLbs}) {
    final unit = useLbs ? 'lbs' : 'kg';
    final displayInit =
        useLbs ? profile.targetWeightKg * _lbsPerKg : profile.targetWeightKg;
    String? errorText;
    showDialog<void>(
      context: context,
      builder: (ctx) => _DialogControllerScope(
        initialTexts: [displayInit.toStringAsFixed(1)],
        builder: (ctx, ctrls) {
          final controller = ctrls[0];
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              backgroundColor: AppTheme.cardSurface,
              title: const Text('Update Target Weight',
                  style: TextStyle(color: AppTheme.textPrimary)),
              content: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Target Weight ($unit)',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  suffixText: unit,
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final raw = double.tryParse(controller.text.trim());
                    final valKg =
                        raw == null ? null : (useLbs ? raw / _lbsPerKg : raw);
                    if (valKg == null) {
                      setDialogState(() {
                        errorText = 'Enter a valid target weight ($unit)';
                      });
                      return;
                    }
                    final v = DomainValidator.validateTargetWeight(
                      targetWeightKg: valKg,
                      heightCm: profile.heightCm,
                      goalType: profile.goalType,
                      useImperial: useLbs,
                    );
                    if (v.isValid) {
                      ref.read(userProfileProvider.notifier).updateProfile(
                            profile.copyWith(targetWeightKg: valKg),
                          );
                      Navigator.of(ctx).pop();
                    } else {
                      setDialogState(() {
                        errorText = v.errorMessage ?? 'Invalid target weight';
                      });
                    }
                  },
                  child: const Text('Save changes',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.activeBlueText)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHeightDialog(BuildContext context, {bool useImperial = false}) {
    final imperial = UnitFormatter.cmToFeetInches(profile.heightCm);
    String? errorText;
    showDialog<void>(
      context: context,
      builder: (ctx) => _DialogControllerScope(
        initialTexts: [
          profile.heightCm.toStringAsFixed(0),
          imperial.feet.toString(),
          imperial.inches.round().toString(),
        ],
        builder: (ctx, ctrls) {
          final cmController = ctrls[0];
          final ftController = ctrls[1];
          final inController = ctrls[2];
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              backgroundColor: AppTheme.cardSurface,
              title: const Text('Update Height',
                  style: TextStyle(color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (useImperial)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ftController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            autofocus: true,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            onChanged: (_) {
                              if (errorText != null) {
                                setDialogState(() => errorText = null);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Feet',
                              labelStyle:
                                  TextStyle(color: AppTheme.textSecondary),
                              suffixText: 'ft',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: inController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            style: const TextStyle(color: AppTheme.textPrimary),
                            onChanged: (_) {
                              if (errorText != null) {
                                setDialogState(() => errorText = null);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Inches',
                              labelStyle:
                                  TextStyle(color: AppTheme.textSecondary),
                              suffixText: 'in',
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    TextField(
                      controller: cmController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      autofocus: true,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      onChanged: (_) {
                        if (errorText != null) {
                          setDialogState(() => errorText = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: UnitFormatter.heightLabel(),
                        labelStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        suffixText: UnitFormatter.heightUnit(),
                      ),
                    ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.calories,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    double? val;
                    if (useImperial) {
                      final ft = int.tryParse(ftController.text.trim());
                      final inches =
                          int.tryParse(inController.text.trim()) ?? 0;
                      if (ft != null && inches >= 0 && inches <= 11) {
                        val =
                            UnitFormatter.feetInchesToCm(ft, inches.toDouble());
                      }
                    } else {
                      val = double.tryParse(cmController.text.trim());
                    }
                    if (val == null || val <= 80 || val >= 260) {
                      setDialogState(() {
                        errorText = useImperial
                            ? 'Enter a height between 2 ft 8 in and 8 ft 6 in'
                            : 'Enter a height between 81 and 259 cm';
                      });
                      return;
                    }
                    ref.read(userProfileProvider.notifier).updateProfile(
                          profile.copyWith(heightCm: val),
                        );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save changes',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.activeBlueText)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAgeSexDialog(BuildContext context) {
    final profile = ref.read(userProfileProvider);
    var isMale = profile.isMale;
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (ctx) => _DialogControllerScope(
        initialTexts: [profile.age.toString()],
        builder: (ctx, ctrls) {
          final ageController = ctrls[0];
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              backgroundColor: AppTheme.cardSurface,
              title: const Text(
                'Edit Age & Biological Sex',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Age (years)',
                      labelStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Biological Sex (for baseline metabolism)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Male'),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Female'),
                      ),
                    ],
                    selected: {isMale},
                    onSelectionChanged: (selection) {
                      if (selection.isNotEmpty) {
                        setDialogState(() => isMale = selection.first);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final age = int.tryParse(ageController.text.trim());
                    if (age == null || age < 18 || age > 110) {
                      setDialogState(() {
                        errorText = 'Enter an age between 18 and 110';
                      });
                      return;
                    }
                    ref.read(userProfileProvider.notifier).updateProfile(
                          profile.copyWith(age: age, isMale: isMale),
                        );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text(
                    'Save changes',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.activeBlueText,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DialogControllerScope extends StatefulWidget {
  const _DialogControllerScope({
    required this.initialTexts,
    required this.builder,
  });

  final List<String> initialTexts;
  final Widget Function(
    BuildContext context,
    List<TextEditingController> controllers,
  ) builder;

  @override
  State<_DialogControllerScope> createState() => _DialogControllerScopeState();
}

class _DialogControllerScopeState extends State<_DialogControllerScope> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialTexts
        .map((t) => TextEditingController(text: t))
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controllers);
}
