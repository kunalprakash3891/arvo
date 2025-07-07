import 'package:flutter/material.dart';
import 'package:arvo/theme/palette.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: lightColorScheme,
  // Define the default 'TextTheme'. Use this to specify the default
  // text styling for headlines, titles, bodies of text, and more.
  // Display is the largest, down to label which is the smallest.
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: kBaseLightDisplayTextColour,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: kBaseLightDisplayTextColour,
      fontWeight: FontWeight.bold,
    ),
    // Use displaySmall for navigation button text.
    displaySmall: TextStyle(
      color: kBaseLightDisplayTextColour,
      fontWeight: FontWeight.bold,
      fontSize: 24.0,
    ),
    headlineLarge: TextStyle(
      color: kBaseLightHeadlineTextColour,
      fontWeight: FontWeight.w500,
    ),
    headlineMedium: TextStyle(
      color: kBaseLightHeadlineTextColour,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: TextStyle(
      color: kBaseLightHeadlineTextColour,
      fontWeight: FontWeight.w500,
    ),
    // Use title for input text.
    titleLarge: TextStyle(
      color: kBaseLightTitleTextColour,
    ),
    titleMedium: TextStyle(
      color: kBaseLightTitleTextColour,
    ),
    titleSmall: TextStyle(
      color: kBaseLightTitleTextColour,
    ),
    bodyLarge: TextStyle(
      color: kBaseLightBodyTextColour,
    ),
    bodyMedium: TextStyle(
      color: kBaseLightBodyTextColour,
    ),
    bodySmall: TextStyle(
      color: kBaseLightBodyTextColour,
    ),
    labelLarge: TextStyle(
      color: kBaseLightLabelTextColour,
    ),
    labelMedium: TextStyle(
      color: kBaseLightLabelTextColour,
    ),
    labelSmall: TextStyle(
      color: kBaseLightLabelTextColour,
    ),
  ),

  // Define widget themes.
  appBarTheme: const AppBarTheme(
    foregroundColor: kBaseLightDisplayTextColour,
  ),
  buttonTheme: const ButtonThemeData(buttonColor: kBaseLightColour),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(50.0),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50.0),
    ),
  ),
  iconTheme: const IconThemeData(color: kBaseLightColour),
  inputDecorationTheme: const InputDecorationTheme(
    enabledBorder: OutlineInputBorder(
      //borderSide: BorderSide(width: 1.0, color: kBaseLightBorderColour),
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 2.0, color: kBaseLightColour),
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
    errorBorder: OutlineInputBorder(
      //  borderSide: BorderSide(width: 2.0, color: kBaseLightErrorColour),
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 2.0, color: kBaseLightErrorColour),
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
  ),
  scaffoldBackgroundColor: kBaseLightScaffoldColour,
  dividerTheme: const DividerThemeData(
    color: kBaseLightBorderColour,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: kBaseLightColour,
  ),
);

// https://www.logicui.com/colorgenerator
// Primary = kBaseOutbackOchre (#D84315), Secondary = kBaseOutbackOchre60 (#F4511E), Tertiary = kBaseOutbackOchre20 (#FF7043), Error = kBaseUluruRed
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFD84315),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE6B3A4),
  onPrimaryContainer: Color(0xFF331005),
  secondary: Color(0xFFF4511E),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE6B5A6),
  onSecondaryContainer: Color(0xFF331106),
  tertiary: Color(0xFFFF7043),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFE6BDB0),
  onTertiaryContainer: Color(0xFF33160D),
  error: Color(0xFFB71C1C),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFE6A8A8),
  onErrorContainer: Color(0xFF330808),
  surface: Color(0xFFfcfcfb),
  onSurface: Color(0xFF333131),
  onSurfaceVariant: Color(0xFF665854),
  surfaceContainerHighest: Color(0xFFe6dbd8),
  outline: Color(0xFF99847d),
);
