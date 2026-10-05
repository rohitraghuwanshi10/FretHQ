import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/circle_key.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import '../widgets/circle_fretboard_widget.dart';
import '../widgets/circle_of_fifths_widget.dart';
import '../widgets/glass_card.dart';
import 'circle_quiz_screen.dart';

class CircleOfFifthsScreen extends StatefulWidget {
  final bool isEmbedded;

  const CircleOfFifthsScreen({super.key, this.isEmbedded = false});

  @override
  State<CircleOfFifthsScreen> createState() => _CircleOfFifthsScreenState();
}

class _CircleOfFifthsScreenState extends State<CircleOfFifthsScreen> {
  CircleKey _selectedKey = CircleKey.circleKeys[0]; // Start with C Major / Am
  bool _isMinorSelected = false;
  ChordInfo? _isolatedChord;

  void _onKeyChanged(CircleKey key, bool isMinor) {
    setState(() {
      _selectedKey = key;
      _isMinorSelected = isMinor;
      _isolatedChord = null; // Reset chord isolation when key changes
    });
  }

  void _toggleChordIsolation(ChordInfo chord) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_isolatedChord == chord) {
        _isolatedChord = null; // Unselect and show full scale
      } else {
        _isolatedChord = chord;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTwoColumn = ResponsiveLayout.isWideDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Circle of Fifths',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              centerTitle: true,
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveLayout.contentWidth(context, desktopMaxWidth: 1150),
            ),
            child: SingleChildScrollView(
              padding: isDesktop
                  ? const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0)
                  : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header & Mode Indicator
                  _buildHeader(textPrimary, textSecondary),

                  const SizedBox(height: 18),

                  // 2. Main Content: 2-Column Split (Desktop) vs Stack (Mobile)
                  if (isTwoColumn)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Interactive Wheel
                        SizedBox(
                          width: 440,
                          child: Column(
                            children: [
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    CircleOfFifthsWidget(
                                      selectedKey: _selectedKey,
                                      isMinorSelected: _isMinorSelected,
                                      onKeyChanged: _onKeyChanged,
                                      size: 380,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildWheelHelperText(textSecondary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Key Details, Chords & Fretboard
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKeyOverviewCard(isDark, textPrimary, textSecondary),
                              const SizedBox(height: 16),
                              _buildChordFamilyCard(isDark, textPrimary, textSecondary),
                              const SizedBox(height: 16),
                              _buildFretboardSection(textPrimary, textSecondary),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Mobile Stack
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      child: Column(
                        children: [
                          CircleOfFifthsWidget(
                            selectedKey: _selectedKey,
                            isMinorSelected: _isMinorSelected,
                            onKeyChanged: _onKeyChanged,
                          ),
                          const SizedBox(height: 10),
                          _buildWheelHelperText(textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildKeyOverviewCard(isDark, textPrimary, textSecondary),
                    const SizedBox(height: 16),
                    _buildChordFamilyCard(isDark, textPrimary, textSecondary),
                    const SizedBox(height: 16),
                    _buildFretboardSection(textPrimary, textSecondary),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _isMinorSelected ? AppColors.emerald : AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Circle of Fifths',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Explore keys, accidentals, relative minors, and harmonic chord families',
                style: TextStyle(fontSize: 12.5, color: textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode switch pill
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceElevated
                    : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.borderSubtle
                      : AppColors.lightBorderSubtle,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModePill('Major', !_isMinorSelected, AppColors.primary),
                  _buildModePill('Minor', _isMinorSelected, AppColors.emerald),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Quiz action button
            InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CircleQuizScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.psychology_outlined, size: 15, color: AppColors.purple),
                    SizedBox(width: 5),
                    Text(
                      'Quiz',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModePill(String label, bool isActive, Color activeColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _isMinorSelected = (label == 'Minor');
          _isolatedChord = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWheelHelperText(Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.touch_app_outlined, size: 14, color: textSecondary),
        const SizedBox(width: 6),
        Text(
          'Tap outer ring for Major • Inner ring for Relative Minor',
          style: TextStyle(fontSize: 11, color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildKeyOverviewCard(bool isDark, Color textPrimary, Color textSecondary) {
    final activeColor = _isMinorSelected ? AppColors.emerald : AppColors.primary;
    final currentKeyTitle = _isMinorSelected
        ? '${_selectedKey.minorDisplayName} Natural Minor'
        : '${_selectedKey.majorDisplayName} Major';
    final relativeKeyLabel = _isMinorSelected
        ? 'Relative Major: ${_selectedKey.majorDisplayName}'
        : 'Relative Minor: ${_selectedKey.minorDisplayName}';

    final activeScaleNotes = _isMinorSelected
        ? _selectedKey.relativeMinorScaleNotes
        : _selectedKey.majorScaleNotes;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentKeyTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      relativeKeyLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Accidental Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: activeColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedKey.accidentalSummary,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: activeColor,
                      ),
                    ),
                    Text(
                      _selectedKey.accidentalCount == 0
                          ? 'All Natural'
                          : (_selectedKey.accidentalCount > 0 ? 'Sharps' : 'Flats'),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Accidentals list if any
          if (_selectedKey.accidentalsList.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Accidentals: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary),
                ),
                const SizedBox(width: 6),
                Wrap(
                  spacing: 6,
                  children: _selectedKey.accidentalsList.map((acc) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF232330) : const Color(0xFFE4E4EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        acc,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Scale Notes Sequence
          Text(
            'SCALE NOTES',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: activeScaleNotes.asMap().entries.map((entry) {
              final idx = entry.key;
              final note = entry.value;
              final isRoot = (idx == 0);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: isRoot ? activeColor : (isDark ? const Color(0xFF1B1B26) : const Color(0xFFF0F0F4)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isRoot ? Colors.white.withValues(alpha: 0.6) : (isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle),
                  ),
                ),
                child: Text(
                  note.id,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isRoot ? FontWeight.w900 : FontWeight.w700,
                    color: isRoot ? Colors.white : textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChordFamilyCard(bool isDark, Color textPrimary, Color textSecondary) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHORD PROGRESSION FAMILY',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Harmonic neighborhood for songwriting and Nashville numbers',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
              if (_isolatedChord != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isolatedChord = null);
                  },
                  icon: const Icon(Icons.clear_rounded, size: 14),
                  label: const Text('Show All', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // 7 Chord Pills (I, ii, iii, IV, V, vi, vii°)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedKey.chordFamily.map((chord) {
              final isIsolated = (_isolatedChord == chord);

              Color roleColor;
              if (chord.numeral == 'I') {
                roleColor = AppColors.primary;
              } else if (chord.numeral == 'IV') {
                roleColor = AppColors.cyan;
              } else if (chord.numeral == 'V') {
                roleColor = AppColors.purple;
              } else if (chord.numeral == 'vi') {
                roleColor = AppColors.emerald;
              } else {
                roleColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
              }

              return InkWell(
                onTap: () => _toggleChordIsolation(chord),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isIsolated
                        ? roleColor
                        : (isDark ? const Color(0xFF191924) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isIsolated
                          ? Colors.white
                          : roleColor.withValues(alpha: 0.45),
                      width: isIsolated ? 1.8 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        chord.numeral,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isIsolated ? Colors.white : roleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chord.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isIsolated ? Colors.white : textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFretboardSection(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isolatedChord != null
                  ? 'FRETBOARD: ${_isolatedChord!.name} TRIAD NOTES'
                  : 'FRETBOARD: ${_selectedKey.majorName} SCALE POSITIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            if (_isolatedChord != null)
              Text(
                'Triad: ${_isolatedChord!.triadNotes.map((n) => n.id).join(' - ')}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyan),
              ),
          ],
        ),
        const SizedBox(height: 10),
        CircleFretboardWidget(
          selectedKey: _selectedKey,
          isMinor: _isMinorSelected,
          isolatedChord: _isolatedChord,
          maxFret: 12,
        ),
      ],
    );
  }
}
