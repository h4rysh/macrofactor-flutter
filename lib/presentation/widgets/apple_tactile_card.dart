import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Tactile micro-interaction bouncy wrapper inspired by Apple iOS design.
/// Provides a gentle spring scale-down on press, subtle haptic feedback,
/// and spring-up on release with [Curves.easeOutCubic].
class AppleBouncy extends StatefulWidget {
  const AppleBouncy({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOutCubic,
    this.behavior = HitTestBehavior.opaque,
    this.enableHaptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final Curve curve;
  final HitTestBehavior behavior;
  final bool enableHaptics;

  @override
  State<AppleBouncy> createState() => _AppleBouncyState();
}

class _AppleBouncyState extends State<AppleBouncy> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTap() {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown: enabled ? _handleTapDown : null,
      onTapUp: enabled ? _handleTapUp : null,
      onTapCancel: enabled ? _handleTapCancel : null,
      onTap: enabled ? _handleTap : null,
      behavior: widget.behavior,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

/// Frosted glass card following Apple Human Interface Guidelines Liquid Glass standards.
/// Combines [BackdropFilter] gaussian blur with translucent specular border highlights.
class AppleGlassCard extends StatelessWidget {
  const AppleGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 18.0,
    this.borderGradient,
    this.borderColor,
    this.backgroundColor,
    this.blurSigma = 14.0,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient? borderGradient;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderGradient != null
        ? null
        : Border.all(
            color: borderColor ?? AppTheme.cardBorder.withValues(alpha: 0.8),
            width: 0.8,
          );

    final effectiveShadow = boxShadow ??
        const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveShadow,
        border: effectiveBorder,
        color: backgroundColor ?? AppTheme.cardSurface.withValues(alpha: 0.82),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Apple-styled pill tag or badge with subtle glow and refined contrast.
class AppleBadge extends StatelessWidget {
  const AppleBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.textColor,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor ?? color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile interactive card combining AppleBouncy spring feedback with subtle surface styling.
class AppleTactileCard extends StatelessWidget {
  const AppleTactileCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 18.0,
    this.border,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.blur = 0.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;
  final BoxBorder? border;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ??
        Border.all(
          color: borderColor ?? AppTheme.cardBorder,
          width: 0.8,
        );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
      ),
      child: child,
    );

    if (blur > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    return AppleBouncy(
      onTap: onTap,
      child: content,
    );
  }
}
