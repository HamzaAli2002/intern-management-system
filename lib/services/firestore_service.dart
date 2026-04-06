// ─── lib/services/firestore_service.dart ──────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/intern_user.dart';
import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── INTERNS ──────────────────────────────────────────────────────────────

  Stream<List<InternUser>> getAllInterns() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'intern')
        .orderBy('joinDate', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => InternUser.fromMap(d.data(), d.id)).toList());
  }

  Future<InternUser?> getInternById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return InternUser.fromMap(doc.data()!, uid);
  }

  Stream<InternUser?> streamInternById(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InternUser.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> updateInternProfile(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  Future<void> updateInternStatus(String uid, String status) =>
      _db.collection('users').doc(uid).update({'status': status});

  Future<void> deleteIntern(String uid) async {
    await _db.collection('users').doc(uid).delete();
    final tasks =
        await _db.collection('tasks').where('assignedTo', isEqualTo: uid).get();
    for (var doc in tasks.docs) {
      await doc.reference.delete();
    }
  }

  Future<Map<String, int>> getInternStats() async {
    final snap =
        await _db.collection('users').where('role', isEqualTo: 'intern').get();
    int active = 0, completed = 0, inactive = 0;
    for (var doc in snap.docs) {
      final s = doc.data()['status'] ?? 'active';
      if (s == 'active')
        active++;
      else if (s == 'completed')
        completed++;
      else
        inactive++;
    }
    return {'active': active, 'completed': completed, 'inactive': inactive};
  }

  // ── TASKS ─────────────────────────────────────────────────────────────────

  Future<String> createTask(TaskModel task) async {
    final ref = await _db.collection('tasks').add(task.toMap());
    await _db.collection('users').doc(task.assignedTo).update({
      'totalTasks': FieldValue.increment(1),
    });
    return ref.id;
  }

  Stream<List<TaskModel>> getTasksForIntern(String uid) {
    return _db
        .collection('tasks')
        .where('assignedTo', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList());
  }

  // Stream a single task (for real-time updates on detail screen)
  Stream<TaskModel?> streamTask(String taskId) {
    return _db.collection('tasks').doc(taskId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TaskModel.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<List<TaskModel>> getAllTasks() {
    return _db
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList());
  }

  // Stream tasks pending admin review
  // NOTE: No orderBy here — avoids requiring a composite index on free plan.
  // We sort client-side in the widget instead.
  Stream<List<TaskModel>> getSubmittedTasksForReview() {
    return _db
        .collection('tasks')
        .where('status', isEqualTo: 'submitted')
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
      // Sort by submittedAt descending (newest first)
      list.sort((a, b) {
        final at = a.submittedAt;
        final bt = b.submittedAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  // ── Intern submits task with GitHub/LinkedIn links ────────────────────────
  Future<void> submitTask({
    required String taskId,
    required String internUid,
    String? submissionNote,
    List<TaskSubmissionLink>? links,
  }) async {
    final data = <String, dynamic>{
      'status': 'submitted',
      'submittedAt': DateTime.now().toIso8601String(),
    };
    if (submissionNote != null && submissionNote.isNotEmpty) {
      data['submissionNote'] = submissionNote;
    }
    if (links != null && links.isNotEmpty) {
      data['links'] = links.map((l) => l.toMap()).toList();
    }
    await _db.collection('tasks').doc(taskId).update(data);
  }

  // ── Intern edits and re-submits after needs_revision ─────────────────────
  Future<void> resubmitTask({
    required String taskId,
    String? submissionNote,
    List<TaskSubmissionLink>? links,
  }) async {
    final data = <String, dynamic>{
      'status': 'submitted',
      'submittedAt': DateTime.now().toIso8601String(),
      'adminRemark': null,
      'adminReviewStatus': null,
      'reviewedAt': null,
    };
    if (submissionNote != null) data['submissionNote'] = submissionNote;
    if (links != null) {
      data['links'] = links.map((l) => l.toMap()).toList();
    }
    await _db.collection('tasks').doc(taskId).update(data);
  }

  // ── Admin reviews a submitted task ───────────────────────────────────────
  Future<void> reviewTask({
    required String taskId,
    required String internUid,
    required String reviewStatus, // 'approved','needs_revision','rejected'
    required String remark,
  }) async {
    final data = <String, dynamic>{
      'adminRemark': remark,
      'adminReviewStatus': reviewStatus,
      'reviewedAt': DateTime.now().toIso8601String(),
    };

    if (reviewStatus == 'approved') {
      data['status'] = 'completed';
      data['completedAt'] = DateTime.now().toIso8601String();
      // Increment intern's completedTasks count
      await _db.collection('users').doc(internUid).update({
        'completedTasks': FieldValue.increment(1),
      });
    } else if (reviewStatus == 'needs_revision') {
      data['status'] = 'in_progress'; // send back for editing
    } else if (reviewStatus == 'rejected') {
      data['status'] = 'pending';
    }

    await _db.collection('tasks').doc(taskId).update(data);
  }

  // ── General status update (start task etc.) ───────────────────────────────
  Future<void> updateTaskStatus(
    String taskId,
    String status, {
    String? submissionNote,
    String? internUid,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (submissionNote != null) data['submissionNote'] = submissionNote;
    if (status == 'completed' && internUid != null) {
      data['completedAt'] = DateTime.now().toIso8601String();
      await _db.collection('users').doc(internUid).update({
        'completedTasks': FieldValue.increment(1),
      });
    }
    await _db.collection('tasks').doc(taskId).update(data);
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) =>
      _db.collection('tasks').doc(taskId).update(data);

  Future<void> deleteTask(String taskId, String internUid) async {
    final doc = await _db.collection('tasks').doc(taskId).get();
    final status = doc.data()?['status'];
    await _db.collection('tasks').doc(taskId).delete();
    await _db.collection('users').doc(internUid).update({
      'totalTasks': FieldValue.increment(-1),
      if (status == 'completed') 'completedTasks': FieldValue.increment(-1),
    });
  }

  Future<Map<String, int>> getTaskStats() async {
    final snap = await _db.collection('tasks').get();
    int pending = 0, inProgress = 0, submitted = 0, completed = 0;
    for (var doc in snap.docs) {
      final s = doc.data()['status'] ?? 'pending';
      if (s == 'pending')
        pending++;
      else if (s == 'in_progress')
        inProgress++;
      else if (s == 'submitted')
        submitted++;
      else if (s == 'completed') completed++;
    }
    return {
      'pending': pending,
      'in_progress': inProgress,
      'submitted': submitted,
      'completed': completed,
      'total': snap.docs.length,
    };
  }
}
