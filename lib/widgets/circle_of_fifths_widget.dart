import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/circle_key.dart';
import 'note_circle_painter.dart';

class CircleOfFifthsWidget extends StatefulWidget {
  final CircleKey selectedKey;
  final bool isMinorSelected;
  final void Function(CircleKey key, bool isMinor) onKeyChanged;
  final double? size;

  const CircleOfFifthsWidget({
    super.key,
    required this.selectedKey,
    required this.onKeyChanged,
    this.isMinorSelected = false,
    this.size,
  });

  @override
  State<CircleOfFifthsWidget> createState() => _CircleOfFifthsWidgetState();
}

class _CircleOfFifthsWidgetState extends State<CircleOfFifthsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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

  void _handleTap(Offset localPos, Size widgetSize) {
    final center = Offset(widgetSize.width / 2, widgetSize.height / 2);
    final minDimension = min(widgetSize.width, widgetSize.height);
    final maxRadius = (minDimension / 2) - 8.0;

    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final rOuterWedgeOut = maxRadius - 16.0;
    final rOuterWedgeIn = maxRadius * 0.65;
    final rInnerWedgeOut = rOuterWedgeIn - 3.0;
    final rInnerWedgeIn = maxRadius * 0.40;
    final rCenterHub = rInnerWedgeIn - 4.0;

    // Center hub tapped: toggle between Major and Relative Minor
    if (distance <= rCenterHub) {
      HapticFeedback.mediumImpact();
      widget.onKeyChanged(widget.selectedKey, !widget.isMinorSelected);
      return;
    }

    // Convert (dx, dy) to angle from 12 o'clock (-pi/2)
    // atan2 gives (-pi to +pi) where 0 is 3 o'clock
    double angle = atan2(dy, dx); // [-pi, +pi]
    // Shift so 12 o'clock (-pi/2) is 0:
    double normalized = angle + (pi / 2);
    if (normalized < 0) normalized += (2 * pi);

    const segmentAngle = (2 * pi) / 12; // 30 degrees (pi/6)
    // Offset by half segment so segment 0 is centered at 12 o'clock
    double offsetAngle = normalized + (segmentAngle / 2);
    if (offsetAngle >= (2 * pi)) offsetAngle -= (2 * pi);

    final tappedIndex = (offsetAngle / segmentAngle).floor() % 12;
    final tappedKey = CircleKey.circleKeys[tappedIndex];

    if (distance >= rInnerWedgeIn && distance <= rInnerWedgeOut) {
      // Inner ring tapped -> Select Relative Minor
      HapticFeedback.selectionClick();
      widget.onKeyChanged(tappedKey, true);
    } else if (distance >= rOuterWedgeIn && distance <= rOuterWedgeOut + 18.0) {
      // Outer ring tapped -> Select Major
      HapticFeedback.selectionClick();
      widget.onKeyChanged(tappedKey, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget wheelContent(double targetDimension) {
      return SizedBox(
        width: targetDimension,
        height: targetDimension,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _handleTap(details.localPosition, Size(targetDimension, targetDimension)),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(targetDimension, targetDimension),
                painter: NoteCirclePainter(
                  selectedKey: widget.selectedKey,
                  isMinorSelected: widget.isMinorSelected,
                  pulseValue: _pulseAnimation.value,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
      );
    }

    if (widget.size != null) {
      return wheelContent(widget.size!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dim = min(constraints.maxWidth, constraints.maxHeight.isFinite ? constraints.maxHeight : constraints.maxWidth);
        final finalSize = dim.clamp(260.0, 480.0);
        return Center(child: wheelContent(finalSize));
      },
    );
  }
}
