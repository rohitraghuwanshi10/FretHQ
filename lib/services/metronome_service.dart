import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/metronome_pattern.dart';

class MetronomeTickEvent {
  final int barCount;
  final int beatIndex; // 0 to beatsPerBar - 1
  final int subdivisionIndex; // 0 to pulsesPerBeat - 1
  final BeatAccent accent;
  final bool isDownbeat;
  final int bpm;

  const MetronomeTickEvent({
    required this.barCount,
    required this.beatIndex,
    required this.subdivisionIndex,
    required this.accent,
    required this.isDownbeat,
    required this.bpm,
  });
}

class MetronomeAudioEngine {
  List<AudioPlayer>? _players;
  int _playerIndex = 0;

  static final _strongAsset = AssetSource('audio/click_strong.wav');
  static final _mediumAsset = AssetSource('audio/click_medium.wav');
  static final _normalAsset = AssetSource('audio/click_normal.wav');
  static final _subAsset = AssetSource('audio/click_sub.wav');

  MetronomeAudioEngine() {
    _initPlayers();
  }

  void _initPlayers() {
    try {
      _players = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
      for (final p in _players!) {
        p.setReleaseMode(ReleaseMode.stop);
        p.setVolume(1.0);
      }
    } catch (e) {
      debugPrint('MetronomeAudioEngine init: $e');
    }
  }

  void playAccent(BeatAccent accent) {
    if (accent == BeatAccent.mute) return;

    final source = switch (accent) {
      BeatAccent.strong => _strongAsset,
      BeatAccent.medium => _mediumAsset,
      BeatAccent.normal => _normalAsset,
      BeatAccent.mute => _normalAsset,
    };

    _playSource(source);
  }

  void playSubdivision() {
    _playSource(_subAsset);
  }

  void _playSource(Source source) {
    if (_players == null || _players!.isEmpty) return;
    try {
      final player = _players![_playerIndex];
      _playerIndex = (_playerIndex + 1) % _players!.length;
      player.stop().then((_) {
        player.play(source).catchError((e) {
          debugPrint('Audio playback error: $e');
        });
      });
    } catch (e) {
      debugPrint('MetronomeAudioEngine error: $e');
    }
  }

  void dispose() {
    if (_players != null) {
      for (final p in _players!) {
        p.dispose();
      }
    }
  }
}

class MetronomeService {
  static final MetronomeService instance = MetronomeService._internal();
  MetronomeService._internal() {
    _audioEngine = MetronomeAudioEngine();
  }

  late final MetronomeAudioEngine _audioEngine;

  int _bpm = 120;
  bool _isPlaying = false;
  TimeSignaturePreset _timeSignature = TimeSignaturePreset.presets[0]; // 4/4
  List<BeatAccent> _accents = List.from(TimeSignaturePreset.presets[0].defaultAccents);
  Subdivision _subdivision = Subdivision.quarter;

  // Speed Trainer
  bool _speedTrainerEnabled = false;
  int _speedTrainerIncrement = 2; // +2 BPM
  int _speedTrainerBars = 4; // every 4 bars

  // Settings
  bool _hapticsEnabled = true;
  bool _soundEnabled = true;

  // State Tracking
  int _currentBar = 0;
  int _currentBeat = 0;
  int _currentSubdivision = 0;
  Timer? _timer;

  final _tickController = StreamController<MetronomeTickEvent>.broadcast();
  Stream<MetronomeTickEvent> get tickStream => _tickController.stream;

  // Tap Tempo state
  final List<DateTime> _tapTimestamps = [];

  // Getters
  int get bpm => _bpm;
  bool get isPlaying => _isPlaying;
  TimeSignaturePreset get timeSignature => _timeSignature;
  List<BeatAccent> get accents => List.unmodifiable(_accents);
  Subdivision get subdivision => _subdivision;
  bool get speedTrainerEnabled => _speedTrainerEnabled;
  int get speedTrainerIncrement => _speedTrainerIncrement;
  int get speedTrainerBars => _speedTrainerBars;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get soundEnabled => _soundEnabled;
  int get currentBeat => _currentBeat;
  int get currentBar => _currentBar;

  void setBpm(int newBpm) {
    final clamped = newBpm.clamp(30, 300);
    if (_bpm != clamped) {
      _bpm = clamped;
      if (_isPlaying) {
        _restartTimer();
      }
    }
  }

  void adjustBpm(int delta) {
    setBpm(_bpm + delta);
  }

  void setTimeSignature(TimeSignaturePreset preset) {
    _timeSignature = preset;
    _accents = List.from(preset.defaultAccents);
    _currentBeat = 0;
    _currentSubdivision = 0;
    if (_isPlaying) {
      _restartTimer();
    }
  }

  void setAccent(int beatIndex, BeatAccent accent) {
    if (beatIndex >= 0 && beatIndex < _accents.length) {
      _accents[beatIndex] = accent;
    }
  }

  void toggleBeatAccent(int beatIndex) {
    if (beatIndex < 0 || beatIndex >= _accents.length) return;
    final current = _accents[beatIndex];
    final next = switch (current) {
      BeatAccent.strong => BeatAccent.medium,
      BeatAccent.medium => BeatAccent.normal,
      BeatAccent.normal => BeatAccent.mute,
      BeatAccent.mute => BeatAccent.strong,
    };
    _accents[beatIndex] = next;
  }

  void setSubdivision(Subdivision sub) {
    _subdivision = sub;
    _currentSubdivision = 0;
    if (_isPlaying) {
      _restartTimer();
    }
  }

  void setSpeedTrainer({
    required bool enabled,
    int? increment,
    int? bars,
  }) {
    _speedTrainerEnabled = enabled;
    if (increment != null) _speedTrainerIncrement = increment;
    if (bars != null) _speedTrainerBars = bars;
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _currentBar = 0;
    _currentBeat = 0;
    _currentSubdivision = 0;
    _restartTimer();
    _handleTick(); // Immediate first tick
  }

  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _currentBeat = 0;
    _currentSubdivision = 0;
  }

  void togglePlay() {
    if (_isPlaying) {
      stop();
    } else {
      start();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_isPlaying) return;

    final totalPulsesPerBeat = _subdivision.pulsesPerBeat;
    final microsecPerTick = ((60 * 1000 * 1000) / (_bpm * totalPulsesPerBeat)).round();

    _timer = Timer.periodic(Duration(microseconds: microsecPerTick), (t) {
      _handleTick();
    });
  }

  void _handleTick() {
    final accent = _currentBeat < _accents.length ? _accents[_currentBeat] : BeatAccent.normal;
    final isDownbeat = _currentBeat == 0 && _currentSubdivision == 0;

    // Trigger Sound & Haptics
    if (_currentSubdivision == 0) {
      // Main beat
      if (accent != BeatAccent.mute) {
        if (_soundEnabled) {
          _audioEngine.playAccent(accent);
        }
        if (_hapticsEnabled) {
          switch (accent) {
            case BeatAccent.strong:
              HapticFeedback.heavyImpact();
              break;
            case BeatAccent.medium:
              HapticFeedback.mediumImpact();
              break;
            case BeatAccent.normal:
              HapticFeedback.lightImpact();
              break;
            case BeatAccent.mute:
              break;
          }
        }
      }
    } else {
      // Subdivision pulse
      if (_soundEnabled && accent != BeatAccent.mute) {
        _audioEngine.playSubdivision();
      }
    }

    // Dispatch event
    _tickController.add(MetronomeTickEvent(
      barCount: _currentBar,
      beatIndex: _currentBeat,
      subdivisionIndex: _currentSubdivision,
      accent: accent,
      isDownbeat: isDownbeat,
      bpm: _bpm,
    ));

    // Advance counters
    _currentSubdivision++;
    if (_currentSubdivision >= _subdivision.pulsesPerBeat) {
      _currentSubdivision = 0;
      _currentBeat++;

      if (_currentBeat >= _timeSignature.beatsPerBar) {
        _currentBeat = 0;
        _currentBar++;

        // Speed Trainer check on bar completion
        if (_speedTrainerEnabled && _currentBar > 0 && _currentBar % _speedTrainerBars == 0) {
          if (_bpm + _speedTrainerIncrement <= 300) {
            _bpm += _speedTrainerIncrement;
            _restartTimer();
          }
        }
      }
    }
  }

  /// Calculates BPM based on tapping intervals
  int? recordTapTempo() {
    final now = DateTime.now();

    if (_tapTimestamps.isNotEmpty) {
      final diff = now.difference(_tapTimestamps.last).inMilliseconds;
      if (diff > 2000) {
        _tapTimestamps.clear(); // Reset after 2s idle
      }
    }

    _tapTimestamps.add(now);

    if (_tapTimestamps.length > 5) {
      _tapTimestamps.removeAt(0); // Keep last 5 taps
    }

    if (_tapTimestamps.length >= 2) {
      int totalDelta = 0;
      for (int i = 1; i < _tapTimestamps.length; i++) {
        totalDelta += _tapTimestamps[i].difference(_tapTimestamps[i - 1]).inMilliseconds;
      }
      final avgDelta = totalDelta / (_tapTimestamps.length - 1);
      if (avgDelta > 0) {
        final calculatedBpm = (60000.0 / avgDelta).round().clamp(30, 300);
        setBpm(calculatedBpm);
        return calculatedBpm;
      }
    }
    return null;
  }

  void dispose() {
    _timer?.cancel();
    _audioEngine.dispose();
    _tickController.close();
  }
}
