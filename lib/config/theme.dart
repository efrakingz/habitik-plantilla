import 'package:flutter/material.dart';

class AppTheme {
  static const green700 = Color(0xFF2E7D32);
  static const green600 = Color(0xFF43A047);
  static const green500 = Color(0xFF66BB6A);
  static const green400 = Color(0xFF66BB6A);
  static const green300 = Color(0xFF81C784);
  static const green200 = Color(0xFFA5D6A7);
  static const green100 = Color(0xFFC8E6C9);
  static const green50 = Color(0xFFE8F5E9);
  static const amber400 = Color(0xFFFFCA28);
  static const amber500 = Color(0xFFFFC107);
  static const blue700 = Color(0xFF1565C0);
  static const red700 = Color(0xFFC62828);
  static const purple700 = Color(0xFF7B1FA2);
  static const textDark = Color(0xFF1B5E20);
  static const textLight = Color(0xFF81C784);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: green700,
      primary: green700,
      secondary: amber400,
    ),
    scaffoldBackgroundColor: green100,
    appBarTheme: const AppBarTheme(
      backgroundColor: green700,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
