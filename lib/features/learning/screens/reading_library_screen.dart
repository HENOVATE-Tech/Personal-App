import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';

class ReadingLibraryScreen extends StatelessWidget {
  const ReadingLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final books = db.getBooks();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Reading & Detail Checklist'),
              bottom: const TabBar(
                indicatorColor: AppTheme.sereneTeal,
                tabs: [
                  Tab(text: 'Reading Library'),
                  Tab(text: 'Pre-Flight Checklist'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // 1. Reading Library Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Books & Study Material', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Book'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sereneTeal, foregroundColor: Colors.white),
                          onPressed: () => _showAddBookDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (books.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No books in your library yet. Tap "+ Add Book" to track reading goals.',
                              style: TextStyle(color: AppTheme.mutedGray),
                            ),
                          ),
                        ),
                      )
                    else
                      ...books.map((b) {
                        final progress = b.totalPages > 0 ? (b.currentPage / b.totalPages) : 0.0;
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFEF3C7),
                              child: Icon(Icons.book, color: Color(0xFFD97706)),
                            ),
                            title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${b.author} • ${b.format.toUpperCase()}'),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  color: AppTheme.sereneTeal,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Page ${b.currentPage} of ${b.totalPages} (${(progress * 100).toInt()}%)',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.mutedGray),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.bookmark_add, color: AppTheme.sereneTeal),
                              onPressed: () => _showUpdateProgressDialog(context, b, db),
                            ),
                          ),
                        );
                      }),
                  ],
                ),

                // 2. Pre-Deliverable Detail Review Checklist Tab (FR-LN-05)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Card(
                      color: Color(0xFFEFF6FF),
                      child: Padding(
                        padding: EdgeInsets.all(14.0),
                        child: Text(
                          'Pre-Deliverable Quality Checklist (FR-LN-05): Before releasing significant deliverables, '
                          'client proposals, or financial reports, verify all items below.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistTile('Mathematical & Calculation Accuracy: Verify sum formulas, minor units, and balances.'),
                    _buildChecklistTile('Completeness: All requested deliverables and appendices attached.'),
                    _buildChecklistTile('Dates & Names: Recipient titles, organization entities, and timeline accuracy.'),
                    _buildChecklistTile('Proofreading & Grammar: Free of spelling, phrasing, or typographical errors.'),
                    _buildChecklistTile('Offline Verification: Functioning without network dependency where applicable.'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChecklistTile(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.sereneTeal, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBookDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final pagesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Book to Library'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Book Title')),
            const SizedBox(height: 10),
            TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author')),
            const SizedBox(height: 10),
            TextField(controller: pagesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Pages')),
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            child: const Text('Add'),
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                final pages = int.tryParse(pagesCtrl.text) ?? 200;
                LocalDatabase.instance.upsertBook(
                  Book(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleCtrl.text.trim(),
                    author: authorCtrl.text.trim().isEmpty ? 'Unknown' : authorCtrl.text.trim(),
                    totalPages: pages,
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

  void _showUpdateProgressDialog(BuildContext context, Book b, LocalDatabase db) {
    final pageCtrl = TextEditingController(text: b.currentPage.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Progress: ${b.title}'),
        content: TextField(
          controller: pageCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Current Page (Max ${b.totalPages})'),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            child: const Text('Update'),
            onPressed: () {
              final newPage = int.tryParse(pageCtrl.text) ?? b.currentPage;
              db.upsertBook(b.copyWith(currentPage: newPage.clamp(0, b.totalPages)));
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
