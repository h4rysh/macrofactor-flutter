import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/tokens/app_colors.dart';
import 'package:sique/presentation/theme/tokens/app_motion.dart';
import 'package:sique/presentation/theme/tokens/app_radii.dart';

/// Clean obsidian bone shimmer skeleton loader for asynchronous states.
///
/// Sweeps a subtle highlight across obsidian surfaces ([AppColors.cardElevated]
/// to [AppColors.cardBorder]), respecting [MediaQuery.disableAnimationsOf(context)].
class SiqueShimmer extends StatefulWidget {
  const SiqueShimmer({
    super.key,
    this.width,
    this.height = 20,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<SiqueShimmer> createState() => _SiqueShimmerState();
}

class _SiqueShimmerState extends State<SiqueShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.shimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? AppRadii.pillShape;
    final base = widget.baseColor ?? AppColors.cardElevated;
    final highlight = widget.highlightColor ?? AppColors.cardBorder;

    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: effectiveRadius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: effectiveRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0.0,
      0.0,
    );
  }
}
