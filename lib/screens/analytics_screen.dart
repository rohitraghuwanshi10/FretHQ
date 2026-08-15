import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/fretboard_heatmap_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  final bool isEmbedded;

  const AnalyticsScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _overallStats = {};
  List<WeakPosition> _weakPositions = [];
  List<SessionSummary> _sessionHistory = [];
  Map<String, FretHeatmapStat> _heatmapStats = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final stats = await DatabaseHelper.instance.getOverallStats();
    final weak = await DatabaseHelper.instance.getWeakestPositions(limit: 10);
    final history = await DatabaseHelper.instance.getSessionHistory(limit: 20);
    final heatmap = await DatabaseHelper.instance.getAllFretPositionsStats();

    if (!mounted) return;
    setState(() {
      _overallStats = stats;
      _weakPositions = weak;
      _sessionHistory = history;
      _heatmapStats = heatmap;
      _isLoading = false;
    });
  }

  String _formatTimestamp(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final monthStr = _monthAbbr(dt.month);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      return '$monthStr ${dt.day}, $hour12:$minuteStr $period';
    } catch (_) {
      return isoStr;
    }
  }

  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1) % 12];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: const Text('Performance & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.purple),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: AppColors.primary,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Overview Summary Metrics
                    const _SectionTitle(
                      title: 'PRACTICE METRICS OVERVIEW',
                      icon: Icons.insights_rounded,
                      color: AppColors.purple,
                    ),
                    const SizedBox(height: 10),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.65,
                      children: [
                        _buildMetricCard(
                          'Overall Accuracy',
                          '${(_overallStats['overall_accuracy'] as double? ?? 0.0).toStringAsFixed(1)}%',
                          Icons.track_changes_rounded,
                          AppColors.cyan,
                        ),
                        _buildMetricCard(
                          'Personal Best',
                          '${_overallStats['highest_score'] ?? 0} pts',
                          Icons.emoji_events_rounded,
                          AppColors.gold,
                        ),
                        _buildMetricCard(
                          'Tests Completed',
                          '${_overallStats['total_sessions'] ?? 0}',
                          Icons.fitness_center_rounded,
                          AppColors.purple,
                        ),
                        _buildMetricCard(
                          'Notes Identified',
                          '${_overallStats['total_attempts'] ?? 0}',
                          Icons.music_note_rounded,
                          AppColors.emerald,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Section 2: Interactive Fretboard Heatmap
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionTitle(
                          title: 'FRETBOARD MASTERY HEATMAP',
                          icon: Icons.grid_view_rounded,
                          color: AppColors.cyan,
                        ),
                        const Text(
                          'Tap note to inspect',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FretboardHeatmapWidget(heatmapStats: _heatmapStats),

                    const SizedBox(height: 28),

                    // Section 3: Weak Frets Needing Practice
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionTitle(
                          title: 'PRIORITY WEAK SPOTS',
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.coral,
                        ),
                        Text(
                          '${_weakPositions.length} Identified',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_weakPositions.isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: const Center(
                          child: Text(
                            'No error patterns detected yet! Complete practice sessions to discover weak spots.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _weakPositions.map((weak) {
                          final note = Note.getNoteForPosition(weak.stringNumber, weak.fretNumber);
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            borderColor: AppColors.coral.withValues(alpha: 0.3),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.coral.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    note.displayName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.coral,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${weak.stringName} String • ${weak.fretNumber == 0 ? "Open (Fret 0)" : "Fret ${weak.fretNumber}"}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: weak.accuracy / 100.0,
                                                backgroundColor: Colors.white10,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  weak.accuracy < 50
                                                      ? AppColors.coral
                                                      : (weak.accuracy < 75 ? AppColors.gold : AppColors.emerald),
                                                ),
                                                minHeight: 6,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${weak.accuracy.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${weak.wrongCount} Missed',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.coral,
                                      ),
                                    ),
                                    Text(
                                      '${weak.totalAttempts} tries',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 28),

                    // Section 4: Practice Sessions History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionTitle(
                          title: 'RECENT TEST HISTORY',
                          icon: Icons.history_rounded,
                          color: AppColors.emerald,
                        ),
                        Text(
                          'Last ${_sessionHistory.length} Sessions',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_sessionHistory.isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: const Center(
                          child: Text(
                            'No practice test history recorded yet.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sessionHistory.length,
                        itemBuilder: (context, index) {
                          final session = _sessionHistory[index];
                          final durationMins = session.durationSec ~/ 60;
                          final isGame2 = session.mode.contains('game2');

                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isGame2 ? AppColors.cyan : AppColors.gold).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isGame2 ? Icons.touch_app_rounded : Icons.music_note_rounded,
                                    color: isGame2 ? AppColors.cyan : AppColors.gold,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            isGame2 ? 'Find Fret (${durationMins}m)' : 'Identify Note (${durationMins}m)',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          _buildSessionModeBadge(session.mode),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTimestamp(session.timestamp),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${session.score} pts',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                    Text(
                                      '${session.accuracy.toStringAsFixed(0)}% Acc',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: session.accuracy >= 80
                                            ? AppColors.emerald
                                            : (session.accuracy >= 50 ? AppColors.gold : AppColors.coral),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionModeBadge(String mode) {
    Color badgeColor;
    String label;

    if (mode.contains('weak_spot')) {
      badgeColor = AppColors.coral;
      label = 'Adaptive';
    } else if (mode.contains('easy')) {
      badgeColor = AppColors.emerald;
      label = 'Easy';
    } else {
      badgeColor = AppColors.gold;
      label = 'Full';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
