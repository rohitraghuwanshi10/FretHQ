import 'package:shared_preferences/shared_preferences.dart';

class HighScoreService {
  static const String _keyHighScore = 'game1_high_score';
  static const String _keyBestAccuracy = 'game1_best_accuracy';
  static const String _keyTotalGames = 'game1_total_games';

  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyHighScore) ?? 0;
  }

  static Future<double> getBestAccuracy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyBestAccuracy) ?? 0.0;
  }

  static Future<int> getTotalGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalGames) ?? 0;
  }

  /// Saves the game session results if it's a new high score
  /// Returns true if a new high score was set
  static Future<bool> saveSession({
    required int score,
    required double accuracy,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt(_keyHighScore) ?? 0;
    final totalGames = prefs.getInt(_keyTotalGames) ?? 0;

    await prefs.setInt(_keyTotalGames, totalGames + 1);

    final currentBestAcc = prefs.getDouble(_keyBestAccuracy) ?? 0.0;
    if (accuracy > currentBestAcc) {
      await prefs.setDouble(_keyBestAccuracy, accuracy);
    }

    if (score > currentHigh) {
      await prefs.setInt(_keyHighScore, score);
      return true;
    }
    return false;
  }
}
