import 'package:flutter/material.dart';
import 'package:arvo/theme/palette.dart';

/*ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kBaseLightColour,
    primary: kBaseLightColour,
    // Specify light, for light theme.
    brightness: Brightness.light,
  ),

  // Define the default brightness and colors.
  primarySwatch: Palette.kToLight,

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
  //appBarTheme: const AppBarTheme(
  //  foregroundColor: kBaseLightDisplayTextColour,
  //),
  buttonTheme: const ButtonThemeData(buttonColor: kBaseLightColour),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(50.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32.0),
      ),
      elevation: 0,
      backgroundColor: kBaseMonochromaticColour,
    ),
  ),
  iconTheme: const IconThemeData(color: kBaseLightColour),
  inputDecorationTheme: const InputDecorationTheme(
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 1.0, color: kBaseLightBorderColour),
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 2.0, color: kBaseLightColour),
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 2.0, color: kBaseLightErrorColour),
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
);*/

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: lightColorScheme,

  // Define the default brightness and colors.
  //primarySwatch: Palette.kToLight,

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

// https://www.logicui.com/colorgenerator, Primary = 4A187D
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF4A187D),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFC8ABE6),
  onPrimaryContainer: Color(0xFF1E0A33),
  secondary: Color(0xFF625B71),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFDCD8E6),
  onSecondaryContainer: Color(0xFF2C2933),
  tertiary: Color(0xFF7D5260),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFE6CDD5),
  onTertiaryContainer: Color(0xFF332227),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFE6ACA9),
  onErrorContainer: Color(0xFF330B09),
  surface: Color(0xFFfcfbfc),
  onSurface: Color(0xFF323133),
  surfaceContainerHighest: Color(0xFFe0dae6),
  onSurfaceVariant: Color(0xFF5e5566),
  outline: Color(0xFF8c8099),
);
