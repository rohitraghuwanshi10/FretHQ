import 'dart:math';
import 'package:flutter/material.dart';
import '../services/pitch_service.dart';

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
      stateColor = Colors.grey.shade600;
    } else if (isInTune) {
      stateColor = Colors.greenAccent;
    } else if (cents < 0) {
      stateColor = Colors.cyanAccent;
    } else {
      stateColor = Colors.redAccent;
    }

    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1926),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stateColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gauge Arc & Animated Needle
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _GaugePainter(
                centsOffset: cents,
                stateColor: stateColor,
                isInTune: isInTune,
              ),
            ),
          ),

          const SizedBox(height: 8),

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
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: stateColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${note.detectedFrequency.toStringAsFixed(1)} Hz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
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
                      fontWeight: FontWeight.bold,
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
                fontWeight: FontWeight.bold,
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Listening via MacBook Microphone...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double centsOffset; // -50 to +50
  final Color stateColor;
  final bool isInTune;

  _GaugePainter({
    required this.centsOffset,
    required this.stateColor,
    required this.isInTune,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.height * 0.72;

    const startAngle = -pi * 0.75; // -135 deg
    const totalAngle = pi * 0.5; // 90 deg range

    // Draw Arc Background
    final arcPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle,
      false,
      arcPaint,
    );

    // Draw In-Tune Center Zone Halo
    final centerZonePaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.3)
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

    // Draw Ticks & Labels (-50 to +50)
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

      tickPaint.color = isZero ? Colors.greenAccent : (isMajor ? Colors.white60 : Colors.white24);
      tickPaint.strokeWidth = isZero ? 3.0 : (isMajor ? 2.0 : 1.0);

      canvas.drawLine(p1, p2, tickPaint);

      if (isMajor) {
        final labelText = cent == 0 ? '0' : (cent > 0 ? '+$cent' : '$cent');
        textPainter.text = TextSpan(
          text: labelText,
          style: TextStyle(
            color: isZero ? Colors.greenAccent : Colors.grey.shade500,
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

    // Draw Animated Needle
    final needleRatio = (centsOffset.clamp(-50.0, 50.0) + 50) / 100.0;
    final needleAngle = startAngle + needleRatio * totalAngle;

    final needleLength = radius - 10;
    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    // Glow halo under needle
    final glowPaint = Paint()
      ..color = stateColor.withValues(alpha: 0.4)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(center, needleEnd, glowPaint);

    // Solid Needle line
    final needlePaint = Paint()
      ..color = stateColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    // Needle pivot hub
    final hubPaint = Paint()..color = stateColor;
    canvas.drawCircle(center, 7, hubPaint);
    final innerHubPaint = Paint()..color = Colors.black;
    canvas.drawCircle(center, 3, innerHubPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.centsOffset != centsOffset ||
        oldDelegate.stateColor != stateColor ||
        oldDelegate.isInTune != isInTune;
  }
}
