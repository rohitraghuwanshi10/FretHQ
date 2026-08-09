import 'package:flutter/material.dart';
import '../services/high_score_service.dart';
import '../services/database_helper.dart';
import '../models/note.dart';
import 'identify_note_screen.dart';
import 'find_fret_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _highScore = 0;
  double _bestAccuracy = 0.0;
  int _totalGames = 0;
  bool _isLoadingStats = true;
  int _selectedDurationMinutes = 1; // Default 1 min
  bool _includeAccidentals = false; // Default Easy Mode (Natural notes only)
  bool _isWeakSpotFocus = false; // Adaptive Weak Spot focus toggle

  final List<int> _durationOptions = [1, 2, 3, 5, 10];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final score = await HighScoreService.getHighScore();
    final accuracy = await HighScoreService.getBestAccuracy();
    final games = await HighScoreService.getTotalGamesPlayed();

    if (!mounted) return;
    setState(() {
      _highScore = score;
      _bestAccuracy = accuracy;
      _totalGames = games;
      _isLoadingStats = false;
    });
  }

  void _navigateToGame1() async {
    List<TargetPosition>? weakTargetPositions;

    if (_isWeakSpotFocus) {
      final weakList = await DatabaseHelper.instance.getWeakestPositions(limit: 10);
      weakTargetPositions = weakList
          .map((w) => TargetPosition(stringNumber: w.stringNumber, fretNumber: w.fretNumber))
          .toList();
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IdentifyNoteScreen(
          durationSeconds: _selectedDurationMinutes * 60,
          includeAccidentals: _includeAccidentals,
          isWeakSpotFocus: _isWeakSpotFocus,
          weakTargetPositions: weakTargetPositions,
        ),
      ),
    );
    _loadStats(); // Refresh stats when returning
  }

  void _navigateToGame2() async {
    List<TargetPosition>? weakTargetPositions;

    if (_isWeakSpotFocus) {
      final weakList = await DatabaseHelper.instance.getWeakestPositions(limit: 10);
      weakTargetPositions = weakList
          .map((w) => TargetPosition(stringNumber: w.stringNumber, fretNumber: w.fretNumber))
          .toList();
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FindFretScreen(
          durationSeconds: _selectedDurationMinutes * 60,
          includeAccidentals: _includeAccidentals,
          isWeakSpotFocus: _isWeakSpotFocus,
          weakTargetPositions: weakTargetPositions,
        ),
      ),
    );
    _loadStats(); // Refresh stats when returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121216),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Main Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.amber, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FRET HQ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Fretboard Memorization & Trainer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Personal Best & Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F1C2E), Color(0xFF161424)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.purple.shade400.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'YOUR PRACTICE STATS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isLoadingStats
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn('Best Score', '$_highScore', 'Notes/min'),
                                  _buildStatColumn('Accuracy', '${_bestAccuracy.toStringAsFixed(1)}%', 'Best %'),
                                  _buildStatColumn('Tests Run', '$_totalGames', 'Completed'),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.analytics_outlined, color: Colors.cyanAccent, size: 16),
                                  label: const Text(
                                    'VIEW PERFORMANCE & WEAK SPOTS',
                                    style: TextStyle(
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'TRAINING GAMES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),

              // Game 1 Card (Identify Note)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF262238), Color(0xFF1C182B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'GAME 1',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${_selectedDurationMinutes} Min Test',
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Identify Note',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A string and fret position is highlighted on a 6-string guitar. Identify the correct note as fast as possible.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Note Scope: Easy (Main 7 notes) vs Full (All 12 notes)
                      const Text(
                        'NOTE SCOPE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _includeAccidentals = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_includeAccidentals ? Colors.amber : const Color(0xFF171424),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: !_includeAccidentals ? Colors.amber : Colors.white12,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Easy Mode',
                                      style: TextStyle(
                                        color: !_includeAccidentals ? Colors.black : Colors.grey.shade300,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Main 7 Notes (C,D,E,F,G,A,B)',
                                      style: TextStyle(
                                        color: !_includeAccidentals ? Colors.black87 : Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _includeAccidentals = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _includeAccidentals ? Colors.amber : const Color(0xFF171424),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _includeAccidentals ? Colors.amber : Colors.white12,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Full Mode',
                                      style: TextStyle(
                                        color: _includeAccidentals ? Colors.black : Colors.grey.shade300,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'All 12 Notes (Sharps & Flats)',
                                      style: TextStyle(
                                        color: _includeAccidentals ? Colors.black87 : Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Adaptive Training Switch Toggle Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171424),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isWeakSpotFocus ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.center_focus_strong,
                              color: _isWeakSpotFocus ? Colors.redAccent : Colors.grey.shade500,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Adaptive Weak Spot Focus',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isWeakSpotFocus ? Colors.redAccent : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Target frets you miss most often based on history',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isWeakSpotFocus,
                              activeColor: Colors.redAccent,
                              onChanged: (val) {
                                setState(() {
                                  _isWeakSpotFocus = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selectable Duration Chips
                      const Text(
                        'TEST DURATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _durationOptions.map((mins) {
                          final isSelected = _selectedDurationMinutes == mins;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDurationMinutes = mins;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.amber
                                        : const Color(0xFF171424),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.amber
                                          : Colors.white12,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${mins}m',
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.grey.shade300,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _navigateToGame1,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                'START ${_selectedDurationMinutes} MIN TEST',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Game 2 Active Training Card (Find Fret Location)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1E28), Color(0xFF151420)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'GAME 2',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Find Fret Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.touch_app, color: Colors.cyanAccent, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Given a target note name, tap its exact string and fret position on the interactive guitar neck.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _navigateToGame2,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.touch_app, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'START FIND FRET TEST (${_selectedDurationMinutes}M)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Game 3 Placeholder (Scale & Chord Practice)
              _buildComingSoonCard(
                gameNumber: 'GAME 3',
                title: 'Scale & Interval Quiz',
                description: 'Master major/minor scales, pentatonics, and musical intervals on the neck.',
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, String sub) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
          ),
        ),
        Text(
          sub,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonCard({
    required String gameNumber,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF181622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      gameNumber,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'COMING SOON',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_clock, color: Colors.grey.shade700, size: 24),
        ],
      ),
    );
  }
}
