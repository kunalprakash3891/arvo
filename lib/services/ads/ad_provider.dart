import 'package:flutter/material.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/features/feature_provider.dart';

abstract class AdProvider {
  DateTime? previousAdDisplayedDateTime;
  Future<void> initalise(FeatureProvider featureProvider,
      LocalStorageProvider localStorageProvider);
  Future<void> loadSystemParameters();
  void showAd(BuildContext context);
}
