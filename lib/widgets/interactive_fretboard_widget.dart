import 'package:flutter/material.dart';
import '../models/note.dart';

class InteractiveFretboardWidget extends StatelessWidget {
  final int maxFret;
  final TargetPosition? selectedPosition;
  final Color flashColor;
  final void Function(int stringNumber, int fretNumber) onFretTapped;

  const InteractiveFretboardWidget({
    super.key,
    required this.onFretTapped,
    this.selectedPosition,
    this.maxFret = 12,
    this.flashColor = Colors.transparent,
  });

  void _handleTap(BuildContext context, TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;
    final Offset localPos = details.localPosition;

    const leftMargin = 45.0;
    const rightMargin = 16.0;
    const topMargin = 25.0;
    const bottomMargin = 25.0;

    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;

    if (fretboardWidth <= 0 || fretboardHeight <= 0) return;

    final stringSpacing = fretboardHeight / 5.0;
    final fretSpacing = fretboardWidth / maxFret;

    final stringIdx = ((localPos.dy - topMargin) / stringSpacing).round().clamp(0, 5);
    final stringNumber = stringIdx + 1; // 1 to 6

    int fretNumber;
    if (localPos.dx < leftMargin) {
      fretNumber = 0; // Open string
    } else {
      fretNumber = (((localPos.dx - leftMargin) / fretSpacing).floor() + 1).clamp(1, maxFret);
    }

    onFretTapped(stringNumber, fretNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
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
          height: 180,
          width: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _handleTap(context, details),
            child: CustomPaint(
              painter: _InteractiveFretboardPainter(
                selectedPosition: selectedPosition,
                maxFret: maxFret,
                flashColor: flashColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveFretboardPainter extends CustomPainter {
  final TargetPosition? selectedPosition;
  final int maxFret;
  final Color flashColor;

  _InteractiveFretboardPainter({
    required this.selectedPosition,
    required this.maxFret,
    required this.flashColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 45.0;
    const rightMargin = 16.0;
    const topMargin = 25.0;
    const bottomMargin = 25.0;

    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;

    // Draw fretboard neck background
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
      final flashPaint = Paint()..color = flashColor.withValues(alpha: 0.28);
      canvas.drawRect(neckRect, flashPaint);
    }

    final numFrets = maxFret;
    final fretSpacing = fretboardWidth / numFrets;

    // Inlay Dot Markers (Frets 3, 5, 7, 9, 12)
    final dotPaint = Paint()..color = const Color(0xFFD4C5B9).withValues(alpha: 0.6);
    final inlayFrets = [3, 5, 7, 9, 12];

    for (var f in inlayFrets) {
      if (f <= numFrets) {
        final centerX = leftMargin + (f - 0.5) * fretSpacing;
        final centerY = topMargin + fretboardHeight / 2;

        if (f == 12) {
          canvas.drawCircle(Offset(centerX, topMargin + fretboardHeight * 0.28), 4, dotPaint);
          canvas.drawCircle(Offset(centerX, topMargin + fretboardHeight * 0.72), 4, dotPaint);
        } else {
          canvas.drawCircle(Offset(centerX, centerY), 4.5, dotPaint);
        }
      }
    }

    // Nut (Fret 0 divider)
    final nutPaint = Paint()
      ..color = const Color(0xFFE8E0D5)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(leftMargin, topMargin),
      Offset(leftMargin, topMargin + fretboardHeight),
      nutPaint,
    );

    // Vertical Fret Wires & Labels
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

    // 6 Strings (String 1 = High E, String 6 = Low E)
    const numStrings = 6;
    final stringSpacing = fretboardHeight / (numStrings - 1);
    final stringNames = ['E', 'B', 'G', 'D', 'A', 'E'];
    final stringGauges = [1.2, 1.6, 2.0, 2.6, 3.2, 4.0];

    for (int i = 0; i < numStrings; i++) {
      final stringY = topMargin + i * stringSpacing;
      final gauge = stringGauges[i];

      final stringPaint = Paint()
        ..color = const Color(0xFFD1D5DB)
        ..strokeWidth = gauge;

      canvas.drawLine(
        Offset(leftMargin, stringY),
        Offset(leftMargin + fretboardWidth, stringY),
        stringPaint,
      );

      final labelTextPainter = TextPainter(
        text: TextSpan(
          text: stringNames[i],
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 12,
            fontWeight: FontWeight.bold,
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

    // Highlight user selected / tapped position marker
    if (selectedPosition != null) {
      final strIdx = selectedPosition!.stringNumber - 1;
      final fret = selectedPosition!.fretNumber;

      final targetY = topMargin + strIdx * stringSpacing;
      final targetX = fret == 0
          ? leftMargin - 8
          : leftMargin + (fret - 0.5) * fretSpacing;

      final badgeColor = flashColor != Colors.transparent ? flashColor : Colors.amberAccent;

      final glowPaint = Paint()
        ..color = badgeColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(targetX, targetY), 16, glowPaint);

      final badgePaint = Paint()
        ..color = badgeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(targetX, targetY), 11, badgePaint);

      final corePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(targetX, targetY), 4, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveFretboardPainter oldDelegate) {
    return oldDelegate.selectedPosition != selectedPosition ||
        oldDelegate.maxFret != maxFret ||
        oldDelegate.flashColor != flashColor;
  }
}
