import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frethq/models/circle_key.dart';
import 'package:frethq/screens/circle_of_fifths_screen.dart';
import 'package:frethq/screens/circle_quiz_screen.dart';
import 'package:frethq/widgets/circle_of_fifths_widget.dart';
import 'package:frethq/widgets/circle_fretboard_widget.dart';

void main() {
  group('Circle of Fifths Data Model Tests', () {
    test('12 keys are present in canonical circular order', () {
      expect(CircleKey.circleKeys.length, equals(12));

      // Key 0: C Major / A Minor
      final cKey = CircleKey.circleKeys[0];
      expect(cKey.majorName, equals('C'));
      expect(cKey.minorName, equals('Am'));
      expect(cKey.accidentalCount, equals(0));
      expect(cKey.accidentalSummary, equals('0 (Natural)'));
      expect(cKey.majorScaleNotes.map((n) => n.id).toList(), equals(['C', 'D', 'E', 'F', 'G', 'A', 'B']));

      // Key 1: G Major / E Minor (1 sharp)
      final gKey = CircleKey.circleKeys[1];
      expect(gKey.majorName, equals('G'));
      expect(gKey.minorName, equals('Em'));
      expect(gKey.accidentalCount, equals(1));
      expect(gKey.accidentalsList, equals(['F♯']));

      // Key 2: D Major (2 sharps)
      expect(CircleKey.circleKeys[2].majorName, equals('D'));
      expect(CircleKey.circleKeys[2].accidentalCount, equals(2));

      // Key 11: F Major (1 flat)
      final fKey = CircleKey.circleKeys[11];
      expect(fKey.majorName, equals('F'));
      expect(fKey.minorName, equals('Dm'));
      expect(fKey.accidentalCount, equals(-1));
      expect(fKey.accidentalsList, equals(['B♭']));
    });

    test('Harmonic dominant and subdominant neighbor navigation is correct', () {
      final cKey = CircleKey.circleKeys[0];
      expect(cKey.dominant.majorName, equals('G')); // Clockwise (V)
      expect(cKey.subdominant.majorName, equals('F')); // Counter-clockwise (IV)

      final gKey = CircleKey.circleKeys[1];
      expect(gKey.dominant.majorName, equals('D')); // V of G is D
      expect(gKey.subdominant.majorName, equals('C')); // IV of G is C
    });

    test('Each key contains a complete 7-chord family (I - vii°)', () {
      for (final key in CircleKey.circleKeys) {
        expect(key.chordFamily.length, equals(7));
        expect(key.chordFamily[0].numeral, equals('I'));
        expect(key.chordFamily[0].isMajor, isTrue);

        expect(key.chordFamily[1].numeral, equals('ii'));
        expect(key.chordFamily[1].isMinor, isTrue);

        expect(key.chordFamily[2].numeral, equals('iii'));
        expect(key.chordFamily[2].isMinor, isTrue);

        expect(key.chordFamily[3].numeral, equals('IV'));
        expect(key.chordFamily[3].isMajor, isTrue);

        expect(key.chordFamily[4].numeral, equals('V'));
        expect(key.chordFamily[4].isMajor, isTrue);

        expect(key.chordFamily[5].numeral, equals('vi'));
        expect(key.chordFamily[5].isMinor, isTrue);

        expect(key.chordFamily[6].numeral, equals('vii°'));
        expect(key.chordFamily[6].isDiminished, isTrue);

        // Triad notes must have exactly 3 notes
        for (final chord in key.chordFamily) {
          expect(chord.triadNotes.length, equals(3));
        }
      }
    });
  });

  group('Circle of Fifths Widget & Screen Tests', () {
    testWidgets('CircleOfFifthsScreen renders wheel, chord pills and fretboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CircleOfFifthsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Screen title and widgets
      expect(find.text('Circle of Fifths'), findsWidgets);
      expect(find.byType(CircleOfFifthsWidget), findsOneWidget);
      expect(find.byType(CircleFretboardWidget), findsOneWidget);

      // Default C Major display
      expect(find.text('C Major'), findsOneWidget);
      expect(find.text('Relative Minor: Am'), findsOneWidget);

      // Chords in C Major
      expect(find.text('I'), findsOneWidget);
      expect(find.text('IV'), findsOneWidget);
      expect(find.text('V'), findsOneWidget);
      expect(find.text('vi'), findsOneWidget);

      // Tap on Chord V to isolate triad notes
      final chordVPill = find.text('V');
      expect(chordVPill, findsOneWidget);
      await tester.ensureVisible(chordVPill);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(chordVPill);
      await tester.pump(const Duration(milliseconds: 100));

      // Should indicate isolated triad
      expect(find.textContaining('TRIAD NOTES'), findsOneWidget);
      expect(find.textContaining('Show All'), findsOneWidget);

      // Tap Show All to reset
      final showAllFinder = find.text('Show All');
      await tester.ensureVisible(showAllFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(showAllFinder);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('SCALE POSITIONS'), findsOneWidget);
    });

    testWidgets('Mode pill switches between Major and Minor mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CircleOfFifthsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Minor mode pill
      final minorPill = find.text('Minor');
      expect(minorPill, findsOneWidget);
      await tester.tap(minorPill);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should display Natural Minor header
      expect(find.textContaining('Natural Minor'), findsOneWidget);
    });

    testWidgets('CircleQuizScreen renders HUD, wheel reference and 4 multiple-choice options', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CircleQuizScreen(durationSeconds: 60),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // HUD elements: Close button, wheel reference
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byType(CircleOfFifthsWidget), findsOneWidget);

      // 4 options rendered inside GridView
      expect(find.byType(GridView), findsOneWidget);
      final optionTiles = find.descendant(of: find.byType(GridView), matching: find.byType(InkWell));
      expect(optionTiles, findsNWidgets(4));

      // Tap an option
      await tester.ensureVisible(optionTiles.first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(optionTiles.first);
      await tester.pump(const Duration(milliseconds: 100));

      // Screen remains responsive
      expect(find.byType(CircleQuizScreen), findsOneWidget);
    });
  });
}
