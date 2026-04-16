// ─── lib/screens/admin/add_intern_screen.dart ─────────────────────────────

import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/auth_service.dart';

class AddInternScreen extends StatefulWidget {
  const AddInternScreen({super.key});

  @override
  State<AddInternScreen> createState() => _AddInternScreenState();
}

class _AddInternScreenState extends State<AddInternScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  String _selectedDept = 'Flutter';
  bool _obscurePass = true;

  final _departments = [
    'Flutter',
    'React',
    'Python',
    'AI/ML',
    'Backend',
    'UI/UX',
    'Full Stack'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    final result = await _auth.registerIntern(
      email: email,
      password: password,
      name: name,
      department: _selectedDept,
      batchNo: _batchCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      // Show success dialog with intern credentials
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppTheme.accent, size: 28),
              SizedBox(width: 10),
              Text('Intern Registered!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share these login credentials with the intern:',
                  style: TextStyle(color: AppTheme.textMid, fontSize: 13)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _credRow('Name', name),
                    const SizedBox(height: 6),
                    _credRow('Email', email),
                    const SizedBox(height: 6),
                    _credRow('Password', password),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } else {
      // Show error in a dialog so it's clearly visible
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red, size: 26),
              SizedBox(width: 10),
              Text('Registration Failed'),
            ],
          ),
          content: Text(result.error ?? 'An unknown error occurred.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _credRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Add New Intern')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionHeader(
                    'Personal Information', Icons.person_outline_rounded),
                const SizedBox(height: 14),
                _field(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Full name is required' : null,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Email is required';
                    if (!v!.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 24),
                _sectionHeader(
                    'Internship Details', Icons.work_outline_rounded),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedDept,
                  decoration: const InputDecoration(
                    labelText: 'Department / Track',
                    prefixIcon:
                        Icon(Icons.category_outlined, color: AppTheme.accent),
                  ),
                  items: _departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDept = v!),
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _batchCtrl,
                  label: 'Batch No. (e.g. Batch-12)',
                  icon: Icons.group_outlined,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Batch number is required' : null,
                ),
                const SizedBox(height: 24),
                _sectionHeader('Login Credentials', Icons.security_outlined),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: AppTheme.accent),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Password is required';
                    if (v!.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '🔐 Share these credentials with the intern so they can log in.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMid),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _register,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.person_add_rounded),
                    label: const Text('Register Intern'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.accent),
      ),
      validator: validator,
    );
  }
}
