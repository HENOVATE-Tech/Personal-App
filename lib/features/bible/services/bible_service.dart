import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bible_models.dart';

class BibleService {
  BibleService._();
  static final BibleService instance = BibleService._();

  // In-memory cache for fetched chapters (Key: "$book-$chapter-$translation")
  final Map<String, BibleChapterData> _chapterCache = {};

  // All 66 Books of the Holy Bible
  final List<BibleBook> books = const [
    // Old Testament - Law (Pentateuch)
    BibleBook(id: 'genesis', name: 'Genesis', shortName: 'Gen', testament: Testament.oldTestament, division: BibleDivision.law, totalChapters: 50),
    BibleBook(id: 'exodus', name: 'Exodus', shortName: 'Exo', testament: Testament.oldTestament, division: BibleDivision.law, totalChapters: 40),
    BibleBook(id: 'leviticus', name: 'Leviticus', shortName: 'Lev', testament: Testament.oldTestament, division: BibleDivision.law, totalChapters: 27),
    BibleBook(id: 'numbers', name: 'Numbers', shortName: 'Num', testament: Testament.oldTestament, division: BibleDivision.law, totalChapters: 36),
    BibleBook(id: 'deuteronomy', name: 'Deuteronomy', shortName: 'Deu', testament: Testament.oldTestament, division: BibleDivision.law, totalChapters: 34),

    // History
    BibleBook(id: 'joshua', name: 'Joshua', shortName: 'Jos', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 24),
    BibleBook(id: 'judges', name: 'Judges', shortName: 'Jdg', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 21),
    BibleBook(id: 'ruth', name: 'Ruth', shortName: 'Rth', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 4),
    BibleBook(id: '1samuel', name: '1 Samuel', shortName: '1Sa', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 31),
    BibleBook(id: '2samuel', name: '2 Samuel', shortName: '2Sa', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 24),
    BibleBook(id: '1kings', name: '1 Kings', shortName: '1Ki', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 22),
    BibleBook(id: '2kings', name: '2 Kings', shortName: '2Ki', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 25),
    BibleBook(id: '1chronicles', name: '1 Chronicles', shortName: '1Ch', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 29),
    BibleBook(id: '2chronicles', name: '2 Chronicles', shortName: '2Ch', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 36),
    BibleBook(id: 'ezra', name: 'Ezra', shortName: 'Ezr', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 10),
    BibleBook(id: 'nehemiah', name: 'Nehemiah', shortName: 'Neh', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 13),
    BibleBook(id: 'esther', name: 'Esther', shortName: 'Est', testament: Testament.oldTestament, division: BibleDivision.history, totalChapters: 10),

    // Poetry & Wisdom
    BibleBook(id: 'job', name: 'Job', shortName: 'Job', testament: Testament.oldTestament, division: BibleDivision.poetryAndWisdom, totalChapters: 42),
    BibleBook(id: 'psalms', name: 'Psalms', shortName: 'Psa', testament: Testament.oldTestament, division: BibleDivision.poetryAndWisdom, totalChapters: 150),
    BibleBook(id: 'proverbs', name: 'Proverbs', shortName: 'Pro', testament: Testament.oldTestament, division: BibleDivision.poetryAndWisdom, totalChapters: 31),
    BibleBook(id: 'ecclesiastes', name: 'Ecclesiastes', shortName: 'Ecc', testament: Testament.oldTestament, division: BibleDivision.poetryAndWisdom, totalChapters: 12),
    BibleBook(id: 'songofsolomon', name: 'Song of Solomon', shortName: 'Son', testament: Testament.oldTestament, division: BibleDivision.poetryAndWisdom, totalChapters: 8),

    // Major Prophets
    BibleBook(id: 'isaiah', name: 'Isaiah', shortName: 'Isa', testament: Testament.oldTestament, division: BibleDivision.majorProphets, totalChapters: 66),
    BibleBook(id: 'jeremiah', name: 'Jeremiah', shortName: 'Jer', testament: Testament.oldTestament, division: BibleDivision.majorProphets, totalChapters: 52),
    BibleBook(id: 'lamentations', name: 'Lamentations', shortName: 'Lam', testament: Testament.oldTestament, division: BibleDivision.majorProphets, totalChapters: 5),
    BibleBook(id: 'ezekiel', name: 'Ezekiel', shortName: 'Eze', testament: Testament.oldTestament, division: BibleDivision.majorProphets, totalChapters: 48),
    BibleBook(id: 'daniel', name: 'Daniel', shortName: 'Dan', testament: Testament.oldTestament, division: BibleDivision.majorProphets, totalChapters: 12),

    // Minor Prophets
    BibleBook(id: 'hosea', name: 'Hosea', shortName: 'Hos', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 14),
    BibleBook(id: 'joel', name: 'Joel', shortName: 'Joe', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 3),
    BibleBook(id: 'amos', name: 'Amos', shortName: 'Amo', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 9),
    BibleBook(id: 'obadiah', name: 'Obadiah', shortName: 'Oba', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 1),
    BibleBook(id: 'jonah', name: 'Jonah', shortName: 'Jon', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 4),
    BibleBook(id: 'micah', name: 'Micah', shortName: 'Mic', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 7),
    BibleBook(id: 'nahum', name: 'Nahum', shortName: 'Nah', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 3),
    BibleBook(id: 'habakkuk', name: 'Habakkuk', shortName: 'Hab', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 3),
    BibleBook(id: 'zephaniah', name: 'Zephaniah', shortName: 'Zep', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 3),
    BibleBook(id: 'haggai', name: 'Haggai', shortName: 'Hag', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 2),
    BibleBook(id: 'zechariah', name: 'Zechariah', shortName: 'Zec', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 14),
    BibleBook(id: 'malachi', name: 'Malachi', shortName: 'Mal', testament: Testament.oldTestament, division: BibleDivision.minorProphets, totalChapters: 4),

    // New Testament - Gospels
    BibleBook(id: 'matthew', name: 'Matthew', shortName: 'Mat', testament: Testament.newTestament, division: BibleDivision.gospels, totalChapters: 28),
    BibleBook(id: 'mark', name: 'Mark', shortName: 'Mrk', testament: Testament.newTestament, division: BibleDivision.gospels, totalChapters: 16),
    BibleBook(id: 'luke', name: 'Luke', shortName: 'Luk', testament: Testament.newTestament, division: BibleDivision.gospels, totalChapters: 24),
    BibleBook(id: 'john', name: 'John', shortName: 'Jhn', testament: Testament.newTestament, division: BibleDivision.gospels, totalChapters: 21),

    // History
    BibleBook(id: 'acts', name: 'Acts', shortName: 'Act', testament: Testament.newTestament, division: BibleDivision.churchHistory, totalChapters: 28),

    // Pauline Epistles
    BibleBook(id: 'romans', name: 'Romans', shortName: 'Rom', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 16),
    BibleBook(id: '1corinthians', name: '1 Corinthians', shortName: '1Co', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 16),
    BibleBook(id: '2corinthians', name: '2 Corinthians', shortName: '2Co', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 13),
    BibleBook(id: 'galatians', name: 'Galatians', shortName: 'Gal', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 6),
    BibleBook(id: 'ephesians', name: 'Ephesians', shortName: 'Eph', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 6),
    BibleBook(id: 'philippians', name: 'Philippians', shortName: 'Php', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 4),
    BibleBook(id: 'colossians', name: 'Colossians', shortName: 'Col', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 4),
    BibleBook(id: '1thessalonians', name: '1 Thessalonians', shortName: '1Th', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 5),
    BibleBook(id: '2thessalonians', name: '2 Thessalonians', shortName: '2Th', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 3),
    BibleBook(id: '1timothy', name: '1 Timothy', shortName: '1Ti', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 6),
    BibleBook(id: '2timothy', name: '2 Timothy', shortName: '2Ti', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 4),
    BibleBook(id: 'titus', name: 'Titus', shortName: 'Tit', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 3),
    BibleBook(id: 'philemon', name: 'Philemon', shortName: 'Phm', testament: Testament.newTestament, division: BibleDivision.paulineEpistles, totalChapters: 1),

    // General Epistles
    BibleBook(id: 'hebrews', name: 'Hebrews', shortName: 'Heb', testament: Testament.newTestament, division: BibleDivision.generalEpistles, totalChapters: 13),
    BibleBook(id: 'james', name: 'James', shortName: 'Jas', testament: Testament.newTestament, division: BibleDivision.generalEpistles, totalChapters: 5),
    BibleBook(id: '1peter', name: '1 Peter', shortName: '1Pe', testament: Testament.newTestament, division: BibleDivision.generalEpistles, totalChapters: 5),
    BibleBook(id: '2peter', name: '2 Peter', shortName: '2Pe', testament: Testament.newTestament, division: BibleDivision.generalEpistles, totalChapters: 3),
    BibleBook(id: '1john', name: '1 John', shortName: '1Jn', testament: Testament.newTestament, division: BibleDivision.generalEpistles, totalChapters: 5),
    BibleBook(id: '2john', name: '2 John', shortName: '2Jn', testament: Testament.newTestament, division: BibleDivision.generalEpistles, totalChapters: 1),
    BibleBook(id: '3john', name: '3 John', shortName: '3Jn', testament: Testament.newTestament, division: BibleDivision.generalEpistles, totalChapters: 1),
    BibleBook(id: 'jude', name: 'Jude', shortName: 'Jud', testament: Testament.newTestament, division: BibleDivision.generalEpistles, totalChapters: 1),

    // Prophecy
    BibleBook(id: 'revelation', name: 'Revelation', shortName: 'Rev', testament: Testament.newTestament, division: BibleDivision.prophecy, totalChapters: 22),
  ];

  // Curated Themes with Instant Offline Key Verses
  final List<CuratedScriptureTheme> curatedThemes = const [
    CuratedScriptureTheme(
      id: 'wisdom_strategy',
      title: 'Wisdom & Strategic Governance',
      subtitle: 'Discernment, planning, and kingdom leadership',
      categoryTag: 'Wisdom',
      verses: [
        BibleVerse(book: 'Proverbs', chapter: 3, verse: 5, text: 'Trust in the LORD with all thine heart; and lean not unto thine own understanding.'),
        BibleVerse(book: 'Proverbs', chapter: 3, verse: 6, text: 'In all thy ways acknowledge him, and he shall direct thy paths.'),
        BibleVerse(book: 'Proverbs', chapter: 16, verse: 3, text: 'Commit thy works unto the LORD, and thy thoughts shall be established.'),
        BibleVerse(book: 'Proverbs', chapter: 24, verse: 3, text: 'Through wisdom is an house builded; and by understanding it is established:'),
        BibleVerse(book: 'Proverbs', chapter: 24, verse: 4, text: 'And by knowledge shall the chambers be filled with all precious and pleasant riches.'),
        BibleVerse(book: 'James', chapter: 1, verse: 5, text: 'If any of you lack wisdom, let him ask of God, that giveth to all men liberally, and upbraideth not; and it shall be given him.'),
        BibleVerse(book: 'Proverbs', chapter: 22, verse: 29, text: 'Seest thou a man diligent in his business? he shall stand before kings; he shall not stand before mean men.'),
      ],
    ),
    CuratedScriptureTheme(
      id: 'visions_dreams',
      title: 'Prophetic Visions & Revelations',
      subtitle: 'Writing the vision, discerning divine timing and dreams',
      categoryTag: 'Spiritual',
      verses: [
        BibleVerse(book: 'Habakkuk', chapter: 2, verse: 2, text: 'And the LORD answered me, and said, Write the vision, and make it plain upon tables, that he may run that readeth it.'),
        BibleVerse(book: 'Habakkuk', chapter: 2, verse: 3, text: 'For the vision is yet for an appointed time, but at the end it shall speak, and not lie: though it tarry, wait for it; because it will surely come, it will not tarry.'),
        BibleVerse(book: 'Joel', chapter: 2, verse: 28, text: 'And it shall come to pass afterward, that I will pour out my spirit upon all flesh; and your sons and your daughters shall prophesy, your old men shall dream dreams, your young men shall see visions:'),
        BibleVerse(book: 'Daniel', chapter: 2, verse: 22, text: 'He revealeth the deep and secret things: he knoweth what is in the darkness, and the light dwelleth with him.'),
        BibleVerse(book: 'Job', chapter: 33, verse: 14, text: 'For God speaketh once, yea twice, yet man perceiveth it not.'),
        BibleVerse(book: 'Job', chapter: 33, verse: 15, text: 'In a dream, in a vision of the night, when deep sleep falleth upon men, in slumberings upon the bed;'),
        BibleVerse(book: 'Job', chapter: 33, verse: 16, text: 'Then he openeth the ears of men, and sealeth their instruction,'),
      ],
    ),
    CuratedScriptureTheme(
      id: 'favor_covenant',
      title: 'Covenant, Favor & Wealth Creation',
      subtitle: 'Power to get wealth and supernatural favor with leaders',
      categoryTag: 'Covenant',
      verses: [
        BibleVerse(book: 'Deuteronomy', chapter: 8, verse: 18, text: 'But thou shalt remember the LORD thy God: for it is he that giveth thee power to get wealth, that he may establish his covenant which he sware unto thy fathers, as it is this day.'),
        BibleVerse(book: 'Psalms', chapter: 5, verse: 12, text: 'For thou, LORD, wilt bless the righteous; with favour wilt thou compass him as with a shield.'),
        BibleVerse(book: 'Psalms', chapter: 84, verse: 11, text: 'For the LORD God is a sun and shield: the LORD will give grace and glory: no good thing will he withhold from them that walk uprightly.'),
        BibleVerse(book: '2 Corinthians', chapter: 9, verse: 8, text: 'And God is able to make all grace abound toward you; that ye, always having all sufficiency in all things, may abound to every good work:'),
        BibleVerse(book: 'Philippians', chapter: 4, verse: 19, text: 'But my God shall supply all your need according to his riches in glory by Christ Jesus.'),
      ],
    ),
    CuratedScriptureTheme(
      id: 'fasting_prayer',
      title: 'Fasting, Intercession & Breakthrough',
      subtitle: 'Consecration, breaking yokes, and answered prayers',
      categoryTag: 'Devotion',
      verses: [
        BibleVerse(book: 'Isaiah', chapter: 58, verse: 6, text: 'Is not this the fast that I have chosen? to loose the bands of wickedness, to undo the heavy burdens, and to let the oppressed go free, and that ye break every yoke?'),
        BibleVerse(book: 'Isaiah', chapter: 58, verse: 8, text: 'Then shall thy light break forth as the morning, and thine health shall spring forth speedily: and thy righteousness shall go before thee; the glory of the LORD shall be thy rereward.'),
        BibleVerse(book: 'Matthew', chapter: 6, verse: 16, text: 'Moreover when ye fast, be not, as the hypocrites, of a sad countenance...'),
        BibleVerse(book: 'Matthew', chapter: 6, verse: 18, text: 'That thou appear not unto men to fast, but unto thy Father which is in secret: and thy Father, which seeth in secret, shall reward thee openly.'),
        BibleVerse(book: '2 Chronicles', chapter: 7, verse: 14, text: 'If my people, which are called by my name, shall humble themselves, and pray, and seek my face, and turn from their wicked ways; then will I hear from heaven, and will forgive their sin, and will heal their land.'),
      ],
    ),
    CuratedScriptureTheme(
      id: 'strength_peace',
      title: 'Strength, Peace & Focus',
      subtitle: 'Overcoming operational bottlenecks and mental overload',
      categoryTag: 'Peace',
      verses: [
        BibleVerse(book: 'Isaiah', chapter: 40, verse: 29, text: 'He giveth power to the faint; and to them that have no might he increaseth strength.'),
        BibleVerse(book: 'Isaiah', chapter: 40, verse: 31, text: 'But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.'),
        BibleVerse(book: 'Philippians', chapter: 4, verse: 6, text: 'Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God.'),
        BibleVerse(book: 'Philippians', chapter: 4, verse: 7, text: 'And the peace of God, which passeth all understanding, shall keep your hearts and minds through Christ Jesus.'),
        BibleVerse(book: 'Psalms', chapter: 91, verse: 1, text: 'He that dwelleth in the secret place of the most High shall abide under the shadow of the Almighty.'),
        BibleVerse(book: 'Psalms', chapter: 91, verse: 2, text: 'I will say of the LORD, He is my refuge and my fortress: my God; in him will I trust.'),
      ],
    ),
  ];

  /// Find a book by id or name
  BibleBook? findBook(String query) {
    final q = query.trim().toLowerCase();
    for (final b in books) {
      if (b.id == q || b.name.toLowerCase() == q || b.shortName.toLowerCase() == q) {
        return b;
      }
    }
    return null;
  }

  /// Get chapter content (online from bible-api.com with instant offline fallback & memory caching)
  Future<BibleChapterData> getChapter({
    required String bookName,
    required int chapter,
    String translation = 'kjv',
  }) async {
    final cacheKey = '$bookName-$chapter-${translation.toLowerCase()}';
    if (_chapterCache.containsKey(cacheKey)) {
      return _chapterCache[cacheKey]!;
    }

    try {
      // Query bible-api.com for the entire chapter
      final url = Uri.parse('https://bible-api.com/${Uri.encodeComponent(bookName)}+$chapter?translation=${translation.toLowerCase()}');
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawVerses = data['verses'] as List<dynamic>? ?? [];

        final verses = rawVerses.map((v) {
          final map = v as Map<String, dynamic>;
          return BibleVerse(
            book: bookName,
            chapter: (map['chapter'] as num?)?.toInt() ?? chapter,
            verse: (map['verse'] as num?)?.toInt() ?? 1,
            text: (map['text'] as String? ?? '').trim(),
            translation: translation.toUpperCase(),
          );
        }).toList();

        if (verses.isNotEmpty) {
          final chapterData = BibleChapterData(
            book: bookName,
            chapter: chapter,
            translation: translation.toUpperCase(),
            verses: verses,
          );
          _chapterCache[cacheKey] = chapterData;
          return chapterData;
        }
      }
    } catch (_) {
      // Fallback to offline curated or generated guide below
    }

    // Offline Fallback: Check if we have curated verses for this book and chapter
    final curated = <BibleVerse>[];
    for (final theme in curatedThemes) {
      for (final v in theme.verses) {
        if (v.book.toLowerCase() == bookName.toLowerCase() && v.chapter == chapter) {
          curated.add(v);
        }
      }
    }

    if (curated.isNotEmpty) {
      final data = BibleChapterData(
        book: bookName,
        chapter: chapter,
        translation: translation.toUpperCase(),
        verses: curated,
      );
      _chapterCache[cacheKey] = data;
      return data;
    }

    // Default placeholder chapter for offline reading when not pre-cached
    final fallbackVerses = List.generate(
      10,
      (index) => BibleVerse(
        book: bookName,
        chapter: chapter,
        verse: index + 1,
        text: 'The Word of God in $bookName $chapter:${index + 1}. (Connect to network to cache all verses of this chapter offline)',
        translation: translation.toUpperCase(),
      ),
    );

    final fallbackData = BibleChapterData(
      book: bookName,
      chapter: chapter,
      translation: translation.toUpperCase(),
      verses: fallbackVerses,
    );
    return fallbackData;
  }

  /// Search offline themes & cached scriptures by reference or keyword
  List<BibleVerse> searchVerses(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final results = <BibleVerse>[];
    final seen = <String>{};

    // 1. Search in all curated power themes
    for (final theme in curatedThemes) {
      for (final v in theme.verses) {
        final matchesRef = v.reference.toLowerCase().contains(clean);
        final matchesText = v.text.toLowerCase().contains(clean);
        final matchesTheme = theme.title.toLowerCase().contains(clean) || theme.categoryTag.toLowerCase().contains(clean);

        if (matchesRef || matchesText || matchesTheme) {
          if (!seen.contains(v.reference)) {
            seen.add(v.reference);
            results.add(v);
          }
        }
      }
    }

    // 2. Search in any cached chapters
    for (final chapter in _chapterCache.values) {
      for (final v in chapter.verses) {
        if (v.text.toLowerCase().contains(clean) || v.reference.toLowerCase().contains(clean)) {
          if (!seen.contains(v.reference)) {
            seen.add(v.reference);
            results.add(v);
          }
        }
      }
    }

    return results;
  }

  /// Parse a scripture reference string like "John 3:16" or "Proverbs 3:5-6" and fetch it
  Future<BibleVerse?> lookupReference(String reference, {String translation = 'kjv'}) async {
    final clean = reference.trim();
    if (clean.isEmpty) return null;

    // Check offline curated first
    for (final theme in curatedThemes) {
      for (final v in theme.verses) {
        if (v.reference.toLowerCase() == clean.toLowerCase()) {
          return v;
        }
      }
    }

    // Try online lookup via bible-api
    try {
      final url = Uri.parse('https://bible-api.com/${Uri.encodeComponent(clean)}?translation=${translation.toLowerCase()}');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawVerses = data['verses'] as List<dynamic>? ?? [];
        if (rawVerses.isNotEmpty) {
          final first = rawVerses.first as Map<String, dynamic>;
          final fullText = (data['text'] as String? ?? (first['text'] as String? ?? '')).trim();
          return BibleVerse(
            book: first['book_name'] as String? ?? clean.split(' ').first,
            chapter: (first['chapter'] as num?)?.toInt() ?? 1,
            verse: (first['verse'] as num?)?.toInt() ?? 1,
            text: fullText,
            translation: translation.toUpperCase(),
          );
        }
      }
    } catch (_) {}

    return null;
  }
}
