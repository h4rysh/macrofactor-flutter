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
import 'package:sique/data/utils/backup_crypto.dart';
import 'package:sique/data/utils/csv_sanitizer.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/providers/recipes_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/data_export_dialogs.dart';
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
    final appSettings = Map<String, String>.from(db.getAllSettings())
      ..remove('gemini_api_key');
    final bodyMeasurements =
        db.bodyMeasurementsDao.getRecentMeasurements(limit: 5000);
    final weeklyChallenges = [
      ...db.challengesDao.getActiveChallenges(),
      ...db.challengesDao.getChallengeHistory(limit: 500),
    ];
    final waterLogs = db.waterDao.getAllWaterLogs();
    final fastingSessions = db.fastingDao.getRecentFasts(limit: 500);
    final customRecipes = db.recipesDao.getAllRecipes();
    final repeatItems = db.diaryToolsDao.getAllRepeatItems();
    final dayNotes = db.diaryToolsDao.getAllDayNotes();
    final microGoals = db.diaryToolsDao.getCustomMicroGoals();

    return BackupCodec.encodeBackup(
      profile: profile,
      foodLogs: foodLogs,
      weightLogs: weightLogs,
      workoutSessions: workoutSessions,
      expenditureHistory: expenditureHistory,
      coachingCheckIns: coachingCheckIns,
      dayCompletions: dayCompletions,
      appSettings: appSettings,
      bodyMeasurements: bodyMeasurements,
      weeklyChallenges: weeklyChallenges,
      waterLogs: waterLogs,
      fastingSessions: fastingSessions,
      customRecipes: customRecipes,
      repeatItems: repeatItems,
      dayNotes: dayNotes,
      microGoals: microGoals,
    );
  }

  Future<File?> _saveExportToFile(String filename, String content) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory(p.join(tempDir.path, 'sique_exports'));
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
      if (file == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Unable to write export archive to temporary storage.'),
              backgroundColor: AppTheme.calories,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      if (mounted) {
        final xFile = XFile(file.path, mimeType: mimeType, name: filename);
        try {
          // ignore: deprecated_member_use
          await Share.shareXFiles(
            [xFile],
            text: 'Sique Data Export: $filename',
          );
        } finally {
          try {
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
        }

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

  Future<void> _exportFullBackup() async {
    if (_isProcessing) return;
    final choice = await showBackupFormatDialog(context);
    if (!mounted || choice == null) return;

    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final backupJson = _generateFullBackupJson();

    if (choice == 'encrypted') {
      final password = await showBackupPassphraseDialog(
        context,
        title: 'Encrypt Backup (AES-256-GCM)',
        hint: 'Passphrase (min 8 characters)',
        confirmPassword: true,
      );
      if (!mounted || password == null) return;
      setState(() => _isProcessing = true);
      final String encrypted;
      try {
        encrypted = await BackupCrypto.encryptBackup(
          plaintextJson: backupJson,
          password: password,
        );
      } on BackupCryptoException catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppTheme.calories,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      } catch (_) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to encrypt backup archive.'),
              backgroundColor: AppTheme.calories,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() => _isProcessing = false);
      await _shareExportFile(
        filename: 'sique_backup_$timestamp.sique.enc',
        content: encrypted,
        mimeType: 'application/json',
        successMessage: 'Encrypted AES-256-GCM backup created & shared',
        color: AppTheme.activeBlue,
      );
      return;
    }

    await _shareExportFile(
      filename: 'sique_backup_$timestamp.sique.json',
      content: backupJson,
      mimeType: 'application/json',
      successMessage: 'Full backup archive created & shared',
      color: AppTheme.calories,
    );
  }

  Future<void> _restoreFromBackupContent(String rawContent) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    const maxBackupBytes = 25 * 1024 * 1024;
    try {
      if (rawContent.length > maxBackupBytes) {
        throw const FormatException(
          'Backup payload exceeds the 25 MB safety limit.',
        );
      }
      var jsonContent = rawContent;
      if (BackupCrypto.isEncryptedEnvelope(rawContent)) {
        final password = await showBackupPassphraseDialog(
          context,
          title: 'Decrypt Backup (.sique.enc)',
          hint: 'Enter backup passphrase',
        );
        if (password == null || !mounted) return;
        jsonContent = await BackupCrypto.decryptBackup(
          envelopeJson: rawContent,
          password: password,
        );
        if (!mounted) return;
      }

      final decoded = BackupCodec.decodeAndValidate(jsonContent);
      final db = ref.read(databaseProvider);
      final uid = db.currentUserId;

      db.rawDb.execute('BEGIN TRANSACTION;');
      try {
        if (decoded.profile != null) {
          db.profileDao.saveUserProfile(decoded.profile!, userId: uid);
        }

        for (final w in decoded.weightLogs) {
          final dateStr = w.date.toIso8601String().split('T').first;
          db.weightDao.insertWeightLog(
            dateStr,
            w.weightKg,
            w.note,
            userId: uid,
            source: w.source,
          );
        }

        for (final f in decoded.foodLogs) {
          db.foodDao.restoreFoodLog(f, userId: uid);
        }

        if (decoded.workoutSessions.isNotEmpty) {
          db.workoutDao.insertWorkoutSessions(
            decoded.workoutSessions,
            userId: uid,
            manageTransaction: false,
          );
        }

        if (decoded.expenditureHistory.isNotEmpty) {
          db.expenditureDao.saveExpenditures(
            decoded.expenditureHistory,
            userId: uid,
            manageTransaction: false,
          );
        }

        for (final c in decoded.coachingCheckIns) {
          db.insertCoachingCheckIn(c, userId: uid);
        }

        decoded.dayCompletions.forEach((date, isComplete) {
          db.expenditureDao.setDayComplete(date, isComplete, userId: uid);
        });

        decoded.appSettings.forEach((k, v) {
          db.setSetting(k, v);
        });

        for (final bm in decoded.bodyMeasurements) {
          db.bodyMeasurementsDao.upsertMeasurement(bm, userId: uid);
        }

        for (final ch in decoded.weeklyChallenges) {
          db.challengesDao.upsertChallenge(ch, userId: uid);
        }

        final restoredWaterDates = <String>{};
        for (final w in decoded.waterLogs) {
          if (restoredWaterDates.add(w.date)) {
            final parsedDate = DateTime.tryParse(w.date);
            if (parsedDate != null) {
              db.waterDao.clearDayWater(parsedDate, userId: uid);
            }
          }
        }
        for (final w in decoded.waterLogs) {
          db.waterDao.logWater(
            w.amountMl,
            date: DateTime.tryParse(w.date),
            userId: uid,
            loggedAt: w.loggedAt,
          );
        }

        for (final fs in decoded.fastingSessions) {
          db.fastingDao.upsertFastingSession(fs, userId: uid);
        }

        for (final rec in decoded.customRecipes) {
          db.recipesDao.upsertRecipe(
            rec,
            userId: uid,
            manageTransaction: false,
          );
        }

        for (final rep in decoded.repeatItems) {
          db.diaryToolsDao.upsertRepeatItem(rep, userId: uid);
        }

        for (final entry in decoded.dayNotes.entries) {
          db.diaryToolsDao.saveDayNote(entry.key, entry.value, userId: uid);
        }

        for (final mg in decoded.microGoals.entries) {
          db.diaryToolsDao.setCustomMicroGoal(mg.key, mg.value, userId: uid);
        }
        db.rawDb.execute('COMMIT;');
      } catch (_) {
        db.rawDb.execute('ROLLBACK;');
        rethrow;
      }

      // Refresh providers
      ref.read(userDataEpochProvider.notifier).state++;
      ref.read(foodLogSettingsRevisionProvider.notifier).state++;
      ref.invalidate(useImperialUnitsProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(weightLogsProvider);
      ref.invalidate(dailyFoodLogsProvider);
      ref.invalidate(dayCompletionsProvider);
      ref.invalidate(workoutSessionsProvider);
      ref.invalidate(bodyMeasurementsProvider);
      ref.invalidate(weeklyChallengesProvider);
      ref.invalidate(customRecipesProvider);
      ref.invalidate(healthConnectSyncProvider);
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
      final safeMessage = switch (e) {
        BackupCryptoException(:final message) => message,
        FormatException(:final message) => message,
        _ => 'Restore failed: Backup file could not be validated or imported.',
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(safeMessage),
            backgroundColor: AppTheme.calories,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickAndRestoreFile() async {
    const maxBackupBytes = 25 * 1024 * 1024;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final length = await file.length();
        if (length > maxBackupBytes) {
          throw const FormatException(
            'Selected backup file exceeds the 25 MB safety limit.',
          );
        }
        final content = await file.readAsString();
        await _restoreFromBackupContent(content);
      }
    } catch (e, st) {
      developer.log('File pick error', error: e, stackTrace: st);
      final msg = e is FormatException
          ? e.message
          : 'Failed to read selected backup file.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.calories,
          ),
        );
      }
    }
  }

  void _showRestoreDialog() {
    showBackupRestoreDialog(
      context,
      onPickFile: _pickAndRestoreFile,
      onRestoreText: _restoreFromBackupContent,
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
            isLoading: _isProcessing,
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
            isLoading: _isProcessing,
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
            title: 'Full Backup & Recovery (.sique.enc / .json)',
            subtitle:
                'Export or restore an encrypted AES-256-GCM or plaintext snapshot of all nutrition, metabolic, lifestyle, and recipe data.',
            badgeText: 'Complete schema snapshot (v7)',
            primaryButtonLabel: 'Export Backup',
            primaryButtonIcon: Icons.download_rounded,
            isLoading: _isProcessing,
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
              'Zero Tracking • Private by Default\nYour health and nutrition data never leaves your device. All calculations and logs stay 100% offline on this device.',
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
