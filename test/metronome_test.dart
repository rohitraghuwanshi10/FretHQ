import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frethq/models/metronome_pattern.dart';
import 'package:frethq/services/metronome_service.dart';
import 'package:frethq/widgets/metronome_pendulum_widget.dart';
import 'package:frethq/screens/tuner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (MethodCall methodCall) async {
    return 1;
  });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (MethodCall methodCall) async {
    return 1;
  });

  group('Metronome Models & Theory Tests', () {
    test('TimeSignaturePreset presets contain all 8 standard signatures', () {
      expect(TimeSignaturePreset.presets.length, equals(8));
      final names = TimeSignaturePreset.presets.map((p) => p.name).toList();
      expect(names, containsAll(['4/4', '3/4', '2/4', '6/8', '12/8', '5/4', '7/8', '1/1']));
    });

    test('4/4 time signature has 4 beats with strong downbeat and medium secondary accent', () {
      final sig44 = TimeSignaturePreset.presets.firstWhere((p) => p.name == '4/4');
      expect(sig44.beatsPerBar, equals(4));
      expect(sig44.defaultAccents.length, equals(4));
      expect(sig44.defaultAccents[0], equals(BeatAccent.strong));
      expect(sig44.defaultAccents[1], equals(BeatAccent.normal));
      expect(sig44.defaultAccents[2], equals(BeatAccent.medium));
      expect(sig44.defaultAccents[3], equals(BeatAccent.normal));
    });

    test('6/8 time signature has 6 pulses with accents on 1 and 4', () {
      final sig68 = TimeSignaturePreset.presets.firstWhere((p) => p.name == '6/8');
      expect(sig68.beatsPerBar, equals(6));
      expect(sig68.defaultAccents[0], equals(BeatAccent.strong));
      expect(sig68.defaultAccents[3], equals(BeatAccent.medium));
    });

    test('Subdivision pulses calculate correctly', () {
      expect(Subdivision.quarter.pulsesPerBeat, equals(1));
      expect(Subdivision.eighth.pulsesPerBeat, equals(2));
      expect(Subdivision.triplet.pulsesPerBeat, equals(3));
      expect(Subdivision.sixteenth.pulsesPerBeat, equals(4));
    });

    test('TempoMarking returns correct Italian terms for BPMs', () {
      expect(TempoMarking.getForBpm(50).italianName, equals('Largo'));
      expect(TempoMarking.getForBpm(70).italianName, equals('Adagio'));
      expect(TempoMarking.getForBpm(95).italianName, equals('Andante'));
      expect(TempoMarking.getForBpm(115).italianName, equals('Moderato'));
      expect(TempoMarking.getForBpm(130).italianName, equals('Allegro'));
      expect(TempoMarking.getForBpm(165).italianName, equals('Vivace'));
      expect(TempoMarking.getForBpm(185).italianName, equals('Presto'));
      expect(TempoMarking.getForBpm(220).italianName, equals('Prestissimo'));
    });
  });

  group('MetronomeService Unit Tests', () {
    late MetronomeService service;

    setUp(() {
      service = MetronomeService.instance;
      service.stop();
      service.setBpm(120);
      service.setTimeSignature(TimeSignaturePreset.presets[0]); // 4/4
      service.setSubdivision(Subdivision.quarter);
      service.setSpeedTrainer(enabled: false);
      service.setTimerDuration(null);
    });

    tearDown(() {
      service.stop();
    });

    test('BPM clamps within valid range 30 to 300', () {
      service.setBpm(20);
      expect(service.bpm, equals(30));

      service.setBpm(350);
      expect(service.bpm, equals(300));

      service.setBpm(140);
      expect(service.bpm, equals(140));

      service.adjustBpm(5);
      expect(service.bpm, equals(145));

      service.adjustBpm(-10);
      expect(service.bpm, equals(135));
    });

    test('Toggle beat accent cycles through states', () {
      // 4/4 Beat 0 starts as strong
      expect(service.accents[0], equals(BeatAccent.strong));

      service.toggleBeatAccent(0); // strong -> medium
      expect(service.accents[0], equals(BeatAccent.medium));

      service.toggleBeatAccent(0); // medium -> normal
      expect(service.accents[0], equals(BeatAccent.normal));

      service.toggleBeatAccent(0); // normal -> mute
      expect(service.accents[0], equals(BeatAccent.mute));

      service.toggleBeatAccent(0); // mute -> strong
      expect(service.accents[0], equals(BeatAccent.strong));
    });

    test('Start and stop changes isPlaying state', () {
      expect(service.isPlaying, isFalse);
      service.start();
      expect(service.isPlaying, isTrue);
      service.stop();
      expect(service.isPlaying, isFalse);
    });

    test('Practice timer duration initializes and countdown updates', () {
      service.setTimerDuration(300); // 5 minutes
      expect(service.timerDurationSeconds, equals(300));
      expect(service.remainingSeconds, equals(300));

      service.setTimerDuration(null); // Continuous
      expect(service.timerDurationSeconds, isNull);
    });
  });

  group('Metronome Widget Tests', () {
    testWidgets('MetronomePendulumWidget renders BPM and pendulum canvas', (WidgetTester tester) async {
      final service = MetronomeService.instance;
      service.setBpm(120);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetronomePendulumWidget(metronomeService: service),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('120'), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
      expect(find.textContaining('ALLEGRO'), findsOneWidget);
      expect(find.byType(MetronomePendulumWidget), findsOneWidget);
    });

    testWidgets('TunerScreen renders Metronome tab with steppers, timer chips, and time signatures', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TunerScreen(initialTabIndex: 2), // Open directly to Metronome tab
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Metronome'), findsOneWidget);
      expect(find.text('TAP TEMPO'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('3/4'), findsOneWidget);
      expect(find.text('6/8'), findsOneWidget);
      expect(find.text('PRACTICE TIMER (AUTO-STOP)'), findsOneWidget);
      expect(find.text('∞ Continuous'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
      expect(find.text('Speed Trainer (Auto-Increment)'), findsOneWidget);
    });
  });
}
