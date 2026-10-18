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
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Financial Ledger (NGN)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.coralPrimary, size: 28),
                tooltip: 'Add Transaction',
                onPressed: onAddTransaction,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Sunset Mesh Gradient Balance Card (matching reference design)
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
                          label: const Text('Record Transaction'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.darkCharcoal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: onAddTransaction,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
                      'No recorded transactions yet. Tap "Record Transaction" above.',
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
