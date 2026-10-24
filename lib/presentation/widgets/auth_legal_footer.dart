import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Reusable legal footer containing Privacy Policy and Medical Disclaimer dialog triggers.
class AuthLegalFooter extends StatelessWidget {
  const AuthLegalFooter({super.key});

  static void showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Sique prioritizes your data privacy and security.\n\n'
            '1. Data Collection & Local Storage:\n'
            'All your workout logs, nutritional intake, body weight metrics, and personal health data '
            'are stored locally in an encrypted SQLite database on your device.\n\n'
            '2. Cloud Synchronization:\n'
            'When authenticated with Google or Email, data is synchronized securely with Firebase servers. '
            'We do not sell, rent, or monetize your personal data.\n\n'
            '3. Account Deletion & Data Wipe:\n'
            'You may permanently delete your account at any time from Settings. '
            'Deleting your account completely purges all local databases and cloud records.',
            style: TextStyle(
              fontFamily: 'DMSans',
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
                fontFamily: 'MacroSans',
                fontWeight: FontWeight.w600,
                color: AppTheme.activeBlue,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Medical Disclaimer',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Important Health & Safety Notice:\n\n'
            '1. Informational Purposes Only:\n'
            'Sique is an automated fitness and nutritional tracking tool. It does not provide medical advice, '
            'diagnosis, or treatment plans.\n\n'
            '2. Consult Healthcare Professionals:\n'
            'Always consult a physician or licensed healthcare provider before making significant adjustments to your diet, '
            'calorie intake, macronutrient distribution, or starting an intensive physical exercise regimen.\n\n'
            '3. Assumption of Risk:\n'
            'By using Sique, you acknowledge that participation in exercise programs and dietary modifications carries '
            'inherent risks, and you do so voluntarily.',
            style: TextStyle(
              fontFamily: 'DMSans',
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
                fontFamily: 'MacroSans',
                fontWeight: FontWeight.w600,
                color: AppTheme.activeBlue,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Privacy Policy',
            style: TextStyle(
              fontFamily: 'DMSans',
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Medical Disclaimer',
            style: TextStyle(
              fontFamily: 'DMSans',
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
