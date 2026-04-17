// ─── lib/screens/admin/assign_task_screen.dart ────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../main.dart';
import '../../utils/responsive.dart';
import '../../models/intern_user.dart';
import '../../models/task_model.dart';
import '../../services/firestore_service.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});
  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirestoreService();
  bool _isLoading = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String? _selectedInternUid;
  String? _selectedInternName;
  String _priority = 'medium';
  String _category = 'General';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  final _categories = ['General','Flutter','Firebase','UI Design','Testing','Documentation','Research'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _assignTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInternUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an intern'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);

    final task = TaskModel(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      assignedTo: _selectedInternUid!,
      assignedToName: _selectedInternName!,
      assignedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
      dueDate: _dueDate,
      createdAt: DateTime.now(),
      status: 'pending',
      priority: _priority,
      category: _category,
    );

    await _db.createTask(task);
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Task assigned successfully!'),
      backgroundColor: AppTheme.accent,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Assign New Task')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: R.maxW),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Task Details ──
                    _sectionHeader('Task Details', Icons.task_outlined),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        prefixIcon: Icon(Icons.title_rounded, color: AppTheme.accent),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Task title is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Task Description',
                        prefixIcon: Icon(Icons.description_outlined, color: AppTheme.accent),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Configuration ──
                    _sectionHeader('Configuration', Icons.settings_outlined),
                    const SizedBox(height: 14),

                    // Priority
                    const Text('Priority',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textMid)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['low', 'medium', 'high'].map((p) {
                        final colors = {'low': Colors.green, 'medium': Colors.orange, 'high': Colors.red};
                        final selected = _priority == p;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _priority = p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: selected ? colors[p]! : colors[p]!.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(p.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: selected ? Colors.white : colors[p],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined, color: AppTheme.accent),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 14),

                    // Due Date
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_outlined, color: AppTheme.accent, size: 20),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Due Date',
                                style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                            Text(DateFormat('MMMM dd, yyyy').format(_dueDate),
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                          ]),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textLight, size: 14),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Assign To ──
                    _sectionHeader('Assign To', Icons.person_search_outlined),
                    const SizedBox(height: 14),
                    StreamBuilder<List<InternUser>>(
                      stream: _db.getAllInterns(),
                      builder: (ctx, snap) {
                        final interns = snap.data ?? [];
                        if (interns.isEmpty) {
                          return const Center(child: Text('No interns available',
                              style: TextStyle(color: AppTheme.textLight)));
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedInternUid,
                          decoration: const InputDecoration(
                            labelText: 'Select Intern',
                            prefixIcon: Icon(Icons.person_outline, color: AppTheme.accent),
                          ),
                          items: interns.map((i) => DropdownMenuItem(
                              value: i.uid,
                              child: Text('${i.name} — ${i.department}'))).toList(),
                          onChanged: (uid) {
                            final intern = interns.firstWhere((i) => i.uid == uid);
                            setState(() {
                              _selectedInternUid = uid;
                              _selectedInternName = intern.name;
                            });
                          },
                          validator: (v) => v == null ? 'Please select an intern' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _assignTask,
                        icon: _isLoading
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded),
                        label: const Text('Assign Task'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Row(children: [
    Icon(icon, color: AppTheme.accent, size: 18),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
  ]);
}
