import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/circle_key.dart';
import '../models/game_session.dart';
import '../models/note.dart';
import '../services/database_helper.dart';
import '../services/high_score_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import '../widgets/circle_of_fifths_widget.dart';
import '../widgets/glass_card.dart';
import 'results_screen.dart';

enum CircleQuestionType {
  accidentalCount,
  keyFromAccidentals,
  relativeMinor,
  relativeMajor,
  dominantFifth,
  subdominantFourth,
  chordInKey,
}

class CircleQuizQuestion {
  final CircleQuestionType type;
  final String categoryTitle;
  final String questionText;
  final CircleKey referenceKey;
  final String correctAnswer;
  final List<String> options;
  final String explanation;
  final Note expectedNote;

  CircleQuizQuestion({
    required this.type,
    required this.categoryTitle,
    required this.questionText,
    required this.referenceKey,
    required this.correctAnswer,
    required this.options,
    required this.explanation,
    required this.expectedNote,
  });
}

class CircleQuizScreen extends StatefulWidget {
  final int durationSeconds;

  const CircleQuizScreen({
    super.key,
    this.durationSeconds = 60,
  });

  @override
  State<CircleQuizScreen> createState() => _CircleQuizScreenState();
}

class _CircleQuizScreenState extends State<CircleQuizScreen> {
  late GameSession _session;
  Timer? _timer;
  Color _flashColor = Colors.transparent;
  Timer? _flashTimer;
  bool _isNewHighScore = false;

  late CircleQuizQuestion _currentQuestion;
  String? _selectedAnswer;
  bool _isAnswerLocked = false;

  @override
  void initState() {
    super.initState();
    _startTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  void _startTest() {
    _session = GameSession(durationSeconds: widget.durationSeconds);
    _session.start();
    _isNewHighScore = false;
    _isAnswerLocked = false;
    _selectedAnswer = null;
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

  void _generateNextQuestion() {
    final rand = Random();
    final keys = CircleKey.circleKeys;
    final targetKey = keys[rand.nextInt(keys.length)];

    final type = CircleQuestionType.values[rand.nextInt(CircleQuestionType.values.length)];
    late String categoryTitle;
    late String questionText;
    late String correctAnswer;
    late List<String> distractors;
    late String explanation;
    late Note expectedNote;

    switch (type) {
      case CircleQuestionType.accidentalCount:
        categoryTitle = 'KEY SIGNATURE';
        questionText = 'How many sharps or flats in ${targetKey.majorDisplayName} Major?';
        correctAnswer = targetKey.accidentalSummary;
        distractors = keys
            .where((k) => k.accidentalSummary != targetKey.accidentalSummary)
            .map((k) => k.accidentalSummary)
            .toSet()
            .toList()
          ..shuffle(rand);
        explanation = targetKey.accidentalsList.isEmpty
            ? '${targetKey.majorDisplayName} Major has no sharps or flats (All Natural).'
            : '${targetKey.majorDisplayName} Major has ${targetKey.accidentalSummary}: ${targetKey.accidentalsList.join(', ')}.';
        expectedNote = targetKey.majorNote;
        break;

      case CircleQuestionType.keyFromAccidentals:
        categoryTitle = 'KEY IDENTIFICATION';
        final acc = targetKey.accidentalSummary == '0 (Natural)' ? 'no sharps or flats' : targetKey.accidentalSummary;
        questionText = 'Which Major key signature has $acc?';
        correctAnswer = targetKey.majorDisplayName;
        distractors = keys
            .where((k) => k.circleIndex != targetKey.circleIndex)
            .map((k) => k.majorDisplayName)
            .toList()
          ..shuffle(rand);
        explanation = '${targetKey.majorDisplayName} Major contains $acc.';
        expectedNote = targetKey.majorNote;
        break;

      case CircleQuestionType.relativeMinor:
        categoryTitle = 'RELATIVE MINOR';
        questionText = 'What is the relative minor of ${targetKey.majorDisplayName} Major?';
        correctAnswer = targetKey.minorDisplayName;
        distractors = keys
            .where((k) => k.circleIndex != targetKey.circleIndex)
            .map((k) => k.minorDisplayName)
            .toList()
          ..shuffle(rand);
        explanation = '${targetKey.minorDisplayName} is the 6th degree (vi) of ${targetKey.majorDisplayName} Major.';
        expectedNote = targetKey.minorNote;
        break;

      case CircleQuestionType.relativeMajor:
        categoryTitle = 'RELATIVE MAJOR';
        questionText = 'What is the relative major of ${targetKey.minorDisplayName}?';
        correctAnswer = targetKey.majorDisplayName;
        distractors = keys
            .where((k) => k.circleIndex != targetKey.circleIndex)
            .map((k) => k.majorDisplayName)
            .toList()
          ..shuffle(rand);
        explanation = '${targetKey.majorDisplayName} Major shares the same key signature as ${targetKey.minorDisplayName}.';
        expectedNote = targetKey.majorNote;
        break;

      case CircleQuestionType.dominantFifth:
        categoryTitle = 'CIRCLE NAVIGATION (5TH)';
        final dom = targetKey.dominant;
        questionText = 'What is the Dominant (5th degree) of ${targetKey.majorName}?';
        correctAnswer = dom.majorName;
        distractors = keys
            .where((k) => k.majorName != dom.majorName && k.majorName != targetKey.majorName)
            .map((k) => k.majorName)
            .toList()
          ..shuffle(rand);
        explanation = '${dom.majorName} is 1 step clockwise (a Perfect 5th up) from ${targetKey.majorName}.';
        expectedNote = dom.majorNote;
        break;

      case CircleQuestionType.subdominantFourth:
        categoryTitle = 'CIRCLE NAVIGATION (4TH)';
        final sub = targetKey.subdominant;
        questionText = 'What is the Subdominant (4th degree) of ${targetKey.majorName}?';
        correctAnswer = sub.majorName;
        distractors = keys
            .where((k) => k.majorName != sub.majorName && k.majorName != targetKey.majorName)
            .map((k) => k.majorName)
            .toList()
          ..shuffle(rand);
        explanation = '${sub.majorName} is 1 step counter-clockwise (a Perfect 4th up) from ${targetKey.majorName}.';
        expectedNote = sub.majorNote;
        break;

      case CircleQuestionType.chordInKey:
        categoryTitle = 'CHORD DEGREE';
        // Pick IV, V, or vi chord
        final degrees = ['IV', 'V', 'vi'];
        final chosenNumeral = degrees[rand.nextInt(degrees.length)];
        final chord = targetKey.chordFamily.firstWhere((c) => c.numeral == chosenNumeral);
        questionText = 'In the key of ${targetKey.majorName} Major, what is the $chosenNumeral chord?';
        correctAnswer = chord.name;
        distractors = targetKey.chordFamily
            .where((c) => c.name != chord.name)
            .map((c) => c.name)
            .toList()
          ..shuffle(rand);
        explanation = 'The $chosenNumeral chord in ${targetKey.majorName} Major is ${chord.name} (${chord.role}).';
        expectedNote = chord.rootNote;
        break;
    }

    final options = <String>[correctAnswer, ...distractors.take(3)]..shuffle(rand);

    setState(() {
      _currentQuestion = CircleQuizQuestion(
        type: type,
        categoryTitle: categoryTitle,
        questionText: questionText,
        referenceKey: targetKey,
        correctAnswer: correctAnswer,
        options: options,
        explanation: explanation,
        expectedNote: expectedNote,
      );
      _selectedAnswer = null;
      _isAnswerLocked = false;
      _session.currentPosition = TargetPosition(stringNumber: 6, fretNumber: expectedNote.chromaticIndex);
    });
  }

  void _handleOptionSelected(String option) {
    if (_isAnswerLocked || _session.status != GameStatus.playing) return;

    final isCorrect = (option == _currentQuestion.correctAnswer);
    setState(() {
      _isAnswerLocked = true;
      _selectedAnswer = option;
      _flashColor = isCorrect ? AppColors.emerald : AppColors.coral;
    });

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
      position: TargetPosition(stringNumber: 6, fretNumber: _currentQuestion.expectedNote.chromaticIndex),
      userSelectedNote: _currentQuestion.expectedNote,
      isCorrect: isCorrect,
    ));

    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _flashColor = Colors.transparent;
        _generateNextQuestion();
      });
    });
  }

  Future<void> _onTestFinished() async {
    final modeKey = widget.durationSeconds <= 0 ? 'game4_circle_quiz_untimed' : 'game4_circle_quiz';
    await DatabaseHelper.instance.saveGameSession(_session, modeKey);

    final isHigh = await HighScoreService.saveSession(
      score: _session.correctCount,
      accuracy: _session.accuracyPercentage,
      gameKey: 'game4',
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

  String _formatTimerText(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_session.status == GameStatus.finished) {
      return ResultsScreen(
        session: _session,
        isNewHighScore: _isNewHighScore,
        onPlayAgain: _startTest,
        onHome: () => Navigator.of(context).pop(),
      );
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTwoColumn = ResponsiveLayout.isWideDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleExitAttempt();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: _flashColor.withValues(alpha: 0.08),
          child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveLayout.contentWidth(context, desktopMaxWidth: 1100),
              ),
              child: Padding(
                padding: isDesktop
                    ? const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0)
                    : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    // 1. HUD Row (Exit, Timer, Streak, Score)
                    _buildHUD(textPrimary, textSecondary),

                    const SizedBox(height: 12),

                    // 2. Responsive Content Split: 2-Column (Desktop) vs Stack (Mobile)
                    Expanded(
                      child: isTwoColumn
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left: Wheel Reference
                                SizedBox(
                                  width: 420,
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleOfFifthsWidget(
                                          selectedKey: _currentQuestion.referenceKey,
                                          isMinorSelected: false,
                                          onKeyChanged: (key, isMinor) {},
                                          size: 340,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Focus: ${_currentQuestion.referenceKey.majorDisplayName} Major / ${_currentQuestion.referenceKey.minorDisplayName}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Right: Question & Options
                                Expanded(
                                  child: _buildQuestionAndOptions(isDark, textPrimary, textSecondary),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Compact Wheel in Mobile
                                  GlassCard(
                                    padding: const EdgeInsets.all(12),
                                    child: CircleOfFifthsWidget(
                                      selectedKey: _currentQuestion.referenceKey,
                                      isMinorSelected: false,
                                      onKeyChanged: (key, isMinor) {},
                                      size: 260,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildQuestionAndOptions(isDark, textPrimary, textSecondary),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildHUD(Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
          onPressed: _handleExitAttempt,
        ),
        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                widget.durationSeconds <= 0 ? 'Practice' : _formatTimerText(_session.secondsRemaining),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // Streak & Score
        Row(
          children: [
            if (_session.currentStreak > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 15, color: AppColors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${_session.currentStreak}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${_session.correctCount}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionAndOptions(bool isDark, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Question Card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _currentQuestion.categoryTitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.purple,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _currentQuestion.questionText,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: 1.35,
                ),
              ),
              if (_isAnswerLocked) ...[
                const SizedBox(height: 10),
                AnimatedOpacity(
                  opacity: _isAnswerLocked ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _currentQuestion.explanation,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectedAnswer == _currentQuestion.correctAnswer
                          ? AppColors.emerald
                          : AppColors.coral,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4 Multiple Choice Option Cards (2x2 Grid)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: _currentQuestion.options.map((option) {
            final isSelected = (_selectedAnswer == option);
            final isCorrect = (option == _currentQuestion.correctAnswer);

            Color optionBg;
            Color optionBorder;
            Color optionText;

            if (_isAnswerLocked) {
              if (isCorrect) {
                optionBg = AppColors.emerald.withValues(alpha: 0.25);
                optionBorder = AppColors.emerald;
                optionText = AppColors.emerald;
              } else if (isSelected) {
                optionBg = AppColors.coral.withValues(alpha: 0.25);
                optionBorder = AppColors.coral;
                optionText = AppColors.coral;
              } else {
                optionBg = isDark ? const Color(0xFF14141C) : const Color(0xFFF4F4F6);
                optionBorder = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;
                optionText = textSecondary;
              }
            } else {
              optionBg = isDark ? const Color(0xFF181824) : Colors.white;
              optionBorder = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;
              optionText = textPrimary;
            }

            return InkWell(
              onTap: _isAnswerLocked ? null : () => _handleOptionSelected(option),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: optionBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: optionBorder, width: isSelected || (_isAnswerLocked && isCorrect) ? 2.0 : 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: optionText,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
