import 'package:flutter/material.dart';

class AppColors {
  static const Color charcoal = Color(0xFF1E1E1E); // Fundo
  static const Color cardDark = Color(0xFF2C2C2C); // Cards
  static const Color gold = Color(0xFFC5A059); // Primária/Acentos
  static const Color green = Color(0xFF2ECC71); // Sucesso
  static const Color white = Color(0xFFF5F5F5); // Texto
  static const Color grey = Color(0xFF9E9E9E); // Texto secundário
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.charcoal,
      primaryColor: AppColors.gold,
      colorScheme: ColorScheme.dark(
        primary: AppColors.gold,
        surface: AppColors.cardDark,
        onSurface: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        hintStyle: const TextStyle(color: AppColors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.charcoal, // Texto preto no botão dourado
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
