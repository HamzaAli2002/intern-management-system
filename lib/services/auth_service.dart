// ─── lib/services/auth_service.dart ───────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/intern_user.dart';
import '../firebase_options.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Sign In ───────────────────────────────────────────────────────────────
  Future<AuthResult> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) return AuthResult.error('Login failed.');

      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        return AuthResult.error(
            'Profile not found. Contact admin to set up your account.');
      }

      final role = doc.data()?['role'] ?? 'intern';
      return AuthResult.success(user, role);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_firebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: $e');
    }
  }

  // ── Register Intern ───────────────────────────────────────────────────────
  // FIX: Uses a SECONDARY Firebase App so admin session is NOT interrupted.
  // Without this, createUserWithEmailAndPassword() logs out the admin
  // and signs in the new intern, causing the Firestore write to fail
  // with a permission error — which is why interns appeared in Auth
  // but NOT in Firestore.
  Future<AuthResult> registerIntern({
    required String email,
    required String password,
    required String name,
    required String department,
    required String batchNo,
    required String phone,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // Step 1: Create a temporary secondary Firebase app instance
      // This does NOT affect the admin's current login session
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Step 2: Create the intern Auth account via the secondary app
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final newUser = credential.user;
      if (newUser == null) return AuthResult.error('Registration failed.');

      final uid = newUser.uid;

      // Step 3: Sign out from secondary app immediately (cleanup)
      await secondaryAuth.signOut();

      // Step 4: Write intern profile to Firestore using ADMIN's auth context
      // At this point _auth.currentUser is still the admin — no interruption
      final intern = InternUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        role: 'intern',
        department: department,
        batchNo: batchNo,
        phone: phone,
        joinDate: DateTime.now(),
        status: 'active',
        completedTasks: 0,
        totalTasks: 0,
      );

      await _db.collection('users').doc(uid).set(intern.toMap());

      return AuthResult.success(newUser, 'intern');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_firebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Registration error: $e');
    } finally {
      // Always clean up the secondary app
      await secondaryApp?.delete();
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Get Current User Data ─────────────────────────────────────────────────
  Future<InternUser?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return InternUser.fromMap(doc.data()!, user.uid);
  }

  // ── Password Reset ────────────────────────────────────────────────────────
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _firebaseErrorMessage(e.code);
    }
  }

  // ── Error Messages ────────────────────────────────────────────────────────
  String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':  // newer Firebase SDK uses this instead
        return 'No account found with this email or password is incorrect.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'permission-denied':
        return 'Permission denied. Check Firestore security rules.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled in Firebase Console.';
      default:
        return 'Error ($code). Please try again.';
    }
  }
}

class AuthResult {
  final User? user;
  final String? role;
  final String? error;

  AuthResult._({this.user, this.role, this.error});

  factory AuthResult.success(User user, String role) =>
      AuthResult._(user: user, role: role);

  factory AuthResult.error(String message) => AuthResult._(error: message);

  bool get isSuccess => error == null;
}
