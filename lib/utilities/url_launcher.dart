import 'package:flutter/material.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:app_base/loading/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> browseToUrl(String url, {BuildContext? context}) async {
  Future<void> navigateToUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not browse to $uri');
    }
  }

  if (context == null) {
    await navigateToUrl(url);
  } else {
    try {
      if (context.mounted) {
        LoadingIndicator().show(
          context: context,
        );
      }
      await navigateToUrl(url);
      if (context.mounted) {
        LoadingIndicator().hide();
      }
    } on Exception catch (e) {
      if (context.mounted) {
        LoadingIndicator().hide();
        await processException(context: context, exception: e);
      }
    }
  }
}
