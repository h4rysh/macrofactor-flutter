import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sique/data/utils/backup_codec.dart';
import 'package:sique/data/utils/csv_sanitizer.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Screen for exporting user nutrition logs and weight observations to JSON or CSV via Android share sheet.
/// Supports full backup (.sique.json) and restore with schema version validation.
class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  static const int _kMaxPreviewChars = 40 * 1024; // ~40 KB preview limit

  int _foodCatalogCount = 0;
  int _totalFoodLogs = 0;
  int _totalWeightLogs = 0;
  bool _isProcessing = false;

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
    final profile = ref.read(userProfileProvider);
    final foodLogs = db.getAllFoodLogs();
    return BackupCodec.encodeBackup(
      profile: profile,
      foodLogs: foodLogs,
      weightLogs: const [],
    );
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

  String _generateFullBackupJson() {
    final db = ref.read(databaseProvider);
    final profile = ref.read(userProfileProvider);
    final foodLogs = db.getAllFoodLogs();
    final weightLogs = db.getAllWeightLogs();

    return BackupCodec.encodeBackup(
      profile: profile,
      foodLogs: foodLogs,
      weightLogs: weightLogs,
    );
  }

  Future<File?> _saveExportToFile(String filename, String content) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(docsDir.path, 'exports'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final file = File(p.join(exportDir.path, filename));
      await file.writeAsString(content, flush: true);
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

  Future<void> _shareExportFile({
    required String filename,
    required String content,
    required String mimeType,
    required String successMessage,
    required Color color,
  }) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final file = await _saveExportToFile(filename, content);
      if (file != null && mounted) {
        final xFile = XFile(file.path, mimeType: mimeType, name: filename);
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [xFile],
          text: 'Sique Data Export: $filename',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, st) {
      developer.log(
        'Error sharing export file',
        name: 'DataExportScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export file: $e'),
            backgroundColor: AppTheme.calories,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _exportFoodLogs() {
    final jsonStr = _generateFoodLogsJson();
    _shareExportFile(
      filename: 'food_logs_export.json',
      content: jsonStr,
      mimeType: 'application/json',
      successMessage: 'Food logs exported ($_totalFoodLogs entries)',
      color: AppTheme.activeBlue,
    );
  }

  void _exportWeightLogs() {
    final csvStr = _generateWeightLogsCsv();
    _shareExportFile(
      filename: 'weight_logs_export.csv',
      content: csvStr,
      mimeType: 'text/csv',
      successMessage: 'Weight logs exported ($_totalWeightLogs entries)',
      color: AppTheme.trendWeight,
    );
  }

  void _exportFullBackup() {
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final backupJson = _generateFullBackupJson();
    _shareExportFile(
      filename: 'sique_backup_$timestamp.sique.json',
      content: backupJson,
      mimeType: 'application/json',
      successMessage: 'Full backup archive created & shared',
      color: AppTheme.calories,
    );
  }

  Future<void> _restoreFromBackupContent(String jsonContent) async {
    try {
      final decoded = BackupCodec.decodeAndValidate(jsonContent);
      final db = ref.read(databaseProvider);

      if (decoded.profile != null) {
        db.profileDao.saveUserProfile(decoded.profile!);
      }

      for (final w in decoded.weightLogs) {
        final dateStr = w.date.toIso8601String().split('T').first;
        db.weightDao.insertWeightLog(
          dateStr,
          w.weightKg,
          w.note,
          source: w.source,
        );
      }

      for (final f in decoded.foodLogs) {
        db.foodDao.restoreFoodLog(f);
      }

      // Refresh providers
      ref.invalidate(userProfileProvider);
      ref.invalidate(weightLogsProvider);
      ref.invalidate(dailyFoodLogsProvider);
      _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup restored: ${decoded.foodLogs.length} foods, ${decoded.weightLogs.length} weights, profile updated.',
            ),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Restore from backup failed',
        name: 'DataExportScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: AppTheme.calories,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showRestoreDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Row(
          children: [
            Icon(Icons.restore_page_rounded, color: AppTheme.activeBlue),
            SizedBox(width: 8),
            Text('Restore from Backup',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste the raw JSON content of your .sique.json backup archive below. Schema version will be validated prior to restoring.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('restore_backup_json_input'),
                controller: controller,
                maxLines: 6,
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText:
                      '{\n  "app": "Sique",\n  "schemaVersion": 3,\n  ...\n}',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.cardElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('restore_backup_confirm_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.activeBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final text = controller.text.trim();
              Navigator.of(ctx).pop();
              if (text.isNotEmpty) {
                _restoreFromBackupContent(text);
              }
            },
            child: const Text('Validate & Restore'),
          ),
        ],
      ),
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
            onShare: _exportFoodLogs,
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
            onShare: _exportWeightLogs,
            onPreview: () => _showPreviewDialog(
                'Scale Weights CSV Preview', _generateWeightLogsCsv()),
          ),
          const SizedBox(height: 16),
          _buildFullBackupCard(),
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
    required VoidCallback onShare,
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
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withAlpha(40),
                    foregroundColor: color,
                    elevation: 0,
                    side: BorderSide(color: color.withAlpha(90)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullBackupCard() {
    return Container(
      key: const Key('full_backup_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.backup_rounded, size: 22, color: AppTheme.calories),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Backup & Recovery (.sique.json)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Complete schema snapshot (v3)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.calories,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Export or restore an entire snapshot of your profile, nutrition targets, scale weights, and meal entries with cryptographic schema version validation.',
            style: TextStyle(
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
                  key: const Key('restore_from_backup_btn'),
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Restore Backup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showRestoreDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('export_full_backup_btn'),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.calories.withAlpha(40),
                    foregroundColor: AppTheme.calories,
                    elevation: 0,
                    side: BorderSide(color: AppTheme.calories.withAlpha(90)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _exportFullBackup,
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
