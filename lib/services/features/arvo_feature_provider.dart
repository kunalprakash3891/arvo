import 'package:app_base/theming/theme.dart';
import 'package:flutter/material.dart';
import 'package:arvo/theme/theme_cubit.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/features/feature_provider.dart';

class ArvoFeatureProvider implements FeatureProvider {
  // create as singleton
  static final _shared = ArvoFeatureProvider._sharedInstance();
  ArvoFeatureProvider._sharedInstance();
  factory ArvoFeatureProvider() => _shared;

  late ConnectionProvider _connectionProvider;
  late LocalStorageProvider _localStorageProvider;
  ThemeCubit? _themeCubit;
  // Needs to be assigned outside initialise() because a user has to be logged in.
  late Member? _currentUser;
  late DatabaseUserSetting _databaseUserSetting;
  final Map<String, Function> _updateFunctionsMap = {};

  Member _getCurrentUserOrThrow() {
    if (_currentUser != null) {
      return _currentUser!;
    } else {
      throw GenericUserAccessException(message: 'Invalid user.');
    }
  }

  @override
  bool? featureAdFree = false;

  @override
  bool? featureMatchInsight = false;

  @override
  bool? featurePhotoTypeSearch = false;

  // NOTE: Default theme is 0 since the app will use the system theme on first launch.
  @override
  int? featureSelectedTheme = 0; // 1 = System.

  @override
  bool? featureThemeControl = false;

  @override
  bool? featureMemberOnlineIndicator = false;

  @override
  bool? featureCustomOpeners = false;

  @override
  bool? featureFavouritedMe = false;

  @override
  Future<void> initalise(
    ConnectionProvider connectionProvider,
    LocalStorageProvider localStorageProvider,
    ThemeCubit themeCubit,
  ) async {
    _connectionProvider = connectionProvider;
    _localStorageProvider = localStorageProvider;
    _themeCubit = themeCubit;
  }

  @override
  Future<void> loadSystemParameters() async {
    _currentUser = _connectionProvider.currentUser;

    _getCurrentUserOrThrow();
    _databaseUserSetting =
        await _localStorageProvider.getUserSetting(_currentUser!.id);
    featureAdFree = _databaseUserSetting.featureAdFree;
    featureMatchInsight = _databaseUserSetting.featureMatchInsight;
    featurePhotoTypeSearch = _databaseUserSetting.featurePhotoTypeSearch;
    featureThemeControl = _databaseUserSetting.featureThemeControl;
    bool setTheme =
        featureSelectedTheme != _databaseUserSetting.featureSelectedTheme;
    featureSelectedTheme = _databaseUserSetting.featureThemeControl
        ? _databaseUserSetting.featureSelectedTheme
        : 1;
    featureMemberOnlineIndicator =
        _databaseUserSetting.featureMemberOnlineIndicator;
    featureCustomOpeners = _databaseUserSetting.featureCustomOpeners;
    featureFavouritedMe = _databaseUserSetting.featureFavouritedMe;
    // Execute callbacks for views that have registered to listen to updates.
    for (final updateFunction in _updateFunctionsMap.values) {
      updateFunction();
    }

    // Set the theme.
    if (setTheme) {
      _setTheme(_themeCubit, _databaseUserSetting);
    }
  }

  @override
  void registerFunctionForUpdate(String uuid, Function updateFunction) {
    _updateFunctionsMap[uuid] = updateFunction;
  }

  @override
  void unregisterFunction(String uuid) {
    _updateFunctionsMap.remove(uuid);
  }

  void _setTheme(
      ThemeCubit? themeCubit, DatabaseUserSetting databaseUserSetting) {
    themeCubit?.updateTheme(themeModeMap.keys.firstWhere(
        (theme) =>
            themeModeMap[theme] == databaseUserSetting.featureSelectedTheme,
        orElse: () => ThemeMode.light));
  }
}
