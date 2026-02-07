import 'package:flutter/material.dart';

class AppTheme {
  static const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4F46E5),
    onPrimary: Colors.white,
    secondary: Color(0xFF06B6D4),
    onSecondary: Colors.white,
    error: Color(0xFFDC2626),
    onError: Colors.white,
    surface: Color(0xFFF7F7FB),
    onSurface: Color(0xFF111827),
    tertiary: Color(0xFFF59E0B),
    onTertiary: Color(0xFF111827),
  );

  static BorderRadius get radiusXL => BorderRadius.circular(28);
  static BorderRadius get radiusL => BorderRadius.circular(22);

  static List<BoxShadow> get softShadow => const [
    BoxShadow(
      blurRadius: 28,
      spreadRadius: 0,
      offset: Offset(0, 12),
      color: Color(0x14000000),
    ),
  ];
}
