import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/tokens/app_motion.dart';
import 'package:sique/presentation/theme/tokens/app_typography.dart';
export 'apple_tactile_card.dart';

/// Silky-smooth numeric count-up / count-down odometer text.
/// Interpolates numbers with [Curves.easeOutCubic] so changes feel organic.
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    this.initialValue = 0.0,
    this.formatter,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = AppMotion.countUp,
    this.curve = AppMotion.decelerated,
  });

  final double value;
  final double initialValue;
  final String Function(double)? formatter;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = AppTypography.withTabularFigures(
      style ?? DefaultTextStyle.of(context).style,
    );
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (disableAnimations) {
      final formatted =
          formatter != null ? formatter!(value) : value.round().toString();
      return Text(
        '$prefix$formatted$suffix',
        style: effectiveStyle,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: initialValue, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        final formatted = formatter != null
            ? formatter!(animatedValue)
            : animatedValue.round().toString();
        return Text(
          '$prefix$formatted$suffix',
          style: effectiveStyle,
        );
      },
    );
  }
}

/// Staggered entrance animation inspired by Apple iOS sheet and card reveals.
/// Elements smoothly fade in and slide up with [Curves.easeOutCubic].
/// Includes single-play guard and keep-alive to prevent unwanted replay during scrolling.
class AppleStaggeredEntrance extends StatefulWidget {
  const AppleStaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.interval = const Duration(milliseconds: 50),
    this.duration = AppMotion.slow,
    this.curve = AppMotion.decelerated,
    this.offsetY = 16.0,
  });

  final Widget child;
  final int index;
  final Duration interval;
  final Duration duration;
  final Curve curve;
  final double offsetY;

  @override
  State<AppleStaggeredEntrance> createState() => _AppleStaggeredEntranceState();
}

class _AppleStaggeredEntranceState extends State<AppleStaggeredEntrance>
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
    ).animate(_fadeAnimation);

    final totalDelay = widget.interval * widget.index;
    if (totalDelay == Duration.zero) {
      _hasPlayed = true;
      _controller.forward();
    } else {
      _delayTimer = Timer(totalDelay, () {
        if (mounted && !_hasPlayed && !_controller.isCompleted) {
          _hasPlayed = true;
          _controller.forward();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _delayTimer?.cancel();
      _hasPlayed = true;
      _controller.value = 1.0;
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
    if (disableAnimations) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
    );
  }
}

/// Animated linear macro progress bar with glowing gradient fill and smooth tweens.
class AnimatedMacroBar extends StatelessWidget {
  const AnimatedMacroBar({
    super.key,
    required this.ratio,
    required this.color,
    this.height = 6.0,
    this.backgroundColor,
    this.duration = AppMotion.macroBar,
    this.curve = AppMotion.decelerated,
  });

  final double ratio;
  final Color color;
  final double height;
  final Color? backgroundColor;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? const Color(0xFF282834);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final targetWidth = (maxWidth * ratio.clamp(0.0, 1.0));

        Widget buildBar(double width) {
          return Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.8),
                  color,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          );
        }

        return Container(
          height: height,
          width: maxWidth,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          alignment: Alignment.centerLeft,
          child: disableAnimations
              ? buildBar(targetWidth)
              : TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: targetWidth),
                  duration: duration,
                  curve: curve,
                  builder: (context, animatedWidth, child) {
                    return buildBar(animatedWidth);
                  },
                ),
        );
      },
    );
  }
}
