import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Tactile micro-interaction bouncy wrapper inspired by Apple iOS design.
/// Provides a gentle spring scale-down on press, subtle haptic feedback,
/// a clamped 80-100ms dwell time on quick taps, and spring-up on release.
class AppleBouncy extends StatefulWidget {
  const AppleBouncy({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeOutCubic,
    this.behavior = HitTestBehavior.opaque,
    this.enableHaptics = true,
    this.enabled = true,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.focusBorderRadius,
    this.minDwell = AppMotion.tactileDwell,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final Curve curve;
  final HitTestBehavior behavior;
  final bool enableHaptics;
  final bool enabled;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;
  final BorderRadius? focusBorderRadius;
  final Duration minDwell;

  @override
  State<AppleBouncy> createState() => _AppleBouncyState();
}

class _AppleBouncyState extends State<AppleBouncy> {
  bool _isPressed = false;
  bool _isFocused = false;
  DateTime? _pressStartTime;
  Timer? _dwellTimer;

  bool get _isInteractive => widget.enabled && widget.onTap != null;

  @override
  void dispose() {
    _dwellTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isInteractive) return;
    _dwellTimer?.cancel();
    _pressStartTime = clock.now();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isInteractive) return;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final startTime = _pressStartTime;

    _handleTap();

    if (disableAnimations ||
        startTime == null ||
        widget.minDwell == Duration.zero) {
      if (_isPressed) {
        setState(() => _isPressed = false);
      }
      return;
    }

    final elapsed = clock.now().difference(startTime);
    final remaining = widget.minDwell - elapsed;

    if (remaining > Duration.zero) {
      _dwellTimer = Timer(remaining, () {
        if (mounted) {
          setState(() => _isPressed = false);
        }
      });
    } else {
      if (_isPressed) {
        setState(() => _isPressed = false);
      }
    }
  }

  void _handleTapCancel() {
    _dwellTimer?.cancel();
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
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final effectiveDuration =
        disableAnimations ? Duration.zero : widget.duration;
    final isInteractive = _isInteractive;

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: widget.semanticLabel,
      onTap: isInteractive ? _handleTap : null,
      child: FocusableActionDetector(
        enabled: isInteractive,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onShowFocusHighlight: (focused) {
          if (_isFocused != focused) {
            setState(() => _isFocused = focused);
          }
        },
        onFocusChange: (focused) {
          if (_isFocused != focused) {
            setState(() => _isFocused = focused);
          }
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (isInteractive) {
                _handleTap();
              }
              return null;
            },
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) {
              if (isInteractive) {
                _handleTap();
              }
              return null;
            },
          ),
        },
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.focusBorderRadius ?? BorderRadius.circular(16),
            border: _isFocused
                ? Border.all(color: AppColors.activeBlue, width: 2.0)
                : null,
          ),
          child: GestureDetector(
            onTapDown: isInteractive ? _handleTapDown : null,
            onTapUp: isInteractive ? _handleTapUp : null,
            onTapCancel: isInteractive ? _handleTapCancel : null,
            behavior: widget.behavior,
            child: AnimatedScale(
              scale: _isPressed ? widget.scaleDown : 1.0,
              duration: effectiveDuration,
              curve: widget.curve,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Obsidian card adhering to Apple Human Interface Guidelines standards.
/// Pure matte-obsidian surface with translucent specular border highlights and zero blur overhead.
class AppleGlassCard extends StatelessWidget {
  const AppleGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 18.0,
    this.borderGradient,
    this.borderColor,
    this.backgroundColor,
    this.blurSigma = 25.0,
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
            color: borderColor ?? Colors.white.withValues(alpha: 0.12),
            width: 0.5,
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
        color: backgroundColor ?? AppTheme.cardSurface,
      ),
      child: Padding(
        padding: padding,
        child: child,
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
    this.enabled = true,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
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
  final bool enabled;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

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

    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    return AppleBouncy(
      onTap: onTap,
      enabled: enabled,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      focusBorderRadius: BorderRadius.circular(borderRadius),
      child: content,
    );
  }
}
