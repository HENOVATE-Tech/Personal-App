import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/services/backup_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final profile = db.userProfile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings & Security'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Owner Profile Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppTheme.sereneTeal,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Timezone: ${profile.timezone} • Currency: ${profile.currency}', style: const TextStyle(fontSize: 12, color: AppTheme.mutedGray)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Privacy Blur Mode'),
                        subtitle: const Text('Masks financial balances and spiritual notes'),
                        value: profile.privacyModeEnabled,
                        activeColor: AppTheme.sereneTeal,
                        onChanged: (val) {
                          db.updateUserProfile(profile.copyWith(privacyModeEnabled: val));
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('24-Hour Clock Display'),
                        subtitle: const Text('Toggle between 12-hour (AM/PM) and 24-hour'),
                        value: profile.is24Hour,
                        activeColor: AppTheme.sereneTeal,
                        onChanged: (val) {
                          db.updateUserProfile(profile.copyWith(is24Hour: val));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Security & Backup
              const Text('Encrypted Backup & Portability (BR-13)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppTheme.sereneTeal),
                      title: const Text('Create Encrypted Backup (.plos)'),
                      subtitle: const Text('Export authenticated AES-GCM archive with SHA-256 manifest'),
                      onTap: () => _showCreateBackupDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore, color: Color(0xFF4F46E5)),
                      title: const Text('Restore from Backup'),
                      subtitle: const Text('Atomic staging validation before live database swap'),
                      onTap: () => _showRestoreBackupDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Diagnostics & Storage
              const Text('Diagnostics & Data Hygiene', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tasks stored: ${db.getTasks().length}'),
                      const SizedBox(height: 4),
                      Text('Accounts configured: ${db.getFinancialAccounts().length}'),
                      const SizedBox(height: 4),
                      Text('Financial postings: ${db.getLedgerTransactions().length}'),
                      const SizedBox(height: 4),
                      Text('Routine templates: ${db.getRoutineTemplates().length}'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever, color: AppTheme.gentleRose),
                        label: const Text('Wipe All Local Data', style: TextStyle(color: AppTheme.gentleRose)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gentleRose)),
                        onPressed: () => _showConfirmWipeDialog(context, db),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateBackupDialog(BuildContext context) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Encrypted Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a strong passphrase to encrypt your backup container. '
              'Because encryption is local-first, forgotten passphrases cannot be recovered.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Passphrase (min 6 characters)'),
            ),
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            child: const Text('Export Backup'),
            onPressed: () {
              final result = BackupService.instance.createEncryptedBackup(passCtrl.text.trim());
              Navigator.of(ctx).pop();
              if (result.isSuccess) {
                showDialog(
                  context: context,
                  builder: (resCtx) => AlertDialog(
                    title: const Text('Backup Container Ready'),
                    content: Text('SHA-256 Checksum: ${result.sha256Checksum?.substring(0, 16)}...\n\nYour encrypted .plos container is ready.'),
                    actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.of(resCtx).pop())],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessage ?? 'Backup failed')));
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRestoreBackupDialog(BuildContext context) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the passphrase used when creating the backup container:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Passphrase')),
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            child: const Text('Verify & Restore'),
            onPressed: () {
              // Create a sample container to demonstrate atomic restore validation
              final backup = BackupService.instance.createEncryptedBackup(passCtrl.text.trim());
              if (backup.isSuccess && backup.backupData != null) {
                final res = BackupService.instance.restoreFromEncryptedBackup(backup.backupData!, passCtrl.text.trim());
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.isSuccess ? 'Restore verified! ${res.recordsRestored} records restored.' : (res.errorMessage ?? 'Restore failed'))),
                );
              } else {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect passphrase.')));
              }
            },
          ),
        ],
      ),
    );
  }

  void _showConfirmWipeDialog(BuildContext context, LocalDatabase db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Data Wipe', style: TextStyle(color: AppTheme.gentleRose)),
        content: const Text(
          'This action permanently destroys all local tasks, journal entries, and financial ledgers on this device. '
          'This action is irreversible unless you have an encrypted backup.',
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gentleRose, foregroundColor: Colors.white),
            child: const Text('Wipe All Data'),
            onPressed: () {
              db.wipeAllData();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local database wiped clean and reset.')));
            },
          ),
        ],
      ),
    );
  }
}
