import 'package:flutter/foundation.dart';

@immutable
class Ad {
  final String headline;
  final String? promoText;
  final String? assetImage;

  const Ad({
    required this.headline,
    this.promoText,
    this.assetImage,
  });
}
