import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nifty_three_bp_app_base/constants/member_filter.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/services/ads/ad_service.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/bloc/auth_state.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:nifty_three_bp_app_base/api/x_profile_options_item.dart';
import 'package:arvo/services/crud/crud_exceptions.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/services/features/subscription_service.dart';
import 'package:arvo/services/messaging/messaging_handler_service.dart';
import 'package:arvo/services/push_notifications/push_notification_provider.dart';
import 'package:arvo/services/push_notifications/push_notification_service.dart';
import 'package:arvo/services/tips/tip_service.dart';
import 'package:arvo/theme/theme_cubit.dart';
import 'package:arvo/utilities/url_launcher.dart';
import 'package:app_base/extensions/string_extensions.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    ConnectionProvider connectionProvider,
    LocalStorageProvider storageProvider,
    PushNotificationProvider pushNotificationProvider,
    ThemeCubit themeCubit,
  ) : super(const AuthStateUninitialised(isLoading: true)) {
    // Initialise.
    on<AuthEventInitialise>((event, emit) async {
      final user = connectionProvider.currentUser;
      if (user == null) {
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ),
        );
      } else {
        emit(AuthStateLoggedIn(
          user: user,
          isLoading: false,
        ));
      }
    });
    // Lost password.
    on<AuthEventLostPassword>(
      (event, emit) async {
        emit(const AuthStateLostPassword(
          exception: null,
          hasSentEmail: false,
          isLoading: false,
        ));

        final email = event.email;
        if (email == null) {
          return;
        }
        emit(const AuthStateLostPassword(
          exception: null,
          hasSentEmail: false,
          isLoading: true,
          loadingText: 'Sending email...',
        ));

        bool didSendEmail;
        Exception? exception;
        try {
          var databaseSystemSetting = await storageProvider.getSystemSetting();
          var lastPasswordResetRequestTimestamp =
              DateTime.fromMillisecondsSinceEpoch(
                  databaseSystemSetting.passwordResetRequestTimestamp);
          var timeDiff = DateTime.now()
              .difference(lastPasswordResetRequestTimestamp)
              .inMinutes;
          if (timeDiff < 5) {
            throw GenericException(
              title: 'Try again later',
              message:
                  "You've recently requested a password reset, please wait 5 minutes before trying again.",
            );
          }
          await connectionProvider.sendPasswordResetEmail(email);
          databaseSystemSetting.passwordResetRequestTimestamp =
              DateTime.now().millisecondsSinceEpoch;
          await storageProvider.updateSystemSetting(databaseSystemSetting);
          didSendEmail = true;
          exception = null;
        } on Exception catch (e) {
          didSendEmail = false;
          exception = e;
        }

        emit(AuthStateLostPassword(
          exception: exception,
          hasSentEmail: didSendEmail,
          isLoading: false,
        ));
      },
    );
    // Verify.
    on<AuthEventShouldVerifySms>((event, emit) async {
      try {
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: true,
          ),
        );
        // Check if SMS verification system is available.
        final smsVerificationSystemStatus =
            await connectionProvider.getSmsVerificationSystemStatus();
        if (smsVerificationSystemStatus.available) {
          // Start SMS verification.
          emit(
            const AuthStateVerifying(
              exception: null,
              hasSentVerificationCode: false,
              currentUser: null,
              verifiedUserId: null,
              verified: false,
              rejected: false,
              isLoading: false,
            ),
          );
        } else {
          // Go straight to registration.
          emit(
            const AuthStateRegistering(
              exception: null,
              isLoading: false,
            ),
          );
        }
      } on Exception catch (_) {
        // Go straight to registration.
        emit(
          const AuthStateRegistering(
            exception: null,
            isLoading: false,
          ),
        );
      }
    });
    on<AuthEventShouldVerifyLoggedInSms>((event, emit) async {
      try {
        emit(
          AuthStateLoggedIn(
            user: event.currentUser,
            exception: null,
            isLoading: true,
          ),
        );
        // Check if SMS verification system is available.
        final smsVerificationSystemStatus =
            await connectionProvider.getSmsVerificationSystemStatus();
        if (smsVerificationSystemStatus.available) {
          // Start SMS verification.
          emit(
            AuthStateVerifying(
              exception: null,
              hasSentVerificationCode: false,
              currentUser: event.currentUser,
              verifiedUserId: null,
              verified: false,
              rejected: false,
              isLoading: false,
            ),
          );
        } else {
          // Go back to dashboard.
          emit(
            AuthStateLoggedIn(
              user: event.currentUser,
              exception: SMSVerificationNotAvailableException(),
              isLoading: false,
            ),
          );
        }
      } on Exception catch (_) {
        // Go back to dashboard.
        emit(
          AuthStateLoggedIn(
            user: event.currentUser,
            exception: SMSVerificationNotAvailableException(),
            isLoading: false,
          ),
        );
      }
    });
    on<AuthEventRequestSmsVerification>((event, emit) async {
      final smsCodeRequest = event.smsCodeRequest;
      try {
        emit(
          AuthStateVerifying(
            exception: null,
            isLoading: true,
            hasSentVerificationCode: false,
            currentUser: event.currentUser,
            verifiedUserId: null,
            verified: false,
            rejected: false,
            loadingText: 'Requesting SMS code...',
          ),
        );

        final smsCodeRequestResult =
            await connectionProvider.requestSmsCode(smsCodeRequest);
        if (smsCodeRequestResult.verified) {
          emit(
            AuthStateVerifying(
              exception: null,
              hasSentVerificationCode: false,
              verified: true,
              rejected: false,
              currentUser: event.currentUser,
              verifiedUserId: null,
              isLoading: false,
            ),
          );
        } else if (smsCodeRequestResult.requested) {
          emit(
            AuthStateVerifying(
              exception: null,
              hasSentVerificationCode: true,
              currentUser: event.currentUser,
              verifiedUserId: null,
              verified: false,
              rejected: false,
              requestId: smsCodeRequestResult.requestId,
              isLoading: false,
            ),
          );
        }
      } on Exception catch (e) {
        emit(
          AuthStateVerifying(
            exception: e,
            hasSentVerificationCode: false,
            currentUser: event.currentUser,
            verifiedUserId: null,
            verified: false,
            rejected: false,
            isLoading: false,
          ),
        );
      }
    });
    on<AuthEventVerifySmsCode>((event, emit) async {
      final verifySmsCodeRequest = event.verifySmsCodeRequest;
      try {
        emit(
          AuthStateVerifying(
            exception: null,
            hasSentVerificationCode: true,
            currentUser: event.currentUser,
            verifiedUserId: null,
            verified: false,
            rejected: false,
            isLoading: true,
            requestId: verifySmsCodeRequest.requestId,
            loadingText: 'Verifying SMS code...',
          ),
        );
        final verifySmsCodeResult =
            await connectionProvider.verifySmsCode(verifySmsCodeRequest);
        if (connectionProvider.currentUser == null ||
            !verifySmsCodeRequest.generateAuth) {
          emit(AuthStateVerifying(
            exception: null,
            hasSentVerificationCode: true,
            currentUser: event.currentUser,
            verifiedUserId: verifySmsCodeResult.userId > 0
                ? verifySmsCodeResult.userId
                : null,
            verified: verifySmsCodeResult.verified,
            rejected: !verifySmsCodeResult.verified,
            requestId: verifySmsCodeRequest.requestId,
            isLoading: false,
          ));
        } else {
          // Account already exists and has been logged in, go to the dashboard.
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: true,
              loadingText: 'Welcome back, logging you in...',
            ),
          );
          await _logIn(
            connectionProvider: connectionProvider,
            storageProvider: storageProvider,
            themeCubit: themeCubit,
            username: connectionProvider.currentUserEmailAddress ?? '',
            password: '',
            verified: true,
          );
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
          emit(
            AuthStateLoggedIn(
              user: connectionProvider.currentUser!,
              isLoading: false,
            ),
          );
        }
      } on Exception catch (e) {
        emit(
          AuthStateVerifying(
            exception: e,
            hasSentVerificationCode: true,
            currentUser: event.currentUser,
            verifiedUserId: null,
            verified: false,
            rejected: false,
            requestId: verifySmsCodeRequest.requestId,
            isLoading: false,
          ),
        );
      }
    });
    // Register.
    on<AuthEventShouldRegister>((event, emit) async {
      final deviceId = event.deviceId;
      emit(AuthStateRegistering(
        deviceId: deviceId,
        exception: null,
        isLoading: false,
      ));
    });
    on<AuthEventRegister>((event, emit) async {
      final data = event.registrationData;
      try {
        emit(
          const AuthStateRegistering(
            exception: null,
            isLoading: true,
            loadingText: 'Registering...',
          ),
        );
        await connectionProvider.signUp(data);
        // Update registered status so that log in form is displayed on next start.
        DatabaseSystemSetting systemSetting =
            await storageProvider.getSystemSetting();
        systemSetting.hasRegistered = true;
        systemSetting =
            await storageProvider.updateSystemSetting(systemSetting);
        emit(AuthStateNeedsActivation(
          username: data['user_email'].toString(),
          password: data['password'].toString(),
          isLoading: false,
        ));
      } on Exception catch (e) {
        emit(
          AuthStateRegistering(
            exception: e,
            isLoading: false,
          ),
        );
      }
    });
    // Activate account.
    on<AuthEventActivateAccount>((event, emit) async {
      final username = event.username;
      final password = event.password;
      emit(
        AuthStateNeedsActivation(
          username: username,
          password: password,
          exception: null,
          isLoading: true,
          loadingText: 'Activating...',
        ),
      );
      final activationKey = event.activationKey;
      try {
        await connectionProvider.activateAccount(activationKey);
        emit(
          AuthStateNeedsActivation(
            username: username,
            password: password,
            exception: null,
            isLoading: true,
            loadingText: 'Activated, logging you in...',
          ),
        );
        await _logIn(
          connectionProvider: connectionProvider,
          storageProvider: storageProvider,
          themeCubit: themeCubit,
          username: username,
          password: password,
        );
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ),
        );
        emit(
          AuthStateLoggedIn(
            user: connectionProvider.currentUser!,
            isLoading: false,
          ),
        );
      } on Exception catch (e) {
        emit(
          AuthStateNeedsActivation(
            username: username,
            password: password,
            exception: e,
            isLoading: false,
          ),
        );
      }
    });
    // Log in.
    on<AuthEventLogIn>((event, emit) async {
      emit(
        const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
          loadingText: 'Logging you in...',
        ),
      );
      final username = event.username;
      final password = event.password;
      try {
        await _logIn(
          connectionProvider: connectionProvider,
          storageProvider: storageProvider,
          themeCubit: themeCubit,
          username: username,
          password: password,
        );
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ),
        );
        emit(
          AuthStateLoggedIn(
            user: connectionProvider.currentUser!,
            isLoading: false,
          ),
        );
      } on Exception catch (e) {
        if (e is AccountNotActivatedException) {
          emit(AuthStateNeedsActivation(
            username: username,
            password: password,
            isLoading: false,
          ));
        } else {
          emit(
            AuthStateLoggedOut(
              exception: e,
              isLoading: false,
            ),
          );
        }
      }
    });
    // Log out.
    on<AuthEventLogOut>((event, emit) async {
      try {
        await connectionProvider.logOut();
        pushNotificationProvider.pushNotificationTokenRegistered = false;
        // Clear stored token.
        DatabaseSystemSetting systemSetting =
            await storageProvider.getSystemSetting();
        systemSetting.logInToken = '';
        systemSetting =
            await storageProvider.updateSystemSetting(systemSetting);
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ),
        );
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ),
        );
      }
    });
    // Contact us.
    on<AuthEventContactUs>((event, emit) async {
      try {
        await browseToUrl(connectionProvider.serverUrl! + contactUsURL);
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ),
        );
      }
    });
    // Logged in.
    on<AuthEventLoggedIn>((event, emit) async {
      emit(
        AuthStateLoggedIn(
          user: event.currentUser,
          isLoading: false,
        ),
      );
    });
  }
}

Future<DatabaseUserSetting> _createNewUserSetting(
    int userId,
    LocalStorageProvider storageProvider,
    ConnectionProvider connectionProvider) async {
  final newUserSetting = DatabaseUserSetting(
    id: 0,
    userId: userId,
    memberSearchConnectionTypes: _generateFilter(
      connectionProvider,
      xProfileGroupAboutMe,
      xProfileFieldConnection,
      filterDisplayTitleConnection,
    ),
    memberSearchSexualOrientations: _generateFilter(
      connectionProvider,
      xProfileGroupAboutMe,
      xProfileFieldSexualOrientation,
      filterDisplayTitleSexualOrientation,
    ),
    // Note: This uses the xProfileFieldLookingFor field which is
    // different to xProfileFieldGender.
    memberSearchGenders: _generateFilter(
      connectionProvider,
      xProfileGroupAboutMe,
      xProfileFieldLookingFor,
      filterDisplayTitleGender,
    ),
    memberSearchLocations: '',
    memberSearchPassions: '',
    memberSearchEthnicities: '',
    memberSearchAgeFrom: 18,
    memberSearchAgeTo: 99,
    memberSearchPhotoType: 0,
    memberSearchKey: '',
    memberSearchOrderType: 0,
    featureAdFree: false,
    featureThemeControl: false,
    featureSelectedTheme: 1, // 1 = Light.
    featurePhotoTypeSearch: false,
    featureMatchInsight: false,
    featureMemberOnlineIndicator: false,
    featureCustomOpeners: false,
    featureFavouritedMe: false,
    showTipFiltersApplied: true,
    showTipSwipe: true,
    showTipMessageGuidelines: true,
  );
  return await storageProvider.createUserSetting(newUserSetting);
}

String _generateFilter(ConnectionProvider connectionProvider,
    int xProfileGroupId, int xProfileFieldId, String displayTitle) {
  var filter = '';

  final group = connectionProvider.currentUser?.xProfile?.groups
      .where((group) => group.id == xProfileGroupId)
      .firstOrNull;

  if (group != null) {
    final field =
        group.fields.where((field) => field.id == xProfileFieldId).firstOrNull;

    var xProfileField = connectionProvider.xProfileFields
        ?.where((xProfileField) => xProfileField.id == xProfileFieldId)
        .firstOrNull;

    if (field != null && xProfileField != null) {
      final optionsItem = XProfileFieldOptionsItem(
        xProfileFieldId: xProfileField.id,
        displayTitle: displayTitle,
        selectionItems: [],
      );

      if (field.value != null) {
        final values = field.value!.unserialized;

        if (values != null) {
          for (final value in values) {
            final option = xProfileField.options
                ?.where((option) => option.name == value)
                .firstOrNull;
            if (option != null) {
              optionsItem.selectionItems.add(
                XProfileFieldOptionSelectionItem(
                    contextTypeId: option.id,
                    contextTypeDescription: option.name,
                    isSelected: true),
              );
            }
          }
        }

        filter = jsonEncode(optionsItem.toJson());
      }
    }
  }

  return filter;
}

Future<void> _logIn({
  required ConnectionProvider connectionProvider,
  required LocalStorageProvider storageProvider,
  required ThemeCubit themeCubit,
  required String username,
  required String password,
  bool verified = false,
}) async {
  if (!verified) {
    await connectionProvider.logIn(
      username: username.addEscapeCharacters(),
      password: password.addEscapeCharacters(),
    );
  }
  // Update stored username and password.
  DatabaseSystemSetting systemSetting =
      await storageProvider.getSystemSetting();
  systemSetting.logInToken = connectionProvider.token!;
  if (systemSetting.rememberLogIn) {
    systemSetting.logInUserName = username;
    systemSetting.logInPassword = password;
  }
  // Update registered status so that log in form is displayed on next start.
  systemSetting.hasRegistered = true;
  systemSetting = await storageProvider.updateSystemSetting(systemSetting);
  // Check user setting exists, if not, create it.
  int currentUserId = connectionProvider.currentUser!.id;
  try {
    await storageProvider.getUserSetting(currentUserId);
  } on Exception catch (e) {
    if (e is CouldNotFindUserSettingException) {
      await _createNewUserSetting(
          currentUserId, storageProvider, connectionProvider);
    }
  }
  // Register FCM token.
  PushNotificationService.firebase().registerPushNotificationTokenWithServer();
  // Load Feature Service parameters.
  await FeatureService.arvo().loadSystemParameters();
  // Restore Subscription.
  await SubscriptionService.arvo().restorePurchases();
  // Load Ad Service parameters.
  await AdService.arvo().loadSystemParameters();
  // Load Tip Service parameters.
  await TipService.arvo().loadSystemParameters();
  // Load Member Directory Service parameters.
  await MemberDirectoryService.arvo().loadSystemParameters();
  await MessagingHandlerService.arvo().loadSystemParameters();
  await MessagingHandlerService.arvo().refreshUnreadMessageCount();
}
