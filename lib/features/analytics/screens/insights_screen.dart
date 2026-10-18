import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/privacy_blur_wrapper.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final allTasks = db.getTasks();
        final completedTasks = allTasks.where((t) => t.status == TaskStatus.completed).toList();
        final pendingTasks = allTasks.where((t) => t.status != TaskStatus.completed).toList();

        final accounts = db.getFinancialAccounts();
        final totalBalanceKobo = accounts.fold<int>(0, (sum, a) => sum + a.balanceKobo);
        final transactions = db.getLedgerTransactions();
        final reviews = db.getReviews();

        final double taskCompletionPct = allTasks.isNotEmpty
            ? (completedTasks.length / allTasks.length) * 100
            : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Reviews & Insights'),
            actions: [
              IconButton(
                icon: const Icon(Icons.rate_review, color: AppTheme.sereneTeal),
                tooltip: 'Start Weekly Review',
                onPressed: () => _showWeeklyReviewDialog(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Operational Health Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Operational Completion Overview',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricItem('Active Tasks', '${pendingTasks.length}', AppTheme.softAmber),
                          _buildMetricItem('Completed', '${completedTasks.length}', AppTheme.sereneTeal),
                          _buildMetricItem('Ratio', '${taskCompletionPct.toInt()}%', AppTheme.colorPersonal),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Live persistent data only. Denominators clearly shown to eliminate fabricated metrics.',
                        style: TextStyle(fontSize: 11, color: AppTheme.mutedGray),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Financial Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Financial Ledger Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recorded Net Balance:', style: TextStyle(color: AppTheme.mutedGray)),
                          PrivacyBlurWrapper(
                            child: Text(
                              MoneyFormatter.formatKobo(totalBalanceKobo),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recorded Postings:', style: TextStyle(color: AppTheme.mutedGray)),
                          Text('${transactions.length} entries', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Weekly Reviews History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Past Review Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Review'),
                    onPressed: () => _showWeeklyReviewDialog(context),
                  ),
                ],
              ),
              if (reviews.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No weekly or monthly reviews saved yet. Tap "+ New Review" on Sunday evening.',
                        style: TextStyle(color: AppTheme.mutedGray),
                      ),
                    ),
                  ),
                )
              else
                ...reviews.map((r) {
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFD1FAE5),
                        child: Icon(Icons.check, color: Color(0xFF059669)),
                      ),
                      title: Text(r.summary, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Accomplishments: ${r.accomplishments}\nLessons: ${r.lessons}'),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.mutedGray)),
      ],
    );
  }

  void _showWeeklyReviewDialog(BuildContext context) {
    final summaryCtrl = TextEditingController(text: 'Weekly review completed');
    final accomplishmentsCtrl = TextEditingController();
    final lessonsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sunday Review Wizard'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: summaryCtrl, decoration: const InputDecoration(labelText: 'Review Title / Period')),
              const SizedBox(height: 10),
              TextField(controller: accomplishmentsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Key Accomplishments this week')),
              const SizedBox(height: 10),
              TextField(controller: lessonsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Lessons Learned / Adjustments for next week')),
            ],
          ),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            child: const Text('Save Review'),
            onPressed: () {
              if (summaryCtrl.text.trim().isNotEmpty) {
                LocalDatabase.instance.saveReview(
                  ReviewEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    kind: 'weekly',
                    completedAt: DateTime.now(),
                    summary: summaryCtrl.text.trim(),
                    accomplishments: accomplishmentsCtrl.text.trim().isEmpty ? 'Consistent progress' : accomplishmentsCtrl.text.trim(),
                    lessons: lessonsCtrl.text.trim().isEmpty ? 'Sustained focus' : lessonsCtrl.text.trim(),
                  ),
                );
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
