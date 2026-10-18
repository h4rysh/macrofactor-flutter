import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';
import 'package:macro_factor_app/presentation/providers/auth_providers.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';
import 'package:macro_factor_app/presentation/widgets/apple_tactile_card.dart';

/// Section 1: Google Account Card displaying user info and auth controls.
class GoogleAccountCard extends ConsumerWidget {
  const GoogleAccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isLoading = authState is AuthLoading;

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(user),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email.isNotEmpty
                          ? user.email
                          : 'Local Guest Account',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    AppleBadge(
                      label: user.isAuthenticated ? 'Connected' : 'Guest Mode',
                      color: user.isAuthenticated
                          ? AppTheme.success
                          : AppTheme.warning,
                      icon: user.isAuthenticated
                          ? Icons.check_circle_rounded
                          : Icons.cloud_off_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAuthButton(context, ref, user, isLoading),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppTheme.cardBorder, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Connect Sync',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Auto-sync Hevy workouts & smart scale weights',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                key: const Key('profile_health_connect_toggle'),
                value: user.healthConnectEnabled,
                activeTrackColor: AppTheme.activeBlue,
                onChanged: (val) => ref
                    .read(authNotifierProvider.notifier)
                    .setHealthConnectEnabled(val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserAccount user) {
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: AppTheme.cardElevated,
        backgroundImage: NetworkImage(user.photoUrl!),
        onBackgroundImageError: (_, __) {},
        child: user.photoUrl == null ? _buildFallbackInitial(user) : null,
      );
    }
    return _buildFallbackInitial(user);
  }

  Widget _buildFallbackInitial(UserAccount user) {
    final initial = user.displayName.trim().isNotEmpty
        ? user.displayName.trim().characters.first.toUpperCase()
        : 'G';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [
          AppTheme.activeBlue.withValues(alpha: 0.8),
          AppTheme.expenditure.withValues(alpha: 0.8),
        ]),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAuthButton(
      BuildContext context, WidgetRef ref, UserAccount user, bool isLoading) {
    if (user.isAuthenticated) {
      return AppleBouncy(
        onTap: isLoading
            ? null
            : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardSurface,
                    title: const Text('Sign Out',
                        style: TextStyle(color: AppTheme.textPrimary)),
                    content: const Text(
                      'Are you sure you want to sign out? All your local workout logs and nutrition data will remain intact.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out',
                            style: TextStyle(color: AppTheme.calories)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(authNotifierProvider.notifier).signOut();
                }
              },
        child: Container(
          key: const Key('profile_sign_out_btn'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: AppTheme.calories.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.calories.withValues(alpha: 0.4), width: 1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.calories,
                  ),
                )
              else ...[
                const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: AppTheme.calories,
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Sign Out',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.calories,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return AppleBouncy(
      onTap: isLoading
          ? null
          : () {
              ref.read(authNotifierProvider.notifier).signInWithGoogle();
            },
      child: Container(
        key: const Key('profile_sign_in_btn'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.activeBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              const Icon(Icons.login_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Sign in with Google',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
