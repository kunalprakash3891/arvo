import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  ValueNotifier<ThemeMode> selectedTheme = ValueNotifier(ThemeMode.system);

  void updateTheme(ThemeMode themeMode) {
    selectedTheme.value = themeMode;
    emit(themeMode);
  }

  // This handles the restoration of the theme mode when the app is restarted.
  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    final theme = json['themeMode'];

    switch (theme) {
      case 'ThemeMode.system':
        selectedTheme.value = ThemeMode.system;
      case 'ThemeMode.light':
        selectedTheme.value = ThemeMode.system;
      case 'ThemeMode.dark':
        selectedTheme.value = ThemeMode.system;
    }
    return selectedTheme.value;
  }

  // This stores the ThemeMode anytime its changed
  @override
  Map<String, dynamic>? toJson(ThemeMode state) {
    return {
      'themeMode': state.toString(),
    };
  }
}
