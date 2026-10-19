import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/database/local_database.dart';
import 'package:personal_life_os/core/database/schema_models.dart';
import 'package:personal_life_os/core/services/sms_ingestion_service.dart';

void main() {
  group('Budgeting, Expense Analytics & SMS Debit Alert Governance Tests', () {
    late LocalDatabase db;

    setUp(() {
      db = LocalDatabase.instance;
      db.wipeAllData();
    });

    test('Category spending calculations accurately sum expense movements for current month', () {
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // 1. Initially spent is 0
      expect(db.getCategorySpentKobo('cat-food', periodMonthYear: period), 0);

      // 2. Post an expense of ₦15,000 for Food
      db.postTransaction(
        type: TransactionType.expense,
        effectiveAt: now,
        memo: 'Groceries at Shoprite',
        movements: [
          const LedgerMovement(id: 'm1', transactionId: 'tx1', categoryId: 'cat-food', amountKobo: 1500000),
          const LedgerMovement(id: 'm2', transactionId: 'tx1', accountId: 'acc-gtb', amountKobo: -1500000),
        ],
      );

      expect(db.getCategorySpentKobo('cat-food', periodMonthYear: period), 1500000);
      expect(db.getMonthTotalExpenseKobo(periodMonthYear: period), 1500000);
    });

    test('Overspending detection triggers when category expense exceeds monthly allocated budget', () {
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Set budget for Entertainment: ₦10,000 (1,000,000 kobo)
      db.upsertBudget(Budget(
        id: 'b-ent',
        categoryId: 'cat-entertainment',
        periodMonthYear: period,
        allocatedKobo: 1000000,
      ));

      // Post ₦12,000 expense (exceeds ₦10,000 by ₦2,000)
      db.postTransaction(
        type: TransactionType.expense,
        effectiveAt: now,
        memo: 'Cinema and Dinner',
        movements: [
          const LedgerMovement(id: 'm1', transactionId: 'tx2', categoryId: 'cat-entertainment', amountKobo: 1200000),
          const LedgerMovement(id: 'm2', transactionId: 'tx2', accountId: 'acc-cash', amountKobo: -1200000),
        ],
      );

      final overspending = db.getOverspendingBudgets(periodMonthYear: period);
      expect(overspending.any((b) => b.categoryId == 'cat-entertainment'), isTrue);

      final entBudget = db.getBudgetForCategory('cat-entertainment', periodMonthYear: period);
      expect(entBudget?.isOverspent, isTrue);
      expect(entBudget?.percentUsed, 120.0);
      expect(entBudget?.remainingKobo, -200000); // ₦2,000 over
    });

    test('Non-essential / Discretionary spend calculation accurately tracks unnecessary purchases', () {
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Essential spend: Food ₦10,000
      db.postTransaction(
        type: TransactionType.expense,
        effectiveAt: now,
        memo: 'Groceries',
        movements: [
          const LedgerMovement(id: 'm1', transactionId: 'tx-ess', categoryId: 'cat-food', amountKobo: 1000000),
          const LedgerMovement(id: 'm2', transactionId: 'tx-ess', accountId: 'acc-cash', amountKobo: -1000000),
        ],
      );

      // Non-essential spend: Shopping ₦7,500
      db.postTransaction(
        type: TransactionType.expense,
        effectiveAt: now,
        memo: 'Fashion impulse buy',
        movements: [
          const LedgerMovement(id: 'm3', transactionId: 'tx-noness', categoryId: 'cat-shopping', amountKobo: 750000),
          const LedgerMovement(id: 'm4', transactionId: 'tx-noness', accountId: 'acc-cash', amountKobo: -750000),
        ],
      );

      expect(db.getMonthTotalExpenseKobo(periodMonthYear: period), 1750000);
      expect(db.getUnnecessarySpendKobo(periodMonthYear: period), 750000);
    });

    test('SMS Regex Parser correctly extracts GTBank debit alert format', () {
      const sampleGtSms = 'Debit: Amt: NGN 18,500.00 | Acc: 014****567 | Desc: POS PURCHASE - TOTAL FILLING STATION | Date: 19-Oct-2026 | Bal: NGN 245,000.00';
      final alert = SmsIngestionService.parseDebitAlert(
        sender: 'GTBANK',
        body: sampleGtSms,
      );

      expect(alert, isNotNull);
      expect(alert!.amountKobo, 1850000); // ₦18,500.00
      expect(alert.accountLast4, '567');
      expect(alert.memo, contains('TOTAL FILLING STATION'));
      expect(alert.isDebit, isTrue);
      expect(alert.suggestedCategoryId, 'cat-transport');
    });

    test('SMS Regex Parser correctly extracts Kuda Bank debit alert format', () {
      const sampleKudaSms = 'You spent ₦8,500.00 at Chicken Republic. Available balance: ₦42,000.00';
      final alert = SmsIngestionService.parseDebitAlert(
        sender: 'KUDA',
        body: sampleKudaSms,
      );

      expect(alert, isNotNull);
      expect(alert!.amountKobo, 850000); // ₦8,500.00
      expect(alert.isDebit, isTrue);
      expect(alert.suggestedCategoryId, 'cat-food');
    });

    test('SMS Regex Parser correctly extracts Zenith Bank DR alert format', () {
      const sampleZenithSms = 'Acct: 208***123 | Amt: 25,000.00 DR | Desc: NETFLIX SUBSCRIPTION | Bal: 180,000.00';
      final alert = SmsIngestionService.parseDebitAlert(
        sender: 'ZENITH',
        body: sampleZenithSms,
      );

      expect(alert, isNotNull);
      expect(alert!.amountKobo, 2500000); // ₦25,000.00
      expect(alert.accountLast4, '123');
      expect(alert.isDebit, isTrue);
      expect(alert.suggestedCategoryId, 'cat-entertainment');
    });

    test('Processing an SMS Debit Alert creates balanced double-entry transaction and decrements account', () {
      final gtbBefore = db.getFinancialAccounts().firstWhere((a) => a.id == 'acc-gtb').balanceKobo;

      // Add a simulated alert
      final alert = SmsIngestionService.simulateTestAlert(
        sender: 'GTBANK',
        amountKobo: 500000, // ₦5,000.00
        memo: 'Fuel purchase',
        categoryId: 'cat-transport',
      );

      expect(db.getPendingSmsDebitAlerts().any((a) => a.id == alert.id), isTrue);

      // Process and post to ledger
      db.processSmsDebitAlert(
        alert.id,
        accountId: 'acc-gtb',
        categoryId: 'cat-transport',
      );

      final gtbAfter = db.getFinancialAccounts().firstWhere((a) => a.id == 'acc-gtb').balanceKobo;
      expect(gtbAfter, gtbBefore - 500000);

      // Ensure alert is marked processed
      expect(db.getPendingSmsDebitAlerts().any((a) => a.id == alert.id), isFalse);

      // Ensure balanced double entry
      final latestTx = db.getLedgerTransactions().first;
      expect(latestTx.memo, contains('Fuel purchase'));
      final movements = db.getLedgerMovements().where((m) => m.transactionId == latestTx.id).toList();
      final sum = movements.fold<int>(0, (s, m) => s + m.amountKobo);
      expect(sum, 0); // Balanced!
    });
  });
}
