import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
