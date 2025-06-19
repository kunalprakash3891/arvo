import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:nifty_three_bp_app_base/api/member.dart' show Member;

// immutable super class
@immutable
abstract class AuthState {
  final bool isLoading;
  final String? loadingText;
  final Exception? exception;
  const AuthState({
    required this.isLoading,
    this.loadingText = 'Loading...',
    this.exception,
  });
}

class AuthStateUninitialised extends AuthState {
  const AuthStateUninitialised({required super.isLoading});
}

class AuthStateVerifying extends AuthState {
  final bool hasSentVerificationCode;
  final Member? currentUser;
  final int? verifiedUserId;
  final bool verified;
  final bool rejected;
  final int? requestId;
  const AuthStateVerifying({
    required super.exception,
    required super.isLoading,
    required this.hasSentVerificationCode,
    required this.currentUser,
    required this.verifiedUserId,
    required this.verified,
    required this.rejected,
    this.requestId,
    super.loadingText = null,
  }) : super();
}

class AuthStateRegistering extends AuthState {
  final String? deviceId;
  const AuthStateRegistering({
    required super.exception,
    required super.isLoading,
    super.loadingText = null,
    this.deviceId,
  }) : super();
}

class AuthStateLostPassword extends AuthState with EquatableMixin {
  final bool hasSentEmail;

  const AuthStateLostPassword({
    required super.exception,
    required this.hasSentEmail,
    required super.isLoading,
    super.loadingText = null,
  }) : super();

  @override
  List<Object?> get props => [exception, isLoading];
}

class AuthStateLoggedIn extends AuthState {
  final Member user;
  const AuthStateLoggedIn({
    required this.user,
    super.exception,
    required super.isLoading,
  }) : super();
}

class AuthStateNeedsActivation extends AuthState {
  final String username;
  final String password;
  const AuthStateNeedsActivation({
    required this.username,
    required this.password,
    super.exception,
    required super.isLoading,
    super.loadingText = null,
  }) : super();
}

class AuthStateLoggedOut extends AuthState with EquatableMixin {
  const AuthStateLoggedOut({
    super.exception,
    required super.isLoading,
    super.loadingText = null,
  }) : super();

  @override
  List<Object?> get props => [exception, isLoading];
}
