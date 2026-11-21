import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders a food title with matching substring highlights.
class FoodSearchHighlight extends StatelessWidget {
  const FoodSearchHighlight({
    super.key,
    required this.name,
    required this.query,
  });

  final String name;
  final String query;

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();
    if (trimmed.isEmpty ||
        !name.toLowerCase().contains(trimmed.toLowerCase())) {
      return Text(
        name,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      );
    }

    final lowerName = name.toLowerCase();
    final lowerQuery = trimmed.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    const baseStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary,
    );
    const matchStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w900,
      color: AppTheme.buttonBackground,
      backgroundColor: Color(0x33FAFAFA),
    );

    while (start < name.length) {
      final index = lowerName.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: name.substring(start), style: baseStyle));
        break;
      }
      if (index > start) {
        spans.add(
            TextSpan(text: name.substring(start, index), style: baseStyle));
      }
      spans.add(TextSpan(
        text: name.substring(index, index + lowerQuery.length),
        style: matchStyle,
      ));
      start = index + lowerQuery.length;
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
