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
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50.0),
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

// https://www.logicui.com/colorgenerator, Primary = 4A187D
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFBB92E6),
  onPrimary: Color(0xFF2D0F4C),
  primaryContainer: Color(0xFF3C1366),
  onPrimaryContainer: Color(0xFFC8ABE6),
  secondary: Color(0xFFD8D2E6),
  onSecondary: Color(0xFF433E4C),
  secondaryContainer: Color(0xFF595366),
  onSecondaryContainer: Color(0xFFDCD8E6),
  tertiary: Color(0xFFE6C3CE),
  onTertiary: Color(0xFF4C323B),
  tertiaryContainer: Color(0xFF66434F),
  onTertiaryContainer: Color(0xFFE6CDD5),
  error: Color(0xFFE69490),
  onError: Color(0xFF4C100D),
  errorContainer: Color(0xFF661511),
  onErrorContainer: Color(0xFFE6ACA9),
  surface: Color(0xFF323133),
  onSurface: Color(0xFFe4e3e6),
  surfaceContainerHighest: Color(0xFF5e5566),
  onSurfaceVariant: Color(0xFFddd5e6),
  outline: Color(0xFFa9a0b3),
);
