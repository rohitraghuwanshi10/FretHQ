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
      if (!hasPermission) {
        debugPrint('PitchService: Microphone permission denied');
        return false;
      }

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
        debugPrint('PitchService error: $err');
      });

      return true;
    } catch (e) {
      debugPrint('PitchService failed to start microphone: $e');
      _isListening = false;
      return false;
    }
  }

  Future<void> _processAudioBuffer(Uint8List buffer) async {
    if (buffer.length < 2048) return;

    try {
      final result = await _pitchDetector.getPitchFromIntBuffer(buffer);
      if (result.pitched && result.pitch > 40 && result.pitch < 1000) {
        final tunerNote = TunerNote.fromFrequency(result.pitch);
        _pitchController.add(tunerNote);
      }
    } catch (e) {
      debugPrint('Pitch processing error: $e');
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
    }
  }

  void dispose() {
    stopListening();
    _pitchController.close();
    _audioRecorder.dispose();
  }
}
