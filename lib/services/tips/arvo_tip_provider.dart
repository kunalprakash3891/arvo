import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/enums/tip_type.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/tips/tip_provider.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:lottie/lottie.dart';
import 'package:app_base/overlays/tip_overlay.dart';

class ArvoTipProvider implements TipProvider {
  // create as singleton
  static final _shared = ArvoTipProvider._sharedInstance();
  ArvoTipProvider._sharedInstance();
  factory ArvoTipProvider() => _shared;

  late ConnectionProvider _connectionProvider;
  late LocalStorageProvider _localStorageProvider;
  // Needs to be assigned outside initialise() because a user has to be logged in.
  late Member? _currentUser;

  Member _getCurrentUserOrThrow() {
    if (_currentUser != null) {
      return _currentUser!;
    } else {
      throw GenericUserAccessException(message: 'Invalid user.');
    }
  }

  @override
  Future<void> initalise(ConnectionProvider connectionProvider,
      LocalStorageProvider localStorageProvider) async {
    _connectionProvider = connectionProvider;
    _localStorageProvider = localStorageProvider;
  }

  @override
  Future<void> loadSystemParameters() async {
    _currentUser = _connectionProvider.currentUser;

    _getCurrentUserOrThrow();
  }

  @override
  Future<void> showTipOverlay(BuildContext context, TipType tipType) async {
    final databaseUserSetting =
        await _localStorageProvider.getUserSetting(_currentUser!.id);
    switch (tipType) {
      case TipType.tipFiltersApplied:
        if (databaseUserSetting.showTipFiltersApplied && context.mounted) {
          TipOverlay().show(
            context: context,
            widget: _buildFiltersTipWidget(),
            hideCallback: () {},
            dontShowAgainCallback: () async {
              await dismissTip(tipType);
            },
            dontShowAgainButtonBorderColour: kBaseColour,
          );
        }
        break;
      case TipType.tipSwipe:
        if (databaseUserSetting.showTipSwipe && context.mounted) {
          TipOverlay().show(
            context: context,
            widget: _buildSwipeTipWidget(context),
            hideCallback: () {},
            dontShowAgainCallback: () async {
              await dismissTip(tipType);
            },
            dontShowAgainButtonBorderColour: kBaseColour,
          );
        }
        break;
      case TipType.tipMessageGuidelines:
        if (databaseUserSetting.showTipMessageGuidelines && context.mounted) {
          TipOverlay().show(
            context: context,
            widget: _buildGuidelinesTipWidget(context),
            hideCallback: () {},
            dontShowAgainCallback: () async {
              await dismissTip(tipType);
            },
            dontShowAgainButtonBorderColour: kBaseColour,
          );
        }
        break;
    }
  }

  Widget _buildFiltersTipWidget() {
    return Column(
      children: setHeightBetweenWidgets(
        [
          Icon(
            Platform.isIOS
                ? CupertinoIcons.slider_horizontal_3
                : Icons.tune_rounded,
            size: 64.0,
          ),
          const Text(
            "We've applied filters for you based on your profile, you can adjust them by tapping the filters button on the bottom right.",
            textAlign: TextAlign.center,
          ),
        ],
        height: 8.0,
      ),
    );
  }

  Widget _buildSwipeTipWidget(BuildContext context) {
    return Column(
      children: [
        Text(
          "Swipe to Navigate.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Lottie.asset(
              'assets/animations/swipe_left.json',
              repeat: true,
              height: 120.0,
            ),
            Lottie.asset(
              'assets/animations/swipe_right.json',
              repeat: true,
              height: 120.0,
            ),
          ],
        ),
        const Text(
          "Swipe left to view the next profile, and right to view the previous profile.",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGuidelinesTipWidget(BuildContext context) {
    Map<IconData, String> guidelines = {
      Platform.isIOS ? CupertinoIcons.smiley : Icons.mood_rounded:
          "Be polite and respectful in your messages.",
      Platform.isIOS
              ? CupertinoIcons.exclamationmark_triangle_fill
              : Icons.warning_rounded:
          "Exercise caution when sharing any contact details. Do not feel pressured to communicate off-platform.",
      Platform.isIOS
              ? CupertinoIcons.person_crop_circle_fill_badge_exclam
              : Icons.no_accounts_rounded:
          "Sending unsolicited contact information may result in account suspension.",
      Platform.isIOS
          ? CupertinoIcons.exclamationmark_octagon_fill
          : Icons.report_rounded: "Report any users who behave inappropriately."
    };

    List<Widget> guidelinesWidget = [];

    guidelinesWidget.add(
      Text(
        "Help us make this a great experience for everyone.",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );

    guidelines.forEach((key, value) {
      guidelinesWidget.add(
        _buildGuidelineWidget(context, key, value),
      );
    });

    return Column(
      children: setHeightBetweenWidgets(
        guidelinesWidget,
        height: 8.0,
      ),
    );
  }

  Widget _buildGuidelineWidget(
      BuildContext context, IconData iconData, String guildeline) {
    return Row(
      children: setWidthBetweenWidgets(
        width: 8.0,
        [
          Icon(
            iconData,
            size: 32.0,
          ),
          Expanded(
            child: Text(
              guildeline,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> dismissTip(TipType tipType) async {
    // Always read the setting again, in case it has been
    // changed by some other process.
    final databaseUserSetting =
        await _localStorageProvider.getUserSetting(_currentUser!.id);

    switch (tipType) {
      case TipType.tipFiltersApplied:
        {
          if (!databaseUserSetting.showTipFiltersApplied) return;
          databaseUserSetting.showTipFiltersApplied = false;
        }
        break;
      case TipType.tipSwipe:
        {
          if (!databaseUserSetting.showTipSwipe) return;
          databaseUserSetting.showTipSwipe = false;
        }
        break;
      case TipType.tipMessageGuidelines:
        {
          if (!databaseUserSetting.showTipMessageGuidelines) return;
          databaseUserSetting.showTipMessageGuidelines = false;
        }
        break;
    }
    await _localStorageProvider.updateUserSetting(databaseUserSetting);
  }
}
