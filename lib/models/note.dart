class Note {
  final String id; // e.g. 'C', 'C#', etc.
  final String displayName; // e.g. 'C', 'C♯ / D♭'
  final int chromaticIndex; // 0 to 11

  const Note({
    required this.id,
    required this.displayName,
    required this.chromaticIndex,
  });

  static const List<Note> chromaticNotes = [
    Note(id: 'C', displayName: 'C', chromaticIndex: 0),
    Note(id: 'C#', displayName: 'C♯ / D♭', chromaticIndex: 1),
    Note(id: 'D', displayName: 'D', chromaticIndex: 2),
    Note(id: 'D#', displayName: 'D♯ / E♭', chromaticIndex: 3),
    Note(id: 'E', displayName: 'E', chromaticIndex: 4),
    Note(id: 'F', displayName: 'F', chromaticIndex: 5),
    Note(id: 'F#', displayName: 'F♯ / G♭', chromaticIndex: 6),
    Note(id: 'G', displayName: 'G', chromaticIndex: 7),
    Note(id: 'G#', displayName: 'G♯ / A♭', chromaticIndex: 8),
    Note(id: 'A', displayName: 'A', chromaticIndex: 9),
    Note(id: 'A#', displayName: 'A♯ / B♭', chromaticIndex: 10),
    Note(id: 'B', displayName: 'B', chromaticIndex: 11),
  ];

  /// Standard tuning open string chromatic starting offsets (1-indexed string numbers)
  /// String 1 (High E): 4 (E)
  /// String 2 (B): 11 (B)
  /// String 3 (G): 7 (G)
  /// String 4 (D): 2 (D)
  /// String 5 (A): 9 (A)
  /// String 6 (Low E): 4 (E)
  static const Map<int, int> openStringOffsets = {
    1: 4,
    2: 11,
    3: 7,
    4: 2,
    5: 9,
    6: 4,
  };

  /// Calculates the note on a given 6-string guitar position (string 1-6, fret 0-24)
  static Note getNoteForPosition(int stringNumber, int fretNumber) {
    final baseOffset = openStringOffsets[stringNumber] ?? 4;
    final index = (baseOffset + fretNumber) % 12;
    return chromaticNotes[index];
  }

  /// Returns true if note is one of the 7 natural notes (C, D, E, F, G, A, B)
  bool get isNatural => !id.contains('#');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          chromaticIndex == other.chromaticIndex;

  @override
  int get hashCode => chromaticIndex.hashCode;
}

class TargetPosition {
  final int stringNumber; // 1 to 6 (1 = High E, 6 = Low E)
  final int fretNumber;   // 0 to 12
  final Note targetNote;

  TargetPosition({
    required this.stringNumber,
    required this.fretNumber,
  }) : targetNote = Note.getNoteForPosition(stringNumber, fretNumber);

  String get stringName {
    switch (stringNumber) {
      case 1:
        return 'E (High)';
      case 2:
        return 'B';
      case 3:
        return 'G';
      case 4:
        return 'D';
      case 5:
        return 'A';
      case 6:
        return 'E (Low)';
      default:
        return 'String $stringNumber';
    }
  }
}
