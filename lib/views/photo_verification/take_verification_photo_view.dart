import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:image_cropper/image_cropper.dart';

class TakeVerificationPhotoView extends StatefulWidget {
  final String promptImageUrl;

  const TakeVerificationPhotoView({required this.promptImageUrl, super.key});

  @override
  State<TakeVerificationPhotoView> createState() =>
      _TakeVerificationPhotoViewState();
}

class _TakeVerificationPhotoViewState extends State<TakeVerificationPhotoView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final ConnectionService _connectionService;
  late final String _promptImageUrl;
  final List<CameraDescription> _cameras = <CameraDescription>[];
  CameraController? _cameraController;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  CameraDescription? _selectedCamera;
  FlashMode _flashMode = FlashMode.auto;
  int _selectedCameraIndex = 0;
  late final ImageCropper _imageCropper;
  CroppedFile? _croppedImageFile;
  late final Future _future;
  Object? _error;
  bool _camerasInitialised = false;
  bool _isCropping = false;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectionService = ConnectionService.arvo();
    _promptImageUrl = widget.promptImageUrl;
    _imageCropper = ImageCropper();
    _future = _initialiseCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  // #docregion AppLifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Don't dispose the camera controller while cropping since CameraPreview
      // is still active.
      if (!_isCropping) {
        cameraController.dispose();
      }
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }
  // #enddocregion AppLifecycle

  @override
  Widget build(BuildContext context) {
    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
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
            return _error != null
                ? buildErrorScaffold(
                    title: const SizedBox.shrink(),
                    error: _error,
                  )
                : (_cameraController == null ||
                        !_cameraController!.value.isInitialized ||
                        _isCropping)
                    ? Scaffold(
                        appBar: AppBar(),
                        body: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Scaffold(
                        appBar: AppBar(
                          iconTheme: const IconThemeData(color: Colors.white),
                          backgroundColor: Colors.transparent,
                        ),
                        floatingActionButton: _buildCameraControlsWidget(),
                        floatingActionButtonLocation:
                            FloatingActionButtonLocation.centerFloat,
                        body: Stack(
                          alignment: FractionalOffset.center,
                          children: [
                            Positioned.fill(
                              child: ClipRect(
                                child: OverflowBox(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      height: 1,
                                      child: AspectRatio(
                                        aspectRatio: isPortrait
                                            ? 1 /
                                                _cameraController!
                                                    .value.aspectRatio
                                            : _cameraController!
                                                    .value.aspectRatio /
                                                1,
                                        child: _buildCameraPreviewWidget(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 40.0, right: 16.0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: CachedNetworkImage(
                                  imageUrl: _promptImageUrl,
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
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                    padding: const EdgeInsets.all(8.0),
                                    height: 176.0,
                                    width: 176.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
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
                                    "Authorization":
                                        "Bearer ${_connectionService.token}",
                                    "User-Agent":
                                        "${_connectionService.userAgent}",
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        extendBodyBehindAppBar: true,
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

  Future<void> _initialiseCameras() async {
    if (_camerasInitialised) return;

    // availableCameras() can return multiple cameras (duplicates), use the first front
    // and back camera from the list.
    final cameras = await availableCameras();
    final frontCamera = cameras
        .where((camera) => camera.lensDirection == CameraLensDirection.front)
        .firstOrNull;
    final backCamera = cameras
        .where((camera) => camera.lensDirection == CameraLensDirection.back)
        .firstOrNull;
    if (frontCamera != null) _cameras.add(frontCamera);
    if (backCamera != null) _cameras.add(backCamera);
    _camerasInitialised = true;
    if (_cameras.isNotEmpty) {
      _selectedCamera = _cameras[_selectedCameraIndex];
      await _onNewCameraSelected(_selectedCamera!);
    }
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _buildCameraPreviewWidget() {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Text(
        'No camera found.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          cameraController,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapDown: (TapDownDetails details) =>
                  _onViewFinderTap(details, constraints),
            );
          }),
        ),
      );
    }
  }

  Widget _buildCameraControlsWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: setWidthBetweenWidgets(
        width: 16.0,
        [
          FloatingActionButton.small(
            heroTag: null,
            shape: const CircleBorder(),
            onPressed: () async {
              _toggleFlashMode();
            },
            backgroundColor: Colors.black.withValues(alpha: 0.4),
            child: Icon(
              _getFlashIcon(),
              size: 24.0,
              color: Colors.white,
            ),
          ),
          FloatingActionButton(
            heroTag: null,
            shape: const CircleBorder(),
            onPressed: () async {
              _takePicture();
            },
            child: Icon(
              Platform.isIOS ? CupertinoIcons.camera : Icons.camera,
              size: 32.0,
            ),
          ),
          _cameras.length > 1
              ? FloatingActionButton.small(
                  heroTag: null,
                  shape: const CircleBorder(),
                  onPressed: () async {
                    _toggleCamera();
                  },
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: Icon(
                    Platform.isIOS
                        ? CupertinoIcons.switch_camera
                        : Icons.cameraswitch_rounded,
                    size: 24.0,
                    color: Colors.white,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale.
    if (_cameraController == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await _cameraController!.setZoomLevel(_currentScale);
  }

  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_cameraController == null) {
      return;
    }

    final CameraController cameraController = _cameraController!;

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      return _cameraController!.setDescription(cameraDescription);
    } else {
      return _initializeCameraController(cameraDescription);
    }
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        throw Exception(cameraController.value.errorDescription);
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait(<Future<Object?>>[
        cameraController
            .getMaxZoomLevel()
            .then((double value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((double value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'CameraAccessDenied':
          _error = GenericException(
              title: 'Permissions Denied.',
              message:
                  'You have denied camera permissions.\n\nPlease use your Settings app to enable camera access.');
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          _error = GenericException(
              title: 'Permissions Denied.',
              message: 'Please use your Settings app to enable camera access.');
        case 'CameraAccessRestricted':
          // iOS only
          _error = GenericException(
              title: 'Permissions Denied.',
              message: 'Camera access is restricted.');
        case 'AudioAccessDenied':
          _error = GenericException(
              title: 'Permissions Denied.',
              message:
                  'You have denied audio permissions.\n\nPlease use your Settings app to enable audio access.');
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          _error = GenericException(
              title: 'Permissions Denied.',
              message: 'Please use your Settings app to enable audio access.');
        case 'AudioAccessRestricted':
          // iOS only
          _error = GenericException(
              title: 'Permissions Denied.',
              message: 'Audio access is restricted.');
        default:
          if (mounted) {
            await processException(context: context, exception: e);
          }
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _takePicture() async {
    try {
      final CameraController? cameraController = _cameraController;
      if (cameraController == null || !cameraController.value.isInitialized) {
        throw Exception('Camera not initialised.');
      }

      if (cameraController.value.isTakingPicture) {
        // A capture is already pending, do nothing.
        return;
      }

      final XFile file = await cameraController.takePicture();

      _isCropping = true;

      final croppedImageFile = await _imageCropper.cropImage(
        sourcePath: file.path,
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

      _croppedImageFile = croppedImageFile;
      _isCropping = false;
      if (mounted) {
        WidgetsBinding.instance.removeObserver(this);
        Navigator.of(context).pop(_croppedImageFile);
      }
    } on Exception catch (e) {
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.isEmpty) return;

    if (_cameras.length == 1) return;

    _selectedCameraIndex = _selectedCameraIndex + 1;
    if (_selectedCameraIndex == _cameras.length) {
      _selectedCameraIndex = 0;
    }
    _selectedCamera = _cameras[_selectedCameraIndex];
    await _onNewCameraSelected(_selectedCamera!);
  }

  Future<void> _toggleFlashMode() async {
    if (_cameraController == null) {
      return;
    }

    final CameraController cameraController = _cameraController!;

    try {
      switch (_flashMode) {
        case FlashMode.auto:
          _flashMode = FlashMode.off;
        case FlashMode.off:
          _flashMode = FlashMode.always;
        case FlashMode.always:
          _flashMode = FlashMode.torch;
        case FlashMode.torch:
          _flashMode = FlashMode.auto;
      }
      await cameraController.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.torch:
        return Icons.flashlight_on_rounded;
    }
  }
}
