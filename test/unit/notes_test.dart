import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/database/local_database.dart';
import 'package:personal_life_os/core/database/schema_models.dart';

void main() {
  group('OmniNote & Note System Tests', () {
    late LocalDatabase db;

    setUp(() {
      db = LocalDatabase.instance;
      db.wipeAllData();
    });

    test('Initial database contains realistic seeded notes across categories', () {
      final allNotes = db.getNotes();
      expect(allNotes.isNotEmpty, isTrue);
      expect(allNotes.length, greaterThanOrEqualTo(5));

      final spiritual = db.getNotes(category: NoteCategory.spiritual);
      expect(spiritual.isNotEmpty, isTrue);
      expect(spiritual.first.subCategory, contains('Vision'));

      final bibleStudy = db.getNotes(category: NoteCategory.bibleStudy);
      expect(bibleStudy.isNotEmpty, isTrue);
      expect(bibleStudy.first.scriptureReference, isNotNull);

      final vision = db.getNotes(category: NoteCategory.visionStrategy);
      expect(vision.isNotEmpty, isTrue);

      final professional = db.getNotes(category: NoteCategory.professional);
      expect(professional.isNotEmpty, isTrue);

      final relationships = db.getNotes(category: NoteCategory.relationships);
      expect(relationships.isNotEmpty, isTrue);
    });

    test('OmniNote json serialization roundtrip preserves all fields', () {
      final note = OmniNote(
        id: 'test-note-1',
        workspaceId: 'ws-henovate',
        title: 'Prophetic Strategy 2027',
        content: '- [ ] Fast 3 days\n- [ ] Draft investment prospectus',
        category: NoteCategory.visionStrategy,
        subCategory: 'Venture Roadmap',
        tags: ['#vision2027', '#henovate', '#breakthrough'],
        scriptureReference: 'Habakkuk 2:2-3',
        isPinned: true,
        colorValue: 0xFF1E3A8A,
        linkedTaskId: null,
        createdAt: DateTime(2026, 10, 19, 3, 30),
        updatedAt: DateTime(2026, 10, 19, 4, 0),
      );

      final json = note.toJson();
      expect(json['id'], 'test-note-1');
      expect(json['category'], 'visionStrategy');
      expect(json['tags'], ['#vision2027', '#henovate', '#breakthrough']);
      expect(json['scriptureReference'], 'Habakkuk 2:2-3');

      final reconstructed = OmniNote.fromJson(json);
      expect(reconstructed.id, note.id);
      expect(reconstructed.title, note.title);
      expect(reconstructed.content, note.content);
      expect(reconstructed.category, NoteCategory.visionStrategy);
      expect(reconstructed.subCategory, 'Venture Roadmap');
      expect(reconstructed.tags, note.tags);
      expect(reconstructed.scriptureReference, 'Habakkuk 2:2-3');
      expect(reconstructed.isPinned, isTrue);
      expect(reconstructed.colorValue, 0xFF1E3A8A);
    });

    test('Toggle note pin works idempotently', () {
      final note = db.getNotes().first;
      final initialPinned = note.isPinned;

      db.toggleNotePin(note.id);
      final updated = db.getNoteById(note.id);
      expect(updated?.isPinned, !initialPinned);

      db.toggleNotePin(note.id);
      final reverted = db.getNoteById(note.id);
      expect(reverted?.isPinned, initialPinned);
    });

    test('Convert note to actionable task links note and creates workspace task', () {
      final note = OmniNote(
        id: 'revelation-task-source',
        workspaceId: 'ws-henovate',
        title: 'Divine Architecture for Henovate AI Cloud',
        content: 'Blueprint received at 3:15 AM.\n- [ ] Prototype local vector engine\n- [ ] Deploy zero-telemetry daemon',
        category: NoteCategory.spiritual,
        subCategory: 'Night Vision (3:15 AM)',
        tags: ['#prophecy', '#architecture'],
        scriptureReference: 'Exodus 25:9',
        isPinned: true,
        colorValue: 0xFF4C1D95,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      db.upsertNote(note);

      // Convert note to task
      final createdTask = db.convertNoteToTask(note.id);
      expect(createdTask.title, contains('Divine Architecture for Henovate AI Cloud'));
      expect(createdTask.workspaceId, 'ws-henovate');
      expect(createdTask.importance, TaskImportance.high);
      expect(createdTask.isTopPriority, isTrue);

      // Note should now have linkedTaskId populated
      final updatedNote = db.getNoteById(note.id);
      expect(updatedNote?.linkedTaskId, createdTask.id);

      // Task should be in active tasks of the database
      final matchingTask = db.getTasks().firstWhere((t) => t.id == createdTask.id);
      expect(matchingTask.nextAction, isNotEmpty);
    });

    test('Delete note removes it from database', () {
      final note = OmniNote(
        id: 'temporary-note',
        workspaceId: 'ws-personal',
        title: 'Quick Scratchpad',
        content: 'Temporary ideas',
        category: NoteCategory.personal,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      db.upsertNote(note);
      expect(db.getNoteById('temporary-note'), isNotNull);

      db.deleteNote('temporary-note');
      expect(db.getNoteById('temporary-note'), isNull);
    });
  });
}
