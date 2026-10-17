import 'package:flutter/material.dart';
import 'package:macro_factor_app/presentation/screens/about_screen.dart';
import 'package:macro_factor_app/presentation/screens/data_export_screen.dart';
import 'package:macro_factor_app/presentation/screens/expenditure_settings_screen.dart';
import 'package:macro_factor_app/presentation/screens/food_log_settings_screen.dart';
import 'package:macro_factor_app/presentation/screens/profile_targets_screen.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';

/// Hub screen for the "More" bottom navigation destination.
/// Provides access to user profile, nutrition settings, expenditure engine tuning, data export, and app provenance.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSettingsTile(
            context: context,
            icon: Icons.account_circle_outlined,
            iconColor: AppTheme.activeBlue,
            title: 'Profile & Targets',
            subtitle: 'Caloric balance, height, weight, target macros',
            destination: const ProfileTargetsScreen(),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.restaurant_outlined,
            iconColor: AppTheme.calories,
            title: 'Food Log Settings',
            subtitle: 'Timeline display, portion units, cooking oil modifiers',
            destination: const FoodLogSettingsScreen(),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.monitor_weight_outlined,
            iconColor: AppTheme.expenditure,
            title: 'Expenditure & Weight Settings',
            subtitle:
                'Bayesian Kalman sensitivity, trend weight noise smoothing',
            destination: const ExpenditureSettingsScreen(),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.download_rounded,
            iconColor: AppTheme.trendWeight,
            title: 'Data Export & Diagnostics',
            subtitle: 'Export logs to JSON or CSV, inspect database health',
            destination: const DataExportScreen(),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.info_outline_rounded,
            iconColor: AppTheme.textSecondary,
            title: 'About MacroFactor (Indian Edition)',
            subtitle: 'v1.1.0 • Clean-Room Adherence-Neutral',
            destination: const AboutScreen(),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => destination,
              ),
            );
          },
          child: Padding(
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
        ),
      ),
    );
  }
}
