import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:frethq/services/database_helper.dart';
import 'package:frethq/models/game_session.dart';
import 'package:frethq/models/note.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper & Analytics Unit Tests', () {
    test('saveGameSession stores session summary and answer attempts', () async {
      final session = GameSession(durationSeconds: 60);
      session.start();

      // Answer 3 correct, 2 wrong
      final target1 = session.currentPosition!.targetNote;
      session.answer(target1); // Correct

      final target2 = session.currentPosition!.targetNote;
      final wrongNote = Note.chromaticNotes.firstWhere((n) => n != target2);
      session.answer(wrongNote); // Incorrect

      final target3 = session.currentPosition!.targetNote;
      session.answer(target3); // Correct

      final sessionId = await DatabaseHelper.instance.saveGameSession(session, 'test_mode');
      expect(sessionId, greaterThan(0));

      final history = await DatabaseHelper.instance.getSessionHistory(limit: 5);
      expect(history.isNotEmpty, isTrue);
      expect(history.first.score, equals(2));
      expect(history.first.totalAttempts, equals(3));
    });

    test('getWeakestPositions identifies fret positions with highest error rates', () async {
      final session = GameSession(durationSeconds: 60);
      session.start();

      // Manually record specific wrong attempts on String 6 Fret 1 (F)
      final posF = TargetPosition(stringNumber: 6, fretNumber: 1); // F note
      final posG = TargetPosition(stringNumber: 6, fretNumber: 3); // G note

      session.attemptsHistory.add(AnswerAttempt(
        position: posF,
        userSelectedNote: Note.chromaticNotes[0], // C (wrong)
        isCorrect: false,
      ));
      session.attemptsHistory.add(AnswerAttempt(
        position: posF,
        userSelectedNote: Note.chromaticNotes[2], // D (wrong)
        isCorrect: false,
      ));
      session.attemptsHistory.add(AnswerAttempt(
        position: posG,
        userSelectedNote: Note.getNoteForPosition(6, 3),
        isCorrect: true,
      ));

      await DatabaseHelper.instance.saveGameSession(session, 'weak_test');

      final weakPositions = await DatabaseHelper.instance.getWeakestPositions(limit: 5);
      expect(weakPositions.isNotEmpty, isTrue);
      final topWeak = weakPositions.first;
      expect(topWeak.stringNumber, equals(6));
      expect(topWeak.fretNumber, equals(1));
      expect(topWeak.wrongCount, greaterThanOrEqualTo(2));
    });

    test('Weak Spot Focus mode generates prompts targeting weak fret positions', () {
      final weakPos = [
        TargetPosition(stringNumber: 6, fretNumber: 1), // Low E fret 1
        TargetPosition(stringNumber: 5, fretNumber: 3), // A string fret 3
      ];

      final session = GameSession(
        durationSeconds: 60,
        isWeakSpotFocus: true,
        weakTargetPositions: weakPos,
      );
      session.start();

      int hitCount = 0;
      for (int i = 0; i < 50; i++) {
        final pos = session.currentPosition!;
        if ((pos.stringNumber == 6 && pos.fretNumber == 1) ||
            (pos.stringNumber == 5 && pos.fretNumber == 3)) {
          hitCount++;
        }
        session.answer(pos.targetNote);
      }

      // 70% targeting probability means hitCount should be high (>= 15 out of 50)
      expect(hitCount, greaterThanOrEqualTo(15));
    });

    test('Easy Mode combined with Weak Spot Focus generates only natural target notes', () {
      final weakPos = [
        TargetPosition(stringNumber: 6, fretNumber: 1), // F note (Natural)
        TargetPosition(stringNumber: 6, fretNumber: 2), // F# note (Accidental)
      ];

      final session = GameSession(
        durationSeconds: 60,
        includeAccidentals: false, // Easy mode
        isWeakSpotFocus: true,
        weakTargetPositions: weakPos,
      );
      session.start();

      for (int i = 0; i < 50; i++) {
        final target = session.currentPosition!.targetNote;
        expect(target.isNatural, isTrue, reason: 'Expected natural note in Easy Mode, got ${target.id}');
        session.answer(target);
      }
    });
  });
}
