import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/tokens/app_motion.dart';

/// Staggered entrance animation for cards, list items, and modal reveals.
///
/// Features:
/// - Smooth fade and slide up with [Curves.easeOutCubic].
/// - Index-based delay stagger (default 40ms interval).
/// - Single-play guard and keep-alive so scrolling does not re-trigger jarring replays.
/// - Respects [MediaQuery.disableAnimationsOf(context)] for accessibility.
class SiqueEntrance extends StatefulWidget {
  const SiqueEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.interval = const Duration(milliseconds: 40),
    this.duration = AppMotion.slow,
    this.curve = Curves.easeOutCubic,
    this.offsetY = 16.0,
  });

  final Widget child;
  final int index;
  final Duration interval;
  final Duration duration;
  final Curve curve;
  final double offsetY;

  @override
  State<SiqueEntrance> createState() => _SiqueEntranceState();
}

class _SiqueEntranceState extends State<SiqueEntrance>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _delayTimer;
  bool _hasPlayed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    final delay = widget.interval * widget.index;
    if (delay == Duration.zero) {
      _controller.forward();
      _hasPlayed = true;
    } else {
      _delayTimer = Timer(delay, () {
        if (mounted) {
          _controller.forward();
          _hasPlayed = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (disableAnimations || _hasPlayed && _controller.isCompleted) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) => Transform.translate(
          offset: _slideAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
