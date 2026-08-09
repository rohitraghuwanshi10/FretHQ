import 'dart:async';
import 'package:flutter/material.dart';
import '../services/pitch_service.dart';
import '../services/intonation_service.dart';
import '../widgets/tuner_gauge_widget.dart';

class TunerScreen extends StatefulWidget {
  final int initialTabIndex;

  const TunerScreen({
    super.key,
    this.initialTabIndex = 0,
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
    final success = await _pitchService.startListening();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission required for Guitar Tuner & Intonation Checker.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    _pitchSubscription = _pitchService.pitchStream.listen((note) {
      if (!mounted) return;
      setState(() {
        _currentNote = note;
      });

      // Auto capture frequencies for Intonation Wizard if active note is detected
      _processIntonationCapture(note);
    });
  }

  void _processIntonationCapture(TunerNote note) {
    if (note.detectedFrequency <= 40) return;

    if (_intonationStep == 1 && _openFreqCaptured == null) {
      // Capture open string note
      setState(() {
        _openFreqCaptured = note.detectedFrequency;
        _intonationStep = 2;
      });
    } else if (_intonationStep == 2 && _openFreqCaptured != null && _fret12FreqCaptured == null) {
      // Capture 12th fret note (only if frequency is higher than open note)
      if (note.detectedFrequency > _openFreqCaptured! * 1.5) {
        setState(() {
          _fret12FreqCaptured = note.detectedFrequency;
          _intonationService.recordResult(
            stringNumber: _selectedIntonationString,
            openFreq: _openFreqCaptured!,
            fret12Freq: _fret12FreqCaptured!,
          );
        });
      }
    }
  }

  void _resetIntonationStep() {
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
      backgroundColor: const Color(0xFF121216),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Guitar Tools',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.tune, size: 20), text: 'Chromatic Tuner'),
            Tab(icon: Icon(Icons.build_circle_outlined, size: 20), text: 'Intonation Checker'),
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
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Tuner Analog Gauge Widget
          TunerGaugeWidget(currentNote: _currentNote),

          const SizedBox(height: 28),

          // Standard Guitar Tuning References Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.music_note, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'STANDARD GUITAR STRINGS (E A D G B E)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStringRefChip('6: Low E', 'E2 (82.4 Hz)', _currentNote?.noteName == 'E' && _currentNote?.octave == 2),
                    _buildStringRefChip('5: A', 'A2 (110 Hz)', _currentNote?.noteName == 'A' && _currentNote?.octave == 2),
                    _buildStringRefChip('4: D', 'D3 (146.8 Hz)', _currentNote?.noteName == 'D' && _currentNote?.octave == 3),
                    _buildStringRefChip('3: G', 'G3 (196 Hz)', _currentNote?.noteName == 'G' && _currentNote?.octave == 3),
                    _buildStringRefChip('2: B', 'B3 (246.9 Hz)', _currentNote?.noteName == 'B' && _currentNote?.octave == 3),
                    _buildStringRefChip('1: High E', 'E4 (329.6 Hz)', _currentNote?.noteName == 'E' && _currentNote?.octave == 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStringRefChip(String stringLabel, String target, bool isActive) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.amber : const Color(0xFF141220),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? Colors.amber : Colors.white12),
          ),
          child: Text(
            stringLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          target,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // --- TAB 2: INTONATION CHECKER ---
  Widget _buildIntonationTab() {
    final activeResult = _intonationService.getResult(_selectedIntonationString);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Intonation setup ensures notes stay in tune all the way up the neck by comparing Open String pitch vs 12th Fret pitch.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade300, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // String Selector
          const Text(
            'SELECT STRING TO CHECK',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Row(
            children: IntonationService.stringDefs.map((s) {
              final num = s['num'] as int;
              final name = s['name'] as String;
              final isSelected = _selectedIntonationString == num;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIntonationString = num;
                        _resetIntonationStep();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber : const Color(0xFF1E1E28),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.amber : Colors.white12),
                      ),
                      child: Center(
                        child: Text(
                          '$num: $name',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.grey.shade300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Guided Step Wizard Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STEP $_intonationStep OF 2',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 1.0),
                    ),
                    TextButton.icon(
                      onPressed: _resetIntonationStep,
                      icon: const Icon(Icons.refresh, size: 14, color: Colors.amber),
                      label: const Text('RESTART', style: TextStyle(fontSize: 11, color: Colors.amber)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_intonationStep == 1) ...[
                  const Text(
                    '1. Pluck the OPEN String',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let the string ring clearly into your microphone until frequency is captured.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  _buildCapturedBox('Open String Pitch', _openFreqCaptured),
                ] else ...[
                  const Text(
                    '2. Pluck the 12TH FRET (Pressed Note)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fret and pluck the 12th fret note on this string to measure octave pitch.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildCapturedBox('Open Pitch', _openFreqCaptured)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildCapturedBox('12th Fret Pitch', _fret12FreqCaptured)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Intonation Evaluation & Saddle Adjustment Recommendation
          if (activeResult != null && activeResult.status != IntonationStatus.incomplete) ...[
            const Text(
              'INTONATION EVALUATION & RECOMMENDATION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1.0),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: activeResult.status == IntonationStatus.ideal
                    ? Colors.greenAccent.withValues(alpha: 0.15)
                    : (activeResult.status == IntonationStatus.sharp
                        ? Colors.redAccent.withValues(alpha: 0.15)
                        : Colors.cyanAccent.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: activeResult.status == IntonationStatus.ideal
                      ? Colors.greenAccent
                      : (activeResult.status == IntonationStatus.sharp ? Colors.redAccent : Colors.cyanAccent),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        activeResult.status == IntonationStatus.ideal
                            ? Icons.check_circle
                            : (activeResult.status == IntonationStatus.sharp ? Icons.arrow_upward : Icons.arrow_downward),
                        color: activeResult.status == IntonationStatus.ideal
                            ? Colors.greenAccent
                            : (activeResult.status == IntonationStatus.sharp ? Colors.redAccent : Colors.cyanAccent),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activeResult.status == IntonationStatus.ideal
                            ? 'PERFECT INTONATION'
                            : (activeResult.status == IntonationStatus.sharp ? 'SHARP INTONATION' : 'FLAT INTONATION'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: activeResult.status == IntonationStatus.ideal
                              ? Colors.greenAccent
                              : (activeResult.status == IntonationStatus.sharp ? Colors.redAccent : Colors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    activeResult.saddleRecommendation,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapturedBox(String title, double? freq) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141220),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: freq != null ? Colors.greenAccent : Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          Text(
            freq != null ? '${freq.toStringAsFixed(1)} Hz' : 'Listening...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: freq != null ? Colors.greenAccent : Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}
