import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 12; // interactive components
  static const double r16 = 16; // primary content cards
  static const double r24 = 24; // action wrappers & sheets
}

class AppSpacing {
  AppSpacing._();

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

// Ambient diffused elevation — no hard drop lines.
// Alpha key: 0x06≈2%, 0x0A≈4%, 0x0D≈5%, 0x12≈7%
class AppShadows {
  AppShadows._();

  /// Near-flat surface lift — borders do the separation work.
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// Standard ambient card shadow (spec: 0x0A / 12dp / 4dp offset).
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Elevated panel — modals, bottom sheets.
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 6)),
  ];

  /// Maximum lift — FABs, overlays.
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x12000000), blurRadius: 32, offset: Offset(0, 12)),
  ];
}
