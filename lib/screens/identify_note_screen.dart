import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_session.dart';
import '../models/note.dart';
import '../services/high_score_service.dart';
import '../services/database_helper.dart';
import '../widgets/fretboard_widget.dart';
import '../widgets/note_keypad_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class IdentifyNoteScreen extends StatefulWidget {
  final int durationSeconds;
  final bool includeAccidentals;
  final bool isWeakSpotFocus;
  final List<TargetPosition>? weakTargetPositions;

  const IdentifyNoteScreen({
    super.key,
    this.durationSeconds = 60,
    this.includeAccidentals = true,
    this.isWeakSpotFocus = false,
    this.weakTargetPositions,
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

    await DatabaseHelper.instance.saveGameSession(_session, modeName);

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

    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _flashColor = isCorrect ? AppColors.emerald : AppColors.coral;
    });

    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 280), () {
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
    final timerRatio = widget.durationSeconds > 0
        ? _session.secondsRemaining / widget.durationSeconds
        : 0.0;
    final isLowTime = _session.secondsRemaining <= 10;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Identify Note • ${durationMins}m ${widget.isWeakSpotFocus ? "(Weak Spots)" : (widget.includeAccidentals ? "(Full)" : "(Easy)")}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top HUD
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Timer with animated indicator
                        Row(
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: timerRatio,
                                    strokeWidth: 3,
                                    backgroundColor: Colors.white10,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isLowTime ? AppColors.coral : AppColors.primary,
                                    ),
                                  ),
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: isLowTime ? AppColors.coral : AppColors.primary,
                                  ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatTimerText(_session.secondsRemaining),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isLowTime ? AppColors.coral : Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // Streak Badge
                    if (_session.currentStreak >= 3)
                      GlassBadge(
                        text: '${_session.currentStreak} Streak 🔥',
                        color: AppColors.orange,
                        icon: Icons.bolt_rounded,
                        fontSize: 11,
                      ),

                    // Score Display
                    Row(
                      children: [
                        const Text(
                          'Score: ',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${_session.correctCount}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Photorealistic 6-String Fretboard
              FretboardWidget(
                targetPosition: targetPos,
                maxFret: 12,
                flashColor: _flashColor,
              ),

              const SizedBox(height: 14),

              // Target Prompt Guidance Card
              if (targetPos != null)
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  borderColor: AppColors.gold.withValues(alpha: 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'What note is on ',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${targetPos.stringName} String',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold, fontSize: 13),
                        ),
                      ),
                      const Text(
                        ' at ',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          targetPos.fretNumber == 0 ? 'Open (Fret 0)' : 'Fret ${targetPos.fretNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.cyan, fontSize: 13),
                        ),
                      ),
                      const Text(
                        ' ?',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // Note Keypad Answer Grid
              NoteKeypadWidget(
                onNoteSelected: _handleNoteInput,
                isEnabled: _session.status == GameStatus.playing,
                allowAccidentals: widget.includeAccidentals,
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
