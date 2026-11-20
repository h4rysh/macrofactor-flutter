import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/tokens/app_haptics.dart';

/// Tactile spring-physics press wrapper for interactive Sique components.
///
/// Features:
/// - 0.982 scale compression on press with damped spring release.
/// - 90ms down duration / 180ms spring release.
/// - Minimum tactile dwell time (80ms) so rapid taps produce visible physical feedback.
/// - Defensive haptic integration via [AppHaptics.lightImpact].
/// - Instant bypass when [MediaQuery.disableAnimationsOf] is true for accessibility.
class SiqueBouncy extends StatefulWidget {
  const SiqueBouncy({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.982,
    this.pressDownDuration = const Duration(milliseconds: 90),
    this.releaseDuration = const Duration(milliseconds: 180),
    this.behavior = HitTestBehavior.opaque,
    this.enableHaptics = true,
    this.enabled = true,
    this.semanticLabel,
    this.minDwell = const Duration(milliseconds: 80),
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration pressDownDuration;
  final Duration releaseDuration;
  final HitTestBehavior behavior;
  final bool enableHaptics;
  final bool enabled;
  final String? semanticLabel;
  final Duration minDwell;

  @override
  State<SiqueBouncy> createState() => _SiqueBouncyState();
}

class _SiqueBouncyState extends State<SiqueBouncy> {
  bool _isPressed = false;
  DateTime? _pressStartTime;
  Timer? _dwellTimer;

  bool get _isInteractive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  @override
  void dispose() {
    _dwellTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_isInteractive) return;
    _dwellTimer?.cancel();
    _pressStartTime = DateTime.now();
    setState(() => _isPressed = true);
    if (widget.enableHaptics) {
      AppHaptics.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_isInteractive) return;
    _releaseWithDwell(widget.onTap);
  }

  void _handleTapCancel() {
    if (!_isInteractive) return;
    _releaseWithDwell(null);
  }

  void _releaseWithDwell(VoidCallback? callback) {
    final startTime = _pressStartTime;
    if (startTime == null) {
      if (mounted) setState(() => _isPressed = false);
      callback?.call();
      return;
    }

    final elapsed = DateTime.now().difference(startTime);
    final remaining = widget.minDwell - elapsed;

    if (remaining > Duration.zero) {
      _dwellTimer = Timer(remaining, () {
        if (!mounted) return;
        setState(() => _isPressed = false);
        callback?.call();
      });
    } else {
      if (mounted) setState(() => _isPressed = false);
      callback?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    Widget content = widget.child;
    if (!disableAnimations) {
      content = AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration:
            _isPressed ? widget.pressDownDuration : widget.releaseDuration,
        curve: _isPressed ? Curves.easeOutQuad : Curves.easeOutBack,
        child: widget.child,
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      button: _isInteractive,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _isInteractive ? _handleTapDown : null,
        onTapUp: _isInteractive ? _handleTapUp : null,
        onTapCancel: _isInteractive ? _handleTapCancel : null,
        onLongPress: _isInteractive && widget.onLongPress != null
            ? () {
                if (widget.enableHaptics) AppHaptics.mediumImpact();
                widget.onLongPress!();
              }
            : null,
        child: content,
      ),
    );
  }
}
