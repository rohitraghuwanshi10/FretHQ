enum BeatAccent {
  strong, // Downbeat / primary accent (e.g. Beat 1)
  medium, // Secondary accent (e.g. Beat 3 in 4/4 or Beat 4 in 6/8)
  normal, // Regular beat
  mute,   // Silent beat / rest (visual only, for internal timing training)
}

enum Subdivision {
  quarter(1, '♩', 'Quarter'),
  eighth(2, '♫', '8ths (2x)'),
  triplet(3, '3', 'Triplets (3x)'),
  sixteenth(4, '♬', '16ths (4x)');

  final int pulsesPerBeat;
  final String symbol;
  final String label;

  const Subdivision(this.pulsesPerBeat, this.symbol, this.label);
}

class TimeSignaturePreset {
  final String name;
  final int beatsPerBar;
  final int beatUnit; // e.g. 4 for quarter note, 8 for eighth note
  final List<BeatAccent> defaultAccents;
  final String description;

  const TimeSignaturePreset({
    required this.name,
    required this.beatsPerBar,
    required this.beatUnit,
    required this.defaultAccents,
    required this.description,
  });

  static const List<TimeSignaturePreset> presets = [
    TimeSignaturePreset(
      name: '4/4',
      beatsPerBar: 4,
      beatUnit: 4,
      defaultAccents: [
        BeatAccent.strong,
        BeatAccent.normal,
        BeatAccent.medium,
        BeatAccent.normal,
      ],
      description: 'Common Time • Rock, Pop, Blues, Funk',
    ),
    TimeSignaturePreset(
      name: '3/4',
      beatsPerBar: 3,
      beatUnit: 4,
      defaultAccents: [
        BeatAccent.strong,
        BeatAccent.normal,
        BeatAccent.normal,
      ],
      description: 'Waltz Time • Ballads, Folk, Country',
    ),
    TimeSignaturePreset(
      name: '2/4',
      beatsPerBar: 2,
      beatUnit: 4,
      defaultAccents: [
        BeatAccent.strong,
        BeatAccent.normal,
      ],
      description: 'March / Polka • Fast Country, Punk',
    ),
    TimeSignaturePreset(
      name: '6/8',
      beatsPerBar: 6,
      beatUnit: 8,
      defaultAccents: [
        BeatAccent.strong,
        BeatAccent.normal,
        BeatAccent.normal,
        BeatAccent.medium,
        BeatAccent.normal,
        BeatAccent.normal,
      ],
      description: 'Compound Duple • Blues Shuffle, Rock Ballads',
    ),
    TimeSignaturePreset(
      name: '12/8',
      beatsPerBar: 12,
      beatUnit: 8,
      defaultAccents: [
        BeatAccent.strong,
        BeatAccent.normal,
        BeatAccent.normal,
        BeatAccent.medium,
        BeatAccent.normal,
        BeatAccent.normal,
        BeatAccent.medium,
        BeatAccent.normal,
        BeatAccent.normal,
        BeatAccent.medium,
        BeatAccent.normal,
        BeatAccent.normal,
      ],
      description: 'Slow Blues & Soul • 4 Triplet Groups',
    ),
    TimeSignaturePreset(
      name: '5/4',
      beatsPerBar: 5,
      beatUnit: 4,
      defaultAccents: [
        BeatAccent.strong,
        BeatAccent.normal,
        BeatAccent.normal,
        BeatAccent.medium,
        BeatAccent.normal,
      ],
      description: 'Odd Meter (3+2) • Progressive Rock, Jazz',
    ),
    TimeSignaturePreset(
      name: '7/8',
      beatsPerBar: 7,
      beatUnit: 8,
      defaultAccents: [
        BeatAccent.strong,
        BeatAccent.normal,
        BeatAccent.medium,
        BeatAccent.normal,
        BeatAccent.medium,
        BeatAccent.normal,
        BeatAccent.normal,
      ],
      description: 'Complex Odd Meter (2+2+3) • Prog Metal, Balkan',
    ),
    TimeSignaturePreset(
      name: '1/1',
      beatsPerBar: 1,
      beatUnit: 4,
      defaultAccents: [
        BeatAccent.normal,
      ],
      description: 'Continuous Click • Unaccented Speed Drills',
    ),
  ];
}

class TempoMarking {
  final String italianName;
  final String englishDescription;
  final int minBpm;
  final int maxBpm;

  const TempoMarking(this.italianName, this.englishDescription, this.minBpm, this.maxBpm);

  static const List<TempoMarking> markings = [
    TempoMarking('Grave', 'Very slow & solemn', 20, 44),
    TempoMarking('Largo', 'Slow & broad', 45, 59),
    TempoMarking('Adagio', 'Slow & stately', 60, 75),
    TempoMarking('Andante', 'Walking pace', 76, 107),
    TempoMarking('Moderato', 'Moderate', 108, 119),
    TempoMarking('Allegro', 'Fast & bright', 120, 155),
    TempoMarking('Vivace', 'Lively & brisk', 156, 175),
    TempoMarking('Presto', 'Very fast', 176, 199),
    TempoMarking('Prestissimo', 'Extremely fast', 200, 320),
  ];

  static TempoMarking getForBpm(int bpm) {
    for (final m in markings) {
      if (bpm >= m.minBpm && bpm <= m.maxBpm) {
        return m;
      }
    }
    return markings.last;
  }
}
