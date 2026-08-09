import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/note.dart';
import '../services/high_score_service.dart';
import '../widgets/fretboard_widget.dart';
import '../widgets/note_keypad_widget.dart';
import 'results_screen.dart';

class IdentifyNoteScreen extends StatefulWidget {
  final int durationSeconds;

  const IdentifyNoteScreen({
    super.key,
    this.durationSeconds = 60,
  });

  @override
  State<IdentifyNoteScreen> createState() => _IdentifyNoteScreenState();
}

class _IdentifyNoteScreenState extends State<IdentifyNoteScreen> {
  late GameSession _session;
  Timer? _timer;
  Color _flashColor = Colors.transparent;
  Timer? _flashTimer;
  bool _isNewHighScore = false;

  @override
  void initState() {
    super.initState();
    _session = GameSession(durationSeconds: widget.durationSeconds);
    _startTest();
  }

  void _startTest() {
    _session = GameSession(durationSeconds: widget.durationSeconds);
    _session.start();
    _isNewHighScore = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _session.tick();
        if (_session.status == GameStatus.finished) {
          _timer?.cancel();
          _onTestFinished();
        }
      });
    });
  }

  Future<void> _onTestFinished() async {
    final isHigh = await HighScoreService.saveSession(
      score: _session.correctCount,
      accuracy: _session.accuracyPercentage,
    );
    if (!mounted) return;
    setState(() {
      _isNewHighScore = isHigh;
    });
  }

  void _handleNoteInput(Note selectedNote) {
    if (_session.status != GameStatus.playing) return;

    final isCorrect = _session.answer(selectedNote);

    // Trigger visual feedback flash
    setState(() {
      _flashColor = isCorrect ? Colors.greenAccent : Colors.redAccent;
    });

    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _flashColor = Colors.transparent;
      });
    });
  }

  String _formatTimerText(int seconds) {
    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return '$mins:${secs.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session.status == GameStatus.finished) {
      return ResultsScreen(
        session: _session,
        isNewHighScore: _isNewHighScore,
        onPlayAgain: () {
          setState(() {
            _startTest();
          });
        },
        onHome: () {
          Navigator.of(context).pop();
        },
      );
    }

    final targetPos = _session.currentPosition;
    final durationMins = widget.durationSeconds ~/ 60;

    return Scaffold(
      backgroundColor: const Color(0xFF121216),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Identify Note - ${durationMins}m Speed Test',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Stats Header (Timer, Score, Streak)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer Gauge
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: _session.secondsRemaining <= 10 ? Colors.redAccent : Colors.amberAccent,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTimerText(_session.secondsRemaining),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _session.secondsRemaining <= 10 ? Colors.redAccent : Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),

                    // Streak Counter
                    if (_session.currentStreak >= 3)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orangeAccent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: Colors.orangeAccent, size: 16),
                            const SizedBox(width: 2),
                            Text(
                              '${_session.currentStreak} Streak!',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Score Display
                    Row(
                      children: [
                        const Text(
                          'Score: ',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        Text(
                          '${_session.correctCount}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Interactive 6-String Guitar Fretboard
              FretboardWidget(
                targetPosition: targetPos,
                maxFret: 12,
                flashColor: _flashColor,
              ),

              const SizedBox(height: 14),

              // Prompt Text Guidance
              if (targetPos != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                      children: [
                        const TextSpan(text: 'What note is on '),
                        TextSpan(
                          text: '${targetPos.stringName} String',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
                        ),
                        const TextSpan(text: ' at '),
                        TextSpan(
                          text: targetPos.fretNumber == 0 ? 'Open (Fret 0)' : 'Fret ${targetPos.fretNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                        ),
                        const TextSpan(text: '?'),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Note Keypad Answer Grid (12 Notes)
              NoteKeypadWidget(
                onNoteSelected: _handleNoteInput,
                isEnabled: _session.status == GameStatus.playing,
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
