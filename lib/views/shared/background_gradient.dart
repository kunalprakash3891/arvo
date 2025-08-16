import 'package:app_base/theming/theme.dart';
import 'package:arvo/theme/palette.dart';
import 'package:flutter/material.dart';

const darkModeBackgroundGradient = [
  kBaseOutbackNight,
  kBaseBushGrey,
  kBaseOutbackOchre,
  kBaseCoralSunset,
];

const lightModeBackgroundGradient = [
  kBaseOceanBlue,
  kBaseCoastalTeal,
  kBaseOutbackOchre,
  kBaseCoralSunset,
];

List<Color> getBackgroundGradientColours(
    int selectedTheme, BuildContext context) {
  final themeMode = themeModeMap.keys.firstWhere(
      (theme) => themeModeMap[theme] == selectedTheme,
      orElse: () => ThemeMode.light);

  switch (themeMode) {
    case ThemeMode.light:
      return lightModeBackgroundGradient;
    case ThemeMode.dark:
      return darkModeBackgroundGradient;
    default:
      return MediaQuery.of(context).platformBrightness == Brightness.light
          ? lightModeBackgroundGradient
          : darkModeBackgroundGradient;
  }
}
