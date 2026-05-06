import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();
  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r24 = 24;
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

// Alpha values: 0.08→0x14, 0.10→0x1A, 0.12→0x1F, 0.16→0x29
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x140D1B2A), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x1A0D1B2A), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1F0D1B2A), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x290D1B2A), blurRadius: 40, offset: Offset(0, 16)),
  ];
}
