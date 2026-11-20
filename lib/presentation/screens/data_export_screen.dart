import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sique/data/local/app_database_coaching.dart';
import 'package:sique/data/utils/backup_codec.dart';
import 'package:sique/data/utils/csv_sanitizer.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/export_card_tile.dart';

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
    final workoutSessions = db.getAllWorkoutSessions();
    final expenditureHistory = db.expenditureDao.getExpenditureHistory();
    final coachingCheckIns = db.getCoachingCheckIns();
    final dayCompletions = db.expenditureDao.getDayCompletions();
    final appSettings = db.getAllSettings();

    return BackupCodec.encodeBackup(
      profile: profile,
      foodLogs: foodLogs,
      weightLogs: weightLogs,
      workoutSessions: workoutSessions,
      expenditureHistory: expenditureHistory,
      coachingCheckIns: coachingCheckIns,
      dayCompletions: dayCompletions,
      appSettings: appSettings,
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

      if (decoded.workoutSessions.isNotEmpty) {
        db.insertWorkoutSessions(decoded.workoutSessions);
      }

      if (decoded.expenditureHistory.isNotEmpty) {
        db.expenditureDao.saveExpenditures(decoded.expenditureHistory);
      }

      for (final c in decoded.coachingCheckIns) {
        db.insertCoachingCheckIn(c);
      }

      decoded.dayCompletions.forEach((date, isComplete) {
        db.expenditureDao.setDayComplete(date, isComplete);
      });

      decoded.appSettings.forEach((k, v) {
        db.setSetting(k, v);
      });

      // Refresh providers
      ref.read(userDataEpochProvider.notifier).state++;
      ref.invalidate(userProfileProvider);
      ref.invalidate(weightLogsProvider);
      ref.invalidate(dailyFoodLogsProvider);
      ref.invalidate(dayCompletionsProvider);
      ref.invalidate(workoutSessionsProvider);
      _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup restored: ${decoded.foodLogs.length} foods, ${decoded.weightLogs.length} weights, ${decoded.workoutSessions.length} workouts, profile updated.',
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

  Future<void> _pickAndRestoreFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final content = await file.readAsString();
        await _restoreFromBackupContent(content);
      }
    } catch (e, st) {
      developer.log('File pick error', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read file: $e'),
            backgroundColor: AppTheme.calories,
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  key: const Key('choose_backup_file_btn'),
                  icon: const Icon(Icons.file_open_rounded, size: 18),
                  label: const Text('Choose .sique.json File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.activeBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _pickAndRestoreFile();
                  },
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.cardBorder)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('OR PASTE JSON',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted)),
                    ),
                    Expanded(child: Divider(color: AppTheme.cardBorder)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('restore_backup_json_input'),
                  controller: controller,
                  maxLines: 5,
                  style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText:
                        '{\n  "app": "Sique",\n  "schemaVersion": 4,\n  ...\n}',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('restore_backup_confirm_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.activeBlue.withValues(alpha: 0.2),
              foregroundColor: AppTheme.activeBlue,
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
          ExportCardTile(
            icon: Icons.data_object_rounded,
            color: AppTheme.activeBlue,
            title: 'Export Food Logs (JSON)',
            subtitle:
                'Complete nutritional history formatted with ISO timestamps, portion weights, and oil modifiers.',
            badgeText: '$_totalFoodLogs meals logged',
            primaryButtonLabel: 'Share File',
            primaryButtonIcon: Icons.share_rounded,
            onPrimaryPressed: _exportFoodLogs,
            secondaryButtonLabel: 'Preview',
            secondaryButtonIcon: Icons.preview_rounded,
            onSecondaryPressed: () => _showPreviewDialog(
                'Food Logs Preview', _generateFoodLogsJson()),
          ),
          const SizedBox(height: 16),
          ExportCardTile(
            icon: Icons.table_chart_rounded,
            color: AppTheme.trendWeight,
            title: 'Export Scale Weights (CSV)',
            subtitle:
                'Chronological weigh-ins compatible with Excel, Google Sheets, or custom statistical models.',
            badgeText: '$_totalWeightLogs weigh-ins logged',
            primaryButtonLabel: 'Share File',
            primaryButtonIcon: Icons.share_rounded,
            onPrimaryPressed: _exportWeightLogs,
            secondaryButtonLabel: 'Preview',
            secondaryButtonIcon: Icons.preview_rounded,
            onSecondaryPressed: () => _showPreviewDialog(
                'Scale Weights CSV Preview', _generateWeightLogsCsv()),
          ),
          const SizedBox(height: 16),
          ExportCardTile(
            actionKey: const Key('full_backup_card'),
            icon: Icons.backup_rounded,
            color: AppTheme.calories,
            title: 'Full Backup & Recovery (.sique.json)',
            subtitle:
                'Export or restore an entire snapshot of your profile, nutrition targets, scale weights, and meal entries with schema version validation.',
            badgeText: 'Complete schema snapshot (v4)',
            primaryButtonLabel: 'Export Backup',
            primaryButtonIcon: Icons.download_rounded,
            onPrimaryPressed: _exportFullBackup,
            secondaryButtonLabel: 'Restore Backup',
            secondaryButtonIcon: Icons.restore_rounded,
            secondaryButtonKey: const Key('restore_from_backup_btn'),
            onSecondaryPressed: _showRestoreDialog,
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
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color),
              textAlign: TextAlign.center),
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
