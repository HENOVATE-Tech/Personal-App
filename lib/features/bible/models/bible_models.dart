enum Testament { oldTestament, newTestament }

enum BibleDivision {
  law,
  history,
  poetryAndWisdom,
  majorProphets,
  minorProphets,
  gospels,
  churchHistory,
  paulineEpistles,
  generalEpistles,
  prophecy,
}

class BibleBook {
  final String id;
  final String name;
  final String shortName;
  final Testament testament;
  final BibleDivision division;
  final int totalChapters;

  const BibleBook({
    required this.id,
    required this.name,
    required this.shortName,
    required this.testament,
    required this.division,
    required this.totalChapters,
  });

  String get divisionLabel {
    switch (division) {
      case BibleDivision.law:
        return 'The Law (Pentateuch)';
      case BibleDivision.history:
        return 'Historical Books';
      case BibleDivision.poetryAndWisdom:
        return 'Poetry & Wisdom';
      case BibleDivision.majorProphets:
        return 'Major Prophets';
      case BibleDivision.minorProphets:
        return 'Minor Prophets';
      case BibleDivision.gospels:
        return 'The Gospels';
      case BibleDivision.churchHistory:
        return 'Church History';
      case BibleDivision.paulineEpistles:
        return "Paul's Epistles";
      case BibleDivision.generalEpistles:
        return 'General Epistles';
      case BibleDivision.prophecy:
        return 'Prophecy';
    }
  }
}

class BibleVerse {
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String translation;

  const BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.translation = 'KJV',
  });

  String get reference => '$book $chapter:$verse';

  String toFormattedQuote() {
    return '> "$text"\n> — $book $chapter:$verse ($translation)';
  }

  Map<String, dynamic> toJson() => {
        'book': book,
        'chapter': chapter,
        'verse': verse,
        'text': text,
        'translation': translation,
      };

  factory BibleVerse.fromJson(Map<String, dynamic> json) => BibleVerse(
        book: json['book'] as String? ?? '',
        chapter: (json['chapter'] as num?)?.toInt() ?? 1,
        verse: (json['verse'] as num?)?.toInt() ?? 1,
        text: json['text'] as String? ?? '',
        translation: json['translation'] as String? ?? 'KJV',
      );
}

class BibleChapterData {
  final String book;
  final int chapter;
  final String translation;
  final List<BibleVerse> verses;

  const BibleChapterData({
    required this.book,
    required this.chapter,
    this.translation = 'KJV',
    required this.verses,
  });

  String get reference => '$book $chapter';
}

class CuratedScriptureTheme {
  final String id;
  final String title;
  final String subtitle;
  final String categoryTag;
  final List<BibleVerse> verses;

  const CuratedScriptureTheme({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categoryTag,
    required this.verses,
  });
}
