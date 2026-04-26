import 'package:flutter/material.dart';

class AppShapes {
  // Soft, playful, organic radii
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 32.0; // Very round for cards
  static const double radiusPill = 999.0;

  static const BorderRadius shapeSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius shapeMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius shapeLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius shapePill = BorderRadius.all(Radius.circular(radiusPill));

  // Backward compatibility constants (instead of getters, for const expressions)
  static const double thickBorderWidth = 2.0;
  static const double cardRadius = radiusLarge;
  static const double buttonRadius = radiusPill;
  static const double inputRadius = radiusMedium;
  static const double pillRadius = radiusPill;
  static const double bottomSheetRadius = radiusLarge;
  
  static RoundedRectangleBorder get cardShape => RoundedRectangleBorder(
    borderRadius: shapeLarge,
    side: const BorderSide(color: Color(0x1A000000)),
  );
  static RoundedRectangleBorder get cardShapeDark => RoundedRectangleBorder(
    borderRadius: shapeLarge,
    side: const BorderSide(color: Color(0x1AFFFFFF)),
  );
}
