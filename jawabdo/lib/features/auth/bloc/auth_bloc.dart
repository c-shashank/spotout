import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/user.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthPhoneSendOtp extends AuthEvent {
  final String phoneNumber;
  const AuthPhoneSendOtp(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class AuthPhoneVerifyOtp extends AuthEvent {
  final String verificationId;
  final String smsCode;
  const AuthPhoneVerifyOtp(this.verificationId, this.smsCode);
  @override
  List<Object?> get props => [verificationId, smsCode];
}

class AuthPhoneAutoVerified extends AuthEvent {
  final PhoneAuthCredential credential;
  const AuthPhoneAutoVerified(this.credential);
}

class AuthPhoneCodeSent extends AuthEvent {
  final String verificationId;
  final String phoneNumber;
  const AuthPhoneCodeSent({
    required this.verificationId,
    required this.phoneNumber,
  });
  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

class AuthPhoneSendOtpFailed extends AuthEvent {
  final String message;
  const AuthPhoneSendOtpFailed(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthEmailSignIn extends AuthEvent {
  final String email;
  final String password;
  const AuthEmailSignIn(this.email, this.password);
  @override
  List<Object?> get props => [email];
}

class AuthProfileSetup extends AuthEvent {
  final String name;
  final String wardId;
  final String? avatarUrl;
  const AuthProfileSetup({required this.name, required this.wardId, this.avatarUrl});
}

class AuthSignOut extends AuthEvent {}

// ── States ────────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  const AuthOtpSent(this.verificationId, this.phoneNumber);
  @override
  List<Object?> get props => [verificationId];
}

class AuthNeedsProfileSetup extends AuthState {
  final String uid;
  final String phone;
  final String? errorMessage;
  const AuthNeedsProfileSetup(this.uid, this.phone, {this.errorMessage});
  @override
  List<Object?> get props => [uid, errorMessage];
}

class AuthCitizenAuthenticated extends AuthState {
  final Jawab DoUser user;
  const AuthCitizenAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthAuthorityAuthenticated extends AuthState {
  final Jawab DoUser user;
  const AuthAuthorityAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  String? _pendingVerificationId;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthPhoneSendOtp>(_onPhoneSendOtp);
    on<AuthPhoneCodeSent>(_onPhoneCodeSent);
    on<AuthPhoneSendOtpFailed>(_onPhoneSendOtpFailed);
    on<AuthPhoneVerifyOtp>(_onPhoneVerifyOtp);
    on<AuthPhoneAutoVerified>(_onPhoneAutoVerified);
    on<AuthEmailSignIn>(_onEmailSignIn);
    on<AuthProfileSetup>(_onProfileSetup);
    on<AuthSignOut>(_onSignOut);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final fbUser = _authService.currentFirebaseUser;
    if (fbUser == null) {
      emit(AuthUnauthenticated());
      return;
    }
    try {
      final user = await _authService.fetchUserProfile(fbUser.uid);
      if (user == null) {
        // No row in DB — genuinely new user, needs profile setup.
        emit(AuthNeedsProfileSetup(fbUser.uid, fbUser.phoneNumber ?? ''));
      } else if (user.isAuthority) {
        emit(AuthAuthorityAuthenticated(user));
      } else {
        emit(AuthCitizenAuthenticated(user));
      }
    } catch (e) {
      // Query failed (network, RLS, etc.) — don't lose the session.
      emit(AuthError('Could not load profile: $e'));
    }
  }

  Future<void> _onPhoneSendOtp(AuthPhoneSendOtp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authService.sendPhoneOtp(
      phoneNumber: event.phoneNumber,
      onVerificationCompleted: (cred) => add(AuthPhoneAutoVerified(cred)),
      onVerificationFailed: (e) => add(AuthPhoneSendOtpFailed(e.message ?? 'OTP failed')),
      onCodeSent: (verificationId, _) {
        add(
          AuthPhoneCodeSent(
            verificationId: verificationId,
            phoneNumber: event.phoneNumber,
          ),
        );
      },
      onCodeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _onPhoneCodeSent(AuthPhoneCodeSent event, Emitter<AuthState> emit) async {
    _pendingVerificationId = event.verificationId;
    emit(AuthOtpSent(event.verificationId, event.phoneNumber));
  }

  Future<void> _onPhoneSendOtpFailed(
    AuthPhoneSendOtpFailed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthError(event.message));
  }

  Future<void> _onPhoneVerifyOtp(AuthPhoneVerifyOtp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = await _authService.verifyOtp(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );
      final uid = cred.user!.uid;
      final phone = cred.user!.phoneNumber ?? '';
      final user = await _authService.fetchUserProfile(uid);
      if (user == null) {
        emit(AuthNeedsProfileSetup(uid, phone));
      } else if (user.isAuthority) {
        emit(AuthAuthorityAuthenticated(user));
      } else {
        emit(AuthCitizenAuthenticated(user));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Invalid OTP'));
    }
  }

  Future<void> _onPhoneAutoVerified(AuthPhoneAutoVerified event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = await FirebaseAuth.instance.signInWithCredential(event.credential);
      final uid = cred.user!.uid;
      final phone = cred.user!.phoneNumber ?? '';
      final user = await _authService.fetchUserProfile(uid);
      if (user == null) {
        emit(AuthNeedsProfileSetup(uid, phone));
      } else if (user.isAuthority) {
        emit(AuthAuthorityAuthenticated(user));
      } else {
        emit(AuthCitizenAuthenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onEmailSignIn(AuthEmailSignIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = await _authService.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      final uid = cred.user!.uid;
      final user = await _authService.fetchUserProfile(uid);
      if (user == null || !user.isAuthority) {
        await _authService.signOut();
        emit(const AuthError('This account does not have authority access.'));
        return;
      }
      emit(AuthAuthorityAuthenticated(user));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Sign in failed'));
    }
  }

  Future<void> _onProfileSetup(AuthProfileSetup event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final fbUser = _authService.currentFirebaseUser!;
      final user = await _authService.createCitizenProfile(
        uid: fbUser.uid,
        phone: fbUser.phoneNumber ?? '',
        name: event.name,
        wardId: event.wardId,
        avatarUrl: event.avatarUrl,
      );
      emit(AuthCitizenAuthenticated(user));
    } catch (e) {
      final fbUser = _authService.currentFirebaseUser;
      if (fbUser == null) {
        emit(AuthUnauthenticated());
        return;
      }
      emit(
        AuthNeedsProfileSetup(
          fbUser.uid,
          fbUser.phoneNumber ?? '',
          errorMessage: 'Could not complete profile setup. Please try again.',
        ),
      );
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    await _authService.signOut();
    emit(AuthUnauthenticated());
  }
}
