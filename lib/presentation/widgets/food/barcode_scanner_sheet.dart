import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/recipe_models.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/providers/plate_staging_provider.dart';
import 'package:sique/presentation/providers/recipes_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_sheet_grabber.dart';
import 'package:sique/presentation/widgets/food/nutrition_label_ocr_sheet.dart';

/// Offline-first Barcode Scanner modal sheet using `mobile_scanner` + local
/// SQLite `barcode_cache` + lazy OpenFoodFacts fallback + manual code input.
class BarcodeScannerSheet extends ConsumerStatefulWidget {
  const BarcodeScannerSheet({
    super.key,
    required this.mealType,
    required this.loggedAt,
    this.stageMode = false,
  });

  final MealType mealType;
  final DateTime loggedAt;
  final bool stageMode;

  static Future<void> show(
    BuildContext context, {
    required MealType mealType,
    required DateTime loggedAt,
    bool stageMode = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerSheet(
        mealType: mealType,
        loggedAt: loggedAt,
        stageMode: stageMode,
      ),
    );
  }

  @override
  ConsumerState<BarcodeScannerSheet> createState() =>
      _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends ConsumerState<BarcodeScannerSheet> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _manualCodeCtrl = TextEditingController();

  bool _isLookingUp = false;
  bool _torchOn = false;
  String? _lastScannedCode;
  BarcodeFoodProduct? _resolvedProduct;
  String? _statusMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || _isLookingUp || code == _lastScannedCode) return;

    setState(() {
      _lastScannedCode = code;
      _isLookingUp = true;
      _statusMessage = null;
      _resolvedProduct = null;
    });

    try {
      final product =
          await ref.read(openFoodFactsServiceProvider).lookupBarcode(code);
      if (!mounted) return;

      setState(() {
        _isLookingUp = false;
        _resolvedProduct = product;
        if (product == null) {
          _statusMessage =
              'Barcode "$code" not found offline or in OpenFoodFacts.';
        } else {
          AppHaptics.successFeedback();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _statusMessage =
            'Unable to reach OpenFoodFacts. Try scanning a nutrition label instead.';
      });
    }
  }

  void _logProduct(BarcodeFoodProduct product, {required bool stageOnly}) {
    final foodItem = product.toFoodItem();
    final defaultUnit = foodItem.defaultPortionUnit;
    if (stageOnly) {
      ref.read(plateStagingProvider.notifier).addItem(
            foodItem,
            unit: defaultUnit,
          );
      AppHaptics.mediumImpact();
      Navigator.of(context).pop();
      return;
    }

    ref.read(dailyFoodLogsProvider.notifier).addEntry(
          food: foodItem,
          portionUnit: defaultUnit,
          quantity: 1.0,
          mealType: widget.mealType,
          oilModifier: OilModifier.standard,
          loggedAt: widget.loggedAt,
        );
    AppHaptics.successFeedback();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppleSheetGrabber(margin: EdgeInsets.only(bottom: 10)),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Scan Packaged Food',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _torchOn ? 'Turn off flash' : 'Turn on flash',
                      icon: Icon(
                        _torchOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color:
                            _torchOn ? AppTheme.carbs : AppTheme.textSecondary,
                      ),
                      onPressed: () async {
                        if (!_scannerController.value.isRunning) return;
                        try {
                          await _scannerController.toggleTorch();
                          if (mounted) {
                            setState(() => _torchOn = !_torchOn);
                          }
                        } catch (_) {
                          // Safe no-op if device camera lacks torch or failed initialization
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Close scanner',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: AppRadii.lgBorderRadius,
                  child: SizedBox(
                    height: 185,
                    width: double.infinity,
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) {
                        for (final barcode in capture.barcodes) {
                          final raw = barcode.rawValue;
                          if (raw != null && raw.trim().isNotEmpty) {
                            _handleBarcode(raw);
                            break;
                          }
                        }
                      },
                      errorBuilder: (context, error) => Container(
                        color: AppTheme.surface,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Camera unavailable (${error.errorCode.name}). Enter barcode manually below.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualCodeCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Or type EAN / UPC (e.g. 8901262010016)',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                          filled: true,
                          fillColor: AppTheme.surface,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.mdBorderRadius,
                            borderSide: BorderSide(
                              color: AppTheme.cardBorder,
                            ),
                          ),
                        ),
                        onSubmitted: _handleBarcode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _lastScannedCode = null;
                        _handleBarcode(_manualCodeCtrl.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.activeBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Lookup'),
                    ),
                  ],
                ),
                if (_isLookingUp) ...[
                  const SizedBox(height: 14),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_statusMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.calories,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    NutritionLabelOcrSheet.show(
                      context,
                      barcode: _manualCodeCtrl.text.trim(),
                      onParsed: (product) {
                        ref
                            .read(databaseProvider)
                            .barcodeDao
                            .upsertProduct(product);
                        setState(() {
                          _resolvedProduct = product;
                          _statusMessage =
                              'Parsed via Label OCR & saved locally';
                        });
                      },
                    );
                  },
                  icon: const Icon(Icons.document_scanner_outlined, size: 18),
                  label: const Text('Scan / Paste Nutrition Label (OCR)'),
                ),
                if (_resolvedProduct != null) ...[
                  const SizedBox(height: 12),
                  _ResolvedProductCard(
                    product: _resolvedProduct!,
                    stageMode: widget.stageMode,
                    onStage: () =>
                        _logProduct(_resolvedProduct!, stageOnly: true),
                    onLog: () =>
                        _logProduct(_resolvedProduct!, stageOnly: false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolvedProductCard extends StatelessWidget {
  const _ResolvedProductCard({
    required this.product,
    required this.stageMode,
    required this.onStage,
    required this.onLog,
  });

  final BarcodeFoodProduct product;
  final bool stageMode;
  final VoidCallback onStage;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final food = product.toFoodItem();
    final nutrition = food.calculateNutrition(
      quantity: 1.0,
      unit: food.defaultPortionUnit,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppRadii.lgBorderRadius,
        border: Border.all(color: AppTheme.activeBlue.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.displayTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1 Serving (${product.servingSizeG.toStringAsFixed(0)}g) · ${nutrition.calories.round()} kcal · ${nutrition.protein.toStringAsFixed(1)}P / ${nutrition.carbs.toStringAsFixed(1)}C / ${nutrition.fat.toStringAsFixed(1)}F',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onStage,
                  child: const Text('Add to Plate'),
                ),
              ),
              if (!stageMode) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonBackground,
                      foregroundColor: AppTheme.buttonText,
                    ),
                    child: const Text('Log Now'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
