import 'package:flutter/material.dart';
import 'package:arvo/services/ads/ad_provider.dart';
import 'package:arvo/services/ads/arvo_ad_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/features/feature_provider.dart';

class AdService implements AdProvider {
  final AdProvider provider;
  AdService(this.provider);

  factory AdService.arvo() => AdService(ArvoAdProvider());

  @override
  DateTime get previousAdDisplayedDateTime =>
      provider.previousAdDisplayedDateTime ?? DateTime.now();

  @override
  set previousAdDisplayedDateTime(DateTime? value) =>
      provider.previousAdDisplayedDateTime = value;

  @override
  Future<void> initalise(FeatureProvider featureProvider,
          LocalStorageProvider localStorageProvider) =>
      provider.initalise(featureProvider, localStorageProvider);

  @override
  Future<void> loadSystemParameters() => provider.loadSystemParameters();

  @override
  void showAd(BuildContext context) => provider.showAd(context);
}
