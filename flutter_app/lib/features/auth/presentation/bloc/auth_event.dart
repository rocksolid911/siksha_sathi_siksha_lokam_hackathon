import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is already authenticated
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Sign in with email and password
class AuthEmailLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthEmailLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Register with email and password
class AuthEmailRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const AuthEmailRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

/// Sign in with Google
class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

/// Request phone OTP
class AuthPhoneLoginRequested extends AuthEvent {
  final String phoneNumber;

  const AuthPhoneLoginRequested({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

/// Verify OTP
class AuthVerifyOtpRequested extends AuthEvent {
  final String verificationId;
  final String smsCode;

  const AuthVerifyOtpRequested({
    required this.verificationId,
    required this.smsCode,
  });

  @override
  List<Object?> get props => [verificationId, smsCode];
}

/// Update user profile
class AuthUpdateProfileRequested extends AuthEvent {
  final String name;
  final String? school;
  final String? district;
  final String? state;
  final String? preferredLanguage;

  const AuthUpdateProfileRequested({
    required this.name,
    this.school,
    this.district,
    this.state,
    this.preferredLanguage,
  });

  @override
  List<Object?> get props => [name, school, district, state, preferredLanguage];
}

/// Sign out
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
