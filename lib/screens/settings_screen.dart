import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTuning = 'Standard E (E A D G B E)';
  String _accidentalStyle = 'both'; // 'both', 'sharps', 'flats'
  bool _hapticsEnabled = true;
  bool _soundEnabled = true;

  final List<String> _tuningOptions = [
    'Standard E (E A D G B E)',
    'Drop D (D A D G B E)',
    'Half-Step Down (E♭ A♭ D♭ G♭ B♭ E♭)',
    'DADGAD (D A D G A D)',
    'Open G (D G D G B D)',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTuning = prefs.getString('pref_tuning') ?? _tuningOptions[0];
      _accidentalStyle = prefs.getString('pref_accidentals') ?? 'both';
      _hapticsEnabled = prefs.getBool('pref_haptics') ?? true;
      _soundEnabled = prefs.getBool('pref_sound') ?? true;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  void _triggerHaptic() {
    if (_hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void _confirmResetData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.coralGlow),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 24),
            SizedBox(width: 8),
            Text('Reset Practice Data?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will permanently erase all test sessions, weak spot analytics, and personal high scores. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final db = await DatabaseHelper.instance.database;
              await db.delete('answer_logs');
              await db.delete('game_sessions');
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('high_score');
              await prefs.remove('best_accuracy');
              await prefs.remove('total_games');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Practice data successfully reset.'),
                    backgroundColor: AppColors.emerald,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          children: [
            // Tuning Section
            const _SectionHeader(title: 'GUITAR TUNING & NECK SETUP', icon: Icons.tune),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Tuning Preset',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Calculates fretboard positions and standard open string pitches.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderMedium),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTuning,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        items: _tuningOptions.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedTuning = val);
                            _savePreference('pref_tuning', val);
                            _triggerHaptic();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Accidental Notation Style
            const _SectionHeader(title: 'NOTATION & ACCIDENTALS', icon: Icons.music_note),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accidental Display Style',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose how non-natural chromatic notes are labeled in quizzes and fretboard prompts.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildAccidentalOption('both', 'Both (C♯/D♭)'),
                      const SizedBox(width: 8),
                      _buildAccidentalOption('sharps', 'Sharps (♯)'),
                      const SizedBox(width: 8),
                      _buildAccidentalOption('flats', 'Flats (♭)'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Feedback & Experience
            const _SectionHeader(title: 'FEEDBACK & TACTILE', icon: Icons.vibration),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Haptic Vibration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Tactile response on note taps and correct answers', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _hapticsEnabled,
                    activeColor: AppColors.gold,
                    onChanged: (val) {
                      setState(() => _hapticsEnabled = val);
                      _savePreference('pref_haptics', val);
                      if (val) HapticFeedback.mediumImpact();
                    },
                  ),
                  const Divider(color: AppColors.borderSubtle),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sound Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Audio cues for correct and incorrect answers', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _soundEnabled,
                    activeColor: AppColors.cyan,
                    onChanged: (val) {
                      setState(() => _soundEnabled = val);
                      _savePreference('pref_sound', val);
                      _triggerHaptic();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Danger Zone / Reset
            const _SectionHeader(title: 'DATA MANAGEMENT', icon: Icons.storage),
            const SizedBox(height: 10),
            GlassCard(
              borderColor: AppColors.coral.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Reset Analytics & Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.coral)),
                        SizedBox(height: 2),
                        Text('Clear all session history and weak spots', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _confirmResetData,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coral,
                      side: const BorderSide(color: AppColors.coral),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // About Footer
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: AppColors.gold, size: 24),
                  ),
                  const SizedBox(height: 8),
                  const Text('FRET HQ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2)),
                  const SizedBox(height: 2),
                  const Text('Version 2.0.0 • Pro Guitar Mastery', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAccidentalOption(String id, String label) {
    final isSelected = _accidentalStyle == id;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _accidentalStyle = id);
          _savePreference('pref_accidentals', id);
          _triggerHaptic();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.gold : AppColors.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.white70,
              ),
            ),
          ),
        ),
      ),
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
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
