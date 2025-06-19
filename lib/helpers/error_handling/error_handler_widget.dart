import 'package:flutter/material.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:app_base/dialogs/error_dialog.dart';

// Note: The ErrorHandlerWidget wraps around an existing widget to catch errors.

class ErrorHandlerWidget extends StatefulWidget {
  final Widget child;

  const ErrorHandlerWidget({super.key, required this.child});

  @override
  State<ErrorHandlerWidget> createState() => _ErrorHandlerWidgetState();
}

class _ErrorHandlerWidgetState extends State<ErrorHandlerWidget> {
  // Error handling logic
  void onError(FlutterErrorDetails errorDetails) {
    // Add error handling logic here, e.g., logging, reporting to a server, etc.
    if (errorDetails.exception is Exception) {
      processException(
          context: context, exception: errorDetails.exception as Exception);
    } else if (errorDetails.exception is FlutterError) {
      // FlutterError, such as rendering error, swallow the exception.
    } else {
      showErrorDialog(
        context,
        text: errorDetails.exceptionAsString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorWidgetBuilder(
      onError: onError,
      child: widget.child,
    );
  }
}

class ErrorWidgetBuilder extends StatefulWidget {
  final void Function(FlutterErrorDetails) onError;
  final Widget child;

  const ErrorWidgetBuilder({
    super.key,
    required this.onError,
    required this.child,
  });

  @override
  State<ErrorWidgetBuilder> createState() => _ErrorWidgetBuilderState();
}

class _ErrorWidgetBuilderState extends State<ErrorWidgetBuilder> {
  @override
  void initState() {
    super.initState();
    // Set up global error handling
    FlutterError.onError = widget.onError;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
