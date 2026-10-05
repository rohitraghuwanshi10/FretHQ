import 'package:flutter/material.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import 'realistic_fretboard_painter.dart';

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
        color: const Color(0xFF140F0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.08),
            blurRadius: 14,
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
    const leftMargin = RealisticFretboardRenderer.defaultLeftMargin;
    const rightMargin = RealisticFretboardRenderer.defaultRightMargin;
    const topMargin = RealisticFretboardRenderer.defaultTopMargin;
    const bottomMargin = RealisticFretboardRenderer.defaultBottomMargin;

    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;
    if (fretboardWidth <= 0 || fretboardHeight <= 0) return;

    // 1. Draw base photorealistic rosewood fretboard, bone nut, frets, inlays & strings
    RealisticFretboardRenderer.drawFretboardBase(
      canvas: canvas,
      size: size,
      maxFret: maxFret,
      leftMargin: leftMargin,
      rightMargin: rightMargin,
      topMargin: topMargin,
      bottomMargin: bottomMargin,
      flashColor: flashColor,
      highlightedString: targetPosition?.stringNumber,
      accentColor: AppColors.gold,
    );

    // 2. Draw Target Position Highlight & Pulse Waves
    if (targetPosition != null) {
      final targetOffset = RealisticFretboardRenderer.getPositionOffset(
        stringNumber: targetPosition!.stringNumber,
        fretNumber: targetPosition!.fretNumber,
        fretboardWidth: fretboardWidth,
        fretboardHeight: fretboardHeight,
        maxFret: maxFret,
        leftMargin: leftMargin,
        topMargin: topMargin,
      );

      final targetX = targetOffset.dx;
      final targetY = targetOffset.dy;
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

  @override
  bool shouldRepaint(covariant _PhotorealisticFretboardPainter oldDelegate) {
    return oldDelegate.targetPosition != targetPosition ||
        oldDelegate.maxFret != maxFret ||
        oldDelegate.flashColor != flashColor ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.showNoteName != showNoteName;
  }
}
