import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../theme/app_theme.dart';

/// A normalized data point for [MetabolicSeriesChart].
@immutable
class ChartSeriesPoint {
  const ChartSeriesPoint({
    required this.dateLabel,
    required this.value,
    this.bandLow,
    this.bandHigh,
    this.scatterValue,
  });

  final String dateLabel;
  final double value;
  final double? bandLow;
  final double? bandHigh;
  final double? scatterValue;
}

/// Interactive hardware-accelerated CustomPainter time-series chart with shaded
/// uncertainty/noise envelope, scatter points, dashed target line, and touch scrubbing.
class MetabolicSeriesChart extends StatefulWidget {
  const MetabolicSeriesChart({
    super.key,
    required this.points,
    required this.accentColor,
    required this.unitLabel,
    this.decimals = 0,
    this.targetLineValue,
    this.targetLineLabel,
    this.height = 132,
  });

  final List<ChartSeriesPoint> points;
  final Color accentColor;
  final String unitLabel;
  final int decimals;
  final double? targetLineValue;
  final String? targetLineLabel;
  final double height;

  @override
  State<MetabolicSeriesChart> createState() => _MetabolicSeriesChartState();
}

class _MetabolicSeriesChartState extends State<MetabolicSeriesChart> {
  int _windowDays = 30;
  int? _scrubIndex;

  List<ChartSeriesPoint> get _visiblePoints {
    if (widget.points.length <= _windowDays || _windowDays <= 0) {
      return widget.points;
    }
    return widget.points.sublist(widget.points.length - _windowDays);
  }

  void _updateScrub(Offset localPos, double width, List<ChartSeriesPoint> pts) {
    final count = pts.length;
    if (count < 2 || width <= 0) return;
    final ratio = (localPos.dx / width).clamp(0.0, 1.0);
    final idx = (ratio * (count - 1)).round().clamp(0, count - 1);
    if (idx != _scrubIndex) {
      AppHaptics.selectionClick();
      setState(() => _scrubIndex = idx);
      final p = pts[idx];
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${p.dateLabel}: ${p.value.toStringAsFixed(widget.decimals)} ${widget.unitLabel}',
        TextDirection.ltr,
      );
    }
  }

  (double, double) _computeBounds(List<ChartSeriesPoint> points) {
    double minV = double.infinity;
    double maxV = double.negativeInfinity;

    for (final p in points) {
      minV = math.min(minV, p.bandLow ?? p.value);
      maxV = math.max(maxV, p.bandHigh ?? p.value);
      if (p.scatterValue != null) {
        minV = math.min(minV, p.scatterValue!);
        maxV = math.max(maxV, p.scatterValue!);
      }
    }
    if (widget.targetLineValue != null) {
      minV = math.min(minV, widget.targetLineValue!);
      maxV = math.max(maxV, widget.targetLineValue!);
    }

    if ((maxV - minV).abs() < 1e-3) {
      return (minV - 1.0, maxV + 1.0);
    }
    final pad = (maxV - minV) * 0.12;
    return (minV - pad, maxV + pad);
  }

  @override
  Widget build(BuildContext context) {
    final pts = _visiblePoints;
    if (pts.length < 2) {
      return const SizedBox.shrink();
    }

    final activeIdx = _scrubIndex?.clamp(0, pts.length - 1);
    final scrubbed = activeIdx != null ? pts[activeIdx] : null;
    final (minV, maxV) = _computeBounds(pts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top mini bar: scrubbed readout or time window selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: scrubbed != null
                  ? GestureDetector(
                      onTap: () => setState(() => _scrubIndex = null),
                      child: Text(
                        '${scrubbed.dateLabel}: ${scrubbed.value.toStringAsFixed(widget.decimals)} ${widget.unitLabel}'
                        '${scrubbed.scatterValue != null ? ' (Raw: ${scrubbed.scatterValue!.toStringAsFixed(widget.decimals)})' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.accentColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    )
                  : Text(
                      '${pts.first.dateLabel} — ${pts.last.dateLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final w in const [(30, '30D'), (90, '90D'), (0, 'ALL')])
                  Semantics(
                    button: true,
                    selected: _windowDays == w.$1,
                    label: '${w.$2} time window',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        AppHaptics.selectionClick();
                        setState(() {
                          _windowDays = w.$1;
                          _scrubIndex = null;
                        });
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        child: Center(
                          widthFactor: 1.0,
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _windowDays == w.$1
                                  ? widget.accentColor.withValues(alpha: 0.2)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _windowDays == w.$1
                                    ? widget.accentColor.withValues(alpha: 0.5)
                                    : AppTheme.cardBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              w.$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _windowDays == w.$1
                                    ? widget.accentColor
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) =>
                  _updateScrub(d.localPosition, constraints.maxWidth, pts),
              onHorizontalDragUpdate: (d) =>
                  _updateScrub(d.localPosition, constraints.maxWidth, pts),
              child: RepaintBoundary(
                child: SizedBox(
                  height: widget.height,
                  width: constraints.maxWidth,
                  child: CustomPaint(
                    painter: _SeriesPainter(
                      points: pts,
                      accentColor: widget.accentColor,
                      scrubIndex: activeIdx,
                      targetLineValue: widget.targetLineValue,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Range: ${minV.toStringAsFixed(widget.decimals)}–${maxV.toStringAsFixed(widget.decimals)} ${widget.unitLabel}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (widget.targetLineLabel != null)
              Text(
                widget.targetLineLabel!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SeriesPainter extends CustomPainter {
  const _SeriesPainter({
    required this.points,
    required this.accentColor,
    this.scrubIndex,
    this.targetLineValue,
  });

  final List<ChartSeriesPoint> points;
  final Color accentColor;
  final int? scrubIndex;
  final double? targetLineValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) return;

    const topPad = 8.0;
    const bottomPad = 8.0;
    final chartH = math.max(1.0, size.height - topPad - bottomPad);

    double minV = double.infinity;
    double maxV = double.negativeInfinity;

    for (final p in points) {
      minV = math.min(minV, p.bandLow ?? p.value);
      maxV = math.max(maxV, p.bandHigh ?? p.value);
      if (p.scatterValue != null) {
        minV = math.min(minV, p.scatterValue!);
        maxV = math.max(maxV, p.scatterValue!);
      }
    }
    if (targetLineValue != null) {
      minV = math.min(minV, targetLineValue!);
      maxV = math.max(maxV, targetLineValue!);
    }

    if ((maxV - minV).abs() < 1e-3) {
      minV -= 1.0;
      maxV += 1.0;
    } else {
      final pad = (maxV - minV) * 0.12;
      minV -= pad;
      maxV += pad;
    }

    double xAt(int i) => (i / (points.length - 1)) * size.width;
    double yAt(double v) =>
        topPad + chartH - (((v - minV) / (maxV - minV)) * chartH);

    // 1. Draw target dashed line if inside frame
    if (targetLineValue != null) {
      final ty = yAt(targetLineValue!);
      final dashPaint = Paint()
        ..color = AppTheme.textMuted.withValues(alpha: 0.45)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      const dashW = 5.0;
      const gap = 4.0;
      for (double x = 0; x < size.width; x += dashW + gap) {
        canvas.drawLine(
          Offset(x, ty),
          Offset(math.min(x + dashW, size.width), ty),
          dashPaint,
        );
      }
    }

    // 2. Draw uncertainty / water noise shaded band if present
    final hasBand = points.any((p) => p.bandLow != null && p.bandHigh != null);
    if (hasBand) {
      final bandPath = Path();
      bandPath.moveTo(xAt(0), yAt(points[0].bandHigh ?? points[0].value));
      for (int i = 1; i < points.length; i++) {
        bandPath.lineTo(xAt(i), yAt(points[i].bandHigh ?? points[i].value));
      }
      for (int i = points.length - 1; i >= 0; i--) {
        bandPath.lineTo(xAt(i), yAt(points[i].bandLow ?? points[i].value));
      }
      bandPath.close();

      canvas.drawPath(
        bandPath,
        Paint()
          ..color = accentColor.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );
    }

    // 3. Draw smooth curve + gradient fill under curve
    final linePath = Path();
    final fillPath = Path();
    linePath.moveTo(xAt(0), yAt(points[0].value));
    fillPath.moveTo(xAt(0), size.height);
    fillPath.lineTo(xAt(0), yAt(points[0].value));

    for (int i = 0; i < points.length - 1; i++) {
      final x0 = xAt(i);
      final y0 = yAt(points[i].value);
      final x1 = xAt(i + 1);
      final y1 = yAt(points[i + 1].value);
      final midX = (x0 + x1) / 2;
      linePath.cubicTo(midX, y0, midX, y1, x1, y1);
      fillPath.cubicTo(midX, y0, midX, y1, x1, y1);
    }

    fillPath.lineTo(xAt(points.length - 1), size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withValues(alpha: 0.25),
            accentColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = accentColor
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // 4. Draw raw scale scatter dots
    final dotPaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final s = points[i].scatterValue;
      if (s != null) {
        canvas.drawCircle(Offset(xAt(i), yAt(s)), 2.5, dotPaint);
      }
    }

    // 5. Draw active scrub cursor or latest endpoint indicator
    final highlightIdx = scrubIndex ?? (points.length - 1);
    final hx = xAt(highlightIdx);
    final hy = yAt(points[highlightIdx].value);

    if (scrubIndex != null) {
      canvas.drawLine(
        Offset(hx, 0),
        Offset(hx, size.height),
        Paint()
          ..color = accentColor.withValues(alpha: 0.5)
          ..strokeWidth = 1.0,
      );
    }

    canvas.drawCircle(
      Offset(hx, hy),
      6.0,
      Paint()..color = accentColor.withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      Offset(hx, hy),
      3.4,
      Paint()..color = accentColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SeriesPainter old) =>
      old.points != points ||
      old.accentColor != accentColor ||
      old.scrubIndex != scrubIndex ||
      old.targetLineValue != targetLineValue;
}
