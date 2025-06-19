import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/features/feature_provider.dart';
import 'package:arvo/services/features/arvo_feature_provider.dart';
import 'package:arvo/theme/theme_cubit.dart';

class FeatureService implements FeatureProvider {
  final FeatureProvider provider;
  FeatureService(this.provider);

  factory FeatureService.arvo() => FeatureService(ArvoFeatureProvider());

  @override
  bool get featureAdFree => provider.featureAdFree ?? false;

  @override
  set featureAdFree(bool? value) => provider.featureAdFree = value;

  @override
  bool get featureMatchInsight => provider.featureMatchInsight ?? false;

  @override
  set featureMatchInsight(bool? value) => provider.featureMatchInsight = value;

  @override
  bool get featurePhotoTypeSearch => provider.featurePhotoTypeSearch ?? false;

  @override
  set featurePhotoTypeSearch(bool? value) =>
      provider.featurePhotoTypeSearch = value;

  // NOTE: Default theme is 0 since the app will use the system theme on first launch.
  @override
  int get featureSelectedTheme =>
      provider.featureSelectedTheme ?? 0; // 0 = System.

  @override
  set featureSelectedTheme(int? value) => provider.featureSelectedTheme = value;

  @override
  bool get featureThemeControl => provider.featureThemeControl ?? false;

  @override
  set featureThemeControl(bool? value) => provider.featureThemeControl = value;

  @override
  bool get featureMemberOnlineIndicator =>
      provider.featureMemberOnlineIndicator ?? false;

  @override
  set featureMemberOnlineIndicator(bool? value) =>
      provider.featureMemberOnlineIndicator = value;

  @override
  bool get featureCustomOpeners => provider.featureCustomOpeners ?? false;

  @override
  set featureCustomOpeners(bool? value) =>
      provider.featureCustomOpeners = value;

  @override
  bool get featureFavouritedMe => provider.featureFavouritedMe ?? false;

  @override
  set featureFavouritedMe(bool? value) => provider.featureFavouritedMe = value;

  @override
  Future<void> initalise(ConnectionProvider connectionProvider,
          LocalStorageProvider localStorageProvider, ThemeCubit themeCubit) =>
      provider.initalise(connectionProvider, localStorageProvider, themeCubit);

  @override
  Future<void> loadSystemParameters() => provider.loadSystemParameters();

  @override
  void registerFunctionForUpdate(String uuid, Function updateFunction) =>
      provider.registerFunctionForUpdate(uuid, updateFunction);

  @override
  void unregisterFunction(String uuid) => provider.unregisterFunction(uuid);
}
