import 'package:flutter/material.dart';

class AppTheme {
  // Ultra-Premium Coral/Sunset & Crisp Canvas Color Palette (matching UI design)
  static const Color background = Color(0xFFF3F4F7);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color darkCharcoal = Color(0xFF1E2124);
  static const Color darkPill = Color(0xFF282B30);
  
  // Sunset Mesh Gradients
  static const Color coralPrimary = Color(0xFFFF5722);
  static const Color coralLight = Color(0xFFFF8A65);
  static const Color sunsetOrange = Color(0xFFFF7043);
  static const Color amberWarm = Color(0xFFFFA726);

  static const LinearGradient sunsetMesh = LinearGradient(
    colors: [
      Color(0xFFFF5252),
      Color(0xFFFF7043),
      Color(0xFFFFA726),
      Color(0xFFFF8A65),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 0.8, 1.0],
  );

  static const LinearGradient coralCardGradient = LinearGradient(
    colors: [
      Color(0xFFEE5A24),
      Color(0xFFF79F1F),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft Pastel Category Tags (from design)
  static const Color pastelPeach = Color(0xFFFFECE5);
  static const Color pastelPeachText = Color(0xFFE65100);

  static const Color pastelTeal = Color(0xFFE0F2F1);
  static const Color pastelTealText = Color(0xFF00796B);

  static const Color pastelPurple = Color(0xFFEDE7F6);
  static const Color pastelPurpleText = Color(0xFF5E35B1);

  static const Color pastelBlue = Color(0xFFE3F2FD);
  static const Color pastelBlueText = Color(0xFF1565C0);
  static const Color softAmber = Color(0xFFF59E0B);
  // Workspaces Accent Colors
  static const Color colorPersonal = Color(0xFF2563EB); // Deep Blue
  static const Color colorBems = Color(0xFF059669);     // Emerald COO
  static const Color colorHenovate = Color(0xFF7C3AED); // Founder Violet

  // Neutral tones
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color dividerColor = Color(0xFFF3F4F6);

  // Aliases for unified reference UI system & backward compatibility
  static const Color creamCanvas = background;
  static const Color offWhiteBg = Color(0xFFF3F4F7);
  static const Color peachPillBg = pastelPeach;
  static const Color sereneTeal = Color(0xFF0D9488);
  static const Color slateNavy = textPrimary;
  static const Color mutedGray = textSecondary;
  static const Color gentleRose = Color(0xFFE11D48);

  static const LinearGradient coralMeshGradient = sunsetMesh;

  static final BoxDecoration floatingCardDecoration = BoxDecoration(
    color: surfaceCard,
    borderRadius: BorderRadius.circular(24),
    boxShadow: softCardShadow,
  );

  // Modern Soft Diffusion Shadows
  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> heroFloatShadow = [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 30,
      offset: Offset(0, 14),
      spreadRadius: -2,
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: coralPrimary,
        brightness: Brightness.light,
        surface: surfaceCard,
        primary: coralPrimary,
      ),
      fontFamily: 'Inter',
      cardTheme: const CardTheme(
        color: surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: darkCharcoal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: coralPrimary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme; // Defaulting to the reference light design
}
