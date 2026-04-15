// ─── lib/screens/auth/splash_screen.dart ──────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../utils/responsive.dart';
import '../intern/intern_dashboard.dart';
import '../admin/admin_dashboard.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6)));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _navigate(const LoginScreen());
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;
    final role = doc.data()?['role'] ?? 'intern';

    if (role == 'admin') {
      _navigate(const AdminDashboard());
    } else {
      _navigate(InternDashboard(uid: user.uid));
    }
  }

  void _navigate(Widget screen) {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = ResponsiveHelper.fontSize(context,
        mobileSize: 90, tabletSize: 110, desktopSize: 130);
    final logoIconSize = ResponsiveHelper.fontSize(context,
        mobileSize: 46, tabletSize: 56, desktopSize: 66);
    final gapSize = ResponsiveHelper.hp(context, 3);
    final loaderSize = ResponsiveHelper.fontSize(context,
        mobileSize: 32, tabletSize: 40, desktopSize: 48);

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accent, Color(0xFF00897B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(logoSize * 0.3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withOpacity(0.45),
                            blurRadius: 32,
                            spreadRadius: 4,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'I',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: logoIconSize,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: gapSize),
                    ResponsiveText(
                      'internee.pk',
                      mobileSize: 26,
                      tabletSize: 30,
                      desktopSize: 36,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: gapSize * 0.3),
                    ResponsiveText(
                      'Intern Management System',
                      mobileSize: 12,
                      tabletSize: 13,
                      desktopSize: 14,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: gapSize * 2.4),
                    SizedBox(
                      width: loaderSize,
                      height: loaderSize,
                      child: const CircularProgressIndicator(
                        color: AppTheme.accent,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
