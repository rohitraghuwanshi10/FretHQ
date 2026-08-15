import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_session.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ResultsScreen extends StatefulWidget {
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
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.session.correctCount.toDouble(),
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();

    if (widget.isNewHighScore) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.session.accuracyPercentage;
    final attempts = widget.session.totalAttempts;
    final incorrectAttempts = widget.session.incorrectAttempts;
    final maxStreak = widget.session.maxStreak;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header badge
                if (widget.isNewHighScore) ...[
                  GlassBadge(
                    text: 'NEW PERSONAL BEST SCORE!',
                    color: AppColors.gold,
                    icon: Icons.emoji_events_rounded,
                    fontSize: 13,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  const SizedBox(height: 14),
                ],

                const Text(
                  'Time\'s Up!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Practice Session Summary',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                // Main Score Hero Card
                GlassCard(
                  gradient: AppColors.heroCardGradient,
                  borderColor: AppColors.purple.withValues(alpha: 0.5),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _scoreAnimation,
                        builder: (context, child) {
                          return Text(
                            '${_scoreAnimation.value.toInt()}',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: AppColors.gold,
                              height: 1.0,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'CORRECT NOTES IN ${widget.session.durationSeconds}s',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 14),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Accuracy', '${accuracy.toStringAsFixed(1)}%', Icons.track_changes_rounded, AppColors.cyan),
                          _buildStatItem('Max Streak', '$maxStreak 🔥', Icons.bolt_rounded, AppColors.orange),
                          _buildStatItem('Total Answered', '$attempts', Icons.format_list_numbered_rounded, AppColors.emerald),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Missed Questions Review
                GlassCard(
                  borderColor: incorrectAttempts.isEmpty
                      ? AppColors.emerald.withValues(alpha: 0.3)
                      : AppColors.coral.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            incorrectAttempts.isEmpty ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                            color: incorrectAttempts.isEmpty ? AppColors.emerald : AppColors.coral,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            incorrectAttempts.isEmpty
                                ? 'PERFECT ROUND — NO MISSED NOTES!'
                                : 'MISSED NOTES REVIEW (${incorrectAttempts.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: incorrectAttempts.isEmpty ? AppColors.emerald : AppColors.coral,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (incorrectAttempts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.0),
                          child: Text(
                            'Flawless precision! You identified every fretboard note with 100% accuracy.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: incorrectAttempts.length,
                          separatorBuilder: (context, index) => const Divider(color: AppColors.borderSubtle),
                          itemBuilder: (context, index) {
                            final item = incorrectAttempts[index];
                            final pos = item.position;
                            final userAns = item.userSelectedNote;
                            final correctAns = pos.targetNote;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  // Fret Location
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${pos.stringName} String',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.gold,
                                          ),
                                        ),
                                        Text(
                                          pos.fretNumber == 0 ? 'Open (Fret 0)' : 'Fret ${pos.fretNumber}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Comparison
                                  Expanded(
                                    child: Row(
                                      children: [
                                        // User Wrong Choice
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'YOUR ANSWER',
                                                style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(Icons.close_rounded, color: AppColors.coral, size: 14),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      userAns.displayName,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.coral,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Correct Answer
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'CORRECT NOTE',
                                                style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(Icons.check_rounded, color: AppColors.emerald, size: 14),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      correctAns.displayName,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.emerald,
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
                      child: OutlinedButton.icon(
                        onPressed: widget.onHome,
                        icon: const Icon(Icons.home_rounded, size: 20),
                        label: const Text('Main Menu'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onPlayAgain,
                        icon: const Icon(Icons.replay_rounded, size: 20),
                        label: const Text('Play Again'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
