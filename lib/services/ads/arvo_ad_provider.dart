import 'dart:io';

import 'package:flutter/material.dart';
import 'package:arvo/constants/localised_assets.dart';
import 'package:arvo/services/ads/ad.dart';
import 'package:arvo/services/ads/ad_provider.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/features/feature_provider.dart';
import 'package:arvo/views/shared/ad_overlay.dart';

class ArvoAdProvider implements AdProvider {
  // create as singleton
  static final _shared = ArvoAdProvider._sharedInstance();
  ArvoAdProvider._sharedInstance();
  factory ArvoAdProvider() => _shared;

  late FeatureProvider _featureProvider;
  late LocalStorageProvider _localStorageProvider;
  // Needs to be assigned outside initialise() because a user has to be logged in.
  late DatabaseSystemSetting _databaseSystemSetting;
  int _adDisplayInterval = 1;
  final List<Ad> _ads = [
    Ad(
        headline: 'Connect quicker.',
        promoText:
            "See who's added you as a favourite, only available with Premium.",
        assetImage: Platform.isIOS
            ? adImageIOSFavouritedMe
            : adImageAndroidFavouritedMe),
    Ad(
        headline: 'Match perfect.',
        promoText:
            'See how well you match with others with highlighted colour-coded matching fields, available with Premium.',
        assetImage: Platform.isIOS
            ? adImageIOSColourCodedMatchingFields
            : adImageAndroidColourCodedMatchingFields),
    Ad(
        headline: 'Match in colour.',
        promoText: 'Upgrade to Premium for colour-coded match meters.',
        assetImage: Platform.isIOS
            ? adImageIOSColourCodedMatchMeters
            : adImageAndroidColourCodedMatchMeters),
    Ad(
        headline: 'Catch their eye.',
        promoText:
            'Stand out with custom message openers, only available with Premium.',
        assetImage: Platform.isIOS
            ? adImageIOSCustomOpeners
            : adImageAndroidCustomOpeners),
    Ad(
        headline: 'Sieze the moment.',
        promoText:
            "See who's active with the online status indicator, available with Premium.",
        assetImage: Platform.isIOS
            ? adImageIOSActivityIndicator
            : adImageAndroidActivityIndicator),
    Ad(
        headline: 'Relax your eyes.',
        promoText: 'Browse with dark mode, only available with Premium.',
        assetImage:
            Platform.isIOS ? adImageIOSDarkMode : adImageAndroidDarkMode),
    Ad(
        headline: 'A picture is worth a thousand taps.',
        promoText: 'Filter profiles with photos, only available with Premium.',
        assetImage:
            Platform.isIOS ? adImageIOSPhotoFilter : adImageAndroidPhotoFilter),
  ];
  int _adIndex = 0;

  @override
  DateTime? previousAdDisplayedDateTime = DateTime.now();

  @override
  Future<void> initalise(FeatureProvider featureProvider,
      LocalStorageProvider localStorageProvider) async {
    _featureProvider = featureProvider;
    _localStorageProvider = localStorageProvider;
  }

  @override
  Future<void> loadSystemParameters() async {
    _databaseSystemSetting = await _localStorageProvider.getSystemSetting();
    _adDisplayInterval = _databaseSystemSetting.adDisplayInterval;
    previousAdDisplayedDateTime = DateTime.now();
  }

  @override
  void showAd(BuildContext context) {
    // Return if ad-free.
    if (_featureProvider.featureAdFree ?? false) return;

    // Return if interval not exceeded.
    if (DateTime.now().difference(previousAdDisplayedDateTime!).inMinutes <
        _adDisplayInterval) {
      return;
    }

    // Show ad.
    AdOverlay().show(
      context: context,
      ad: _ads[_adIndex],
      hideCallback: () {
        previousAdDisplayedDateTime = DateTime.now();
      },
    );

    // Set the index for the next ad.
    _adIndex = (_adIndex == _ads.length - 1) ? 0 : _adIndex + 1;
  }
}
