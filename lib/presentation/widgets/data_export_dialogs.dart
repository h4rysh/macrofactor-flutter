import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Prompts the user to select between AES-256-GCM encrypted `.sique.enc`
/// and unencrypted `.sique.json` backup formats.
Future<String?> showBackupFormatDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      title: const Text(
        'Choose Backup Format',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: const Text(
        'Protect your health data with an AES-256-GCM passphrase (.sique.enc) or export an unencrypted archive (.sique.json).',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop('plain'),
          child: const Text('Unencrypted (.sique.json)'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(ctx).pop('encrypted'),
          icon: const Icon(Icons.lock_rounded, size: 16),
          label: const Text('Encrypted (.sique.enc)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.activeBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

/// Prompts the user for a backup encryption/decryption passphrase.
Future<String?> showBackupPassphraseDialog(
  BuildContext context, {
  required String title,
  required String hint,
  bool confirmPassword = false,
}) async {
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  String? errorMsg;

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('backup_passphrase_input'),
              controller: passCtrl,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: hint,
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            if (confirmPassword) ...[
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Confirm passphrase',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
            if (errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMsg!,
                style: const TextStyle(fontSize: 12, color: AppTheme.calories),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final p = passCtrl.text;
              if (confirmPassword && p.length < 8) {
                setDialogState(
                  () => errorMsg = 'Passphrase must be at least 8 characters.',
                );
                return;
              }
              if (confirmPassword && p != confirmCtrl.text) {
                setDialogState(() => errorMsg = 'Passphrases do not match.');
                return;
              }
              Navigator.of(ctx).pop(p);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.activeBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    ),
  );
  passCtrl.dispose();
  confirmCtrl.dispose();
  return result;
}

/// Modal dialog allowing file picker selection or raw JSON/encrypted paste restore.
void showBackupRestoreDialog(
  BuildContext context, {
  required VoidCallback onPickFile,
  required ValueChanged<String> onRestoreText,
}) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      title: const Row(
        children: [
          Icon(Icons.restore_page_rounded, color: AppTheme.activeBlue),
          SizedBox(width: 8),
          Text(
            'Restore from Backup',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
          ),
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
                label: const Text('Choose .sique.enc or .json File'),
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
                  onPickFile();
                },
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.cardBorder)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'OR PASTE JSON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
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
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText:
                      '{\n  "app": "Sique",\n  "schemaVersion": 7,\n  ...\n}',
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
              onRestoreText(text);
            }
          },
          child: const Text('Validate & Restore'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}
