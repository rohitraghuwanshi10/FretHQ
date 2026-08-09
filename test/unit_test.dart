import 'package:flutter_test/flutter_test.dart';
import 'package:frethq/models/note.dart';
import 'package:frethq/models/game_session.dart';

void main() {
  group('Music Theory & Fretboard Engine Tests', () {
    test('String 6 (Low E) note calculations', () {
      expect(Note.getNoteForPosition(6, 0).id, 'E');
      expect(Note.getNoteForPosition(6, 1).id, 'F');
      expect(Note.getNoteForPosition(6, 3).id, 'G');
      expect(Note.getNoteForPosition(6, 5).id, 'A');
      expect(Note.getNoteForPosition(6, 7).id, 'B');
      expect(Note.getNoteForPosition(6, 12).id, 'E');
    });

    test('String 5 (A) note calculations', () {
      expect(Note.getNoteForPosition(5, 0).id, 'A');
      expect(Note.getNoteForPosition(5, 2).id, 'B');
      expect(Note.getNoteForPosition(5, 3).id, 'C');
      expect(Note.getNoteForPosition(5, 5).id, 'D');
      expect(Note.getNoteForPosition(5, 7).id, 'E');
      expect(Note.getNoteForPosition(5, 12).id, 'A');
    });

    test('String 4 (D) note calculations', () {
      expect(Note.getNoteForPosition(4, 0).id, 'D');
      expect(Note.getNoteForPosition(4, 2).id, 'E');
      expect(Note.getNoteForPosition(4, 3).id, 'F');
      expect(Note.getNoteForPosition(4, 5).id, 'G');
      expect(Note.getNoteForPosition(4, 7).id, 'A');
      expect(Note.getNoteForPosition(4, 12).id, 'D');
    });

    test('String 3 (G) note calculations', () {
      expect(Note.getNoteForPosition(3, 0).id, 'G');
      expect(Note.getNoteForPosition(3, 2).id, 'A');
      expect(Note.getNoteForPosition(3, 5).id, 'C');
      expect(Note.getNoteForPosition(3, 7).id, 'D');
      expect(Note.getNoteForPosition(3, 12).id, 'G');
    });

    test('String 2 (B) note calculations', () {
      expect(Note.getNoteForPosition(2, 0).id, 'B');
      expect(Note.getNoteForPosition(2, 1).id, 'C');
      expect(Note.getNoteForPosition(2, 3).id, 'D');
      expect(Note.getNoteForPosition(2, 5).id, 'E');
      expect(Note.getNoteForPosition(2, 7).id, 'F#');
      expect(Note.getNoteForPosition(2, 12).id, 'B');
    });

    test('String 1 (High E) note calculations', () {
      expect(Note.getNoteForPosition(1, 0).id, 'E');
      expect(Note.getNoteForPosition(1, 1).id, 'F');
      expect(Note.getNoteForPosition(1, 3).id, 'G');
      expect(Note.getNoteForPosition(1, 5).id, 'A');
      expect(Note.getNoteForPosition(1, 7).id, 'B');
      expect(Note.getNoteForPosition(1, 12).id, 'E');
    });

    test('Accidental note display names contain both sharps and flats', () {
      final cSharp = Note.chromaticNotes[1];
      expect(cSharp.displayName, contains('C♯'));
      expect(cSharp.displayName, contains('D♭'));
    });
  });

  group('GameSession State Tests', () {
    test('Initial session state with custom duration', () {
      final session = GameSession(durationSeconds: 180);
      expect(session.status, GameStatus.idle);
      expect(session.durationSeconds, 180);
      expect(session.secondsRemaining, 180);
      expect(session.correctCount, 0);
      expect(session.incorrectCount, 0);
      expect(session.currentStreak, 0);
    });

    test('Start session initializes prompt and status', () {
      final session = GameSession(durationSeconds: 60);
      session.start();
      expect(session.status, GameStatus.playing);
      expect(session.currentPosition, isNotNull);
      expect(session.currentPosition!.stringNumber, greaterThanOrEqualTo(1));
      expect(session.currentPosition!.stringNumber, lessThanOrEqualTo(6));
    });

    test('Correct answer updates score, streak, and generates new prompt', () {
      final session = GameSession(durationSeconds: 60);
      session.start();
      final target = session.currentPosition!.targetNote;

      final isCorrect = session.answer(target);
      expect(isCorrect, isTrue);
      expect(session.correctCount, 1);
      expect(session.currentStreak, 1);
      expect(session.maxStreak, 1);
    });

    test('Incorrect answer resets streak and records in incorrectAttempts history', () {
      final session = GameSession(durationSeconds: 60);
      session.start();

      final target = session.currentPosition!.targetNote;
      final wrongNote = Note.chromaticNotes.firstWhere((n) => n != target);

      final isCorrect = session.answer(wrongNote);
      expect(isCorrect, isFalse);
      expect(session.correctCount, 0);
      expect(session.incorrectCount, 1);
      expect(session.currentStreak, 0);
      expect(session.incorrectAttempts.length, 1);
      expect(session.incorrectAttempts.first.userSelectedNote, wrongNote);
      expect(session.incorrectAttempts.first.position.targetNote, target);
    });

    test('Timer ticks to finish state', () {
      final session = GameSession(durationSeconds: 2);
      session.start();
      expect(session.status, GameStatus.playing);

      session.tick();
      expect(session.secondsRemaining, 1);
      expect(session.status, GameStatus.playing);

      session.tick();
      expect(session.secondsRemaining, 0);
      expect(session.status, GameStatus.finished);
    });

    test('Easy Mode (includeAccidentals = false) generates only natural target notes', () {
      final session = GameSession(durationSeconds: 60, includeAccidentals: false);
      session.start();

      for (int i = 0; i < 50; i++) {
        final target = session.currentPosition!.targetNote;
        expect(target.isNatural, isTrue, reason: 'Expected natural note (C,D,E,F,G,A,B), got ${target.id}');
        session.answer(target);
      }
    });

    test('Full Mode (includeAccidentals = true) generates accidental notes', () {
      final session = GameSession(durationSeconds: 60, includeAccidentals: true);
      session.start();

      bool foundAccidental = false;
      for (int i = 0; i < 100; i++) {
        final target = session.currentPosition!.targetNote;
        if (!target.isNatural) {
          foundAccidental = true;
          break;
        }
        session.answer(target);
      }
      expect(foundAccidental, isTrue, reason: 'Expected to find at least one sharp/flat note in 100 prompts in Full Mode');
    });
  });
}
