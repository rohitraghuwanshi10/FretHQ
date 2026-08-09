import 'dart:math';

enum IntonationStatus {
  ideal,
  sharp,
  flat,
  incomplete,
}

class StringIntonationResult {
  final int stringNumber; // 1 to 6
  final String stringName; // e.g. "Low E (6)"
  final double openFrequency; // Hz
  final double fret12Frequency; // Hz
  final double centsDeviation; // e.g. +7.2 cents or -4.5 cents
  final IntonationStatus status;

  StringIntonationResult({
    required this.stringNumber,
    required this.stringName,
    required this.openFrequency,
    required this.fret12Frequency,
    required this.centsDeviation,
    required this.status,
  });

  /// Recommendation instruction for guitar bridge saddle adjustment
  String get saddleRecommendation {
    switch (status) {
      case IntonationStatus.ideal:
        return 'Intonation is perfect! No saddle adjustment needed.';
      case IntonationStatus.sharp:
        final dist = (centsDeviation.abs() * 0.08).toStringAsFixed(1);
        return '12th fret is SHARP (+${centsDeviation.toStringAsFixed(1)} cents). Move saddle BACK (away from neck) by ~$dist mm.';
      case IntonationStatus.flat:
        final dist = (centsDeviation.abs() * 0.08).toStringAsFixed(1);
        return '12th fret is FLAT (${centsDeviation.toStringAsFixed(1)} cents). Move saddle FORWARD (towards neck) by ~$dist mm.';
      case IntonationStatus.incomplete:
        return 'Pluck open string, then pluck 12th fret to check intonation.';
    }
  }

  /// Calculates cents deviation between 12th fret frequency and 1 octave above open frequency
  static StringIntonationResult calculate({
    required int stringNumber,
    required String stringName,
    required double openFreq,
    required double fret12Freq,
  }) {
    if (openFreq <= 0 || fret12Freq <= 0) {
      return StringIntonationResult(
        stringNumber: stringNumber,
        stringName: stringName,
        openFrequency: openFreq,
        fret12Frequency: fret12Freq,
        centsDeviation: 0.0,
        status: IntonationStatus.incomplete,
      );
    }

    final targetOctaveFreq = openFreq * 2.0;
    final cents = 1200 * (log(fret12Freq / targetOctaveFreq) / log(2));

    IntonationStatus status;
    if (cents.abs() <= 2.5) {
      status = IntonationStatus.ideal;
    } else if (cents > 2.5) {
      status = IntonationStatus.sharp;
    } else {
      status = IntonationStatus.flat;
    }

    return StringIntonationResult(
      stringNumber: stringNumber,
      stringName: stringName,
      openFrequency: openFreq,
      fret12Frequency: fret12Freq,
      centsDeviation: cents,
      status: status,
    );
  }
}

class IntonationService {
  final Map<int, StringIntonationResult> _results = {};

  static const List<Map<String, dynamic>> stringDefs = [
    {'num': 1, 'name': 'High E', 'freq': 329.63},
    {'num': 2, 'name': 'B String', 'freq': 246.94},
    {'num': 3, 'name': 'G String', 'freq': 196.00},
    {'num': 4, 'name': 'D String', 'freq': 146.83},
    {'num': 5, 'name': 'A String', 'freq': 110.00},
    {'num': 6, 'name': 'Low E', 'freq': 82.41},
  ];

  StringIntonationResult? getResult(int stringNum) => _results[stringNum];

  Map<int, StringIntonationResult> get allResults => Map.unmodifiable(_results);

  void recordResult({
    required int stringNumber,
    required double openFreq,
    required double fret12Freq,
  }) {
    final def = stringDefs.firstWhere((s) => s['num'] == stringNumber);
    final res = StringIntonationResult.calculate(
      stringNumber: stringNumber,
      stringName: def['name'] as String,
      openFreq: openFreq,
      fret12Freq: fret12Freq,
    );
    _results[stringNumber] = res;
  }

  void clear() {
    _results.clear();
  }
}
