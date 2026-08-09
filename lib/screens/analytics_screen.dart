import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/note.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _overallStats = {};
  List<WeakPosition> _weakPositions = [];
  List<SessionSummary> _sessionHistory = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final stats = await DatabaseHelper.instance.getOverallStats();
    final weak = await DatabaseHelper.instance.getWeakestPositions(limit: 10);
    final history = await DatabaseHelper.instance.getSessionHistory(limit: 20);

    if (!mounted) return;
    setState(() {
      _overallStats = stats;
      _weakPositions = weak;
      _sessionHistory = history;
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
      backgroundColor: const Color(0xFF121216),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Performance & Analytics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: Colors.amber,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Summary Header
                    const Text(
                      'OVERALL PERFORMANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Grid of 4 Stat Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.8,
                      children: [
                        _buildMetricCard(
                          'Overall Accuracy',
                          '${(_overallStats['overall_accuracy'] as double? ?? 0.0).toStringAsFixed(1)}%',
                          Icons.insights,
                          Colors.cyanAccent,
                        ),
                        _buildMetricCard(
                          'Best Score',
                          '${_overallStats['highest_score'] ?? 0} pts',
                          Icons.emoji_events,
                          Colors.amber,
                        ),
                        _buildMetricCard(
                          'Total Practice Tests',
                          '${_overallStats['total_sessions'] ?? 0}',
                          Icons.sports_esports,
                          Colors.purpleAccent,
                        ),
                        _buildMetricCard(
                          'Notes Answered',
                          '${_overallStats['total_attempts'] ?? 0}',
                          Icons.music_note,
                          Colors.greenAccent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Weak Frets Analytics Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FRETS NEEDING PRACTICE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          '${_weakPositions.length} Positions Identified',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_weakPositions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Center(
                          child: Text(
                            'No error patterns detected yet! Complete more practice sessions.',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _weakPositions.map((weak) {
                          final note = Note.getNoteForPosition(weak.stringNumber, weak.fretNumber);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1826),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    note.displayName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
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
                                                      ? Colors.redAccent
                                                      : (weak.accuracy < 75 ? Colors.orangeAccent : Colors.greenAccent),
                                                ),
                                                minHeight: 6,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${weak.accuracy.toStringAsFixed(0)}% Acc',
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
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    Text(
                                      '${weak.totalAttempts} Attempts',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
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

                    // Game Session History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PRACTICE HISTORY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'Last ${_sessionHistory.length} Tests',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_sessionHistory.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Center(
                          child: Text(
                            'No practice test history recorded yet.',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
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

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E26),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${durationMins}m Test',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: session.mode == 'weak_spot'
                                                  ? Colors.redAccent.withValues(alpha: 0.2)
                                                  : (session.mode == 'easy'
                                                      ? Colors.greenAccent.withValues(alpha: 0.2)
                                                      : Colors.amber.withValues(alpha: 0.2)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              session.mode == 'weak_spot'
                                                  ? 'Weak Spots'
                                                  : (session.mode == 'easy' ? 'Easy' : 'Full'),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: session.mode == 'weak_spot'
                                                    ? Colors.redAccent
                                                    : (session.mode == 'easy' ? Colors.greenAccent : Colors.amber),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTimestamp(session.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
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
                                        color: Colors.amber,
                                      ),
                                    ),
                                    Text(
                                      '${session.accuracy.toStringAsFixed(1)}% Acc',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
