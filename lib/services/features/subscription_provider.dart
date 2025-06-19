import 'dart:async';

import 'package:flutter/material.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/features/feature_provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class SubscriptionProvider {
  InAppPurchase? inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? subscription;
  List<String>? notFoundIds;
  List<ProductDetails>? products;
  List<PurchaseDetails>? purchases;
  List<String>? consumables;
  List<ProductFeatures>? productFeatures;
  bool? isAvailable;
  bool? purchasePending;
  bool? loading;
  String? queryProductError;
  bool? hasSilver;
  bool? hasGold;
  void initalise(
    ConnectionProvider connectionProvider,
    LocalStorageProvider localStorageProvider,
    FeatureProvider featureProvider,
  );
  Future<void> initStoreInfo();
  Future<void> restorePurchases();
  void registerFunctionForUpdate(String uuid, Function updateFunction);
  void unregisterFunction(String uuid);
  void Function()? get onError;
  set onError(void Function()? value);
  void Function()? get onDeliverProduct;
  set onDeliverProduct(void Function()? value);
  void Function()? get onPurchaseUpdated;
  set onPurchaseUpdated(void Function()? value);
  void Function()? get onInvalidPurchase;
  set onInvalidPurchase(void Function()? value);
}

class ProductFeatures {
  final String productId;
  final String displayName;
  final String? description;
  final List<ProductFeature>? features;
  final IconData? iconData;
  final String? image;

  ProductFeatures({
    required this.productId,
    required this.displayName,
    this.description,
    required this.features,
    this.iconData,
    this.image,
  });
}

class ProductFeature {
  final String name;
  final IconData? iconData;
  String? image;

  ProductFeature({
    required this.name,
    this.iconData,
    this.image,
  });
}
