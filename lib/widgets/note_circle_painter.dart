import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/circle_key.dart';
import '../theme/app_theme.dart';

class NoteCirclePainter extends CustomPainter {
  final CircleKey selectedKey;
  final bool isMinorSelected;
  final double pulseValue;
  final bool isDark;

  NoteCirclePainter({
    required this.selectedKey,
    this.isMinorSelected = false,
    this.pulseValue = 0.0,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minDimension = min(size.width, size.height);
    final maxRadius = (minDimension / 2) - 8.0;

    if (maxRadius <= 20) return;

    // Radius layers
    final rAccidentals = maxRadius;
    final rOuterWedgeOut = maxRadius - 16.0;
    final rOuterWedgeIn = maxRadius * 0.65;
    final rInnerWedgeOut = rOuterWedgeIn - 3.0;
    final rInnerWedgeIn = maxRadius * 0.40;
    final rCenterHub = rInnerWedgeIn - 4.0;

    final selectedIdx = selectedKey.circleIndex;
    final ivIdx = (selectedIdx + 11) % 12;
    final vIdx = (selectedIdx + 1) % 12;

    const wedgeAngle = (2 * pi) / 12;
    const gap = 0.028; // Angular separation between wedges

    // 1. Draw Outer Accidental Track Ring (Soft ambient glow)
    final trackPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, rOuterWedgeOut + 2, trackPaint);

    // 2. Draw 12 Outer Wedges (Major Keys)
    for (int i = 0; i < 12; i++) {
      final key = CircleKey.circleKeys[i];
      final isSelectedMajor = (i == selectedIdx && !isMinorSelected);
      final isSubdominant = (i == ivIdx);
      final isDominant = (i == vIdx);
      final isRelativeMajor = (i == selectedIdx && isMinorSelected);

      final midAngle = -pi / 2 + (i * wedgeAngle);
      final startAngle = midAngle - (wedgeAngle / 2) + gap;
      final sweepAngle = wedgeAngle - (2 * gap);

      // Path for this outer wedge
      final path = _createDonutWedgePath(
        center: center,
        innerRadius: rOuterWedgeIn,
        outerRadius: rOuterWedgeOut,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      );

      // Background fill color
      Color wedgeColor;
      Color borderColor;
      double borderWidth = 1.0;

      if (isSelectedMajor) {
        wedgeColor = AppColors.primary.withValues(alpha: 0.88);
        borderColor = Colors.white;
        borderWidth = 2.0;
      } else if (isRelativeMajor) {
        wedgeColor = AppColors.primary.withValues(alpha: 0.35);
        borderColor = AppColors.primary.withValues(alpha: 0.8);
        borderWidth = 1.5;
      } else if (isSubdominant) {
        wedgeColor = AppColors.cyan.withValues(alpha: 0.22);
        borderColor = AppColors.cyan.withValues(alpha: 0.7);
        borderWidth = 1.5;
      } else if (isDominant) {
        wedgeColor = AppColors.purple.withValues(alpha: 0.22);
        borderColor = AppColors.purple.withValues(alpha: 0.7);
        borderWidth = 1.5;
      } else {
        wedgeColor = isDark
            ? const Color(0xFF16161E).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.9);
        borderColor = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;
      }

      // Draw fill
      final fillPaint = Paint()
        ..color = wedgeColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // If active, draw outer pulsing glow
      if (isSelectedMajor) {
        final glowRadius = 6.0 + (pulseValue * 4.0);
        final glowPaint = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.35 + (0.15 * pulseValue))
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowRadius);
        canvas.drawPath(path, glowPaint);
      }

      // Draw border stroke
      final strokePaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawPath(path, strokePaint);

      // Major Key Label text
      final textRadius = (rOuterWedgeIn + rOuterWedgeOut) / 2;
      final textPos = Offset(
        center.dx + textRadius * cos(midAngle),
        center.dy + textRadius * sin(midAngle),
      );

      final textColor = isSelectedMajor
          ? Colors.white
          : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary);

      _paintCenteredText(
        canvas: canvas,
        text: key.majorName,
        center: textPos,
        style: TextStyle(
          color: textColor,
          fontSize: (minDimension < 320) ? 13 : 15,
          fontWeight: isSelectedMajor ? FontWeight.w900 : FontWeight.w800,
          letterSpacing: -0.2,
        ),
      );

      // Harmonic Role Tag for neighbors (IV, V)
      if (isSubdominant || isDominant) {
        final roleTag = isSubdominant ? 'IV' : 'V';
        final tagRadius = rOuterWedgeOut - 10;
        final tagPos = Offset(
          center.dx + tagRadius * cos(midAngle),
          center.dy + tagRadius * sin(midAngle),
        );
        _paintCenteredText(
          canvas: canvas,
          text: roleTag,
          center: tagPos,
          style: TextStyle(
            color: isSubdominant ? AppColors.cyan : AppColors.purple,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        );
      }

      // Draw Outer Accidental Badge
      final badgeRadius = rAccidentals - 3;
      final badgePos = Offset(
        center.dx + badgeRadius * cos(midAngle),
        center.dy + badgeRadius * sin(midAngle),
      );
      final accidentalText = key.accidentalSummary == '0 (Natural)' ? '♮' : key.accidentalSummary;
      final isAccidentalActive = (i == selectedIdx);

      Color badgeColor;
      if (isAccidentalActive) {
        badgeColor = AppColors.primary;
      } else if (key.accidentalCount > 0) {
        badgeColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706); // Warm sharp amber
      } else if (key.accidentalCount < 0) {
        badgeColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7); // Sky flat cyan
      } else {
        badgeColor = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
      }

      _paintCenteredText(
        canvas: canvas,
        text: accidentalText,
        center: badgePos,
        style: TextStyle(
          color: badgeColor,
          fontSize: (minDimension < 320) ? 9 : 10,
          fontWeight: isAccidentalActive ? FontWeight.w900 : FontWeight.w700,
        ),
      );
    }

    // 3. Draw 12 Inner Wedges (Relative Minor Keys)
    for (int i = 0; i < 12; i++) {
      final key = CircleKey.circleKeys[i];
      final isSelectedMinor = (i == selectedIdx && isMinorSelected);
      final isRelativeMinorOfSelected = (i == selectedIdx && !isMinorSelected);
      final isSubdominantMinor = (i == ivIdx); // ii chord in key
      final isDominantMinor = (i == vIdx); // iii chord in key

      final midAngle = -pi / 2 + (i * wedgeAngle);
      final startAngle = midAngle - (wedgeAngle / 2) + (gap * 1.1);
      final sweepAngle = wedgeAngle - (2 * gap * 1.1);

      final path = _createDonutWedgePath(
        center: center,
        innerRadius: rInnerWedgeIn,
        outerRadius: rInnerWedgeOut,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      );

      Color wedgeColor;
      Color borderColor;
      double borderWidth = 1.0;

      if (isSelectedMinor) {
        wedgeColor = AppColors.emerald.withValues(alpha: 0.90);
        borderColor = Colors.white;
        borderWidth = 2.0;
      } else if (isRelativeMinorOfSelected) {
        wedgeColor = AppColors.emerald.withValues(alpha: 0.35);
        borderColor = AppColors.emerald.withValues(alpha: 0.85);
        borderWidth = 1.5;
      } else if (isSubdominantMinor) {
        wedgeColor = AppColors.cyan.withValues(alpha: 0.15);
        borderColor = AppColors.cyan.withValues(alpha: 0.5);
      } else if (isDominantMinor) {
        wedgeColor = AppColors.purple.withValues(alpha: 0.15);
        borderColor = AppColors.purple.withValues(alpha: 0.5);
      } else {
        wedgeColor = isDark
            ? const Color(0xFF101017).withValues(alpha: 0.85)
            : const Color(0xFFF4F4F6);
        borderColor = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;
      }

      final fillPaint = Paint()
        ..color = wedgeColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      if (isSelectedMinor) {
        final glowRadius = 5.0 + (pulseValue * 3.0);
        final glowPaint = Paint()
          ..color = AppColors.emerald.withValues(alpha: 0.40)
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowRadius);
        canvas.drawPath(path, glowPaint);
      }

      final strokePaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawPath(path, strokePaint);

      // Minor Key Label
      final textRadius = (rInnerWedgeIn + rInnerWedgeOut) / 2;
      final textPos = Offset(
        center.dx + textRadius * cos(midAngle),
        center.dy + textRadius * sin(midAngle),
      );

      final textColor = isSelectedMinor
          ? Colors.white
          : (isRelativeMinorOfSelected
              ? (isDark ? AppColors.emerald : const Color(0xFF059669))
              : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary));

      _paintCenteredText(
        canvas: canvas,
        text: key.minorName,
        center: textPos,
        style: TextStyle(
          color: textColor,
          fontSize: (minDimension < 320) ? 10 : 12,
          fontWeight: (isSelectedMinor || isRelativeMinorOfSelected) ? FontWeight.w900 : FontWeight.w700,
          letterSpacing: -0.2,
        ),
      );

      // Harmonic role label for relative chord cluster: vi (relative minor), ii, iii
      if (isRelativeMinorOfSelected && !isMinorSelected) {
        final roleRadius = rInnerWedgeIn + 9;
        final rolePos = Offset(
          center.dx + roleRadius * cos(midAngle),
          center.dy + roleRadius * sin(midAngle),
        );
        _paintCenteredText(
          canvas: canvas,
          text: 'vi',
          center: rolePos,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        );
      } else if (isSubdominantMinor) {
        final roleRadius = rInnerWedgeIn + 9;
        final rolePos = Offset(
          center.dx + roleRadius * cos(midAngle),
          center.dy + roleRadius * sin(midAngle),
        );
        _paintCenteredText(
          canvas: canvas,
          text: 'ii',
          center: rolePos,
          style: TextStyle(
            color: AppColors.cyan.withValues(alpha: 0.9),
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        );
      } else if (isDominantMinor) {
        final roleRadius = rInnerWedgeIn + 9;
        final rolePos = Offset(
          center.dx + roleRadius * cos(midAngle),
          center.dy + roleRadius * sin(midAngle),
        );
        _paintCenteredText(
          canvas: canvas,
          text: 'iii',
          center: rolePos,
          style: TextStyle(
            color: AppColors.purple.withValues(alpha: 0.9),
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        );
      }
    }

    // 4. Center Hub: 3D Glossy Disc
    _drawCenterHub(
      canvas: canvas,
      center: center,
      radius: rCenterHub,
      selectedKey: selectedKey,
      isMinorSelected: isMinorSelected,
      minDimension: minDimension,
      isDark: isDark,
    );
  }

  void _drawCenterHub({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required CircleKey selectedKey,
    required bool isMinorSelected,
    required double minDimension,
    required bool isDark,
  }) {
    if (radius <= 10) return;

    // Radial shadow gradient
    final hubShader = ui.Gradient.radial(
      center,
      radius,
      isDark
          ? const [
              Color(0xFF262635),
              Color(0xFF171720),
              Color(0xFF0D0D12),
            ]
          : const [
              Color(0xFFFFFFFF),
              Color(0xFFF4F4F6),
              Color(0xFFE4E4E8),
            ],
      const [0.0, 0.65, 1.0],
    );

    final hubPaint = Paint()..shader = hubShader;
    canvas.drawCircle(center, radius, hubPaint);

    // Rim highlight
    final activeColor = isMinorSelected ? AppColors.emerald : AppColors.primary;
    final rimPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, rimPaint);

    // Subtle soft glow around center hub
    final glowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);
    canvas.drawCircle(center, radius, glowPaint);

    // Center Hub Text: Active Key, Subtitle, Mode Tag
    final titleText = isMinorSelected ? selectedKey.minorName : selectedKey.majorName;
    final modeLabel = isMinorSelected ? 'RELATIVE MINOR' : 'MAJOR KEY';
    final accidentalsText = selectedKey.accidentalSummary;

    // A. Main Key Title
    final titleStyle = TextStyle(
      color: isDark ? Colors.white : AppColors.lightTextPrimary,
      fontSize: (minDimension < 320) ? 22 : 28,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
    );
    _paintCenteredText(
      canvas: canvas,
      text: titleText,
      center: Offset(center.dx, center.dy - (minDimension < 320 ? 10 : 13)),
      style: titleStyle,
    );

    // B. Mode Badge
    final modeStyle = TextStyle(
      color: activeColor,
      fontSize: (minDimension < 320) ? 8 : 9,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
    );
    _paintCenteredText(
      canvas: canvas,
      text: modeLabel,
      center: Offset(center.dx, center.dy + (minDimension < 320 ? 9 : 11)),
      style: modeStyle,
    );

    // C. Accidentals note
    final accStyle = TextStyle(
      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
      fontSize: (minDimension < 320) ? 8 : 9,
      fontWeight: FontWeight.w600,
    );
    _paintCenteredText(
      canvas: canvas,
      text: accidentalsText,
      center: Offset(center.dx, center.dy + (minDimension < 320 ? 21 : 25)),
      style: accStyle,
    );
  }

  Path _createDonutWedgePath({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double startAngle,
    required double sweepAngle,
  }) {
    final endAngle = startAngle + sweepAngle;
    final path = Path();

    // Outer arc
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false,
    );

    // Line to inner arc
    path.lineTo(
      center.dx + innerRadius * cos(endAngle),
      center.dy + innerRadius * sin(endAngle),
    );

    // Inner arc backwards
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      endAngle,
      -sweepAngle,
      false,
    );

    path.close();
    return path;
  }

  void _paintCenteredText({
    required Canvas canvas,
    required String text,
    required Offset center,
    required TextStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant NoteCirclePainter oldDelegate) {
    return oldDelegate.selectedKey != selectedKey ||
        oldDelegate.isMinorSelected != isMinorSelected ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isDark != isDark;
  }
}
