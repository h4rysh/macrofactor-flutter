import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shimmer animation gradient transform that slides smoothly across bounds.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2.0 - 1.0),
      0.0,
      0.0,
    );
  }
}

/// Sweeping gradient shimmer wrapper following Apple Human Interface Guidelines.
/// Automatically freezes into static placeholders when [MediaQuery.disableAnimationsOf] is true.
class AppleSkeletonShimmer extends StatefulWidget {
  const AppleSkeletonShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF16161C),
    this.highlightColor = const Color(0xFF26262E),
    this.duration = AppMotion.shimmer,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  @override
  State<AppleSkeletonShimmer> createState() => _AppleSkeletonShimmerState();
}

class _AppleSkeletonShimmerState extends State<AppleSkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (disableAnimations) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.1, 0.3, 0.5],
              transform:
                  _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Primitive skeleton placeholder block for layout-matching skeleton wireframes.
class AppleSkeletonBox extends StatelessWidget {
  const AppleSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.shape = BoxShape.rectangle,
    this.color,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
        color: color ?? AppTheme.cardElevated,
      ),
    );
  }
}

/// Layout-matching skeleton for the Sique Dashboard screen.
/// Matches MacroGaugeRing (184px circle), quick action strip (3 pills), and metric card modules.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppleSkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header placeholders
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppleSkeletonBox(width: 80, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    AppleSkeletonBox(width: 140, height: 26, borderRadius: 6),
                  ],
                ),
                AppleSkeletonBox(
                  width: 36,
                  height: 36,
                  shape: BoxShape.circle,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Macro Gauge Card Placeholder (184x184 circle, card radius 22.0)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(22.0),
                border: Border.all(color: AppTheme.cardBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  const Center(
                    child: AppleSkeletonBox(
                      width: 184,
                      height: 184,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (_) => const AppleSkeletonBox(
                        width: 80,
                        height: 36,
                        borderRadius: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions Strip Placeholder (3 action pills)
            Row(
              children: List.generate(
                3,
                (_) => const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: AppleSkeletonBox(
                      height: 48,
                      borderRadius: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metric Cards Placeholders (Expenditure & Weight Trend)
            const AppleSkeletonBox(height: 140, borderRadius: 18),
            const SizedBox(height: 14),
            const AppleSkeletonBox(height: 140, borderRadius: 18),
            const SizedBox(height: 14),
            const AppleSkeletonBox(height: 110, borderRadius: 18),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}

/// Layout-matching skeleton for the Sique Food Log screen.
/// Matches DateCarouselRibbon, NutritionSummaryBanner, and Hourly Timeline Slots.
class FoodLogSkeleton extends StatelessWidget {
  const FoodLogSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppleSkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row Placeholder (leading action, date title, view toggle)
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppleSkeletonBox(width: 32, height: 32, borderRadius: 8),
                AppleSkeletonBox(width: 120, height: 22, borderRadius: 6),
                AppleSkeletonBox(width: 32, height: 32, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 12),

            // Date Carousel Placeholder (7 days)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                7,
                (_) => const AppleSkeletonBox(
                  width: 44,
                  height: 58,
                  borderRadius: 16,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Nutrition Summary Banner Placeholder
            const AppleSkeletonBox(height: 52, borderRadius: 14),
            const SizedBox(height: 16),

            // Hourly Timeline Slot Placeholders
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: AppRadii.lgBorderRadius,
                    border: Border.all(color: AppTheme.cardBorder, width: 0.8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppleSkeletonBox(
                              width: 60, height: 16, borderRadius: 4),
                          AppleSkeletonBox(
                              width: 40, height: 16, borderRadius: 4),
                        ],
                      ),
                      SizedBox(height: 10),
                      AppleSkeletonBox(height: 48, borderRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
