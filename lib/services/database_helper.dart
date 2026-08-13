import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/game_session.dart';

class WeakPosition {
  final int stringNumber;
  final int fretNumber;
  final int totalAttempts;
  final int wrongCount;
  final double accuracy;

  WeakPosition({
    required this.stringNumber,
    required this.fretNumber,
    required this.totalAttempts,
    required this.wrongCount,
    required this.accuracy,
  });

  String get stringName {
    switch (stringNumber) {
      case 1:
        return 'High E';
      case 2:
        return 'B';
      case 3:
        return 'G';
      case 4:
        return 'D';
      case 5:
        return 'A';
      case 6:
        return 'Low E';
      default:
        return 'String $stringNumber';
    }
  }
}

class FretHeatmapStat {
  final int stringNumber;
  final int fretNumber;
  final int totalAttempts;
  final int correctCount;
  final int wrongCount;
  final double accuracy;

  FretHeatmapStat({
    required this.stringNumber,
    required this.fretNumber,
    required this.totalAttempts,
    required this.correctCount,
    required this.wrongCount,
    required this.accuracy,
  });
}

class SessionSummary {
  final int id;
  final String timestamp;
  final String mode;
  final int durationSec;
  final int score;
  final int totalAttempts;
  final double accuracy;
  final int maxStreak;

  SessionSummary({
    required this.id,
    required this.timestamp,
    required this.mode,
    required this.durationSec,
    required this.score,
    required this.totalAttempts,
    required this.accuracy,
    required this.maxStreak,
  });

  factory SessionSummary.fromMap(Map<String, dynamic> map) {
    return SessionSummary(
      id: map['id'] as int,
      timestamp: map['timestamp'] as String,
      mode: map['mode'] as String? ?? 'full',
      durationSec: map['duration_sec'] as int? ?? 60,
      score: map['score'] as int? ?? 0,
      totalAttempts: map['total_attempts'] as int? ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      maxStreak: map['max_streak'] as int? ?? 0,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('frethq_game_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE game_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        mode TEXT NOT NULL,
        duration_sec INTEGER NOT NULL,
        score INTEGER NOT NULL,
        total_attempts INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        max_streak INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE answer_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        string_number INTEGER NOT NULL,
        fret_number INTEGER NOT NULL,
        target_note TEXT NOT NULL,
        user_note TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES game_sessions (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Saves a completed GameSession along with all its individual attempt logs
  Future<int> saveGameSession(GameSession session, String modeName) async {
    final db = await database;

    return await db.transaction((txn) async {
      final nowIso = DateTime.now().toIso8601String();

      final sessionId = await txn.insert('game_sessions', {
        'timestamp': nowIso,
        'mode': modeName,
        'duration_sec': session.durationSeconds,
        'score': session.correctCount,
        'total_attempts': session.totalAttempts,
        'accuracy': session.accuracyPercentage,
        'max_streak': session.maxStreak,
      });

      for (final attempt in session.attemptsHistory) {
        await txn.insert('answer_logs', {
          'session_id': sessionId,
          'timestamp': nowIso,
          'string_number': attempt.position.stringNumber,
          'fret_number': attempt.position.fretNumber,
          'target_note': attempt.position.targetNote.id,
          'user_note': attempt.userSelectedNote.id,
          'is_correct': attempt.isCorrect ? 1 : 0,
        });
      }

      debugPrint('DatabaseHelper: Saved session $sessionId with ${session.attemptsHistory.length} answer logs');
      return sessionId;
    });
  }

  /// Returns recent sessions history (newest first)
  Future<List<SessionSummary>> getSessionHistory({int limit = 30}) async {
    final db = await database;
    final maps = await db.query(
      'game_sessions',
      orderBy: 'id DESC',
      limit: limit,
    );
    return maps.map((map) => SessionSummary.fromMap(map)).toList();
  }

  /// Returns fret positions sorted by highest error rate / wrong answers count
  Future<List<WeakPosition>> getWeakestPositions({int limit = 10}) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        string_number,
        fret_number,
        COUNT(*) as total_attempts,
        SUM(CASE WHEN is_correct = 0 THEN 1 ELSE 0 END) as wrong_count
      FROM answer_logs
      GROUP BY string_number, fret_number
      HAVING wrong_count > 0
      ORDER BY wrong_count DESC, (wrong_count * 1.0 / COUNT(*)) DESC
      LIMIT ?
    ''', [limit]);

    return result.map((row) {
      final total = (row['total_attempts'] as num).toInt();
      final wrong = (row['wrong_count'] as num).toInt();
      final accuracy = total > 0 ? ((total - wrong) / total) * 100.0 : 0.0;

      return WeakPosition(
        stringNumber: row['string_number'] as int,
        fretNumber: row['fret_number'] as int,
        totalAttempts: total,
        wrongCount: wrong,
        accuracy: accuracy,
      );
    }).toList();
  }

  /// Returns heatmap stats for all tested fret positions across strings 1-6 and frets 0-12
  Future<Map<String, FretHeatmapStat>> getAllFretPositionsStats() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        string_number,
        fret_number,
        COUNT(*) as total_attempts,
        SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct_count,
        SUM(CASE WHEN is_correct = 0 THEN 1 ELSE 0 END) as wrong_count
      FROM answer_logs
      GROUP BY string_number, fret_number
    ''');

    final Map<String, FretHeatmapStat> statsMap = {};
    for (final row in result) {
      final str = (row['string_number'] as num).toInt();
      final fret = (row['fret_number'] as num).toInt();
      final total = (row['total_attempts'] as num).toInt();
      final correct = (row['correct_count'] as num).toInt();
      final wrong = (row['wrong_count'] as num).toInt();
      final accuracy = total > 0 ? (correct / total) * 100.0 : 0.0;

      final key = '$str-$fret';
      statsMap[key] = FretHeatmapStat(
        stringNumber: str,
        fretNumber: fret,
        totalAttempts: total,
        correctCount: correct,
        wrongCount: wrong,
        accuracy: accuracy,
      );
    }
    return statsMap;
  }

  /// Get overall aggregated statistics
  Future<Map<String, dynamic>> getOverallStats() async {
    final db = await database;

    final sessionRes = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_sessions,
        SUM(score) as total_correct,
        SUM(total_attempts) as total_attempts,
        MAX(score) as highest_score,
        MAX(accuracy) as best_accuracy
      FROM game_sessions
    ''');

    if (sessionRes.isEmpty || sessionRes.first['total_sessions'] == 0) {
      return {
        'total_sessions': 0,
        'total_correct': 0,
        'total_attempts': 0,
        'highest_score': 0,
        'best_accuracy': 0.0,
        'overall_accuracy': 0.0,
      };
    }

    final row = sessionRes.first;
    final totalSessions = (row['total_sessions'] as num?)?.toInt() ?? 0;
    final totalCorrect = (row['total_correct'] as num?)?.toInt() ?? 0;
    final totalAttempts = (row['total_attempts'] as num?)?.toInt() ?? 0;
    final highestScore = (row['highest_score'] as num?)?.toInt() ?? 0;
    final bestAccuracy = (row['best_accuracy'] as num?)?.toDouble() ?? 0.0;
    final overallAccuracy = totalAttempts > 0 ? (totalCorrect / totalAttempts) * 100.0 : 0.0;

    return {
      'total_sessions': totalSessions,
      'total_correct': totalCorrect,
      'total_attempts': totalAttempts,
      'highest_score': highestScore,
      'best_accuracy': bestAccuracy,
      'overall_accuracy': overallAccuracy,
    };
  }
}
