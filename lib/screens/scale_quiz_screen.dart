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
    await DatabaseHelper.instance.saveGameSession(_session, 'game3_scale_interval');

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
    final isLowTime = _session.secondsRemaining <= 10;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scale & Interval Quiz • ${durationMins}m',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
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
              NoteKeypadWidget(
                onNoteSelected: _handleNoteInput,
                isEnabled: _session.status == GameStatus.playing,
                allowAccidentals: true,
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
