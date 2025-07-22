import 'dart:async';
import 'dart:io';

import 'package:app_base/dialogs/widget_information_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/localised_assets.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/services/features/subscription_products.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:arvo/services/features/subscription_provider.dart';
import 'package:arvo/services/features/subscription_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:arvo/utilities/url_launcher.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:in_app_purchase/in_app_purchase.dart'
    show PurchaseDetails, ProductDetails, PurchaseParam;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/dialogs/generic_dialog.dart';
import 'package:uuid/uuid.dart';

// TODO: Change elevated buttons to fill/outline buttons.
class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  late final ConnectionService _connectionService;
  late final SubscriptionService _subscriptionService;
  late String _uuid;
  ProductDetails? _purchasingProductDetails;
  late final Future _future;

  @override
  void initState() {
    _connectionService = ConnectionService.arvo();
    _subscriptionService = SubscriptionService.arvo();
    _uuid = const Uuid().v1();
    _subscriptionService.registerFunctionForUpdate(_uuid, () {
      if (mounted) {
        setState(() {});
      }
    });
    _subscriptionService.onError = () {
      _purchasingProductDetails = null;
      if (mounted) {
        showErrorDialog(context,
            text:
                "We're sorry, there was an error processing your purchase, please restart the app and try again.");
      }
    };
    _subscriptionService.onPurchaseUpdated = () {
      // Check if a purchase was in progress and completed successfully
      // before showing the success dialog.
      if (_purchasingProductDetails == null) return;

      bool purchaseSuccessful =
          (_purchasingProductDetails!.id == kSilverSubscriptionId &&
                  _subscriptionService.hasSilver) ||
              (_purchasingProductDetails!.id == kGoldSubscriptionId &&
                  _subscriptionService.hasGold);

      if (!purchaseSuccessful) {
        return;
      }

      _purchasingProductDetails = null;

      final premiumAssetImage = _subscriptionService.hasGold
          ? 'assets/images/premium_gold.png'
          : _subscriptionService.hasSilver
              ? 'assets/images/premium_silver.png'
              : gumLeaves;

      if (mounted) {
        showWidgetInformationDialog(
          context: context,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: setHeightBetweenWidgets(height: 8.0, header: true, [
              SizedBox(
                height: 64.0,
                child: Image(
                  image: AssetImage(
                    premiumAssetImage,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                'Welcome to Premium.',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              Text(
                "Your subscription has been applied.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                "Thank you.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        );
      }
    };
    _subscriptionService.onInvalidPurchase = () {
      _purchasingProductDetails = null;
      if (mounted) {
        showErrorDialog(context,
            text:
                "We're sorry, your purchase could not be verified, please restart the app and try again.");
      }
    };
    super.initState();
    // Restore here to ensure purchases are loaded (in case app has been in-memory for  along time).
    _future = _restorePurchases();
  }

  Future<void> _restorePurchases() async {
    await SubscriptionService.arvo().restorePurchases();
  }

  @override
  void dispose() {
    /*if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel(); */
    _subscriptionService.unregisterFunction(_uuid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> stack = [];

    if (_subscriptionService.queryProductError == null) {
      stack.add(
        _buildProductsScaffold(),
      );
    } else {
      stack.add(
        buildErrorScaffold(
          title: const SizedBox.shrink(),
          error: Exception(_subscriptionService.queryProductError!),
        ),
      );
    }

    if (_subscriptionService.purchasePending) {
      stack.add(
        const Stack(
          children: [
            Opacity(
              opacity: 0.3,
              child: ModalBarrier(dismissible: false, color: Colors.grey),
            ),
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      );
    }

    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildErrorScaffold(error: snapshot.error);
        }
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            return Stack(
              children: stack,
            );
          default:
            return const Center(
              child: CircularProgressIndicator(),
            );
        }
      },
    );
  }

  Widget _buildPremiumHeaderWidget() {
    return Column(
      children: [
        const SizedBox(
          height: 96.0,
          child: Image(
            image: AssetImage(
              logo,
            ),
            fit: BoxFit.cover,
          ),
        ),
        Text(
          _subscriptionService.purchases.isNotEmpty
              ? 'Thank you for choosing Premium'
              : 'Upgrade your experience with Premium',
          style: Theme.of(context)
              .textTheme
              .headlineMedium!
              .copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProductsScaffold() {
    if (_subscriptionService.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (!_subscriptionService.isAvailable) {
      return buildErrorScaffold(
        title: const SizedBox.shrink(),
        error: GenericException(
            title: 'No Connection', message: 'Unable to connect to the store.'),
      );
    }
    final List<Widget> productList = [];
    productList.add(_buildPremiumHeaderWidget());
    if (_subscriptionService.notFoundIds.isNotEmpty) {
      productList.add(
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5.0,
                spreadRadius: 1.0,
                offset: const Offset(1.0, 1.0),
              )
            ],
          ),
          child: Column(
            children: [
              Text('[${_subscriptionService.notFoundIds.join(", ")}] not found',
                  style: TextStyle(color: ThemeData.light().colorScheme.error)),
              const Text('Invalid product configuration.'),
            ],
          ),
        ),
      );
    }

    // This loading previous purchases code is just a demo. Please do not use this as it is.
    // In your app you should always verify the purchase data using the `verificationData` inside the [PurchaseDetails] object before trusting it.
    // We recommend that you use your own server to verify the purchase data.
    final Map<String, PurchaseDetails> purchases =
        Map<String, PurchaseDetails>.fromEntries(
      _subscriptionService.purchases.map(
        (PurchaseDetails purchase) {
          if (purchase.pendingCompletePurchase) {
            _subscriptionService.inAppPurchase!.completePurchase(purchase);
          }
          return MapEntry<String, PurchaseDetails>(
              purchase.productID, purchase);
        },
      ),
    );

    productList.addAll(
      _subscriptionService.products.map(
        (ProductDetails productDetails) {
          final PurchaseDetails? previousPurchase =
              purchases[productDetails.id];
          // Find linked features for product in existing features list.
          final productFeatures = _subscriptionService.productFeatures!
              .where((product) => product.productId == productDetails.id)
              .firstOrNull;
          // If product features could not be found, return SizedBox.shrink(),
          // otherwise build the product container.
          return productFeatures == null
              ? const SizedBox.shrink()
              : Stack(children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5.0,
                          spreadRadius: 1.0,
                          offset: const Offset(1.0, 1.0),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: setHeightBetweenWidgets(
                        [
                          Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                                color: kBasePremiumBackgroundColour,
                                borderRadius: BorderRadius.circular(8.0)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: setWidthBetweenWidgets(
                                [
                                  const SizedBox(
                                    height: 16.0,
                                    width: 16.0,
                                    child: Image(
                                      image: AssetImage(
                                        gumLeaves,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Text(
                                    'Premium',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                            color:
                                                kBasePremiumForegroundTextColour),
                                  ),
                                ],
                                width: 8.0,
                              ),
                            ),
                          ),
                          Text(
                            productFeatures.displayName,
                            style: Theme.of(context).textTheme.displaySmall,
                            textAlign: TextAlign.start,
                          ),
                          Text(
                            '${productDetails.currencyCode} ${productDetails.price} per month',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.start,
                          ),
                          productFeatures.description == null
                              ? const SizedBox.shrink()
                              : Text(
                                  productFeatures.description!,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                          const Divider(),
                          _buildFeaturesWidget(productFeatures),
                          _buildPurchaseWidget(
                            productFeatures,
                            productDetails,
                            previousPurchase,
                          )
                        ],
                        height: 8.0,
                      ),
                    ),
                  ),
                  productFeatures.image != null
                      ? Positioned(
                          top: 0.0,
                          right: -48.0,
                          child: Image.asset(
                            productFeatures.image!,
                            height: 128.0,
                            fit: BoxFit.cover,
                            opacity: const AlwaysStoppedAnimation(0.5),
                          ),
                        )
                      : const SizedBox.shrink(),
                ]);
        },
      ),
    );

    productList.add(_buildFinePrintWidget());

    return Scaffold(
      backgroundColor: const Color(0xff782e43),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: setHeightBetweenWidgets(productList, height: 16.0),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesWidget(ProductFeatures productFeatures) {
    final List<Widget> featuresWidgets = [];

    for (final productFeature in productFeatures.features!) {
      featuresWidgets.add(
        Row(
          children: setWidthBetweenWidgets(
            [
              // NOTE: Additional row here to prevent spacing being
              // added via setWidthBetweenWidgets
              Row(
                children: [
                  productFeature.image != null
                      ? Image.asset(
                          productFeature.image!,
                          height: 24.0,
                          width: 24.0,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox.shrink(),
                  productFeature.iconData != null
                      ? Icon(
                          productFeature.iconData,
                          size: 24.0,
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              Flexible(child: Text(productFeature.name)),
            ],
            width: 8.0,
          ),
        ),
      );
    }

    return Column(
      children: setHeightBetweenWidgets(
        featuresWidgets,
        height: 8.0,
      ),
    );
  }

  Widget _buildPurchaseWidget(ProductFeatures productFeatures,
      ProductDetails productDetails, PurchaseDetails? previousPurchase) {
    const unsubscribeMessageAndroid =
        'Please use the Google Play Store app to cancel your subscription.\n\nIf you have already cancelled, your subscription will automatically expire on the next billing date. Until then, you can continue enjoying the benefits of Premium.';
    const unsubscribeMessageiOS =
        'Please use the Apple App Store app to cancel your subscription.\n\nIf you have already cancelled, your subscription will automatically expire on the next billing date. Until then, you can continue enjoying the benefits of Premium.';
    const existingSubscriptionMessageAndroid =
        'You already have an existing subscription, please use the Google Play Store app to cancel before switching.\n\nIf you have already cancelled, your subscription will automatically expire on the next billing date. Until then, you can continue enjoying the benefits of Premium.';
    const existingSubscriptionMessageiOS =
        'You already have an existing subscription, please use the Apple App Store to cancel before switching.\n\nIf you have already cancelled, your subscription will automatically expire on the next billing date. Until then, you can continue enjoying the benefits of Premium.';

    bool hasPurchased = _subscriptionService.purchases
        .any((purchase) => purchase.productID == productDetails.id);
    return Column(
      children: [
        hasPurchased ? const Divider() : const SizedBox.shrink(),
        hasPurchased
            ? Text(
                'You are a ${productFeatures.displayName} user.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              )
            : const SizedBox.shrink(),
        hasPurchased ? const SizedBox(height: 8.0) : const SizedBox.shrink(),
        hasPurchased
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kRedColour),
                onPressed: () async {
                  await showGenericDialog(
                    context: context,
                    title: 'Unsubscribe',
                    content: Platform.isIOS
                        ? unsubscribeMessageiOS
                        : unsubscribeMessageAndroid,
                    optionsBuilder: () => {
                      'OK': null,
                    },
                  );
                },
                child: const Text(
                  'Unsubscribe',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kActionColour,
                ),
                onPressed: () async {
                  if (_subscriptionService.purchases.isNotEmpty) {
                    await showGenericDialog(
                      context: context,
                      title: 'Switch Subscription',
                      content: Platform.isIOS
                          ? existingSubscriptionMessageiOS
                          : existingSubscriptionMessageAndroid,
                      optionsBuilder: () => {
                        'OK': null,
                      },
                    );
                    return;
                  }

                  late PurchaseParam purchaseParam;

                  if (Platform.isAndroid) {
                    // NOTE: If you are making a subscription purchase/upgrade/downgrade, we recommend you to
                    // verify the latest status of you your subscription by using server side receipt validation
                    // and update the UI accordingly. The subscription purchase status shown
                    // inside the app may not be accurate.
                    /*final GooglePlayPurchaseDetails? oldSubscription =
                          _getOldSubscription(productDetails, purchases);*/

                    purchaseParam = GooglePlayPurchaseParam(
                      productDetails: productDetails,
                    );
                  } else {
                    purchaseParam = PurchaseParam(
                      productDetails: productDetails,
                    );
                  }

                  /*if (productDetails.id == _kConsumableId) {
                      _inAppPurchase.buyConsumable(
                          purchaseParam: purchaseParam,
                          autoConsume: _kAutoConsume);
                    } else */
                  {
                    _purchasingProductDetails = productDetails;
                    _subscriptionService.inAppPurchase!
                        .buyNonConsumable(purchaseParam: purchaseParam);
                  }
                },
                child: Text(
                  'Get ${productFeatures.displayName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
      ],
    );
  }

  /* Card _buildConsumableBox() {
    if (_loading) {
      return const Card(
          child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Fetching consumables...')));
    }
    if (!_isAvailable || _notFoundIds.contains(_kConsumableId)) {
      return const Card();
    }
    const ListTile consumableHeader =
        ListTile(title: Text('Purchased consumables'));
    final List<Widget> tokens = _consumables.map((String id) {
      return GridTile(
        child: IconButton(
          icon: const Icon(
            Icons.stars,
            size: 42.0,
            color: Colors.orange,
          ),
          splashColor: Colors.yellowAccent,
          onPressed: () => consume(id),
        ),
      );
    }).toList();
    return Card(
        child: Column(children: <Widget>[
      consumableHeader,
      const Divider(),
      GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        padding: const EdgeInsets.all(16.0),
        children: tokens,
      )
    ]));
  }*/

  Widget _buildFinePrintWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
      ),
      child: Wrap(
        children: [
          Text(
            'Things that you should know',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                    text: Platform.isIOS
                        ? 'Subscriptions can be managed through the Apple App Store app. '
                        : 'Subscriptions renew every month. You may cancel anytime via Subscriptions in the Google Play Store app. '),
                const TextSpan(
                    text:
                        'Subscriptions and features only apply to this app, they do not apply to the website. View our '),
                TextSpan(
                  text: 'Terms and Conditions',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await browseToUrl(
                        context: context,
                        _connectionService.serverUrl! + termsAndConditionsURL,
                      );
                    },
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await browseToUrl(
                        context: context,
                        _connectionService.serverUrl! + privacyPolicyURL,
                      );
                    },
                ),
                const TextSpan(text: ' for more information.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /*Future<void> consume(String id) async {
    await ConsumableStore.consume(id);
    final List<String> consumables = await ConsumableStore.load();
      if (mounted) {
      setState(() {
        _consumables = consumables;
      });
    }
  }

  void showPendingUI() {
    if (mounted) {
      setState(() {
        _subscriptionService.purchasePending = true;
      });
    }
  }*/

  Future<void> confirmPriceChange(BuildContext context) async {
    // Price changes for Android are not handled by the application, but are
    // instead handled by the Play Store. See
    // https://developer.android.com/google/play/billing/price-changes for more
    // information on price changes on Android.
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iapStoreKitPlatformAddition =
          _subscriptionService.inAppPurchase!
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iapStoreKitPlatformAddition.showPriceConsentIfNeeded();
    }
  }
}
