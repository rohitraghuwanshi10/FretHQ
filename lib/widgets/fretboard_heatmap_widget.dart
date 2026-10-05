import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import 'realistic_fretboard_painter.dart';

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

    const leftMargin = RealisticFretboardRenderer.defaultLeftMargin;
    const rightMargin = RealisticFretboardRenderer.defaultRightMargin;
    const topMargin = RealisticFretboardRenderer.defaultTopMargin;
    const bottomMargin = RealisticFretboardRenderer.defaultBottomMargin;

    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;

    if (fretboardWidth <= 0 || fretboardHeight <= 0) return;

    final stringSpacing = fretboardHeight / 5.0;
    final fretSpacing = fretboardWidth / 12.0;

    final stringIdx = ((localPos.dy - topMargin) / stringSpacing).round().clamp(0, 5);
    final stringNumber = stringIdx + 1; // 1 to 6

    int fretNumber;
    if (localPos.dx < leftMargin - 4) {
      fretNumber = 0; // Open string behind or on bone nut
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
            color: const Color(0xFF140F0D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.08),
                blurRadius: 14,
                spreadRadius: 1,
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
    const leftMargin = RealisticFretboardRenderer.defaultLeftMargin;
    const rightMargin = RealisticFretboardRenderer.defaultRightMargin;
    const topMargin = RealisticFretboardRenderer.defaultTopMargin;
    const bottomMargin = RealisticFretboardRenderer.defaultBottomMargin;

    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;
    if (fretboardWidth <= 0 || fretboardHeight <= 0) return;

    const maxFret = 12;

    // 1. Draw photorealistic base fretboard
    RealisticFretboardRenderer.drawFretboardBase(
      canvas: canvas,
      size: size,
      maxFret: maxFret,
      leftMargin: leftMargin,
      rightMargin: rightMargin,
      topMargin: topMargin,
      bottomMargin: bottomMargin,
      accentColor: AppColors.purple,
    );

    // 2. Draw Heatmap Mastery Badges for all 6 strings x 13 frets (0 to 12)
    final notePainter = TextPainter(textDirection: TextDirection.ltr);

    for (int s = 1; s <= 6; s++) {
      for (int f = 0; f <= maxFret; f++) {
        final posOffset = RealisticFretboardRenderer.getPositionOffset(
          stringNumber: s,
          fretNumber: f,
          fretboardWidth: fretboardWidth,
          fretboardHeight: fretboardHeight,
          maxFret: maxFret,
          leftMargin: leftMargin,
          topMargin: topMargin,
        );
        final x = posOffset.dx;
        final y = posOffset.dy;

        final key = '$s-$f';
        final stat = heatmapStats[key];
        final note = Note.getNoteForPosition(s, f);

        Color badgeColor;
        Color textColor;
        bool isTested = false;

        if (stat == null || stat.totalAttempts == 0) {
          badgeColor = const Color(0xFF221816);
          textColor = Colors.white38;
        } else if (stat.accuracy >= 80) {
          badgeColor = AppColors.emerald;
          textColor = Colors.black;
          isTested = true;
        } else if (stat.accuracy >= 50) {
          badgeColor = AppColors.gold;
          textColor = Colors.black;
          isTested = true;
        } else {
          badgeColor = AppColors.coral;
          textColor = Colors.white;
          isTested = true;
        }

        // Soft ambient glow for tested mastery badges
        if (isTested) {
          final glowPaint = Paint()
            ..color = badgeColor.withValues(alpha: 0.35)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(Offset(x, y), 11, glowPaint);
        }

        // Node circle
        final nodePaint = Paint()
          ..color = badgeColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 8.5, nodePaint);

        // Subtle dark or metallic border for untested positions
        if (!isTested) {
          final borderPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8;
          canvas.drawCircle(Offset(x, y), 8.5, borderPaint);
        }

        // Highlight border if this is the inspected position
        if (inspectedPosition != null &&
            inspectedPosition!.stringNumber == s &&
            inspectedPosition!.fretNumber == f) {
          final inspectGlow = Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(Offset(x, y), 12.0, inspectGlow);

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
