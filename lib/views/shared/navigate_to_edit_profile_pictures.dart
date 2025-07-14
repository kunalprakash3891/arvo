import 'package:app_base/loading/loading_indicator.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/connection/connection_service.dart';

Future navigateToEditProfilePicturesView(
    BuildContext context, ConnectionService connectionService,
    {Function? callback}) async {
  // Check if Multiple Photo Management System is available.
  if (context.mounted) {
    LoadingIndicator().show(
      context: context,
    );
  }
  try {
    final multiplePhotoSystemStatus =
        await connectionService.getMultiplePhotoSystemStatus();
    bool userHasUploadedAvatar =
        !memberHasDefaultAvatar(connectionService.currentUser!.avatar!.full!);
    final route = multiplePhotoSystemStatus.available
        // An avatar is already assigned, but does not exist in the Multiple Photo Management System, so navigate
        // to original avatar edit view and prompt user to delete their existing avatar before they can upload more photos.
        ? (userHasUploadedAvatar &&
                (connectionService.currentUser!.photos == null ||
                    connectionService.currentUser!.photos!.isEmpty))
            ? editProfilePictureRoute
            : editProfilePicturesRoute
        : editProfilePictureRoute;
    if (context.mounted) {
      LoadingIndicator().hide();
    }
    // Navigate to view and wait for it to return.
    if (context.mounted) {
      await Navigator.of(context).pushNamed(
        route,
        arguments: multiplePhotoSystemStatus,
      );
    }
    callback?.call();
  } on Exception catch (e) {
    if (context.mounted) {
      LoadingIndicator().hide();
      await processException(context: context, exception: e);
    }
  }
}
