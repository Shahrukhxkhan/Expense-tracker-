import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemeMode {
  light,
  dark,
  amoled,
}

enum AccentColorPreset {
  indigo(Color(0xFF6366F1), 'Indigo'),
  emerald(Color(0xFF10B981), 'Emerald'),
  sky(Color(0xFF0EA5E9), 'Sky Blue'),
  purple(Color(0xFF8B5CF6), 'Royal Violet'),
  rose(Color(0xFFF43F5E), 'Crimson Rose'),
  amber(Color(0xFFF59E0B), 'Sunset Amber');

  final Color color;
  final String label;
  const AccentColorPreset(this.color, this.label);
}

class ThemeSettingsState {
  final AppThemeMode themeMode;
  final AccentColorPreset accentColor;
  final bool dynamicColors;

  const ThemeSettingsState({
    this.themeMode = AppThemeMode.light,
    this.accentColor = AccentColorPreset.indigo,
    this.dynamicColors = false,
  });

  ThemeSettingsState copyWith({
    AppThemeMode? themeMode,
    AccentColorPreset? accentColor,
    bool? dynamicColors,
  }) {
    return ThemeSettingsState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      dynamicColors: dynamicColors ?? this.dynamicColors,
    );
  }
}

class ThemeSettingsNotifier extends StateNotifier<ThemeSettingsState> {
  ThemeSettingsNotifier() : super(const ThemeSettingsState());

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setAccentColor(AccentColorPreset accent) {
    state = state.copyWith(accentColor: accent);
  }

  void toggleDynamicColors(bool enabled) {
    state = state.copyWith(dynamicColors: enabled);
  }

  void cycleThemeMode() {
    final next = switch (state.themeMode) {
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.amoled,
      AppThemeMode.amoled => AppThemeMode.light,
    };
    state = state.copyWith(themeMode: next);
  }
}

final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettingsState>(
  (ref) => ThemeSettingsNotifier(),
);
