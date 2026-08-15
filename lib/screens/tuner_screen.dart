import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/pitch_service.dart';
import '../services/intonation_service.dart';
import '../services/metronome_service.dart';
import '../models/metronome_pattern.dart';
import '../widgets/tuner_gauge_widget.dart';
import '../widgets/metronome_pendulum_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';

class TunerScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool isEmbedded;

  const TunerScreen({
    super.key,
    this.initialTabIndex = 0,
    this.isEmbedded = false,
  });

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PitchService _pitchService = PitchService();
  final IntonationService _intonationService = IntonationService();
  final MetronomeService _metronomeService = MetronomeService.instance;

  StreamSubscription<TunerNote>? _pitchSubscription;
  TunerNote? _currentNote;

  // Intonation wizard state
  int _selectedIntonationString = 6; // Default Low E
  int _intonationStep = 1; // 1 = Open, 2 = 12th Fret
  double? _openFreqCaptured;
  double? _fret12FreqCaptured;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_handleTabChange);
    if (widget.initialTabIndex != 2) {
      _initPitchListener();
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 2) {
      _pitchService.stopListening();
    } else {
      _initPitchListener();
    }
  }

  Future<void> _initPitchListener() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android)) {
      try {
        final micStatus = await Permission.microphone.request();
        debugPrint('TunerScreen: Permission.microphone.request() returned $micStatus');
      } catch (e) {
        debugPrint('Permission request error: $e');
      }
    }

    final success = await _pitchService.startListening();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not start microphone stream. Use the string reference chips below to test pitches.'),
          backgroundColor: AppColors.gold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    _pitchSubscription = _pitchService.pitchStream.listen((note) {
      if (!mounted) return;
      setState(() {
        _currentNote = note;
      });

      _processIntonationCapture(note);
    });
  }

  void _processIntonationCapture(TunerNote note) {
    if (note.detectedFrequency <= 40) return;

    if (_intonationStep == 1 && _openFreqCaptured == null) {
      setState(() {
        _openFreqCaptured = note.detectedFrequency;
        _intonationStep = 2;
      });
      HapticFeedback.mediumImpact();
    } else if (_intonationStep == 2 && _openFreqCaptured != null && _fret12FreqCaptured == null) {
      if (note.detectedFrequency > _openFreqCaptured! * 1.5) {
        setState(() {
          _fret12FreqCaptured = note.detectedFrequency;
          _intonationService.recordResult(
            stringNumber: _selectedIntonationString,
            openFreq: _openFreqCaptured!,
            fret12Freq: _fret12FreqCaptured!,
          );
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _resetIntonationStep() {
    HapticFeedback.selectionClick();
    setState(() {
      _intonationStep = 1;
      _openFreqCaptured = null;
      _fret12FreqCaptured = null;
    });
  }

  @override
  void dispose() {
    _pitchSubscription?.cancel();
    _pitchService.dispose();
    _metronomeService.stop();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: const Text('Guitar Tools & Diagnostics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Tuner'),
            Tab(icon: Icon(Icons.build_circle_outlined, size: 18), text: 'Intonation'),
            Tab(icon: Icon(Icons.speed_rounded, size: 18), text: 'Metronome'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTunerTab(),
          _buildIntonationTab(),
          _buildMetronomeTab(),
        ],
      ),
    );
  }

  // ==========================================
  // --- TAB 1: CHROMATIC TUNER ---
  // ==========================================
  Widget _buildTunerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      child: Column(
        children: [
          const SizedBox(height: 6),

          // Tuner Analog Gauge Widget
          TunerGaugeWidget(currentNote: _currentNote),

          const SizedBox(height: 20),

          // Standard Guitar Tuning References Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.music_note_rounded, color: AppColors.gold, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'STANDARD GUITAR STRINGS (E A D G B E)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStringRefChip('6: Low E', 'E2 (82.4 Hz)', 82.41, _currentNote?.noteName == 'E' && _currentNote?.octave == 2),
                    _buildStringRefChip('5: A', 'A2 (110 Hz)', 110.00, _currentNote?.noteName == 'A' && _currentNote?.octave == 2),
                    _buildStringRefChip('4: D', 'D3 (147 Hz)', 146.83, _currentNote?.noteName == 'D' && _currentNote?.octave == 3),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStringRefChip('3: G', 'G3 (196 Hz)', 196.00, _currentNote?.noteName == 'G' && _currentNote?.octave == 3),
                    _buildStringRefChip('2: B', 'B3 (247 Hz)', 246.94, _currentNote?.noteName == 'B' && _currentNote?.octave == 3),
                    _buildStringRefChip('1: High E', 'E4 (330 Hz)', 329.63, _currentNote?.noteName == 'E' && _currentNote?.octave == 4),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Diagnostic Pitch Trigger
          GlassCard(
            borderColor: AppColors.cyan.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, color: AppColors.cyan, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Test Frequency Trigger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      Text('Tap any string chip above to simulate frequency input', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStringRefChip(String stringLabel, String sub, double targetFreq, bool isActive) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _pitchService.injectFrequency(targetFreq);
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.emerald.withValues(alpha: 0.25) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? AppColors.emerald : AppColors.borderSubtle,
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  stringLabel,
                  style: TextStyle(
                    color: isActive ? AppColors.emerald : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    color: isActive ? AppColors.emerald : AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- TAB 2: INTONATION CHECKER WIZARD ---
  // ==========================================
  Widget _buildIntonationTab() {
    final currentResult = _intonationService.getResult(_selectedIntonationString);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),

          // Overview Guidance Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'GUITAR INTONATION DIAGNOSTICS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyan, letterSpacing: 1.0),
                ),
                SizedBox(height: 6),
                Text(
                  'Intonation ensures your guitar plays in tune across the entire neck. We compare open string frequency with the 12th fret octave.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // String Selector
          const Text(
            'SELECT STRING TO TEST',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),

          Row(
            children: [6, 5, 4, 3, 2, 1].map((s) {
              final isSelected = _selectedIntonationString == s;
              final hasData = _intonationService.getResult(s) != null;
              final sNames = {6: '6: E', 5: '5: A', 4: '4: D', 3: '3: G', 2: '2: B', 1: '1: E'};

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedIntonationString = s;
                        _resetIntonationStep();
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.gold : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : (hasData ? AppColors.cyan : AppColors.borderSubtle),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          sNames[s]!,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
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

          const SizedBox(height: 20),

          // Intonation 2-Step Live Capture Wizard
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STEP $_intonationStep OF 2',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cyan, letterSpacing: 1.0),
                    ),
                    TextButton(
                      onPressed: _resetIntonationStep,
                      child: const Text('Reset', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Step 1: Open String
                _buildStepRow(
                  stepNum: 1,
                  isActive: _intonationStep == 1,
                  isDone: _openFreqCaptured != null,
                  title: 'Pluck Open String',
                  subtitle: _openFreqCaptured != null
                      ? 'Captured: ${_openFreqCaptured!.toStringAsFixed(1)} Hz'
                      : 'Pluck the open string clearly',
                ),

                const SizedBox(height: 12),

                // Step 2: 12th Fret Octave
                _buildStepRow(
                  stepNum: 2,
                  isActive: _intonationStep == 2,
                  isDone: _fret12FreqCaptured != null,
                  title: 'Pluck 12th Fret Note',
                  subtitle: _fret12FreqCaptured != null
                      ? 'Captured: ${_fret12FreqCaptured!.toStringAsFixed(1)} Hz'
                      : 'Fret or play 12th fret harmonic',
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Diagnostic Intonation Advice Card
          if (currentResult != null) ...[
            GlassCard(
              borderColor: currentResult.status == IntonationStatus.ideal
                  ? AppColors.emerald.withValues(alpha: 0.4)
                  : AppColors.gold.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        currentResult.status == IntonationStatus.ideal
                            ? Icons.check_circle_rounded
                            : Icons.build_circle_rounded,
                        color: currentResult.status == IntonationStatus.ideal
                            ? AppColors.emerald
                            : AppColors.gold,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'INTONATION ANALYSIS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: currentResult.status == IntonationStatus.ideal
                              ? AppColors.emerald
                              : AppColors.gold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentResult.saddleRecommendation,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deviation: ${currentResult.centsDeviation > 0 ? "+" : ""}${currentResult.centsDeviation.toStringAsFixed(1)} cents (Open: ${currentResult.openFrequency.toStringAsFixed(1)} Hz vs 12th: ${currentResult.fret12Frequency.toStringAsFixed(1)} Hz)',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required int stepNum,
    required bool isActive,
    required bool isDone,
    required String title,
    required String subtitle,
  }) {
    Color color = isDone ? AppColors.emerald : (isActive ? AppColors.gold : AppColors.textMuted);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: AppColors.emerald, size: 18)
                : Text('$stepNum', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.white70)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // --- TAB 3: PRO METRONOME ---
  // ==========================================
  Widget _buildMetronomeTab() {
    final bpm = _metronomeService.bpm;
    final isPlaying = _metronomeService.isPlaying;
    final activeSig = _metronomeService.timeSignature;
    final activeSub = _metronomeService.subdivision;
    final speedTrainer = _metronomeService.speedTrainerEnabled;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Pendulum & LED Beat Strip
          MetronomePendulumWidget(metronomeService: _metronomeService),

          const SizedBox(height: 16),

          // BPM Stepper Controls & Slider
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStepButton('-5', () => setState(() => _metronomeService.adjustBpm(-5))),
                    _buildStepButton('-1', () => setState(() => _metronomeService.adjustBpm(-1))),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.gold,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: AppColors.gold,
                          overlayColor: AppColors.gold.withValues(alpha: 0.2),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                        ),
                        child: Slider(
                          value: bpm.toDouble(),
                          min: 30,
                          max: 300,
                          onChanged: (val) {
                            setState(() => _metronomeService.setBpm(val.round()));
                          },
                        ),
                      ),
                    ),
                    _buildStepButton('+1', () => setState(() => _metronomeService.adjustBpm(1))),
                    _buildStepButton('+5', () => setState(() => _metronomeService.adjustBpm(5))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tap Tempo Button
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        final calc = _metronomeService.recordTapTempo();
                        if (calc != null) {
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.touch_app_rounded, size: 16),
                      label: const Text('TAP TEMPO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.gold,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.gold),
                        ),
                      ),
                    ),

                    // Play / Stop Toggle Button
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _metronomeService.togglePlay());
                      },
                      icon: Icon(isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 20),
                      label: Text(isPlaying ? 'STOP' : 'START'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPlaying ? AppColors.coral : AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Time Signature Selection
          const _SectionHeader(title: 'TIME SIGNATURE & METER', icon: Icons.straighten_rounded),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TimeSignaturePreset.presets.map((preset) {
                final isSelected = activeSig.name == preset.name;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _metronomeService.setTimeSignature(preset));
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.gold : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // Subdivision Selection
          const _SectionHeader(title: 'RHYTHM SUBDIVISION', icon: Icons.graphic_eq_rounded),
          const SizedBox(height: 8),
          Row(
            children: Subdivision.values.map((sub) {
              final isSelected = activeSub == sub;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _metronomeService.setSubdivision(sub));
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.cyan : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.cyan : AppColors.borderSubtle,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            sub.symbol,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black87 : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // Practice Timer Selection
          const _SectionHeader(title: 'PRACTICE TIMER (AUTO-STOP)', icon: Icons.timer_outlined),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimerChip('∞ Continuous', null, _metronomeService.timerDurationSeconds == null),
                _buildTimerChip('1 min', 60, _metronomeService.timerDurationSeconds == 60),
                _buildTimerChip('2 min', 120, _metronomeService.timerDurationSeconds == 120),
                _buildTimerChip('3 min', 180, _metronomeService.timerDurationSeconds == 180),
                _buildTimerChip('5 min', 300, _metronomeService.timerDurationSeconds == 300),
                _buildTimerChip('10 min', 600, _metronomeService.timerDurationSeconds == 600),
                _buildTimerChip('15 min', 900, _metronomeService.timerDurationSeconds == 900),
                _buildTimerChip('20 min', 1200, _metronomeService.timerDurationSeconds == 1200),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Speed Trainer Configuration Card
          GlassCard(
            borderColor: speedTrainer ? AppColors.purple.withValues(alpha: 0.5) : AppColors.borderSubtle,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: speedTrainer ? AppColors.purple : AppColors.textMuted,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Speed Trainer (Auto-Increment)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: speedTrainer ? AppColors.purple : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+${_metronomeService.speedTrainerIncrement} BPM every ${_metronomeService.speedTrainerBars} bars',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: speedTrainer,
                  activeTrackColor: AppColors.purple.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.purple,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _metronomeService.setSpeedTrainer(enabled: val));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTimerChip(String label, int? seconds, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _metronomeService.setTimerDuration(seconds));
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.emerald : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.emerald : AppColors.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.white,
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
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
