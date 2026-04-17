import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../models/user.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Citizens: Phone OTP ──────────────────────────────────────────────────

  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  // ── Authority Officials: Email + Password ────────────────────────────────

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── User Profile ─────────────────────────────────────────────────────────

  Future<Jawab DoUser?> fetchUserProfile(String uid) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (response == null) return null;
    return Jawab DoUser.fromMap(response);
  }

  Future<Jawab DoUser> createCitizenProfile({
    required String uid,
    required String phone,
    required String name,
    required String wardId,
    String? avatarUrl,
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      'id': uid,
      'phone': phone,
      'name': name,
      'ward_id': wardId,
      'avatar_url': avatarUrl,
      'role': 'citizen',
      'created_at': now,
      'karma_score': 0,
      'issues_filed_count': 0,
      'issues_resolved_count': 0,
      'jurisdiction_wards': <String>[],
    };
    try {
      final response = await _supabase
          .from('users')
          .insert(data)
          .select()
          .single();
      return Jawab DoUser.fromMap(response);
    } on PostgrestException catch (e) {
      // If profile row already exists, return the canonical stored row.
      if (e.code == '23505') {
        final existing = await _supabase
            .from('users')
            .select()
            .eq('id', uid)
            .single();
        return Jawab DoUser.fromMap(existing);
      }
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? wardId,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (wardId != null) updates['ward_id'] = wardId;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (updates.isNotEmpty) {
      await _supabase.from('users').update(updates).eq('id', uid);
    }
  }

  // ── Session ───────────────────────────────────────────────────────────────

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
