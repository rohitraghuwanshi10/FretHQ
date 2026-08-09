import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/note.dart';
import '../services/high_score_service.dart';
import '../services/database_helper.dart';
import '../widgets/interactive_fretboard_widget.dart';
import 'results_screen.dart';

class FindFretScreen extends StatefulWidget {
  final int durationSeconds;
  final bool includeAccidentals;
  final bool isWeakSpotFocus;
  final List<TargetPosition>? weakTargetPositions;

  const FindFretScreen({
    super.key,
    this.durationSeconds = 60,
    this.includeAccidentals = true,
    this.isWeakSpotFocus = false,
    this.weakTargetPositions,
  });

  @override
  State<FindFretScreen> createState() => _FindFretScreenState();
}

class _FindFretScreenState extends State<FindFretScreen> {
  late GameSession _session;
  Timer? _timer;
  Color _flashColor = Colors.transparent;
  Timer? _flashTimer;
  TargetPosition? _lastTappedPosition;
  bool _isNewHighScore = false;

  @override
  void initState() {
    super.initState();
    _session = GameSession(
      durationSeconds: widget.durationSeconds,
      includeAccidentals: widget.includeAccidentals,
      isWeakSpotFocus: widget.isWeakSpotFocus,
      weakTargetPositions: widget.weakTargetPositions,
    );
    _startTest();
  }

  void _startTest() {
    _session = GameSession(
      durationSeconds: widget.durationSeconds,
      includeAccidentals: widget.includeAccidentals,
      isWeakSpotFocus: widget.isWeakSpotFocus,
      weakTargetPositions: widget.weakTargetPositions,
    );
    _session.start();
    _isNewHighScore = false;
    _lastTappedPosition = null;
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
    final modeName = widget.isWeakSpotFocus
        ? 'weak_spot'
        : (widget.includeAccidentals ? 'full' : 'easy');

    // Save session and detailed attempt logs to database with game2 tag
    await DatabaseHelper.instance.saveGameSession(_session, 'game2_$modeName');

    final isHigh = await HighScoreService.saveSession(
      score: _session.correctCount,
      accuracy: _session.accuracyPercentage,
      gameKey: 'game2',
    );
    if (!mounted) return;
    setState(() {
      _isNewHighScore = isHigh;
    });
  }

  void _handleFretTap(int stringNumber, int fretNumber) {
    if (_session.status != GameStatus.playing || _session.currentPosition == null) return;

    final tappedPosition = TargetPosition(stringNumber: stringNumber, fretNumber: fretNumber);
    final userNote = tappedPosition.targetNote;
    final targetNote = _session.currentPosition!.targetNote;
    final isExactMatch = stringNumber == _session.currentPosition!.stringNumber &&
        userNote.id == targetNote.id;

    final isCorrect = _session.answer(userNote);

    _flashTimer?.cancel();
    setState(() {
      _lastTappedPosition = tappedPosition;
      _flashColor = isCorrect ? Colors.greenAccent : Colors.redAccent;
    });

    _flashTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _flashColor = Colors.transparent;
        _lastTappedPosition = null;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  String _getStringName(int stringNum) {
    switch (stringNum) {
      case 1:
        return 'High E (String 1)';
      case 2:
        return 'B String (String 2)';
      case 3:
        return 'G String (String 3)';
      case 4:
        return 'D String (String 4)';
      case 5:
        return 'A String (String 5)';
      case 6:
        return 'Low E (String 6)';
      default:
        return 'String $stringNum';
    }
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

    final durationMins = widget.durationSeconds ~/ 60;
    final currentTarget = _session.currentPosition;
    final targetNote = currentTarget?.targetNote;

    return Scaffold(
      backgroundColor: const Color(0xFF121216),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Find Fret - ${durationMins}m (${widget.isWeakSpotFocus ? "Weak Spots" : (widget.includeAccidentals ? "Full" : "Easy Mode")})',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Bar: Score, Timer, Streak
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score
                  _buildHudItem(
                    label: 'SCORE',
                    value: '${_session.correctCount}',
                    color: Colors.amber,
                  ),
                  // Timer
                  _buildHudItem(
                    label: 'TIME LEFT',
                    value: '${_session.secondsRemaining}s',
                    color: _session.secondsRemaining <= 10 ? Colors.redAccent : Colors.cyanAccent,
                  ),
                  // Streak
                  _buildHudItem(
                    label: 'STREAK',
                    value: '${_session.currentStreak} 🔥',
                    color: Colors.orangeAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Target Prompt Banner
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'TAP THE FRET LOCATION FOR:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (targetNote != null && currentTarget != null) ...[
                      // Note Name Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1C2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          targetNote.displayName,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // String Constraint Subtitle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF262438),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ON ${_getStringName(currentTarget.stringNumber).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Interactive Fretboard Widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                children: [
                  Text(
                    'Tap the string and fret position on the neck below',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 8),
                  InteractiveFretboardWidget(
                    selectedPosition: _lastTappedPosition,
                    flashColor: _flashColor,
                    onFretTapped: _handleFretTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudItem({required String label, required String value, required Color color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
