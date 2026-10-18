import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/database/local_database.dart';
import 'package:personal_life_os/core/database/schema_models.dart';
import 'package:personal_life_os/core/utils/money_formatter.dart';

void main() {
  group('Financial Double-Entry Ledger & Precision Tests (FIN-101..120, BR-06)', () {
    late LocalDatabase db;

    setUp(() {
      db = LocalDatabase.instance;
      db.wipeAllData();
    });

    test('FIN-101: Minor units (kobo) formatting and parsing are exact', () {
      expect(MoneyFormatter.formatKobo(150000), '₦1,500.00');
      expect(MoneyFormatter.formatKobo(5000), '₦50.00');
      expect(MoneyFormatter.formatKobo(35000000), '₦350,000.00');

      expect(MoneyFormatter.parseToKobo('1500'), 150000);
      expect(MoneyFormatter.parseToKobo('₦1,500.50'), 150050);
      expect(MoneyFormatter.parseToKobo('350,000'), 35000000);

      expect(() => MoneyFormatter.parseToKobo('-500'), throwsA(isA<FormatException>()));
    });

    test('FIN-102: Transfer neutrality — Internal transfer moves funds without affecting expense totals', () {
      final cashAcc = db.getFinancialAccounts().firstWhere((a) => a.id == 'acc-cash');
      final gtbAcc = db.getFinancialAccounts().firstWhere((a) => a.id == 'acc-gtb');

      final initialCash = cashAcc.balanceKobo;
      final initialGtb = gtbAcc.balanceKobo;
      const transferAmountKobo = 1000000; // ₦10,000.00

      // Execute transfer: GTB (-₦10,000) -> Cash (+₦10,000)
      db.postTransaction(
        type: TransactionType.transfer,
        effectiveAt: DateTime.now(),
        memo: 'ATM Cash Withdrawal',
        movements: [
          const LedgerMovement(
            id: 'm1',
            transactionId: 'tx-transfer-1',
            accountId: 'acc-gtb',
            amountKobo: -transferAmountKobo,
          ),
          const LedgerMovement(
            id: 'm2',
            transactionId: 'tx-transfer-1',
            accountId: 'acc-cash',
            amountKobo: transferAmountKobo,
          ),
        ],
      );

      final updatedCash = db.getFinancialAccounts().firstWhere((a) => a.id == 'acc-cash').balanceKobo;
      final updatedGtb = db.getFinancialAccounts().firstWhere((a) => a.id == 'acc-gtb').balanceKobo;

      expect(updatedCash, initialCash + transferAmountKobo);
      expect(updatedGtb, initialGtb - transferAmountKobo);

      // Verify transaction is recorded as transfer
      final tx = db.getLedgerTransactions().first;
      expect(tx.type, TransactionType.transfer);
    });

    test('FIN-103: Double-entry invariant — Unbalanced journal throws ArgumentError', () {
      expect(
        () => db.postTransaction(
          type: TransactionType.expense,
          effectiveAt: DateTime.now(),
          memo: 'Unbalanced Attempt',
          movements: [
            const LedgerMovement(
              id: 'm1',
              transactionId: 'tx-err',
              accountId: 'acc-cash',
              amountKobo: -50000,
            ),
            const LedgerMovement(
              id: 'm2',
              transactionId: 'tx-err',
              categoryId: 'cat-food',
              amountKobo: 40000, // Missing 10,000 kobo!
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('FIN-104: Expense posting updates asset balance atomically', () {
      final cashAcc = db.getFinancialAccounts().firstWhere((a) => a.id == 'acc-cash');
      final initialBalance = cashAcc.balanceKobo;
      const expenseAmountKobo = 250000; // ₦2,500.00

      db.postTransaction(
        type: TransactionType.expense,
        effectiveAt: DateTime.now(),
        memo: 'Lunch at Bukka',
        movements: [
          const LedgerMovement(
            id: 'm1',
            transactionId: 'tx-exp-1',
            accountId: 'acc-cash',
            amountKobo: -expenseAmountKobo,
          ),
          const LedgerMovement(
            id: 'm2',
            transactionId: 'tx-exp-1',
            categoryId: 'cat-food',
            amountKobo: expenseAmountKobo,
          ),
        ],
      );

      final updatedCash = db.getFinancialAccounts().firstWhere((a) => a.id == 'acc-cash').balanceKobo;
      expect(updatedCash, initialBalance - expenseAmountKobo);
    });
  });
}
