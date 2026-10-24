import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Interactive portion & serving selector with both direct numeric input
/// and incremental stepper buttons.
class PortionSelectorDialog extends StatefulWidget {
  const PortionSelectorDialog({
    super.key,
    required this.initialQuantity,
    required this.portionUnits,
    required this.initialUnit,
    required this.onConfirmed,
  });

  final double initialQuantity;
  final List<PortionUnit> portionUnits;
  final PortionUnit initialUnit;
  final void Function(double quantity, PortionUnit unit) onConfirmed;

  static Future<void> show({
    required BuildContext context,
    required double initialQuantity,
    required List<PortionUnit> portionUnits,
    required PortionUnit initialUnit,
    required void Function(double quantity, PortionUnit unit) onConfirmed,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PortionSelectorDialog(
        initialQuantity: initialQuantity,
        portionUnits: portionUnits,
        initialUnit: initialUnit,
        onConfirmed: onConfirmed,
      ),
    );
  }

  @override
  State<PortionSelectorDialog> createState() => _PortionSelectorDialogState();
}

class _PortionSelectorDialogState extends State<PortionSelectorDialog> {
  late double _quantity;
  late PortionUnit _selectedUnit;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity > 0 ? widget.initialQuantity : 1.0;
    _selectedUnit = widget.initialUnit;
    _controller = TextEditingController(
      text: _formatQuantity(_quantity),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        final parsed = double.tryParse(_controller.text);
        if (parsed == null || parsed <= 0) {
          _controller.text = _formatQuantity(_quantity);
        } else {
          _quantity = parsed;
          _controller.text = _formatQuantity(_quantity);
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _formatQuantity(double q) {
    return q.truncateToDouble() == q ? q.toInt().toString() : q.toString();
  }

  void _updateQuantity(double newQ) {
    if (newQ > 0) {
      setState(() {
        _quantity = (newQ * 100).roundToDouble() / 100.0;
        _controller.text = _formatQuantity(_quantity);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      title: const Text(
        'Serving Size',
        style: TextStyle(
          fontFamily: 'MacroSans',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portion unit dropdown / selector
            if (widget.portionUnits.isNotEmpty) ...[
              const Text(
                'UNIT',
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PortionUnit>(
                    value: _selectedUnit,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardElevated,
                    items: widget.portionUnits.map((u) {
                      return DropdownMenuItem<PortionUnit>(
                        value: u,
                        child: Text(
                          '${u.unitName} (${u.gramWeight.toStringAsFixed(0)}g)',
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedUnit = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'QUANTITY',
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),

            // Stepper and numeric text input row
            Row(
              children: [
                // Stepper Decrement
                IconButton.filledTonal(
                  key: const Key('portion_decrement_btn'),
                  onPressed: () {
                    final current =
                        double.tryParse(_controller.text) ?? _quantity;
                    if (current > 0.5) {
                      _updateQuantity(current - 0.5);
                    }
                  },
                  icon: const Icon(Icons.remove, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.cardElevated,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),

                // Direct numeric input field (validated > 0)
                Expanded(
                  child: TextFormField(
                    key: const Key('portion_numeric_field'),
                    focusNode: _focusNode,
                    controller: _controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      filled: true,
                      fillColor: AppTheme.cardElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.activeBlue, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        _quantity = parsed;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Stepper Increment
                IconButton.filledTonal(
                  key: const Key('portion_increment_btn'),
                  onPressed: () {
                    final current =
                        double.tryParse(_controller.text) ?? _quantity;
                    _updateQuantity(current + 0.5);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.cardElevated,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'DMSans',
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          key: const Key('portion_confirm_btn'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.activeBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final val = double.parse(_controller.text);
              widget.onConfirmed(val, _selectedUnit);
              Navigator.pop(context);
            }
          },
          child: const Text(
            'Set Portion',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
