import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';

class LocalStorageService implements LocalStorageProvider {
  final LocalStorageProvider provider;
  const LocalStorageService(this.provider);

  factory LocalStorageService.arvo() =>
      LocalStorageService(ArvoLocalStorageProvider());

  @override
  Stream<List<DatabaseServer>> get allServers => provider.allServers;

  @override
  Future<DatabaseServer> createServer(String url, String? pnfpbKey) =>
      provider.createServer(url, pnfpbKey);

  @override
  Future<DatabaseServer> getServer(int id) => provider.getServer(id);

  @override
  Future<Iterable<DatabaseServer>> getAllServers() => provider.getAllServers();

  @override
  Future<DatabaseServer> updateServer(DatabaseServer server) =>
      provider.updateServer(server);

  @override
  Future<void> deleteServer(int id) => provider.deleteServer(id);

  @override
  Future<DatabaseSystemSetting> createSystemSetting(
          DatabaseSystemSetting databaseSystemSetting) =>
      provider.createSystemSetting(databaseSystemSetting);

  @override
  Future<DatabaseSystemSetting> getSystemSetting() =>
      provider.getSystemSetting();

  @override
  Future<DatabaseSystemSetting> updateSystemSetting(
          DatabaseSystemSetting newSystemSetting) =>
      provider.updateSystemSetting(newSystemSetting);

  @override
  Future<void> deleteSystemSetting(int id) => provider.deleteSystemSetting(id);

  @override
  Future<DatabaseUserSetting> createUserSetting(
          DatabaseUserSetting databaseUserSetting) =>
      provider.createUserSetting(databaseUserSetting);

  @override
  Future<DatabaseUserSetting> getUserSetting(int userId) =>
      provider.getUserSetting(userId);

  @override
  Future<DatabaseUserSetting> updateUserSetting(
          DatabaseUserSetting userSetting) =>
      provider.updateUserSetting(userSetting);

  @override
  Future<void> deleteUserSetting(int userId) =>
      provider.deleteUserSetting(userId);

  @override
  Future<void> close() => provider.close();

  @override
  Future<void> open() => provider.open();
}
