import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intern_management/screens/auth/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait on phones; allow landscape on tablets
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const InternManagementApp());
}

class InternManagementApp extends StatelessWidget {
  const InternManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMS — Internee.pk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

// ── Responsive Helper ──────────────────────────────────────────────────────
class Responsive {
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600;
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 900;
  static double hp(BuildContext ctx, double pct) =>
      MediaQuery.of(ctx).size.height * pct;
  static double wp(BuildContext ctx, double pct) =>
      MediaQuery.of(ctx).size.width * pct;
  static double fontSize(BuildContext ctx, double base) =>
      isTablet(ctx) ? base * 1.15 : base;
}

// ── App Theme ──────────────────────────────────────────────────────────────
class AppTheme {
  // Brand: Internee.pk navy + teal
  static const Color primary      = Color(0xFF0D1B2A);
  static const Color accent       = Color(0xFF00BFA6);
  static const Color accentOrange = Color(0xFFFF6E40);
  static const Color surface      = Color(0xFFF4F7FB);
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color textDark     = Color(0xFF0D1B2A);
  static const Color textMid      = Color(0xFF4A5568);
  static const Color textLight    = Color(0xFF9AA5B4);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: surface,
    ),
    scaffoldBackgroundColor: surface,
    // No custom fontFamily — avoids blank screen on web from missing font assets
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle:
          const TextStyle(color: textMid, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      shadowColor: primary.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EDF2)),
      ),
    ),
  );
}

