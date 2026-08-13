import 'dart:math';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class FretboardWidget extends StatefulWidget {
  final TargetPosition? targetPosition;
  final int maxFret;
  final Color flashColor;
  final bool showNoteName;

  const FretboardWidget({
    super.key,
    required this.targetPosition,
    this.maxFret = 12,
    this.flashColor = Colors.transparent,
    this.showNoteName = false,
  });

  @override
  State<FretboardWidget> createState() => _FretboardWidgetState();
}

class _FretboardWidgetState extends State<FretboardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141113),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 185,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: _PhotorealisticFretboardPainter(
                  targetPosition: widget.targetPosition,
                  maxFret: widget.maxFret,
                  flashColor: widget.flashColor,
                  pulseValue: _pulseAnimation.value,
                  showNoteName: widget.showNoteName,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PhotorealisticFretboardPainter extends CustomPainter {
  final TargetPosition? targetPosition;
  final int maxFret;
  final Color flashColor;
  final double pulseValue;
  final bool showNoteName;

  _PhotorealisticFretboardPainter({
    required this.targetPosition,
    required this.maxFret,
    required this.flashColor,
    required this.pulseValue,
    required this.showNoteName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 46.0;
    const rightMargin = 16.0;
    const topMargin = 26.0;
    const bottomMargin = 26.0;

    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;

    final neckRect = Rect.fromLTWH(leftMargin, topMargin, fretboardWidth, fretboardHeight);

    // 1. Draw Rosewood / Dark Ebony Neck Background Gradient
    final neckPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF261D1A), // Dark rich rosewood top
          Color(0xFF1B1412), // Deep espresso center
          Color(0xFF140F0E), // Bottom shadow
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(neckRect);
    canvas.drawRect(neckRect, neckPaint);

    // Subtle Wood Grain horizontal lines
    final grainPaint = Paint()
      ..color = const Color(0xFF382A24).withValues(alpha: 0.25)
      ..strokeWidth = 1.0;
    for (double y = topMargin + 4; y < topMargin + fretboardHeight; y += 6) {
      canvas.drawLine(Offset(leftMargin, y), Offset(leftMargin + fretboardWidth, y), grainPaint);
    }

    // 2. Fretboard Cream Edge Bindings (Top & Bottom edges)
    final bindingPaint = Paint()
      ..color = const Color(0xFFE5DECF)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(leftMargin, topMargin), Offset(leftMargin + fretboardWidth, topMargin), bindingPaint);
    canvas.drawLine(
      Offset(leftMargin, topMargin + fretboardHeight),
      Offset(leftMargin + fretboardWidth, topMargin + fretboardHeight),
      bindingPaint,
    );

    // 3. Flash feedback layer on answer
    if (flashColor != Colors.transparent) {
      final flashPaint = Paint()..color = flashColor.withValues(alpha: 0.3);
      canvas.drawRect(neckRect, flashPaint);
    }

    final fretSpacing = fretboardWidth / maxFret;

    // 4. Draw Pearloid / Mother-of-Pearl Inlay Position Markers (Frets 3, 5, 7, 9, 12)
    final inlayFrets = [3, 5, 7, 9, 12];
    for (var f in inlayFrets) {
      if (f <= maxFret) {
        final centerX = leftMargin + (f - 0.5) * fretSpacing;
        final centerY = topMargin + fretboardHeight / 2;

        if (f == 12) {
          // Double dots on 12th fret
          _drawPearloidInlay(canvas, Offset(centerX, topMargin + fretboardHeight * 0.28), 4.5);
          _drawPearloidInlay(canvas, Offset(centerX, topMargin + fretboardHeight * 0.72), 4.5);
        } else {
          _drawPearloidInlay(canvas, Offset(centerX, centerY), 5.0);
        }
      }
    }

    // 5. Draw Bone Nut (Fret 0 divider)
    final nutRect = Rect.fromLTWH(leftMargin - 6, topMargin - 1, 6, fretboardHeight + 2);
    final nutPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFAF7F0), Color(0xFFE0D8C3), Color(0xFFB5AC98)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(nutRect);
    canvas.drawRRect(RRect.fromRectAndRadius(nutRect, const Radius.circular(2)), nutPaint);

    // 6. Draw 3D Nickel-Silver Frets (Frets 1 to maxFret)
    final fretTextPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int f = 0; f <= maxFret; f++) {
      final fretX = leftMargin + f * fretSpacing;

      if (f > 0) {
        // Shadow behind fret wire
        canvas.drawLine(
          Offset(fretX - 1.0, topMargin),
          Offset(fretX - 1.0, topMargin + fretboardHeight),
          Paint()
            ..color = Colors.black87
            ..strokeWidth = 1.0,
        );

        // Nickel fret body
        canvas.drawLine(
          Offset(fretX, topMargin),
          Offset(fretX, topMargin + fretboardHeight),
          Paint()
            ..color = const Color(0xFFB2B8C2)
            ..strokeWidth = 2.4,
        );

        // Metallic reflection crown highlight
        canvas.drawLine(
          Offset(fretX, topMargin),
          Offset(fretX, topMargin + fretboardHeight),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..strokeWidth = 0.8,
        );
      }

      // Fret numbers label along bottom
      fretTextPainter.text = TextSpan(
        text: '$f',
        style: TextStyle(
          color: (f == 3 || f == 5 || f == 7 || f == 9 || f == 12) ? AppColors.gold : Colors.grey.shade400,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      );
      fretTextPainter.layout();
      final labelX = f == 0 ? leftMargin - 16 : leftMargin + (f - 0.5) * fretSpacing - fretTextPainter.width / 2;
      fretTextPainter.paint(
        canvas,
        Offset(labelX, topMargin + fretboardHeight + 6),
      );
    }

    // 7. Draw 6 Realistic Guitar Strings
    const numStrings = 6;
    final stringSpacing = fretboardHeight / (numStrings - 1);
    final stringNames = ['E', 'B', 'G', 'D', 'A', 'E'];

    // String Gauges: 1 (High E) is thin steel, 6 (Low E) is thick wound bronze
    final stringGauges = [1.2, 1.6, 2.0, 2.8, 3.6, 4.4];
    final isWound = [false, false, false, true, true, true];

    for (int i = 0; i < numStrings; i++) {
      final stringY = topMargin + i * stringSpacing;
      final gauge = stringGauges[i];
      final wound = isWound[i];
      final stringNum = i + 1; // 1 to 6
      final isTargetString = targetPosition?.stringNumber == stringNum;

      // String Shadow
      canvas.drawLine(
        Offset(leftMargin - 6, stringY + 1.2),
        Offset(leftMargin + fretboardWidth, stringY + 1.2),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.6)
          ..strokeWidth = gauge,
      );

      // String Base Core
      final stringPaint = Paint()
        ..color = wound ? const Color(0xFFC49F74) : const Color(0xFFD3D7DF)
        ..strokeWidth = gauge;
      canvas.drawLine(
        Offset(leftMargin - 6, stringY),
        Offset(leftMargin + fretboardWidth, stringY),
        stringPaint,
      );

      // Metallic Top Shine Highlight
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..strokeWidth = min(1.0, gauge * 0.4);
      canvas.drawLine(
        Offset(leftMargin - 6, stringY - gauge * 0.2),
        Offset(leftMargin + fretboardWidth, stringY - gauge * 0.2),
        shinePaint,
      );

      // String Name Label on Left Margin
      final labelTextPainter = TextPainter(
        text: TextSpan(
          text: stringNames[i],
          style: TextStyle(
            color: isTargetString ? AppColors.gold : Colors.grey.shade400,
            fontSize: 12,
            fontWeight: isTargetString ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelTextPainter.layout();
      labelTextPainter.paint(
        canvas,
        Offset(12, stringY - labelTextPainter.height / 2),
      );
    }

    // 8. Draw Target Position Highlight & Pulse Waves
    if (targetPosition != null) {
      final targetStrIdx = targetPosition!.stringNumber - 1; // 0 to 5
      final targetFret = targetPosition!.fretNumber;

      final targetY = topMargin + targetStrIdx * stringSpacing;
      final targetX = targetFret == 0
          ? leftMargin - 10
          : leftMargin + (targetFret - 0.5) * fretSpacing;

      final targetColor = flashColor != Colors.transparent ? flashColor : AppColors.gold;

      // Pulsing outer ripple halo
      final rippleRadius = 14.0 + (pulseValue * 8.0);
      final ripplePaint = Paint()
        ..color = targetColor.withValues(alpha: (1.0 - pulseValue) * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(targetX, targetY), rippleRadius, ripplePaint);

      // Ambient Glow
      final glowPaint = Paint()
        ..color = targetColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(targetX, targetY), 16, glowPaint);

      // Solid Target Badge Ring
      final badgePaint = Paint()
        ..color = targetColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(targetX, targetY), 12, badgePaint);

      // Inner Core or Note Name Text
      if (showNoteName) {
        final note = targetPosition!.targetNote;
        final notePainter = TextPainter(
          text: TextSpan(
            text: note.id,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        notePainter.layout();
        notePainter.paint(
          canvas,
          Offset(targetX - notePainter.width / 2, targetY - notePainter.height / 2),
        );
      } else {
        final corePaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(targetX, targetY), 4.5, corePaint);
      }
    }
  }

  void _drawPearloidInlay(Canvas canvas, Offset center, double radius) {
    // Outer subtle border
    canvas.drawCircle(
      center,
      radius + 0.5,
      Paint()..color = Colors.black54,
    );

    // Pearloid radial gradient
    final inlayRect = Rect.fromCircle(center: center, radius: radius);
    final inlayPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFE6DEC8),
          Color(0xFFC7BBA6),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(inlayRect);
    canvas.drawCircle(center, radius, inlayPaint);
  }

  @override
  bool shouldRepaint(covariant _PhotorealisticFretboardPainter oldDelegate) {
    return oldDelegate.targetPosition != targetPosition ||
        oldDelegate.maxFret != maxFret ||
        oldDelegate.flashColor != flashColor ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.showNoteName != showNoteName;
  }
}
