import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xff4e5053),
      muted = Color(0xff686c71),
      hint = Color(0xffb8bbc0);
  static const purple = Color(0xffbd43da),
      pink = Color(0xffce52bf),
      coral = Color(0xffff6579),
      cyan = Color(0xff4ec5d6);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, purple],
  );
  static const shadow = [
    BoxShadow(color: Color(0x1f686c71), offset: Offset(0, 9), blurRadius: 25),
  ];
}

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Poppins',
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    primary: AppColors.purple,
    surface: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 14, height: 1.65, color: AppColors.muted),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.ink),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    labelStyle: TextStyle(color: AppColors.muted, fontSize: 14),
    hintStyle: TextStyle(color: AppColors.hint, fontSize: 14),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xffd9dadd)),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.purple, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(vertical: 15),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xffededf0), thickness: 1),
  snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
);
