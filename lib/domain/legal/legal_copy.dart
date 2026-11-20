/// Centralized single source of truth for all legal copy across Sique.
/// Includes Privacy Policy, Medical Disclaimer, Terms of Service, and related notices.
class LegalCopy {
  const LegalCopy._();

  // --- Privacy Policy ---
  static const String privacyPolicyTitle = 'Privacy Policy';
  static const String privacyPolicySubtitle =
      'Local-first storage, authentication & privacy';

  static const String privacyPolicyText =
      'Sique prioritizes your data privacy and security.\n\n'
      '1. Data Collection & Local Storage:\n'
      'All your workout logs, nutritional intake, body weight metrics, and personal health data '
      'are stored locally in a private SQLite database protected by Android application sandboxing '
      'and hardware-backed File-Based Encryption (FBE).\n\n'
      '2. Cloud Authentication & Local Sovereignty:\n'
      'When authenticated with Google or Email, credentials are authenticated securely via Firebase Auth. '
      'Your nutrition entries, weight records, and physical profile remain exclusively on your device in local SQLite. '
      'We do not upload, sync, or monetize your personal nutrition or health data.\n\n'
      '3. Account Deletion & Data Wipe:\n'
      'You may permanently delete your account at any time from Settings. '
      'Deleting your account completely purges your authentication profile and permanently wipes all on-device databases.';

  // --- Medical Disclaimer ---
  static const String medicalDisclaimerTitle = 'Medical Disclaimer';
  static const String medicalDisclaimerSubtitle =
      'Safety notices, fitness guidelines & liability';

  static const String medicalDisclaimerText =
      'Important Health & Safety Notice:\n\n'
      '1. Informational Purposes Only:\n'
      'Sique is an automated fitness and nutritional tracking tool. It does not provide medical advice, '
      'diagnosis, or treatment plans.\n\n'
      '2. Consult Healthcare Professionals:\n'
      'Always consult a physician or licensed healthcare provider before making significant adjustments to your diet, '
      'calorie intake, macronutrient distribution, or starting an intensive physical exercise regimen.\n\n'
      '3. Assumption of Risk:\n'
      'By using Sique, you acknowledge that participation in exercise programs and dietary modifications carries '
      'inherent risks, and you do so voluntarily.';

  // --- Onboarding Medical Disclaimer ---
  static const String onboardingNoticeTitle = 'Health & Safety Notice';
  static const String onboardingNoticeSubtitle =
      'Please review and acknowledge Sique\'s clinical disclaimer before activating your program.';
  static const String onboardingDisclaimerBody = '1. Not Medical Advice:\n'
      'Sique is an automated algorithmic tracking and nutritional estimation tool. It does not provide medical diagnosis, treatment, or clinical nutrition therapy.\n\n'
      '2. Physician Consultation:\n'
      'Always consult a qualified healthcare physician or registered clinical dietitian before starting an intensive dietary deficit, surplus, or high-volume resistance training regimen.\n\n'
      '3. Personal Health Responsibility:\n'
      'If you experience faintness, dizzy spells, severe fatigue, or gastrointestinal distress, discontinue the program and seek immediate medical evaluation.';
  static const String onboardingDisclaimerAgreement =
      'I have read, understood, and agree to the Health & Medical Disclaimer.';

  // --- Terms of Service ---
  static const String termsTitle = 'Terms of Service';
  static const String termsSubtitle =
      'Usage terms, user obligations & liability limitations';

  static const String termsText = 'Terms of Service:\n\n'
      '1. Acceptance of Terms:\n'
      'By accessing or using Sique, you agree to be bound by these Terms of Service. '
      'If you do not agree to these terms, do not use the application.\n\n'
      '2. Health & Fitness Information:\n'
      'All recommendations, estimates, and data provided by Sique are for personal '
      'informational purposes only and do not constitute medical or healthcare advice.\n\n'
      '3. Local Data Sovereignty:\n'
      'You are solely responsible for managing and backing up your local device data. '
      'Sique does not host or store your nutritional or biometric data on remote servers.\n\n'
      '4. Limitation of Liability:\n'
      'To the maximum extent permitted by applicable law, Sique and its contributors '
      'shall not be liable for any direct, indirect, incidental, or consequential damages '
      'resulting from the use of this software.';
}
