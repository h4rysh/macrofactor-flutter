import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Standardized empty state widget for Sique.
class SiqueEmptyState extends StatelessWidget {
  const SiqueEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconSize = 44.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    this.isCompact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.cardBorder,
                  width: 1,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Icon(
                  icon,
                  size: isCompact ? iconSize * 0.75 : iconSize,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            SizedBox(height: isCompact ? 10 : 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isCompact ? 15 : 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: isCompact ? 14 : 20),
              AppleBouncy(
                scaleDown: 0.96,
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.activeBlue.withValues(alpha: 0.16),
                    borderRadius: AppRadii.xlBorderRadius,
                    border: Border.all(
                      color: AppTheme.activeBlue.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.activeBlue,
                    ),
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
