import 'package:flutter/material.dart';
import 'package:macro_factor_app/domain/models/user_account.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';
import 'package:macro_factor_app/presentation/widgets/apple_tactile_card.dart';

/// 36x36 (or customizable) circular profile avatar button with AppleBouncy tactile feedback.
/// Displays user photo if available, user initial if authenticated, or guest person icon.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    this.user,
    this.size = 36.0,
    this.onTap,
  });

  final UserAccount? user;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = user?.isAuthenticated ?? false;

    return AppleBouncy(
      onTap: onTap,
      scaleDown: 0.92,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.cardElevated,
          border: Border.all(
            color: isAuthenticated
                ? AppTheme.activeBlue.withValues(alpha: 0.7)
                : AppTheme.cardBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isAuthenticated ? AppTheme.activeBlue : Colors.black)
                  .withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: _buildAvatarContent(context),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(BuildContext context) {
    final photoUrl = user?.photoUrl;
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final u = user;
    if (u != null && u.isAuthenticated && u.displayName.trim().isNotEmpty) {
      final initial = u.displayName.trim().characters.first.toUpperCase();
      return Container(
        color: AppTheme.activeBlue.withValues(alpha: 0.2),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      );
    }
    return Container(
      color: AppTheme.cardElevated,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: size * 0.55,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
