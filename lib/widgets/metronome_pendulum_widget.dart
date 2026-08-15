import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/metronome_pattern.dart';
import '../services/metronome_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class MetronomePendulumWidget extends StatefulWidget {
  final MetronomeService metronomeService;

  const MetronomePendulumWidget({
    super.key,
    required this.metronomeService,
  });

  @override
  State<MetronomePendulumWidget> createState() => _MetronomePendulumWidgetState();
}

class _MetronomePendulumWidgetState extends State<MetronomePendulumWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pendulumAnimController;
  StreamSubscription<MetronomeTickEvent>? _tickSubscription;
  StreamSubscription<int?>? _timerSubscription;

  int _activeBeat = -1;
  int _activeSubdivision = -1;
  BeatAccent _activeAccent = BeatAccent.normal;
  int? _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _subscribeToTicks();
    _remainingSeconds = widget.metronomeService.timerDurationSeconds != null
        ? widget.metronomeService.remainingSeconds
        : null;
  }

  void _initAnimation() {
    final bpm = widget.metronomeService.bpm;
    final periodMs = (60000.0 / bpm).round();

    _pendulumAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: periodMs),
    );

    if (widget.metronomeService.isPlaying) {
      _pendulumAnimController.repeat(reverse: true);
    }
  }

  void _subscribeToTicks() {
    _tickSubscription = widget.metronomeService.tickStream.listen((event) {
      if (!mounted) return;
      setState(() {
        _activeBeat = event.beatIndex;
        _activeSubdivision = event.subdivisionIndex;
        _activeAccent = event.accent;
      });

      // Synchronize pendulum duration if BPM changed
      final periodMs = (60000.0 / event.bpm).round();
      if (_pendulumAnimController.duration?.inMilliseconds != periodMs) {
        _pendulumAnimController.duration = Duration(milliseconds: periodMs);
      }

      if (!_pendulumAnimController.isAnimating && widget.metronomeService.isPlaying) {
        _pendulumAnimController.repeat(reverse: true);
      }
    });

    _timerSubscription = widget.metronomeService.timerStream.listen((seconds) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds = seconds;
      });
    });
  }

  @override
  void didUpdateWidget(covariant MetronomePendulumWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.metronomeService.isPlaying && _pendulumAnimController.isAnimating) {
      _pendulumAnimController.stop();
      _pendulumAnimController.value = 0.5; // Center position
      setState(() {
        _activeBeat = -1;
        _activeSubdivision = -1;
      });
    } else if (widget.metronomeService.isPlaying && !_pendulumAnimController.isAnimating) {
      final periodMs = (60000.0 / widget.metronomeService.bpm).round();
      _pendulumAnimController.duration = Duration(milliseconds: periodMs);
      _pendulumAnimController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _tickSubscription?.cancel();
    _timerSubscription?.cancel();
    _pendulumAnimController.dispose();
    super.dispose();
  }

  Color _getAccentColor(BeatAccent accent) {
    switch (accent) {
      case BeatAccent.strong:
        return AppColors.gold;
      case BeatAccent.medium:
        return AppColors.cyan;
      case BeatAccent.normal:
        return AppColors.emerald;
      case BeatAccent.mute:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bpm = widget.metronomeService.bpm;
    final isPlaying = widget.metronomeService.isPlaying;
    final tempoMarking = TempoMarking.getForBpm(bpm);
    final timeSig = widget.metronomeService.timeSignature;
    final accents = widget.metronomeService.accents;

    final hasTimer = _remainingSeconds != null;
    final mins = hasTimer ? (_remainingSeconds! ~/ 60).toString().padLeft(2, '0') : '00';
    final secs = hasTimer ? (_remainingSeconds! % 60).toString().padLeft(2, '0') : '00';

    return GlassCard(
      gradient: AppColors.heroCardGradient,
      borderColor: isPlaying ? AppColors.gold.withValues(alpha: 0.5) : AppColors.borderMedium,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // 1. LED Beat Indicator Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(timeSig.beatsPerBar, (index) {
              final isCurrent = isPlaying && _activeBeat == index && _activeSubdivision == 0;
              final accent = index < accents.length ? accents[index] : BeatAccent.normal;
              final accentColor = _getAccentColor(accent);

              return GestureDetector(
                onTap: () {
                  widget.metronomeService.toggleBeatAccent(index);
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: isCurrent ? 28 : 22,
                  height: isCurrent ? 28 : 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? accentColor
                        : (accent == BeatAccent.mute
                            ? Colors.white10
                            : accentColor.withValues(alpha: 0.2)),
                    border: Border.all(
                      color: isCurrent ? Colors.white : accentColor.withValues(alpha: 0.6),
                      width: isCurrent ? 2.0 : 1.2,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.8),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: isCurrent ? 12 : 10,
                        fontWeight: FontWeight.w900,
                        color: isCurrent
                            ? Colors.black
                            : (accent == BeatAccent.mute ? Colors.white24 : Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // 2. Pendulum & Digital BPM Hero
          SizedBox(
            height: 155,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated Pendulum Canvas
                AnimatedBuilder(
                  animation: _pendulumAnimController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(double.infinity, 155),
                      painter: _PendulumPainter(
                        progress: isPlaying ? _pendulumAnimController.value : 0.5,
                        activeColor: isPlaying ? _getAccentColor(_activeAccent) : AppColors.textMuted,
                        isPlaying: isPlaying,
                      ),
                    );
                  },
                ),

                // Center BPM Digital Readout
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$bpm',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: isPlaying ? AppColors.gold : Colors.white,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'BPM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassBadge(
                          text: '${tempoMarking.italianName.toUpperCase()} • ${tempoMarking.englishDescription}',
                          color: AppColors.cyan,
                          fontSize: 9,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        ),
                        if (hasTimer) ...[
                          const SizedBox(width: 6),
                          GlassBadge(
                            text: '⏱️ $mins:$secs',
                            color: isPlaying ? AppColors.gold : AppColors.emerald,
                            fontSize: 9,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendulumPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color activeColor;
  final bool isPlaying;

  _PendulumPainter({
    required this.progress,
    required this.activeColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, 8);
    const maxAngle = pi * 0.22; // ~40 degrees swing
    final currentAngle = (progress - 0.5) * 2.0 * maxAngle;

    const armLength = 130.0;
    final bobPosition = Offset(
      pivot.dx + armLength * sin(currentAngle),
      pivot.dy + armLength * cos(currentAngle),
    );

    // Arc guide background
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: armLength),
      pi / 2 - maxAngle,
      maxAngle * 2,
      false,
      guidePaint,
    );

    // Pendulum Arm Shadow
    canvas.drawLine(
      pivot,
      bobPosition + const Offset(1, 2),
      Paint()
        ..color = Colors.black45
        ..strokeWidth = 3.0,
    );

    // Pendulum Arm (Chrome / Metallic)
    final armPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
      ).createShader(Rect.fromPoints(pivot, bobPosition))
      ..strokeWidth = 2.4;
    canvas.drawLine(pivot, bobPosition, armPaint);

    // Pivot Pin
    canvas.drawCircle(pivot, 5.0, Paint()..color = const Color(0xFF64748B));
    canvas.drawCircle(pivot, 2.5, Paint()..color = Colors.white);

    // Sliding Bob Weight
    final bobRect = Rect.fromCenter(center: bobPosition, width: 18, height: 14);
    final bobPaint = Paint()
      ..shader = LinearGradient(
        colors: isPlaying
            ? [activeColor, activeColor.withValues(alpha: 0.7)]
            : const [Color(0xFF94A3B8), Color(0xFF475569)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bobRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bobRect, const Radius.circular(4)), bobPaint);

    // Bob Glow when playing
    if (isPlaying) {
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(bobPosition, 12, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PendulumPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isPlaying != isPlaying;
  }
}
