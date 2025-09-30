import 'package:flutter/material.dart';

/// Category-based theming aligned with the customer app
/// Keys we use across the app: fashion, food, cosmetics, pharmacy, grocery
class CategoryTheme {
  static const String fashion = 'fashion';
  static const String food = 'food';
  static const String cosmetics = 'cosmetics';
  static const String pharmacy = 'pharmacy';
  static const String grocery = 'grocery';

  // Background colors
  static const Map<String, Color> background = {
    fashion: Color(0xFFFCE4EC), // LightModeColors.fashionPink
    food: Color(0xFFFFF3E0), // close to Colors.orange.shade50
    cosmetics: Color(0xFFF3E5F5), // LightModeColors.cosmeticsPurple
    grocery: Color(0xFFE8F5E8), // LightModeColors.groceryGreen
    pharmacy: Color(0xFFE3F2FD), // LightModeColors.pharmacyBlue
  };

  // Accent/dark colors
  static const Map<String, Color> accent = {
    fashion: Color(0xFFE91E63), // LightModeColors.fashionPinkDark
    food: Color(0xFFF57C00), // Colors.orange.shade700
    cosmetics: Color(0xFF9C27B0), // LightModeColors.cosmeticsPurpleDark
    grocery: Color(0xFF4CAF50), // LightModeColors.groceryGreenDark
    pharmacy: Color(0xFF2196F3), // LightModeColors.pharmacyBlueDark
  };

  static Color bg(String key) => background[key] ?? Colors.grey.withValues(alpha: 0.1);
  static Color ac(String key) => accent[key] ?? Colors.blue;
}
