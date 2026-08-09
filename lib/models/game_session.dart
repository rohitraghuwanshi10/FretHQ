import 'dart:math';
import 'note.dart';

enum GameStatus { idle, playing, finished }

class AnswerAttempt {
  final TargetPosition position;
  final Note userSelectedNote;
  final bool isCorrect;

  AnswerAttempt({
    required this.position,
    required this.userSelectedNote,
    required this.isCorrect,
  });
}

class GameSession {
  final int durationSeconds;
  int secondsRemaining;
  int correctCount;
  int incorrectCount;
  int currentStreak;
  int maxStreak;
  GameStatus status;
  TargetPosition? currentPosition;
  int minFret;
  int maxFret;

  final List<AnswerAttempt> attemptsHistory = [];

  GameSession({
    this.durationSeconds = 60,
    this.minFret = 0,
    this.maxFret = 12,
  })  : secondsRemaining = durationSeconds,
        correctCount = 0,
        incorrectCount = 0,
        currentStreak = 0,
        maxStreak = 0,
        status = GameStatus.idle;

  int get totalAttempts => correctCount + incorrectCount;

  double get accuracyPercentage {
    if (totalAttempts == 0) return 0.0;
    return (correctCount / totalAttempts) * 100.0;
  }

  List<AnswerAttempt> get incorrectAttempts =>
      attemptsHistory.where((a) => !a.isCorrect).toList();

  void start() {
    status = GameStatus.playing;
    secondsRemaining = durationSeconds;
    correctCount = 0;
    incorrectCount = 0;
    currentStreak = 0;
    maxStreak = 0;
    attemptsHistory.clear();
    generateNextPrompt();
  }

  void generateNextPrompt() {
    final rand = Random();
    int nextString;
    int nextFret;

    // Pick a random position, avoiding repeating the exact same position consecutively if possible
    do {
      nextString = rand.nextInt(6) + 1; // 1 to 6
      nextFret = minFret + rand.nextInt(maxFret - minFret + 1); // minFret to maxFret
    } while (currentPosition != null &&
        currentPosition!.stringNumber == nextString &&
        currentPosition!.fretNumber == nextFret);

    currentPosition = TargetPosition(
      stringNumber: nextString,
      fretNumber: nextFret,
    );
  }

  /// Processes user note answer and returns true if correct
  bool answer(Note selectedNote) {
    if (status != GameStatus.playing || currentPosition == null) {
      return false;
    }

    final isCorrect = selectedNote == currentPosition!.targetNote;

    attemptsHistory.add(AnswerAttempt(
      position: currentPosition!,
      userSelectedNote: selectedNote,
      isCorrect: isCorrect,
    ));

    if (isCorrect) {
      correctCount++;
      currentStreak++;
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
    } else {
      incorrectCount++;
      currentStreak = 0;
    }

    generateNextPrompt();
    return isCorrect;
  }

  void tick() {
    if (status == GameStatus.playing) {
      secondsRemaining--;
      if (secondsRemaining <= 0) {
        secondsRemaining = 0;
        status = GameStatus.finished;
      }
    }
  }

  void reset() {
    status = GameStatus.idle;
    secondsRemaining = durationSeconds;
    correctCount = 0;
    incorrectCount = 0;
    currentStreak = 0;
    maxStreak = 0;
    attemptsHistory.clear();
    currentPosition = null;
  }
}
