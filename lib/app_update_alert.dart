import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:upgrader/upgrader.dart';

class AppUpdater extends Upgrader {
  AppUpdater({super.debugLogging});
}

class AppUpdateAlert extends UpgradeAlert {
  AppUpdateAlert({super.key, super.upgrader, super.child});

  /// Override the [createState] method to provide a custom class
  /// with overridden methods.
  @override
  UpgradeAlertState createState() => AppUpdateAlertState();
}

class AppUpdateAlertState extends UpgradeAlertState {
  // NOTE: Use this override to enforce dialog display for testing.
  /*@override
  void checkVersion({required BuildContext context}) {
    displayed = true;
    final appMessages = widget.upgrader.determineMessages(context);

    Future.delayed(const Duration(milliseconds: 0), () {
      showTheDialog(
        key: widget.dialogKey ?? const Key('upgrader_alert_dialog'),
        context: context,
        title: appMessages.message(UpgraderMessage.title),
        message: widget.upgrader.body(appMessages),
        releaseNotes:
            shouldDisplayReleaseNotes ? widget.upgrader.releaseNotes : null,
        barrierDismissible: widget.barrierDismissible,
        messages: appMessages,
      );
    });
  }*/

  @override
  void showTheDialog({
    Key? key,
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool barrierDismissible,
    required UpgraderMessages messages,
  }) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              key: key,
              title: const Text('Update Required'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text(Platform.isIOS
                        ? "arvo needs to be updated before proceeding.\n\nTap the Continue button to update."
                        : "arvo needs to be updated before proceeding.\n\nTap the Continue button to update, or Exit to close the app."),
                  ],
                ),
              ),
              actions: [
                if (!Platform.isIOS)
                  TextButton(
                    child: const Text('Exit'),
                    onPressed: () {
                      // Exit the application.
                      SystemChannels.platform
                          .invokeMethod('SystemNavigator.pop');
                    },
                  ),
                TextButton(
                  child: const Text('Continue'),
                  onPressed: () {
                    onUserUpdated(context, !widget.upgrader.blocked());
                  },
                ),
              ],
            ),
          );
        });
  }
}
