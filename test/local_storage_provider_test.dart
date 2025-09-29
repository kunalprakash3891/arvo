import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arvo/services/crud/crud_exceptions.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// NOTE: Test database is located at C:\dev\projects\flutter\arvo\.dart_tool\sqflite_common_ffi\databases
void main() {
  // test server data
  const testServer1URL = 'https://www.testserver1.dating';
  const testServer2URL = 'https://www.testserver1.dating';
  const testPnfpbKey1 = 'abcdefghijklmnopqrstuvwxyz';
  const testPnfpbKey2 = 'thequickbrownfoxjumpsoverthelazydog';
  const invalidServerId = 99;

  // test system_setting data
  const testUserName1 = 'SuperNintendoChalmers';
  const testUserPassword1 = 'Steamed_Hams';
  const testLogInToken1 = 'supercalifragilisticexpialidocious';
  const testFirebaseToken1 = 'abcdefghijklmnopqrstuvwxyz';

  // test user_setting data
  Random random = Random();
  int userId = random.nextInt(999);
  const invalidUserSettingId = 999;
  const testUserSettingJsonData1_1 = "{ 'abc' : 123 }";
  const testUserSettingJsonData1_2 = "{ 'def' : 456 }";
  const testUserSettingJsonData1_3 = "{ 'ghi' : 789 }";
  const testUserSettingJsonData1_4 = "{ 'jkl' : 012 }";
  const testUserSettingJsonData1_5 = "{ 'mno' : 345 }";
  const testUserSettingJsonData1_6 = "{ 'pqr' : 678 }";
  const testUserSettingJsonData2_1 = "{ 'cba' : 'abc' }";
  const testUserSettingJsonData2_2 = "{ 'fed' : 'def' }";
  const testUserSettingJsonData2_3 = "{ 'ihg' : 'ghi' }";
  const testUserSettingJsonData2_4 = "{ 'lkj' : 'jkl' }";
  const testUserSettingJsonData2_5 = "{ 'onm' : 'mno' }";
  const testUserSettingJsonData2_6 = "{ 'rpq' : 'pqr' }";
  const testSearchKey1 = 'patented Skinner burgers';
  const testSearchKey2 = 'despite the fact that they are obviously grilled';

  TestWidgetsFlutterBinding.ensureInitialized();
  final provider = LocalStorageService.arvo();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
    return '.';
  });

  // initialise SQLite for unit testing
  sqfliteFfiInit();
  // change the default factory
  databaseFactory = databaseFactoryFfi;

  group('[Database]', () {
    test('Should be able to open and close database', () async {
      await provider.open();
      await provider.close();
    });
  });

  group('[Server]', () {
    test('Create a new server record, update it, then delete it', () async {
      // create
      final newDatabaseServer =
          await provider.createServer(testServer1URL, testPnfpbKey1);
      expect(newDatabaseServer, isNotNull);
      // retrieve and check properties
      var existingDatabaseServer =
          await provider.getServer(newDatabaseServer.id);
      expect(existingDatabaseServer, isNotNull);
      expect(existingDatabaseServer.id, newDatabaseServer.id);
      expect(existingDatabaseServer.url, testServer1URL);
      expect(existingDatabaseServer.pnfpbKey, testPnfpbKey1);
      var allServers = await provider.getAllServers();
      expect(
          allServers
              .where((server) => server.id == newDatabaseServer.id)
              .length,
          1);

      // attemping to create another server with the same properties should fail
      try {
        await provider.createServer(testServer1URL, testPnfpbKey1);
      } on Exception catch (e) {
        expect(e, isA<ServerAlreadyExistsException>());
      }

      // update and check properties
      existingDatabaseServer.url = testServer2URL;
      existingDatabaseServer.pnfpbKey = testPnfpbKey2;

      await provider.updateServer(existingDatabaseServer);

      existingDatabaseServer =
          await provider.getServer(existingDatabaseServer.id);

      expect(existingDatabaseServer, isNotNull);
      expect(existingDatabaseServer.id, newDatabaseServer.id);
      expect(existingDatabaseServer.url, testServer2URL);
      expect(existingDatabaseServer.pnfpbKey, testPnfpbKey2);

      // delete and confirm deleted
      await provider.deleteServer(existingDatabaseServer.id);

      allServers = await provider.getAllServers();
      expect(
          allServers
              .where((server) => server.id == newDatabaseServer.id)
              .length,
          0);
    });

    test('Attempting to retrieve an invalid server should fail', () async {
      try {
        await provider.getServer(invalidServerId);
      } on Exception catch (e) {
        expect(e, isA<CouldNotFindServerException>());
      }
    });
  });

  group('[System Setting]', () {
    test(
        'Retrieve system setting record, update it, delete it and check that it is recreated automatically',
        () async {
      // retrieve and check properties (opening the database should automatically create a system setting if none exists)
      var existingDatabaseSystemSetting = await provider.getSystemSetting();

      final servers = await provider.getAllServers();

      expect(existingDatabaseSystemSetting, isNotNull);
      expect(existingDatabaseSystemSetting.serverId, servers.first.id);
      expect(existingDatabaseSystemSetting.logInToken, isEmpty);
      expect(existingDatabaseSystemSetting.logInUserName, isEmpty);
      expect(existingDatabaseSystemSetting.logInPassword, isEmpty);
      expect(existingDatabaseSystemSetting.rememberLogIn, true);
      expect(existingDatabaseSystemSetting.firebaseEventLogging, true);
      expect(existingDatabaseSystemSetting.developmentMode, false);
      expect(existingDatabaseSystemSetting.showDemoUsers, false);
      expect(existingDatabaseSystemSetting.showTeamMembers, false);
      expect(
          existingDatabaseSystemSetting.firebasePushNotificationToken, isEmpty);

      // update and check properties
      existingDatabaseSystemSetting.serverId = servers.last.id;
      existingDatabaseSystemSetting.logInToken = testLogInToken1;
      existingDatabaseSystemSetting.logInUserName = testUserName1;
      existingDatabaseSystemSetting.logInPassword = testUserPassword1;
      existingDatabaseSystemSetting.rememberLogIn = false;
      existingDatabaseSystemSetting.firebaseEventLogging = false;
      existingDatabaseSystemSetting.developmentMode = true;
      existingDatabaseSystemSetting.showDemoUsers = true;
      existingDatabaseSystemSetting.showTeamMembers = true;
      existingDatabaseSystemSetting.firebasePushNotificationToken =
          testFirebaseToken1;

      existingDatabaseSystemSetting =
          await provider.updateSystemSetting(existingDatabaseSystemSetting);
      final updatedDatabaseSystemSetting = await provider.getSystemSetting();
      expect(updatedDatabaseSystemSetting, isNotNull);
      expect(updatedDatabaseSystemSetting.id, existingDatabaseSystemSetting.id);
      expect(updatedDatabaseSystemSetting.serverId, servers.last.id);
      expect(updatedDatabaseSystemSetting.logInToken, testLogInToken1);
      expect(updatedDatabaseSystemSetting.logInUserName, testUserName1);
      expect(updatedDatabaseSystemSetting.logInPassword, testUserPassword1);
      expect(updatedDatabaseSystemSetting.rememberLogIn, false);
      expect(updatedDatabaseSystemSetting.firebaseEventLogging, false);
      expect(updatedDatabaseSystemSetting.developmentMode, true);
      expect(updatedDatabaseSystemSetting.showDemoUsers, true);
      expect(updatedDatabaseSystemSetting.showTeamMembers, true);
      expect(updatedDatabaseSystemSetting.firebasePushNotificationToken,
          testFirebaseToken1);

      // delete and check deleted
      await provider.deleteSystemSetting(updatedDatabaseSystemSetting.id);
      try {
        await provider.getSystemSetting();
      } on Exception catch (e) {
        expect(e, isA<CouldNotFindSystemSettingException>());
      }

      //closing and re-opening database should recreate the default system setting
      await provider.close();

      final recreatedDatabaseSystemSetting = await provider.getSystemSetting();
      expect(recreatedDatabaseSystemSetting, isNotNull);
      expect(recreatedDatabaseSystemSetting.serverId, servers.first.id);
      expect(recreatedDatabaseSystemSetting.logInToken, isEmpty);
      expect(recreatedDatabaseSystemSetting.logInUserName, isEmpty);
      expect(recreatedDatabaseSystemSetting.logInPassword, isEmpty);
      expect(recreatedDatabaseSystemSetting.rememberLogIn, true);
      expect(recreatedDatabaseSystemSetting.firebaseEventLogging, true);
      expect(recreatedDatabaseSystemSetting.developmentMode, false);
      expect(recreatedDatabaseSystemSetting.showDemoUsers, false);
      expect(recreatedDatabaseSystemSetting.showTeamMembers, false);
      expect(recreatedDatabaseSystemSetting.firebasePushNotificationToken,
          isEmpty);
    });
  });

  group('[User Setting]', () {
    test('Create a new user setting record, update it, then delete it',
        () async {
      // create
      var newDatabaseUserSetting = DatabaseUserSetting(
        id: 0,
        userId: userId,
        memberSearchConnectionTypes: testUserSettingJsonData1_1,
        memberSearchSexualOrientations: testUserSettingJsonData1_2,
        memberSearchGenders: testUserSettingJsonData1_3,
        memberSearchLocations: testUserSettingJsonData1_4,
        memberSearchPassions: testUserSettingJsonData1_5,
        memberSearchEthnicities: testUserSettingJsonData1_6,
        memberSearchAgeFrom: 18,
        memberSearchAgeTo: 99,
        memberSearchPhotoType: 1,
        memberSearchKey: testSearchKey1,
        memberSearchOrderType: 0,
        featureAdFree: false,
        featureThemeControl: true,
        featureSelectedTheme: 1,
        featurePhotoTypeSearch: false,
        featureMatchInsight: true,
        featureMemberOnlineIndicator: false,
        featureCustomOpeners: true,
        featureFavouritedMe: false,
        showTipFiltersApplied: true,
        showTipSwipe: true,
        showTipMessageGuidelines: true,
      );

      newDatabaseUserSetting =
          await provider.createUserSetting(newDatabaseUserSetting);
      // retrieve and check properties
      var existingUserSetting =
          await provider.getUserSetting(newDatabaseUserSetting.userId);
      expect(existingUserSetting.userId, userId);
      expect(existingUserSetting.memberSearchConnectionTypes,
          testUserSettingJsonData1_1);
      expect(existingUserSetting.memberSearchSexualOrientations,
          testUserSettingJsonData1_2);
      expect(
          existingUserSetting.memberSearchGenders, testUserSettingJsonData1_3);
      expect(existingUserSetting.memberSearchLocations,
          testUserSettingJsonData1_4);
      expect(
          existingUserSetting.memberSearchPassions, testUserSettingJsonData1_5);
      expect(existingUserSetting.memberSearchEthnicities,
          testUserSettingJsonData1_6);
      expect(existingUserSetting.memberSearchAgeFrom, 18);
      expect(existingUserSetting.memberSearchAgeTo, 99);
      expect(existingUserSetting.memberSearchPhotoType, 1);
      expect(existingUserSetting.memberSearchKey, testSearchKey1);
      expect(existingUserSetting.memberSearchOrderType, 0);
      expect(existingUserSetting.featureAdFree, false);
      expect(existingUserSetting.featureThemeControl, true);
      expect(existingUserSetting.featureSelectedTheme, 1);
      expect(existingUserSetting.featurePhotoTypeSearch, false);
      expect(existingUserSetting.featureMatchInsight, true);
      expect(existingUserSetting.featureMemberOnlineIndicator, false);
      expect(existingUserSetting.featureCustomOpeners, true);
      expect(existingUserSetting.featureFavouritedMe, false);
      expect(existingUserSetting.showTipFiltersApplied, true);
      expect(existingUserSetting.showTipSwipe, true);
      expect(existingUserSetting.showTipMessageGuidelines, true);

      // update and check properties
      existingUserSetting.memberSearchConnectionTypes =
          testUserSettingJsonData2_1;
      existingUserSetting.memberSearchSexualOrientations =
          testUserSettingJsonData2_2;
      existingUserSetting.memberSearchGenders = testUserSettingJsonData2_3;
      existingUserSetting.memberSearchLocations = testUserSettingJsonData2_4;
      existingUserSetting.memberSearchPassions = testUserSettingJsonData2_5;
      existingUserSetting.memberSearchEthnicities = testUserSettingJsonData2_6;
      existingUserSetting.memberSearchAgeFrom = 6;
      existingUserSetting.memberSearchAgeTo = 21;
      existingUserSetting.memberSearchPhotoType = 2;
      existingUserSetting.memberSearchKey = testSearchKey2;
      existingUserSetting.memberSearchOrderType = 4;
      existingUserSetting.featureAdFree = true;
      existingUserSetting.featureThemeControl = false;
      existingUserSetting.featureSelectedTheme = 0;
      existingUserSetting.featurePhotoTypeSearch = true;
      existingUserSetting.featureMatchInsight = false;
      existingUserSetting.featureMemberOnlineIndicator = true;
      existingUserSetting.featureCustomOpeners = false;
      existingUserSetting.featureFavouritedMe = true;
      existingUserSetting.showTipFiltersApplied = false;
      existingUserSetting.showTipSwipe = false;
      existingUserSetting.showTipMessageGuidelines = false;

      await provider.updateUserSetting(existingUserSetting);

      existingUserSetting =
          await provider.getUserSetting(existingUserSetting.userId);
      expect(existingUserSetting.userId, userId);
      expect(existingUserSetting.memberSearchConnectionTypes,
          testUserSettingJsonData2_1);
      expect(existingUserSetting.memberSearchSexualOrientations,
          testUserSettingJsonData2_2);
      expect(
          existingUserSetting.memberSearchGenders, testUserSettingJsonData2_3);
      expect(existingUserSetting.memberSearchLocations,
          testUserSettingJsonData2_4);
      expect(
          existingUserSetting.memberSearchPassions, testUserSettingJsonData2_5);
      expect(existingUserSetting.memberSearchEthnicities,
          testUserSettingJsonData2_6);
      expect(existingUserSetting.memberSearchAgeFrom, 6);
      expect(existingUserSetting.memberSearchAgeTo, 21);
      expect(existingUserSetting.memberSearchPhotoType, 2);
      expect(existingUserSetting.memberSearchKey, testSearchKey2);
      expect(existingUserSetting.memberSearchOrderType, 4);
      expect(existingUserSetting.featureAdFree, true);
      expect(existingUserSetting.featureThemeControl, false);
      expect(existingUserSetting.featureSelectedTheme, 0);
      expect(existingUserSetting.featurePhotoTypeSearch, true);
      expect(existingUserSetting.featureMatchInsight, false);
      expect(existingUserSetting.featureMemberOnlineIndicator, true);
      expect(existingUserSetting.featureCustomOpeners, false);
      expect(existingUserSetting.featureFavouritedMe, true);
      expect(existingUserSetting.showTipFiltersApplied, false);
      expect(existingUserSetting.showTipSwipe, false);
      expect(existingUserSetting.showTipMessageGuidelines, false);

      // delete and confirm deleted
      await provider.deleteUserSetting(existingUserSetting.userId);

      try {
        await provider.getUserSetting(existingUserSetting.userId);
      } on Exception catch (e) {
        expect(e, isA<CouldNotFindUserSettingException>());
      }
    });

    test('Attempting to retrieve an invalid user setting should fail',
        () async {
      try {
        await provider.getUserSetting(invalidUserSettingId);
      } on Exception catch (e) {
        expect(e, isA<CouldNotFindUserSettingException>());
      }
    });
  });
}
