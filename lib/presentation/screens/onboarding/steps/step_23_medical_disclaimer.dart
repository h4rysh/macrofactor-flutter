import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 23: Medical Disclaimer & Safety Acknowledgment (Blocks Progression Until Checked)
class Step23MedicalDisclaimer extends StatefulWidget {
  const Step23MedicalDisclaimer({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<Step23MedicalDisclaimer> createState() =>
      _Step23MedicalDisclaimerState();
}

class _Step23MedicalDisclaimerState extends State<Step23MedicalDisclaimer> {
  bool _hasAcknowledged = false;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Health & Safety Notice',
      subtitle:
          'Please review and acknowledge Sique\'s clinical disclaimer before activating your program.',
      icon: Icons.health_and_safety_rounded,
      continueKey: const Key('step_23_continue_btn'),
      isContinueEnabled: _hasAcknowledged,
      onContinue: _hasAcknowledged ? widget.onNext : null,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
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
                    Icon(Icons.medical_information_outlined,
                        size: 20, color: AppTheme.activeBlue),
                    SizedBox(width: 10),
                    Text(
                      'Medical Disclaimer',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '1. Not Medical Advice:\n'
                  'Sique is an automated algorithmic tracking and nutritional estimation tool. It does not provide medical diagnosis, treatment, or clinical nutrition therapy.\n\n'
                  '2. Physician Consultation:\n'
                  'Always consult a qualified healthcare physician or registered clinical dietitian before starting an intensive dietary deficit, surplus, or high-volume resistance training regimen.\n\n'
                  '3. Personal Health Responsibility:\n'
                  'If you experience faintness, dizzy spells, severe fatigue, or gastrointestinal distress, discontinue the program and seek immediate medical evaluation.',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppleTactileCard(
            key: const Key('step_23_disclaimer_checkbox'),
            onTap: () => setState(() => _hasAcknowledged = !_hasAcknowledged),
            backgroundColor: _hasAcknowledged
                ? AppTheme.activeBlue.withValues(alpha: 0.12)
                : AppTheme.cardElevated,
            border: Border.all(
              color:
                  _hasAcknowledged ? AppTheme.activeBlue : AppTheme.cardBorder,
              width: _hasAcknowledged ? 2 : 1,
            ),
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Checkbox.adaptive(
                  value: _hasAcknowledged,
                  activeColor: AppTheme.activeBlue,
                  onChanged: (val) =>
                      setState(() => _hasAcknowledged = val ?? false),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'I have read, understood, and agree to the Health & Medical Disclaimer.',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
