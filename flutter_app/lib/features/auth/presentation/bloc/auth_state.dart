import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - checking auth status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during auth operations
class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  final User user;
  final Map<String, dynamic>? profile;

  const AuthAuthenticated({
    required this.user,
    this.profile,
  });

  @override
  List<Object?> get props => [user.uid, profile];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// OTP sent, waiting for verification
class AuthOtpSent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  const AuthOtpSent({
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber, resendToken];
}

/// Auth failure with error message
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
