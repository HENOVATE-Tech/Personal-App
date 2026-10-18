import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/money_formatter.dart';

class TransactionEditorScreen extends StatefulWidget {
  final TransactionType initialType;

  const TransactionEditorScreen({
    super.key,
    this.initialType = TransactionType.expense,
  });

  @override
  State<TransactionEditorScreen> createState() => _TransactionEditorScreenState();
}

class _TransactionEditorScreenState extends State<TransactionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  late TransactionType _type;
  String? _sourceAccountId;
  String? _targetAccountId; // For transfers
  String? _categoryId;

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    final accounts = LocalDatabase.instance.getFinancialAccounts();
    if (accounts.isNotEmpty) {
      _sourceAccountId = accounts.first.id;
      if (accounts.length > 1) {
        _targetAccountId = accounts[1].id;
      }
    }
    final categories = LocalDatabase.instance.getFinancialCategories();
    if (categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final int kobo;
    try {
      kobo = MoneyFormatter.parseToKobo(_amountController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid amount: $e')),
      );
      return;
    }

    final memo = _memoController.text.trim().isEmpty
        ? '${_type.name.toUpperCase()} transaction'
        : _memoController.text.trim();

    final db = LocalDatabase.instance;
    final List<LedgerMovement> movements = [];
    final txId = _uuid.v4();

    // Construct Balanced Double-Entry Movements (Sum == 0)
    if (_type == TransactionType.expense) {
      // 1. Debit Category (positive expense): +kobo
      movements.add(LedgerMovement(
        id: _uuid.v4(),
        transactionId: txId,
        categoryId: _categoryId,
        amountKobo: kobo,
      ));
      // 2. Credit Asset Account (decreases asset): -kobo
      movements.add(LedgerMovement(
        id: _uuid.v4(),
        transactionId: txId,
        accountId: _sourceAccountId,
        amountKobo: -kobo,
      ));
    } else if (_type == TransactionType.income) {
      // 1. Debit Asset Account (increases asset): +kobo
      movements.add(LedgerMovement(
        id: _uuid.v4(),
        transactionId: txId,
        accountId: _sourceAccountId,
        amountKobo: kobo,
      ));
      // 2. Credit Income Category: -kobo
      movements.add(LedgerMovement(
        id: _uuid.v4(),
        transactionId: txId,
        categoryId: _categoryId,
        amountKobo: -kobo,
      ));
    } else if (_type == TransactionType.transfer) {
      if (_sourceAccountId == _targetAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and target accounts must be different.')),
        );
        return;
      }
      // 1. Outbound Account (decreases): -kobo
      movements.add(LedgerMovement(
        id: _uuid.v4(),
        transactionId: txId,
        accountId: _sourceAccountId,
        amountKobo: -kobo,
      ));
      // 2. Inbound Account (increases): +kobo
      movements.add(LedgerMovement(
        id: _uuid.v4(),
        transactionId: txId,
        accountId: _targetAccountId,
        amountKobo: kobo,
      ));
    }

    // Atomic post to persistent database
    db.postTransaction(
      type: _type,
      effectiveAt: DateTime.now(),
      memo: memo,
      movements: movements,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction posted: ${MoneyFormatter.formatKobo(kobo)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = LocalDatabase.instance.getFinancialAccounts();
    final categories = LocalDatabase.instance.getFinancialCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Transaction Type Segmented Button
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                  icon: Icon(Icons.sync_alt),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
            const SizedBox(height: 20),

            // Amount Input (₦)
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                labelText: 'Amount (₦)',
                prefixText: '₦ ',
                hintText: '0.00',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Enter amount';
                if (!MoneyFormatter.isValidAmount(val)) return 'Enter a valid positive amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Source Account Selector
            DropdownButtonFormField<String>(
              value: _sourceAccountId,
              decoration: InputDecoration(
                labelText: _type == TransactionType.transfer ? 'From Account' : 'Account',
              ),
              items: accounts.map((acc) {
                return DropdownMenuItem(
                  value: acc.id,
                  child: Text('${acc.name} (${MoneyFormatter.formatKobo(acc.balanceKobo)})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _sourceAccountId = val),
            ),
            const SizedBox(height: 16),

            // If Transfer -> Target Account Selector
            if (_type == TransactionType.transfer) ...[
              DropdownButtonFormField<String>(
                value: _targetAccountId,
                decoration: const InputDecoration(labelText: 'To Account'),
                items: accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text('${acc.name} (${MoneyFormatter.formatKobo(acc.balanceKobo)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _targetAccountId = val),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Category Selector
              DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _categoryId = val),
              ),
              const SizedBox(height: 16),
            ],

            // Memo / Merchant
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'Description / Memo (Optional)',
                hintText: 'e.g. Lunch with client, Fuel at Mobil',
              ),
            ),
            const SizedBox(height: 28),

            // Save Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sereneTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _submit,
              child: const Text('Post Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
