import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

class TunerNote {
  final String noteName; // e.g. "E", "A", "F#"
  final int octave; // e.g. 2, 3, 4
  final double targetFrequency; // e.g. 82.41 Hz
  final double detectedFrequency; // e.g. 82.35 Hz
  final double centsOffset; // e.g. -1.2 cents (-50 to +50)
  final bool isInTune; // true if within |cents| <= 2.5

  TunerNote({
    required this.noteName,
    required this.octave,
    required this.targetFrequency,
    required this.detectedFrequency,
    required this.centsOffset,
    required this.isInTune,
  });

  String get fullDisplay => '$noteName$octave';

  static final List<String> chromaticNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  /// Standard guitar string reference notes
  static final List<TunerNote> standardGuitarStrings = [
    fromFrequency(82.41),  // Low E (E2)
    fromFrequency(110.00), // A2
    fromFrequency(146.83), // D3
    fromFrequency(196.00), // G3
    fromFrequency(246.94), // B3
    fromFrequency(329.63), // High E (E4)
  ];

  /// Calculate nearest note, target frequency, and cents offset for any frequency
  static TunerNote fromFrequency(double freq) {
    if (freq <= 0 || freq.isNaN || freq.isInfinite) {
      return TunerNote(
        noteName: '--',
        octave: 0,
        targetFrequency: 0,
        detectedFrequency: 0,
        centsOffset: 0,
        isInTune: false,
      );
    }

    // A4 = 440 Hz is MIDI note 69
    final midiNumDouble = 12 * (log(freq / 440.0) / log(2)) + 69;
    final midiNum = midiNumDouble.round();

    final noteIndex = (midiNum - 12) % 12;
    final name = chromaticNames[noteIndex < 0 ? noteIndex + 12 : noteIndex];
    final oct = ((midiNum - 12) ~/ 12);

    final targetFreq = 440.0 * pow(2, (midiNum - 69) / 12);
    final cents = 1200 * (log(freq / targetFreq) / log(2));
    final clampedCents = cents.clamp(-50.0, 50.0);

    return TunerNote(
      noteName: name,
      octave: oct,
      targetFrequency: targetFreq,
      detectedFrequency: freq,
      centsOffset: clampedCents,
      isInTune: cents.abs() <= 2.5,
    );
  }
}

class PitchService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  late PitchDetector _pitchDetector;
  StreamSubscription<Uint8List>? _audioSubscription;
  final _pitchController = StreamController<TunerNote>.broadcast();

  Stream<TunerNote> get pitchStream => _pitchController.stream;
  bool _isListening = false;
  bool get isListening => _isListening;

  PitchService() {
    _pitchDetector = PitchDetector(audioSampleRate: 44100, bufferSize: 2048);
  }

  /// Start listening to microphone PCM stream
  Future<bool> startListening() async {
    if (_isListening) return true;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      debugPrint('PitchService: hasPermission = $hasPermission');
      if (!hasPermission) {
        debugPrint('PitchService: Microphone permission denied');
        return false;
      }

      debugPrint('PitchService: Starting audio stream (sampleRate=44100)...');
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );

      _isListening = true;
      _audioSubscription = stream.listen((uint8List) {
        _processAudioBuffer(uint8List);
      }, onError: (err) {
        debugPrint('PitchService error in stream listener: $err');
      });

      debugPrint('PitchService: Audio stream listener registered successfully!');
      return true;
    } catch (e, st) {
      debugPrint('PitchService failed to start microphone: $e\n$st');
      _isListening = false;
      return false;
    }
  }

  final List<int> _audioAccumulator = [];

  void _processAudioBuffer(Uint8List chunk) {
    if (chunk.isEmpty) return;
    _audioAccumulator.addAll(chunk);

    // 2048 16-bit PCM samples = 4096 bytes required by PitchDetector
    const targetByteLength = 4096;

    while (_audioAccumulator.length >= targetByteLength) {
      final pcmSlice = Uint8List.fromList(_audioAccumulator.sublist(0, targetByteLength));
      _audioAccumulator.removeRange(0, 2048); // 50% overlap for responsive tracking

      _analyzePcmBuffer(pcmSlice);
    }
  }

  // Pitch stabilization pipeline buffers
  final List<double> _pitchHistory = [];
  double _lockedFundamental = 0.0;
  double _smoothedFreq = 0.0;
  DateTime? _lastValidPitchTime;

  Future<void> _analyzePcmBuffer(Uint8List buffer) async {
    final byteData = buffer.buffer.asByteData(buffer.offsetInBytes, buffer.length);
    final int samplesCount = buffer.length ~/ 2;
    final List<double> floatList = List<double>.filled(samplesCount, 0.0);

    double sumSquare = 0.0;
    for (int i = 0; i < samplesCount; i++) {
      final int sampleInt16 = byteData.getInt16(i * 2, Endian.little);
      final double sampleFloat = sampleInt16 / 32768.0;
      floatList[i] = sampleFloat;
      sumSquare += sampleFloat * sampleFloat;
    }

    final double rms = sqrt(sumSquare / (samplesCount > 0 ? samplesCount : 1));

    // Dynamic noise floor gate: RMS >= 0.018 (~ -35 dB)
    if (rms < 0.018) {
      if (_lastValidPitchTime != null &&
          DateTime.now().difference(_lastValidPitchTime!).inMilliseconds > 900) {
        _pitchHistory.clear();
        _lockedFundamental = 0.0;
        _smoothedFreq = 0.0;
        _pitchController.add(TunerNote.fromFrequency(0));
      }
      return;
    }

    try {
      final result = await _pitchDetector.getPitchFromFloatBuffer(floatList);
      final rawPitch = result.pitch;

      // Filter: guitar frequency range (65 Hz to 1200 Hz) with high confidence
      if (rawPitch >= 65 && rawPitch <= 1200 && (result.pitched || result.probability >= 0.72)) {
        _lastValidPitchTime = DateTime.now();

        // 1. Harmonic Disambiguation (prevent jumping to 2nd/3rd harmonics or subharmonics)
        final resolvedPitch = _resolveHarmonics(rawPitch, _lockedFundamental);

        // 2. Rolling Median Filter to reject attack noise transients and outlier spikes
        _pitchHistory.add(resolvedPitch);
        if (_pitchHistory.length > 5) {
          _pitchHistory.removeAt(0);
        }
        final medianPitch = _computeMedian(_pitchHistory);

        // 3. Note Lock & Low-Pass Smoothing
        if (_lockedFundamental == 0.0 || (medianPitch - _lockedFundamental).abs() > 45) {
          // New string or fret note plucked
          _lockedFundamental = medianPitch;
          _smoothedFreq = medianPitch;
        } else {
          // Note sustaining: gentle Low-Pass filter for stable, jitter-free needle
          _smoothedFreq = 0.30 * medianPitch + 0.70 * _smoothedFreq;
          _lockedFundamental = _smoothedFreq;
        }

        final tunerNote = TunerNote.fromFrequency(_smoothedFreq);
        _pitchController.add(tunerNote);
      }
    } catch (e) {
      debugPrint('Pitch processing error: $e');
    }
  }

  /// Harmonic Disambiguation: Detects if detected frequency is a harmonic overtone
  /// (2x octave, 3x fifth, 4x double octave) of the currently vibrating string.
  double _resolveHarmonics(double detected, double currentFundamental) {
    if (currentFundamental <= 0) return detected;

    // Check if detected is 2x or 3x harmonic of current fundamental
    for (int multiplier = 2; multiplier <= 4; multiplier++) {
      final harmonic = currentFundamental * multiplier;
      if ((detected - harmonic).abs() / harmonic < 0.05) {
        return currentFundamental; // Lock to fundamental
      }
    }

    // Check if current is 2x harmonic of detected (subharmonic resolution)
    final subHarmonic = currentFundamental / 2.0;
    if ((detected - subHarmonic).abs() / subHarmonic < 0.05 && detected >= 70.0) {
      return detected;
    }

    return detected;
  }

  /// Computes median of recent pitch samples
  double _computeMedian(List<double> list) {
    if (list.isEmpty) return 0.0;
    final sorted = List<double>.from(list)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
  }

  /// Manually inject a detected frequency (for testing or simulation)
  void injectFrequency(double frequency) {
    final tunerNote = TunerNote.fromFrequency(frequency);
    _pitchController.add(tunerNote);
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      await _audioRecorder.stop();
    } catch (e) {
      debugPrint('PitchService stop error: $e');
    } finally {
      _isListening = false;
      _pitchHistory.clear();
      _lockedFundamental = 0.0;
      _smoothedFreq = 0.0;
    }
  }

  void dispose() {
    stopListening();
    _pitchController.close();
    _audioRecorder.dispose();
  }
}
