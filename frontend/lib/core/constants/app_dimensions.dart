import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  // Spacing & Padding
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Border Radii
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 14.0;
  static const double radiusXLarge = 20.0;
  static const double radiusFull = 999.0;

  static const BorderRadius roundedSmall = BorderRadius.all(
    Radius.circular(radiusSmall),
  );
  static const BorderRadius roundedMedium = BorderRadius.all(
    Radius.circular(radiusMedium),
  );
  static const BorderRadius roundedLarge = BorderRadius.all(
    Radius.circular(radiusLarge),
  );
  static const BorderRadius roundedXLarge = BorderRadius.all(
    Radius.circular(radiusXLarge),
  );
  static const BorderRadius roundedFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double maxContentWidth = 1440.0;

  // Shell Layout Dimensions
  static const double navigationRailWidth = 240.0;
  static const double navigationRailCompactWidth = 72.0;
  static const double topBarHeight = 64.0;
  static const double bottomNavHeight = 64.0;
}
