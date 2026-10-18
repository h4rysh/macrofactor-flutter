import 'package:flutter/material.dart';
export 'apple_tactile_card.dart';

/// Silky-smooth numeric count-up / count-down odometer text.
/// Interpolates numbers with [Curves.easeOutCubic] so changes feel organic.
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    this.formatter,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.easeOutCubic,
  });

  final double value;
  final String Function(double)? formatter;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        final formatted = formatter != null
            ? formatter!(animatedValue)
            : animatedValue.round().toString();
        return Text(
          '$prefix$formatted$suffix',
          style: style,
        );
      },
    );
  }
}

/// Staggered entrance animation inspired by Apple iOS sheet and card reveals.
/// Elements smoothly fade in and slide up with [Curves.easeOutCubic].
class AppleStaggeredEntrance extends StatefulWidget {
  const AppleStaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.interval = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 450),
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
  State<AppleStaggeredEntrance> createState() => _AppleStaggeredEntranceState();
}

class _AppleStaggeredEntranceState extends State<AppleStaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      _controller.forward();
    } else {
      Future.delayed(totalDelay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeOutCubic,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final targetWidth = (maxWidth * ratio.clamp(0.0, 1.0));

        return Container(
          height: height,
          width: maxWidth,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: targetWidth),
            duration: duration,
            curve: curve,
            builder: (context, animatedWidth, child) {
              return Container(
                height: height,
                width: animatedWidth,
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
            },
          ),
        );
      },
    );
  }
}
