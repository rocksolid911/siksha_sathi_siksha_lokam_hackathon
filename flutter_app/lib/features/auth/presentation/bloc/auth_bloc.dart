import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for authentication
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthEmailLoginRequested>(_onEmailLoginRequested);
    on<AuthEmailRegisterRequested>(_onEmailRegisterRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthPhoneLoginRequested>(_onPhoneLoginRequested);
    on<AuthVerifyOtpRequested>(_onVerifyOtpRequested);
    on<AuthUpdateProfileRequested>(_onUpdateProfileRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);

    // Listen to auth state changes
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        add(const AuthCheckRequested());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      // Set API client auth header
      ApiClient.instance.setAuthUser(user.uid);

      try {
        final profile = await _authRepository.getUserProfile(user.uid);
        emit(AuthAuthenticated(user: user, profile: profile));
      } catch (e) {
        emit(AuthAuthenticated(user: user));
      }
    } else {
      ApiClient.instance.clearAuthUser();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onEmailLoginRequested(
    AuthEmailLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in...'));
    try {
      final credential = await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Set API client auth header
      ApiClient.instance.setAuthUser(credential.user!.uid);

      final profile =
          await _authRepository.getUserProfile(credential.user!.uid);
      emit(AuthAuthenticated(user: credential.user!, profile: profile));
    } on AuthException catch (e) {
      emit(AuthFailure(message: e.message));
    } catch (e) {
      emit(AuthFailure(message: 'Login failed: $e'));
    }
  }

  Future<void> _onEmailRegisterRequested(
    AuthEmailRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating account...'));
    try {
      final credential = await _authRepository.registerWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Set API client auth header
      ApiClient.instance.setAuthUser(credential.user!.uid);

      // Save initial profile
      await _authRepository.saveUserProfile(
        uid: credential.user!.uid,
        profileData: {
          'name': event.name,
          'email': event.email,
          'role': 'teacher',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      final profile =
          await _authRepository.getUserProfile(credential.user!.uid);
      emit(AuthAuthenticated(user: credential.user!, profile: profile));
    } on AuthException catch (e) {
      emit(AuthFailure(message: e.message));
    } catch (e) {
      emit(AuthFailure(message: 'Registration failed: $e'));
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in with Google...'));
    try {
      final credential = await _authRepository.signInWithGoogle();
      final user = credential.user!;

      // Set API client auth header
      ApiClient.instance.setAuthUser(user.uid);

      // Save/update profile with Google info
      await _authRepository.saveUserProfile(
        uid: user.uid,
        profileData: {
          'name': user.displayName ?? 'Teacher',
          'email': user.email,
          'photoUrl': user.photoURL,
          'role': 'teacher',
          'lastLogin': DateTime.now().toIso8601String(),
        },
      );

      final profile = await _authRepository.getUserProfile(user.uid);
      emit(AuthAuthenticated(user: user, profile: profile));
    } on AuthException catch (e) {
      emit(AuthFailure(message: e.message));
    } catch (e) {
      emit(AuthFailure(message: 'Google sign-in failed: $e'));
    }
  }

  Future<void> _onPhoneLoginRequested(
    AuthPhoneLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Sending OTP...'));

    final completer = Completer<void>();

    try {
      await _authRepository.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        verificationCompleted: (credential) async {
          // Auto-verification on Android
          try {
            final userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);

            // Set API client auth header
            ApiClient.instance.setAuthUser(userCredential.user!.uid);

            await _authRepository.saveUserProfile(
              uid: userCredential.user!.uid,
              profileData: {
                'phoneNumber': event.phoneNumber,
                'role': 'teacher',
                'lastLogin': DateTime.now().toIso8601String(),
              },
            );
            final profile =
                await _authRepository.getUserProfile(userCredential.user!.uid);
            emit(AuthAuthenticated(
                user: userCredential.user!, profile: profile));
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            emit(AuthFailure(message: 'Auto-verification failed: $e'));
            if (!completer.isCompleted) completer.complete();
          }
        },
        verificationFailed: (e) {
          debugPrint('Phone verification failed: ${e.message}');
          emit(AuthFailure(message: e.message ?? 'Phone verification failed'));
          if (!completer.isCompleted) completer.complete();
        },
        codeSent: (verificationId, resendToken) {
          emit(AuthOtpSent(
            verificationId: verificationId,
            phoneNumber: event.phoneNumber,
            resendToken: resendToken,
          ));
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // Handle timeout if needed
        },
      );

      await completer.future;
    } catch (e) {
      emit(AuthFailure(message: 'Failed to send OTP: $e'));
    }
  }

  Future<void> _onVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Verifying OTP...'));
    try {
      final credential = await _authRepository.verifyOtpAndSignIn(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );

      // Set API client auth header
      ApiClient.instance.setAuthUser(credential.user!.uid);

      final profile =
          await _authRepository.getUserProfile(credential.user!.uid);
      emit(AuthAuthenticated(user: credential.user!, profile: profile));
    } on AuthException catch (e) {
      emit(AuthFailure(message: e.message));
    } catch (e) {
      emit(AuthFailure(message: 'OTP verification failed: $e'));
    }
  }

  Future<void> _onUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(const AuthFailure(message: 'User not logged in'));
      return;
    }

    emit(const AuthLoading(message: 'Updating profile...'));
    try {
      await _authRepository.saveUserProfile(
        uid: user.uid,
        profileData: {
          'name': event.name,
          if (event.school != null) 'school': event.school,
          if (event.district != null) 'district': event.district,
          if (event.state != null) 'state': event.state,
          if (event.preferredLanguage != null)
            'preferred_language': event.preferredLanguage,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      // Ensure API client header is set (redundancy check)
      ApiClient.instance.setAuthUser(user.uid);

      final profile = await _authRepository.getUserProfile(user.uid);
      emit(AuthAuthenticated(user: user, profile: profile));
    } catch (e) {
      emit(AuthFailure(message: 'Profile update failed: $e'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing out...'));
    try {
      await _authRepository.signOut();

      // Clear API client auth header
      ApiClient.instance.clearAuthUser();

      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(message: 'Sign out failed: $e'));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
