import 'package:flutter/material.dart';
import 'package:sique/domain/legal/legal_copy.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Reusable legal footer containing Privacy Policy and Medical Disclaimer dialog triggers.
class AuthLegalFooter extends StatelessWidget {
  const AuthLegalFooter({super.key});

  static void showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape:
            const RoundedRectangleBorder(borderRadius: AppRadii.lgBorderRadius),
        title: const Text(
          LegalCopy.privacyPolicyTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            LegalCopy.privacyPolicyText,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.activeBlueText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showMedicalDisclaimer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape:
            const RoundedRectangleBorder(borderRadius: AppRadii.lgBorderRadius),
        title: const Text(
          LegalCopy.medicalDisclaimerTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            LegalCopy.medicalDisclaimerText,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Understood',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.activeBlueText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        TextButton(
          key: const Key('auth_privacy_policy_btn'),
          onPressed: () => showPrivacyPolicy(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const Text(
          '•',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        TextButton(
          key: const Key('auth_medical_disclaimer_btn'),
          onPressed: () => showMedicalDisclaimer(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: const Text(
            'Medical Disclaimer',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
