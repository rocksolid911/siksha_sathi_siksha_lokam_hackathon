import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Authentication repository for Firebase Auth operations.
/// Abstracts authentication logic to allow future migration (e.g., to Django Auth).
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Sign in with Google using google_sign_in v7.x API
  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;

    try {
      // Initialize Google Sign-In
      await googleSignIn.initialize();

      // Use a completer to handle the async authentication flow
      final completer = Completer<UserCredential>();
      StreamSubscription? subscription;

      subscription = googleSignIn.authenticationEvents.listen(
        (event) async {
          try {
            debugPrint('Google Sign-In event: ${event.runtimeType}');

            // Handle the event based on its type
            switch (event) {
              case GoogleSignInAuthenticationEventSignIn():
                // Sign in completed - get user and tokens from event
                final user = event.user;
                final authentication = user.authentication;
                final idToken = authentication.idToken;

                if (idToken != null) {
                  // Create Firebase credential (v7.x only provides idToken)
                  final credential = GoogleAuthProvider.credential(
                    idToken: idToken,
                  );

                  // Sign in to Firebase
                  final userCredential =
                      await _firebaseAuth.signInWithCredential(credential);

                  if (!completer.isCompleted) {
                    completer.complete(userCredential);
                  }
                } else {
                  if (!completer.isCompleted) {
                    completer.completeError(
                        AuthException('Failed to get Google ID token'));
                  }
                }
              case GoogleSignInAuthenticationEventSignOut():
                if (!completer.isCompleted) {
                  completer.completeError(
                      AuthException('Google sign-in was cancelled'));
                }
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(AuthException('Sign-in error: $e'));
            }
          } finally {
            subscription?.cancel();
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer
                .completeError(AuthException('Google sign-in failed: $error'));
          }
          subscription?.cancel();
        },
      );

      // Start authentication
      if (googleSignIn.supportsAuthenticate()) {
        await googleSignIn.authenticate();
      } else {
        subscription.cancel();
        throw AuthException(
            'Google Sign-In not supported on this platform. Use web button.');
      }

      // Wait for result with timeout
      return await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          subscription?.cancel();
          throw AuthException('Google sign-in timed out');
        },
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google sign-in failed: $e');
    }
  }

  /// Send OTP to phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 60),
    int? forceResendingToken,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: timeout,
      forceResendingToken: forceResendingToken,
    );
  }

  /// Verify OTP and sign in
  Future<UserCredential> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      GoogleSignIn.instance.signOut(),
    ]);
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException('No user logged in');
    }

    try {
      // 1. Delete from Firestore
      await _firestore.collection('teachers').doc(user.uid).delete();

      // 2. Delete from Firebase Auth
      await user.delete();

      // 3. Sign out from Google (clean up local session)
      await GoogleSignIn.instance.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
            'For security, please log out and log in again to delete your account.');
      }
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }
  }

  /// Save user profile to Firestore
  Future<void> saveUserProfile({
    required String uid,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      await _firestore.collection('teachers').doc(uid).set(
            profileData,
            SetOptions(merge: true),
          );
    } catch (e) {
      throw AuthException('Failed to save profile: $e');
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('teachers').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw AuthException('Failed to get profile: $e');
    }
  }

  /// Map Firebase Auth exceptions to user-friendly messages
  AuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('No user found with this email.');
      case 'wrong-password':
        return AuthException('Incorrect password.');
      case 'email-already-in-use':
        return AuthException('This email is already registered.');
      case 'weak-password':
        return AuthException('Password is too weak.');
      case 'invalid-email':
        return AuthException('Invalid email address.');
      case 'user-disabled':
        return AuthException('This account has been disabled.');
      case 'too-many-requests':
        return AuthException('Too many attempts. Please try again later.');
      case 'invalid-verification-code':
        return AuthException('Invalid OTP. Please try again.');
      case 'invalid-verification-id':
        return AuthException(
            'Verification session expired. Please resend OTP.');
      default:
        return AuthException(e.message ?? 'An authentication error occurred.');
    }
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
