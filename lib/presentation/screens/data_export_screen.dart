import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sique/data/utils/csv_sanitizer.dart';
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
  // Safe payload threshold to prevent Android Binder TransactionTooLargeException crashes (ISS-6-02)
  static const int _kMaxBinderPayloadChars = 200 * 1024; // ~200 KB safe limit
  static const int _kMaxPreviewChars = 40 * 1024; // ~40 KB preview limit

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
      final safeDate =
          CsvSanitizer.sanitize(entry.date.toIso8601String().split('T').first);
      final safeWeight = entry.weightKg.toString();
      final safeNote = CsvSanitizer.sanitize(entry.note ?? '');
      buffer.writeln('$safeDate,$safeWeight,$safeNote');
    }
    return buffer.toString();
  }

  /// Exports large string content to local storage in chunks to prevent memory/binder issues (ISS-6-02).
  Future<File?> _saveExportToFile(String filename, String content) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(docsDir.path, 'exports'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final file = File(p.join(exportDir.path, filename));
      final sink = file.openWrite();

      // Chunked stream write
      const chunkSize = 16 * 1024;
      for (var i = 0; i < content.length; i += chunkSize) {
        final end =
            (i + chunkSize < content.length) ? i + chunkSize : content.length;
        sink.write(content.substring(i, end));
      }
      await sink.flush();
      await sink.close();
      return file;
    } catch (e, st) {
      developer.log(
        'Failed to save export to file',
        name: 'DataExportScreen',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Copies text to system clipboard with binder-safe chunking and fallback to file (ISS-6-02).
  Future<void> _safeCopyToClipboard({
    required String content,
    required String successMessage,
    required Color color,
    required String filename,
  }) async {
    try {
      if (content.length > _kMaxBinderPayloadChars) {
        // Prevent Android TransactionTooLargeException: write full export to file first
        final savedFile = await _saveExportToFile(filename, content);
        final safeChunk = content.substring(0, _kMaxBinderPayloadChars);

        await Clipboard.setData(ClipboardData(text: safeChunk));

        if (mounted) {
          final locationInfo =
              savedFile != null ? 'Full file saved to ${savedFile.path}. ' : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Large payload chunked. ${locationInfo}First chunk copied to clipboard.',
              ),
              backgroundColor: color,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        await Clipboard.setData(ClipboardData(text: content));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: color,
            ),
          );
        }
      }
    } on PlatformException catch (e, st) {
      developer.log(
        'PlatformException during clipboard setData; attempting file fallback',
        name: 'DataExportScreen',
        error: e,
        stackTrace: st,
      );
      final savedFile = await _saveExportToFile(filename, content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedFile != null
                  ? 'Clipboard unavailable. Saved to ${savedFile.path}'
                  : 'Clipboard transaction exceeded platform limits.',
            ),
            backgroundColor: AppTheme.calories,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: AppTheme.calories,
          ),
        );
      }
    }
  }

  void _copyFoodLogs() {
    final jsonStr = _generateFoodLogsJson();
    _safeCopyToClipboard(
      content: jsonStr,
      successMessage: 'Food logs copied to clipboard ($_totalFoodLogs entries)',
      color: AppTheme.activeBlue,
      filename: 'food_logs_export.json',
    );
  }

  void _copyWeightLogs() {
    final csvStr = _generateWeightLogsCsv();
    _safeCopyToClipboard(
      content: csvStr,
      successMessage:
          'Weight logs copied to clipboard ($_totalWeightLogs entries)',
      color: AppTheme.trendWeight,
      filename: 'weight_logs_export.csv',
    );
  }

  void _showPreviewDialog(String title, String content) {
    final isTruncated = content.length > _kMaxPreviewChars;
    final displayContent = isTruncated
        ? '${content.substring(0, _kMaxPreviewChars)}\n\n--- [Preview truncated for performance. Full content: ${content.length} characters] ---'
        : (content.isEmpty ? 'No entries found.' : content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SingleChildScrollView(
            child: Text(
              displayContent,
              style: const TextStyle(
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
              Navigator.of(ctx).pop();
              _safeCopyToClipboard(
                content: content,
                successMessage: 'Copied to clipboard',
                color: AppTheme.activeBlue,
                filename: 'preview_export.txt',
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
          tooltip: 'Back',
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
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      countLabel,
                      style: TextStyle(
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
