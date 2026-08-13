import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:frethq/models/scale_interval.dart';
import 'package:frethq/models/note.dart';
import 'package:frethq/screens/scale_quiz_screen.dart';
import 'package:frethq/widgets/note_keypad_widget.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Game 3 - Scale & Interval Quiz Tests', () {
    test('Calculates expected interval note correctly', () {
      final c = Note.chromaticNotes.firstWhere((n) => n.id == 'C');
      final p5 = MusicalInterval.standardIntervals.firstWhere((i) => i.shortName == 'P5');

      final targetIndex = (c.chromaticIndex + p5.semitones) % 12;
      final targetNote = Note.chromaticNotes[targetIndex];

      expect(targetNote.id, equals('G'));
    });

    testWidgets('ScaleQuizScreen renders HUD and NoteKeypadWidget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScaleQuizScreen(durationSeconds: 60),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Scale & Interval Quiz'), findsOneWidget);
      expect(find.text('IDENTIFY THE MUSICAL INTERVAL NOTE'), findsOneWidget);
      expect(find.byType(NoteKeypadWidget), findsOneWidget);
    });
  });
}
