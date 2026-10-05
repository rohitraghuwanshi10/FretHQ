import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import 'realistic_fretboard_painter.dart';

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

    const leftMargin = RealisticFretboardRenderer.defaultLeftMargin;
    const rightMargin = RealisticFretboardRenderer.defaultRightMargin;
    const topMargin = RealisticFretboardRenderer.defaultTopMargin;
    const bottomMargin = RealisticFretboardRenderer.defaultBottomMargin;

    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;

    if (fretboardWidth <= 0 || fretboardHeight <= 0) return;

    final stringSpacing = fretboardHeight / 5.0;
    final fretSpacing = fretboardWidth / maxFret;

    final stringIdx = ((localPos.dy - topMargin) / stringSpacing).round().clamp(0, 5);
    final stringNumber = stringIdx + 1; // 1 to 6

    int fretNumber;
    if (localPos.dx < leftMargin - 4) {
      fretNumber = 0; // Open string behind or on bone nut
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
        color: const Color(0xFF140F0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.08),
            blurRadius: 14,
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
    const leftMargin = RealisticFretboardRenderer.defaultLeftMargin;
    const rightMargin = RealisticFretboardRenderer.defaultRightMargin;
    const topMargin = RealisticFretboardRenderer.defaultTopMargin;
    const bottomMargin = RealisticFretboardRenderer.defaultBottomMargin;

    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;
    if (fretboardWidth <= 0 || fretboardHeight <= 0) return;

    // 1. Base photorealistic neck
    RealisticFretboardRenderer.drawFretboardBase(
      canvas: canvas,
      size: size,
      maxFret: maxFret,
      leftMargin: leftMargin,
      rightMargin: rightMargin,
      topMargin: topMargin,
      bottomMargin: bottomMargin,
      flashColor: flashColor,
      highlightedString: selectedPosition?.stringNumber,
      accentColor: AppColors.cyan,
    );

    // 2. Selected Tap Marker
    if (selectedPosition != null) {
      final targetOffset = RealisticFretboardRenderer.getPositionOffset(
        stringNumber: selectedPosition!.stringNumber,
        fretNumber: selectedPosition!.fretNumber,
        fretboardWidth: fretboardWidth,
        fretboardHeight: fretboardHeight,
        maxFret: maxFret,
        leftMargin: leftMargin,
        topMargin: topMargin,
      );

      final targetX = targetOffset.dx;
      final targetY = targetOffset.dy;
      final badgeColor = flashColor != Colors.transparent ? flashColor : AppColors.cyan;

      // Ambient Glow
      final glowPaint = Paint()
        ..color = badgeColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(targetX, targetY), 18, glowPaint);

      // Outer ring
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(targetX, targetY), 14, ringPaint);

      // Solid Badge
      final badgePaint = Paint()
        ..color = badgeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(targetX, targetY), 12, badgePaint);

      // Note Name text
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

  @override
  bool shouldRepaint(covariant _PhotorealisticInteractivePainter oldDelegate) {
    return oldDelegate.selectedPosition != selectedPosition ||
        oldDelegate.maxFret != maxFret ||
        oldDelegate.flashColor != flashColor;
  }
}
