import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_session.dart';
import '../models/note.dart';
import '../models/scale_interval.dart';
import '../services/high_score_service.dart';
import '../services/database_helper.dart';
import '../widgets/note_keypad_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import 'results_screen.dart';

class ScaleQuizScreen extends StatefulWidget {
  final int durationSeconds;

  const ScaleQuizScreen({
    super.key,
    this.durationSeconds = 60,
  });

  @override
  State<ScaleQuizScreen> createState() => _ScaleQuizScreenState();
}

class _ScaleQuizScreenState extends State<ScaleQuizScreen> {
  late GameSession _session;
  Timer? _timer;
  Color _flashColor = Colors.transparent;
  Timer? _flashTimer;
  bool _isNewHighScore = false;

  // Question details
  late Note _currentRootNote;
  late MusicalInterval _currentInterval;
  late Note _expectedTargetNote;

  @override
  void initState() {
    super.initState();
    _session = GameSession(durationSeconds: widget.durationSeconds);
    _startTest();
  }

  void _generateNextQuestion() {
    final rand = Random();
    _currentRootNote = Note.chromaticNotes[rand.nextInt(Note.chromaticNotes.length)];

    final candidateIntervals = MusicalInterval.standardIntervals.where((i) => i.semitones > 0).toList();
    _currentInterval = candidateIntervals[rand.nextInt(candidateIntervals.length)];

    final targetIndex = (_currentRootNote.chromaticIndex + _currentInterval.semitones) % 12;
    _expectedTargetNote = Note.chromaticNotes[targetIndex];

    _session.currentPosition = TargetPosition(stringNumber: 6, fretNumber: _currentRootNote.chromaticIndex);
  }

  void _startTest() {
    _session = GameSession(durationSeconds: widget.durationSeconds);
    _session.start();
    _isNewHighScore = false;
    _generateNextQuestion();

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
    final modeKey = widget.durationSeconds <= 0 ? 'game3_scale_interval_untimed' : 'game3_scale_interval';
    await DatabaseHelper.instance.saveGameSession(_session, modeKey);

    final isHigh = await HighScoreService.saveSession(
      score: _session.correctCount,
      accuracy: _session.accuracyPercentage,
      gameKey: 'game3',
    );
    if (!mounted) return;
    setState(() {
      _isNewHighScore = isHigh;
    });
  }

  void _finishSession() {
    _timer?.cancel();
    setState(() {
      _session.finish();
    });
    _onTestFinished();
  }

  void _handleExitAttempt() {
    if (_session.totalAttempts > 0) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceLight : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Leave Practice Session?'),
          content: Text(
            'You answered ${_session.totalAttempts} questions with ${_session.correctCount} correct (${_session.accuracyPercentage.toStringAsFixed(0)}% accuracy). Save and view results?',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Discard & Exit', style: TextStyle(color: AppColors.coral)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _finishSession();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('View Results'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleNoteInput(Note selectedNote) {
    if (_session.status != GameStatus.playing) return;

    final isCorrect = selectedNote == _expectedTargetNote;

    if (isCorrect) {
      HapticFeedback.lightImpact();
      _session.correctCount++;
      _session.currentStreak++;
      if (_session.currentStreak > _session.maxStreak) {
        _session.maxStreak = _session.currentStreak;
      }
    } else {
      HapticFeedback.mediumImpact();
      _session.incorrectCount++;
      _session.currentStreak = 0;
    }

    _session.attemptsHistory.add(AnswerAttempt(
      position: TargetPosition(stringNumber: 6, fretNumber: _expectedTargetNote.chromaticIndex),
      userSelectedNote: selectedNote,
      isCorrect: isCorrect,
    ));

    setState(() {
      _flashColor = isCorrect ? AppColors.emerald : AppColors.coral;
    });

    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        _flashColor = Colors.transparent;
        _generateNextQuestion();
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

    final durationMins = widget.durationSeconds ~/ 60;
    final timerRatio = widget.durationSeconds > 0
        ? _session.secondsRemaining / widget.durationSeconds
        : 0.0;
    final isLowTime = widget.durationSeconds > 0 && _session.secondsRemaining <= 10;
    final isNoTimer = widget.durationSeconds <= 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: _handleExitAttempt,
        ),
        title: Text(
          isNoTimer ? 'Scale & Interval Quiz • Untimed' : 'Scale & Interval Quiz • ${durationMins}m',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _finishSession,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.purple,
                backgroundColor: AppColors.purple.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.purple.withValues(alpha: 0.3)),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: const Text(
                'Finish',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveLayout.contentWidth(context, desktopMaxWidth: 900),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top HUD
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer / Stopwatch display
                    if (isNoTimer)
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.all_inclusive_rounded,
                              size: 16,
                              color: AppColors.purple,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTimerText(_session.elapsedSeconds),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'UNTIMED',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
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
                                    isLowTime ? AppColors.coral : AppColors.purple,
                                  ),
                                ),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: isLowTime ? AppColors.coral : AppColors.purple,
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
                            color: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Question Prompt Card
              GlassCard(
                gradient: AppColors.heroCardGradient,
                borderColor: _flashColor != Colors.transparent
                    ? _flashColor
                    : AppColors.purple.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const Text(
                      'IDENTIFY THE MUSICAL INTERVAL NOTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        // Root Note
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary, width: 1.2),
                          ),
                          child: Text(
                            _currentRootNote.displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Icon(Icons.add_rounded, color: Colors.white54, size: 20),

                        // Interval
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.purple, width: 1.2),
                          ),
                          child: Text(
                            _currentInterval.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'What note is a ${_currentInterval.name} (+${_currentInterval.semitones} semitones) above ${_currentRootNote.displayName}?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Note Keypad
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: NoteKeypadWidget(
                    onNoteSelected: _handleNoteInput,
                    isEnabled: _session.status == GameStatus.playing,
                    allowAccidentals: true,
                  ),
                ),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
