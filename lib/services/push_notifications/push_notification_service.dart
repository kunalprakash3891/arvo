import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/push_notifications/firebase_push_notification_provider.dart';
import 'package:arvo/services/push_notifications/push_notification_provider.dart';

class PushNotificationService implements PushNotificationProvider {
  final PushNotificationProvider provider;
  const PushNotificationService(this.provider);

  factory PushNotificationService.firebase() =>
      PushNotificationService(FirebasePushNotificationProvider());

  @override
  String? get pushNotificationToken => provider.pushNotificationToken;

  @override
  bool get pushNotificationTokenRegistered =>
      provider.pushNotificationTokenRegistered;

  @override
  Future<void> initalise(ConnectionProvider connectionProvider,
          LocalStorageProvider localStorageProvider) =>
      provider.initalise(connectionProvider, localStorageProvider);

  @override
  Future<void> registerPushNotificationTokenWithServer() =>
      provider.registerPushNotificationTokenWithServer();

  @override
  set pushNotificationTokenRegistered(bool value) =>
      provider.pushNotificationTokenRegistered = value;

  @override
  void registerMessageThreadForUpdate(
          int messageThreadId, Function updateFunction) =>
      provider.registerMessageThreadForUpdate(messageThreadId, updateFunction);

  @override
  void unregisterMessageThread(int messageThreadId) =>
      provider.unregisterMessageThread(messageThreadId);

  @override
  void registerFunctionForUpdate(String uuid, Function updateFunction) =>
      provider.registerFunctionForUpdate(uuid, updateFunction);

  @override
  void unregisterFunction(String uuid) => provider.unregisterFunction(uuid);
}
