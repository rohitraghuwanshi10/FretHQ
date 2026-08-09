import 'package:flutter/material.dart';
import '../models/note.dart';

class FretboardWidget extends StatelessWidget {
  final TargetPosition? targetPosition;
  final int maxFret;
  final Color flashColor;

  const FretboardWidget({
    super.key,
    required this.targetPosition,
    this.maxFret = 12,
    this.flashColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24), // Dark rosewood/slate background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 170,
          width: double.infinity,
          child: CustomPaint(
            painter: _FretboardPainter(
              targetPosition: targetPosition,
              maxFret: maxFret,
              flashColor: flashColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _FretboardPainter extends CustomPainter {
  final TargetPosition? targetPosition;
  final int maxFret;
  final Color flashColor;

  _FretboardPainter({
    required this.targetPosition,
    required this.maxFret,
    required this.flashColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 45.0; // Space for open string / nut / labels
    const rightMargin = 16.0;
    const topMargin = 25.0;
    const bottomMargin = 25.0;

    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;

    // Draw fretboard wood neck background
    final neckRect = Rect.fromLTWH(leftMargin, topMargin, fretboardWidth, fretboardHeight);
    final neckPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2A2321), Color(0xFF1A1412)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(neckRect);
    canvas.drawRect(neckRect, neckPaint);

    // Flash animation layer if user just answered
    if (flashColor != Colors.transparent) {
      final flashPaint = Paint()..color = flashColor.withValues(alpha: 0.25);
      canvas.drawRect(neckRect, flashPaint);
    }

    // Fret width calculation (12 frets)
    final numFrets = maxFret;
    final fretSpacing = fretboardWidth / numFrets;

    // Draw Inlay Dot Markers (Frets 3, 5, 7, 9, 12)
    final dotPaint = Paint()..color = const Color(0xFFD4C5B9).withValues(alpha: 0.6);
    final inlayFrets = [3, 5, 7, 9, 12];

    for (var f in inlayFrets) {
      if (f <= numFrets) {
        final centerX = leftMargin + (f - 0.5) * fretSpacing;
        final centerY = topMargin + fretboardHeight / 2;

        if (f == 12) {
          // Double dots on fret 12
          canvas.drawCircle(Offset(centerX, topMargin + fretboardHeight * 0.28), 4, dotPaint);
          canvas.drawCircle(Offset(centerX, topMargin + fretboardHeight * 0.72), 4, dotPaint);
        } else {
          canvas.drawCircle(Offset(centerX, centerY), 4.5, dotPaint);
        }
      }
    }

    // Draw Nut (Fret 0 divider)
    final nutPaint = Paint()
      ..color = const Color(0xFFE8E0D5)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(leftMargin, topMargin),
      Offset(leftMargin, topMargin + fretboardHeight),
      nutPaint,
    );

    // Draw Vertical Frets (Fret 1 to maxFret)
    final fretWirePaint = Paint()
      ..color = const Color(0xFFB0B5BC)
      ..strokeWidth = 2.0;
    final fretTextPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int f = 0; f <= numFrets; f++) {
      final fretX = leftMargin + f * fretSpacing;
      if (f > 0) {
        canvas.drawLine(
          Offset(fretX, topMargin),
          Offset(fretX, topMargin + fretboardHeight),
          fretWirePaint,
        );
      }

      // Fret numbers along bottom
      fretTextPainter.text = TextSpan(
        text: '$f',
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      fretTextPainter.layout();
      final labelX = f == 0 ? leftMargin - 15 : leftMargin + (f - 0.5) * fretSpacing - fretTextPainter.width / 2;
      fretTextPainter.paint(
        canvas,
        Offset(labelX, topMargin + fretboardHeight + 6),
      );
    }

    // Draw 6 Strings (String 1 = High E at top, String 6 = Low E at bottom)
    const numStrings = 6;
    final stringSpacing = fretboardHeight / (numStrings - 1);
    final stringNames = ['E', 'B', 'G', 'D', 'A', 'E'];
    final stringGauges = [1.2, 1.6, 2.0, 2.6, 3.2, 4.0]; // Visual thickness from High E to Low E

    for (int i = 0; i < numStrings; i++) {
      final stringY = topMargin + i * stringSpacing;
      final gauge = stringGauges[i];

      final stringPaint = Paint()
        ..color = const Color(0xFFD1D5DB)
        ..strokeWidth = gauge;

      // Draw horizontal string line from Nut to end
      canvas.drawLine(
        Offset(leftMargin, stringY),
        Offset(leftMargin + fretboardWidth, stringY),
        stringPaint,
      );

      // String Label on left margin
      final stringNum = i + 1; // 1 to 6
      final isTargetString = targetPosition?.stringNumber == stringNum;

      final labelTextPainter = TextPainter(
        text: TextSpan(
          text: stringNames[i],
          style: TextStyle(
            color: isTargetString ? Colors.amberAccent : Colors.grey.shade400,
            fontSize: 12,
            fontWeight: isTargetString ? FontWeight.bold : FontWeight.normal,
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

    // Draw Highlight Pulse Ring on Target String & Fret
    if (targetPosition != null) {
      final targetStrIdx = targetPosition!.stringNumber - 1; // 0 to 5
      final targetFret = targetPosition!.fretNumber;

      final targetY = topMargin + targetStrIdx * stringSpacing;
      final targetX = targetFret == 0
          ? leftMargin - 8 // Open string indicator at nut
          : leftMargin + (targetFret - 0.5) * fretSpacing;

      // Glowing outer halo
      final glowPaint = Paint()
        ..color = Colors.amberAccent.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(targetX, targetY), 16, glowPaint);

      // Solid target badge ring
      final targetBadgePaint = Paint()
        ..color = Colors.amberAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(targetX, targetY), 11, targetBadgePaint);

      // Center core
      final corePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(targetX, targetY), 4, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FretboardPainter oldDelegate) {
    return oldDelegate.targetPosition != targetPosition ||
        oldDelegate.maxFret != maxFret ||
        oldDelegate.flashColor != flashColor;
  }
}
