import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/high_score_service.dart';
import '../services/database_helper.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'identify_note_screen.dart';
import 'find_fret_screen.dart';
import 'scale_quiz_screen.dart';
import 'analytics_screen.dart';
import 'tuner_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isEmbedded;

  const HomeScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _highScore = 0;
  double _bestAccuracy = 0.0;
  int _totalGames = 0;
  bool _isLoadingStats = true;
  int _selectedDurationMinutes = 1;
  bool _includeAccidentals = false;
  bool _isWeakSpotFocus = false;

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
    HapticFeedback.mediumImpact();
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
    _loadStats();
  }

  void _navigateToGame2() async {
    HapticFeedback.mediumImpact();
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
    _loadStats();
  }

  void _navigateToGame3() async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScaleQuizScreen(
          durationSeconds: _selectedDurationMinutes * 60,
        ),
      ),
    );
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Header Logo & Branding
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.music_note_rounded, color: AppColors.gold, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
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
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GlassBadge(
                    text: 'PRO',
                    color: AppColors.gold,
                    fontSize: 10,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Practice Stats Summary Card
              GlassCard(
                gradient: AppColors.heroCardGradient,
                borderColor: AppColors.purple.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'PRACTICE PERFORMANCE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        if (!widget.isEmbedded)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                              );
                            },
                            child: const Text(
                              'Details →',
                              style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isLoadingStats
                        ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('Best Score', '$_highScore', 'Notes/min'),
                              _buildStatColumn('Accuracy', '${_bestAccuracy.toStringAsFixed(1)}%', 'Best %'),
                              _buildStatColumn('Tests Run', '$_totalGames', 'Completed'),
                            ],
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Global Practice Preferences Card
              const _SectionHeader(title: 'PRACTICE CONFIGURATION', icon: Icons.tune_rounded),
              const SizedBox(height: 10),

              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Note Scope Toggle
                    const Text(
                      'NOTE SCOPE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.gold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _includeAccidentals = false);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_includeAccidentals ? AppColors.gold : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !_includeAccidentals ? AppColors.gold : AppColors.borderSubtle,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Easy Mode',
                                    style: TextStyle(
                                      color: !_includeAccidentals ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '7 Naturals (C, D, E, F, G, A, B)',
                                    style: TextStyle(
                                      color: !_includeAccidentals ? Colors.black87 : AppColors.textMuted,
                                      fontSize: 9,
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
                              HapticFeedback.selectionClick();
                              setState(() => _includeAccidentals = true);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _includeAccidentals ? AppColors.gold : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _includeAccidentals ? AppColors.gold : AppColors.borderSubtle,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Full Mode',
                                    style: TextStyle(
                                      color: _includeAccidentals ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'All 12 Chromatic Notes',
                                    style: TextStyle(
                                      color: _includeAccidentals ? Colors.black87 : AppColors.textMuted,
                                      fontSize: 9,
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

                    // Adaptive Weak Spot Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isWeakSpotFocus ? AppColors.coral.withValues(alpha: 0.5) : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.center_focus_strong_rounded,
                            color: _isWeakSpotFocus ? AppColors.coral : AppColors.textMuted,
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
                                    color: _isWeakSpotFocus ? AppColors.coral : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  'Target frets you miss most often based on history',
                                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isWeakSpotFocus,
                            activeColor: AppColors.coral,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _isWeakSpotFocus = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Test Duration Chips
                    const Text(
                      'TEST DURATION',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.gold, letterSpacing: 1.0),
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
                                HapticFeedback.selectionClick();
                                setState(() => _selectedDurationMinutes = mins);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.gold : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.gold : AppColors.borderSubtle,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${mins}m',
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white70,
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Training Games Section
              const _SectionHeader(title: 'TRAINING GAMES', icon: Icons.sports_esports_rounded),
              const SizedBox(height: 12),

              // Game 1: Identify Note
              GlassCard(
                borderColor: AppColors.gold.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlassBadge(text: 'GAME 1', color: AppColors.gold),
                        Row(
                          children: [
                            GlassBadge(
                              text: _includeAccidentals ? 'Full Mode' : 'Easy Mode',
                              color: _includeAccidentals ? AppColors.gold : AppColors.emerald,
                              fontSize: 9,
                            ),
                            if (_isWeakSpotFocus) ...[
                              const SizedBox(width: 4),
                              GlassBadge(text: 'Adaptive', color: AppColors.coral, fontSize: 9),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Identify Note',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'A position is highlighted on the 6-string guitar neck. Identify the note name as fast as possible.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToGame1,
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: Text('START IDENTIFY NOTE (${_selectedDurationMinutes}M)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Game 2: Find Fret Location
              GlassCard(
                borderColor: AppColors.cyan.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlassBadge(text: 'GAME 2', color: AppColors.cyan),
                        Row(
                          children: [
                            GlassBadge(
                              text: _includeAccidentals ? 'Full Mode' : 'Easy Mode',
                              color: _includeAccidentals ? AppColors.gold : AppColors.emerald,
                              fontSize: 9,
                            ),
                            if (_isWeakSpotFocus) ...[
                              const SizedBox(width: 4),
                              GlassBadge(text: 'Adaptive', color: AppColors.coral, fontSize: 9),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Find Fret Location',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Given a target note and string, tap its exact fret position on the interactive guitar neck.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToGame2,
                        icon: const Icon(Icons.touch_app_rounded, size: 20),
                        label: Text('START FIND FRET (${_selectedDurationMinutes}M)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Game 3: Scale & Interval Quiz
              GlassCard(
                borderColor: AppColors.purple.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlassBadge(text: 'GAME 3', color: AppColors.purple),
                        GlassBadge(text: 'Theory', color: AppColors.purple, fontSize: 9),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scale & Interval Quiz',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Master 3rds, 5ths, octaves, and scale notes across the neck with rapid interval ear & fret recognition.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToGame3,
                        icon: const Icon(Icons.psychology_rounded, size: 20),
                        label: Text('START SCALE QUIZ (${_selectedDurationMinutes}M)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!widget.isEmbedded) ...[
                const SizedBox(height: 24),
                // Guitar Tools Section if not embedded in bottom nav
                const _SectionHeader(title: 'GUITAR UTILITIES', icon: Icons.build_circle_outlined),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const TunerScreen(initialTabIndex: 0)),
                          );
                        },
                        icon: const Icon(Icons.tune_rounded, color: AppColors.gold, size: 16),
                        label: const Text('Tuner', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const TunerScreen(initialTabIndex: 1)),
                          );
                        },
                        icon: const Icon(Icons.build_circle_outlined, color: AppColors.cyan, size: 16),
                        label: const Text('Intonation', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const TunerScreen(initialTabIndex: 2)),
                          );
                        },
                        icon: const Icon(Icons.speed_rounded, color: AppColors.purple, size: 16),
                        label: const Text('Metronome', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

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
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.gold),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.gold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
