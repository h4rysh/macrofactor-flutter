import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/presentation/providers/auth_providers.dart';
import 'package:sique/presentation/screens/auth/change_password_dialog.dart';
import 'package:sique/presentation/screens/auth/delete_account_dialog.dart';
import 'package:sique/presentation/screens/auth/email_auth_dialog.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

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
                    _buildAuthProviderBadge(user),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (authState is AuthError) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.calories.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.calories.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.calories,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Google Sign-In Alert',
                          style: TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.calories,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppTheme.calories,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => ref
                            .read(authNotifierProvider.notifier)
                            .clearError(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    authState.message,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final authRepo = ref.watch(authRepositoryProvider);
    final isConfigured = authRepo.isConfigured;

    if (user.isAuthenticated) {
      final isEmailUser = user.authProvider == AuthProviderType.email;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isEmailUser) ...[
            AppleBouncy(
              onTap:
                  isLoading ? null : () => ChangePasswordDialog.show(context),
              child: Container(
                key: const Key('profile_change_password_btn'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder, width: 1),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.key_rounded,
                        size: 16, color: AppTheme.activeBlue),
                    SizedBox(width: 8),
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          AppleBouncy(
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
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              key: const Key('profile_delete_account_btn'),
              onPressed: isLoading
                  ? null
                  : () => DeleteAccountDialog.show(context, user: user),
              child: const Text(
                'Delete Account',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (!isConfigured) ...[
          Container(
            key: const Key('firebase_unconfigured_banner'),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppTheme.warning, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sign-in unavailable: Firebase not configured',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        AppleBouncy(
          onTap: isLoading
              ? null
              : () {
                  if (!isConfigured) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Sign-in unavailable: Firebase not configured'),
                        backgroundColor: AppTheme.warning,
                      ),
                    );
                    return;
                  }
                  ref.read(authNotifierProvider.notifier).signInWithGoogle();
                },
          child: Container(
            key: const Key('profile_sign_in_btn'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: isConfigured ? AppTheme.activeBlue : AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(12),
              border: isConfigured
                  ? null
                  : Border.all(color: AppTheme.cardBorder, width: 1),
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
                  Icon(Icons.login_rounded,
                      size: 18,
                      color:
                          isConfigured ? Colors.white : AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Sign in with Google',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isConfigured
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppleBouncy(
          onTap: isLoading
              ? null
              : () {
                  if (!isConfigured) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Sign-in unavailable: Firebase not configured'),
                        backgroundColor: AppTheme.warning,
                      ),
                    );
                    return;
                  }
                  EmailAuthDialog.show(context);
                },
          child: Container(
            key: const Key('profile_email_sign_in_btn'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.cardBorder,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: AppTheme.textPrimary,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Sign in or Register with Email',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppleBouncy(
          onTap: isLoading
              ? null
              : () {
                  ref
                      .read(authNotifierProvider.notifier)
                      .signInWithDemoAthlete();
                },
          child: Container(
            key: const Key('profile_demo_sign_in_btn'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.cardBorder,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  size: 16,
                  color: AppTheme.activeBlue,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Continue with Demo Athlete Profile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthProviderBadge(UserAccount user) {
    if (!user.isAuthenticated || user.authProvider == AuthProviderType.guest) {
      return const AppleBadge(
        key: Key('profile_auth_provider_badge'),
        label: 'Guest Mode',
        color: AppTheme.warning,
        icon: Icons.cloud_off_rounded,
      );
    }
    if (user.authProvider == AuthProviderType.google) {
      return const AppleBadge(
        key: Key('profile_auth_provider_badge'),
        label: 'Google Account',
        color: AppTheme.activeBlue,
        icon: Icons.g_mobiledata_rounded,
      );
    }
    return const AppleBadge(
      key: Key('profile_auth_provider_badge'),
      label: 'Email Account',
      color: AppTheme.success,
      icon: Icons.mark_email_read_rounded,
    );
  }
}
