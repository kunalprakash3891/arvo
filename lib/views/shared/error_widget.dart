import 'package:flutter/material.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:app_base/utilities/widget_utilities.dart';

Widget buildErrorWidget({
  String? message,
  double width = double.infinity,
}) {
  return Container(
    padding: const EdgeInsets.all(8.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8.0),
      color: Colors.red.shade700,
    ),
    child: Text(
      message ?? localisedGenericFriendlyErrorBodyText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14.0,
      ),
    ),
  );
}

Widget buildCenteredErrorWidget({String? message, Object? error}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: setHeightBetweenWidgets(
        [
          Text(
            message ?? localisedGenericFriendlyErrorBodyText,
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          error != null
              ? Text(
                  '$error',
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        ],
        height: 16.0,
      ),
    ),
  );
}

Widget buildErrorScaffold({Widget? title, Widget? leading, Object? error}) {
  return Scaffold(
    appBar: title == null && leading == null
        ? null
        : AppBar(
            title: title,
            leading: leading,
          ),
    body: buildCenteredErrorWidget(
      message: processExceptionTitle(error),
      error: processExceptionMessage(error),
    ),
  );
}
