import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Screen for exporting user nutrition logs and weight observations to JSON or CSV.
/// Shows database statistics and reinforces local-only data privacy.
class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  int _foodCatalogCount = 0;
  int _totalFoodLogs = 0;
  int _totalWeightLogs = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final db = ref.read(databaseProvider);
    final foodCount = db.getFoodCount();
    final foodLogs = db.getAllFoodLogs();
    final weightLogs = db.getAllWeightLogs();

    setState(() {
      _foodCatalogCount = foodCount;
      _totalFoodLogs = foodLogs.length;
      _totalWeightLogs = weightLogs.length;
    });
  }

  String _generateFoodLogsJson() {
    final db = ref.read(databaseProvider);
    final logs = db.getAllFoodLogs();
    final list = logs.map((e) {
      return {
        'id': e.id,
        'date': e.date,
        'mealType': e.mealType.name,
        'foodId': e.foodId,
        'foodName': e.foodName,
        'servingQuantity': e.servingQuantity,
        'unitName': e.unitName,
        'gramWeight': e.gramWeight,
        'calories': e.calories,
        'protein': e.protein,
        'carbs': e.carbs,
        'fat': e.fat,
        'fiber': e.fiber,
        'oilModifier': e.oilModifier.displayName,
        'loggedAt': e.loggedAt.toIso8601String(),
      };
    }).toList();

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'exportDate': DateTime.now().toIso8601String(),
      'app': 'Sique',
      'totalEntries': list.length,
      'entries': list,
    });
  }

  String _generateWeightLogsCsv() {
    final db = ref.read(databaseProvider);
    final logs = db.getAllWeightLogs();
    final buffer = StringBuffer();
    buffer.writeln('Date,Weight_kg,Notes');
    for (final entry in logs) {
      final safeNote = (entry.note ?? '').replaceAll('"', '""');
      buffer.writeln('${entry.date},${entry.weightKg},"$safeNote"');
    }
    return buffer.toString();
  }

  void _copyFoodLogs() {
    final jsonStr = _generateFoodLogsJson();
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Food logs copied to clipboard ($_totalFoodLogs entries)'),
        backgroundColor: AppTheme.activeBlue,
      ),
    );
  }

  void _copyWeightLogs() {
    final csvStr = _generateWeightLogsCsv();
    Clipboard.setData(ClipboardData(text: csvStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Weight logs copied to clipboard ($_totalWeightLogs entries)'),
        backgroundColor: AppTheme.trendWeight,
      ),
    );
  }

  void _showPreviewDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'MacroSans', color: AppTheme.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SingleChildScrollView(
            child: Text(
              content.isEmpty ? 'No entries found.' : content,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  backgroundColor: AppTheme.activeBlue,
                ),
              );
            },
            child: const Text('Copy All',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.activeBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Data & Export'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildStorageOverviewCard(),
          const SizedBox(height: 16),
          _buildExportTile(
            icon: Icons.data_object_rounded,
            color: AppTheme.activeBlue,
            title: 'Export Food Logs (JSON)',
            subtitle:
                'Complete nutritional history formatted with ISO timestamps, portion weights, and oil modifiers.',
            countLabel: '$_totalFoodLogs meals logged',
            onCopy: _copyFoodLogs,
            onPreview: () => _showPreviewDialog(
                'Food Logs Preview', _generateFoodLogsJson()),
          ),
          const SizedBox(height: 16),
          _buildExportTile(
            icon: Icons.table_chart_rounded,
            color: AppTheme.trendWeight,
            title: 'Export Scale Weights (CSV)',
            subtitle:
                'Chronological weigh-ins compatible with Excel, Google Sheets, or custom statistical models.',
            countLabel: '$_totalWeightLogs weigh-ins logged',
            onCopy: _copyWeightLogs,
            onPreview: () => _showPreviewDialog(
                'Scale Weights CSV Preview', _generateWeightLogsCsv()),
          ),
          const SizedBox(height: 16),
          _buildPrivacyCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStorageOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Local Storage Diagnostics',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Catalog Foods',
                  value: _foodCatalogCount > 0
                      ? _foodCatalogCount.toString()
                      : '2,500+',
                  color: AppTheme.expenditure,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Food Logs',
                  value: _totalFoodLogs.toString(),
                  color: AppTheme.calories,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Weight Logs',
                  value: _totalWeightLogs.toString(),
                  color: AppTheme.trendWeight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExportTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String countLabel,
    required VoidCallback onCopy,
    required VoidCallback onPreview,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      countLabel,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.preview_rounded, size: 16),
                  label: const Text('Preview'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onPreview,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy to Clipboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withAlpha(40),
                    foregroundColor: color,
                    elevation: 0,
                    side: BorderSide(color: color.withAlpha(90)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onCopy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 22, color: AppTheme.expenditure),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Zero Tracking • Local-First Architecture\nYour health and nutrition data never leaves your device. All calculations, database tables, and algorithm filters operate 100% offline via local SQLite.',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
