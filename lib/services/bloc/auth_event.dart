import 'package:flutter/foundation.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/sms_verification.dart';

// immutable super class
@immutable
abstract class AuthEvent {
  const AuthEvent();
}

class AuthEventInitialise extends AuthEvent {
  const AuthEventInitialise();
}

class AuthEventLogIn extends AuthEvent {
  final String username;
  final String password;
  const AuthEventLogIn(this.username, this.password);
}

class AuthEventRegister extends AuthEvent {
  final Map<String, dynamic> registrationData;
  const AuthEventRegister(this.registrationData);
}

class AuthEventActivateAccount extends AuthEvent {
  final String username;
  final String password;
  final String activationKey;
  const AuthEventActivateAccount(
    this.username,
    this.password,
    this.activationKey,
  );
}

class AuthEventShouldRegister extends AuthEvent {
  final String? deviceId;
  const AuthEventShouldRegister({this.deviceId});
}

class AuthEventLostPassword extends AuthEvent {
  final String? email;
  const AuthEventLostPassword({this.email});
}

class AuthEventLogOut extends AuthEvent {
  const AuthEventLogOut();
}

class AuthEventContactUs extends AuthEvent {
  const AuthEventContactUs();
}

class AuthEventShouldVerifySms extends AuthEvent {
  const AuthEventShouldVerifySms();
}

class AuthEventShouldVerifyLoggedInSms extends AuthEvent {
  final Member currentUser;
  const AuthEventShouldVerifyLoggedInSms({required this.currentUser});
}

class AuthEventRequestSmsVerification extends AuthEvent {
  final SmsCodeRequest smsCodeRequest;
  final Member? currentUser;
  const AuthEventRequestSmsVerification(
      {required this.smsCodeRequest, this.currentUser});
}

class AuthEventVerifySmsCode extends AuthEvent {
  final VerifySmsCodeRequest verifySmsCodeRequest;
  final Member? currentUser;
  const AuthEventVerifySmsCode(
      {required this.verifySmsCodeRequest, this.currentUser});
}

class AuthEventLoggedIn extends AuthEvent {
  final Member currentUser;
  const AuthEventLoggedIn({required this.currentUser});
}
