import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/privacy_blur_wrapper.dart';

class BudgetManagementScreen extends StatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  final _uuid = const Uuid();
  late String _currentPeriod;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _openAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    bool isEssential = true;
    String selectedType = 'expense';
    int selectedColor = 0xFF3B82F6;

    final colorOptions = [
      0xFFF59E0B, // Amber
      0xFF3B82F6, // Blue
      0xFF10B981, // Emerald
      0xFFEC4899, // Pink
      0xFF8B5CF6, // Purple
      0xFFEF4444, // Red
      0xFF14B8A6, // Teal
      0xFFF97316, // Orange
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Add Spending Category', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g. Subscriptions, Gym & Health',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Expense'),
                          selected: selectedType == 'expense',
                          selectedColor: const Color(0xFFFFECE5),
                          onSelected: (_) => setDialogState(() => selectedType = 'expense'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Income'),
                          selected: selectedType == 'income',
                          selectedColor: const Color(0xFFE8F5E9),
                          onSelected: (_) => setDialogState(() => selectedType = 'income'),
                        ),
                      ],
                    ),
                    if (selectedType == 'expense') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isEssential ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isEssential ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isEssential ? Icons.verified : Icons.warning_amber_rounded,
                              color: isEssential ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEssential ? 'Essential Need' : 'Non-Essential / Discretionary',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    isEssential
                                        ? 'Necessary living expenses (food, shelter, utilities)'
                                        : 'Impulse, luxury, or leisure spending with overspend warnings',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isEssential,
                              activeColor: const Color(0xFF16A34A),
                              onChanged: (val) => setDialogState(() => isEssential = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('Theme Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: colorOptions.map((c) {
                        final isSel = selectedColor == c;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(c),
                            child: isSel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final newCat = FinancialCategory(
                      id: 'cat-${_uuid.v4().substring(0, 8)}',
                      name: name,
                      type: selectedType,
                      iconName: selectedType == 'expense' ? 'category' : 'payments',
                      colorValue: selectedColor,
                      isEssential: isEssential,
                    );

                    LocalDatabase.instance.addCategory(newCat);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Create Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openSetBudgetDialog(FinancialCategory category, Budget? existingBudget) {
    final amountCtrl = TextEditingController(
      text: existingBudget != null
          ? MoneyFormatter.formatKobo(existingBudget.allocatedKobo).replaceAll('₦', '').trim()
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Set Monthly Budget\n${category.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target Period: $_currentPeriod',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  labelText: 'Allocated Budget',
                  prefixText: '₦ ',
                  hintText: '50,000.00',
                ),
              ),
              const SizedBox(height: 12),
              if (!category.isEssential)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Non-essential category: strict warnings will trigger upon exceeding this allocation.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            if (existingBudget != null)
              TextButton(
                onPressed: () {
                  LocalDatabase.instance.deleteBudget(existingBudget.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Remove Budget', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final kobo = MoneyFormatter.parseToKobo(amountCtrl.text);
                if (kobo <= 0) return;

                final budget = Budget(
                  id: existingBudget?.id ?? 'b-${_uuid.v4().substring(0, 8)}',
                  categoryId: category.id,
                  periodMonthYear: _currentPeriod,
                  allocatedKobo: kobo,
                );

                LocalDatabase.instance.upsertBudget(budget);
                Navigator.pop(ctx);
              },
              child: const Text('Save Budget'),
            ),
          ],
        );
      },
    );
  }

  void _openAddOrEditIncomeSourceDialog({IncomeSource? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final expectedCtrl = TextEditingController(
      text: existing != null ? (existing.expectedMonthlyKobo / 100).toStringAsFixed(0) : '',
    );
    final receivedCtrl = TextEditingController(
      text: existing != null ? (existing.receivedKobo / 100).toStringAsFixed(0) : '0',
    );
    final accounts = LocalDatabase.instance.getFinancialAccounts();
    final workspaces = LocalDatabase.instance.getWorkspaces();

    String selectedAccountId = existing?.accountId ?? (accounts.isNotEmpty ? accounts.first.id : 'acc-gtb');
    String? selectedWorkspaceId = existing?.workspaceId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.trending_up, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    existing == null ? 'Add Income Stream' : 'Edit Income Stream',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Income Source Name',
                        hintText: 'e.g. Consulting, Executive Salary, Dividends',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: expectedCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Target / Budget (₦)',
                        hintText: 'e.g. 500,000',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: receivedCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Received This Month (₦)',
                        hintText: 'e.g. 250,000',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Destination Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedAccountId = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Workspace Link (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String?>(
                      value: selectedWorkspaceId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All / Personal')),
                        ...workspaces.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedWorkspaceId = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton(
                    onPressed: () {
                      LocalDatabase.instance.deleteIncomeSource(existing.id);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final expKobo = MoneyFormatter.parseToKobo(expectedCtrl.text);
                    final recKobo = MoneyFormatter.parseToKobo(receivedCtrl.text);

                    final src = IncomeSource(
                      id: existing?.id ?? 'inc-${const Uuid().v4().substring(0, 8)}',
                      name: name,
                      accountId: selectedAccountId,
                      expectedMonthlyKobo: expKobo,
                      receivedKobo: recKobo,
                      workspaceId: selectedWorkspaceId,
                    );

                    LocalDatabase.instance.upsertIncomeSource(src);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Source'),
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
        final categories = db.getFinancialCategories().where((c) => c.type == 'expense').toList();
        final budgets = db.getBudgets(periodMonthYear: _currentPeriod);
        final totalAllocatedKobo = budgets.fold<int>(0, (sum, b) => sum + b.allocatedKobo);
        final totalSpentKobo = db.getMonthTotalExpenseKobo(periodMonthYear: _currentPeriod);
        final unnecessarySpendKobo = db.getUnnecessarySpendKobo(periodMonthYear: _currentPeriod);
        final overspendingBudgets = db.getOverspendingBudgets(periodMonthYear: _currentPeriod);

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              title: const Text('Budgets & Income Streams'),
              bottom: const TabBar(
                labelColor: AppTheme.coralPrimary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.coralPrimary,
                tabs: [
                  Tab(text: 'Expense Budgets'),
                  Tab(text: 'Income Streams'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_chart, color: Color(0xFF10B981)),
                  tooltip: 'Add Income Stream',
                  onPressed: () => _openAddOrEditIncomeSourceDialog(),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.coralPrimary),
                  tooltip: 'Add Expense Category',
                  onPressed: _openAddCategoryDialog,
                ),
              ],
            ),
            body: TabBarView(
              children: [
                // Tab 1: Expense Budgets
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  children: [
              // Hero Budget Gradient Card
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.sunsetMesh,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.heroFloatShadow,
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BUDGET OVERVIEW • $_currentPeriod',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
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
                          child: Text(
                            totalSpentKobo > totalAllocatedKobo && totalAllocatedKobo > 0
                                ? 'OVER BUDGET'
                                : 'ACTIVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Spent',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            PrivacyBlurWrapper(
                              child: Text(
                                MoneyFormatter.formatKobo(totalSpentKobo),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Total Budget',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            PrivacyBlurWrapper(
                              child: Text(
                                MoneyFormatter.formatKobo(totalAllocatedKobo),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Global Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: totalAllocatedKobo > 0
                            ? (totalSpentKobo / totalAllocatedKobo).clamp(0.0, 1.0)
                            : 0.0,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          totalSpentKobo > totalAllocatedKobo
                              ? const Color(0xFFFF453A)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Overspending Warnings Banner
              if (overspendingBudgets.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF87171), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'OVERSPEND WARNING (${overspendingBudgets.length})',
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...overspendingBudgets.map((b) {
                        final cat = categories.firstWhere(
                          (c) => c.id == b.categoryId,
                          orElse: () => FinancialCategory(
                            id: b.categoryId,
                            name: 'Category',
                            type: 'expense',
                            iconName: 'category',
                            colorValue: 0xFFEF4444,
                          ),
                        );
                        final overAmount = b.spentKobo - b.allocatedKobo;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• ${cat.name}: Exceeded by ${MoneyFormatter.formatKobo(overAmount)} (${b.percentUsed.toStringAsFixed(0)}% used)',
                            style: const TextStyle(
                              color: Color(0xFF7F1D1D),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Unnecessary/Discretionary Spending Warning
              if (unnecessarySpendKobo > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Non-Essential Spending Notice',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'You have spent ${MoneyFormatter.formatKobo(unnecessarySpendKobo)} on discretionary/impulse items this month. Review your non-essential limits.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Category Budget Allocation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Category Budgets & Limits',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16, color: AppTheme.coralPrimary),
                    label: const Text('Category', style: TextStyle(color: AppTheme.coralPrimary, fontWeight: FontWeight.bold)),
                    onPressed: _openAddCategoryDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Categories List with Progress and Edit
              ...categories.map((cat) {
                final budget = budgets.cast<Budget?>().firstWhere(
                      (b) => b?.categoryId == cat.id,
                      orElse: () => null,
                    );

                final spentKobo = db.getCategorySpentKobo(cat.id, periodMonthYear: _currentPeriod);
                final allocatedKobo = budget?.allocatedKobo ?? 0;
                final isOver = allocatedKobo > 0 && spentKobo > allocatedKobo;
                final pct = allocatedKobo > 0 ? (spentKobo / allocatedKobo).clamp(0.0, 1.0) : 0.0;

                Color progressColor;
                if (isOver) {
                  progressColor = const Color(0xFFEF4444);
                } else if (pct >= 0.8) {
                  progressColor = const Color(0xFFF59E0B);
                } else {
                  progressColor = const Color(0xFF10B981);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isOver
                        ? Border.all(color: const Color(0xFFFCA5A5), width: 1.5)
                        : null,
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(cat.colorValue).withOpacity(0.15),
                            child: Icon(
                              _getCategoryIcon(cat.iconName),
                              color: Color(cat.colorValue),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      cat.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: cat.isEssential
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        cat.isEssential ? 'ESSENTIAL' : 'DISCRETIONARY',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: cat.isEssential
                                              ? const Color(0xFF2E7D32)
                                              : const Color(0xFFE65100),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  allocatedKobo > 0
                                      ? 'Spent ${MoneyFormatter.formatKobo(spentKobo)} of ${MoneyFormatter.formatKobo(allocatedKobo)}'
                                      : 'Spent ${MoneyFormatter.formatKobo(spentKobo)} (No budget set)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOver ? const Color(0xFFDC2626) : AppTheme.textSecondary,
                                    fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note, color: AppTheme.textSecondary),
                                tooltip: 'Set Budget',
                                onPressed: () => _openSetBudgetDialog(cat, budget),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textSecondary),
                                onSelected: (action) {
                                  if (action == 'budget') {
                                    _openSetBudgetDialog(cat, budget);
                                  } else if (action == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: const Text('Delete Category?'),
                                        content: Text('Are you sure you want to delete "${cat.name}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFEF4444),
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () {
                                              LocalDatabase.instance.deleteFinancialCategory(cat.id);
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'budget',
                                    child: Row(
                                      children: [
                                        Icon(Icons.savings_outlined, size: 16),
                                        SizedBox(width: 8),
                                        Text('Set Budget'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete Category', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (allocatedKobo > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${((spentKobo / allocatedKobo) * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: progressColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),

          // Tab 2: Income Streams & Revenue Targets
          _buildIncomeStreamsTab(context, db),
        ],
      ),
    ),
  );
      },
    );
  }

  Widget _buildIncomeStreamsTab(BuildContext context, LocalDatabase db) {
    final incomeSources = db.getIncomeSources();
    final totalExpectedKobo = incomeSources.fold<int>(0, (sum, s) => sum + s.expectedMonthlyKobo);
    final totalReceivedKobo = incomeSources.fold<int>(0, (sum, s) => sum + s.receivedKobo);
    final overallPct = totalExpectedKobo > 0 ? (totalReceivedKobo / totalExpectedKobo).clamp(0.0, 1.0) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // Hero Inflow Gradient Card
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppTheme.heroFloatShadow,
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'REVENUE & INFLOW OVERVIEW',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
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
                    child: Text(
                      '${(overallPct * 100).toInt()}% ACHIEVED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  PrivacyBlurWrapper(
                    child: Text(
                      MoneyFormatter.formatKobo(totalReceivedKobo),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'of ${MoneyFormatter.formatKobo(totalExpectedKobo)} target',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: overallPct,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section Title & Add Stream Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Income Streams',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            ElevatedButton.icon(
              onPressed: () => _openAddOrEditIncomeSourceDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Source', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (incomeSources.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'No income streams registered yet. Tap "Add Source" above.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...incomeSources.map((source) {
            final acc = db.getFinancialAccounts().firstWhere(
                  (a) => a.id == source.accountId,
                  orElse: () => db.getFinancialAccounts().first,
                );
            final ws = source.workspaceId != null ? db.getWorkspaceById(source.workspaceId!) : null;
            final pct = source.expectedMonthlyKobo > 0
                ? (source.receivedKobo / source.expectedMonthlyKobo).clamp(0.0, 1.0)
                : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.payments_rounded, color: Color(0xFF16A34A), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    source.name,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${acc.name} • ${ws?.name ?? "General"}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: AppTheme.textSecondary),
                        tooltip: 'Edit Source',
                        onPressed: () => _openAddOrEditIncomeSourceDialog(existing: source),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PrivacyBlurWrapper(
                        child: Text(
                          'Received: ${MoneyFormatter.formatKobo(source.receivedKobo)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                      ),
                      PrivacyBlurWrapper(
                        child: Text(
                          'Budget: ${MoneyFormatter.formatKobo(source.expectedMonthlyKobo)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'bolt':
        return Icons.bolt;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'movie':
        return Icons.movie;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'payments':
        return Icons.payments;
      case 'business_center':
        return Icons.business_center;
      default:
        return Icons.category;
    }
  }
}
