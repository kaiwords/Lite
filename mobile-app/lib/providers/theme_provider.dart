import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_store.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(super.initial);

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final saved = LocalStore.instance.loadThemeMode();
  final initial = ThemeMode.values.firstWhere(
    (m) => m.name == saved,
    orElse: () => ThemeMode.system,
  );
  final notifier = ThemeModeNotifier(initial);
  notifier.addListener((m) => LocalStore.instance.saveThemeMode(m.name),
      fireImmediately: false);
  return notifier;
});
