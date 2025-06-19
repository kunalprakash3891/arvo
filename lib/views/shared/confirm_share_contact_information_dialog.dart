import 'dart:io';

import 'package:app_base/dialogs/widget_confirmation_dialog.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';

Future<bool> confirmPostContactInformationDialog(BuildContext context,
    {String? fieldName}) async {
  return await showWidgetConfirmationDialog(
    context: context,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: setHeightBetweenWidgets(
        height: 16.0,
        header: true,
        [
          Icon(
            Platform.isIOS
                ? CupertinoIcons.exclamationmark_triangle_fill
                : Icons.warning_rounded,
            size: 64.0,
          ),
          Text(
            'Are you trying to post your contact details?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (fieldName != null)
            Text(
              "The '$fieldName' field appears to contain contact details.",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          Text(
            "Sharing unsolicited contact information may result in account suspension.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
    confirmText: 'Continue Anyway',
    cancelText: 'Stay and Edit',
  );
}

Future<bool> reportContactInformationDialog(
    BuildContext context, Member member) async {
  return await showWidgetConfirmationDialog(
    context: context,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: setHeightBetweenWidgets(
        height: 16.0,
        header: true,
        [
          Icon(
            Platform.isIOS
                ? CupertinoIcons.exclamationmark_triangle_fill
                : Icons.warning_rounded,
            size: 64.0,
          ),
          Text(
            '${member.name} may be trying to share their contact details with you.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            "If they have sent you their contact details without your request or approval, you can choose to report them.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
    confirmText: 'Report ${member.name}',
    cancelText: "Don't Report",
  );
}

Future<bool> confirmShareContactInformationDialog(BuildContext context) async {
  return await showWidgetConfirmationDialog(
    context: context,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: setHeightBetweenWidgets(
        height: 16.0,
        header: true,
        [
          Icon(
            Platform.isIOS
                ? CupertinoIcons.exclamationmark_triangle_fill
                : Icons.warning_rounded,
            size: 64.0,
          ),
          Text(
            'Are you trying to send or request contact details?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            "Ensure you know the other person well enough before sharing any contact information.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
    confirmText: 'Send Anyway',
    cancelText: "Don't Send",
  );
}
