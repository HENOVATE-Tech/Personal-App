import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../bible/widgets/scripture_picker_dialog.dart';
import '../../bible/screens/split_screen_bible_study_screen.dart';
import '../models/note_ui_extensions.dart';

class NoteEditorScreen extends StatefulWidget {
  final OmniNote? existingNote;
  final NoteCategory? initialCategory;

  const NoteEditorScreen({
    super.key,
    this.existingNote,
    this.initialCategory,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _scriptureController;
  late final TextEditingController _subCategoryController;
  late final TextEditingController _tagInputController;

  late NoteCategory _selectedCategory;
  late List<String> _tags;
  late bool _isPinned;
  late int _selectedColorValue;
  String? _linkedTaskId;

  static const List<int> _paletteOptions = [
    0xFF1E293B, // Obsidian Slate
    0xFF4C1D95, // Royal Purple / Spiritual
    0xFF065F46, // Emerald Covenant
    0xFF1E3A8A, // Deep Blue Strategy
    0xFF9A3412, // Sunset Amber
    0xFF831843, // Rose Ruby
  ];

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _scriptureController = TextEditingController(text: note?.scriptureReference ?? '');
    _subCategoryController = TextEditingController(text: note?.subCategory ?? '');
    _tagInputController = TextEditingController();

    _selectedCategory = note?.category ?? widget.initialCategory ?? NoteCategory.spiritual;
    _tags = List<String>.from(note?.tags ?? []);
    _isPinned = note?.isPinned ?? false;
    _selectedColorValue = note?.colorValue ?? _getDefaultColorForCategory(_selectedCategory);
    _linkedTaskId = note?.linkedTaskId;
  }

  int _getDefaultColorForCategory(NoteCategory cat) {
    switch (cat) {
      case NoteCategory.spiritual:
        return 0xFF4C1D95; // Royal Purple
      case NoteCategory.bibleStudy:
        return 0xFF065F46; // Emerald Green
      case NoteCategory.visionStrategy:
        return 0xFF1E3A8A; // Sapphire Navy
      case NoteCategory.professional:
        return 0xFF1E293B; // Slate Graphite
      case NoteCategory.relationships:
        return 0xFF831843; // Rose
      case NoteCategory.personal:
        return 0xFF9A3412; // Warm Amber
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scriptureController.dispose();
    _subCategoryController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _tagInputController.text.trim();
    if (text.isNotEmpty) {
      var formatted = text.startsWith('#') ? text : '#$text';
      if (!_tags.contains(formatted)) {
        setState(() {
          _tags.add(formatted);
          _tagInputController.clear();
        });
      }
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _insertMarkdownSnippet(String prefix, [String suffix = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final selectedText = text.substring(start, end);
    final replacement = '$prefix$selectedText$suffix';

    final newText = text.replaceRange(start, end, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note cannot be completely empty.')),
      );
      return;
    }

    final id = widget.existingNote?.id ?? 'note-${DateTime.now().millisecondsSinceEpoch}';
    final note = OmniNote(
      id: id,
      workspaceId: widget.existingNote?.workspaceId ?? 'ws-personal',
      title: title.isEmpty ? 'Untitled Note' : title,
      content: content,
      category: _selectedCategory,
      subCategory: _subCategoryController.text.trim().isNotEmpty
          ? _subCategoryController.text.trim()
          : null,
      tags: _tags,
      scriptureReference: _scriptureController.text.trim().isNotEmpty
          ? _scriptureController.text.trim()
          : null,
      isPinned: _isPinned,
      colorValue: _selectedColorValue,
      linkedTaskId: _linkedTaskId,
      createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    LocalDatabase.instance.upsertNote(note);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${note.title}" to ${note.category.displayName}'),
          backgroundColor: AppTheme.colorHenovate,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(note);
    }
  }

  Future<void> _convertToTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title before converting to a task.')),
      );
      return;
    }

    // Save note first if not saved
    final id = widget.existingNote?.id ?? 'note-${DateTime.now().millisecondsSinceEpoch}';
    final note = OmniNote(
      id: id,
      workspaceId: widget.existingNote?.workspaceId ?? 'ws-personal',
      title: title,
      content: _contentController.text.trim(),
      category: _selectedCategory,
      subCategory: _subCategoryController.text.trim().isNotEmpty
          ? _subCategoryController.text.trim()
          : null,
      tags: _tags,
      scriptureReference: _scriptureController.text.trim().isNotEmpty
          ? _scriptureController.text.trim()
          : null,
      isPinned: _isPinned,
      colorValue: _selectedColorValue,
      linkedTaskId: _linkedTaskId,
      createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    LocalDatabase.instance.upsertNote(note);
    final task = LocalDatabase.instance.convertNoteToTask(id);
    setState(() {
      _linkedTaskId = task.id;
    });
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Task Created!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This note has been connected directly to your execution system as an active task:',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Next Action: ${task.nextAction}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Awesome'),
            ),
          ],
        ),
      );
    }
  }

  void _openScripturePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScripturePickerDialog(
        onVerseSelected: (verse, asQuoteBlock) {
          if (asQuoteBlock) {
            final quote = '\n\n${verse.toFormattedQuote()}\n\n';
            _contentController.text = _contentController.text + quote;
          }
          _scriptureController.text = verse.reference;
          setState(() {});
        },
      ),
    );
  }

  void _openSplitStudy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SplitScreenBibleStudyScreen(
          existingNote: widget.existingNote,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSpiritualOrBible = _selectedCategory == NoteCategory.spiritual ||
        _selectedCategory == NoteCategory.bibleStudy;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.existingNote == null ? 'Create Note' : 'Edit Note',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Insert Holy Scripture',
            icon: const Icon(Icons.auto_stories, color: Color(0xFF4C1D95)),
            onPressed: _openScripturePicker,
          ),
          if (isSpiritualOrBible)
            IconButton(
              tooltip: 'Split-Screen Bible Study',
              icon: const Icon(Icons.vertical_split_rounded, color: Color(0xFF065F46)),
              onPressed: _openSplitStudy,
            ),
          IconButton(
            tooltip: _isPinned ? 'Unpin Note' : 'Pin Note',
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? Colors.amber.shade800 : AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isPinned = !_isPinned;
              });
            },
          ),
          IconButton(
            tooltip: 'Convert Note to Actionable Task',
            icon: Icon(
              _linkedTaskId != null ? Icons.task_alt : Icons.add_task,
              color: _linkedTaskId != null ? Colors.green : AppTheme.colorHenovate,
            ),
            onPressed: _convertToTask,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Domain / Category Selector Cards
            const Text(
              'NOTE DOMAIN & STATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: NoteCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 16,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat.displayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      selectedColor: Color(_selectedColorValue),
                      backgroundColor: Colors.white,
                      elevation: isSelected ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = cat;
                            _selectedColorValue = _getDefaultColorForCategory(cat);
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Color Palette Selector
            Row(
              children: [
                const Text(
                  'Card Accent:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 8),
                ..._paletteOptions.map((colorHex) {
                  final isSelected = _selectedColorValue == colorHex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorValue = colorHex;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(colorHex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Color(colorHex).withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
                            : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Sub-Category / Watch Marker & Scripture anchors
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subCategoryController,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: isSpiritualOrBible ? 'Subcategory / Watch (e.g. 3:15 AM Dream, Exegesis)' : 'Subcategory / Project (e.g. Executive SOP, Q3 Goals)',
                            labelStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.category_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isSpiritualOrBible) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _scriptureController,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Scripture Anchor (e.g. Habakkuk 2:2-3, Joel 2:28)',
                        labelStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.menu_book_outlined, size: 18, color: Colors.teal),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, size: 18, color: Color(0xFF4C1D95)),
                          tooltip: 'Search & Pick Scripture',
                          onPressed: _openScripturePicker,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.format_quote, size: 14, color: Color(0xFF4C1D95)),
                          label: const Text('Insert Holy Scripture into Note', style: TextStyle(fontSize: 11, color: Color(0xFF4C1D95), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFC084FC)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: _openScripturePicker,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Note Title Input
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Note Title...',
                hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Markdown Snippet Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildToolButton(
                      label: 'Checklist',
                      icon: Icons.check_box_outlined,
                      onTap: () => _insertMarkdownSnippet('\n- [ ] '),
                    ),
                    _buildToolButton(
                      label: 'Bullet',
                      icon: Icons.format_list_bulleted,
                      onTap: () => _insertMarkdownSnippet('\n* '),
                    ),
                    _buildToolButton(
                      label: 'Header',
                      icon: Icons.title,
                      onTap: () => _insertMarkdownSnippet('\n### '),
                    ),
                    _buildToolButton(
                      label: 'Quote',
                      icon: Icons.format_quote,
                      onTap: () => _insertMarkdownSnippet('\n> '),
                    ),
                    _buildToolButton(
                      label: 'Bold',
                      icon: Icons.format_bold,
                      onTap: () => _insertMarkdownSnippet('**', '**'),
                    ),
                    _buildToolButton(
                      label: 'Verse Highlight',
                      icon: Icons.lightbulb_outline,
                      onTap: () => _insertMarkdownSnippet('\n> *"'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Note Body Content
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 12,
              style: const TextStyle(fontSize: 15, height: 1.5, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Record details, prophetic insights, scriptures, blueprints, or action checklists...\n\nExample checklist:\n- [ ] Intercede for vision\n- [ ] Prepare blueprint document',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tag Management
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TAGS & METADATA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ..._tags.map(
                        (tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          backgroundColor: Colors.grey.shade100,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => _removeTag(tag),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagInputController,
                          onSubmitted: (_) => _addTag(),
                          decoration: InputDecoration(
                            hintText: 'Add tag (e.g. #revelation, #venture, #sabbath)',
                            hintStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            prefixIcon: const Icon(Icons.tag, size: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addTag,
                        icon: const Icon(Icons.add_circle, color: AppTheme.coralPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Task Connection Status if already linked
            if (_linkedTaskId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Directly converted to Task ID: $_linkedTaskId (Active in Workspaces)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15, color: Colors.blueGrey.shade700),
        label: Text(label, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
