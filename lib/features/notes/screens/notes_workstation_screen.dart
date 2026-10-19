import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../models/note_ui_extensions.dart';
import 'note_editor_screen.dart';

class NotesWorkstationScreen extends StatefulWidget {
  final NoteCategory? initialCategory;

  const NotesWorkstationScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<NotesWorkstationScreen> createState() => _NotesWorkstationScreenState();
}

class _NotesWorkstationScreenState extends State<NotesWorkstationScreen> {
  NoteCategory? _selectedCategory;
  String _searchQuery = '';
  String? _selectedTag;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor({OmniNote? note, NoteCategory? category}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          existingNote: note,
          initialCategory: category ?? _selectedCategory ?? NoteCategory.spiritual,
        ),
      ),
    );
  }

  void _toggleChecklistItem(OmniNote note, String uncheckedItem) {
    // Replace '- [ ] item' with '- [x] item' or vice versa
    final isChecked = uncheckedItem.startsWith('- [x] ') || uncheckedItem.startsWith('* [x] ');
    final target = isChecked
        ? uncheckedItem.replaceFirst('[x]', '[ ]')
        : uncheckedItem.replaceFirst('[ ]', '[x]');

    final updatedContent = note.content.replaceFirst(uncheckedItem, target);
    final updatedNote = note.copyWith(
      content: updatedContent,
      updatedAt: DateTime.now(),
    );

    LocalDatabase.instance.upsertNote(updatedNote);
  }

  void _confirmDeleteNote(OmniNote note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Note?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${note.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              LocalDatabase.instance.deleteNote(note.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${note.title}"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _convertNoteToTask(OmniNote note) {
    final task = LocalDatabase.instance.convertNoteToTask(note.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Converted "${task.title}" to an active Task!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
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
        final allNotes = db.getNotes(category: _selectedCategory);

        // Filter by search query and tag
        final filteredNotes = allNotes.where((note) {
          final matchesSearch = _searchQuery.isEmpty ||
              note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (note.scriptureReference?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (note.subCategory?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              note.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));

          final matchesTag = _selectedTag == null || note.tags.contains(_selectedTag);

          return matchesSearch && matchesTag;
        }).toList();

        final pinnedNotes = filteredNotes.where((n) => n.isPinned).toList();
        final regularNotes = filteredNotes.where((n) => !n.isPinned).toList();

        // Extract all unique tags across the database
        final allTags = <String>{};
        for (final n in db.getNotes()) {
          allTags.addAll(n.tags);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes & Revelations Hub',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Spiritual • Bible Study • Vision • Executive',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                tooltip: 'Quick Sync Remote',
                icon: const Icon(Icons.sync, color: AppTheme.coralPrimary),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Syncing notes with Cloud Supabase & Render...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(category: _selectedCategory),
            backgroundColor: AppTheme.coralPrimary,
            icon: const Icon(Icons.note_add, color: Colors.white),
            label: Text(
              _selectedCategory == null
                  ? 'New Note'
                  : 'New ${_selectedCategory!.displayName}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          body: Column(
            children: [
              // Top Search Bar & Domain Filters Container
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search notes, scriptures, dreams, visions, tags...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Domain Categories Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryFilterChip(
                            label: 'All (${db.getNotes().length})',
                            isSelected: _selectedCategory == null,
                            icon: Icons.all_inbox,
                            color: AppTheme.darkCharcoal,
                            onTap: () {
                              setState(() {
                                _selectedCategory = null;
                              });
                            },
                          ),
                          ...NoteCategory.values.map((cat) {
                            final count = db.getNotes(category: cat).length;
                            return _buildCategoryFilterChip(
                              label: '${cat.displayName} ($count)',
                              isSelected: _selectedCategory == cat,
                              icon: cat.icon,
                              color: _getCategoryAccent(cat),
                              onTap: () {
                                setState(() {
                                  _selectedCategory = _selectedCategory == cat ? null : cat;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),

                    // Tag Filter Chips (if any exist)
                    if (allTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text('Tags: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ...allTags.map((tag) {
                              final isSelected = _selectedTag == tag;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: ActionChip(
                                  label: Text(tag, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                                  backgroundColor: isSelected ? AppTheme.colorHenovate : Colors.grey.shade200,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(2),
                                  onPressed: () {
                                    setState(() {
                                      _selectedTag = isSelected ? null : tag;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: AppTheme.dividerColor),

              // Notes List or Empty State
              Expanded(
                child: filteredNotes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedCategory?.icon ?? Icons.notes_outlined,
                                size: 56,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No notes matching "$_searchQuery"'
                                    : 'No notes in ${_selectedCategory?.displayName ?? 'this station'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap "+ New Note" below to capture prophetic revelations, bible studies, strategy blueprints, or executive directives.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Pinned Section
                          if (pinnedNotes.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.push_pin, size: 16, color: Colors.amber),
                                const SizedBox(width: 6),
                                Text(
                                  'PINNED & CRITICAL (${pinnedNotes.length})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...pinnedNotes.map((n) => _buildNoteCard(n)),
                            const SizedBox(height: 16),
                          ],

                          // Regular Notes Section
                          if (regularNotes.isNotEmpty) ...[
                            if (pinnedNotes.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  'ALL ACTIVE ENTRIES',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ...regularNotes.map((n) => _buildNoteCard(n)),
                          ],

                          const SizedBox(height: 70), // Padding for FAB
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.blueGrey.shade800),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryAccent(NoteCategory cat) {
    switch (cat) {
      case NoteCategory.spiritual:
        return const Color(0xFF6B21A8);
      case NoteCategory.bibleStudy:
        return const Color(0xFF0F766E);
      case NoteCategory.visionStrategy:
        return const Color(0xFF1D4ED8);
      case NoteCategory.professional:
        return const Color(0xFF1F2937);
      case NoteCategory.relationships:
        return const Color(0xFF9D174D);
      case NoteCategory.personal:
        return const Color(0xFFC2410C);
    }
  }

  Widget _buildNoteCard(OmniNote note) {
    final hasScripture = note.scriptureReference != null && note.scriptureReference!.isNotEmpty;
    final hasSubCategory = note.subCategory != null && note.subCategory!.isNotEmpty;
    final cardColor = Color(note.colorValue);

    // Extract any checklist items from markdown
    final lines = note.content.split('\n');
    final checklistLines = lines.where((l) =>
        l.trim().startsWith('- [ ]') ||
        l.trim().startsWith('- [x]') ||
        l.trim().startsWith('* [ ]') ||
        l.trim().startsWith('* [x]')).toList();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: note.isPinned ? Colors.amber.shade300 : Colors.grey.shade200,
          width: note.isPinned ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _openEditor(note: note),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Ribbon
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Row: Category + Subcategory + Pinned + Menu
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(note.category.icon, size: 12, color: cardColor),
                            const SizedBox(width: 4),
                            Text(
                              note.category.displayName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasSubCategory) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            note.subCategory!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade800,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 18,
                          color: note.isPinned ? Colors.amber.shade800 : Colors.grey,
                        ),
                        onPressed: () {
                          LocalDatabase.instance.toggleNotePin(note.id);
                        },
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                        onSelected: (val) {
                          if (val == 'task') {
                            _convertNoteToTask(note);
                          } else if (val == 'copy') {
                            Clipboard.setData(ClipboardData(text: '# ${note.title}\n\n${note.content}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Note copied to clipboard!')),
                            );
                          } else if (val == 'delete') {
                            _confirmDeleteNote(note);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'task',
                            child: Row(
                              children: [
                                Icon(Icons.add_task, size: 18, color: AppTheme.colorHenovate),
                                SizedBox(width: 8),
                                Text('Convert to Task'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'copy',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 18, color: Colors.blueGrey),
                                SizedBox(width: 8),
                                Text('Copy Markdown'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Note', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Scripture Badge if any
                  if (hasScripture) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book, size: 13, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(
                            note.scriptureReference!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Title
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Content Snippet (non-checklist text)
                  Text(
                    note.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  // Inline Interactive Checklist (if any markdown checkboxes exist)
                  if (checklistLines.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: checklistLines.take(3).map((line) {
                          final isChecked = line.contains('[x]');
                          final cleanText = line
                              .replaceFirst('- [ ]', '')
                              .replaceFirst('- [x]', '')
                              .replaceFirst('* [ ]', '')
                              .replaceFirst('* [x]', '')
                              .trim();

                          return InkWell(
                            onTap: () => _toggleChecklistItem(note, line),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  Icon(
                                    isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                                    size: 16,
                                    color: isChecked ? Colors.green : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      cleanText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        decoration: isChecked ? TextDecoration.lineThrough : null,
                                        color: isChecked ? Colors.grey : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Tags Row & Linked Task Badge
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Tags
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          children: note.tags.map((t) {
                            return Text(
                              t,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blueGrey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Task conversion button or indicator
                      if (note.linkedTaskId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.task_alt, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Linked Task ✓',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _convertNoteToTask(note),
                          icon: const Icon(Icons.add_task, size: 12),
                          label: const Text('To Task', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.coralPrimary,
                            side: const BorderSide(color: AppTheme.coralPrimary, width: 0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
