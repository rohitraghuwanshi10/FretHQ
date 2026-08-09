import 'package:flutter/material.dart';
import '../models/game_session.dart';

class ResultsScreen extends StatelessWidget {
  final GameSession session;
  final bool isNewHighScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const ResultsScreen({
    super.key,
    required this.session,
    required this.isNewHighScore,
    required this.onPlayAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = session.accuracyPercentage;
    final score = session.correctCount;
    final attempts = session.totalAttempts;
    final incorrectAttempts = session.incorrectAttempts;

    return Scaffold(
      backgroundColor: const Color(0xFF121216),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header badge
                if (isNewHighScore)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'NEW PERSONAL BEST!',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Text(
                  'Time\'s Up!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fretboard Identification Test Complete',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),

                const SizedBox(height: 24),

                // Main Score Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF232035), Color(0xFF191726)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple.shade400.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 58,
                          fontWeight: FontWeight.w900,
                          color: Colors.amberAccent,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CORRECT NOTES IN 60s',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 14),

                      // Stats Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Accuracy', '${accuracy.toStringAsFixed(1)}%', Icons.track_changes, Colors.cyanAccent),
                          _buildStatItem('Max Streak', '${session.maxStreak}', Icons.bolt, Colors.orangeAccent),
                          _buildStatItem('Total Answered', '$attempts', Icons.format_list_numbered, Colors.greenAccent),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Incorrect Answers Review Breakdown Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1926),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: incorrectAttempts.isEmpty
                          ? Colors.greenAccent.withValues(alpha: 0.3)
                          : Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            incorrectAttempts.isEmpty ? Icons.check_circle : Icons.error_outline,
                            color: incorrectAttempts.isEmpty ? Colors.greenAccent : Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            incorrectAttempts.isEmpty
                                ? 'PERFECT SCORE - NO MISSED NOTES!'
                                : 'MISSED QUESTIONS (${incorrectAttempts.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: incorrectAttempts.isEmpty ? Colors.greenAccent : Colors.redAccent,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (incorrectAttempts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.0),
                          child: Text(
                            'Outstanding performance! You identified every fretboard note correctly in this round.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: incorrectAttempts.length,
                          separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                          itemBuilder: (context, index) {
                            final item = incorrectAttempts[index];
                            final pos = item.position;
                            final userAns = item.userSelectedNote;
                            final correctAns = pos.targetNote;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  // Fretboard Location Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${pos.stringName} String',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                        Text(
                                          pos.fretNumber == 0 ? 'Fret 0 (Open)' : 'Fret ${pos.fretNumber}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Comparison: User Wrong Choice vs Correct Answer
                                  Expanded(
                                    child: Row(
                                      children: [
                                        // User Choice
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'YOUR ANSWER',
                                                style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(Icons.close, color: Colors.redAccent, size: 14),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      userAns.displayName,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.redAccent,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Correct Note
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'CORRECT NOTE',
                                                style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(Icons.check, color: Colors.greenAccent, size: 14),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      correctAns.displayName,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.greenAccent,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onHome,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home, color: Colors.white70, size: 20),
                            SizedBox(width: 8),
                            Text('Main Menu', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onPlayAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.replay, size: 20),
                            SizedBox(width: 8),
                            Text('Play Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
