import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/services/sms_ingestion_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/privacy_blur_wrapper.dart';
import 'budget_management_screen.dart';

class FinanceOverviewScreen extends StatelessWidget {
  final VoidCallback onAddTransaction;

  const FinanceOverviewScreen({
    super.key,
    required this.onAddTransaction,
  });

  void _showSmsDebitApprovalDialog(BuildContext context, SmsDebitAlert alert) {
    final db = LocalDatabase.instance;
    final accounts = db.getFinancialAccounts();
    final categories = db.getFinancialCategories().where((c) => c.type == 'expense').toList();

    String selectedAccountId = accounts.isNotEmpty ? accounts.first.id : '';
    // Auto-match account if accountLast4 matches
    if (alert.accountLast4 != null) {
      for (final a in accounts) {
        if (a.name.contains(alert.accountLast4!)) {
          selectedAccountId = a.id;
          break;
        }
      }
    }

    String selectedCategoryId = alert.suggestedCategoryId ?? (categories.isNotEmpty ? categories.first.id : '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final cat = categories.cast<FinancialCategory?>().firstWhere(
                  (c) => c?.id == selectedCategoryId,
                  orElse: () => null,
                );
            final budget = db.getBudgetForCategory(selectedCategoryId);
            final willOverspend = budget != null &&
                budget.allocatedKobo > 0 &&
                (budget.spentKobo + alert.amountKobo) > budget.allocatedKobo;
            final isNonEssential = cat != null && !cat.isEssential;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFFFECE5),
                    radius: 18,
                    child: Icon(Icons.sms_failed, color: AppTheme.coralPrimary, size: 20),
                  ),
                  SizedBox(width: 10),
                  Text('Approve Debit Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                alert.sender,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              Text(
                                AppDateUtils.formatShortDate(alert.receivedAt),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            MoneyFormatter.formatKobo(alert.amountKobo),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.memo,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Governance Warnings if overspent or non-essential
                    if (willOverspend) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF87171)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'OVERSPEND WARNING: Adding this expense will exceed your monthly budget for ${cat?.name}!',
                                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (isNonEssential) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'NON-ESSENTIAL / DISCRETIONARY SPENDING: Flagged as unnecessary spend.',
                                style: TextStyle(color: Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Select Account
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      decoration: const InputDecoration(labelText: 'Debit From Account'),
                      items: accounts.map((acc) {
                        return DropdownMenuItem(
                          value: acc.id,
                          child: Text('${acc.name} (${MoneyFormatter.formatKobo(acc.balanceKobo)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedAccountId = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Select Category
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category Allocation'),
                      items: categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCategoryId = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    db.dismissSmsDebitAlert(alert.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Dismiss', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    db.processSmsDebitAlert(
                      alert.id,
                      accountId: selectedAccountId,
                      categoryId: selectedCategoryId,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Posted ${MoneyFormatter.formatKobo(alert.amountKobo)} to ledger')),
                    );
                  },
                  child: const Text('Post to Ledger'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final accounts = db.getFinancialAccounts();
        final transactions = db.getLedgerTransactions();
        final totalLiquidityKobo = accounts.fold<int>(0, (sum, a) => sum + a.balanceKobo);
        final pendingAlerts = db.getPendingSmsDebitAlerts();
        final overspendingBudgets = db.getOverspendingBudgets();
        final unnecessarySpendKobo = db.getUnnecessarySpendKobo();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Financial Ledger (NGN)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.pie_chart, color: AppTheme.coralPrimary),
                tooltip: 'Budgets & Analytics',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BudgetManagementScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.coralPrimary, size: 28),
                tooltip: 'Add Transaction',
                onPressed: onAddTransaction,
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 110 + MediaQuery.of(context).padding.bottom),
            children: [
              // Sunset Mesh Gradient Balance Card
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.sunsetMesh,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppTheme.heroFloatShadow,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL LIQUID LEDGER',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NGN • ₦',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    PrivacyBlurWrapper(
                      child: Text(
                        MoneyFormatter.formatKobo(totalLiquidityKobo),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Record'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.darkCharcoal,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: onAddTransaction,
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.pie_chart, size: 16),
                          label: const Text('Budgets & Analytics'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BudgetManagementScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Active Overspending Alerts Banner
              if (overspendingBudgets.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BudgetManagementScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF87171), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OVERSPEND WARNING (${overspendingBudgets.length} CATEGORIES)',
                                style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'You have exceeded monthly allocations. Tap to view budget analytics and adjust limits.',
                                style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF991B1B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Discretionary / Unnecessary Spending Warning Card
              if (unnecessarySpendKobo > 0) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Unnecessary Spend Notice: You have spent ${MoneyFormatter.formatKobo(unnecessarySpendKobo)} on non-essential items this month.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // --- SMS Bank Debit Ingestion Governance ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bank Debit Alerts (SMS)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.flash_on, size: 14, color: AppTheme.coralPrimary),
                        label: const Text('Simulate Alert', style: TextStyle(color: AppTheme.coralPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          // Rotate sample bank alerts (GTBank, Kuda, Zenith)
                          final sampleSenders = ['GTBANK', 'KUDA', 'ZENITH', 'ACCESS'];
                          final sampleMemos = [
                            'POS PURCHASE - MOBIL FILLING STATION',
                            'Dominos Pizza VI Lagos',
                            'Jumia Online Shopping Express',
                            'EEDC Electricity Prepaid Token',
                          ];
                          final sampleAmounts = [1250000, 850000, 3200000, 500000];
                          final idx = DateTime.now().millisecond % sampleSenders.length;

                          SmsIngestionService.simulateTestAlert(
                            sender: sampleSenders[idx],
                            amountKobo: sampleAmounts[idx],
                            memo: sampleMemos[idx],
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Simulated incoming ${sampleSenders[idx]} debit alert')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20, color: AppTheme.textSecondary),
                        tooltip: 'Scan SMS Inbox',
                        onPressed: () async {
                          final alerts = await SmsIngestionService.instance.scanInboxForAlerts();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Scanned SMS inbox: ${alerts.length} new debit alerts found')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (pendingAlerts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.mark_email_read_outlined, color: AppTheme.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No unposted debit alerts. Incoming bank SMS (GTB, Kuda, Zenith, etc.) will appear here for 1-tap review.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...pendingAlerts.map((alert) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.coralPrimary.withOpacity(0.3), width: 1.5),
                      boxShadow: AppTheme.softCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFECE5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                alert.sender,
                                style: const TextStyle(
                                  color: AppTheme.coralPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Text(
                              AppDateUtils.formatShortDate(alert.receivedAt),
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    MoneyFormatter.formatKobo(alert.amountKobo),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    alert.memo,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.coralPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _showSmsDebitApprovalDialog(context, alert),
                              child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // Accounts Header
              const Text(
                'Accounts & Wallets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              ...accounts.map((acc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: acc.accountType == AccountType.cash
                          ? AppTheme.pastelPeach
                          : AppTheme.pastelBlue,
                      child: Icon(
                        acc.accountType == AccountType.cash
                            ? Icons.account_balance_wallet
                            : Icons.account_balance,
                        color: acc.accountType == AccountType.cash
                            ? AppTheme.pastelPeachText
                            : AppTheme.pastelBlueText,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      acc.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      acc.accountType.name.toUpperCase(),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    trailing: PrivacyBlurWrapper(
                      child: Text(
                        MoneyFormatter.formatKobo(acc.balanceKobo),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Journal Postings Header
              const Text(
                'Recent Postings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              if (transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: const Center(
                    child: Text(
                      'No recorded transactions yet. Tap "Record" above or approve an SMS debit alert.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...transactions.map((tx) {
                  final isExpense = tx.type == TransactionType.expense;
                  final isIncome = tx.type == TransactionType.income;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softCardShadow,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isExpense
                            ? const Color(0xFFFFECE5)
                            : isIncome
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFEDE7F6),
                        child: Icon(
                          isExpense
                              ? Icons.arrow_upward
                              : isIncome
                                  ? Icons.arrow_downward
                                  : Icons.sync_alt,
                          color: isExpense
                              ? AppTheme.coralPrimary
                              : isIncome
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF5E35B1),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        tx.memo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${tx.type.name.toUpperCase()} • ${AppDateUtils.formatShortDate(tx.effectiveAt)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tx.type == TransactionType.transfer ? 'NEUTRAL' : 'POSTED',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
