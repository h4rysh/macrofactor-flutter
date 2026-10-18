import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/screens/about_screen.dart';
import 'package:macro_factor_app/presentation/screens/account_profile_screen.dart';
import 'package:macro_factor_app/presentation/screens/data_export_screen.dart';
import 'package:macro_factor_app/presentation/screens/expenditure_settings_screen.dart';
import 'package:macro_factor_app/presentation/screens/food_log_settings_screen.dart';
import 'package:macro_factor_app/presentation/screens/goal_questionnaire_sheet.dart';
import 'package:macro_factor_app/presentation/screens/profile_targets_screen.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';
import 'package:macro_factor_app/presentation/widgets/animated_primitives.dart';
import 'package:macro_factor_app/presentation/widgets/profile_avatar_button.dart';

/// Hub screen for the "More" bottom navigation destination.
/// Provides access to user profile, nutrition settings, expenditure engine tuning, data export, and app provenance.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          AppleStaggeredEntrance(
            index: 0,
            child: _buildAccountCard(context, user),
          ),
          const SizedBox(height: 12),
          // Featured Apple Tactile Card: Interactive Goal & Preference Questionnaire
          AppleStaggeredEntrance(
            index: 1,
            child: AppleBouncy(
              onTap: () => GoalQuestionnaireSheet.show(context),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.activeBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.activeBlue.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppTheme.activeBlue.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.activeBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Interactive Program Setup',
                            style: TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '6-step dynamic branching for goal, rate, and Indian diet',
                            style: TextStyle(
                              fontFamily: 'DMSans',
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
                      color: AppTheme.activeBlue,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppleStaggeredEntrance(
            index: 2,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.account_circle_outlined,
              iconColor: AppTheme.activeBlue,
              title: 'Profile & Targets',
              subtitle: 'Caloric balance, height, weight, target macros',
              destination: const ProfileTargetsScreen(),
            ),
          ),
          AppleStaggeredEntrance(
            index: 3,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.restaurant_outlined,
              iconColor: AppTheme.calories,
              title: 'Food Log Settings',
              subtitle:
                  'Timeline display, portion units, cooking oil modifiers',
              destination: const FoodLogSettingsScreen(),
            ),
          ),
          AppleStaggeredEntrance(
            index: 4,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.monitor_weight_outlined,
              iconColor: AppTheme.expenditure,
              title: 'Expenditure & Weight Settings',
              subtitle:
                  'Bayesian Kalman sensitivity, trend weight noise smoothing',
              destination: const ExpenditureSettingsScreen(),
            ),
          ),
          AppleStaggeredEntrance(
            index: 5,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.download_rounded,
              iconColor: AppTheme.trendWeight,
              title: 'Data Export & Diagnostics',
              subtitle: 'Export logs to JSON or CSV, inspect database health',
              destination: const DataExportScreen(),
            ),
          ),
          AppleStaggeredEntrance(
            index: 6,
            child: _buildSettingsTile(
              context: context,
              icon: Icons.info_outline_rounded,
              iconColor: AppTheme.textSecondary,
              title: 'About MacroFactor (Indian Edition)',
              subtitle: 'v1.5.0 • Clean-Room Adherence-Neutral',
              destination: const AboutScreen(),
            ),
          ),
        ],
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
          borderRadius: BorderRadius.circular(16),
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
                            fontFamily: 'MacroSans',
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
                              fontFamily: 'DMSans',
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
                      fontFamily: 'DMSans',
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
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return AppleBouncy(
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
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
    );
  }
}
