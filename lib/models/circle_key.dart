import 'note.dart';

class ChordInfo {
  final String numeral; // e.g. 'I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°'
  final String name; // e.g. 'C', 'Dm', 'G7'
  final String role; // e.g. 'Tonic', 'Dominant'
  final Note rootNote;
  final List<Note> triadNotes;
  final bool isMajor;
  final bool isMinor;
  final bool isDiminished;

  const ChordInfo({
    required this.numeral,
    required this.name,
    required this.role,
    required this.rootNote,
    required this.triadNotes,
    this.isMajor = false,
    this.isMinor = false,
    this.isDiminished = false,
  });
}

class CircleKey {
  final int circleIndex; // 0 to 11 starting at 12 o'clock (C Major) clockwise
  final String majorName; // e.g. 'C', 'G'
  final String majorDisplayName; // e.g. 'C', 'F♯ / G♭'
  final String minorName; // e.g. 'Am', 'Em'
  final String minorDisplayName; // e.g. 'Am', 'D♯m / E♭m'
  final Note majorNote;
  final Note minorNote;
  final int accidentalCount; // 0, +1..+6 for sharps, -1..-5 for flats
  final String accidentalSummary; // '0', '1♯', '2♭'
  final List<String> accidentalsList; // ['F♯', 'C♯']
  final List<Note> majorScaleNotes;
  final List<Note> relativeMinorScaleNotes;
  final List<ChordInfo> chordFamily;

  const CircleKey({
    required this.circleIndex,
    required this.majorName,
    required this.majorDisplayName,
    required this.minorName,
    required this.minorDisplayName,
    required this.majorNote,
    required this.minorNote,
    required this.accidentalCount,
    required this.accidentalSummary,
    required this.accidentalsList,
    required this.majorScaleNotes,
    required this.relativeMinorScaleNotes,
    required this.chordFamily,
  });

  /// Clockwise neighbor on the Circle of 5ths (the Dominant / V)
  CircleKey get dominant => circleKeys[(circleIndex + 1) % 12];

  /// Counter-clockwise neighbor on the Circle of 5ths (the Subdominant / IV)
  CircleKey get subdominant => circleKeys[(circleIndex + 11) % 12];

  /// Convenient lookup helpers for note lookup
  static Note _n(int chromaticIdx) => Note.chromaticNotes[chromaticIdx];

  /// Precomputed standard Circle of Fifths keys
  static final List<CircleKey> circleKeys = [
    // 0: C Major / A Minor (12 o'clock - Natural)
    CircleKey(
      circleIndex: 0,
      majorName: 'C',
      majorDisplayName: 'C',
      minorName: 'Am',
      minorDisplayName: 'Am',
      majorNote: _n(0),
      minorNote: _n(9),
      accidentalCount: 0,
      accidentalSummary: '0 (Natural)',
      accidentalsList: const [],
      majorScaleNotes: [_n(0), _n(2), _n(4), _n(5), _n(7), _n(9), _n(11)],
      relativeMinorScaleNotes: [_n(9), _n(11), _n(0), _n(2), _n(4), _n(5), _n(7)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'C', role: 'Tonic (Major)', rootNote: _n(0), triadNotes: [_n(0), _n(4), _n(7)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'Dm', role: 'Supertonic (Minor)', rootNote: _n(2), triadNotes: [_n(2), _n(5), _n(9)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'Em', role: 'Mediant (Minor)', rootNote: _n(4), triadNotes: [_n(4), _n(7), _n(11)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'F', role: 'Subdominant (Major)', rootNote: _n(5), triadNotes: [_n(5), _n(9), _n(0)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'G', role: 'Dominant (Major)', rootNote: _n(7), triadNotes: [_n(7), _n(11), _n(2)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'Am', role: 'Submediant (Relative Minor)', rootNote: _n(9), triadNotes: [_n(9), _n(0), _n(4)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'B°', role: 'Leading Tone (Diminished)', rootNote: _n(11), triadNotes: [_n(11), _n(2), _n(5)], isDiminished: true),
      ],
    ),

    // 1: G Major / E Minor (1 o'clock - 1 Sharp: F#)
    CircleKey(
      circleIndex: 1,
      majorName: 'G',
      majorDisplayName: 'G',
      minorName: 'Em',
      minorDisplayName: 'Em',
      majorNote: _n(7),
      minorNote: _n(4),
      accidentalCount: 1,
      accidentalSummary: '1♯',
      accidentalsList: const ['F♯'],
      majorScaleNotes: [_n(7), _n(9), _n(11), _n(0), _n(2), _n(4), _n(6)],
      relativeMinorScaleNotes: [_n(4), _n(6), _n(7), _n(9), _n(11), _n(0), _n(2)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'G', role: 'Tonic (Major)', rootNote: _n(7), triadNotes: [_n(7), _n(11), _n(2)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'Am', role: 'Supertonic (Minor)', rootNote: _n(9), triadNotes: [_n(9), _n(0), _n(4)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'Bm', role: 'Mediant (Minor)', rootNote: _n(11), triadNotes: [_n(11), _n(2), _n(6)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'C', role: 'Subdominant (Major)', rootNote: _n(0), triadNotes: [_n(0), _n(4), _n(7)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'D', role: 'Dominant (Major)', rootNote: _n(2), triadNotes: [_n(2), _n(6), _n(9)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'Em', role: 'Submediant (Relative Minor)', rootNote: _n(4), triadNotes: [_n(4), _n(7), _n(11)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'F♯°', role: 'Leading Tone (Diminished)', rootNote: _n(6), triadNotes: [_n(6), _n(9), _n(0)], isDiminished: true),
      ],
    ),

    // 2: D Major / B Minor (2 o'clock - 2 Sharps: F#, C#)
    CircleKey(
      circleIndex: 2,
      majorName: 'D',
      majorDisplayName: 'D',
      minorName: 'Bm',
      minorDisplayName: 'Bm',
      majorNote: _n(2),
      minorNote: _n(11),
      accidentalCount: 2,
      accidentalSummary: '2♯',
      accidentalsList: const ['F♯', 'C♯'],
      majorScaleNotes: [_n(2), _n(4), _n(6), _n(7), _n(9), _n(11), _n(1)],
      relativeMinorScaleNotes: [_n(11), _n(1), _n(2), _n(4), _n(6), _n(7), _n(9)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'D', role: 'Tonic (Major)', rootNote: _n(2), triadNotes: [_n(2), _n(6), _n(9)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'Em', role: 'Supertonic (Minor)', rootNote: _n(4), triadNotes: [_n(4), _n(7), _n(11)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'F♯m', role: 'Mediant (Minor)', rootNote: _n(6), triadNotes: [_n(6), _n(9), _n(1)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'G', role: 'Subdominant (Major)', rootNote: _n(7), triadNotes: [_n(7), _n(11), _n(2)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'A', role: 'Dominant (Major)', rootNote: _n(9), triadNotes: [_n(9), _n(1), _n(4)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'Bm', role: 'Submediant (Relative Minor)', rootNote: _n(11), triadNotes: [_n(11), _n(2), _n(6)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'C♯°', role: 'Leading Tone (Diminished)', rootNote: _n(1), triadNotes: [_n(1), _n(4), _n(7)], isDiminished: true),
      ],
    ),

    // 3: A Major / F# Minor (3 o'clock - 3 Sharps: F#, C#, G#)
    CircleKey(
      circleIndex: 3,
      majorName: 'A',
      majorDisplayName: 'A',
      minorName: 'F#m',
      minorDisplayName: 'F♯m',
      majorNote: _n(9),
      minorNote: _n(6),
      accidentalCount: 3,
      accidentalSummary: '3♯',
      accidentalsList: const ['F♯', 'C♯', 'G♯'],
      majorScaleNotes: [_n(9), _n(11), _n(1), _n(2), _n(4), _n(6), _n(8)],
      relativeMinorScaleNotes: [_n(6), _n(8), _n(9), _n(11), _n(1), _n(2), _n(4)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'A', role: 'Tonic (Major)', rootNote: _n(9), triadNotes: [_n(9), _n(1), _n(4)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'Bm', role: 'Supertonic (Minor)', rootNote: _n(11), triadNotes: [_n(11), _n(2), _n(6)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'C♯m', role: 'Mediant (Minor)', rootNote: _n(1), triadNotes: [_n(1), _n(4), _n(8)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'D', role: 'Subdominant (Major)', rootNote: _n(2), triadNotes: [_n(2), _n(6), _n(9)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'E', role: 'Dominant (Major)', rootNote: _n(4), triadNotes: [_n(4), _n(8), _n(11)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'F♯m', role: 'Submediant (Relative Minor)', rootNote: _n(6), triadNotes: [_n(6), _n(9), _n(1)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'G♯°', role: 'Leading Tone (Diminished)', rootNote: _n(8), triadNotes: [_n(8), _n(11), _n(2)], isDiminished: true),
      ],
    ),

    // 4: E Major / C# Minor (4 o'clock - 4 Sharps: F#, C#, G#, D#)
    CircleKey(
      circleIndex: 4,
      majorName: 'E',
      majorDisplayName: 'E',
      minorName: 'C#m',
      minorDisplayName: 'C♯m',
      majorNote: _n(4),
      minorNote: _n(1),
      accidentalCount: 4,
      accidentalSummary: '4♯',
      accidentalsList: const ['F♯', 'C♯', 'G♯', 'D♯'],
      majorScaleNotes: [_n(4), _n(6), _n(8), _n(9), _n(11), _n(1), _n(3)],
      relativeMinorScaleNotes: [_n(1), _n(3), _n(4), _n(6), _n(8), _n(9), _n(11)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'E', role: 'Tonic (Major)', rootNote: _n(4), triadNotes: [_n(4), _n(8), _n(11)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'F♯m', role: 'Supertonic (Minor)', rootNote: _n(6), triadNotes: [_n(6), _n(9), _n(1)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'G♯m', role: 'Mediant (Minor)', rootNote: _n(8), triadNotes: [_n(8), _n(11), _n(3)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'A', role: 'Subdominant (Major)', rootNote: _n(9), triadNotes: [_n(9), _n(1), _n(4)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'B', role: 'Dominant (Major)', rootNote: _n(11), triadNotes: [_n(11), _n(3), _n(6)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'C♯m', role: 'Submediant (Relative Minor)', rootNote: _n(1), triadNotes: [_n(1), _n(4), _n(8)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'D♯°', role: 'Leading Tone (Diminished)', rootNote: _n(3), triadNotes: [_n(3), _n(6), _n(9)], isDiminished: true),
      ],
    ),

    // 5: B Major / G# Minor (5 o'clock - 5 Sharps: F#, C#, G#, D#, A#)
    CircleKey(
      circleIndex: 5,
      majorName: 'B',
      majorDisplayName: 'B / C♭',
      minorName: 'G#m',
      minorDisplayName: 'G♯m',
      majorNote: _n(11),
      minorNote: _n(8),
      accidentalCount: 5,
      accidentalSummary: '5♯',
      accidentalsList: const ['F♯', 'C♯', 'G♯', 'D♯', 'A♯'],
      majorScaleNotes: [_n(11), _n(1), _n(3), _n(4), _n(6), _n(8), _n(10)],
      relativeMinorScaleNotes: [_n(8), _n(10), _n(11), _n(1), _n(3), _n(4), _n(6)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'B', role: 'Tonic (Major)', rootNote: _n(11), triadNotes: [_n(11), _n(3), _n(6)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'C♯m', role: 'Supertonic (Minor)', rootNote: _n(1), triadNotes: [_n(1), _n(4), _n(8)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'D♯m', role: 'Mediant (Minor)', rootNote: _n(3), triadNotes: [_n(3), _n(6), _n(10)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'E', role: 'Subdominant (Major)', rootNote: _n(4), triadNotes: [_n(4), _n(8), _n(11)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'F♯', role: 'Dominant (Major)', rootNote: _n(6), triadNotes: [_n(6), _n(10), _n(1)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'G♯m', role: 'Submediant (Relative Minor)', rootNote: _n(8), triadNotes: [_n(8), _n(11), _n(3)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'A♯°', role: 'Leading Tone (Diminished)', rootNote: _n(10), triadNotes: [_n(10), _n(1), _n(4)], isDiminished: true),
      ],
    ),

    // 6: F# / Gb Major / D#m (6 o'clock - 6 Sharps / 6 Flats)
    CircleKey(
      circleIndex: 6,
      majorName: 'F#',
      majorDisplayName: 'F♯ / G♭',
      minorName: 'D#m',
      minorDisplayName: 'D♯m / E♭m',
      majorNote: _n(6),
      minorNote: _n(3),
      accidentalCount: 6,
      accidentalSummary: '6♯ / 6♭',
      accidentalsList: const ['F♯', 'C♯', 'G♯', 'D♯', 'A♯', 'E♯'],
      majorScaleNotes: [_n(6), _n(8), _n(10), _n(11), _n(1), _n(3), _n(5)],
      relativeMinorScaleNotes: [_n(3), _n(5), _n(6), _n(8), _n(10), _n(11), _n(1)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'F♯', role: 'Tonic (Major)', rootNote: _n(6), triadNotes: [_n(6), _n(10), _n(1)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'G♯m', role: 'Supertonic (Minor)', rootNote: _n(8), triadNotes: [_n(8), _n(11), _n(3)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'A♯m', role: 'Mediant (Minor)', rootNote: _n(10), triadNotes: [_n(10), _n(1), _n(5)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'B', role: 'Subdominant (Major)', rootNote: _n(11), triadNotes: [_n(11), _n(3), _n(6)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'C♯', role: 'Dominant (Major)', rootNote: _n(1), triadNotes: [_n(1), _n(5), _n(8)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'D♯m', role: 'Submediant (Relative Minor)', rootNote: _n(3), triadNotes: [_n(3), _n(6), _n(10)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'E♯°', role: 'Leading Tone (Diminished)', rootNote: _n(5), triadNotes: [_n(5), _n(8), _n(11)], isDiminished: true),
      ],
    ),

    // 7: Db / C# Major / Bbm (7 o'clock - 5 Flats: Bb, Eb, Ab, Db, Gb)
    CircleKey(
      circleIndex: 7,
      majorName: 'Db',
      majorDisplayName: 'D♭ / C♯',
      minorName: 'Bbm',
      minorDisplayName: 'B♭m',
      majorNote: _n(1),
      minorNote: _n(10),
      accidentalCount: -5,
      accidentalSummary: '5♭',
      accidentalsList: const ['B♭', 'E♭', 'A♭', 'D♭', 'G♭'],
      majorScaleNotes: [_n(1), _n(3), _n(5), _n(6), _n(8), _n(10), _n(0)],
      relativeMinorScaleNotes: [_n(10), _n(0), _n(1), _n(3), _n(5), _n(6), _n(8)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'D♭', role: 'Tonic (Major)', rootNote: _n(1), triadNotes: [_n(1), _n(5), _n(8)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'E♭m', role: 'Supertonic (Minor)', rootNote: _n(3), triadNotes: [_n(3), _n(6), _n(10)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'Fm', role: 'Mediant (Minor)', rootNote: _n(5), triadNotes: [_n(5), _n(8), _n(0)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'G♭', role: 'Subdominant (Major)', rootNote: _n(6), triadNotes: [_n(6), _n(10), _n(1)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'A♭', role: 'Dominant (Major)', rootNote: _n(8), triadNotes: [_n(8), _n(0), _n(3)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'B♭m', role: 'Submediant (Relative Minor)', rootNote: _n(10), triadNotes: [_n(10), _n(1), _n(5)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'C°', role: 'Leading Tone (Diminished)', rootNote: _n(0), triadNotes: [_n(0), _n(3), _n(6)], isDiminished: true),
      ],
    ),

    // 8: Ab Major / F Minor (8 o'clock - 4 Flats: Bb, Eb, Ab, Db)
    CircleKey(
      circleIndex: 8,
      majorName: 'Ab',
      majorDisplayName: 'A♭',
      minorName: 'Fm',
      minorDisplayName: 'Fm',
      majorNote: _n(8),
      minorNote: _n(5),
      accidentalCount: -4,
      accidentalSummary: '4♭',
      accidentalsList: const ['B♭', 'E♭', 'A♭', 'D♭'],
      majorScaleNotes: [_n(8), _n(10), _n(0), _n(1), _n(3), _n(5), _n(7)],
      relativeMinorScaleNotes: [_n(5), _n(7), _n(8), _n(10), _n(0), _n(1), _n(3)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'A♭', role: 'Tonic (Major)', rootNote: _n(8), triadNotes: [_n(8), _n(0), _n(3)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'B♭m', role: 'Supertonic (Minor)', rootNote: _n(10), triadNotes: [_n(10), _n(1), _n(5)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'Cm', role: 'Mediant (Minor)', rootNote: _n(0), triadNotes: [_n(0), _n(3), _n(7)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'D♭', role: 'Subdominant (Major)', rootNote: _n(1), triadNotes: [_n(1), _n(5), _n(8)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'E♭', role: 'Dominant (Major)', rootNote: _n(3), triadNotes: [_n(3), _n(7), _n(10)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'Fm', role: 'Submediant (Relative Minor)', rootNote: _n(5), triadNotes: [_n(5), _n(8), _n(0)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'G°', role: 'Leading Tone (Diminished)', rootNote: _n(7), triadNotes: [_n(7), _n(10), _n(1)], isDiminished: true),
      ],
    ),

    // 9: Eb Major / C Minor (9 o'clock - 3 Flats: Bb, Eb, Ab)
    CircleKey(
      circleIndex: 9,
      majorName: 'Eb',
      majorDisplayName: 'E♭',
      minorName: 'Cm',
      minorDisplayName: 'Cm',
      majorNote: _n(3),
      minorNote: _n(0),
      accidentalCount: -3,
      accidentalSummary: '3♭',
      accidentalsList: const ['B♭', 'E♭', 'A♭'],
      majorScaleNotes: [_n(3), _n(5), _n(7), _n(8), _n(10), _n(0), _n(2)],
      relativeMinorScaleNotes: [_n(0), _n(2), _n(3), _n(5), _n(7), _n(8), _n(10)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'E♭', role: 'Tonic (Major)', rootNote: _n(3), triadNotes: [_n(3), _n(7), _n(10)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'Fm', role: 'Supertonic (Minor)', rootNote: _n(5), triadNotes: [_n(5), _n(8), _n(0)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'Gm', role: 'Mediant (Minor)', rootNote: _n(7), triadNotes: [_n(7), _n(10), _n(2)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'A♭', role: 'Subdominant (Major)', rootNote: _n(8), triadNotes: [_n(8), _n(0), _n(3)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'B♭', role: 'Dominant (Major)', rootNote: _n(10), triadNotes: [_n(10), _n(2), _n(5)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'Cm', role: 'Submediant (Relative Minor)', rootNote: _n(0), triadNotes: [_n(0), _n(3), _n(7)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'D°', role: 'Leading Tone (Diminished)', rootNote: _n(2), triadNotes: [_n(2), _n(5), _n(8)], isDiminished: true),
      ],
    ),

    // 10: Bb Major / G Minor (10 o'clock - 2 Flats: Bb, Eb)
    CircleKey(
      circleIndex: 10,
      majorName: 'Bb',
      majorDisplayName: 'B♭',
      minorName: 'Gm',
      minorDisplayName: 'Gm',
      majorNote: _n(10),
      minorNote: _n(7),
      accidentalCount: -2,
      accidentalSummary: '2♭',
      accidentalsList: const ['B♭', 'E♭'],
      majorScaleNotes: [_n(10), _n(0), _n(2), _n(3), _n(5), _n(7), _n(9)],
      relativeMinorScaleNotes: [_n(7), _n(9), _n(10), _n(0), _n(2), _n(3), _n(5)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'B♭', role: 'Tonic (Major)', rootNote: _n(10), triadNotes: [_n(10), _n(2), _n(5)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'Cm', role: 'Supertonic (Minor)', rootNote: _n(0), triadNotes: [_n(0), _n(3), _n(7)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'Dm', role: 'Mediant (Minor)', rootNote: _n(2), triadNotes: [_n(2), _n(5), _n(9)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'E♭', role: 'Subdominant (Major)', rootNote: _n(3), triadNotes: [_n(3), _n(7), _n(10)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'F', role: 'Dominant (Major)', rootNote: _n(5), triadNotes: [_n(5), _n(9), _n(0)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'Gm', role: 'Submediant (Relative Minor)', rootNote: _n(7), triadNotes: [_n(7), _n(10), _n(2)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'A°', role: 'Leading Tone (Diminished)', rootNote: _n(9), triadNotes: [_n(9), _n(0), _n(3)], isDiminished: true),
      ],
    ),

    // 11: F Major / D Minor (11 o'clock - 1 Flat: Bb)
    CircleKey(
      circleIndex: 11,
      majorName: 'F',
      majorDisplayName: 'F',
      minorName: 'Dm',
      minorDisplayName: 'Dm',
      majorNote: _n(5),
      minorNote: _n(2),
      accidentalCount: -1,
      accidentalSummary: '1♭',
      accidentalsList: const ['B♭'],
      majorScaleNotes: [_n(5), _n(7), _n(9), _n(10), _n(0), _n(2), _n(4)],
      relativeMinorScaleNotes: [_n(2), _n(4), _n(5), _n(7), _n(9), _n(10), _n(0)],
      chordFamily: [
        ChordInfo(numeral: 'I', name: 'F', role: 'Tonic (Major)', rootNote: _n(5), triadNotes: [_n(5), _n(9), _n(0)], isMajor: true),
        ChordInfo(numeral: 'ii', name: 'Gm', role: 'Supertonic (Minor)', rootNote: _n(7), triadNotes: [_n(7), _n(10), _n(2)], isMinor: true),
        ChordInfo(numeral: 'iii', name: 'Am', role: 'Mediant (Minor)', rootNote: _n(9), triadNotes: [_n(9), _n(0), _n(4)], isMinor: true),
        ChordInfo(numeral: 'IV', name: 'B♭', role: 'Subdominant (Major)', rootNote: _n(10), triadNotes: [_n(10), _n(2), _n(5)], isMajor: true),
        ChordInfo(numeral: 'V', name: 'C', role: 'Dominant (Major)', rootNote: _n(0), triadNotes: [_n(0), _n(4), _n(7)], isMajor: true),
        ChordInfo(numeral: 'vi', name: 'Dm', role: 'Submediant (Relative Minor)', rootNote: _n(2), triadNotes: [_n(2), _n(5), _n(9)], isMinor: true),
        ChordInfo(numeral: 'vii°', name: 'E°', role: 'Leading Tone (Diminished)', rootNote: _n(4), triadNotes: [_n(4), _n(7), _n(10)], isDiminished: true),
      ],
    ),
  ];
}
