import 'dart:async';

import 'package:arvo/services/connection/connection_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/features/feature_provider.dart';
import 'package:arvo/services/features/arvo_subscription_provider.dart';
import 'package:arvo/services/features/subscription_provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService implements SubscriptionProvider {
  final SubscriptionProvider provider;
  SubscriptionService(this.provider);

  factory SubscriptionService.arvo() =>
      SubscriptionService(ArvoSubscriptionProvider());

  @override
  InAppPurchase? get inAppPurchase => provider.inAppPurchase;

  @override
  set inAppPurchase(InAppPurchase? value) => provider.inAppPurchase = value;

  @override
  bool get isAvailable => provider.isAvailable ?? false;

  @override
  set isAvailable(bool? value) => provider.isAvailable = value;

  @override
  bool get loading => provider.loading ?? false;

  @override
  set loading(bool? value) => provider.loading = value;

  @override
  List<String> get notFoundIds => provider.notFoundIds ?? [];

  @override
  set notFoundIds(List<String>? value) => provider.notFoundIds = value;

  @override
  List<ProductDetails> get products => provider.products ?? [];

  @override
  set products(List<ProductDetails>? value) => provider.products = value;

  @override
  bool get purchasePending => provider.purchasePending ?? false;

  @override
  set purchasePending(bool? value) => provider.purchasePending = value;

  @override
  List<PurchaseDetails> get purchases => provider.purchases ?? [];

  @override
  set purchases(List<PurchaseDetails>? value) => provider.purchases = value;

  @override
  List<String> get consumables => provider.consumables ?? [];

  @override
  set consumables(List<String>? value) => provider.consumables = value;

  @override
  List<ProductFeatures>? get productFeatures => provider.productFeatures ?? [];

  @override
  set productFeatures(List<ProductFeatures>? value) =>
      provider.productFeatures = value;

  @override
  String? queryProductError;

  @override
  StreamSubscription<List<PurchaseDetails>>? subscription;

  @override
  bool get hasSilver => provider.hasSilver ?? false;

  @override
  set hasSilver(bool? value) => provider.hasSilver = value;

  @override
  bool get hasGold => provider.hasGold ?? false;

  @override
  set hasGold(bool? value) => provider.hasGold = value;

  @override
  void initalise(
    ConnectionProvider connectionProvider,
    LocalStorageProvider localStorageProvider,
    FeatureProvider featureProvider,
  ) =>
      provider.initalise(
        connectionProvider,
        localStorageProvider,
        featureProvider,
      );

  @override
  Future<void> initStoreInfo() => provider.initStoreInfo();

  @override
  Future<void> restorePurchases() => provider.restorePurchases();

  @override
  void registerFunctionForUpdate(String uuid, Function updateFunction) =>
      provider.registerFunctionForUpdate(uuid, updateFunction);

  @override
  void unregisterFunction(String uuid) => provider.unregisterFunction(uuid);

  @override
  void Function()? get onError => provider.onError;

  @override
  set onError(void Function()? value) => provider.onError = value;

  @override
  void Function()? get onDeliverProduct => provider.onDeliverProduct;

  @override
  set onDeliverProduct(void Function()? value) =>
      provider.onDeliverProduct = value;

  @override
  void Function()? get onPurchaseUpdated => provider.onPurchaseUpdated;

  @override
  set onPurchaseUpdated(void Function()? value) =>
      provider.onPurchaseUpdated = value;

  @override
  void Function()? get onInvalidPurchase => provider.onInvalidPurchase;

  @override
  set onInvalidPurchase(void Function()? value) =>
      provider.onInvalidPurchase = value;
}
