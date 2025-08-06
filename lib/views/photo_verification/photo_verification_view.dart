import 'dart:io';

import 'package:app_base/dialogs/widget_information_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/photo_verification.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/photo_verification/take_verification_photo_view.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/success_dialog.dart';
import 'package:app_base/loading/loading_screen.dart';
import 'package:nifty_three_bp_app_base/enums/photo_verification_status_type.dart';

class PhotoVerificationView extends StatefulWidget {
  const PhotoVerificationView({super.key});

  @override
  State<PhotoVerificationView> createState() => _PhotoVerificationViewState();
}

class _PhotoVerificationViewState extends State<PhotoVerificationView> {
  late final ConnectionService _connectionService;
  late final Future _future;
  PhotoVerificationPrompt? _photoVerificationPrompt;
  CroppedFile? _croppedImageFile;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _future = _getPhotoVerificationPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildErrorScaffold(
            title: const SizedBox.shrink(),
            error: snapshot.error,
          );
        }
        switch (snapshot.connectionState) {
          case ConnectionState.done:
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
                  title: const Text('Verify Your Account'),
                ),
                bottomNavigationBar: SizedBox(
                  child: BottomAppBar(
                      child: _croppedImageFile == null
                          ? _buildTakeVerificationPhotoWidget()
                          : _buildPhotoUploadWidget()),
                ),
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _croppedImageFile == null
                        ? _buildVerificationPromptImageWidget()
                        : _buildUploadVerificationImageWidget(),
                  ),
                ),
              ),
            );
          default:
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
        }
      },
    );
  }

  Widget _buildVerificationPromptImageWidget() {
    return Column(
      children: setHeightBetweenWidgets(
        height: 16.0,
        [
          Text(
            "Take a selfie while copying the pose in the sample photo below.",
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          CachedNetworkImage(
            imageUrl: _photoVerificationPrompt!.image,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(Platform.isIOS
                    ? CupertinoIcons.xmark_rectangle_fill
                    : Icons.image_not_supported_rounded),
              ),
            ),
            imageBuilder: (context, imageProvider) => Container(
              padding: const EdgeInsets.all(8.0),
              height: 400.0,
              width: 400.0,
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
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            httpHeaders: {
              "Authorization": "Bearer ${_connectionService.token}",
              "User-Agent": "${_connectionService.userAgent}",
            },
          ),
          Text(
            "We'll compare your photo with the sample photo, and verify your account if they are the same.",
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadVerificationImageWidget() {
    final mediaSize = MediaQuery.of(context).size;
    double squareSize = (mediaSize.width / 2) - 16;
    return Column(
      children: setHeightBetweenWidgets(
        height: 16.0,
        [
          Text(
            "Upload this photo?",
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: setWidthBetweenWidgets(
              width: 8.0,
              [
                CachedNetworkImage(
                  imageUrl: _photoVerificationPrompt!.image,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(Platform.isIOS
                          ? CupertinoIcons.xmark_rectangle_fill
                          : Icons.image_not_supported_rounded),
                    ),
                  ),
                  imageBuilder: (context, imageProvider) => Container(
                    padding: const EdgeInsets.all(8.0),
                    height: squareSize,
                    width: squareSize,
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
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                  httpHeaders: {
                    "Authorization": "Bearer ${_connectionService.token}",
                    "User-Agent": "${_connectionService.userAgent}",
                  },
                ),
                Container(
                  height: squareSize,
                  width: squareSize,
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
                    image: DecorationImage(
                      image: FileImage(File(_croppedImageFile!.path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              ],
            ),
          ),
          Text(
            "We'll compare your photo with the sample photo, and verify your account if they are the same.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            "This will not become your profile photo, you'll be able to upload a profile photo after your account has been verified.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTakeVerificationPhotoWidget() {
    return FilledButton(
      onPressed: () async {
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
                'Your face should be clearly visible.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                'You should be copying the pose as best as possible.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        );
        _awaitReturnTakeVerificationPhotoView();
      },
      child: const Text(
        'Continue',
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

  Future<void> _awaitReturnTakeVerificationPhotoView() async {
    // Navigate to view and wait for it to return.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TakeVerificationPhotoView(
          promptImageUrl: _photoVerificationPrompt!.image,
        ),
      ),
    ).then((croppedImageFile) {
      _croppedImageFile = croppedImageFile;
    });
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _getPhotoVerificationPrompt() async {
    _photoVerificationPrompt ??=
        await _connectionService.getPhotoVerificationRandomPrompt();
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
        var sent = await _connectionService.sendPhotoVerificationRequest(
          _photoVerificationPrompt!.id,
          _croppedImageFile!.path,
        );
        if (mounted) {
          LoadingScreen().hide();
        }
        if (sent) {
          _connectionService.currentUser!.photoVerificationStatus =
              PhotoVerificationStatusType.pending;
          if (mounted) {
            await showSuccessDialog(context,
                "Your account verification photo has been uploaded and is now awaiting review.\n\nDon't worry, it won't take long!");
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

  void _clear() {
    if (mounted) {
      setState(() {
        _croppedImageFile = null;
      });
    }
  }
}
