import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../models/bible_models.dart';
import '../services/bible_service.dart';

class ScripturePickerDialog extends StatefulWidget {
  final Function(BibleVerse verse, bool asQuoteBlock) onVerseSelected;

  const ScripturePickerDialog({
    super.key,
    required this.onVerseSelected,
  });

  @override
  State<ScripturePickerDialog> createState() => _ScripturePickerDialogState();
}

class _ScripturePickerDialogState extends State<ScripturePickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<BibleVerse> _searchResults = [];
  bool _isLoading = false;
  String? _selectedThemeId;

  @override
  void initState() {
    super.initState();
    // Default to first theme
    _selectedThemeId = BibleService.instance.curatedThemes.first.id;
    _searchResults = BibleService.instance.curatedThemes.first.verses;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        final currentTheme = BibleService.instance.curatedThemes.firstWhere(
          (t) => t.id == _selectedThemeId,
          orElse: () => BibleService.instance.curatedThemes.first,
        );
        _searchResults = currentTheme.verses;
      });
      return;
    }

    // Check offline search
    final offlineMatches = BibleService.instance.searchVerses(clean);
    setState(() {
      _searchResults = offlineMatches;
    });

    // If looks like a reference (has numbers or colons) and offline results are few, try online lookup
    if (clean.contains(RegExp(r'\d')) && offlineMatches.length < 2) {
      setState(() => _isLoading = true);
      final remoteMatch = await BibleService.instance.lookupReference(clean);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (remoteMatch != null && !_searchResults.any((v) => v.reference == remoteMatch.reference)) {
            _searchResults = [remoteMatch, ..._searchResults];
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themes = BibleService.instance.curatedThemes;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_stories, color: Color(0xFF4C1D95), size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Insert Holy Scripture',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search passage (e.g. Prov 3:5, Jer 29:11, Favor, Wisdom)...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF4C1D95)),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4C1D95)),
                        ),
                      )
                    : (_searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Curated Theme Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: themes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final theme = themes[index];
                final isSelected = _selectedThemeId == theme.id && _searchController.text.isEmpty;

                return ChoiceChip(
                  label: Text(
                    theme.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF4C1D95),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (selected) {
                    if (selected) {
                      _searchController.clear();
                      setState(() {
                        _selectedThemeId = theme.id;
                        _searchResults = theme.verses;
                      });
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Results List
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No scriptures matched "${_searchController.text}"',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try entering a book & chapter (e.g. "Psalm 23" or "Rom 8:28")',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final verse = _searchResults[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  verse.reference,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF6B21A8),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9D5FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    verse.translation,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF581C87),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"${verse.text}"',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.bookmark_border, size: 14),
                                  label: const Text('Set as Anchor', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6B21A8),
                                    side: const BorderSide(color: Color(0xFFD8B4FE)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                  onPressed: () {
                                    widget.onVerseSelected(verse, false);
                                    Navigator.of(context).pop();
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.format_quote, size: 14, color: Colors.white),
                                  label: const Text('Insert Quote Block', style: TextStyle(fontSize: 11, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7E22CE),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  onPressed: () {
                                    widget.onVerseSelected(verse, true);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
