import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_session.dart';
import '../models/note.dart';
import '../services/high_score_service.dart';
import '../services/database_helper.dart';
import '../widgets/interactive_fretboard_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
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

    final isCorrect = _session.answer(userNote);

    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    _flashTimer?.cancel();
    setState(() {
      _lastTappedPosition = tappedPosition;
      _flashColor = isCorrect ? AppColors.emerald : AppColors.coral;
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
    final timerRatio = widget.durationSeconds > 0
        ? _session.secondsRemaining / widget.durationSeconds
        : 0.0;
    final isLowTime = _session.secondsRemaining <= 10;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Find Fret • ${durationMins}m ${widget.isWeakSpotFocus ? "(Weak Spots)" : (widget.includeAccidentals ? "(Full)" : "(Easy)")}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer
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
                                  isLowTime ? AppColors.coral : AppColors.cyan,
                                ),
                              ),
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: isLowTime ? AppColors.coral : AppColors.cyan,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_session.secondsRemaining}s',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isLowTime ? AppColors.coral : Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // Streak
                    if (_session.currentStreak >= 3)
                      GlassBadge(
                        text: '${_session.currentStreak} Streak 🔥',
                        color: AppColors.orange,
                        icon: Icons.bolt_rounded,
                        fontSize: 11,
                      ),

                    // Score
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
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Target Prompt Banner
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'TAP THE FRET LOCATION FOR:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (targetNote != null && currentTarget != null) ...[
                      // Glowing Target Note Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B32),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          targetNote.displayName,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: AppColors.gold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // String Constraint Subtitle Pill
                      GlassBadge(
                        text: 'ON ${_getStringName(currentTarget.stringNumber).toUpperCase()}',
                        color: AppColors.cyan,
                        icon: Icons.music_note_rounded,
                        fontSize: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Interactive Fretboard Widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
              child: Column(
                children: [
                  const Text(
                    'Tap string and fret location on guitar neck below',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
}
