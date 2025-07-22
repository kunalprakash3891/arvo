import 'package:flutter/material.dart';
import 'package:arvo/theme/palette.dart';

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: darkColorScheme,

  // Define the default brightness and colors.
  //primarySwatch: Palette.kToDark,

  // Define the default 'TextTheme'. Use this to specify the default
  // text styling for headlines, titles, bodies of text, and more.
  // Display is the largest, down to label which is the smallest.
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: kBaseDarkDisplayTextColour,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: kBaseDarkDisplayTextColour,
      fontWeight: FontWeight.bold,
    ),
    // Use displaySmall for navigation button text.
    displaySmall: TextStyle(
      color: kBaseDarkDisplayTextColour,
      fontWeight: FontWeight.bold,
      fontSize: 24.0,
    ),
    headlineLarge: TextStyle(
      color: kBaseDarkHeadlineTextColour,
      fontWeight: FontWeight.w500,
    ),
    headlineMedium: TextStyle(
      color: kBaseDarkHeadlineTextColour,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: TextStyle(
      color: kBaseDarkHeadlineTextColour,
      fontWeight: FontWeight.w500,
    ),
    // Use title for input text.
    titleLarge: TextStyle(
      color: kBaseDarkTitleTextColour,
    ),
    titleMedium: TextStyle(
      color: kBaseDarkTitleTextColour,
    ),
    titleSmall: TextStyle(
      color: kBaseDarkTitleTextColour,
    ),
    bodyLarge: TextStyle(
      color: kBaseDarkBodyTextColour,
    ),
    bodyMedium: TextStyle(
      color: kBaseDarkBodyTextColour,
    ),
    bodySmall: TextStyle(
      color: kBaseDarkBodyTextColour,
    ),
    labelLarge: TextStyle(
      color: kBaseDarkLabelTextColour,
    ),
    labelMedium: TextStyle(
      color: kBaseDarkLabelTextColour,
    ),
    labelSmall: TextStyle(
      color: kBaseDarkLabelTextColour,
    ),
  ),

  // Define widget themes.
  appBarTheme: const AppBarTheme(
    foregroundColor: kBaseDarkBodyTextColour,
  ),
  buttonTheme: const ButtonThemeData(buttonColor: kBaseDarkColour),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(50.0),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50.0),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  iconTheme: const IconThemeData(color: kBaseDarkColour),
  inputDecorationTheme: const InputDecorationTheme(
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 1.0, color: kBaseDarkBorderColour),
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 2.0, color: kBaseDarkColour),
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 2.0, color: kBaseDarkErrorColour),
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 2.0, color: kBaseDarkErrorColour),
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
  ),
  scaffoldBackgroundColor: kBaseDarkScaffoldColour,
  dividerTheme: const DividerThemeData(
    color: kBaseDarkBorderColour,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: kBaseDarkColour,
  ),
);

// https://www.logicui.com/colorgenerator
// Primary = kBaseOutbackOchre (#D84315), Secondary = kBaseOutbackOchre60 (#F4511E), Tertiary = kBaseOutbackOchre20 (#FF7043), Error = kBaseUluruRed
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE69F89),
  onPrimary: Color(0xFF4C1808),
  primaryContainer: Color(0xFF66200A),
  onPrimaryContainer: Color(0xFFE6B3A4),
  secondary: Color(0xFFE6A18B),
  onSecondary: Color(0xFF4C1909),
  secondaryContainer: Color(0xFF66220C),
  onSecondaryContainer: Color(0xFFE6B5A6),
  tertiary: Color(0xFFE6AC9A),
  onTertiary: Color(0xFF4C2214),
  tertiaryContainer: Color(0xFF662D1B),
  onTertiaryContainer: Color(0xFFE6BDB0),
  error: Color(0xFFE68E8E),
  onError: Color(0xFF4C0B0B),
  errorContainer: Color(0xFF660F0F),
  onErrorContainer: Color(0xFFE6A8A8),
  surface: Color(0xFF333131),
  onSurface: Color(0xFFe6e3e2),
  onSurfaceVariant: Color(0xFFe6d7d3),
  surfaceContainerHighest: Color(0xFF665854),
  outline: Color(0xFFb3a39e),
);
