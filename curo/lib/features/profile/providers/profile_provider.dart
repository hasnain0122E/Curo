import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.initials,
    required this.mediPoints,
    required this.reportsCount,
    required this.testsBooked,
  });

  final String name;
  final String initials;
  final int mediPoints;
  final int reportsCount;
  final int testsBooked;
}

final userProfileProvider = Provider<UserProfile>(
  (_) => const UserProfile(
    name: 'Ali Khan',
    initials: 'AK',
    mediPoints: 240,
    reportsCount: 12,
    testsBooked: 5,
  ),
);

// ── Language ──────────────────────────────────────────────────────────────────

class LanguageNotifier extends Notifier<Locale> {
  LanguageNotifier([this._initial = const Locale('en')]);
  final Locale _initial;

  @override
  Locale build() => _initial;

  Future<void> setLanguage(String code) async {
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, Locale>(
  LanguageNotifier.new,
);
