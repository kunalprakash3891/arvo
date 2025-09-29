import 'dart:async';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

import 'crud_exceptions.dart';

class ArvoLocalStorageProvider implements LocalStorageProvider {
  Database? _db;

  List<DatabaseServer> _servers = [];

  // create as singleton
  static final _shared = ArvoLocalStorageProvider._sharedInstance();
  ArvoLocalStorageProvider._sharedInstance() {
    {
      // .broadcast allows listening to the stream more than once
      // handy for situations like hot reload (would error otherwise)
      _serversStreamController =
          StreamController<List<DatabaseServer>>.broadcast(
        onListen: () {
          _serversStreamController.sink.add(_servers);
        },
      );
    }
  }
  factory ArvoLocalStorageProvider() => _shared;

  late final StreamController<List<DatabaseServer>> _serversStreamController;

  @override
  Stream<List<DatabaseServer>> get allServers =>
      _serversStreamController.stream;

  Future<void> _cacheServers() async {
    final allServers = await getAllServers();
    _servers = allServers.toList();
    _serversStreamController.add(_servers);
  }

// server
  @override
  Future<DatabaseServer> createServer(String url, String? pnfpbKey) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      serverTable,
      limit: 1,
      where: 'url = ?',
      whereArgs: [
        url,
      ],
    );
    if (results.isNotEmpty) {
      throw ServerAlreadyExistsException();
    }
    final serverId = await db.insert(
      serverTable,
      {
        urlColumn: url.toLowerCase(),
        pnfpbKeyColumn: pnfpbKey,
      },
    );

    final server = DatabaseServer(
      id: serverId,
      url: url,
      pnfpbKey: pnfpbKey,
    );

    //add to local cache, then add to our stream controller to update UI
    _servers.add(server);
    _serversStreamController.add(_servers);

    return server;
  }

  @override
  Future<DatabaseServer> getServer(int id) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      serverTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [
        id,
      ],
    );
    if (results.isEmpty) {
      throw CouldNotFindServerException();
    }
    final server = DatabaseServer.fromRow(results.first);

    // update our local cache, in case it still has the old record
    // then and add to our stream controller to update UI
    _servers.removeWhere((server) => server.id == id);
    _servers.add(server);
    _serversStreamController.add(_servers);

    return server;
  }

  @override
  Future<Iterable<DatabaseServer>> getAllServers() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(serverTable);

    return results.map((resultsRow) => DatabaseServer.fromRow(resultsRow));
  }

  @override
  Future<DatabaseServer> updateServer(
    DatabaseServer server,
  ) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure it exists
    final previousServer = await getServer(server.id);

    final updatedCount = await db.update(
      serverTable,
      {
        urlColumn: server.url,
        pnfpbKeyColumn: server.pnfpbKey,
      },
      where: 'id = ?',
      whereArgs: [previousServer.id],
    );

    if (updatedCount == 0) {
      throw CouldNotUpdateServerException();
    } else {
      final updatedServer = await getServer(server.id);
      _servers.removeWhere((server) => server.id == updatedServer.id);
      _servers.add(updatedServer);
      _serversStreamController.add(_servers);
      return updatedServer;
    }
  }

  @override
  Future<void> deleteServer(int id) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      serverTable,
      where: 'id = ?',
      whereArgs: [
        id,
      ],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteServerException();
    } else {
      //remove from local cache, then add to our stream controller to update UI
      _servers.removeWhere((server) => server.id == id);
      _serversStreamController.add(_servers);
    }
  }

// system_setting
  @override
  Future<DatabaseSystemSetting> createSystemSetting(
      DatabaseSystemSetting databaseSystemSetting) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      systemSettingTable,
      limit: 1,
    );
    if (results.isNotEmpty) {
      throw SystemSettingAlreadyExistsException();
    }
    final systemSettingId = await db.insert(
      systemSettingTable,
      {
        serverIdColumn: databaseSystemSetting.serverId,
        logInTokenColumn: databaseSystemSetting.logInToken,
        logInUserNameColumn: databaseSystemSetting.logInUserName,
        logInPasswordColumn: databaseSystemSetting.logInPassword,
        rememberLogInColumn: databaseSystemSetting.rememberLogIn ? 1 : 0,
        firebaseEventLoggingColumn:
            databaseSystemSetting.firebaseEventLogging ? 1 : 0,
        developmentModeColumn: databaseSystemSetting.developmentMode ? 1 : 0,
        showDemoUsersColumn: databaseSystemSetting.showDemoUsers ? 1 : 0,
        showTeamMembersColumn: databaseSystemSetting.showTeamMembers ? 1 : 0,
        showContributorsColumn: databaseSystemSetting.showContributors ? 1 : 0,
        bypassStoreColumn: databaseSystemSetting.bypassStore ? 1 : 0,
        firebasePushNotificationTokenColumn:
            databaseSystemSetting.firebasePushNotificationToken,
        hasRegistedColumn: databaseSystemSetting.hasRegistered ? 1 : 0,
        messageCountLimitPerThreadColumn:
            databaseSystemSetting.messageCountLimitPerThread,
        maxPendingMessageRepliesColumn:
            databaseSystemSetting.maxPendingMessageReplies,
        adDisplayIntervalColumn: databaseSystemSetting.adDisplayInterval,
      },
    );
    return DatabaseSystemSetting(
      id: systemSettingId,
      serverId: databaseSystemSetting.serverId,
      logInToken: databaseSystemSetting.logInToken,
      logInUserName: databaseSystemSetting.logInUserName,
      logInPassword: databaseSystemSetting.logInPassword,
      rememberLogIn: databaseSystemSetting.rememberLogIn,
      firebaseEventLogging: databaseSystemSetting.firebaseEventLogging,
      developmentMode: databaseSystemSetting.developmentMode,
      showDemoUsers: databaseSystemSetting.showDemoUsers,
      showTeamMembers: databaseSystemSetting.showTeamMembers,
      showContributors: databaseSystemSetting.showContributors,
      bypassStore: databaseSystemSetting.bypassStore,
      firebasePushNotificationToken:
          databaseSystemSetting.firebasePushNotificationToken,
      hasRegistered: databaseSystemSetting.hasRegistered,
      messageCountLimitPerThread:
          databaseSystemSetting.messageCountLimitPerThread,
      maxPendingMessageReplies: databaseSystemSetting.maxPendingMessageReplies,
      adDisplayInterval: databaseSystemSetting.adDisplayInterval,
    );
  }

  @override
  Future<DatabaseSystemSetting> getSystemSetting() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      systemSettingTable,
      limit: 1,
    );
    if (results.isEmpty) {
      throw CouldNotFindSystemSettingException();
    }
    return DatabaseSystemSetting.fromRow(results.first);
  }

  @override
  Future<DatabaseSystemSetting> updateSystemSetting(
    DatabaseSystemSetting systemSetting,
  ) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure it exists
    final previousSystemSetting = await getSystemSetting();

    final updatedCount = await db.update(
      systemSettingTable,
      {
        serverIdColumn: systemSetting.serverId,
        logInTokenColumn: systemSetting.logInToken,
        logInUserNameColumn: systemSetting.logInUserName,
        logInPasswordColumn: systemSetting.logInPassword,
        rememberLogInColumn: systemSetting.rememberLogIn ? 1 : 0,
        firebaseEventLoggingColumn: systemSetting.firebaseEventLogging ? 1 : 0,
        developmentModeColumn: systemSetting.developmentMode ? 1 : 0,
        showDemoUsersColumn: systemSetting.showDemoUsers ? 1 : 0,
        showTeamMembersColumn: systemSetting.showTeamMembers ? 1 : 0,
        showContributorsColumn: systemSetting.showContributors ? 1 : 0,
        bypassStoreColumn: systemSetting.bypassStore ? 1 : 0,
        firebasePushNotificationTokenColumn:
            systemSetting.firebasePushNotificationToken,
        passwordResetRequestTimestampColumn:
            systemSetting.passwordResetRequestTimestamp,
        hasRegistedColumn: systemSetting.hasRegistered ? 1 : 0,
        messageCountLimitPerThreadColumn:
            systemSetting.messageCountLimitPerThread,
        maxPendingMessageRepliesColumn: systemSetting.maxPendingMessageReplies,
        adDisplayIntervalColumn: systemSetting.adDisplayInterval,
      },
      where: 'id = ?',
      whereArgs: [previousSystemSetting.id],
    );

    if (updatedCount == 0) {
      throw CouldNotUpdateSystemSettingException();
    } else {
      return await getSystemSetting();
    }
  }

  @override
  Future<void> deleteSystemSetting(int id) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      systemSettingTable,
      where: 'id = ?',
      whereArgs: [
        id,
      ],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteSystemSettingException();
    }
  }

// user_setting
  @override
  Future<DatabaseUserSetting> createUserSetting(
      DatabaseUserSetting databaseUserSetting) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final results = await db.query(
      userSettingTable,
      limit: 1,
      where: 'user_id = ?',
      whereArgs: [
        databaseUserSetting.userId,
      ],
    );
    if (results.isNotEmpty) {
      throw UserSettingAlreadyExistsException();
    }
    final userSettingId = await db.insert(
      userSettingTable,
      {
        userIdColumn: databaseUserSetting.userId,
        memberSearchConnectionTypesColumn:
            databaseUserSetting.memberSearchConnectionTypes,
        memberSearchSexualOrientationsColumn:
            databaseUserSetting.memberSearchSexualOrientations,
        memberSearchGendersColumn: databaseUserSetting.memberSearchGenders,
        memberSearchLocationsColumn: databaseUserSetting.memberSearchLocations,
        memberSearchPassionsColumn: databaseUserSetting.memberSearchPassions,
        memberSearchEthnicitiesColumn:
            databaseUserSetting.memberSearchEthnicities,
        memberSearchAgeFromColumn: databaseUserSetting.memberSearchAgeFrom,
        memberSearchAgeToColumn: databaseUserSetting.memberSearchAgeTo,
        memberSearchPhotoTypeColumn: databaseUserSetting.memberSearchPhotoType,
        memberSearchKeyColumn: databaseUserSetting.memberSearchKey,
        memberSearchOrderTypeColumn: databaseUserSetting.memberSearchOrderType,
        featureAdFreeColumn: databaseUserSetting.featureAdFree ? 1 : 0,
        featureThemeControlColumn:
            databaseUserSetting.featureThemeControl ? 1 : 0,
        featureSelectedThemeColumn: databaseUserSetting.featureSelectedTheme,
        featurePhotoTypeSearchColumn:
            databaseUserSetting.featurePhotoTypeSearch ? 1 : 0,
        featureMatchInsightColumn:
            databaseUserSetting.featureMatchInsight ? 1 : 0,
        featureMemberOnlineIndicatorColumn:
            databaseUserSetting.featureMemberOnlineIndicator ? 1 : 0,
        featureCustomOpenersColumn:
            databaseUserSetting.featureCustomOpeners ? 1 : 0,
        featureFavouritedMeColumn:
            databaseUserSetting.featureFavouritedMe ? 1 : 0,
        showTipFiltersAppliedColumn:
            databaseUserSetting.showTipFiltersApplied ? 1 : 0,
        showTipSwipeColumn: databaseUserSetting.showTipSwipe ? 1 : 0,
        showTipMessageGuidelinesColumn:
            databaseUserSetting.showTipMessageGuidelines ? 1 : 0,
      },
    );
    return DatabaseUserSetting(
      id: userSettingId,
      userId: databaseUserSetting.userId,
      memberSearchConnectionTypes:
          databaseUserSetting.memberSearchConnectionTypes,
      memberSearchSexualOrientations:
          databaseUserSetting.memberSearchSexualOrientations,
      memberSearchGenders: databaseUserSetting.memberSearchGenders,
      memberSearchLocations: databaseUserSetting.memberSearchLocations,
      memberSearchPassions: databaseUserSetting.memberSearchPassions,
      memberSearchEthnicities: databaseUserSetting.memberSearchEthnicities,
      memberSearchAgeFrom: databaseUserSetting.memberSearchAgeFrom,
      memberSearchAgeTo: databaseUserSetting.memberSearchAgeTo,
      memberSearchPhotoType: databaseUserSetting.memberSearchPhotoType,
      memberSearchKey: databaseUserSetting.memberSearchKey,
      memberSearchOrderType: databaseUserSetting.memberSearchOrderType,
      featureAdFree: databaseUserSetting.featureAdFree,
      featureThemeControl: databaseUserSetting.featureThemeControl,
      featureSelectedTheme: databaseUserSetting.featureSelectedTheme,
      featurePhotoTypeSearch: databaseUserSetting.featurePhotoTypeSearch,
      featureMatchInsight: databaseUserSetting.featureMatchInsight,
      featureMemberOnlineIndicator:
          databaseUserSetting.featureMemberOnlineIndicator,
      featureCustomOpeners: databaseUserSetting.featureCustomOpeners,
      featureFavouritedMe: databaseUserSetting.featureFavouritedMe,
      showTipFiltersApplied: databaseUserSetting.showTipFiltersApplied,
      showTipSwipe: databaseUserSetting.showTipSwipe,
      showTipMessageGuidelines: databaseUserSetting.showTipMessageGuidelines,
    );
  }

  @override
  Future<DatabaseUserSetting> getUserSetting(int userId) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userSettingTable,
      limit: 1,
      where: "user_id = ?",
      whereArgs: [
        userId,
      ],
    );
    if (results.isEmpty) {
      throw CouldNotFindUserSettingException();
    }
    return DatabaseUserSetting.fromRow(results.first);
  }

  @override
  Future<DatabaseUserSetting> updateUserSetting(
    DatabaseUserSetting userSetting,
  ) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure it exists
    final previousUserSetting = await getUserSetting(userSetting.userId);

    final updatedCount = await db.update(
      userSettingTable,
      {
        memberSearchConnectionTypesColumn:
            userSetting.memberSearchConnectionTypes,
        memberSearchSexualOrientationsColumn:
            userSetting.memberSearchSexualOrientations,
        memberSearchGendersColumn: userSetting.memberSearchGenders,
        memberSearchLocationsColumn: userSetting.memberSearchLocations,
        memberSearchPassionsColumn: userSetting.memberSearchPassions,
        memberSearchEthnicitiesColumn: userSetting.memberSearchEthnicities,
        memberSearchAgeFromColumn: userSetting.memberSearchAgeFrom,
        memberSearchAgeToColumn: userSetting.memberSearchAgeTo,
        memberSearchPhotoTypeColumn: userSetting.memberSearchPhotoType,
        memberSearchKeyColumn: userSetting.memberSearchKey,
        memberSearchOrderTypeColumn: userSetting.memberSearchOrderType,
        lastNewMessageSentTimestampColumn:
            userSetting.lastNewMessageSentTimestamp,
        newMessagesSentCountColumn: userSetting.newMessagesSentCount,
        lastFavouriteAddedTimestampColumn:
            userSetting.lastFavouriteAddedTimestamp,
        newFavouritesAddedCountColumn: userSetting.newFavouritesAddedCount,
        featureAdFreeColumn: userSetting.featureAdFree ? 1 : 0,
        featureThemeControlColumn: userSetting.featureThemeControl ? 1 : 0,
        featureSelectedThemeColumn: userSetting.featureSelectedTheme,
        featurePhotoTypeSearchColumn:
            userSetting.featurePhotoTypeSearch ? 1 : 0,
        featureMatchInsightColumn: userSetting.featureMatchInsight ? 1 : 0,
        featureMemberOnlineIndicatorColumn:
            userSetting.featureMemberOnlineIndicator ? 1 : 0,
        featureCustomOpenersColumn: userSetting.featureCustomOpeners ? 1 : 0,
        featureFavouritedMeColumn: userSetting.featureFavouritedMe ? 1 : 0,
        showTipFiltersAppliedColumn: userSetting.showTipFiltersApplied ? 1 : 0,
        showTipSwipeColumn: userSetting.showTipSwipe ? 1 : 0,
        showTipMessageGuidelinesColumn:
            userSetting.showTipMessageGuidelines ? 1 : 0,
      },
      where: 'user_id = ?',
      whereArgs: [userSetting.userId],
    );

    if (updatedCount == 0) {
      throw CouldNotUpdateUserSettingException();
    } else {
      return await getUserSetting(previousUserSetting.userId);
    }
  }

  @override
  Future<void> deleteUserSetting(int userId) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userSettingTable,
      where: 'user_id = ?',
      whereArgs: [
        userId,
      ],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUserSettingException();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      return db;
    }
  }

  @override
  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      // empty
    }
  }

  @override
  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }

    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      // Create tables.
      await _createTables(db);

      // Insert defaults.
      await _insertDefaults(db);

      // Apply database updates.
      await _applyDatabaseUpdates(db);

      // cache all the servers
      await _cacheServers();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryException();
    }
  }

  Future<void> _createTables(Database db) async {
    // create server table
    await db.execute(createServerTable);
    // create system_setting table
    await db.execute(createSystemSettingTable);
    // create user_setting table
    await db.execute(createUserSettingTable);
  }

  Future<void> _insertDefaults(Database db) async {
    // insert default servers if no servers available
    final servers = await db.query(serverTable);
    if (servers.isEmpty) {
      await db.execute(insertDefaultServers);
    }

    // insert system_setting if none available
    final systemSetting = await db.query(systemSettingTable);
    if (systemSetting.isEmpty) {
      final serverId = (await getAllServers()).first.id;

      final databaseSystemSetting = DatabaseSystemSetting(
        id: 0,
        serverId: serverId,
        logInToken: '',
        logInUserName: '',
        logInPassword: '',
        rememberLogIn: true,
        firebaseEventLogging: true,
        developmentMode: false,
        showDemoUsers: false,
        showTeamMembers: false,
        showContributors: false,
        bypassStore: false,
        firebasePushNotificationToken: '',
        hasRegistered: false,
        messageCountLimitPerThread: 500,
        maxPendingMessageReplies: 10,
        adDisplayInterval: 1,
      );
      await createSystemSetting(databaseSystemSetting);

      // No system_setting, so this is a brand new install.
      // Set the database version to be the latest.
      db.setVersion(_latestDatabaseVersion);
    }
  }

  Future<void> _applyDatabaseUpdates(Database db) async {
    var existingDatabaseVersion = await db.getVersion();

    try {
      while (existingDatabaseVersion < _latestDatabaseVersion) {
        final nextDatabaseVersion = existingDatabaseVersion + 1;
        await _updateDatabaseVersion(nextDatabaseVersion);
        existingDatabaseVersion = await db.getVersion();
      }
    } on Exception catch (_) {
      // Update failed, can't do much from this point.
      // Drop and recreate tables and defaults.
      await _dropTables(db);
      await _createTables(db);
      await _insertDefaults(db);
    }
  }

  Future<void> _dropTables(Database db) async {
    // drop server table
    await db.execute(dropServerTable);
    // drop system_setting table
    await db.execute(dropSystemSettingTable);
    // drop user_setting table
    await db.execute(dropUserSettingTable);
  }

  // For database updates, increment _latestDatabaseVersion and
  // add any database update queries to _updateDatabaseVersion below.

  // NOTE: _latestDatabaseVersion is also used by _insertDefaults() when
  // creating system_setting.

  // NOTE: When extending or modifying database tables, make sure to add the
  // changes to the create scripts as well as adding the differences as update
  // scripts to _updateDatabaseVersion.
  static const _latestDatabaseVersion = 0;

  Future<void> _updateDatabaseVersion(int version) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    switch (version) {
      case 1:
        // Update to version 1.
        // Excecute queries here.
        // e.g. await db.execute(alterTableQueryHere);
        break;
      case 2:
        // Update to version 2.
        // Excecute queries here.
        // e.g. await db.execute(alterTableQueryHere);
        break;
      default:
        break;
    }
    db.setVersion(version);
  }
}

class DatabaseSystemSettingLegacy {
  String loggedInToken;
  String logInUserName;
  String logInPassword;

  DatabaseSystemSettingLegacy({
    required this.loggedInToken,
    required this.logInUserName,
    required this.logInPassword,
  });

  DatabaseSystemSettingLegacy.fromRow(Map<String, Object?> map)
      : loggedInToken = map['LoggedInToken'] as String,
        logInUserName = map['LogInUserName'] as String,
        logInPassword = map['LogInPassword'] as String;
}

class DatabaseServer {
  final int id;
  String url;
  String? pnfpbKey;

  DatabaseServer({
    required this.id,
    required this.url,
    this.pnfpbKey,
  });

  DatabaseServer.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        url = map[urlColumn] as String,
        pnfpbKey = map[pnfpbKeyColumn] as String;

  @override
  String toString() => 'Server, ID = $id, url = $url';

  @override
  bool operator ==(covariant DatabaseServer other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

int _oneSmallStep = DateTime.parse('1969-07-20 20:17:00Z')
    .millisecondsSinceEpoch; // Moon landing, 20th July 1969, 8:17pm UTC.

class DatabaseSystemSetting {
  final int id;
  int serverId;
  String logInToken;
  String logInUserName;
  String logInPassword;
  bool rememberLogIn;
  bool firebaseEventLogging;
  bool developmentMode;
  bool showDemoUsers;
  bool showTeamMembers;
  bool showContributors;
  bool bypassStore;
  String firebasePushNotificationToken;
  int passwordResetRequestTimestamp = _oneSmallStep;
  bool hasRegistered;
  int messageCountLimitPerThread;
  int maxPendingMessageReplies;
  int adDisplayInterval;

  DatabaseSystemSetting({
    required this.id,
    required this.serverId,
    required this.logInToken,
    required this.logInUserName,
    required this.logInPassword,
    required this.rememberLogIn,
    required this.firebaseEventLogging,
    required this.developmentMode,
    required this.showDemoUsers,
    required this.showTeamMembers,
    required this.showContributors,
    required this.bypassStore,
    required this.firebasePushNotificationToken,
    required this.hasRegistered,
    required this.messageCountLimitPerThread,
    required this.maxPendingMessageReplies,
    required this.adDisplayInterval,
  });

  DatabaseSystemSetting.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        serverId = map[serverIdColumn] as int,
        logInToken = map[logInTokenColumn] as String,
        logInUserName = map[logInUserNameColumn] as String,
        logInPassword = map[logInPasswordColumn] as String,
        rememberLogIn = (map[rememberLogInColumn] as int) == 1 ? true : false,
        firebaseEventLogging =
            (map[firebaseEventLoggingColumn] as int) == 1 ? true : false,
        developmentMode =
            (map[developmentModeColumn] as int) == 1 ? true : false,
        showDemoUsers = (map[showDemoUsersColumn] as int) == 1 ? true : false,
        showTeamMembers =
            (map[showTeamMembersColumn] as int) == 1 ? true : false,
        showContributors =
            (map[showContributorsColumn] as int) == 1 ? true : false,
        bypassStore = (map[bypassStoreColumn] as int) == 1 ? true : false,
        firebasePushNotificationToken =
            map[firebasePushNotificationTokenColumn] as String,
        passwordResetRequestTimestamp =
            map[passwordResetRequestTimestampColumn] as int,
        hasRegistered = (map[hasRegistedColumn] as int) == 1 ? true : false,
        messageCountLimitPerThread =
            map[messageCountLimitPerThreadColumn] as int,
        maxPendingMessageReplies = map[maxPendingMessageRepliesColumn] as int,
        adDisplayInterval = map[adDisplayIntervalColumn] as int;

  @override
  String toString() =>
      'System Setting, ID = $id, serverId = $serverId, logInToken = $logInToken, logInUserName = $logInUserName, logInPassword = $logInPassword, rememberLogIn = $rememberLogIn, firebaseEventLogging = $firebaseEventLogging, developmentMode = $developmentMode, showDemoUsers = $showDemoUsers, showTeamMembers = $showTeamMembers, showContributors = $showContributors, bypassStore = $bypassStore, firebasePushNotificationToken = $firebasePushNotificationToken, hasRegisterd = $hasRegistered, messageCountLimitPerThread = $messageCountLimitPerThread, maxPendingMessageReplies = $maxPendingMessageReplies, adDisplayInterval = $adDisplayInterval';

  @override
  bool operator ==(covariant DatabaseSystemSetting other) =>
      other.id == id &&
      other.serverId == serverId &&
      other.logInToken == logInToken &&
      other.logInUserName == logInUserName &&
      other.logInPassword == logInPassword &&
      other.rememberLogIn == rememberLogIn &&
      other.firebaseEventLogging == firebaseEventLogging &&
      other.developmentMode == developmentMode &&
      other.showDemoUsers == showDemoUsers &&
      other.showTeamMembers == showTeamMembers &&
      other.showContributors == showContributors &&
      other.bypassStore == bypassStore &&
      other.firebasePushNotificationToken == firebasePushNotificationToken &&
      other.passwordResetRequestTimestamp == passwordResetRequestTimestamp &&
      other.hasRegistered == hasRegistered &&
      other.messageCountLimitPerThread == messageCountLimitPerThread &&
      other.maxPendingMessageReplies == maxPendingMessageReplies &&
      other.adDisplayInterval == adDisplayInterval;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseUserSetting {
  final int id;
  final int userId;
  String memberSearchConnectionTypes;
  String memberSearchSexualOrientations;
  String memberSearchGenders;
  String memberSearchLocations;
  String memberSearchPassions;
  String memberSearchEthnicities;
  int memberSearchAgeFrom;
  int memberSearchAgeTo;
  int memberSearchPhotoType;
  String memberSearchKey;
  int memberSearchOrderType;
  int lastNewMessageSentTimestamp = _oneSmallStep;
  int newMessagesSentCount = 0;
  int lastFavouriteAddedTimestamp = _oneSmallStep;
  int newFavouritesAddedCount = 0;
  bool featureAdFree; // For subscription ads.
  bool featureThemeControl;
  int featureSelectedTheme;
  bool featurePhotoTypeSearch;
  bool featureMatchInsight;
  bool featureMemberOnlineIndicator;
  bool featureCustomOpeners;
  bool featureFavouritedMe;
  bool showTipFiltersApplied;
  bool showTipSwipe;
  bool showTipMessageGuidelines;

  DatabaseUserSetting({
    required this.id,
    required this.userId,
    required this.memberSearchConnectionTypes,
    required this.memberSearchSexualOrientations,
    required this.memberSearchGenders,
    required this.memberSearchLocations,
    required this.memberSearchPassions,
    required this.memberSearchEthnicities,
    required this.memberSearchAgeFrom,
    required this.memberSearchAgeTo,
    required this.memberSearchPhotoType,
    required this.memberSearchKey,
    required this.memberSearchOrderType,
    required this.featureAdFree,
    required this.featureThemeControl,
    required this.featureSelectedTheme,
    required this.featurePhotoTypeSearch,
    required this.featureMatchInsight,
    required this.featureMemberOnlineIndicator,
    required this.featureCustomOpeners,
    required this.featureFavouritedMe,
    required this.showTipFiltersApplied,
    required this.showTipSwipe,
    required this.showTipMessageGuidelines,
  });

  DatabaseUserSetting.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        memberSearchConnectionTypes =
            map[memberSearchConnectionTypesColumn] as String,
        memberSearchSexualOrientations =
            map[memberSearchSexualOrientationsColumn] as String,
        memberSearchGenders = map[memberSearchGendersColumn] as String,
        memberSearchLocations = map[memberSearchLocationsColumn] as String,
        memberSearchPassions = map[memberSearchPassionsColumn] as String,
        memberSearchEthnicities = map[memberSearchEthnicitiesColumn] as String,
        memberSearchAgeFrom = map[memberSearchAgeFromColumn] as int,
        memberSearchAgeTo = map[memberSearchAgeToColumn] as int,
        memberSearchPhotoType = map[memberSearchPhotoTypeColumn] as int,
        memberSearchKey = map[memberSearchKeyColumn] as String,
        memberSearchOrderType = map[memberSearchOrderTypeColumn] as int,
        lastNewMessageSentTimestamp =
            map[lastNewMessageSentTimestampColumn] as int,
        newMessagesSentCount = map[newMessagesSentCountColumn] as int,
        lastFavouriteAddedTimestamp =
            map[lastFavouriteAddedTimestampColumn] as int,
        newFavouritesAddedCount = map[newFavouritesAddedCountColumn] as int,
        featureAdFree = (map[featureAdFreeColumn] as int) == 1 ? true : false,
        featureThemeControl =
            (map[featureThemeControlColumn] as int) == 1 ? true : false,
        featureSelectedTheme = map[featureSelectedThemeColumn] as int,
        featurePhotoTypeSearch =
            (map[featurePhotoTypeSearchColumn] as int) == 1 ? true : false,
        featureMatchInsight =
            (map[featureMatchInsightColumn] as int) == 1 ? true : false,
        featureMemberOnlineIndicator =
            (map[featureMemberOnlineIndicatorColumn] as int) == 1
                ? true
                : false,
        featureCustomOpeners =
            (map[featureCustomOpenersColumn] as int) == 1 ? true : false,
        featureFavouritedMe =
            (map[featureFavouritedMeColumn] as int) == 1 ? true : false,
        showTipFiltersApplied =
            (map[showTipFiltersAppliedColumn] as int) == 1 ? true : false,
        showTipSwipe = (map[showTipSwipeColumn] as int) == 1 ? true : false,
        showTipMessageGuidelines =
            (map[showTipMessageGuidelinesColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'User Setting, ID = $id, memberSearchConnectionTypes = $memberSearchConnectionTypes, memberSearchSexualOrientations = $memberSearchSexualOrientations, memberSearchGenders = $memberSearchGenders, memberSearchLocations = $memberSearchLocations, memberSearchPassions = $memberSearchPassions, memberSearchEthnicities = $memberSearchEthnicities, memberSearchAgeFrom = $memberSearchAgeFrom, memberSearchAgeTo = $memberSearchAgeTo, memberSearchPhotoType = $memberSearchPhotoType, memberSearchKey = $memberSearchKey, memberSearchOrderType = $memberSearchOrderType, lastSentMessageTimestamp = $lastNewMessageSentTimestamp, newMessagesSentCount = $newMessagesSentCount, lastFavouriteAddedTimestamp = $lastFavouriteAddedTimestamp, newFavouritesAddedCount = $newFavouritesAddedCount, featureAdFree = $featureAdFree, featureThemeControl = $featureThemeControl,  featureSelectedTheme = $featureSelectedTheme, featurePhotoTypeSearch = $featurePhotoTypeSearch, featureMatchInsight = $featureMatchInsight, featureMemberOnlineIndicator = $featureMemberOnlineIndicator, featureCustomOpeners = $featureCustomOpeners, featureFavouritedMe = $featureFavouritedMe, showTipFiltersApplied = $showTipFiltersApplied, showTipSwipe = $showTipSwipe, showTipMessageGuidelines = $showTipMessageGuidelines';

  @override
  bool operator ==(covariant DatabaseUserSetting other) =>
      other.id == id &&
      other.userId == userId &&
      other.memberSearchConnectionTypes == memberSearchConnectionTypes &&
      other.memberSearchSexualOrientations == memberSearchSexualOrientations &&
      other.memberSearchGenders == memberSearchGenders &&
      other.memberSearchLocations == memberSearchLocations &&
      other.memberSearchPassions == memberSearchPassions &&
      other.memberSearchEthnicities == memberSearchEthnicities &&
      other.memberSearchAgeFrom == memberSearchAgeFrom &&
      other.memberSearchAgeTo == memberSearchAgeTo &&
      other.memberSearchPhotoType == memberSearchPhotoType &&
      other.memberSearchKey == memberSearchKey &&
      other.memberSearchOrderType == memberSearchOrderType &&
      other.lastNewMessageSentTimestamp == lastNewMessageSentTimestamp &&
      other.newMessagesSentCount == newMessagesSentCount &&
      other.lastFavouriteAddedTimestamp == lastFavouriteAddedTimestamp &&
      other.newFavouritesAddedCount == newFavouritesAddedCount &&
      other.featureAdFree == featureAdFree &&
      other.featureThemeControl == featureThemeControl &&
      other.featureSelectedTheme == featureSelectedTheme &&
      other.featurePhotoTypeSearch == featurePhotoTypeSearch &&
      other.featureMatchInsight == featureMatchInsight &&
      other.featureMemberOnlineIndicator == featureMemberOnlineIndicator &&
      other.featureCustomOpeners == featureCustomOpeners &&
      other.featureFavouritedMe == featureFavouritedMe &&
      other.showTipFiltersApplied == showTipFiltersApplied &&
      other.showTipSwipe == showTipSwipe &&
      other.showTipMessageGuidelines == showTipMessageGuidelines;

  @override
  int get hashCode => id.hashCode;
}

// db
const dbName = 'local.db';

// tables
const serverTable = 'server';
const systemSettingTable = 'system_setting';
const userSettingTable = 'user_setting';
const systemSettingTableLegacy = 'Settings';

// columns
const idColumn = 'id';

// server table columns
const urlColumn = 'url';
const pnfpbKeyColumn = 'pnfpb_key';

// system_setting columns
const serverIdColumn = 'server_id';
const logInTokenColumn = 'log_in_token';
const logInUserNameColumn = 'log_in_user_name';
const logInPasswordColumn = 'log_in_password';
const rememberLogInColumn = 'remember_log_in';
const firebaseEventLoggingColumn = 'firebase_event_logging';
const developmentModeColumn = 'development_mode';
const showDemoUsersColumn = 'show_demo_users';
const showTeamMembersColumn = 'show_team_members';
const showContributorsColumn = 'show_contributors';
const bypassStoreColumn = 'bypass_store';
const firebasePushNotificationTokenColumn = 'firebase_push_notification_token';
const passwordResetRequestTimestampColumn = 'password_reset_request_timestamp';
const hasRegistedColumn = 'has_registered';
const messageCountLimitPerThreadColumn = 'message_count_limit_per_thread';
const maxPendingMessageRepliesColumn = 'max_pending_message_replies';
const adDisplayIntervalColumn = 'ad_display_interval';

// user_setting columns
const userIdColumn = 'user_id';
const memberSearchConnectionTypesColumn = 'member_search_connection_types';
const memberSearchSexualOrientationsColumn =
    'member_search_sexual_orientations';
const memberSearchGendersColumn = 'member_search_genders';
const memberSearchLocationsColumn = 'member_search_locations';
const memberSearchPassionsColumn = 'member_search_passions';
const memberSearchEthnicitiesColumn = 'member_search_ethnicities';
const memberSearchAgeFromColumn = 'member_search_age_from';
const memberSearchAgeToColumn = 'member_search_age_to';
const memberSearchPhotoTypeColumn = 'member_search_photo_type';
const memberSearchKeyColumn = 'member_search_key';
const memberSearchOrderTypeColumn = 'member_search_order_type';
const lastNewMessageSentTimestampColumn = 'last_new_message_sent_timestamp';
const newMessagesSentCountColumn = 'new_messages_sent_count';
const lastFavouriteAddedTimestampColumn = 'last_favourite_added_timestamp';
const newFavouritesAddedCountColumn = 'new_favourites_added_count';
const featureAdFreeColumn = 'feature_ad_free';
const featureThemeControlColumn = 'feature_theme_control';
const featureSelectedThemeColumn = 'feature_selected_theme';
const featurePhotoTypeSearchColumn = 'feature_photo_type_search';
const featureMatchInsightColumn = 'feature_match_insight';
const featureMemberOnlineIndicatorColumn = 'feature_member_online_indicator';
const featureCustomOpenersColumn = 'feature_custom_openers';
const featureFavouritedMeColumn = 'feature_favourited_me';
const showTipFiltersAppliedColumn = 'show_tip_filters_applied';
const showTipSwipeColumn = 'show_tip_swipe';
const showTipMessageGuidelinesColumn = 'show_tip_message_guidelines';

// Create table SQL statements.
const createServerTable = '''CREATE TABLE IF NOT EXISTS "server" (
  "id"	INTEGER NOT NULL,
  "url"	TEXT NOT NULL UNIQUE,
  "pnfpb_key"	TEXT,
  PRIMARY KEY("id" AUTOINCREMENT)
);''';

const createSystemSettingTable =
    '''CREATE TABLE IF NOT EXISTS "system_setting" (
  "id"	INTEGER NOT NULL,
  "server_id" 	INTEGER NOT NULL,
  "log_in_token"	TEXT,
  "log_in_user_name" TEXT,
  "log_in_password" TEXT,
  "remember_log_in"	INTEGER DEFAULT 0,
  "firebase_event_logging"	INTEGER DEFAULT 1,
  "development_mode"	INTEGER DEFAULT 0,
  "show_demo_users"	INTEGER DEFAULT 0,
  "show_team_members"	INTEGER DEFAULT 0,
  "show_contributors"	INTEGER DEFAULT 0,
  "bypass_store"	INTEGER DEFAULT 0,
  "firebase_push_notification_token" TEXT,
  "password_reset_request_timestamp" INTEGER DEFAULT 0,
  "has_registered" INTEGER DEFAULT 0,
  "message_count_limit_per_thread" INTEGER DEFAULT 500,
  "max_pending_message_replies" INTEGER DEFAULT 10,
  "ad_display_interval"	INTEGER DEFAULT 1,
  FOREIGN KEY("server_id") REFERENCES "server"("id"),
  PRIMARY KEY("id" AUTOINCREMENT)
);''';

const createUserSettingTable = '''CREATE TABLE IF NOT EXISTS "user_setting" (
  "id"	INTEGER NOT NULL,
  "user_id"	INTEGER NOT NULL,
  "member_search_connection_types"	TEXT,
  "member_search_sexual_orientations" TEXT,
  "member_search_genders" TEXT,
  "member_search_locations" TEXT,
  "member_search_passions" TEXT,
  "member_search_ethnicities" TEXT,
  "member_search_age_from"	INTEGER DEFAULT 0,
  "member_search_age_to"	INTEGER DEFAULT 81,
  "member_search_photo_type"	INTEGER DEFAULT 0,
  "member_search_key" TEXT,
  "member_search_order_type"	INTEGER DEFAULT 0,
  "last_new_message_sent_timestamp" INTEGER DEFAULT 0,
  "new_messages_sent_count" INTEGER DEFAULT 0,
  "last_favourite_added_timestamp" INTEGER DEFAULT 0, 
  "new_favourites_added_count" INTEGER DEFAULT 0,
  "feature_ad_free"	INTEGER DEFAULT 0,
  "feature_theme_control"	INTEGER DEFAULT 0,
  "feature_selected_theme"	INTEGER DEFAULT 1,
  "feature_photo_type_search"	INTEGER DEFAULT 0,
  "feature_match_insight"	INTEGER DEFAULT 0,
  "feature_member_online_indicator"	INTEGER DEFAULT 0,
  "feature_custom_openers"	INTEGER DEFAULT 0,
  "feature_favourited_me"	INTEGER DEFAULT 0,
  "show_tip_filters_applied"	INTEGER DEFAULT 1,
  "show_tip_swipe"	INTEGER DEFAULT 1,
  "show_tip_message_guidelines"	INTEGER DEFAULT 1,
  PRIMARY KEY("id" AUTOINCREMENT)
);''';

const insertDefaultServers = '''INSERT INTO server(url, pnfpb_key) VALUES 
('https://www.arvo.dating', 'ed3c35b8f7cd2201b57c12c0c930fe2d')
;''';

// Drop table SQL statements.
const dropServerTable = '''DROP TABLE IF EXISTS "server";''';

const dropSystemSettingTable = '''DROP TABLE IF EXISTS "system_setting";''';

const dropUserSettingTable = '''DROP TABLE IF EXISTS "user_setting";''';
