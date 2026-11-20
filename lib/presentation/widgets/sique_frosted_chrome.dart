import 'dart:ui';
import 'package:flutter/material.dart';

/// Fixed floating frosted chrome container for the Sique Design System.
///
/// Designed strictly for pinned, top-level chrome (e.g. sticky bottom CTA bars,
/// persistent top app bars, floating navigation docks).
///
/// Architecture Rule: NEVER nest [SiqueFrostedChrome] inside scrolling list items,
/// as rasterizing realtime Gaussian blurs across 60-120Hz scrolling leads to frame drops.
class SiqueFrostedChrome extends StatelessWidget {
  const SiqueFrostedChrome({
    super.key,
    required this.child,
    this.sigmaX = 18.0,
    this.sigmaY = 18.0,
    this.backgroundColor = const Color(0xCC09090B),
    this.borderColor = const Color(0x1AFFFFFF),
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.showTopBorder = true,
    this.showBottomBorder = false,
    this.borderRadius,
  });

  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final bool showTopBorder;
  final bool showBottomBorder;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.zero;

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: effectiveRadius,
            border: Border(
              top: showTopBorder
                  ? BorderSide(color: borderColor, width: 1.0)
                  : BorderSide.none,
              bottom: showBottomBorder
                  ? BorderSide(color: borderColor, width: 1.0)
                  : BorderSide.none,
            ),
          ),
          child: SafeArea(
            top: false,
            child: child,
          ),
        ),
      ),
    );
  }
}
