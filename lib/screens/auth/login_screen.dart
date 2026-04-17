// ─── lib/screens/auth/login_screen.dart ───────────────────────────────────

import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
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
    setState(() { _isLoading = true; _errorMsg = null; });
    final result = await _authService.signIn(_emailCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isSuccess) {
      if (result.role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InternDashboard(uid: result.user!.uid)));
      }
    } else {
      setState(() => _errorMsg = result.error);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) { setState(() => _errorMsg = 'Enter your email first.'); return; }
    final error = await _authService.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Password reset email sent to $email'),
      backgroundColor: error != null ? Colors.red : AppTheme.accent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      // Full-width dark background — no gaps on sides
      backgroundColor: AppTheme.primary,
      body: SizedBox(
        width: sw,
        height: sh,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header — full width ──
              SizedBox(
                width: sw,
                height: sh * 0.32,
                child: Stack(fit: StackFit.expand, children: [
                  CustomPaint(painter: _WavePainter()),
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68, height: 68,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.accent, Color(0xFF00897B)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(
                                color: AppTheme.accent.withOpacity(0.4),
                                blurRadius: 20, spreadRadius: 2,
                              )],
                            ),
                            child: const Center(child: Text('I',
                                style: TextStyle(color: Colors.white, fontSize: 34,
                                    fontWeight: FontWeight.w800, height: 1))),
                          ),
                          const SizedBox(height: 12),
                          const Text('internee.pk',
                              style: TextStyle(color: Colors.white, fontSize: 24,
                                  fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                          const SizedBox(height: 4),
                          Text('Intern Management System',
                              style: TextStyle(color: Colors.white.withOpacity(0.5),
                                  fontSize: 12, letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),

              // ── Form card — centered with max width ──
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: sw < 520 ? 16 : 0,
                      vertical: 0,
                    ),
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(
                        color: AppTheme.primary.withOpacity(0.2),
                        blurRadius: 40, offset: const Offset(0, 12),
                      )],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Welcome Back 👋',
                              style: TextStyle(fontSize: 22,
                                  fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                          const SizedBox(height: 4),
                          const Text('Sign in to your account',
                              style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
                          const SizedBox(height: 28),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.accent),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _isLoading ? null : _login(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.accent),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppTheme.textLight,
                                ),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: const Text('Forgot Password?',
                                  style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w500)),
                            ),
                          ),

                          if (_errorMsg != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 17),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMsg!,
                                    style: const TextStyle(color: Colors.red, fontSize: 13))),
                              ]),
                            ),
                          ],

                          const SizedBox(height: 22),

                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(height: 18),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '💡 Admin accounts are created directly in Firebase.\nIntern accounts are added by the Admin panel.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMid),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.04)..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.42, size.width * 0.5, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.68, size.width, size.height * 0.52)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}
