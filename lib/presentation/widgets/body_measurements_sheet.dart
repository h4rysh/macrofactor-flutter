import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/algorithms/anthropometric_service.dart';
import '../../domain/models/body_measurement_entry.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';
import 'apple_sheet_grabber.dart';
import 'apple_tactile_card.dart';

/// Card on Strategy tab showing anthropometric body composition and silent recomp status.
class AnthropometricsCard extends ConsumerWidget {
  const AnthropometricsCard({super.key});

  void _openMeasurementsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BodyMeasurementsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurements = ref.watch(bodyMeasurementsProvider);
    final profile = ref.watch(userProfileProvider);
    final isSilentRecomp = ref.watch(recompositionStatusProvider);

    final latest = measurements.isNotEmpty ? measurements.first : null;
    final waist = latest?.waistCm;
    final neck = latest?.neckCm ?? profile.neckCircumferenceCm;
    final hips = latest?.hipsCm;
    final height = profile.heightCm;

    // Calculate US Navy Body Fat % if possible
    double? navyBf;
    if (waist != null && neck != null && height > 0) {
      navyBf = AnthropometricService.calculateNavyBodyFatPct(
        isMale: profile.isMale,
        heightCm: height,
        waistCm: waist,
        neckCm: neck,
        hipsCm: hips,
      );
    }

    // Waist-to-Height Ratio
    double? whtr;
    String? whtrClassification;
    if (waist != null && height > 0) {
      whtr = AnthropometricService.calculateWhtr(
        waistCm: waist,
        heightCm: height,
      );
      if (whtr != null) {
        whtrClassification =
            AnthropometricService.classifyWhtr(whtr).displayName;
      }
    }

    return AppleTactileCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      backgroundColor: AppTheme.cardSurface,
      borderColor: isSilentRecomp
          ? const Color(0xFF66BB6A).withValues(alpha: 0.6)
          : AppTheme.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSilentRecomp
                      ? const Color(0xFF66BB6A).withValues(alpha: 0.16)
                      : AppTheme.activeBlue.withValues(alpha: 0.16),
                  borderRadius: AppRadii.mdBorderRadius,
                ),
                child: Icon(
                  isSilentRecomp
                      ? Icons.fitness_center_rounded
                      : Icons.straighten_rounded,
                  size: 20,
                  color: isSilentRecomp
                      ? const Color(0xFF66BB6A)
                      : AppTheme.activeBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSilentRecomp
                          ? 'SILENT RECOMPOSITION ACTIVE'
                          : 'BODY COMPOSITION & ANTHROPOMETRICS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSilentRecomp
                            ? const Color(0xFF66BB6A)
                            : AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSilentRecomp
                          ? 'Fat Loss & Muscle Growth Detected'
                          : 'Circumference & Navy BF% Radar',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openMeasurementsSheet(context),
                icon: const Icon(
                  Icons.edit_calendar_rounded,
                  color: AppTheme.activeBlue,
                  size: 20,
                ),
                tooltip: 'Log Body Measurements',
              ),
            ],
          ),
          if (isSilentRecomp) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                borderRadius: AppRadii.mdBorderRadius,
                border: Border.all(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Color(0xFF66BB6A),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scale weight holds steady while waist circumference shrank. Sique preserves your calorie targets to support muscle building.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Metric Summary Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Waist',
                  value: waist != null ? '${waist.toStringAsFixed(1)} cm' : '—',
                  sub: whtrClassification ?? 'Not logged',
                  color: AppTheme.activeBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Navy Body Fat',
                  value:
                      navyBf != null ? '${navyBf.toStringAsFixed(1)}%' : '—',
                  sub: navyBf != null ? 'US Navy formula' : 'Add neck + waist',
                  color: AppTheme.protein,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'WHtR Ratio',
                  value: whtr != null ? whtr.toStringAsFixed(2) : '—',
                  sub: whtr != null
                      ? (whtr < 0.50 ? 'Optimal' : 'Elevated')
                      : 'Target < 0.50',
                  color: AppTheme.carbs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppleBouncy(
            scaleDown: 0.96,
            onTap: () {
              AppHaptics.lightImpact();
              _openMeasurementsSheet(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardElevated,
                borderRadius: AppRadii.mdBorderRadius,
                border: Border.all(color: AppTheme.cardBorder, width: 1),
              ),
              alignment: Alignment.center,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: AppTheme.activeBlue),
                    SizedBox(width: 6),
                    Text(
                      'Log Circumference & Body Fat',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.activeBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: const BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: AppRadii.mdBorderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Modal bottom sheet for logging new circumference entries.
class BodyMeasurementsSheet extends ConsumerStatefulWidget {
  const BodyMeasurementsSheet({super.key});

  @override
  ConsumerState<BodyMeasurementsSheet> createState() =>
      _BodyMeasurementsSheetState();
}

class _BodyMeasurementsSheetState
    extends ConsumerState<BodyMeasurementsSheet> {
  late final TextEditingController _waistCtrl;
  late final TextEditingController _neckCtrl;
  late final TextEditingController _hipsCtrl;
  late final TextEditingController _chestCtrl;
  late final TextEditingController _thighCtrl;
  late final TextEditingController _bicepsCtrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    final recent = ref.read(bodyMeasurementsProvider);
    final latest = recent.isNotEmpty ? recent.first : null;

    _waistCtrl = TextEditingController(
      text: latest?.waistCm?.toString() ?? '',
    );
    _neckCtrl = TextEditingController(
      text: latest?.neckCm?.toString() ??
          profile.neckCircumferenceCm?.toString() ??
          '',
    );
    _hipsCtrl = TextEditingController(
      text: latest?.hipsCm?.toString() ?? '',
    );
    _chestCtrl = TextEditingController(
      text: latest?.chestCm?.toString() ?? '',
    );
    _thighCtrl = TextEditingController(
      text: latest?.thighCm?.toString() ?? '',
    );
    _bicepsCtrl = TextEditingController(
      text: latest?.bicepsCm?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _waistCtrl.dispose();
    _neckCtrl.dispose();
    _hipsCtrl.dispose();
    _chestCtrl.dispose();
    _thighCtrl.dispose();
    _bicepsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    double? parseBound(String text, double min, double max) {
      final v = double.tryParse(text.trim());
      if (v == null || v < min || v > max) return null;
      return v;
    }

    final waist = parseBound(_waistCtrl.text, 30.0, 250.0);
    final neck = parseBound(_neckCtrl.text, 15.0, 90.0);
    final hips = parseBound(_hipsCtrl.text, 30.0, 250.0);
    final chest = parseBound(_chestCtrl.text, 30.0, 250.0);
    final thigh = parseBound(_thighCtrl.text, 20.0, 150.0);
    final biceps = parseBound(_bicepsCtrl.text, 15.0, 100.0);

    // Guard: Require at least one valid measurement
    if (waist == null &&
        neck == null &&
        hips == null &&
        chest == null &&
        thigh == null &&
        biceps == null) {
      Navigator.of(context).pop();
      return;
    }

    final profile = ref.read(userProfileProvider);
    final now = DateTime.now();

    // Compute US Navy body fat if inputs are present
    double? bf;
    if (waist != null && neck != null && profile.heightCm > 0) {
      bf = AnthropometricService.calculateNavyBodyFatPct(
        isMale: profile.isMale,
        heightCm: profile.heightCm,
        waistCm: waist,
        neckCm: neck,
        hipsCm: hips,
      );
    }

    final entry = BodyMeasurementEntry(
      id: 'bm_${now.millisecondsSinceEpoch}',
      date: now,
      waistCm: waist,
      neckCm: neck,
      hipsCm: hips,
      chestCm: chest,
      thighCm: thigh,
      bicepsCm: biceps,
      bodyFatPct: bf,
      loggedAt: now,
    );

    ref.read(bodyMeasurementsProvider.notifier).saveMeasurement(entry);

    // Also update profile baseline neck circumference if provided
    if (neck != null) {
      ref.read(userProfileProvider.notifier).updateProfile(
            profile.copyWith(neckCircumferenceCm: neck),
          );
    }

    AppHaptics.successFeedback();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 16),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppleSheetGrabber(margin: EdgeInsets.only(bottom: 8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Log Body Measurements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Record circumferences in centimeters. Sique calculates US Navy Body Fat % and monitors waist trends for muscle retention.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _waistCtrl,
                        label: 'Waist (cm)',
                        hint: 'e.g. 82.0',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _neckCtrl,
                        label: 'Neck (cm)',
                        hint: 'e.g. 38.0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _hipsCtrl,
                        label: 'Hips (cm)',
                        hint: 'e.g. 96.0',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _chestCtrl,
                        label: 'Chest (cm)',
                        hint: 'e.g. 98.0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _thighCtrl,
                        label: 'Thigh (cm)',
                        hint: 'e.g. 56.0',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _bicepsCtrl,
                        label: 'Bicep (cm)',
                        hint: 'e.g. 34.0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppleBouncy(
                  scaleDown: 0.96,
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppTheme.activeBlue,
                      borderRadius: AppRadii.lgBorderRadius,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Save Measurements',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            filled: true,
            fillColor: AppTheme.cardElevated,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: const OutlineInputBorder(
              borderRadius: AppRadii.mdBorderRadius,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
