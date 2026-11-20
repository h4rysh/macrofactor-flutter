import 'package:flutter/material.dart';

/// Reusable Apple Human Interface Guidelines drag-to-dismiss sheet grabber pill.
///
/// Implements Apple's standardized 36x5 pt grabber with 2.5 pt corner radii,
/// subtle 30% white specular luminosity, and accessible semantics.
class AppleSheetGrabber extends StatelessWidget {
  const AppleSheetGrabber({
    super.key,
    this.width = 36.0,
    this.height = 5.0,
    this.color,
    this.margin = const EdgeInsets.only(top: 8.0, bottom: 12.0),
  });

  /// Horizontal pill length (default 36 pt).
  final double width;

  /// Vertical pill thickness (default 5 pt).
  final double height;

  /// Specular pill tint (defaults to 30% translucent white).
  final Color? color;

  /// External spacing framing the pill inside modal headers.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Drag handle to dismiss modal sheet',
      container: true,
      child: Center(
        child: Container(
          margin: margin,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color ?? const Color(0x4DFFFFFF),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
