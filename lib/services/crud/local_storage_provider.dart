import 'package:arvo/services/crud/arvo_local_storage_provider.dart';

abstract class LocalStorageProvider {
  Stream<List<DatabaseServer>> get allServers;

  Future<DatabaseServer> createServer(String url, String? pnfpbKey);

  Future<DatabaseServer> getServer(int id);

  Future<Iterable<DatabaseServer>> getAllServers();

  Future<DatabaseServer> updateServer(
    DatabaseServer server,
  );

  Future<void> deleteServer(int id);

  Future<DatabaseSystemSetting> createSystemSetting(
      DatabaseSystemSetting databaseSystemSetting);

  Future<DatabaseSystemSetting> getSystemSetting();

  Future<DatabaseSystemSetting> updateSystemSetting(
    DatabaseSystemSetting systemSetting,
  );

  Future<void> deleteSystemSetting(int id);

  Future<DatabaseUserSetting> createUserSetting(
      DatabaseUserSetting databaseUserSetting);

  Future<DatabaseUserSetting> getUserSetting(int userId);

  Future<DatabaseUserSetting> updateUserSetting(
    DatabaseUserSetting userSetting,
  );

  Future<void> deleteUserSetting(int userId);

  Future<void> close();

  Future<void> open();
}
