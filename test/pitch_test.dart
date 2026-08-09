import 'package:flutter_test/flutter_test.dart';
import 'package:frethq/services/pitch_service.dart';
import 'package:frethq/services/intonation_service.dart';

void main() {
  group('Chromatic Pitch & Intonation Unit Tests', () {
    test('TunerNote.fromFrequency correctly maps Low E (E2 = 82.41 Hz)', () {
      final note = TunerNote.fromFrequency(82.41);
      expect(note.noteName, equals('E'));
      expect(note.octave, equals(2));
      expect(note.centsOffset.abs(), lessThan(1.5));
      expect(note.isInTune, isTrue);
    });

    test('TunerNote.fromFrequency correctly maps A2 (110 Hz)', () {
      final note = TunerNote.fromFrequency(110.0);
      expect(note.noteName, equals('A'));
      expect(note.octave, equals(2));
      expect(note.centsOffset.abs(), lessThan(1.5));
      expect(note.isInTune, isTrue);
    });

    test('TunerNote.fromFrequency detects Flat pitch', () {
      final note = TunerNote.fromFrequency(81.5); // Slightly flat E2 (82.41 Hz)
      expect(note.noteName, equals('E'));
      expect(note.octave, equals(2));
      expect(note.centsOffset, lessThan(-2.5));
      expect(note.isInTune, isFalse);
    });

    test('TunerNote.fromFrequency detects Sharp pitch', () {
      final note = TunerNote.fromFrequency(83.2); // Slightly sharp E2 (82.41 Hz)
      expect(note.noteName, equals('E'));
      expect(note.octave, equals(2));
      expect(note.centsOffset, greaterThan(2.5));
      expect(note.isInTune, isFalse);
    });

    test('StringIntonationResult evaluates SHARP 12th fret intonation correctly', () {
      // Open E = 82.41 Hz. Ideal 12th fret = 164.82 Hz.
      // Suppose 12th fret is 167.0 Hz (Sharp)
      final result = StringIntonationResult.calculate(
        stringNumber: 6,
        stringName: 'Low E',
        openFreq: 82.41,
        fret12Freq: 167.0,
      );

      expect(result.status, equals(IntonationStatus.sharp));
      expect(result.centsDeviation, greaterThan(2.5));
      expect(result.saddleRecommendation.contains('SHARP'), isTrue);
      expect(result.saddleRecommendation.contains('BACK'), isTrue);
    });

    test('StringIntonationResult evaluates FLAT 12th fret intonation correctly', () {
      // Open E = 82.41 Hz. Ideal 12th fret = 164.82 Hz.
      // Suppose 12th fret is 162.0 Hz (Flat)
      final result = StringIntonationResult.calculate(
        stringNumber: 6,
        stringName: 'Low E',
        openFreq: 82.41,
        fret12Freq: 162.0,
      );

      expect(result.status, equals(IntonationStatus.flat));
      expect(result.centsDeviation, lessThan(-2.5));
      expect(result.saddleRecommendation.contains('FLAT'), isTrue);
      expect(result.saddleRecommendation.contains('FORWARD'), isTrue);
    });

    test('StringIntonationResult evaluates PERFECT intonation when frequencies match', () {
      final result = StringIntonationResult.calculate(
        stringNumber: 6,
        stringName: 'Low E',
        openFreq: 82.41,
        fret12Freq: 164.82,
      );

      expect(result.status, equals(IntonationStatus.ideal));
      expect(result.centsDeviation.abs(), lessThan(2.5));
      expect(result.saddleRecommendation.contains('perfect'), isTrue);
    });
  });
}
