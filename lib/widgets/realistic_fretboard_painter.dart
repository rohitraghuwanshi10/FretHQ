import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Helper and rendering engine for drawing an ultra-photorealistic guitar fretboard:
/// - Dark Indian/Brazilian Rosewood with 3D camber radius, realistic longitudinal grain, and open pores.
/// - Aged ivoroid/cream multi-ply edge bindings with black purfling and rolled fingerboard edges.
/// - Carved vintage bone nut with precision gauge-cut string slots.
/// - Polished stainless steel medium-jumbo frets with fret kerf slots, drop shadows, and high-specular crown reflections.
/// - Iridescent mother-of-pearl position marker inlays.
/// - Plain steel and round-wound strings with micro-ribbed winding coil texture and ambient drop shadows.
class RealisticFretboardRenderer {
  static const double defaultLeftMargin = 46.0;
  static const double defaultRightMargin = 16.0;
  static const double defaultTopMargin = 26.0;
  static const double defaultBottomMargin = 26.0;
  static const double nutWidth = 8.5;

  /// String gauges from High E (1) to Low E (6)
  static const List<double> stringGauges = [1.1, 1.5, 1.9, 2.7, 3.5, 4.3];
  static const List<bool> isWound = [false, false, false, true, true, true];
  static const List<String> stringNames = ['E', 'B', 'G', 'D', 'A', 'E'];
  static const List<int> defaultInlayFrets = [3, 5, 7, 9, 12];

  /// Precomputed deterministic wood grain data: list of (yRatio, amplitude, frequency, isDark, width)
  static final List<_GrainLine> _grainLines = [
    _GrainLine(0.04, 0.6, 0.02, true, 1.0, 0.45),
    _GrainLine(0.09, 0.8, 0.015, false, 1.4, 0.30),
    _GrainLine(0.14, 0.5, 0.03, true, 0.8, 0.40),
    _GrainLine(0.19, 1.1, 0.012, false, 1.8, 0.35),
    _GrainLine(0.24, 0.7, 0.025, true, 1.2, 0.50),
    _GrainLine(0.31, 0.9, 0.018, false, 1.5, 0.32),
    _GrainLine(0.38, 0.5, 0.035, true, 0.9, 0.42),
    _GrainLine(0.44, 1.2, 0.014, true, 1.6, 0.55),
    _GrainLine(0.49, 0.8, 0.022, false, 2.0, 0.38),
    _GrainLine(0.56, 0.6, 0.028, true, 1.1, 0.48),
    _GrainLine(0.63, 1.0, 0.016, false, 1.7, 0.34),
    _GrainLine(0.70, 0.7, 0.024, true, 1.3, 0.52),
    _GrainLine(0.77, 0.5, 0.032, true, 0.8, 0.40),
    _GrainLine(0.83, 1.1, 0.013, false, 1.9, 0.36),
    _GrainLine(0.89, 0.6, 0.027, true, 1.0, 0.46),
    _GrainLine(0.95, 0.8, 0.019, true, 1.4, 0.50),
  ];

  /// Render the complete photorealistic base guitar neck:
  /// headstock ramp, rosewood board, binding, bone nut, frets, inlays, and strings.
  static void drawFretboardBase({
    required Canvas canvas,
    required Size size,
    required int maxFret,
    double leftMargin = defaultLeftMargin,
    double rightMargin = defaultRightMargin,
    double topMargin = defaultTopMargin,
    double bottomMargin = defaultBottomMargin,
    Color flashColor = Colors.transparent,
    int? highlightedString,
    Color accentColor = AppColors.gold,
  }) {
    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;
    if (fretboardWidth <= 0 || fretboardHeight <= 0) return;

    final neckRect = Rect.fromLTWH(leftMargin, topMargin, fretboardWidth, fretboardHeight);
    final fretSpacing = fretboardWidth / maxFret;

    // 1. Headstock Veneer & Ramp (left of bone nut)
    _drawHeadstockRamp(canvas, size, leftMargin, topMargin, fretboardHeight);

    // 2. Rich Rosewood Fingerboard with 3D Camber & Longitudinal Wood Grain
    _drawRosewoodBoard(canvas, neckRect, topMargin, fretboardHeight, leftMargin, fretboardWidth);

    // 3. Multi-Ply Aged Cream Binding & Rolled Edge
    _drawBindingAndRolledEdges(canvas, leftMargin, topMargin, fretboardWidth, fretboardHeight);

    // 4. Flash Feedback Overlay (for quiz responses)
    if (flashColor != Colors.transparent) {
      final flashPaint = Paint()..color = flashColor.withValues(alpha: 0.32);
      canvas.drawRect(neckRect, flashPaint);
    }

    // 5. Iridescent Mother-of-Pearl Position Markers (Frets 3, 5, 7, 9, 12...)
    _drawPearloidInlays(canvas, maxFret, fretSpacing, leftMargin, topMargin, fretboardHeight);

    // 6. Polished Stainless Steel Frets (Medium Jumbo Spec)
    _drawStainlessSteelFrets(canvas, maxFret, fretSpacing, leftMargin, topMargin, fretboardHeight);

    // 7. Authentic Bone Nut with Precision String Slots
    _drawBoneNut(canvas, leftMargin, topMargin, fretboardHeight);

    // 8. Fret Number Markers below neck
    _drawFretNumbers(canvas, maxFret, fretSpacing, leftMargin, topMargin, fretboardHeight, accentColor);

    // 9. Realistic Strings with Wound Texture & Cast Shadows
    _drawRealisticStrings(
      canvas: canvas,
      leftMargin: leftMargin,
      topMargin: topMargin,
      fretboardWidth: fretboardWidth,
      fretboardHeight: fretboardHeight,
      highlightedString: highlightedString,
      accentColor: accentColor,
    );
  }

  /// 1. Headstock ramp area behind the bone nut
  static void _drawHeadstockRamp(
    Canvas canvas,
    Size size,
    double leftMargin,
    double topMargin,
    double fretboardHeight,
  ) {
    final rampRect = Rect.fromLTWH(0, topMargin - 4, leftMargin - nutWidth + 1, fretboardHeight + 8);
    final rampPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, topMargin),
        Offset(leftMargin - nutWidth, topMargin),
        const [
          Color(0xFF100A09),
          Color(0xFF19100E),
          Color(0xFF0F0A09),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(rampRect, rampPaint);

    // Soft drop shadow cast by the bone nut onto the headstock ramp
    final nutBackShadow = Paint()
      ..shader = ui.Gradient.linear(
        Offset(leftMargin - nutWidth - 6, topMargin),
        Offset(leftMargin - nutWidth, topMargin),
        [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.65),
        ],
        const [0.0, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(leftMargin - nutWidth - 6, topMargin - 2, 6, fretboardHeight + 4),
      nutBackShadow,
    );
  }

  /// 2. Photorealistic Indian Rosewood Fingerboard with 3D Camber and open-pore wood grain
  static void _drawRosewoodBoard(
    Canvas canvas,
    Rect neckRect,
    double topMargin,
    double fretboardHeight,
    double leftMargin,
    double fretboardWidth,
  ) {
    // 3D Arched Fretboard Camber (cylindrical radius highlight along the middle strings)
    final woodShader = ui.Gradient.linear(
      Offset(leftMargin, topMargin),
      Offset(leftMargin, topMargin + fretboardHeight),
      const [
        Color(0xFF1C110E), // Top dark shadow
        Color(0xFF281814), // Upper string area
        Color(0xFF35201A), // Apex of radius (warm chocolate rosewood catching ambient light)
        Color(0xFF291814), // Lower string area
        Color(0xFF170E0B), // Bottom edge shadow
      ],
      const [0.0, 0.22, 0.50, 0.78, 1.0],
    );
    canvas.drawRect(neckRect, Paint()..shader = woodShader);

    // Procedural Longitudinal Rosewood Grain
    final darkGrainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final auburnGrainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final line in _grainLines) {
      final baseY = topMargin + line.yRatio * fretboardHeight;
      final path = Path();
      path.moveTo(leftMargin, baseY);

      // Subtle natural organic waviness
      const segmentWidth = 28.0;
      final segments = (fretboardWidth / segmentWidth).ceil();
      for (int i = 1; i <= segments; i++) {
        final x = min(leftMargin + i * segmentWidth, leftMargin + fretboardWidth);
        final wave = sin(i * line.frequency * 50) * line.amplitude;
        path.lineTo(x, baseY + wave);
      }

      if (line.isDark) {
        darkGrainPaint
          ..color = const Color(0xFF0F0806).withValues(alpha: line.opacity)
          ..strokeWidth = line.width;
        canvas.drawPath(path, darkGrainPaint);
      } else {
        auburnGrainPaint
          ..color = const Color(0xFF4A2A20).withValues(alpha: line.opacity)
          ..strokeWidth = line.width;
        canvas.drawPath(path, auburnGrainPaint);
      }
    }

    // Realistic Open Pores (tiny dark elongated specks typical of Dalbergia Rosewood)
    final porePaint = Paint()
      ..color = const Color(0xFF090403).withValues(alpha: 0.50)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    for (int p = 0; p < 70; p++) {
      // Deterministic pseudo-random distribution
      final px = leftMargin + ((p * 73 + 17) % fretboardWidth.toInt()).toDouble();
      final py = topMargin + 4 + ((p * 97 + 23) % (fretboardHeight.toInt() - 8)).toDouble();
      final poreLength = 3.0 + (p % 5) * 1.2;
      canvas.drawLine(Offset(px, py), Offset(min(px + poreLength, leftMargin + fretboardWidth), py), porePaint);
    }
  }

  /// 3. Aged Multi-Ply Ivoroid/Cream Binding and Rolled Edge Shadow
  static void _drawBindingAndRolledEdges(
    Canvas canvas,
    double leftMargin,
    double topMargin,
    double fretboardWidth,
    double fretboardHeight,
  ) {
    const bindingThickness = 2.4;

    // Top Binding (with rounded corner sheen)
    final topBindingRect = Rect.fromLTWH(leftMargin, topMargin - bindingThickness, fretboardWidth, bindingThickness);
    final topBindingPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(leftMargin, topMargin - bindingThickness),
        Offset(leftMargin, topMargin),
        const [
          Color(0xFFFAF4E6), // Highlight edge
          Color(0xFFE5D8BE), // Aged cream body
          Color(0xFFC4B698), // Lower junction
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(topBindingRect, topBindingPaint);

    // Bottom Binding
    final bottomBindingRect = Rect.fromLTWH(leftMargin, topMargin + fretboardHeight, fretboardWidth, bindingThickness);
    final bottomBindingPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(leftMargin, topMargin + fretboardHeight),
        Offset(leftMargin, topMargin + fretboardHeight + bindingThickness),
        const [
          Color(0xFFC4B698),
          Color(0xFFE5D8BE),
          Color(0xFFFAF4E6),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(bottomBindingRect, bottomBindingPaint);

    // Crisp Black Purfling Line (separating cream binding from the dark rosewood)
    final purflingPaint = Paint()
      ..color = const Color(0xFF0C0806)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(leftMargin, topMargin), Offset(leftMargin + fretboardWidth, topMargin), purflingPaint);
    canvas.drawLine(
      Offset(leftMargin, topMargin + fretboardHeight),
      Offset(leftMargin + fretboardWidth, topMargin + fretboardHeight),
      purflingPaint,
    );

    // Rolled Fretboard Edge Highlight/Bevel inside the wood
    final rolledEdgeTop = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(leftMargin, topMargin + 1.2), Offset(leftMargin + fretboardWidth, topMargin + 1.2), rolledEdgeTop);
    canvas.drawLine(
      Offset(leftMargin, topMargin + fretboardHeight - 1.2),
      Offset(leftMargin + fretboardWidth, topMargin + fretboardHeight - 1.2),
      rolledEdgeTop,
    );
  }

  /// 4. Iridescent Mother-of-Pearl Position Markers (Frets 3, 5, 7, 9, 12, etc.)
  static void _drawPearloidInlays(
    Canvas canvas,
    int maxFret,
    double fretSpacing,
    double leftMargin,
    double topMargin,
    double fretboardHeight,
  ) {
    for (final f in defaultInlayFrets) {
      if (f <= maxFret) {
        final centerX = leftMargin + (f - 0.5) * fretSpacing;
        if (f == 12) {
          // Double pearl dots on the 12th fret
          _drawMotherOfPearlDot(canvas, Offset(centerX, topMargin + fretboardHeight * 0.28), 4.5);
          _drawMotherOfPearlDot(canvas, Offset(centerX, topMargin + fretboardHeight * 0.72), 4.5);
        } else {
          // Single center pearl dot
          _drawMotherOfPearlDot(canvas, Offset(centerX, topMargin + fretboardHeight / 2), 5.0);
        }
      }
    }
  }

  /// Render individual authentic Mother-of-Pearl dot with oyster shell nacre sheen
  static void _drawMotherOfPearlDot(Canvas canvas, Offset center, double radius) {
    // 1. Routed cavity recess ring in the dark rosewood
    canvas.drawCircle(
      center,
      radius + 0.8,
      Paint()
        ..color = const Color(0xFF0C0705)
        ..style = PaintingStyle.fill,
    );

    // 2. Multi-stop radial nacre gradient
    final pearlPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - radius * 0.25, center.dy - radius * 0.25),
        radius,
        const [
          Color(0xFFFFFFFF), // Brilliant white pearl luster
          Color(0xFFF3F7FA), // Delicate cold-pearl shimmer
          Color(0xFFE2E7ED), // Silver-blue nacre
          Color(0xFFDCD2C5), // Warm mother-of-pearl undertone
          Color(0xFFB5ABA0), // Soft boundary rim
        ],
        const [0.0, 0.30, 0.60, 0.85, 1.0],
      );
    canvas.drawCircle(center, radius, pearlPaint);

    // 3. Subtle iridescent oyster-shell diagonal sheen streak
    final streakPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.2),
      Offset(center.dx + radius * 0.2, center.dy - radius * 0.5),
      streakPaint,
    );
  }

  /// 5. Polished Stainless Steel Frets (Medium Jumbo Spec)
  static void _drawStainlessSteelFrets(
    Canvas canvas,
    int maxFret,
    double fretSpacing,
    double leftMargin,
    double topMargin,
    double fretboardHeight,
  ) {
    for (int f = 1; f <= maxFret; f++) {
      final fretX = leftMargin + f * fretSpacing;

      // A. Fret Slot Kerf (dark saw slot where tang is seated into the rosewood)
      final kerfPaint = Paint()
        ..color = const Color(0xFF090504)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(fretX - 1.4, topMargin),
        Offset(fretX - 1.4, topMargin + fretboardHeight),
        kerfPaint,
      );

      // B. Ambient Drop Shadow on the wood (simulating fret height above board)
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..strokeWidth = 1.8;
      canvas.drawLine(
        Offset(fretX + 1.8, topMargin),
        Offset(fretX + 1.8, topMargin + fretboardHeight),
        shadowPaint,
      );

      // C. Stainless Steel Crown Body (High-Specular Metallic Gradient)
      const crownWidth = 2.6;
      final crownRect = Rect.fromLTWH(fretX - crownWidth / 2, topMargin, crownWidth, fretboardHeight);
      final ssPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(fretX - crownWidth / 2, topMargin),
          Offset(fretX + crownWidth / 2, topMargin),
          const [
            Color(0xFF6F7987), // Dark metallic shoulder
            Color(0xFFB5BDCA), // Bright stainless steel body
            Color(0xFFFFFFFF), // Specular apex crown reflection
            Color(0xFFCAD1DC), // Chrome face
            Color(0xFF7E8896), // Right metallic rim
          ],
          const [0.0, 0.25, 0.50, 0.78, 1.0],
        );
      canvas.drawRect(crownRect, ssPaint);

      // D. Razor-sharp Specular Apex Highlight Line (Mirror-polish SS reflection)
      final specularLine = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 0.7;
      canvas.drawLine(
        Offset(fretX, topMargin),
        Offset(fretX, topMargin + fretboardHeight),
        specularLine,
      );

      // E. Crowned Beveled Fret Ends (Dressed & polished into the cream binding)
      final endPaint = Paint()..color = const Color(0xFFD6DCE5);
      canvas.drawCircle(Offset(fretX, topMargin), 1.2, endPaint);
      canvas.drawCircle(Offset(fretX, topMargin + fretboardHeight), 1.2, endPaint);
    }
  }

  /// 6. Carved Vintage Bone Nut with Precision String Slots
  static void _drawBoneNut(
    Canvas canvas,
    double leftMargin,
    double topMargin,
    double fretboardHeight,
  ) {
    final nutLeft = leftMargin - nutWidth;
    final nutRect = Rect.fromLTWH(nutLeft, topMargin - 1.5, nutWidth, fretboardHeight + 3.0);
    final nutRRect = RRect.fromRectAndRadius(nutRect, const Radius.circular(2.5));

    // A. 3D Bone Body Gradient (Unbleached organic bone coloration)
    final bonePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(nutLeft, topMargin),
        Offset(leftMargin, topMargin),
        const [
          Color(0xFFFAF7EE), // Left bevel highlight
          Color(0xFFF1E8D3), // Polished bone body
          Color(0xFFE4D7BD), // Organic warmth
          Color(0xFFC7B998), // Contact shadow
        ],
        const [0.0, 0.35, 0.75, 1.0],
      );
    canvas.drawRRect(nutRRect, bonePaint);

    // B. Organic Bone Striation lines (natural bone density fibers)
    final fiberPaint = Paint()
      ..color = const Color(0xFFA69675).withValues(alpha: 0.25)
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(nutLeft + 2.5, topMargin), Offset(nutLeft + 2.5, topMargin + fretboardHeight), fiberPaint);
    canvas.drawLine(Offset(nutLeft + 5.5, topMargin), Offset(nutLeft + 5.5, topMargin + fretboardHeight), fiberPaint);

    // C. Crisp Contact Shadow with Fret 0 / Rosewood Joint
    final jointPaint = Paint()
      ..color = const Color(0xFF0C0705)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(leftMargin, topMargin - 1.5),
      Offset(leftMargin, topMargin + fretboardHeight + 1.5),
      jointPaint,
    );

    // D. Precision String Slots (Hand-carved string notches cut into the bone nut)
    final stringSpacing = fretboardHeight / 5.0;
    for (int i = 0; i < 6; i++) {
      final stringY = topMargin + i * stringSpacing;
      final gauge = stringGauges[i];
      final slotHeight = max(1.4, gauge * 0.9);

      // Dark slot cavity
      final slotPaint = Paint()
        ..color = const Color(0xFF1E140D)
        ..strokeWidth = slotHeight
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(
        Offset(nutLeft + 1.5, stringY),
        Offset(leftMargin + 0.5, stringY),
        slotPaint,
      );

      // Micro-bevel highlight on the chamfered rim of the bone slot
      final slotChamfer = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 0.6;
      canvas.drawLine(
        Offset(nutLeft + 1.0, stringY - slotHeight / 2 - 0.4),
        Offset(leftMargin, stringY - slotHeight / 2 - 0.4),
        slotChamfer,
      );
    }
  }

  /// 7. Fret Number Indicators along bottom edge
  static void _drawFretNumbers(
    Canvas canvas,
    int maxFret,
    double fretSpacing,
    double leftMargin,
    double topMargin,
    double fretboardHeight,
    Color accentColor,
  ) {
    final fretTextPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int f = 0; f <= maxFret; f++) {
      final isMarkerFret = (f == 3 || f == 5 || f == 7 || f == 9 || f == 12);
      fretTextPainter.text = TextSpan(
        text: '$f',
        style: TextStyle(
          color: isMarkerFret ? accentColor : Colors.grey.shade400,
          fontSize: 10,
          fontWeight: isMarkerFret ? FontWeight.w900 : FontWeight.w700,
          letterSpacing: 0.3,
        ),
      );
      fretTextPainter.layout();
      final labelX = f == 0
          ? leftMargin - nutWidth - fretTextPainter.width - 4
          : leftMargin + (f - 0.5) * fretSpacing - fretTextPainter.width / 2;

      fretTextPainter.paint(
        canvas,
        Offset(labelX, topMargin + fretboardHeight + 6),
      );
    }
  }

  /// 8. Realistic Guitar Strings (Plain Steel & Wound Nickel/Bronze with Coil Textures)
  static void _drawRealisticStrings({
    required Canvas canvas,
    required double leftMargin,
    required double topMargin,
    required double fretboardWidth,
    required double fretboardHeight,
    int? highlightedString,
    required Color accentColor,
  }) {
    const numStrings = 6;
    final stringSpacing = fretboardHeight / (numStrings - 1);
    final stringStartX = leftMargin - nutWidth - 6;
    final stringEndX = leftMargin + fretboardWidth;

    for (int i = 0; i < numStrings; i++) {
      final stringY = topMargin + i * stringSpacing;
      final gauge = stringGauges[i];
      final wound = isWound[i];
      final stringNum = i + 1; // 1 to 6
      final isTarget = highlightedString == stringNum;

      // A. String Cast Shadow on the Rosewood and Frets (offset downward by +1.6px)
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..strokeWidth = gauge * 0.95;
      canvas.drawLine(
        Offset(stringStartX, stringY + 1.6),
        Offset(stringEndX, stringY + 1.6),
        shadowPaint,
      );

      // B. String Base Metal Core
      if (!wound) {
        // Plain Swedish Steel / Chrome (Strings 1, 2, 3)
        final plainCorePaint = Paint()
          ..color = const Color(0xFF9097A3)
          ..strokeWidth = gauge;
        canvas.drawLine(Offset(stringStartX, stringY), Offset(stringEndX, stringY), plainCorePaint);

        // Specular Mirror Sheen Line
        final shinePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = max(0.6, gauge * 0.4);
        canvas.drawLine(
          Offset(stringStartX, stringY - gauge * 0.2),
          Offset(stringEndX, stringY - gauge * 0.2),
          shinePaint,
        );
      } else {
        // Round-Wound Strings (Strings 4, 5, 6 - D, A, Low E)
        final woundBaseColor = i == 5
            ? const Color(0xFFC0A486) // Low E phosphor bronze / nickel alloy
            : (i == 4 ? const Color(0xFFB5A795) : const Color(0xFFB8BAC1)); // A and D nickel-steel

        final woundCorePaint = Paint()
          ..color = woundBaseColor
          ..strokeWidth = gauge;
        canvas.drawLine(Offset(stringStartX, stringY), Offset(stringEndX, stringY), woundCorePaint);

        // Micro-Ribbed Coil Winding Texture
        // Alternating micro-shadow grooves and coil crowns across the string
        final coilDarkPaint = Paint()
          ..color = const Color(0xFF1E1712).withValues(alpha: 0.45)
          ..strokeWidth = 0.9;

        final coilLightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 0.9;

        const coilStep = 2.4;
        for (double cx = stringStartX; cx < stringEndX; cx += coilStep) {
          canvas.drawLine(
            Offset(cx, stringY - gauge / 2),
            Offset(cx, stringY + gauge / 2),
            coilDarkPaint,
          );
          canvas.drawLine(
            Offset(cx + 1.1, stringY - gauge / 2),
            Offset(cx + 1.1, stringY + gauge / 2),
            coilLightPaint,
          );
        }

        // Top Specular Highlight Streak across the crest of the coils
        final crestShine = Paint()
          ..color = Colors.white.withValues(alpha: 0.60)
          ..strokeWidth = max(0.7, gauge * 0.3);
        canvas.drawLine(
          Offset(stringStartX, stringY - gauge * 0.22),
          Offset(stringEndX, stringY - gauge * 0.22),
          crestShine,
        );
      }

      // C. String Name Pill on Far Left
      final labelPainter = TextPainter(
        text: TextSpan(
          text: stringNames[i],
          style: TextStyle(
            color: isTarget ? accentColor : Colors.grey.shade400,
            fontSize: 12,
            fontWeight: isTarget ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(12, stringY - labelPainter.height / 2),
      );
    }
  }

  /// Helper to calculate coordinates for any target or tapped fret position
  static Offset getPositionOffset({
    required int stringNumber, // 1 to 6
    required int fretNumber, // 0 to maxFret
    required double fretboardWidth,
    required double fretboardHeight,
    required int maxFret,
    double leftMargin = defaultLeftMargin,
    double topMargin = defaultTopMargin,
  }) {
    final stringSpacing = fretboardHeight / 5.0;
    final fretSpacing = fretboardWidth / maxFret;

    final y = topMargin + (stringNumber - 1) * stringSpacing;
    final x = fretNumber == 0
        ? leftMargin - nutWidth - 8.0
        : leftMargin + (fretNumber - 0.5) * fretSpacing;

    return Offset(x, y);
  }
}

class _GrainLine {
  final double yRatio;
  final double amplitude;
  final double frequency;
  final bool isDark;
  final double width;
  final double opacity;

  const _GrainLine(
    this.yRatio,
    this.amplitude,
    this.frequency,
    this.isDark,
    this.width,
    this.opacity,
  );
}
