import 'dart:math';
import 'package:flutter/material.dart';
import '../services/pitch_service.dart';
import '../theme/app_theme.dart';

class TunerGaugeWidget extends StatelessWidget {
  final TunerNote? currentNote;

  const TunerGaugeWidget({
    super.key,
    required this.currentNote,
  });

  @override
  Widget build(BuildContext context) {
    final note = currentNote;
    final cents = note?.centsOffset ?? 0.0;
    final isInTune = note?.isInTune ?? false;

    Color stateColor;
    if (note == null || note.noteName == '--') {
      stateColor = AppColors.textMuted;
    } else if (isInTune) {
      stateColor = AppColors.emerald;
    } else if (cents < 0) {
      stateColor = AppColors.cyan;
    } else {
      stateColor = AppColors.coral;
    }

    return Container(
      width: double.infinity,
      height: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stateColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: stateColor.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Gauge Arc & Animated Needle
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: cents),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              builder: (context, animatedCents, child) {
                return CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: _PhotorealisticGaugePainter(
                    centsOffset: animatedCents,
                    stateColor: stateColor,
                    isInTune: isInTune,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Digital Display Readings
          if (note != null && note.noteName != '--') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  note.fullDisplay,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: stateColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${note.detectedFrequency.toStringAsFixed(1)} Hz',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: stateColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    isInTune
                        ? 'PERFECT IN TUNE'
                        : (cents < 0
                            ? 'FLAT (${cents.toStringAsFixed(1)} cents) • TUNE UP ↑'
                            : 'SHARP (+${cents.toStringAsFixed(1)} cents) • TUNE DOWN ↓'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: stateColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'PLUCK A GUITAR STRING',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white70,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Listening via device microphone...',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotorealisticGaugePainter extends CustomPainter {
  final double centsOffset;
  final Color stateColor;
  final bool isInTune;

  _PhotorealisticGaugePainter({
    required this.centsOffset,
    required this.stateColor,
    required this.isInTune,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = size.height * 0.74;

    const startAngle = -pi * 0.75; // -135 deg
    const totalAngle = pi * 0.5; // 90 deg range

    // Arc Background
    final arcPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle,
      false,
      arcPaint,
    );

    // In-Tune Center Zone Halo
    final centerZonePaint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.35)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;
    const centerZoneAngle = (5.0 / 100.0) * totalAngle;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.5 - centerZoneAngle / 2,
      centerZoneAngle,
      false,
      centerZonePaint,
    );

    // Ticks & Labels (-50 to +50)
    final tickPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.5;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int cent = -50; cent <= 50; cent += 10) {
      final ratio = (cent + 50) / 100.0;
      final angle = startAngle + ratio * totalAngle;

      final isMajor = cent % 25 == 0;
      final isZero = cent == 0;

      final innerR = isMajor ? radius - 14 : radius - 8;
      final outerR = radius;

      final p1 = Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle));
      final p2 = Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle));

      tickPaint.color = isZero ? AppColors.emerald : (isMajor ? Colors.white70 : Colors.white24);
      tickPaint.strokeWidth = isZero ? 3.0 : (isMajor ? 2.0 : 1.0);

      canvas.drawLine(p1, p2, tickPaint);

      if (isMajor) {
        final labelText = cent == 0 ? '0' : (cent > 0 ? '+$cent' : '$cent');
        textPainter.text = TextSpan(
          text: labelText,
          style: TextStyle(
            color: isZero ? AppColors.emerald : Colors.grey.shade500,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        final textPos = Offset(
          center.dx + (radius - 26) * cos(angle) - textPainter.width / 2,
          center.dy + (radius - 26) * sin(angle) - textPainter.height / 2,
        );
        textPainter.paint(canvas, textPos);
      }
    }

    // Animated Needle
    final needleRatio = (centsOffset.clamp(-50.0, 50.0) + 50) / 100.0;
    final needleAngle = startAngle + needleRatio * totalAngle;

    final needleLength = radius - 10;
    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    // Glow under needle
    final glowPaint = Paint()
      ..color = stateColor.withValues(alpha: 0.5)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(center, needleEnd, glowPaint);

    // Needle line
    final needlePaint = Paint()
      ..color = stateColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    // Hub
    final hubPaint = Paint()..color = stateColor;
    canvas.drawCircle(center, 8, hubPaint);
    final innerHubPaint = Paint()..color = Colors.black;
    canvas.drawCircle(center, 3.5, innerHubPaint);
  }

  @override
  bool shouldRepaint(covariant _PhotorealisticGaugePainter oldDelegate) {
    return oldDelegate.centsOffset != centsOffset ||
        oldDelegate.stateColor != stateColor ||
        oldDelegate.isInTune != isInTune;
  }
}
