import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/pitch_service.dart';
import '../services/intonation_service.dart';
import '../widgets/tuner_gauge_widget.dart';
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
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _initPitchListener();
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
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.tune_rounded, size: 20), text: 'Chromatic Tuner'),
            Tab(icon: Icon(Icons.build_circle_outlined, size: 20), text: 'Intonation Setup'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTunerTab(),
          _buildIntonationTab(),
        ],
      ),
    );
  }

  // --- TAB 1: CHROMATIC TUNER ---
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

  // --- TAB 2: INTONATION CHECKER WIZARD ---
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
}
