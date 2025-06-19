import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/theme/theme_cubit.dart';

abstract class FeatureProvider {
  bool? featureAdFree; // Use featureAdFree for subscription ads.
  bool? featureThemeControl;
  int? featureSelectedTheme;
  bool? featurePhotoTypeSearch;
  bool? featureMatchInsight;
  bool? featureMemberOnlineIndicator;
  bool? featureCustomOpeners;
  bool? featureFavouritedMe;
  Future<void> initalise(ConnectionProvider connectionProvider,
      LocalStorageProvider localStorageProvider, ThemeCubit themeCubit);
  Future<void> loadSystemParameters();
  void registerFunctionForUpdate(String uuid, Function updateFunction);
  void unregisterFunction(String uuid);
}
