import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arvo/services/bloc/auth_bloc.dart';
import 'package:arvo/services/bloc/auth_event.dart';
import 'package:arvo/services/bloc/auth_state.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:app_base/dialogs/error_dialog.dart';

class ProcessedException implements Exception {
  final String message;

  ProcessedException(this.message); // Pass your message in constructor.

  @override
  String toString() {
    return message;
  }
}

String processExceptionMessage(Object? exception) {
  if (exception is InvalidUserException) {
    return (exception).message;
  } else if (exception is DeletedUserException) {
    return exception.message;
  } else if (exception is SMSVerificationNotAvailableException) {
    return (exception).message;
  } else if (exception is GenericException) {
    return (exception).message;
  } else if (exception is BadRequestResponseException) {
    return (exception).badRequestResponse.message;
  } else if (exception is GenericRequestException) {
    return (exception).message;
  } else if (exception is GenericUserAccessException) {
    return (exception).message;
  } else {
    return exception.toString();
  }
}

String? processExceptionTitle(Object? exception) {
  if (exception is InvalidUserException) {
    return exception.title;
  } else if (exception is DeletedUserException) {
    return exception.title;
  } else if (exception is SMSVerificationNotAvailableException) {
    return (exception).title;
  } else if (exception is GenericException) {
    return exception.title;
  } else if (exception is GenericUserAccessException) {
    return exception.title;
  }
  return null;
}

Future<ProcessedException?> processException({
  required BuildContext context,
  required Exception? exception,
  bool showDialog = true,
  bool enforceLogOut = false,
}) async {
  if (exception == null) return null;

  String? title;
  late final String message;

  title = processExceptionTitle(exception);

  if (exception is GenericUserAccessException) {
    // GenericUserAccessException always shows a dialog and enforces log out.
    showDialog = true;
    enforceLogOut = true;
  }

  message = processExceptionMessage(exception);

  if (showDialog) {
    if (context.mounted) {
      await showErrorDialog(
        context,
        title: title,
        text: message,
      );
    }
  }

  if (enforceLogOut) {
    if (context.mounted) {
      context.read<AuthBloc>().add(
            const AuthEventLogOut(),
          );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  return ProcessedException(message);
}

Future<ProcessedException?> processBlocException({
  required BuildContext context,
  required AuthState state,
  bool showDialog = true,
  bool enforceLogOut = false,
}) async {
  Exception? exception;

  if (state is AuthStateLoggedOut) {
    exception = state.exception;
  } else if (state is AuthStateLostPassword) {
    exception = state.exception;
  } else if (state is AuthStateNeedsActivation) {
    exception = state.exception;
  } else if (state is AuthStateVerifying) {
    exception = state.exception;
  } else if (state is AuthStateRegistering) {
    exception = state.exception;
  } else if (state is AuthStateLoggedIn) {
    exception = state.exception;
  }

  return await processException(
    context: context,
    exception: exception,
    showDialog: showDialog,
    enforceLogOut: enforceLogOut,
  );
}

void throwUserAccessException(context) async {
  try {
    throw GenericUserAccessException(
        title: 'Exception Test', message: 'User access exception test.');
  } on Exception catch (e) {
    await processException(context: context, exception: e);
  }
}
