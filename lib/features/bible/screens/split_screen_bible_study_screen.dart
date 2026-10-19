import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../models/bible_models.dart';
import '../services/bible_service.dart';

class SplitScreenBibleStudyScreen extends StatefulWidget {
  final String? initialBook;
  final int? initialChapter;
  final BibleVerse? initialVerse;
  final OmniNote? existingNote;

  const SplitScreenBibleStudyScreen({
    super.key,
    this.initialBook,
    this.initialChapter,
    this.initialVerse,
    this.existingNote,
  });

  @override
  State<SplitScreenBibleStudyScreen> createState() => _SplitScreenBibleStudyScreenState();
}

class _SplitScreenBibleStudyScreenState extends State<SplitScreenBibleStudyScreen> {
  // Bible Reader State
  late BibleBook _currentBook;
  late int _currentChapter;
  BibleChapterData? _chapterData;
  BibleVerse? _selectedVerse;
  bool _isLoadingBible = false;

  // Study Note Editor State
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _scriptureCtrl;
  late final TextEditingController _tagCtrl;
  late List<String> _tags;
  late NoteCategory _category;
  String? _noteId;

  // View mode for mobile
  int _mobileTab = 0; // 0 = Bible, 1 = Note

  @override
  void initState() {
    super.initState();
    final defaultBook = BibleService.instance.findBook(widget.initialBook ?? widget.initialVerse?.book ?? 'Proverbs') ??
        BibleService.instance.books.firstWhere((b) => b.id == 'proverbs');
    _currentBook = defaultBook;
    _currentChapter = widget.initialChapter ?? widget.initialVerse?.chapter ?? 3;
    _selectedVerse = widget.initialVerse;

    // Initialize Study Note
    final note = widget.existingNote;
    _noteId = note?.id ?? 'note-study-${DateTime.now().millisecondsSinceEpoch}';
    _titleCtrl = TextEditingController(
      text: note?.title ?? (widget.initialVerse != null ? 'Study: ${widget.initialVerse!.reference}' : 'Bible Study: ${_currentBook.name} $_currentChapter'),
    );
    _contentCtrl = TextEditingController(
      text: note?.content ?? (widget.initialVerse != null ? '${widget.initialVerse!.toFormattedQuote()}\n\n### Key Exegesis & Revelation:\n- \n\n### Practical Life Application:\n- ' : '### Key Exegesis & Revelation:\n- \n\n### Practical Life Application:\n- '),
    );
    _scriptureCtrl = TextEditingController(
      text: note?.scriptureReference ?? (widget.initialVerse?.reference ?? '${_currentBook.name} $_currentChapter'),
    );
    _tagCtrl = TextEditingController();
    _tags = List<String>.from(note?.tags ?? ['#BibleStudy', '#Word']);
    _category = note?.category ?? NoteCategory.bibleStudy;

    _loadBibleChapter();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _scriptureCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBibleChapter() async {
    setState(() => _isLoadingBible = true);
    final data = await BibleService.instance.getChapter(
      bookName: _currentBook.name,
      chapter: _currentChapter,
    );
    if (mounted) {
      setState(() {
        _chapterData = data;
        _isLoadingBible = false;
      });
    }
  }

  void _insertVerseIntoNote(BibleVerse verse) {
    final quote = '\n\n${verse.toFormattedQuote()}\n\n';
    final currentText = _contentCtrl.text;
    _contentCtrl.text = currentText + quote;
    _scriptureCtrl.text = '${_scriptureCtrl.text.isEmpty ? '' : '${_scriptureCtrl.text}, '}${verse.reference}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inserted ${verse.reference} into study note!'),
        backgroundColor: const Color(0xFF4C1D95),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Switch to note tab on mobile if currently on Bible tab
    if (_mobileTab == 0 && MediaQuery.of(context).size.width < 720) {
      setState(() => _mobileTab = 1);
    }
  }

  void _saveStudyNote() {
    final title = _titleCtrl.text.trim().isEmpty ? 'Bible Study: ${_currentBook.name} $_currentChapter' : _titleCtrl.text.trim();
    final note = OmniNote(
      id: _noteId!,
      title: title,
      content: _contentCtrl.text.trim(),
      category: _category,
      scriptureReference: _scriptureCtrl.text.trim(),
      tags: _tags,
      isPinned: true,
      colorValue: 0xFF065F46, // Emerald green for Bible Study
      createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    LocalDatabase.instance.upsertNote(note);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${note.title}" to Notes Workstation!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _convertVerseToTask(BibleVerse verse) {
    final taskTitle = 'Scripture Action: ${verse.reference}';
    final taskNote = '"${verse.text}"\n\nCommitment Application: ';
    final task = Task(
      id: 'task-scripture-${DateTime.now().millisecondsSinceEpoch}',
      workspaceId: 'ws-personal',
      title: taskTitle,
      notes: taskNote,
      status: TaskStatus.scheduled,
      importance: TaskImportance.high,
      scheduledDate: DateTime.now(),
      createdAt: DateTime.now(),
    );
    LocalDatabase.instance.upsertTask(task);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Created life commitment task: "${task.title}"!'),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.vertical_split_rounded, size: 14, color: Color(0xFF7E22CE)),
                  SizedBox(width: 4),
                  Text('Split-Screen Bible Study', style: TextStyle(color: Color(0xFF7E22CE), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 16, color: Colors.white),
            label: const Text('Save Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF065F46),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saveStudyNote,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  // Left Pane: Bible Reader
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(right: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: _buildBibleReaderPane(),
                    ),
                  ),

                  // Right Pane: Study Note Pad
                  Expanded(
                    flex: 5,
                    child: _buildStudyNotePane(),
                  ),
                ],
              )
            : Column(
                children: [
                  // Mobile Mode Switcher
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.menu_book, size: 16),
                                const SizedBox(width: 6),
                                Text('📖 Bible (${_currentBook.name} $_currentChapter)'),
                              ],
                            ),
                            selected: _mobileTab == 0,
                            selectedColor: const Color(0xFF4C1D95),
                            labelStyle: TextStyle(
                              color: _mobileTab == 0 ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setState(() => _mobileTab = 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_note, size: 16),
                                SizedBox(width: 6),
                                Text('✍️ Study Note'),
                              ],
                            ),
                            selected: _mobileTab == 1,
                            selectedColor: const Color(0xFF065F46),
                            labelStyle: TextStyle(
                              color: _mobileTab == 1 ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setState(() => _mobileTab = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Mobile Active Pane
                  Expanded(
                    child: _mobileTab == 0 ? _buildBibleReaderPane() : _buildStudyNotePane(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBibleReaderPane() {
    return Column(
      children: [
        // Book & Chapter Controls Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFFAF5FF),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<BibleBook>(
                value: _currentBook,
                underline: const SizedBox(),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF4C1D95)),
                items: BibleService.instance.books.map((b) {
                  return DropdownMenuItem(
                    value: b,
                    child: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  );
                }).toList(),
                onChanged: (b) {
                  if (b != null) {
                    setState(() {
                      _currentBook = b;
                      _currentChapter = 1;
                    });
                    _loadBibleChapter();
                  }
                },
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: _currentChapter > 1
                        ? () {
                            setState(() => _currentChapter--);
                            _loadBibleChapter();
                          }
                        : null,
                  ),
                  Text(
                    'Ch $_currentChapter / ${_currentBook.totalChapters}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6B21A8)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: _currentChapter < _currentBook.totalChapters
                        ? () {
                            setState(() => _currentChapter++);
                            _loadBibleChapter();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE9D5FF)),

        // Verses List
        Expanded(
          child: _isLoadingBible
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4C1D95)))
              : (_chapterData == null || _chapterData!.verses.isEmpty)
                  ? Center(child: Text('No verses found for ${_currentBook.name} $_currentChapter'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _chapterData!.verses.length,
                      itemBuilder: (context, index) {
                        final verse = _chapterData!.verses[index];
                        final isSelected = _selectedVerse?.verse == verse.verse;

                        return InkWell(
                          onTap: () {
                            setState(() => _selectedVerse = isSelected ? null : verse);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected ? Border.all(color: const Color(0xFFC084FC)) : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
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
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Georgia',
                                          height: 1.55,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.arrow_downward, size: 14, color: Colors.white),
                                        label: const Text('⬇ Insert to Note', style: TextStyle(fontSize: 11, color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF7E22CE),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                        onPressed: () => _insertVerseIntoNote(verse),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.task_alt, size: 14),
                                        label: const Text('🎯 Commit to Task', style: TextStyle(fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF0D9488),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                        onPressed: () => _convertVerseToTask(verse),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStudyNotePane() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Input
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Note Title / Theme...',
              border: InputBorder.none,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // Scripture Anchor Pill
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _scriptureCtrl,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.auto_stories, size: 16, color: Color(0xFF065F46)),
                    labelText: 'Passage Anchor(s)',
                    labelStyle: const TextStyle(fontSize: 11),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFECFDF5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Content Markdown Field
          Expanded(
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(
                hintText: 'Write revelations, exegesis, prayer insights, or click "Insert to Note" from any verse on the Bible pane...',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
