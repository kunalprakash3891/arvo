import 'dart:io';
import 'package:app_base/dialogs/widget_information_dialog.dart';
import 'package:app_base/generics/get_arguments.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/delete_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/dialogs/success_dialog.dart';
import 'package:app_base/loading/loading_screen.dart';
import 'package:nifty_three_bp_app_base/api/multiple_photo.dart';
import 'package:nifty_three_bp_app_base/enums/photo_verification_status_type.dart';

class EditProfilePictureView extends StatefulWidget {
  const EditProfilePictureView({super.key});

  @override
  State<EditProfilePictureView> createState() => _EditProfilePictureViewState();
}

class _EditProfilePictureViewState extends State<EditProfilePictureView> {
  late final ConnectionService _connectionService;
  late Member _currentUser;
  late final ImagePicker _imagePicker;
  late final ImageCropper _imageCropper;
  CroppedFile? _croppedImageFile;
  MultiplePhotoSystemStatus? _multiplePhotoSystemStatus;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _currentUser = _connectionService.currentUser!;
    _imagePicker = ImagePicker();
    _imageCropper = ImageCropper();
  }

  Future<void> _pickImage(ImageSource imageSource) async {
    await showWidgetInformationDialog(
      context: context,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: setHeightBetweenWidgets(height: 8.0, header: true, [
          const SizedBox(
            height: 64.0,
            child: Image(
              image: AssetImage(
                'assets/images/selfie_stick.png',
              ),
              fit: BoxFit.contain,
            ),
          ),
          Text(
            'Please keep the following in mind.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            'Your photo must be of you.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            'Your face should be clearly visible.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
    String? selectedImageFilePath;
    switch (imageSource) {
      case ImageSource.camera:
        selectedImageFilePath =
            (await _imagePicker.pickImage(source: ImageSource.camera))?.path;
      default:
        selectedImageFilePath = (await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: false,
          allowedExtensions: ['jpg', 'jpeg', 'png'],
        ))
            ?.files[0]
            .path;
    }

    if (selectedImageFilePath != null) {
      final croppedImageFile = await _imageCropper.cropImage(
        sourcePath: selectedImageFilePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop',
              toolbarColor: kBaseColour,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: true),
          IOSUiSettings(
            title: 'Crop',
            showCancelConfirmationDialog: true,
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (mounted) {
        setState(() {
          _croppedImageFile = croppedImageFile;
        });
      }
    }
  }

  void _clear() {
    if (mounted) {
      setState(() {
        _croppedImageFile = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiplePhotoSystemStatus =
        context.getArgument<MultiplePhotoSystemStatus>();

    if (multiplePhotoSystemStatus == null) {
      throw Exception('Invalid Multiple Photo Management System Status.');
    }

    _multiplePhotoSystemStatus = multiplePhotoSystemStatus;

    bool userHasDefaultPhoto =
        memberHasDefaultAvatar(_currentUser.avatar!.full!);

    return PopScope(
      canPop: _croppedImageFile == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile Photo'),
        ),
        bottomNavigationBar: SizedBox(
          height: userHasDefaultPhoto ? 112.0 : 180.0,
          child: BottomAppBar(
              child: userHasDefaultPhoto
                  ? _croppedImageFile == null
                      ? _buildSelectPhotoWidget()
                      : _buildPhotoUploadWidget()
                  : _buildDeletePhotoWidget()),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildProfilePhotoWidget(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectPhotoWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: setWidthBetweenWidgets(
        [
          Expanded(
            child: FilledButton(
              onPressed: () async {
                _pickImage(ImageSource.camera);
              },
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: setWidthBetweenWidgets(
                  [
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.camera_fill
                          : Icons.camera_alt_rounded,
                    ),
                    const Text(
                      'Camera',
                    ),
                  ],
                  width: 8.0,
                ),
              ),
            ),
          ),
          Expanded(
            child: FilledButton(
              onPressed: () async {
                _pickImage(ImageSource.gallery);
              },
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: setWidthBetweenWidgets(
                  [
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.photo_fill_on_rectangle_fill
                          : Icons.photo_library_rounded,
                    ),
                    const Text(
                      'Browse',
                    ),
                  ],
                  width: 8.0,
                ),
              ),
            ),
          ),
        ],
        width: 16.0,
      ),
    );
  }

  Widget _buildPhotoUploadWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: setWidthBetweenWidgets(
        [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _clear();
              },
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: setWidthBetweenWidgets(
                  [
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.xmark
                          : Icons.clear_rounded,
                      color: kBaseColour,
                    ),
                    const Text(
                      'Clear',
                    ),
                  ],
                  width: 8.0,
                ),
              ),
            ),
          ),
          Expanded(
            child: FilledButton(
              onPressed: () async {
                _uploadProfilePhoto();
              },
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: setWidthBetweenWidgets(
                  [
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.cloud_upload_fill
                          : Icons.upload_rounded,
                    ),
                    const Text(
                      'Upload',
                    ),
                  ],
                  width: 8.0,
                ),
              ),
            ),
          ),
        ],
        width: 16.0,
      ),
    );
  }

  Widget _buildDeletePhotoWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: setHeightBetweenWidgets(
        [
          _multiplePhotoSystemStatus!.available
              ? Row(
                  children: setWidthBetweenWidgets(
                    width: 16.0,
                    [
                      const SizedBox(
                        height: 48.0,
                        width: 48.0,
                        child: Image(
                          image: AssetImage(
                            'assets/images/new.png',
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Flexible(
                        child: Text(
                          'You can now upload more than one photo, but you will need to delete your current photo first.',
                        ),
                      ),
                    ],
                  ),
                )
              : const Text(
                  'You will need to delete your current photo before uploading a new one.',
                  textAlign: TextAlign.center,
                ),
          FilledButton(
            onPressed: () async {
              await _deleteProfilePhoto(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: kRedColour,
            ),
            child: const Text(
              'Delete Photo',
            ),
          ),
        ],
        height: 8.0,
      ),
    );
  }

  Widget _buildProfilePhotoWidget() {
    bool userHasDefaultPhoto =
        memberHasDefaultAvatar(_currentUser.avatar!.full!);

    return Container(
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5.0,
            spreadRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          )
        ],
        image: userHasDefaultPhoto
            ? _croppedImageFile != null
                ? DecorationImage(
                    image: FileImage(File(_croppedImageFile!.path)),
                    fit: BoxFit.cover,
                  )
                : DecorationImage(
                    image:
                        CachedNetworkImageProvider(_currentUser.avatar!.full!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.6),
                      BlendMode.dstOut,
                    ),
                  )
            : DecorationImage(
                image: CachedNetworkImageProvider(_currentUser.avatar!.full!),
                fit: BoxFit.cover,
              ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  height: 400.0,
                  child: userHasDefaultPhoto
                      ? _croppedImageFile != null
                          ? null
                          : const Center(
                              child: Center(
                                child: Text(
                                  'Use the buttons below to add a profile photo.',
                                  style: TextStyle(
                                    fontSize: 24.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                      : const SizedBox.shrink(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      final shouldUpload = await showConfirmDialog(
        context: context,
        content: 'Upload this photo?',
      );

      if (shouldUpload) {
        if (mounted) {
          LoadingScreen().show(
            context: context,
            text: 'Uploading...',
          );
        }
        var memberAvatar = (await _connectionService
                .updateUserProfilePicture(_croppedImageFile!.path))
            .firstOrNull;
        if (mounted) {
          LoadingScreen().hide();
        }
        if (memberAvatar != null &&
            !memberHasDefaultAvatar(memberAvatar.full!)) {
          if (mounted) {
            await showSuccessDialog(context,
                "Your profile photo has been uploaded and is now awaiting moderation.\n\nDon't worry, it won't take long!");
          }
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        LoadingScreen().hide();
      }
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  Future<void> _deleteProfilePhoto(BuildContext context) async {
    try {
      final shouldDelete = await showDeleteDialog(
        context: context,
        content: 'Delete this photo?',
      );
      if (shouldDelete) {
        if (context.mounted) {
          LoadingScreen().show(
            context: context,
            text: 'Deleting...',
          );
        }
        var deleted =
            (await _connectionService.deleteUserProfilePicture()).deleted;
        if (context.mounted) {
          LoadingScreen().hide();
        }
        if (deleted) {
          await _connectionService.refreshCurrentUser();
          if (mounted) {
            setState(() {
              _currentUser = _connectionService.currentUser!;
            });
          }
          if (_currentUser.photoVerificationStatus !=
              PhotoVerificationStatusType.approved) {
            if (context.mounted) Navigator.of(context).pop();
          }
          if (_multiplePhotoSystemStatus!.available && context.mounted) {
            await Navigator.of(context).popAndPushNamed(
              editProfilePicturesRoute,
              arguments: _multiplePhotoSystemStatus,
            );
          }
        } else {
          if (context.mounted) {
            await showErrorDialog(context);
          }
        }
      }
    } on Exception catch (e) {
      if (context.mounted) {
        LoadingScreen().hide();
      }
      if (context.mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  Future<void> _exit() async {
    if (await showConfirmDialog(
        context: context,
        content:
            "You haven't uploaded your photo yet, exit and discard changes?")) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
