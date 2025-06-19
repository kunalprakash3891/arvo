import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';

abstract class PushNotificationProvider {
  String? get pushNotificationToken;
  bool get pushNotificationTokenRegistered;
  set pushNotificationTokenRegistered(bool value);

  Future<void> initalise(ConnectionProvider connectionProvider,
      LocalStorageProvider localStorageProvider);
  Future<void> registerPushNotificationTokenWithServer();
  void registerMessageThreadForUpdate(
      int messageThreadId, Function updateFunction);
  void unregisterMessageThread(int messageThreadId);
  void registerFunctionForUpdate(String uuid, Function updateFunction);
  void unregisterFunction(String uuid);
}
