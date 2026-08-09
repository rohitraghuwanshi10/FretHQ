import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:frethq/models/game_session.dart';
import 'package:frethq/models/note.dart';
import 'package:frethq/screens/find_fret_screen.dart';
import 'package:frethq/widgets/interactive_fretboard_widget.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Game 2 - Find Fret Location Unit & Widget Tests', () {
    test('Game 2 session accepts correct fret tap answer', () {
      final session = GameSession(durationSeconds: 60);
      session.start();

      final targetPos = session.currentPosition!;
      final correctNote = targetPos.targetNote;

      final isCorrect = session.answer(correctNote);
      expect(isCorrect, isTrue);
      expect(session.correctCount, equals(1));
      expect(session.currentStreak, equals(1));
    });

    testWidgets('FindFretScreen renders prompt badge and InteractiveFretboardWidget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FindFretScreen(
            durationSeconds: 60,
            includeAccidentals: false,
          ),
        ),
      );

      // Verify prompt title and elements render
      expect(find.textContaining('Find Fret'), findsOneWidget);
      expect(find.text('TAP THE FRET LOCATION FOR:'), findsOneWidget);
      expect(find.byType(InteractiveFretboardWidget), findsOneWidget);
    });

    testWidgets('Tapping InteractiveFretboardWidget registers fret answer', (WidgetTester tester) async {
      int tappedString = -1;
      int tappedFret = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveFretboardWidget(
              onFretTapped: (stringNum, fretNum) {
                tappedString = stringNum;
                tappedFret = fretNum;
              },
            ),
          ),
        ),
      );

      // Tap on middle of fretboard
      final fretboardFinder = find.byType(InteractiveFretboardWidget);
      expect(fretboardFinder, findsOneWidget);

      await tester.tap(fretboardFinder);
      await tester.pump();

      expect(tappedString, greaterThanOrEqualTo(1));
      expect(tappedString, lessThanOrEqualTo(6));
      expect(tappedFret, greaterThanOrEqualTo(0));
      expect(tappedFret, lessThanOrEqualTo(12));
    });
  });
}
