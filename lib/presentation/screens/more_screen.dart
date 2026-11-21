import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/about_screen.dart';
import 'package:sique/presentation/screens/account_profile_screen.dart';
import 'package:sique/presentation/screens/auth/delete_account_dialog.dart';
import 'package:sique/presentation/screens/data_export_screen.dart';
import 'package:sique/presentation/screens/expenditure_settings_screen.dart';
import 'package:sique/presentation/screens/food_log_settings_screen.dart';
import 'package:sique/presentation/screens/health_sync_settings_screen.dart';
import 'package:sique/presentation/screens/profile_targets_screen.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/animated_primitives.dart';
import 'package:sique/presentation/widgets/auth_legal_footer.dart';
import 'package:sique/presentation/widgets/profile_avatar_button.dart';

/// Hub screen for the "More" bottom navigation destination.
/// Grouped into 4 obsidian cards:
/// 1. ACCOUNT & PROFILE
/// 2. COACHING & LOGGING
/// 3. DATA & INTEGRATIONS
/// 4. LEGAL & DANGER ZONE
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider);
    final targets = ref.watch(macroTargetProvider);

    final profileSummary =
        '${profile.currentWeightKg.toStringAsFixed(1)} kg · ${targets.targetCalories.round()} kcal/day';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. ACCOUNT & PROFILE
          _buildSectionHeader('ACCOUNT & PROFILE'),
          AppleStaggeredEntrance(
            index: 0,
            child: _buildAccountCard(context, user),
          ),
          const SizedBox(height: 8),
          AppleStaggeredEntrance(
            index: 1,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.account_circle_outlined,
              title: 'Profile & Targets',
              subtitle: profileSummary,
              destination: const ProfileTargetsScreen(),
            ),
          ),

          const SizedBox(height: 16),

          // 2. COACHING & LOGGING
          _buildSectionHeader('COACHING & LOGGING'),
          AppleStaggeredEntrance(
            index: 2,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.restaurant_outlined,
              title: 'Food Log Settings',
              subtitle:
                  'Timeline display, portion units, cooking oil modifiers',
              destination: const FoodLogSettingsScreen(),
            ),
          ),
          AppleStaggeredEntrance(
            index: 3,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.monitor_weight_outlined,
              title: 'Expenditure & Weight Settings',
              subtitle:
                  'Bayesian Kalman sensitivity, trend weight noise smoothing',
              destination: const ExpenditureSettingsScreen(),
            ),
          ),

          const SizedBox(height: 16),

          // 3. DATA & INTEGRATIONS
          _buildSectionHeader('DATA & INTEGRATIONS'),
          AppleStaggeredEntrance(
            index: 4,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.sync_rounded,
              title: 'Health Connect Sync',
              subtitle:
                  'Scale weight, workout sessions, permission diagnostics',
              destination: const HealthSyncSettingsScreen(),
            ),
          ),
          AppleStaggeredEntrance(
            index: 5,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.download_rounded,
              title: 'Data Export & Diagnostics',
              subtitle: 'Export logs to JSON or CSV, inspect database health',
              destination: const DataExportScreen(),
            ),
          ),

          const SizedBox(height: 16),

          // 4. LEGAL & DANGER ZONE
          _buildSectionHeader('LEGAL & DANGER ZONE'),
          AppleStaggeredEntrance(
            index: 6,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.info_outline_rounded,
              title: 'About Sique',
              subtitle: 'v2.0.0 • Clean-Room Adherence-Neutral',
              destination: const AboutScreen(),
            ),
          ),
          AppleStaggeredEntrance(
            index: 7,
            child: _buildAttributionAndLegalCard(context),
          ),
          const SizedBox(height: 10),
          AppleStaggeredEntrance(
            index: 8,
            child: _buildDeleteDataTile(context, user),
          ),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildAttributionAndLegalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: AppRadii.lgBorderRadius,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_menu_rounded,
                  size: 16, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nutritional data sourced from ICMR-NIN IFCT 2017 (Indian Food Composition Tables).',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.cardBorder),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                key: const Key('more_medical_disclaimer_btn'),
                onPressed: () => AuthLegalFooter.showMedicalDisclaimer(context),
                child: const Text(
                  'Medical Disclaimer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.activeBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text('•', style: TextStyle(color: AppTheme.textMuted)),
              TextButton(
                key: const Key('more_privacy_policy_btn'),
                onPressed: () => AuthLegalFooter.showPrivacyPolicy(context),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.activeBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteDataTile(BuildContext context, UserAccount? user) {
    return AppleBouncy(
      key: const Key('more_delete_data_tile'),
      onTap: () {
        DeleteAccountDialog.show(
          context,
          user: user ?? UserAccount.guest,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.calories.withValues(alpha: 0.08),
          borderRadius: AppRadii.lgBorderRadius,
          border: Border.all(
            color: AppTheme.calories.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.delete_forever_rounded,
                color: AppTheme.calories, size: 22),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delete All My Data',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.calories,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Permanently wipe local databases and reset account',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.calories,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, UserAccount? user) {
    final isSignedIn = user != null && user.isAuthenticated;
    final displayName = isSignedIn && user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : 'Guest Athlete';
    final subtitle = isSignedIn && user.email.trim().isNotEmpty
        ? user.email.trim()
        : 'Sign in with Google to sync workouts & scale data';

    return AppleBouncy(
      key: const Key('more_account_card'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AccountProfileScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: AppRadii.lgBorderRadius,
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            ProfileAvatarButton(
              user: user,
              size: 46,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountProfileScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSignedIn && user.healthConnectEnabled) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.activeBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SYNC ACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.activeBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return Semantics(
      button: true,
      hint: 'Navigates to $title screen',
      child: AppleBouncy(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => destination,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: AppRadii.lgBorderRadius,
            border: Border.all(color: AppTheme.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.cardElevated,
                  borderRadius: AppRadii.mdBorderRadius,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
