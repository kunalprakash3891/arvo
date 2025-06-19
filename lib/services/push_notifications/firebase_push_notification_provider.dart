import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:arvo/main.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/push_notifications/push_notification_provider.dart';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart' as crypto;
import 'package:arvo/views/messages/message_thread_view.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {}

class FirebasePushNotificationProvider implements PushNotificationProvider {
  bool _initialised = false;
  String? _pushNotificationToken;
  bool _pushNotificationTokenRegistered = false;
  // Contains a map of message thread views that need to be updated when a new message
  // is received.
  final Map<int, Function> _activeMessageThreadViewsMap = {};
  final Map<String, Function> _activeUpdateFunctionsMap = {};

  // create as singleton
  static final _shared = FirebasePushNotificationProvider._sharedInstance();
  FirebasePushNotificationProvider._sharedInstance();
  factory FirebasePushNotificationProvider() => _shared;

  late ConnectionProvider _connectionProvider;
  late LocalStorageProvider _localStorageProvider;

  // Android foreground notifications channel.
  final _androidNotificationChannel = const AndroidNotificationChannel(
    'foreground',
    'Foreground',
    description: 'The channel for foreground notifications.',
    importance: Importance.max,
  );
  final _localNotifications = FlutterLocalNotificationsPlugin();

  void handleMessage(RemoteMessage? message) {
    // Only handle if logged in.
    if (_connectionProvider.currentUser == null) return;
    if (message == null) return;

    if (message.data.isEmpty) return;
    // Retrieve message thread id from notification.
    final messageThreadId = _parseMessageThreadId(message);

    if (messageThreadId == null) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => MessageThreadView(
          messageThreadId: messageThreadId,
        ),
      ),
    );
  }

  void handleBackgroundStateMessage(RemoteMessage? message) {
    // Only handle if logged in.
    if (_connectionProvider.currentUser == null) return;
    if (message == null) return;

    if (message.data.isEmpty) return;
    // Retrieve message thread id from notification.
    final messageThreadId = _parseMessageThreadId(message);

    if (messageThreadId == null) return;
    // Pop until first, then push message thread view.
    // Prevents multiple instances of the same message thread being open.
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => MessageThreadView(
          messageThreadId: messageThreadId,
        ),
      ),
    );
  }

  Future initialisePushNotifications() async {
    // handle when opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    // handle when opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen(handleBackgroundStateMessage);
    // background handler
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    // foreground handler
    FirebaseMessaging.onMessage.listen((message) async {
      // only notify if logged in
      if (_connectionProvider.currentUser == null) return;

      final notification = message.notification;
      if (notification == null) return;

      // Update if message thread has been registered for updates,
      // otherwise notify.
      final messageThreadId = _parseMessageThreadId(message);

      final messageThreadViewActive = (messageThreadId != null &&
          _activeMessageThreadViewsMap[messageThreadId] != null);

      // Set iOS foregound notification options based on if message thread view
      // is active (i.e. the linked message thread is being viewed).
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: !messageThreadViewActive,
        badge: !messageThreadViewActive,
        sound: !messageThreadViewActive,
      );

      if (messageThreadViewActive) {
        _activeMessageThreadViewsMap[messageThreadId]!();
      } else {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidNotificationChannel.id,
              _androidNotificationChannel.name,
              channelDescription: _androidNotificationChannel.description,
              icon: '@drawable/notification_icon',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: jsonEncode(message.toMap()),
        );
      }

      // Disable iOS foreground notifications.
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      // Execute callbacks for views that have registered to listen to updates.
      for (final updateFunction in _activeUpdateFunctionsMap.values) {
        updateFunction();
      }
    });
  }

  Future initialiseLocalNotifications() async {
    const iOS = DarwinInitializationSettings();
    const android =
        AndroidInitializationSettings('@drawable/notification_icon');
    const settings = InitializationSettings(android: android, iOS: iOS);

    await _localNotifications.initialize(settings,
        onDidReceiveNotificationResponse: (notificationResponse) {
      final message =
          RemoteMessage.fromMap(jsonDecode(notificationResponse.payload!));
      handleMessage(message);
    });

    // Register Android notification channel.
    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidNotificationChannel);

    // Set iOS foregound notification options to not display.
    // FirebaseMessaging.onMessage.listen() above will manage iOS foreground notifications.
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
  }

  @override
  Future<void> initalise(ConnectionProvider connectionProvider,
      LocalStorageProvider localStorageProvider) async {
    if (_initialised) return;

    _connectionProvider = connectionProvider;
    _localStorageProvider = localStorageProvider;

    try {
      await FirebaseMessaging.instance.requestPermission();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      _pushNotificationToken = fcmToken;
      initialisePushNotifications();
      initialiseLocalNotifications();
      if (connectionProvider.currentUser != null &&
          fcmToken != null &&
          fcmToken.isNotEmpty) {
        await registerPushNotificationTokenWithServer();
      }
    } on Exception catch (_) {
      _pushNotificationTokenRegistered = false;
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      try {
        // Note: This callback is fired at each app startup and whenever a new
        // token is generated.
        _pushNotificationTokenRegistered = false;
        _pushNotificationToken = fcmToken;
        if (connectionProvider.currentUser != null && fcmToken.isNotEmpty) {
          await registerPushNotificationTokenWithServer();
        }
      } on Exception catch (_) {
        _pushNotificationTokenRegistered = false;
      }
    }).onError((err) {
      _pushNotificationTokenRegistered = false;
    });

    _initialised = true;

    return;
  }

  @override
  Future<void> registerPushNotificationTokenWithServer() async {
    if (_pushNotificationToken == null) return;

    if (_pushNotificationTokenRegistered) return;

    final databaseSystemSetting =
        await _localStorageProvider.getSystemSetting();

    final server =
        await _localStorageProvider.getServer(databaseSystemSetting.serverId);
    String secretKey = server.pnfpbKey ?? '';

    final iv = encrypt.IV.fromLength(16);

    final key = encrypt.Key.fromUtf8(secretKey); //hardcode

    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted =
        encrypter.encrypt(_pushNotificationToken.toString(), iv: iv);

    var hmacSha256 =
        crypto.Hmac(crypto.sha256, utf8.encode(secretKey)); // HMAC-SHA256

    var hmacstring =
        hmacSha256.convert(utf8.encode(_pushNotificationToken.toString()));

    var encryptedToken =
        "${encrypted.base64}:${iv.base64}:$hmacstring:$hmacstring";

    // register with server
    await _connectionProvider.registerFirebaseTokenWithPnfpb(encryptedToken);

    final storedFcmToken = databaseSystemSetting.firebasePushNotificationToken;

    if (storedFcmToken != _pushNotificationToken) {
      // save to local storage
      databaseSystemSetting.firebasePushNotificationToken =
          _pushNotificationToken!;
      await _localStorageProvider.updateSystemSetting(databaseSystemSetting);
    }

    _pushNotificationTokenRegistered = true;
  }

  @override
  String? get pushNotificationToken => _pushNotificationToken;

  @override
  bool get pushNotificationTokenRegistered => _pushNotificationTokenRegistered;

  @override
  set pushNotificationTokenRegistered(bool value) {
    _pushNotificationTokenRegistered = value;
  }

  @override
  void registerMessageThreadForUpdate(
      int messageThreadId, Function updateFunction) {
    // Not using a ??= here because the most recent view needs to be able
    // to register for updates, even if there is a previous view already open.
    // This is to cater for situations where a thread is opened while the app
    // has been minimised.
    _activeMessageThreadViewsMap[messageThreadId] = updateFunction;
  }

  @override
  void unregisterMessageThread(int messageThreadId) {
    _activeMessageThreadViewsMap.remove(messageThreadId);
  }

  int? _parseMessageThreadId(RemoteMessage remoteMessage) {
    final dataMessageThreadId = remoteMessage.data['thread_id'];
    return (dataMessageThreadId == null)
        ? dataMessageThreadId
        : int.tryParse(dataMessageThreadId);
  }

  @override
  void registerFunctionForUpdate(String uuid, Function updateFunction) {
    _activeUpdateFunctionsMap[uuid] ??= updateFunction;
  }

  @override
  void unregisterFunction(String uuid) {
    _activeUpdateFunctionsMap.remove(uuid);
  }
}
