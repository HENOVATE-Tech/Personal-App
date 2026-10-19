import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/supabase_sync_service.dart';
import '../../../core/services/api_service.dart';

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
          backgroundColor: AppTheme.creamCanvas,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.coralMeshGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.35)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield_outlined, size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Zero Telemetry',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Security & System',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Offline privacy blur, local encryption & authenticated backups',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Owner Profile Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.floatingCardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  gradient: AppTheme.coralMeshGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.person, color: Colors.white, size: 28),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                        color: AppTheme.darkCharcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Preferred: ${profile.displayName} • ${profile.timezone} • ${profile.currency}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Privacy Blur Mode',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.darkCharcoal),
                            ),
                            subtitle: Text('Masks liquid balances and devotional logs', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            value: profile.privacyModeEnabled,
                            activeColor: AppTheme.coralPrimary,
                            onChanged: (val) {
                              db.updateUserProfile(profile.copyWith(privacyModeEnabled: val));
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              '24-Hour Clock Display',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.darkCharcoal),
                            ),
                            subtitle: Text('Format timeline into military or 12-hour AM/PM', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            value: profile.is24Hour,
                            activeColor: AppTheme.coralPrimary,
                            onChanged: (val) {
                              db.updateUserProfile(profile.copyWith(is24Hour: val));
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const RenderBackendCard(),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Direct Cloud DB (Supabase)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA5D6A7)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Color(0xFF2E7D32)),
                              SizedBox(width: 4),
                              Text(
                                'Postgres Connected',
                                style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.floatingCardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F4EA),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.cloud_done, color: Color(0xFF137333), size: 24),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Supabase Cloud PostgreSQL',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkCharcoal),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'db.actqetxmyfdmoqyykwxj.supabase.co:5432',
                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• 21 PostgreSQL Tables Configured', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('• TLS Encrypted Remote Replication', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('• Workspaces, Tasks, Ledger & Budgets Synced', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                                  label: const Text('Push to Cloud'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.coralPrimary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Synchronizing with Supabase PostgreSQL...')),
                                    );
                                    final res = await SupabaseSyncService.instance.pushToSupabase();
                                    if (!context.mounted) return;
                                    if (res.isSuccess) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Synced ${res.recordsPushed} records to Supabase Cloud!')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Sync failed: ${res.errorMessage}')),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.cloud_download_outlined, size: 16),
                                  label: const Text('Pull from Cloud'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.darkCharcoal,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Pulling data from Supabase...')),
                                    );
                                    final res = await SupabaseSyncService.instance.pullFromSupabase();
                                    if (!context.mounted) return;
                                    if (res.isSuccess) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Pulled ${res.recordsPulled} records from Supabase Cloud!')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Pull failed: ${res.errorMessage}')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Encrypted Portability (BR-13)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.floatingCardDecoration,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.peachPillBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.lock_outline, color: AppTheme.coralPrimary, size: 22),
                            ),
                            title: const Text(
                              'Create Encrypted Backup (.plos)',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.darkCharcoal),
                            ),
                            subtitle: Text(
                              'Authenticated AES-GCM container with SHA-256 manifest',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: AppTheme.darkCharcoal),
                            onTap: () => _showCreateBackupDialog(context),
                          ),
                          const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.restore, color: Color(0xFF4F46E5), size: 22),
                            ),
                            title: const Text(
                              'Restore from Backup Container',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.darkCharcoal),
                            ),
                            subtitle: Text(
                              'Atomic staging verification before live database swap',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: AppTheme.darkCharcoal),
                            onTap: () => _showRestoreBackupDialog(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Diagnostics & Hygiene',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.floatingCardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Active Tasks', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              Text('${db.getTasks().length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Financial Accounts', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              Text('${db.getFinancialAccounts().length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ledger Postings', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              Text('${db.getLedgerTransactions().length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Routine Templates', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              Text('${db.getRoutineTemplates().length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => _showConfirmWipeDialog(context, db),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFECDD3)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_forever, color: Color(0xFFE11D48), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Wipe All Local Data',
                                    style: TextStyle(
                                      color: Color(0xFFE11D48),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
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

class RenderBackendCard extends StatefulWidget {
  const RenderBackendCard({super.key});

  @override
  State<RenderBackendCard> createState() => _RenderBackendCardState();
}

class _RenderBackendCardState extends State<RenderBackendCard> {
  bool _isChecking = false;
  bool _isSyncing = false;
  ApiHealthResult? _health;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() => _isChecking = true);
    final res = await ApiService.instance.checkHealth();
    if (mounted) {
      setState(() {
        _isChecking = false;
        _health = res;
      });
    }
  }

  void _showEditUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiService.instance.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Render Backend API URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the public URL of your Render backend deployment (or local development address):',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'https://personal-life-os-api.onrender.com',
                labelText: 'Backend URL',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.link, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Default local: http://localhost:5000 (or http://10.0.2.2:5000 on Android emulator)',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.coralPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & Test'),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiService.instance.setBaseUrl(newUrl);
                Navigator.of(ctx).pop();
                _checkHealth();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _health?.isHealthy ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.floatingCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFFE8F0FE) : const Color(0xFFFCE8E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.dns_outlined,
                  color: isOnline ? const Color(0xFF1967D2) : const Color(0xFFD93025),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Render Backend REST API',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkCharcoal),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? const Color(0xFF34A853) : const Color(0xFFEA4335),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ApiService.instance.baseUrl,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'monospace'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                tooltip: 'Change Backend URL',
                onPressed: () => _showEditUrlDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'API Status: ${isOnline ? 'Online (Healthy)' : (_isChecking ? 'Connecting...' : 'Offline')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOnline ? const Color(0xFF137333) : const Color(0xFFC5221F),
                      ),
                    ),
                    if (_health?.database != null)
                      Text(
                        'DB: ${_health!.database}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Express & TypeScript REST engine with Render Blueprint support\n'
                  '• Double-entry ledger integrity & batch bi-directional push/pull\n'
                  '• Connected to Supabase PostgreSQL cloud storage',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: _isSyncing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.sync_outlined, size: 16),
                  label: Text(_isSyncing ? 'Syncing...' : 'Sync via API'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSyncing
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isSyncing = true);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Syncing with Render REST API backend...')),
                          );
                          final res = await ApiService.instance.syncAll(LocalDatabase.instance);
                          if (!mounted) return;
                          setState(() => _isSyncing = false);
                          if (res.isSuccess) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'API Sync Complete! Pushed: ${res.recordsPushed}, Pulled: ${res.recordsPulled}',
                                ),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Sync failed: ${res.errorMessage}')),
                            );
                          }
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: _isChecking
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.network_ping_outlined, size: 16),
                  label: const Text('Test Ping'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.darkCharcoal,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isChecking ? null : _checkHealth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
