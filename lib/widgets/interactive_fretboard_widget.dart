import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

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

    const leftMargin = 46.0;
    const rightMargin = 16.0;
    const topMargin = 26.0;
    const bottomMargin = 26.0;

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

    HapticFeedback.selectionClick();
    onFretTapped(stringNumber, fretNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141113),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 195,
          width: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _handleTap(context, details),
            child: CustomPaint(
              painter: _PhotorealisticInteractivePainter(
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

class _PhotorealisticInteractivePainter extends CustomPainter {
  final TargetPosition? selectedPosition;
  final int maxFret;
  final Color flashColor;

  _PhotorealisticInteractivePainter({
    required this.selectedPosition,
    required this.maxFret,
    required this.flashColor,
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

    // 1. Neck Background Gradient
    final neckPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF261D1A),
          Color(0xFF1B1412),
          Color(0xFF140F0E),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(neckRect);
    canvas.drawRect(neckRect, neckPaint);

    // Grain
    final grainPaint = Paint()
      ..color = const Color(0xFF382A24).withValues(alpha: 0.25)
      ..strokeWidth = 1.0;
    for (double y = topMargin + 4; y < topMargin + fretboardHeight; y += 6) {
      canvas.drawLine(Offset(leftMargin, y), Offset(leftMargin + fretboardWidth, y), grainPaint);
    }

    // Edge Binding
    final bindingPaint = Paint()
      ..color = const Color(0xFFE5DECF)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(leftMargin, topMargin), Offset(leftMargin + fretboardWidth, topMargin), bindingPaint);
    canvas.drawLine(
      Offset(leftMargin, topMargin + fretboardHeight),
      Offset(leftMargin + fretboardWidth, topMargin + fretboardHeight),
      bindingPaint,
    );

    // Flash feedback
    if (flashColor != Colors.transparent) {
      final flashPaint = Paint()..color = flashColor.withValues(alpha: 0.35);
      canvas.drawRect(neckRect, flashPaint);
    }

    final fretSpacing = fretboardWidth / maxFret;

    // Inlay Dots
    final inlayFrets = [3, 5, 7, 9, 12];
    for (var f in inlayFrets) {
      if (f <= maxFret) {
        final centerX = leftMargin + (f - 0.5) * fretSpacing;
        final centerY = topMargin + fretboardHeight / 2;

        if (f == 12) {
          _drawInlay(canvas, Offset(centerX, topMargin + fretboardHeight * 0.28), 4.5);
          _drawInlay(canvas, Offset(centerX, topMargin + fretboardHeight * 0.72), 4.5);
        } else {
          _drawInlay(canvas, Offset(centerX, centerY), 5.0);
        }
      }
    }

    // Bone Nut (Fret 0)
    final nutRect = Rect.fromLTWH(leftMargin - 6, topMargin - 1, 6, fretboardHeight + 2);
    final nutPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFAF7F0), Color(0xFFE0D8C3), Color(0xFFB5AC98)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(nutRect);
    canvas.drawRRect(RRect.fromRectAndRadius(nutRect, const Radius.circular(2)), nutPaint);

    // Frets
    final fretTextPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int f = 0; f <= maxFret; f++) {
      final fretX = leftMargin + f * fretSpacing;
      if (f > 0) {
        // Shadow
        canvas.drawLine(
          Offset(fretX - 1.0, topMargin),
          Offset(fretX - 1.0, topMargin + fretboardHeight),
          Paint()
            ..color = Colors.black87
            ..strokeWidth = 1.0,
        );
        // Nickel wire
        canvas.drawLine(
          Offset(fretX, topMargin),
          Offset(fretX, topMargin + fretboardHeight),
          Paint()
            ..color = const Color(0xFFB2B8C2)
            ..strokeWidth = 2.4,
        );
        // Crown shine
        canvas.drawLine(
          Offset(fretX, topMargin),
          Offset(fretX, topMargin + fretboardHeight),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..strokeWidth = 0.8,
        );
      }

      fretTextPainter.text = TextSpan(
        text: '$f',
        style: TextStyle(
          color: (f == 3 || f == 5 || f == 7 || f == 9 || f == 12) ? AppColors.cyan : Colors.grey.shade400,
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

    // 6 Strings
    const numStrings = 6;
    final stringSpacing = fretboardHeight / (numStrings - 1);
    final stringNames = ['E', 'B', 'G', 'D', 'A', 'E'];
    final stringGauges = [1.2, 1.6, 2.0, 2.8, 3.6, 4.4];
    final isWound = [false, false, false, true, true, true];

    for (int i = 0; i < numStrings; i++) {
      final stringY = topMargin + i * stringSpacing;
      final gauge = stringGauges[i];
      final wound = isWound[i];

      // String Shadow
      canvas.drawLine(
        Offset(leftMargin - 6, stringY + 1.2),
        Offset(leftMargin + fretboardWidth, stringY + 1.2),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.6)
          ..strokeWidth = gauge,
      );

      // Core
      final stringPaint = Paint()
        ..color = wound ? const Color(0xFFC49F74) : const Color(0xFFD3D7DF)
        ..strokeWidth = gauge;
      canvas.drawLine(
        Offset(leftMargin - 6, stringY),
        Offset(leftMargin + fretboardWidth, stringY),
        stringPaint,
      );

      // Shine
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..strokeWidth = min(1.0, gauge * 0.4);
      canvas.drawLine(
        Offset(leftMargin - 6, stringY - gauge * 0.2),
        Offset(leftMargin + fretboardWidth, stringY - gauge * 0.2),
        shinePaint,
      );

      // Label
      final labelTextPainter = TextPainter(
        text: TextSpan(
          text: stringNames[i],
          style: const TextStyle(
            color: Colors.grey,
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

    // Selected Tap Marker
    if (selectedPosition != null) {
      final strIdx = selectedPosition!.stringNumber - 1;
      final fret = selectedPosition!.fretNumber;

      final targetY = topMargin + strIdx * stringSpacing;
      final targetX = fret == 0
          ? leftMargin - 10
          : leftMargin + (fret - 0.5) * fretSpacing;

      final badgeColor = flashColor != Colors.transparent ? flashColor : AppColors.cyan;

      // Glow
      final glowPaint = Paint()
        ..color = badgeColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(targetX, targetY), 18, glowPaint);

      // Badge
      final badgePaint = Paint()
        ..color = badgeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(targetX, targetY), 13, badgePaint);

      // Center Note Name or Dot
      final userNote = selectedPosition!.targetNote;
      final notePainter = TextPainter(
        text: TextSpan(
          text: userNote.id,
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
    }
  }

  void _drawInlay(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius + 0.5, Paint()..color = Colors.black54);
    final inlayRect = Rect.fromCircle(center: center, radius: radius);
    final inlayPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFFFFF), Color(0xFFE6DEC8), Color(0xFFC7BBA6)],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(inlayRect);
    canvas.drawCircle(center, radius, inlayPaint);
  }

  @override
  bool shouldRepaint(covariant _PhotorealisticInteractivePainter oldDelegate) {
    return oldDelegate.selectedPosition != selectedPosition ||
        oldDelegate.maxFret != maxFret ||
        oldDelegate.flashColor != flashColor;
  }
}
