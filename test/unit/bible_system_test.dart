import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/database/local_database.dart';
import 'package:personal_life_os/core/database/schema_models.dart';
import 'package:personal_life_os/features/bible/models/bible_models.dart';
import 'package:personal_life_os/features/bible/services/bible_service.dart';

void main() {
  group('Bible Service & Scripture Integration Tests', () {
    final bible = BibleService.instance;

    test('Contains exactly 66 Canonical Books with 39 OT and 27 NT', () {
      expect(bible.books.length, equals(66));

      final ot = bible.books.where((b) => b.testament == Testament.oldTestament).toList();
      final nt = bible.books.where((b) => b.testament == Testament.newTestament).toList();

      expect(ot.length, equals(39));
      expect(nt.length, equals(27));

      expect(ot.first.name, equals('Genesis'));
      expect(ot.last.name, equals('Malachi'));
      expect(nt.first.name, equals('Matthew'));
      expect(nt.last.name, equals('Revelation'));
    });

    test('Can find books by name, id or short abbreviation', () {
      final gen = bible.findBook('Genesis');
      expect(gen, isNotNull);
      expect(gen!.totalChapters, equals(50));

      final prov = bible.findBook('Pro');
      expect(prov, isNotNull);
      expect(prov!.name, equals('Proverbs'));
      expect(prov.totalChapters, equals(31));

      final rom = bible.findBook('romans');
      expect(rom, isNotNull);
      expect(rom!.totalChapters, equals(16));
    });

    test('Curated power themes provide immediate offline scriptures', () {
      expect(bible.curatedThemes.isNotEmpty, isTrue);

      final wisdomTheme = bible.curatedThemes.firstWhere((t) => t.id == 'wisdom_strategy');
      expect(wisdomTheme.verses.isNotEmpty, isTrue);

      final prov35 = wisdomTheme.verses.firstWhere((v) => v.reference == 'Proverbs 3:5');
      expect(prov35.text, contains('Trust in the LORD'));
      expect(prov35.translation, equals('KJV'));
    });

    test('BibleVerse formats properly as markdown quote block for note insertion', () {
      const verse = BibleVerse(
        book: 'Jeremiah',
        chapter: 29,
        verse: 11,
        text: 'For I know the thoughts that I think toward you, saith the LORD, thoughts of peace, and not of evil, to give you an expected end.',
        translation: 'KJV',
      );

      final quote = verse.toFormattedQuote();
      expect(quote, startsWith('> "For I know the thoughts'));
      expect(quote, contains('— Jeremiah 29:11 (KJV)'));
    });

    test('Search finds scriptures by reference and keyword', () {
      final refResults = bible.searchVerses('Proverbs 3');
      expect(refResults.isNotEmpty, isTrue);
      expect(refResults.any((v) => v.book == 'Proverbs'), isTrue);

      final keywordResults = bible.searchVerses('wisdom');
      expect(keywordResults.isNotEmpty, isTrue);

      final visionResults = bible.searchVerses('vision');
      expect(visionResults.any((v) => v.book == 'Habakkuk' || v.book == 'Joel'), isTrue);
    });

    test('Can convert scripture into a life commitment task in LocalDatabase', () {
      final db = LocalDatabase.instance;
      const verse = BibleVerse(
        book: 'Proverbs',
        chapter: 16,
        verse: 3,
        text: 'Commit thy works unto the LORD, and thy thoughts shall be established.',
        translation: 'KJV',
      );

      final task = Task(
        id: 'task-scripture-test-1',
        workspaceId: 'ws-henovate',
        title: 'Scripture Commitment: ${verse.reference}',
        notes: '"${verse.text}"\n\nDaily morning prayer before dev sprints.',
        status: TaskStatus.scheduled,
        importance: TaskImportance.high,
        scheduledDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      db.upsertTask(task);

      final retrieved = db.getTaskById('task-scripture-test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, contains('Proverbs 16:3'));
      expect(retrieved.workspaceId, equals('ws-henovate'));
      expect(retrieved.status, equals(TaskStatus.scheduled));
    });
  });
}
