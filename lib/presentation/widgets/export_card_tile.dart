import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Reusable card tile for data export and backup options.
class ExportCardTile extends StatelessWidget {
  final Key? actionKey;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badgeText;
  final String primaryButtonLabel;
  final IconData primaryButtonIcon;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonLabel;
  final IconData? secondaryButtonIcon;
  final VoidCallback? onSecondaryPressed;
  final Key? secondaryButtonKey;

  const ExportCardTile({
    super.key,
    this.actionKey,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.primaryButtonLabel,
    required this.primaryButtonIcon,
    required this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.secondaryButtonIcon,
    this.onSecondaryPressed,
    this.secondaryButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: actionKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: AppRadii.lgBorderRadius,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 10),
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
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (secondaryButtonLabel != null &&
                  onSecondaryPressed != null) ...[
                Expanded(
                  child: Semantics(
                    button: true,
                    label: '$secondaryButtonLabel for $title',
                    child: OutlinedButton.icon(
                      key: secondaryButtonKey,
                      icon: Icon(secondaryButtonIcon ?? Icons.preview_rounded,
                          size: 16),
                      label: Text(secondaryButtonLabel!),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.cardBorder),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.mdBorderRadius),
                      ),
                      onPressed: onSecondaryPressed,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Semantics(
                  button: true,
                  label: '$primaryButtonLabel for $title',
                  child: ElevatedButton.icon(
                    icon: Icon(primaryButtonIcon, size: 16),
                    label: Text(primaryButtonLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withAlpha(40),
                      foregroundColor: color,
                      elevation: 0,
                      side: BorderSide(color: color.withAlpha(90)),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.mdBorderRadius),
                    ),
                    onPressed: onPrimaryPressed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
