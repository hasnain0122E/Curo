import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  /// CURO primary brand cyan — matches the official logo colour.
  static const Color primary = Color(0xFF36BDF2);

  /// CURO brand cerulean — darker variant for buttons, active states.
  static const Color primaryDark = Color(0xFF22A9DF);

  /// Alias for [primaryDark]; use on interactive CTA elements.
  static const Color accent = primaryDark;

  /// Backward-compat alias; prefer [accent] in new code.
  static const Color deep = primaryDark;

  // ── Canvas ───────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F9FF); // spec canvas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E0); // 8% slate/gray stroke

  // ── Typography ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF6B7A8D);

  // ── Functional Status Matrix ─────────────────────────────────────────────
  // Normal / Healthy
  static const Color successBackground = Color(0xFFE8F5E9);
  static const Color successForeground = Color(0xFF2E7D32);

  // Warning / Requires Attention
  static const Color warningBackground = Color(0xFFFFF8E1);
  static const Color warningForeground = Color(0xFFB78103);

  // Critical Alert / High Outliers
  static const Color dangerBackground = Color(0xFFFFEBEE);
  static const Color dangerForeground = Color(0xFFC62828);

  // MediPoints accent (gold)
  static const Color medipointsBackground = Color(0xFFFFF3E0);
  static const Color medipointsForeground = Color(0xFFE65100);

  // ── Semantic UI Colours ──────────────────────────────────────────────────
  /// Star-rating amber — used on lab/pharmacy cards.
  static const Color ratingGold = Color(0xFFF59E0B);

  // Raw semantic shorthands (legacy — prefer the paired tokens above)
  static const Color success = successForeground;
  static const Color danger = dangerForeground;
}
