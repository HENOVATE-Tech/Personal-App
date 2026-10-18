import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/privacy_blur_wrapper.dart';

class FinanceOverviewScreen extends StatelessWidget {
  final VoidCallback onAddTransaction;

  const FinanceOverviewScreen({
    super.key,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final accounts = db.getFinancialAccounts();
        final transactions = db.getLedgerTransactions();

        final totalLiquidityKobo = accounts.fold<int>(0, (sum, a) => sum + a.balanceKobo);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Financial Ledger (NGN)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppTheme.sereneTeal),
                tooltip: 'Add Transaction',
                onPressed: onAddTransaction,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Total Balance Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Ledger Net Worth',
                        style: TextStyle(color: AppTheme.mutedGray, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      PrivacyBlurWrapper(
                        child: Text(
                          MoneyFormatter.formatKobo(totalLiquidityKobo),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppTheme.slateNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Double-entry verified. Amounts stored in integer minor units (kobo).',
                        style: TextStyle(fontSize: 11, color: AppTheme.mutedGray),
                      ),
                    ],
                  ),
                ),
              ),

              // Accounts List
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  'Accounts & Balances',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...accounts.map((acc) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: acc.accountType == AccountType.cash
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFE0E7FF),
                      child: Icon(
                        acc.accountType == AccountType.cash
                            ? Icons.account_balance_wallet
                            : Icons.account_balance,
                        color: acc.accountType == AccountType.cash
                            ? const Color(0xFFD97706)
                            : const Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      acc.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      acc.accountType.name.toUpperCase(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: PrivacyBlurWrapper(
                      child: Text(
                        MoneyFormatter.formatKobo(acc.balanceKobo),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Recent Transactions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Text(
                  'Recent Journal Postings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Center(
                    child: Text(
                      'No recorded transactions yet. Tap "+" to record your first expense or income.',
                      style: TextStyle(color: AppTheme.mutedGray),
                    ),
                  ),
                )
              else
                ...transactions.map((tx) {
                  final isExpense = tx.type == TransactionType.expense;
                  final isIncome = tx.type == TransactionType.income;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isExpense
                            ? const Color(0xFFFFE4E6)
                            : isIncome
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFE0E7FF),
                        child: Icon(
                          isExpense
                              ? Icons.arrow_upward
                              : isIncome
                                  ? Icons.arrow_downward
                                  : Icons.sync_alt,
                          color: isExpense
                              ? AppTheme.gentleRose
                              : isIncome
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF4F46E5),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        tx.memo,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${tx.type.name.toUpperCase()} • ${AppDateUtils.formatShortDate(tx.effectiveAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Chip(
                        label: Text(
                          tx.type == TransactionType.transfer ? 'NEUTRAL' : 'POSTED',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                      ),
                    ),
                  );
                }),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
            backgroundColor: AppTheme.sereneTeal,
            foregroundColor: Colors.white,
            onPressed: onAddTransaction,
          ),
        );
      },
    );
  }
}
