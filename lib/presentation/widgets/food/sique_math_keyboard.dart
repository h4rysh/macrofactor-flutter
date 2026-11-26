import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Safe arithmetic expression evaluator supporting +, -, *, / for inline
/// serving math (e.g., "150*2", "300/3", "100+50").
class SiqueMathEvaluator {
  const SiqueMathEvaluator._();

  static double? evaluate(String raw) {
    final cleaned = raw.replaceAll(' ', '').trim();
    if (cleaned.isEmpty) return null;
    final direct = double.tryParse(cleaned);
    if (direct != null) return direct;
    try {
      final parser = _Parser(cleaned);
      final val = parser.parseExpression();
      if (!parser.isAtEnd || val.isNaN || val.isInfinite) return null;
      return val;
    } catch (_) {
      return null;
    }
  }
}

class _Parser {
  _Parser(this.input);
  final String input;
  int pos = 0;

  bool get isAtEnd => pos >= input.length;

  double parseExpression() {
    var left = parseTerm();
    while (!isAtEnd && (input[pos] == '+' || input[pos] == '-')) {
      final op = input[pos++];
      final right = parseTerm();
      left = op == '+' ? left + right : left - right;
    }
    return left;
  }

  double parseTerm() {
    var left = parseFactor();
    while (!isAtEnd && (input[pos] == '*' || input[pos] == '/')) {
      final op = input[pos++];
      final right = parseFactor();
      if (op == '*') {
        left *= right;
      } else {
        if (right == 0) return double.nan;
        left /= right;
      }
    }
    return left;
  }

  double parseFactor() {
    if (!isAtEnd && input[pos] == '-') {
      pos++;
      return -parseFactor();
    }
    final start = pos;
    while (!isAtEnd &&
        ((input.codeUnitAt(pos) >= 48 && input.codeUnitAt(pos) <= 57) ||
            input[pos] == '.')) {
      pos++;
    }
    if (start == pos) throw const FormatException('Expected number');
    return double.parse(input.substring(start, pos));
  }
}

/// Compact inline math operator bar (+, -, *, /) and unit pills for serving inputs.
class SiqueMathKeyboardBar extends StatelessWidget {
  const SiqueMathKeyboardBar({
    super.key,
    required this.controller,
    required this.onEvaluated,
    this.units = const ['g', 'ml', 'serving', 'cup'],
    this.selectedUnit,
    this.onUnitSelected,
  });

  final TextEditingController controller;
  final ValueChanged<double> onEvaluated;
  final List<String> units;
  final String? selectedUnit;
  final ValueChanged<String>? onUnitSelected;

  void _append(String token) {
    final next = '${controller.text}$token';
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    final val = SiqueMathEvaluator.evaluate(next);
    if (val != null && val > 0) {
      onEvaluated(val);
    }
  }

  void _solve() {
    final val = SiqueMathEvaluator.evaluate(controller.text);
    if (val != null && val > 0) {
      final formatted =
          val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      onEvaluated(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final op in ['+', '-', '*', '/', '='])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(
                  op,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                backgroundColor: op == '='
                    ? AppTheme.activeBlue.withValues(alpha: 0.25)
                    : AppTheme.cardElevated,
                side: const BorderSide(color: AppTheme.cardBorder),
                onPressed: () => op == '=' ? _solve() : _append(op),
              ),
            ),
          if (onUnitSelected != null)
            for (final u in units)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(u, style: const TextStyle(fontSize: 11)),
                  selected: selectedUnit == u,
                  onSelected: (_) => onUnitSelected!(u),
                ),
              ),
        ],
      ),
    );
  }
}
