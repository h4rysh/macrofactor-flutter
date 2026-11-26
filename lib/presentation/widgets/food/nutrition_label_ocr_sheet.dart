import 'package:flutter/material.dart';
import 'package:sique/domain/models/recipe_models.dart';
import 'package:sique/domain/services/nutrition_label_ocr_parser.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Bottom sheet allowing users to parse FSSAI/FDA nutrition labels offline
/// when a barcode is missing from OpenFoodFacts or local cache.
class NutritionLabelOcrSheet extends StatefulWidget {
  const NutritionLabelOcrSheet({
    super.key,
    required this.barcode,
    required this.onParsed,
  });

  final String barcode;
  final ValueChanged<BarcodeFoodProduct> onParsed;

  static Future<void> show(
    BuildContext context, {
    required String barcode,
    required ValueChanged<BarcodeFoodProduct> onParsed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          NutritionLabelOcrSheet(barcode: barcode, onParsed: onParsed),
    );
  }

  @override
  State<NutritionLabelOcrSheet> createState() => _NutritionLabelOcrSheetState();
}

class _NutritionLabelOcrSheetState extends State<NutritionLabelOcrSheet> {
  final _nameCtrl = TextEditingController();
  final _rawCtrl = TextEditingController();
  ParsedNutritionLabel? _preview;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rawCtrl.dispose();
    super.dispose();
  }

  void _parse() {
    final name = _nameCtrl.text.trim().isEmpty
        ? 'Packaged Item (${widget.barcode})'
        : _nameCtrl.text.trim();
    setState(() {
      _preview = NutritionLabelOcrParser.parse(
        _rawCtrl.text,
        fallbackName: name,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nutrition Label Parser (FSSAI / FDA)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Product Name'),
            onChanged: (_) => _parse(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rawCtrl,
            maxLines: 4,
            maxLength: 4000,
            decoration: const InputDecoration(
              labelText: 'Paste or type label text',
              hintText:
                  'e.g. Per 100g: Energy 380 kcal, Protein 24g, Carbohydrate 42g, Total Fat 11g, Fiber 6g',
            ),
            onChanged: (_) => _parse(),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cardElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Per 100g: ${_preview!.caloriesPer100g.round()} kcal · ${_preview!.proteinPer100g.toStringAsFixed(1)}g P · ${_preview!.carbsPer100g.toStringAsFixed(1)}g C · ${_preview!.fatPer100g.toStringAsFixed(1)}g F',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.activeBlue,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _preview == null
                ? null
                : () {
                    final code = widget.barcode.isEmpty
                        ? 'ocr_${DateTime.now().millisecondsSinceEpoch}'
                        : widget.barcode;
                    widget.onParsed(_preview!.toBarcodeProduct(code));
                    Navigator.of(context).pop();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.activeBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text('Save & Log Product'),
          ),
        ],
      ),
    );
  }
}
