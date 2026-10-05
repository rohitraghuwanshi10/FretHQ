import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import '../widgets/glass_card.dart';
import 'identify_note_screen.dart';
import 'find_fret_screen.dart';
import 'scale_quiz_screen.dart';
import 'circle_of_fifths_screen.dart';
import 'circle_quiz_screen.dart';
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

  final List<int> _durationOptions = [0, 1, 2, 3, 5, 10];

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

  void _navigateToCircleOfFifths() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CircleOfFifthsScreen(),
      ),
    );
  }

  void _navigateToCircleQuiz() {
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => CircleQuizScreen(
              durationSeconds: _selectedDurationMinutes * 60,
            ),
          ),
        )
        .then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTwoColumn = ResponsiveLayout.isWideDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final borderSubtle = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveLayout.contentWidth(context, desktopMaxWidth: 1100),
            ),
            child: SingleChildScrollView(
              padding: isDesktop
                  ? const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0)
                  : const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Sleek Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: isDesktop ? 44 : 38,
                              height: isDesktop ? 44 : 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Icon(Icons.music_note_rounded, color: AppColors.primary, size: isDesktop ? 24 : 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isDesktop ? 'FRETBOARD TRAINING HUB' : 'FRET HQ',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isDesktop ? 22 : 18,
                                      fontWeight: FontWeight.w900,
                                      color: textPrimary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'Master note positions, intervals, and fret recognition',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: isDesktop ? 13 : 11, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isEmbedded)
                        IconButton(
                          icon: const Icon(Icons.insights_rounded, size: 22),
                          color: textSecondary,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                            );
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. Practice Performance Summary Row
                  GlassCard(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 28 : 16,
                      vertical: isDesktop ? 18 : 14,
                    ),
                    child: _isLoadingStats
                        ? const SizedBox(
                            height: 48,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Best Score', '$_highScore', 'notes/min', textPrimary, textSecondary, isDesktop),
                              Container(height: isDesktop ? 36 : 28, width: 1, color: borderSubtle),
                              _buildStatItem('Accuracy', '${_bestAccuracy.toStringAsFixed(1)}%', 'best %', textPrimary, textSecondary, isDesktop),
                              Container(height: isDesktop ? 36 : 28, width: 1, color: borderSubtle),
                              _buildStatItem('Sessions', '$_totalGames', 'completed', textPrimary, textSecondary, isDesktop),
                            ],
                          ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Desktop 2-Column Split vs Mobile Single Column
                  if (isTwoColumn)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Settings & Guide (360px)
                        SizedBox(
                          width: 360,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPracticeSettingsCard(),
                              const SizedBox(height: 16),
                              _buildQuickTipsCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right: Training Modes Cards (Expanded)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRAINING MODES',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: textSecondary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildGameCard(
                                title: 'Identify Note',
                                subtitle: 'A fret position is illuminated on the guitar neck. Name the note as quickly and accurately as possible.',
                                icon: Icons.visibility_outlined,
                                accentColor: AppColors.primary,
                                badgeText: 'Visual Recognition',
                                onTap: _navigateToGame1,
                              ),
                              const SizedBox(height: 14),
                              _buildGameCard(
                                title: 'Find Fret Location',
                                subtitle: 'Given a target note and string, tap the exact fret position directly on the interactive fretboard.',
                                icon: Icons.touch_app_outlined,
                                accentColor: AppColors.cyan,
                                badgeText: 'Spatial Memory',
                                onTap: _navigateToGame2,
                              ),
                              const SizedBox(height: 14),
                              _buildGameCard(
                                title: 'Scale & Interval Quiz',
                                subtitle: 'Test your understanding of root notes, intervals, 3rds, 5ths, and scale degrees across keys.',
                                icon: Icons.auto_stories_outlined,
                                accentColor: AppColors.purple,
                                badgeText: 'Music Theory',
                                onTap: _navigateToGame3,
                              ),
                              const SizedBox(height: 14),
                              _buildGameCard(
                                title: 'Circle of Fifths',
                                subtitle: 'Interactive theory wheel: explore key signatures, relative minors, and 6-chord song families synced with the fretboard.',
                                icon: Icons.donut_large_rounded,
                                accentColor: AppColors.emerald,
                                badgeText: 'Harmonic Wheel',
                                onTap: _navigateToCircleOfFifths,
                              ),
                              const SizedBox(height: 14),
                              _buildGameCard(
                                title: 'Circle of Fifths Quiz',
                                subtitle: 'Master key signatures, relative minors, 4ths/5ths, and chord progression degrees with fast-paced visual challenges.',
                                icon: Icons.psychology_outlined,
                                accentColor: AppColors.purple,
                                badgeText: 'Theory Quiz',
                                onTap: _navigateToCircleQuiz,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Mobile Stack
                    _buildPracticeSettingsCard(),
                    const SizedBox(height: 20),
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
                      badgeText: 'Visual',
                      onTap: _navigateToGame1,
                    ),
                    const SizedBox(height: 10),
                    _buildGameCard(
                      title: 'Find Fret Location',
                      subtitle: 'Given a target note & string, tap the correct fret position.',
                      icon: Icons.touch_app_outlined,
                      accentColor: AppColors.cyan,
                      badgeText: 'Fretboard Tap',
                      onTap: _navigateToGame2,
                    ),
                    const SizedBox(height: 10),
                    _buildGameCard(
                      title: 'Scale & Interval Quiz',
                      subtitle: 'Recognize intervals, 3rds, 5ths, and scale degrees.',
                      icon: Icons.auto_stories_outlined,
                      accentColor: AppColors.purple,
                      badgeText: 'Theory Quiz',
                      onTap: _navigateToGame3,
                    ),
                    const SizedBox(height: 10),
                    _buildGameCard(
                      title: 'Circle of Fifths',
                      subtitle: 'Interactive wheel: keys, relative minors & chord families.',
                      icon: Icons.donut_large_rounded,
                      accentColor: AppColors.emerald,
                      badgeText: 'Theory Wheel',
                      onTap: _navigateToCircleOfFifths,
                    ),
                    const SizedBox(height: 10),
                    _buildGameCard(
                      title: 'Circle of Fifths Quiz',
                      subtitle: 'Key signatures, relative minors & chord progressions.',
                      icon: Icons.psychology_outlined,
                      accentColor: AppColors.purple,
                      badgeText: 'Theory Quiz',
                      onTap: _navigateToCircleQuiz,
                    ),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeSettingsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final surfaceElevated = isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;
    final borderSubtle = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    return GlassCard(
      padding: const EdgeInsets.all(18),
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
                  fontWeight: FontWeight.w800,
                  color: textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_selectedDurationMinutes == 0 ? "No Timer" : "${_selectedDurationMinutes}m"} • ${_includeAccidentals ? "Chromatic" : "Naturals"}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

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

          const SizedBox(height: 14),

          // Duration selection
          Row(
            children: [
              Text(
                'SESSION DURATION',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textSecondary, letterSpacing: 0.5),
              ),
              const Spacer(),
              if (_selectedDurationMinutes == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'No Timer • Untimed',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.cyan),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _durationOptions.map((mins) {
              final isSelected = _selectedDurationMinutes == mins;
              return Expanded(
                flex: mins == 0 ? 3 : 2,
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : borderSubtle,
                        ),
                      ),
                      child: Center(
                        child: mins == 0
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.all_inclusive_rounded,
                                    size: 13,
                                    color: isSelected ? Colors.white : textSecondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'None',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                '${mins}m',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : textSecondary,
                                  fontWeight: FontWeight.w700,
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

          const SizedBox(height: 14),

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
                    size: 18,
                    color: _isWeakSpotFocus ? AppColors.primary : textSecondary,
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
                            fontWeight: FontWeight.w600,
                            color: _isWeakSpotFocus ? textPrimary : textSecondary,
                          ),
                        ),
                        Text(
                          'Targets frets with lowest accuracy',
                          style: TextStyle(fontSize: 10, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: _isWeakSpotFocus,
                      activeThumbColor: AppColors.primary,
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
    );
  }

  Widget _buildQuickTipsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold, size: 16),
              SizedBox(width: 8),
              Text(
                'MASTERY TIPS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• Start with Natural notes (A-G) before adding accidentals.\n'
            '• Use the Fretboard Heatmap in Analytics to identify cold spots.\n'
            '• A 2-minute daily session builds rapid fretboard intuition.',
            style: TextStyle(fontSize: 11, color: textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color primaryColor, Color secondaryColor, bool isDesktop) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isDesktop ? 26 : 20,
            fontWeight: FontWeight.w900,
            color: primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 12 : 10,
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
    required String badgeText,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 18),
                const SizedBox(width: 4),
                Text(
                  _selectedDurationMinutes == 0 ? 'Start' : '${_selectedDurationMinutes}m',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
