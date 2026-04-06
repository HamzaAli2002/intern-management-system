// ─── lib/models/task_model.dart ────────────────────────────────────────────

class TaskSubmissionLink {
  final String type; // 'github', 'linkedin', 'other'
  final String url;
  final String label; // display label

  TaskSubmissionLink({
    required this.type,
    required this.url,
    required this.label,
  });

  factory TaskSubmissionLink.fromMap(Map<String, dynamic> map) =>
      TaskSubmissionLink(
        type: map['type'] ?? 'other',
        url: map['url'] ?? '',
        label: map['label'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'type': type,
        'url': url,
        'label': label,
      };

  bool get isGitHub => type == 'github';
  bool get isLinkedIn => type == 'linkedin';
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedTo;
  final String assignedToName;
  final String assignedBy;
  final DateTime dueDate;
  final DateTime createdAt;
  final String status; // 'pending','in_progress','submitted','completed'
  final String priority;
  final String category;
  final String? submissionNote;
  final List<TaskSubmissionLink> links; // GitHub / LinkedIn / other URLs
  final List<String> attachments; // File paths or URLs
  final DateTime? completedAt;
  final DateTime? submittedAt;
  // Admin review
  final String? adminRemark;
  final String? adminReviewStatus; // 'approved','needs_revision','rejected'
  final DateTime? reviewedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedToName,
    required this.assignedBy,
    required this.dueDate,
    required this.createdAt,
    this.status = 'pending',
    this.priority = 'medium',
    this.category = 'General',
    this.submissionNote,
    this.links = const [],
    this.attachments = const [],
    this.completedAt,
    this.submittedAt,
    this.adminRemark,
    this.adminReviewStatus,
    this.reviewedAt,
  });

  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) &&
      status != 'completed' &&
      status != 'submitted';

  bool get hasReview => adminRemark != null && adminRemark!.isNotEmpty;

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    final rawLinks = map['links'] as List<dynamic>? ?? [];
    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      assignedToName: map['assignedToName'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : DateTime.now().add(const Duration(days: 7)),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 'medium',
      category: map['category'] ?? 'General',
      submissionNote: map['submissionNote'],
      links: rawLinks
          .map((l) => TaskSubmissionLink.fromMap(Map<String, dynamic>.from(l)))
          .toList(),
      attachments:
          List<String>.from(map['attachments'] as List<dynamic>? ?? []),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      submittedAt: map['submittedAt'] != null
          ? DateTime.parse(map['submittedAt'])
          : null,
      adminRemark: map['adminRemark'],
      adminReviewStatus: map['adminReviewStatus'],
      reviewedAt:
          map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'assignedToName': assignedToName,
        'assignedBy': assignedBy,
        'dueDate': dueDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'priority': priority,
        'category': category,
        'submissionNote': submissionNote,
        'links': links.map((l) => l.toMap()).toList(),
        'attachments': attachments,
        'completedAt': completedAt?.toIso8601String(),
        'submittedAt': submittedAt?.toIso8601String(),
        'adminRemark': adminRemark,
        'adminReviewStatus': adminReviewStatus,
        'reviewedAt': reviewedAt?.toIso8601String(),
      };

  TaskModel copyWith({
    String? title,
    String? description,
    String? assignedTo,
    String? assignedToName,
    String? assignedBy,
    DateTime? dueDate,
    String? status,
    String? priority,
    String? category,
    String? submissionNote,
    List<TaskSubmissionLink>? links,
    List<String>? attachments,
    DateTime? completedAt,
    DateTime? submittedAt,
    String? adminRemark,
    String? adminReviewStatus,
    DateTime? reviewedAt,
  }) =>
      TaskModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        assignedTo: assignedTo ?? this.assignedTo,
        assignedToName: assignedToName ?? this.assignedToName,
        assignedBy: assignedBy ?? this.assignedBy,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        submissionNote: submissionNote ?? this.submissionNote,
        links: links ?? this.links,
        attachments: attachments ?? this.attachments,
        completedAt: completedAt ?? this.completedAt,
        submittedAt: submittedAt ?? this.submittedAt,
        adminRemark: adminRemark ?? this.adminRemark,
        adminReviewStatus: adminReviewStatus ?? this.adminReviewStatus,
        reviewedAt: reviewedAt ?? this.reviewedAt,
      );
}
