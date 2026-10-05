import 'package:flutter/material.dart';

/// Responsive design breakpoints and layout utilities for FretHQ.
class ResponsiveLayout {
  // Breakpoints
  static const double mobileBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;

  // Standard max content widths
  static const double defaultMaxContentWidth = 1100.0;
  static const double wideMaxContentWidth = 1150.0;
  static const double gameMaxContentWidth = 1050.0;
  static const double formMaxContentWidth = 900.0;
  static const double mobileMaxWidth = 580.0;

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileBreakpoint;
  }

  static bool isWideDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static double contentWidth(BuildContext context, {double desktopMaxWidth = defaultMaxContentWidth}) {
    final width = MediaQuery.of(context).size.width;
    if (width >= mobileBreakpoint) {
      return desktopMaxWidth;
    }
    return mobileMaxWidth;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final isDesk = isDesktop(context);
    if (isDesk) {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0);
    }
    return const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0);
  }
}
