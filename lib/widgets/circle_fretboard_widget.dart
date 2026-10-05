import 'package:flutter/material.dart';
import '../models/circle_key.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import 'realistic_fretboard_painter.dart';

class CircleFretboardWidget extends StatelessWidget {
  final CircleKey selectedKey;
  final bool isMinor;
  final ChordInfo? isolatedChord;
  final int maxFret;

  const CircleFretboardWidget({
    super.key,
    required this.selectedKey,
    this.isMinor = false,
    this.isolatedChord,
    this.maxFret = 12,
  });

  @override
  Widget build(BuildContext context) {
    final activeNotes = isolatedChord != null
        ? isolatedChord!.triadNotes
        : (isMinor ? selectedKey.relativeMinorScaleNotes : selectedKey.majorScaleNotes);

    final rootNote = isolatedChord != null
        ? isolatedChord!.rootNote
        : (isMinor ? selectedKey.minorNote : selectedKey.majorNote);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140F0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isMinor ? AppColors.emerald : AppColors.primary).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: (isMinor ? AppColors.emerald : AppColors.primary).withValues(alpha: 0.08),
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
          child: CustomPaint(
            painter: _CircleFretboardPainter(
              activeNotes: activeNotes,
              rootNote: rootNote,
              maxFret: maxFret,
              isMinor: isMinor,
              isolatedChord: isolatedChord,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleFretboardPainter extends CustomPainter {
  final List<Note> activeNotes;
  final Note rootNote;
  final int maxFret;
  final bool isMinor;
  final ChordInfo? isolatedChord;

  _CircleFretboardPainter({
    required this.activeNotes,
    required this.rootNote,
    required this.maxFret,
    required this.isMinor,
    required this.isolatedChord,
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

    // 1. Draw base photorealistic rosewood fretboard
    RealisticFretboardRenderer.drawFretboardBase(
      canvas: canvas,
      size: size,
      maxFret: maxFret,
      leftMargin: leftMargin,
      rightMargin: rightMargin,
      topMargin: topMargin,
      bottomMargin: bottomMargin,
      accentColor: isMinor ? AppColors.emerald : AppColors.primary,
    );

    // 2. Map and highlight scale / chord notes across strings 1..6
    final activeSet = activeNotes.map((n) => n.chromaticIndex).toSet();
    final rootIndex = rootNote.chromaticIndex;

    for (int stringNum = 1; stringNum <= 6; stringNum++) {
      for (int fret = 0; fret <= maxFret; fret++) {
        final note = Note.getNoteForPosition(stringNum, fret);
        if (!activeSet.contains(note.chromaticIndex)) continue;

        final isRoot = (note.chromaticIndex == rootIndex);
        final offset = RealisticFretboardRenderer.getPositionOffset(
          stringNumber: stringNum,
          fretNumber: fret,
          fretboardWidth: fretboardWidth,
          fretboardHeight: fretboardHeight,
          maxFret: maxFret,
          leftMargin: leftMargin,
          topMargin: topMargin,
        );

        _drawNoteMarker(
          canvas: canvas,
          offset: offset,
          note: note,
          isRoot: isRoot,
          fret: fret,
        );
      }
    }
  }

  void _drawNoteMarker({
    required Canvas canvas,
    required Offset offset,
    required Note note,
    required bool isRoot,
    required int fret,
  }) {
    final double radius = isRoot ? 11.0 : 9.5;

    // Outer glow for root notes
    if (isRoot) {
      final glowPaint = Paint()
        ..color = (isMinor ? AppColors.emerald : AppColors.primary).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);
      canvas.drawCircle(offset, radius + 2, glowPaint);
    }

    // Node body gradient
    final baseColor = isRoot
        ? (isMinor ? AppColors.emerald : AppColors.primary)
        : const Color(0xFF1E293B);

    final borderStroke = isRoot
        ? Colors.white
        : (isMinor ? AppColors.emerald.withValues(alpha: 0.7) : AppColors.cyan.withValues(alpha: 0.7));

    final nodePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, radius, nodePaint);

    final borderPaint = Paint()
      ..color = borderStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = isRoot ? 2.0 : 1.2;
    canvas.drawCircle(offset, radius, borderPaint);

    // Note Name inside pill
    final textPainter = TextPainter(
      text: TextSpan(
        text: note.id,
        style: TextStyle(
          color: Colors.white,
          fontSize: isRoot ? 10 : 8.5,
          fontWeight: isRoot ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(offset.dx - (textPainter.width / 2), offset.dy - (textPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant _CircleFretboardPainter oldDelegate) {
    return oldDelegate.activeNotes != activeNotes ||
        oldDelegate.rootNote != rootNote ||
        oldDelegate.maxFret != maxFret ||
        oldDelegate.isMinor != isMinor ||
        oldDelegate.isolatedChord != isolatedChord;
  }
}
