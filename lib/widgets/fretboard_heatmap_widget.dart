import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

class FretboardHeatmapWidget extends StatefulWidget {
  final Map<String, FretHeatmapStat> heatmapStats;
  final void Function(int stringNumber, int fretNumber, FretHeatmapStat? stat)? onFretTapped;

  const FretboardHeatmapWidget({
    super.key,
    required this.heatmapStats,
    this.onFretTapped,
  });

  @override
  State<FretboardHeatmapWidget> createState() => _FretboardHeatmapWidgetState();
}

class _FretboardHeatmapWidgetState extends State<FretboardHeatmapWidget> {
  TargetPosition? _inspectedPosition;

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
    final fretSpacing = fretboardWidth / 12.0;

    final stringIdx = ((localPos.dy - topMargin) / stringSpacing).round().clamp(0, 5);
    final stringNumber = stringIdx + 1; // 1 to 6

    int fretNumber;
    if (localPos.dx < leftMargin) {
      fretNumber = 0; // Open string
    } else {
      fretNumber = (((localPos.dx - leftMargin) / fretSpacing).floor() + 1).clamp(1, 12);
    }

    HapticFeedback.selectionClick();
    final pos = TargetPosition(stringNumber: stringNumber, fretNumber: fretNumber);
    final stat = widget.heatmapStats['$stringNumber-$fretNumber'];

    setState(() {
      _inspectedPosition = pos;
    });

    widget.onFretTapped?.call(stringNumber, fretNumber, stat);
    _showFretDetailModal(pos, stat);
  }

  void _showFretDetailModal(TargetPosition pos, FretHeatmapStat? stat) {
    final note = pos.targetNote;
    final total = stat?.totalAttempts ?? 0;
    final correct = stat?.correctCount ?? 0;
    final accuracy = stat?.accuracy ?? 0.0;

    Color statusColor;
    String statusLabel;
    if (total == 0) {
      statusColor = Colors.grey.shade500;
      statusLabel = 'UNTESTED POSITION';
    } else if (accuracy >= 80) {
      statusColor = AppColors.emerald;
      statusLabel = 'HIGH MASTERY (>${accuracy.toStringAsFixed(0)}%)';
    } else if (accuracy >= 50) {
      statusColor = AppColors.gold;
      statusLabel = 'DEVELOPING (${accuracy.toStringAsFixed(0)}%)';
    } else {
      statusColor = AppColors.coral;
      statusLabel = 'WEAK SPOT FOCUS (${accuracy.toStringAsFixed(0)}%)';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        note.displayName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pos.stringName} String',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          pos.fretNumber == 0 ? 'Open (Fret 0)' : 'Fret ${pos.fretNumber}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Attempts', '$total', Icons.format_list_numbered, Colors.white70),
                _buildStatItem('Correct', '$correct', Icons.check_circle_outline, AppColors.emerald),
                _buildStatItem('Accuracy', total > 0 ? '${accuracy.toStringAsFixed(1)}%' : '--', Icons.insights, statusColor),
              ],
            ),
            const SizedBox(height: 16),
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: accuracy / 100.0,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 8,
                ),
              ),
            ] else ...[
              const Center(
                child: Text(
                  'Complete practice quizzes to build analytics for this note.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heatmap Legend
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendPill('Mastered (>80%)', AppColors.emerald),
              _buildLegendPill('Learning (50-80%)', AppColors.gold),
              _buildLegendPill('Weak (<50%)', AppColors.coral),
              _buildLegendPill('Untested', Colors.grey.shade600),
            ],
          ),
        ),

        // Heatmap Fretboard
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141113),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handleTap(context, details),
                child: CustomPaint(
                  painter: _HeatmapFretboardPainter(
                    heatmapStats: widget.heatmapStats,
                    inspectedPosition: _inspectedPosition,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendPill(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}

class _HeatmapFretboardPainter extends CustomPainter {
  final Map<String, FretHeatmapStat> heatmapStats;
  final TargetPosition? inspectedPosition;

  _HeatmapFretboardPainter({
    required this.heatmapStats,
    required this.inspectedPosition,
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

    // Neck background
    final neckPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF241C1A), Color(0xFF191311), Color(0xFF120E0D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(neckRect);
    canvas.drawRect(neckRect, neckPaint);

    // Binding
    final bindingPaint = Paint()
      ..color = const Color(0xFFE5DECF)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(leftMargin, topMargin), Offset(leftMargin + fretboardWidth, topMargin), bindingPaint);
    canvas.drawLine(
      Offset(leftMargin, topMargin + fretboardHeight),
      Offset(leftMargin + fretboardWidth, topMargin + fretboardHeight),
      bindingPaint,
    );

    const maxFret = 12;
    final fretSpacing = fretboardWidth / maxFret;

    // Bone Nut
    final nutRect = Rect.fromLTWH(leftMargin - 6, topMargin - 1, 6, fretboardHeight + 2);
    final nutPaint = Paint()..color = const Color(0xFFE0D8C3);
    canvas.drawRRect(RRect.fromRectAndRadius(nutRect, const Radius.circular(2)), nutPaint);

    // Frets
    final fretTextPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int f = 0; f <= maxFret; f++) {
      final fretX = leftMargin + f * fretSpacing;
      if (f > 0) {
        canvas.drawLine(
          Offset(fretX, topMargin),
          Offset(fretX, topMargin + fretboardHeight),
          Paint()
            ..color = const Color(0xFF8E95A0)
            ..strokeWidth = 1.5,
        );
      }

      fretTextPainter.text = TextSpan(
        text: '$f',
        style: TextStyle(
          color: (f == 3 || f == 5 || f == 7 || f == 9 || f == 12) ? AppColors.purple : Colors.grey.shade400,
          fontSize: 9,
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
    final stringGauges = [1.0, 1.4, 1.8, 2.4, 3.0, 3.8];

    for (int i = 0; i < numStrings; i++) {
      final stringY = topMargin + i * stringSpacing;
      final gauge = stringGauges[i];

      final stringPaint = Paint()
        ..color = const Color(0xFF8B92A0)
        ..strokeWidth = gauge;
      canvas.drawLine(
        Offset(leftMargin - 6, stringY),
        Offset(leftMargin + fretboardWidth, stringY),
        stringPaint,
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: stringNames[i],
          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(12, stringY - labelPainter.height / 2),
      );
    }

    // Draw Heatmap Mastery Badges for all 6 strings x 13 frets (0 to 12)
    final notePainter = TextPainter(textDirection: TextDirection.ltr);

    for (int s = 1; s <= 6; s++) {
      final strIdx = s - 1;
      final y = topMargin + strIdx * stringSpacing;

      for (int f = 0; f <= maxFret; f++) {
        final x = f == 0 ? leftMargin - 10 : leftMargin + (f - 0.5) * fretSpacing;
        final key = '$s-$f';
        final stat = heatmapStats[key];
        final note = Note.getNoteForPosition(s, f);

        Color badgeColor;
        Color textColor;
        if (stat == null || stat.totalAttempts == 0) {
          badgeColor = const Color(0xFF262334);
          textColor = Colors.white30;
        } else if (stat.accuracy >= 80) {
          badgeColor = AppColors.emerald;
          textColor = Colors.black;
        } else if (stat.accuracy >= 50) {
          badgeColor = AppColors.gold;
          textColor = Colors.black;
        } else {
          badgeColor = AppColors.coral;
          textColor = Colors.white;
        }

        // Draw node circle
        final nodePaint = Paint()
          ..color = badgeColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 8.5, nodePaint);

        // Highlight border if this is the inspected position
        if (inspectedPosition != null &&
            inspectedPosition!.stringNumber == s &&
            inspectedPosition!.fretNumber == f) {
          final inspectPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawCircle(Offset(x, y), 11.5, inspectPaint);
        }

        // Note letter text inside circle
        notePainter.text = TextSpan(
          text: note.id,
          style: TextStyle(
            color: textColor,
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
          ),
        );
        notePainter.layout();
        notePainter.paint(
          canvas,
          Offset(x - notePainter.width / 2, y - notePainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapFretboardPainter oldDelegate) {
    return oldDelegate.heatmapStats != heatmapStats ||
        oldDelegate.inspectedPosition != inspectedPosition;
  }
}

Widget _buildStatItem(String label, String value, IconData icon, Color color) {
  return Column(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    ],
  );
}
