import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../models/bible_models.dart';
import '../services/bible_service.dart';
import 'split_screen_bible_study_screen.dart';

class BibleReaderScreen extends StatefulWidget {
  final String? initialBook;
  final int? initialChapter;

  const BibleReaderScreen({
    super.key,
    this.initialBook,
    this.initialChapter,
  });

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  late BibleBook _currentBook;
  late int _currentChapter;
  bool _isLoading = false;
  BibleChapterData? _chapterData;
  BibleVerse? _selectedVerse;

  // Typography settings
  double _fontSize = 17.0;
  bool _isSerif = true;

  @override
  void initState() {
    super.initState();
    final defaultBook = BibleService.instance.findBook(widget.initialBook ?? 'Proverbs') ??
        BibleService.instance.books.firstWhere((b) => b.id == 'proverbs');
    _currentBook = defaultBook;
    _currentChapter = widget.initialChapter ?? 3;
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    setState(() {
      _isLoading = true;
      _selectedVerse = null;
    });

    final data = await BibleService.instance.getChapter(
      bookName: _currentBook.name,
      chapter: _currentChapter,
    );

    if (mounted) {
      setState(() {
        _chapterData = data;
        _isLoading = false;
      });
    }
  }

  void _previousChapter() {
    if (_currentChapter > 1) {
      setState(() => _currentChapter--);
      _loadChapter();
    }
  }

  void _nextChapter() {
    if (_currentChapter < _currentBook.totalChapters) {
      setState(() => _currentChapter++);
      _loadChapter();
    }
  }

  void _showBookPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookPickerSheet(
        selectedBook: _currentBook,
        onBookSelected: (book) {
          setState(() {
            _currentBook = book;
            _currentChapter = 1;
          });
          _loadChapter();
        },
      ),
    );
  }

  void _showChapterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Chapter (${_currentBook.name})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _currentBook.totalChapters,
                  itemBuilder: (context, index) {
                    final ch = index + 1;
                    final isCurrent = ch == _currentChapter;

                    return InkWell(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        setState(() => _currentChapter = ch);
                        _loadChapter();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF4C1D95) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$ch',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _convertVerseToTask(BibleVerse verse) {
    showDialog(
      context: context,
      builder: (ctx) {
        final titleCtrl = TextEditingController(text: 'Apply Scripture: ${verse.reference}');
        final noteCtrl = TextEditingController(text: '"${verse.text}"\n\nAction Commitment: ');
        String selectedWorkspace = 'ws-personal';

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.assignment_turned_in, color: Color(0xFF4C1D95)),
              SizedBox(width: 8),
              Text('Convert to Life Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Task Title', isDense: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Scripture & Practical Steps', isDense: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedWorkspace,
                  decoration: const InputDecoration(labelText: 'Target Workspace', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'ws-personal', child: Text('Personal & Spiritual')),
                    DropdownMenuItem(value: 'ws-bems', child: Text('Bems Group (COO)')),
                    DropdownMenuItem(value: 'ws-henovate', child: Text('Henovate (Founder)')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedWorkspace = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C1D95),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final db = LocalDatabase.instance;
                final task = Task(
                  id: 'task-scripture-${DateTime.now().millisecondsSinceEpoch}',
                  workspaceId: selectedWorkspace,
                  title: titleCtrl.text.trim(),
                  notes: noteCtrl.text.trim(),
                  status: TaskStatus.scheduled,
                  importance: TaskImportance.high,
                  scheduledDate: DateTime.now(),
                  createdAt: DateTime.now(),
                );
                db.upsertTask(task);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created task "${task.title}"!'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save Commitment'),
            ),
          ],
        );
      },
    );
  }

  void _openSplitStudy(BibleVerse? verse) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SplitScreenBibleStudyScreen(
          initialBook: _currentBook.name,
          initialChapter: _currentChapter,
          initialVerse: verse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF9), // Clean Warm Paper background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: InkWell(
          onTap: _showBookPicker,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentBook.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF4C1D95)),
              ],
            ),
          ),
        ),
        actions: [
          // Chapter Quick Picker Pill
          TextButton(
            onPressed: _showChapterPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'Ch $_currentChapter / ${_currentBook.totalChapters}',
                style: const TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),

          // Split Study Button
          IconButton(
            tooltip: 'Split-Screen Bible Study',
            icon: const Icon(Icons.vertical_split_rounded, color: Color(0xFF4C1D95)),
            onPressed: () => _openSplitStudy(_selectedVerse),
          ),

          // Typography Settings Modal
          IconButton(
            tooltip: 'Reader Typography',
            icon: const Icon(Icons.text_fields_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => StatefulBuilder(
                  builder: (ctx, setModalState) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      height: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Typography & Reader Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Font Size'),
                              Slider(
                                value: _fontSize,
                                min: 14,
                                max: 26,
                                divisions: 6,
                                label: '${_fontSize.toInt()}',
                                activeColor: const Color(0xFF4C1D95),
                                onChanged: (val) {
                                  setModalState(() => _fontSize = val);
                                  setState(() => _fontSize = val);
                                },
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Font Family'),
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(value: true, label: Text('Serif (Classic)')),
                                  ButtonSegment(value: false, label: Text('Sans (Modern)')),
                                ],
                                selected: {_isSerif},
                                onSelectionChanged: (val) {
                                  setModalState(() => _isSerif = val.first);
                                  setState(() => _isSerif = val.first);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chapter Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    label: const Text('Prev Ch'),
                    style: TextButton.styleFrom(foregroundColor: _currentChapter > 1 ? const Color(0xFF4C1D95) : Colors.grey),
                    onPressed: _currentChapter > 1 ? _previousChapter : null,
                  ),
                  Text(
                    '${_currentBook.name} $_currentChapter (KJV)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    label: const Text('Next Ch'),
                    style: TextButton.styleFrom(
                      foregroundColor: _currentChapter < _currentBook.totalChapters ? const Color(0xFF4C1D95) : Colors.grey,
                    ),
                    onPressed: _currentChapter < _currentBook.totalChapters ? _nextChapter : null,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Scripture Verses Canvas
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF4C1D95)),
                          SizedBox(height: 12),
                          Text('Opening holy scriptures...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    )
                  : (_chapterData == null || _chapterData!.verses.isEmpty)
                      ? Center(
                          child: Text(
                            'Could not load ${_currentBook.name} $_currentChapter.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                          itemCount: _chapterData!.verses.length,
                          itemBuilder: (context, index) {
                            final verse = _chapterData!.verses[index];
                            final isSelected = _selectedVerse?.verse == verse.verse;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedVerse = isSelected ? null : verse;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected ? Border.all(color: const Color(0xFFC084FC)) : null,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 26,
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '${verse.verse}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isSelected ? const Color(0xFF7E22CE) : AppTheme.coralPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        verse.text,
                                        style: TextStyle(
                                          fontSize: _fontSize,
                                          fontFamily: _isSerif ? 'Georgia' : null,
                                          height: 1.6,
                                          color: isSelected ? const Color(0xFF3B0764) : const Color(0xFF1E293B),
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),

      // Bottom Floating Action Sheet when a verse is tapped
      bottomSheet: _selectedVerse == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedVerse!.reference,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF4C1D95)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _selectedVerse = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.vertical_split, size: 16),
                            label: const Text('Study Mode'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4C1D95),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _openSplitStudy(_selectedVerse),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_task, size: 16),
                            label: const Text('To Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _convertVerseToTask(_selectedVerse!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Copy Verse',
                          icon: const Icon(Icons.copy, color: AppTheme.textSecondary),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _selectedVerse!.toFormattedQuote()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied ${_selectedVerse!.reference} to clipboard!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BookPickerSheet extends StatefulWidget {
  final BibleBook selectedBook;
  final ValueChanged<BibleBook> onBookSelected;

  const _BookPickerSheet({
    required this.selectedBook,
    required this.onBookSelected,
  });

  @override
  State<_BookPickerSheet> createState() => _BookPickerSheetState();
}

class _BookPickerSheetState extends State<_BookPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.selectedBook.testament == Testament.newTestament) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBooks = BibleService.instance.books;
    final otBooks = allBooks.where((b) => b.testament == Testament.oldTestament && b.name.toLowerCase().contains(_filter.toLowerCase())).toList();
    final ntBooks = allBooks.where((b) => b.testament == Testament.newTestament && b.name.toLowerCase().contains(_filter.toLowerCase())).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Choose Book', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _filter = v),
              decoration: InputDecoration(
                hintText: 'Filter books (e.g. Genesis, Romans)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF4C1D95),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF4C1D95),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Old Testament (39)'),
              Tab(text: 'New Testament (27)'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBooksList(otBooks),
                _buildBooksList(ntBooks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList(List<BibleBook> bookList) {
    if (bookList.isEmpty) {
      return const Center(child: Text('No books matched search.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookList.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        final b = bookList[index];
        final isSelected = b.id == widget.selectedBook.id;

        return ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: isSelected ? const Color(0xFFF3E8FF) : null,
          title: Text(
            b.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF4C1D95) : AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            '${b.divisionLabel} • ${b.totalChapters} Chapters',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF4C1D95), size: 18) : null,
          onTap: () {
            Navigator.of(context).pop();
            widget.onBookSelected(b);
          },
        );
      },
    );
  }
}
