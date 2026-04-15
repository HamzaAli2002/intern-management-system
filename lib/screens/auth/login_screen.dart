// ─── lib/screens/auth/login_screen.dart ───────────────────────────────────

import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../intern/intern_dashboard.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();

  bool _obscurePass = true;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final result = await _authService.signIn(
      _emailCtrl.text,
      _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (result.role == 'admin') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => InternDashboard(uid: result.user!.uid)));
      }
    } else {
      setState(() => _errorMsg = result.error);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = 'Enter your email first to reset password.');
      return;
    }
    final error = await _authService.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Password reset email sent to $email'),
      backgroundColor: error != null ? Colors.red : AppTheme.accent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final screenHeight = ResponsiveHelper.screenHeight(context);
    final screenWidth = ResponsiveHelper.screenWidth(context);

    // Responsive dimensions
    final maxFormWidth = isMobile ? screenWidth * 0.9 : 520.0;
    double headerHeight;
    if (isMobile) {
      headerHeight = screenHeight * 0.25;
    } else if (isTablet) {
      headerHeight = 260.0;
    } else {
      headerHeight = 240.0;
    }

    final logoSize = isMobile ? 60.0 : 72.0;
    final titleSize = ResponsiveHelper.fontSize(context,
        mobileSize: 20, tabletSize: 24, desktopSize: 26);
    final subtitleSize =
        ResponsiveHelper.fontSize(context, mobileSize: 12, tabletSize: 13);
    final cardPadding = ResponsiveHelper.paddingSymmetric(context,
        mobileH: 20, mobileV: 24, tabletH: 28, desktopH: 32);
    final cardMargin = ResponsiveHelper.paddingSymmetric(context,
        mobileH: 16, mobileV: 12, tabletH: 20, tabletV: 16);
    final gapSize = isMobile ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxFormWidth),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Responsive Header ──
                  SizedBox(
                    height: headerHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _WavePainter()),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.accent,
                                      Color(0xFF00897B)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(logoSize * 0.25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accent.withOpacity(0.4),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text('I',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: logoSize * 0.5,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      )),
                                ),
                              ),
                              SizedBox(height: gapSize * 0.7),
                              Text(
                                'internee.pk',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: gapSize * 0.3),
                              Text(
                                'Intern Management System',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: subtitleSize,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Form Card ──
                  Container(
                    margin: cardMargin,
                    padding: cardPadding,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.15),
                          blurRadius: 40,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ResponsiveText(
                            'Welcome Back 👋',
                            mobileSize: 20,
                            tabletSize: 22,
                            desktopSize: 24,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          SizedBox(height: gapSize * 0.4),
                          ResponsiveText(
                            'Sign in to your account',
                            mobileSize: 13,
                            tabletSize: 14,
                            style: const TextStyle(color: AppTheme.textMid),
                          ),
                          SizedBox(height: gapSize * 1.5),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: AppTheme.accent),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Email is required';
                              if (!v.contains('@'))
                                return 'Enter a valid email';
                              return null;
                            },
                          ),
                          SizedBox(height: gapSize),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: AppTheme.accent),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.textLight,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Password is required';
                              if (v.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                          SizedBox(height: gapSize * 0.5),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          // Error message
                          if (_errorMsg != null) ...[
                            SizedBox(height: gapSize * 0.5),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 18),
                                  SizedBox(width: gapSize * 0.5),
                                  Expanded(
                                    child: ResponsiveText(
                                      _errorMsg!,
                                      mobileSize: 12,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: gapSize * 1.2),

                          // Login Button
                          SizedBox(
                            height: isMobile ? 48 : 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : ResponsiveText(
                                      'Sign In',
                                      mobileSize: 14,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),

                          SizedBox(height: gapSize),

                          // Demo hint
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ResponsiveText(
                              '💡 Admin accounts are created directly in Firebase.\n'
                              'Intern accounts are added by the Admin panel.',
                              mobileSize: 11,
                              tabletSize: 12,
                              style: const TextStyle(color: AppTheme.textMid),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.45,
          size.width * 0.5, size.height * 0.6)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.75, size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
