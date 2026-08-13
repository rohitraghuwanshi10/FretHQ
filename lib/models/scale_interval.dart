import 'note.dart';

class MusicalInterval {
  final String name;
  final String shortName; // e.g. 'R', 'm3', 'M3', 'P5', 'P8'
  final int semitones;

  const MusicalInterval({
    required this.name,
    required this.shortName,
    required this.semitones,
  });

  static const List<MusicalInterval> standardIntervals = [
    MusicalInterval(name: 'Unison / Root', shortName: 'R', semitones: 0),
    MusicalInterval(name: 'Minor 2nd', shortName: 'm2', semitones: 1),
    MusicalInterval(name: 'Major 2nd', shortName: 'M2', semitones: 2),
    MusicalInterval(name: 'Minor 3rd', shortName: 'm3', semitones: 3),
    MusicalInterval(name: 'Major 3rd', shortName: 'M3', semitones: 4),
    MusicalInterval(name: 'Perfect 4th', shortName: 'P4', semitones: 5),
    MusicalInterval(name: 'Tritone / Flat 5th', shortName: 'd5', semitones: 6),
    MusicalInterval(name: 'Perfect 5th', shortName: 'P5', semitones: 7),
    MusicalInterval(name: 'Minor 6th', shortName: 'm6', semitones: 8),
    MusicalInterval(name: 'Major 6th', shortName: 'M6', semitones: 9),
    MusicalInterval(name: 'Minor 7th', shortName: 'm7', semitones: 10),
    MusicalInterval(name: 'Major 7th', shortName: 'M7', semitones: 11),
    MusicalInterval(name: 'Octave', shortName: 'P8', semitones: 12),
  ];
}

class GuitarScale {
  final String name;
  final String description;
  final List<int> semitoneOffsets;

  const GuitarScale({
    required this.name,
    required this.description,
    required this.semitoneOffsets,
  });

  static const List<GuitarScale> popularScales = [
    GuitarScale(
      name: 'Major Scale',
      description: 'The foundation of Western music theory (1-2-3-4-5-6-7).',
      semitoneOffsets: [0, 2, 4, 5, 7, 9, 11],
    ),
    GuitarScale(
      name: 'Natural Minor',
      description: 'The standard minor scale with a dark, emotional tonality (1-2-b3-4-5-b6-b7).',
      semitoneOffsets: [0, 2, 3, 5, 7, 8, 10],
    ),
    GuitarScale(
      name: 'Minor Pentatonic',
      description: 'The most essential scale for rock, blues, and guitar solos (1-b3-4-5-b7).',
      semitoneOffsets: [0, 3, 5, 7, 10],
    ),
    GuitarScale(
      name: 'Major Pentatonic',
      description: 'A sweet, country and blues-rock 5-note melodic scale (1-2-3-5-6).',
      semitoneOffsets: [0, 2, 4, 7, 9],
    ),
    GuitarScale(
      name: 'Blues Scale',
      description: 'Minor pentatonic plus the expressive blue note / flat 5 (1-b3-4-b5-5-b7).',
      semitoneOffsets: [0, 3, 5, 6, 7, 10],
    ),
  ];

  /// Returns true if note is inside this scale starting on rootNote
  bool containsNote(Note rootNote, Note note) {
    final diff = (note.chromaticIndex - rootNote.chromaticIndex + 12) % 12;
    return semitoneOffsets.contains(diff);
  }
}
