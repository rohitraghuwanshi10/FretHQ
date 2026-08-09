import 'package:shared_preferences/shared_preferences.dart';

class HighScoreService {
  static Future<int> getHighScore({String gameKey = 'game1'}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${gameKey}_high_score') ?? 0;
  }

  static Future<double> getBestAccuracy({String gameKey = 'game1'}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('${gameKey}_best_accuracy') ?? 0.0;
  }

  static Future<int> getTotalGamesPlayed({String gameKey = 'game1'}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${gameKey}_total_games') ?? 0;
  }

  /// Saves the game session results if it's a new high score
  /// Returns true if a new high score was set
  static Future<bool> saveSession({
    required int score,
    required double accuracy,
    String gameKey = 'game1',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keyHigh = '${gameKey}_high_score';
    final keyAcc = '${gameKey}_best_accuracy';
    final keyTotal = '${gameKey}_total_games';

    final currentHigh = prefs.getInt(keyHigh) ?? 0;
    final totalGames = prefs.getInt(keyTotal) ?? 0;

    await prefs.setInt(keyTotal, totalGames + 1);

    final currentBestAcc = prefs.getDouble(keyAcc) ?? 0.0;
    if (accuracy > currentBestAcc) {
      await prefs.setDouble(keyAcc, accuracy);
    }

    if (score > currentHigh) {
      await prefs.setInt(keyHigh, score);
      return true;
    }
    return false;
  }
}
