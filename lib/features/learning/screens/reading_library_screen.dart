import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../notes/screens/notes_workstation_screen.dart';

class ReadingLibraryScreen extends StatefulWidget {
  const ReadingLibraryScreen({super.key});

  @override
  State<ReadingLibraryScreen> createState() => _ReadingLibraryScreenState();
}

class _ReadingLibraryScreenState extends State<ReadingLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();
  String _bookFilter = 'all'; // 'all', 'reading', 'completed'

  final List<Map<String, dynamic>> _checklistItems = [
    {
      'id': 'chk-math',
      'title': 'Mathematical & Calculation Accuracy',
      'desc': 'Verify sum formulas, minor unit kobo rounding, and balance sheets.',
      'checked': false,
    },
    {
      'id': 'chk-complete',
      'title': 'Document Completeness & Appendices',
      'desc': 'All requested schedules, contracts, appendices, and quotes attached.',
      'checked': false,
    },
    {
      'id': 'chk-entities',
      'title': 'Dates, Names & Corporate Entities',
      'desc': 'Correct recipient designations (Bems Group / Henovate) and timeline alignment.',
      'checked': false,
    },
    {
      'id': 'chk-grammar',
      'title': 'Proofreading & Executive Phrasing',
      'desc': 'Free of typographical errors, clear active voice, and professional layout.',
      'checked': false,
    },
    {
      'id': 'chk-offline',
      'title': 'Offline Verification & PDF Integrity',
      'desc': 'Document opens without missing fonts, broken links, or remote dependencies.',
      'checked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddBookDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final pagesCtrl = TextEditingController(text: '250');
    String format = 'paperback';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Book to Executive Library',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Book Title',
                    hintText: 'e.g. High Output Management, The Effective Executive',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorCtrl,
                  decoration: InputDecoration(
                    labelText: 'Author',
                    hintText: 'e.g. Andrew S. Grove, Peter Drucker',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pagesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Total Pages',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: format,
                        decoration: InputDecoration(
                          labelText: 'Format',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'paperback', child: Text('📖 Physical Book')),
                          DropdownMenuItem(value: 'kindle', child: Text('📱 Kindle / eBook')),
                          DropdownMenuItem(value: 'audiobook', child: Text('🎧 Audiobook')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => format = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;

                    final pages = int.tryParse(pagesCtrl.text) ?? 200;
                    final book = Book(
                      id: 'book-${_uuid.v4().substring(0, 8)}',
                      title: title,
                      author: authorCtrl.text.trim().isEmpty ? 'Unknown' : authorCtrl.text.trim(),
                      totalPages: pages,
                      format: format,
                    );

                    LocalDatabase.instance.upsertBook(book);
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: const Text('Add to Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUpdateProgressDialog(BuildContext context, Book b, LocalDatabase db) {
    final pageCtrl = TextEditingController(text: b.currentPage.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Update Progress: ${b.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pageCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Current Page Reached (Out of ${b.totalPages})',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.note_add, size: 16),
                    label: const Text('Capture Note'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotesWorkstationScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkCharcoal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final newPage = int.tryParse(pageCtrl.text) ?? b.currentPage;
                      db.upsertBook(b.copyWith(currentPage: newPage.clamp(0, b.totalPages)));
                      Navigator.of(ctx).pop();
                      setState(() {});
                    },
                    child: const Text('Update Pages', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChecklistDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Custom Verification Check',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Checklist Criterion',
                hintText: 'e.g. Legal Signoff, Stakeholder Approval',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Guidance / Verification Details',
                hintText: 'e.g. Ensure managing partner signature is attached',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkCharcoal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                setState(() {
                  _checklistItems.add({
                    'id': 'chk-${DateTime.now().millisecondsSinceEpoch}',
                    'title': title,
                    'desc': descCtrl.text.trim(),
                    'checked': false,
                  });
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Add Checkpoint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final books = db.getBooks();

        final readingBooks = books.where((b) => b.currentPage < b.totalPages && b.currentPage > 0).toList();
        final completedBooks = books.where((b) => b.currentPage >= b.totalPages).toList();

        List<Book> displayedBooks = books;
        if (_bookFilter == 'reading') displayedBooks = readingBooks;
        if (_bookFilter == 'completed') displayedBooks = completedBooks;

        final checkedCount = _checklistItems.where((c) => c['checked'] == true).length;
        final double readinessPct = _checklistItems.isNotEmpty ? (checkedCount / _checklistItems.length) : 0.0;

        return Scaffold(
          backgroundColor: AppTheme.creamCanvas,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) {
              return [
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top + 16 : 56,
                      20,
                      18,
                    ),
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
                                  Icon(Icons.menu_book, size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Knowledge & Reviews',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Reading & Deliverable Quality',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Curated library study, reading progression & pre-deliverable review checklist',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 18),

                        // Pill TabBar
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: AppTheme.darkCharcoal,
                            unselectedLabelColor: Colors.white,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Reading Library 📚'),
                              Tab(text: 'Pre-Flight Checklist ✈️'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 1. Reading Library Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Books & Study Tracks',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkCharcoal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _showAddBookDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filter chips
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text('All (${books.length})'),
                          selected: _bookFilter == 'all',
                          selectedColor: AppTheme.darkCharcoal,
                          labelStyle: TextStyle(
                            color: _bookFilter == 'all' ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _bookFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('In Progress (${readingBooks.length})'),
                          selected: _bookFilter == 'reading',
                          selectedColor: AppTheme.darkCharcoal,
                          labelStyle: TextStyle(
                            color: _bookFilter == 'reading' ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _bookFilter = 'reading'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Completed (${completedBooks.length})'),
                          selected: _bookFilter == 'completed',
                          selectedColor: const Color(0xFF059669),
                          labelStyle: TextStyle(
                            color: _bookFilter == 'completed' ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _bookFilter = 'completed'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (displayedBooks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: AppTheme.floatingCardDecoration,
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.menu_book, size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              Text('No books found for this filter.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...displayedBooks.map((b) {
                        final progress = b.totalPages > 0 ? (b.currentPage / b.totalPages) : 0.0;
                        final isFinished = b.currentPage >= b.totalPages;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.floatingCardDecoration,
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isFinished ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isFinished ? Icons.check_circle : Icons.book,
                                  color: isFinished ? const Color(0xFF059669) : const Color(0xFFD97706),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.title,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.darkCharcoal),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${b.author} • ${b.format.toUpperCase()}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progress.clamp(0.0, 1.0),
                                      color: isFinished ? const Color(0xFF059669) : AppTheme.coralPrimary,
                                      backgroundColor: const Color(0xFFF3F4F6),
                                      minHeight: 5,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Page ${b.currentPage} of ${b.totalPages} (${(progress * 100).toInt()}%)',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.bookmark_border, color: AppTheme.coralPrimary),
                                tooltip: 'Update Page Progress',
                                onPressed: () => _showUpdateProgressDialog(context, b, db),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),

                // 2. Pre-Deliverable Detail Review Checklist Tab (FR-LN-05)
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Readiness Score Banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: readinessPct == 1.0
                              ? [const Color(0xFF065F46), const Color(0xFF059669)]
                              : [const Color(0xFF1E293B), const Color(0xFF334155)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.softCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                readinessPct == 1.0 ? '✓ Ready for Release' : 'Pre-Flight Readiness',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(readinessPct * 100).toInt()}% Verified',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            readinessPct == 1.0
                                ? 'All pre-flight criteria satisfied. You may release this proposal, deliverable, or report with full confidence.'
                                : '$checkedCount of ${_checklistItems.length} criteria satisfied. Verify remaining checkpoints before delivering to executive partners.',
                            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: readinessPct,
                            backgroundColor: Colors.white24,
                            color: readinessPct == 1.0 ? const Color(0xFF34D399) : AppTheme.coralPrimary,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verification Checkpoints',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.darkCharcoal),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16, color: AppTheme.coralPrimary),
                          label: const Text('Add Checkpoint', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.coralPrimary)),
                          onPressed: () => _showAddChecklistDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ..._checklistItems.map((chk) {
                      final isChecked = chk['checked'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.floatingCardDecoration,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isChecked,
                              activeColor: const Color(0xFF059669),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              onChanged: (val) {
                                setState(() {
                                  chk['checked'] = val ?? false;
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chk['title'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isChecked ? Colors.grey : AppTheme.darkCharcoal,
                                      decoration: isChecked ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    chk['desc'] as String,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
