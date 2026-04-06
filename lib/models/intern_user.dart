// ─── lib/models/intern_user.dart ───────────────────────────────────────────

class InternUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'intern' or 'admin'
  final String department;
  final String batchNo;
  final String phone;
  final DateTime joinDate;
  final String status; // 'active', 'completed', 'inactive'
  final int completedTasks;
  final int totalTasks;

  InternUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.department = '',
    this.batchNo = '',
    this.phone = '',
    required this.joinDate,
    this.status = 'active',
    this.completedTasks = 0,
    this.totalTasks = 0,
  });

  double get progressPercent =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  factory InternUser.fromMap(Map<String, dynamic> map, String uid) {
    return InternUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'intern',
      department: map['department'] ?? '',
      batchNo: map['batchNo'] ?? '',
      phone: map['phone'] ?? '',
      joinDate: map['joinDate'] != null
          ? DateTime.parse(map['joinDate'])
          : DateTime.now(),
      status: map['status'] ?? 'active',
      completedTasks: map['completedTasks'] ?? 0,
      totalTasks: map['totalTasks'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'batchNo': batchNo,
      'phone': phone,
      'joinDate': joinDate.toIso8601String(),
      'status': status,
      'completedTasks': completedTasks,
      'totalTasks': totalTasks,
    };
  }

  InternUser copyWith({
    String? name,
    String? email,
    String? role,
    String? department,
    String? batchNo,
    String? phone,
    DateTime? joinDate,
    String? status,
    int? completedTasks,
    int? totalTasks,
  }) {
    return InternUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      batchNo: batchNo ?? this.batchNo,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      completedTasks: completedTasks ?? this.completedTasks,
      totalTasks: totalTasks ?? this.totalTasks,
    );
  }
}
