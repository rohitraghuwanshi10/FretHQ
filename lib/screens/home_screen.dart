import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'identify_note_screen.dart';
import 'find_fret_screen.dart';
import 'scale_quiz_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isEmbedded;

  const HomeScreen({super.key, this.isEmbedded = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedDurationMinutes = 1;
  bool _includeAccidentals = false;
  bool _isWeakSpotFocus = false;

  int _highScore = 0;
  double _bestAccuracy = 0.0;
  int _totalGames = 0;
  bool _isLoadingStats = true;

  final List<int> _durationOptions = [1, 2, 3, 5, 10];

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
    _loadStats();
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDurationMinutes = prefs.getInt('pref_duration') ?? 1;
      _includeAccidentals = prefs.getBool('pref_accidentals_mode') ?? false;
      _isWeakSpotFocus = prefs.getBool('pref_weak_spots') ?? false;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseHelper.instance;
    final sessions = await db.getAllSessions();

    int bestScore = prefs.getInt('high_score') ?? 0;
    double bestAcc = prefs.getDouble('best_accuracy') ?? 0.0;

    for (final s in sessions) {
      if (s.score > bestScore) bestScore = s.score;
      if (s.accuracy > bestAcc) bestAcc = s.accuracy;
    }

    if (mounted) {
      setState(() {
        _highScore = bestScore;
        _bestAccuracy = bestAcc;
        _totalGames = sessions.length;
        _isLoadingStats = false;
      });
    }
  }

  void _navigateToGame1() {
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => IdentifyNoteScreen(
              durationSeconds: _selectedDurationMinutes * 60,
              includeAccidentals: _includeAccidentals,
              isWeakSpotFocus: _isWeakSpotFocus,
            ),
          ),
        )
        .then((_) => _loadStats());
  }

  void _navigateToGame2() {
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => FindFretScreen(
              durationSeconds: _selectedDurationMinutes * 60,
              includeAccidentals: _includeAccidentals,
              isWeakSpotFocus: _isWeakSpotFocus,
            ),
          ),
        )
        .then((_) => _loadStats());
  }

  void _navigateToGame3() {
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ScaleQuizScreen(
              durationSeconds: _selectedDurationMinutes * 60,
            ),
          ),
        )
        .then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final surfaceElevated = isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;
    final borderSubtle = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Sleek Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FRET HQ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Fretboard Mastery & Practice',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!widget.isEmbedded)
                        IconButton(
                          icon: const Icon(Icons.insights_rounded, size: 20),
                          color: textSecondary,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                            );
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 2. Practice Performance Summary
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: _isLoadingStats
                        ? const SizedBox(
                            height: 48,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Best Score', '$_highScore', 'notes/min', textPrimary, textSecondary),
                              Container(height: 28, width: 1, color: borderSubtle),
                              _buildStatItem('Accuracy', '${_bestAccuracy.toStringAsFixed(1)}%', 'best %', textPrimary, textSecondary),
                              Container(height: 28, width: 1, color: borderSubtle),
                              _buildStatItem('Sessions', '$_totalGames', 'completed', textPrimary, textSecondary),
                            ],
                          ),
                  ),

                  const SizedBox(height: 18),

                  // 3. Compact Practice Settings Card
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PRACTICE SETTINGS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              '${_selectedDurationMinutes}m • ${_includeAccidentals ? "Chromatic" : "Naturals"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Mode Selector (Naturals vs Chromatics)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSegmentButton(
                                  label: 'Naturals (7 Notes)',
                                  isSelected: !_includeAccidentals,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _includeAccidentals = false);
                                    _savePreference('pref_accidentals_mode', false);
                                  },
                                ),
                              ),
                              Expanded(
                                child: _buildSegmentButton(
                                  label: 'All 12 Chromatic',
                                  isSelected: _includeAccidentals,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _includeAccidentals = true);
                                    _savePreference('pref_accidentals_mode', true);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Duration Chips & Weak Spot Toggle Row
                        Row(
                          children: [
                            // Duration selection
                            Expanded(
                              child: Row(
                                children: _durationOptions.map((mins) {
                                  final isSelected = _selectedDurationMinutes == mins;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setState(() => _selectedDurationMinutes = mins);
                                          _savePreference('pref_duration', mins);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(vertical: 7),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary : surfaceElevated,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected ? AppColors.primary : borderSubtle,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${mins}m',
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : textSecondary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Adaptive Weak Spot switch
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isWeakSpotFocus = !_isWeakSpotFocus);
                            _savePreference('pref_weak_spots', _isWeakSpotFocus);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.center_focus_strong_rounded,
                                  size: 16,
                                  color: _isWeakSpotFocus ? AppColors.primary : textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Adaptive Weak Spot Focus',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isWeakSpotFocus ? textPrimary : textSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 24,
                                  child: Switch(
                                    value: _isWeakSpotFocus,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _isWeakSpotFocus = val);
                                      _savePreference('pref_weak_spots', val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Training Games (Clean, Uncluttered List)
                  Text(
                    'TRAINING MODES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildGameCard(
                    title: 'Identify Note',
                    subtitle: 'A fret is highlighted. Name the note as fast as you can.',
                    icon: Icons.visibility_outlined,
                    accentColor: AppColors.primary,
                    onTap: _navigateToGame1,
                  ),
                  const SizedBox(height: 10),

                  _buildGameCard(
                    title: 'Find Fret Location',
                    subtitle: 'Given a target note & string, tap the correct fret position.',
                    icon: Icons.touch_app_outlined,
                    accentColor: AppColors.cyan,
                    onTap: _navigateToGame2,
                  ),
                  const SizedBox(height: 10),

                  _buildGameCard(
                    title: 'Scale & Interval Quiz',
                    subtitle: 'Recognize intervals, 3rds, 5ths, and scale degrees.',
                    icon: Icons.auto_stories_outlined,
                    accentColor: AppColors.purple,
                    onTap: _navigateToGame3,
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color primaryColor, Color secondaryColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceLight : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                  : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 16),
                const SizedBox(width: 2),
                Text(
                  '${_selectedDurationMinutes}m',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
