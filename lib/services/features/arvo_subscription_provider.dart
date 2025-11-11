import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/services/connection/member_filters.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/crud/arvo_local_storage_provider.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/features/feature_provider.dart';
import 'package:arvo/services/features/subscription_products.dart';
import 'package:arvo/services/features/subscription_provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// NOTE: Conusmable code has been left in but commented out in case
// we decide to implement consumables in future.
// Auto-consume must be true on iOS.
// To try without auto-consume on another platform, change `true` to `false` here.
//final bool _kAutoConsume = Platform.isIOS || true;

class ArvoSubscriptionProvider implements SubscriptionProvider {
  // create as singleton
  static final _shared = ArvoSubscriptionProvider._sharedInstance();
  ArvoSubscriptionProvider._sharedInstance();
  factory ArvoSubscriptionProvider() => _shared;

  late ConnectionProvider _connectionProvider;
  late LocalStorageProvider _localStorageProvider;
  late FeatureProvider _featureProvider;

  // Needs to be assigned outside initialise() because a user has to be logged in.
  Member? _currentUser;
  DatabaseSystemSetting? _databaseSystemSetting;
  final Map<String, Function> _updateFunctionsMap = {};
  final _kSilverSubscriptionFeatures = ProductFeatures(
    productId: Platform.isIOS
        ? kiOSSilverSubscriptionId
        : kAndroidSilverSubscriptionId,
    displayName: 'Silver',
    description:
        'Search for your perfect match without the interruption of ads.',
    features: [
      ProductFeature(
        name: 'No more full screen ads, anywhere',
        iconData: Icons.self_improvement_rounded,
      ),
    ],
    image: 'assets/images/premium_silver.png',
  );
  final _kGoldSubscriptionFeatures = ProductFeatures(
    productId:
        Platform.isIOS ? kiOSGoldSubscriptionId : kAndroidGoldSubscriptionId,
    displayName: 'Gold',
    description:
        'All the exclusive features to help you find your perfect match.',
    features: [
      ProductFeature(
        name: 'See who has added you as a favourite with the Favourited Me tab',
        iconData:
            Platform.isIOS ? CupertinoIcons.heart_fill : Icons.favorite_rounded,
      ),
      ProductFeature(
        name:
            'Match Insight to highlight profile fields where you match with others',
        iconData: Icons.join_left,
      ),
      ProductFeature(
        name: 'Write custom message openers',
        iconData: Platform.isIOS
            ? CupertinoIcons.text_bubble_fill
            : Icons.message_rounded,
      ),
      ProductFeature(
        name: "Online status indicator to show who's online",
        iconData: Icons.radio_button_checked_rounded,
      ),
      ProductFeature(
        name: 'Photo Filter to search for members with photos',
        iconData: Platform.isIOS
            ? CupertinoIcons.photo_fill_on_rectangle_fill
            : Icons.filter_rounded,
      ),
      ProductFeature(
        name: 'Access to dark mode in Settings',
        iconData:
            Platform.isIOS ? CupertinoIcons.moon_fill : Icons.dark_mode_rounded,
      ),
      ProductFeature(
        name: 'No more full screen ads, anywhere',
        iconData: Icons.self_improvement_rounded,
      ),
    ],
    image: 'assets/images/premium_gold.png',
  );

  Member _getCurrentUserOrThrow() {
    if (_currentUser != null) {
      return _currentUser!;
    } else {
      throw GenericUserAccessException(message: 'Invalid user.');
    }
  }

  @override
  InAppPurchase? inAppPurchase = InAppPurchase.instance;

  @override
  bool? isAvailable = false;

  @override
  bool? loading = true;

  @override
  List<String>? notFoundIds = [];

  @override
  List<ProductDetails>? products = [];

  @override
  List<ProductFeatures>? productFeatures = [];

  @override
  bool? purchasePending = false;

  @override
  List<PurchaseDetails>? purchases = [];

  @override
  List<String>? consumables = [];

  @override
  String? queryProductError = '';

  @override
  StreamSubscription<List<PurchaseDetails>>? subscription;

  @override
  bool? hasSilver = false;

  @override
  bool? hasGold = false;

  @override
  void Function()? get onError => _onError;

  void Function()? _onError;

  @override
  set onError(void Function()? value) {
    if (value != null) {
      _onError = value;
    }
  }

  @override
  void Function()? get onDeliverProduct => _onDeliverProduct;

  void Function()? _onDeliverProduct;

  @override
  set onDeliverProduct(void Function()? value) {
    if (value != null) {
      _onDeliverProduct = value;
    }
  }

  @override
  void Function()? get onPurchaseUpdated => _onPurchaseUpdated;

  void Function()? _onPurchaseUpdated;

  @override
  set onPurchaseUpdated(void Function()? value) {
    if (value != null) {
      _onPurchaseUpdated = value;
    }
  }

  @override
  void Function()? get onInvalidPurchase => _onInvalidPurchase;

  void Function()? _onInvalidPurchase;

  @override
  set onInvalidPurchase(void Function()? value) {
    if (value != null) {
      _onInvalidPurchase = value;
    }
  }

  @override
  void initalise(
    ConnectionProvider connectionProvider,
    LocalStorageProvider localStorageProvider,
    FeatureProvider featureProvider,
  ) {
    _connectionProvider = connectionProvider;
    _localStorageProvider = localStorageProvider;
    _featureProvider = featureProvider;
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        inAppPurchase!.purchaseStream;
    subscription =
        purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      subscription?.cancel();
    }, onError: (Object error) {
      throw error;
    });
    productFeatures!
      ..add(_kSilverSubscriptionFeatures)
      ..add(_kGoldSubscriptionFeatures);
    initStoreInfo();
  }

  @override
  Future<void> initStoreInfo() async {
    isAvailable = await inAppPurchase!.isAvailable();
    if (!isAvailable!) {
      isAvailable = isAvailable;
      products = <ProductDetails>[];
      purchases = <PurchaseDetails>[];
      notFoundIds = <String>[];
      //_consumables = <String>[];
      purchasePending = false;
      loading = false;
      _updateListeners();
      return;
    }

    /*if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      // await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }*/

    final ProductDetailsResponse productDetailResponse = await inAppPurchase!
        .queryProductDetails(Platform.isIOS
            ? kiOSProductIds.toSet()
            : kAndroidProductIds.toSet());
    if (productDetailResponse.error != null) {
      queryProductError = productDetailResponse.error!.message;
      isAvailable = isAvailable;
      products = productDetailResponse.productDetails;
      purchases = <PurchaseDetails>[];
      notFoundIds = productDetailResponse.notFoundIDs;
      purchasePending = false;
      loading = false;
      _updateListeners();
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      queryProductError = null;
      isAvailable = isAvailable;
      products = productDetailResponse.productDetails;
      purchases = <PurchaseDetails>[];
      notFoundIds = productDetailResponse.notFoundIDs;
      purchasePending = false;
      loading = false;
      _updateListeners();
      return;
    }

    // final List<String> consumables = await ConsumableStore.load();
    isAvailable = isAvailable;
    products = productDetailResponse.productDetails;
    notFoundIds = productDetailResponse.notFoundIDs;
    purchasePending = false;
    loading = false;
    _updateListeners();
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    if (_currentUser == null) return;

    if (purchases == null) return;

    purchases!.clear();

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        purchasePending = true;
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            final bool isActiveSubscription =
                await _verifySubscription(purchaseDetails);
            if (isActiveSubscription) {
              await _deliverProduct(purchaseDetails);
            }
          } else {
            _handleInvalidPurchase(purchaseDetails);
            break;
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          _handleCanceledPurchase();
        }
        /*if (Platform.isAndroid) {
          if (!_kAutoConsume && purchaseDetails.productID == _kConsumableId) {
            final InAppPurchaseAndroidPlatformAddition androidAddition =
                inAppPurchase!.getPlatformAddition<
                    InAppPurchaseAndroidPlatformAddition>();
            await androidAddition.consumePurchase(purchaseDetails);
          }
        }*/
        if (purchaseDetails.pendingCompletePurchase) {
          await inAppPurchase!.completePurchase(purchaseDetails);
        }
      }
    }

    await _applyFeatures();
    _updateListeners();
    onPurchaseUpdated?.call();
  }

  void handleError(IAPError error) {
    purchasePending = false;
    onError?.call();
  }

  void _updateListeners() {
    // Execute callbacks for views that have registered to listen to updates.
    for (final updateFunction in _updateFunctionsMap.values) {
      updateFunction();
    }
  }

  // NOTE: Use this function to perform any verification on the purchase.
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    return Future<bool>.value(true);
  }

  // NOTE: Use this function to verify a subscription.
  // iOS subscriptions needs to be verified manually, Android automatically verifies them.
  Future<bool> _verifySubscription(PurchaseDetails purchaseDetails) {
    if (Platform.isIOS) {
      if (purchaseDetails.transactionDate == null) {
        return Future<bool>.value(false);
      }

      // Unix to date & time converter https://currentmillis.com/
      final transactionDate = purchaseDetails.transactionDate!;

      int? purchaseDateMilliseconds = int.tryParse(transactionDate);

      if (purchaseDateMilliseconds == null) {
        return Future<bool>.value(false);
      }

      DateTime purchaseDate =
          DateTime.fromMillisecondsSinceEpoch(purchaseDateMilliseconds);

      final expiryDate = purchaseDate.add(const Duration(days: 31));

      bool isActive = DateTime.now().isBefore(expiryDate);

      return Future<bool>.value(isActive);
    }
    return Future<bool>.value(true);
  }

  // NOTE: Use this function to perform actions when purchase verification fails.
  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    onInvalidPurchase?.call();
  }

  void _handleCanceledPurchase() {
    purchasePending = false;
  }

  /*Future<void> consume(String id) async {
    await ConsumableStore.consume(id);
    final List<String> consumables = await ConsumableStore.load();
    setState(() {
      _consumables = consumables;
    });*/

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    /*if (purchaseDetails.productID == _kConsumableId) {
      await ConsumableStore.save(purchaseDetails.purchaseID!);
      final List<String> consumables = await ConsumableStore.load();
      setState(() {
        _purchasePending = false;
        _consumables = consumables;
      });
    } else 
    {*/
    purchases!.add(purchaseDetails);
    purchasePending = false;
    //}
    onDeliverProduct?.call();
  }

  Future<void> _applyFeatures() async {
    if (_currentUser == null) return;

    final hasSilver = purchases!
        .where((purchaseDetails) =>
            purchaseDetails.productID ==
            (Platform.isIOS
                ? kiOSSilverSubscriptionId
                : kAndroidSilverSubscriptionId))
        .isNotEmpty;

    this.hasSilver = hasSilver;

    final hasGold = purchases!
        .where((purchaseDetails) =>
            purchaseDetails.productID ==
            (Platform.isIOS
                ? kiOSGoldSubscriptionId
                : kAndroidGoldSubscriptionId))
        .isNotEmpty;

    this.hasGold = hasGold;

    final databaseUserSetting =
        await _localStorageProvider.getUserSetting(_currentUser!.id);

    databaseUserSetting.featureAdFree = hasSilver || hasGold;
    databaseUserSetting.featureMatchInsight = hasGold;
    databaseUserSetting.featurePhotoTypeSearch = hasGold;
    databaseUserSetting.featureThemeControl = hasGold;
    databaseUserSetting.featureSelectedTheme =
        hasGold ? databaseUserSetting.featureSelectedTheme : 1;
    databaseUserSetting.featureMemberOnlineIndicator = hasGold;
    databaseUserSetting.featureCustomOpeners = hasGold;
    databaseUserSetting.featureFavouritedMe = hasGold;
    databaseUserSetting.memberSearchPhotoType =
        hasGold ? databaseUserSetting.memberSearchPhotoType : photoTypeAll;

    await _localStorageProvider.updateUserSetting(databaseUserSetting);

    // Apply features.
    await _featureProvider.loadSystemParameters();
  }

  @override
  Future<void> restorePurchases() async {
    _currentUser = _connectionProvider.currentUser;

    _getCurrentUserOrThrow();

    _databaseSystemSetting = await _localStorageProvider.getSystemSetting();

    if (isAvailable! && !_databaseSystemSetting!.bypassStore) {
      await inAppPurchase!.restorePurchases();
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
}
