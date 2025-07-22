import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/services/ads/ad.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';

typedef HideCallback = void Function();

class AdOverlay {
  AdOverlayController? controller;
  HideCallback? hideCallback;

  void show({
    required BuildContext context,
    required Ad ad,
    HideCallback? hideCallback,
  }) {
    controller = showOverlay(
      context: context,
      ad: ad,
      hideCallback: hideCallback,
    );
  }

  void hide() {
    hideCallback?.call();
    controller?.close();
    controller = null;
  }

  AdOverlayController showOverlay({
    required BuildContext context,
    required Ad ad,
    HideCallback? hideCallback,
  }) {
    // get the state of the parent overlay
    final state = Overlay.of(context);
    this.hideCallback = hideCallback;
    // create the overlay
    // overlays don't have a parent such as a scaffold, so they need to be wrapped with
    // a material component
    final mediaSize = MediaQuery.of(context).size;
    final overlay = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.black.withOpacity(0.7),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Advertisement'),
              actions: [
                IconButton(
                  onPressed: hide,
                  icon: Icon(Platform.isIOS
                      ? CupertinoIcons.xmark
                      : Icons.close_rounded),
                )
              ],
            ),
            bottomNavigationBar: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
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
                    children: setHeightBetweenWidgets(
                      [
                        Text(
                          ad.headline,
                          style: Theme.of(context).textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                        ad.promoText != null
                            ? Text(
                                ad.promoText!,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              )
                            : const SizedBox.shrink(),
                        ad.assetImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image(
                                  height: mediaSize.height * 0.5,
                                  image: AssetImage(
                                    ad.assetImage!,
                                  ),
                                  fit: BoxFit.fitHeight,
                                ),
                              )
                            : const SizedBox.shrink(),
                        FilledButton(
                          onPressed: () async {
                            hide();
                            await Navigator.of(context)
                                .pushNamed(subscriptionsViewRoute);
                          },
                          style: FilledButton.styleFrom(
                              backgroundColor: kBasePremiumBackgroundColour),
                          child: const Text(
                            'Get Premium',
                            style: TextStyle(
                              color: kBasePremiumForegroundTextColour,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: hide,
                          child: const Text(
                            'Skip',
                          ),
                        ),
                      ],
                      height: 8.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // insert the overlay into the current state
    state.insert(overlay);

    return AdOverlayController(
      close: () {
        overlay.remove();
        return true;
      },
    );
  }
}

// available functions
typedef CloseAdOverlay = bool Function();

@immutable
class AdOverlayController {
  final CloseAdOverlay close;

  const AdOverlayController({
    required this.close,
  });
}
