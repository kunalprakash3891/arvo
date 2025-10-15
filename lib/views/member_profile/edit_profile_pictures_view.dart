import 'dart:io';

import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/success_dialog.dart';
import 'package:app_base/dialogs/widget_information_dialog.dart';
import 'package:app_base/generics/get_arguments.dart';
import 'package:app_base/loading/loading_screen.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:arvo/utilities/url_launcher.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/multiple_photo.dart';
import 'package:nifty_three_bp_app_base/enums/member_photo_type.dart';
import 'package:nifty_three_bp_app_base/views/widgets/member_grid_widget.dart';
import 'package:uuid/uuid.dart';

class EditProfilePicturesView extends StatefulWidget {
  const EditProfilePicturesView({super.key});

  @override
  State<EditProfilePicturesView> createState() =>
      _EditProfilePicturesViewState();
}

class _EditProfilePicturesViewState extends State<EditProfilePicturesView> {
  late final ConnectionService _connectionService;
  late final FeatureService _featureService;
  late Member _currentUser;
  late final ImagePicker _imagePicker;
  late final ImageCropper _imageCropper;
  final _scrollController = ScrollController();
  final _gridViewKey = GlobalKey();
  late final Future _future;
  final List<MemberPhotoEdit> _userPhotosOriginal = [];
  List<MemberPhotoEdit> _userPhotosEdit = [];
  final List<int> _placeholderIndices = [];
  int? _maxAllowedPhotos;
  late final Uuid _uuid;
  bool _showPhotoPrompt = true;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _featureService = FeatureService.arvo();
    _currentUser = _connectionService.currentUser!;
    _imagePicker = ImagePicker();
    _imageCropper = ImageCropper();
    _uuid = const Uuid();
    _future = _getUserPhotos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiplePhotoSystemStatus =
        context.getArgument<MultiplePhotoSystemStatus>();

    if (multiplePhotoSystemStatus == null) {
      throw Exception('Invalid Multiple Photo Management System Status.');
    }

    _maxAllowedPhotos = multiplePhotoSystemStatus.maximumAllowed;

    // Set fixed placeholders.
    _placeholderIndices.clear();
    for (int i = 0; i < _userPhotosEdit.length; i++) {
      if (_userPhotosEdit[i].isPlaceholder) {
        _placeholderIndices.add(i);
      }
    }

    // Remove placeholders if over maximum.
    if (_userPhotosEdit.length > _maxAllowedPhotos!) {
      final over = _userPhotosEdit.length - _maxAllowedPhotos!;
      for (int i = over - 1; i >= 0; i--) {
        if (_userPhotosEdit.last.isPlaceholder) {
          _userPhotosEdit.removeLast();
        }
      }
    }

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
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) {
                  return;
                }
                _save(prompt: true);
              },
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Edit Profile Photos'),
                  leading: IconButton(
                    onPressed: () async {
                      _save(prompt: true);
                    },
                    icon: Icon(
                      Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        _save();
                      },
                      child: const Text(
                        'Done',
                      ),
                    ),
                  ],
                ),
                body: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: setHeightBetweenWidgets(
                        [
                          Text(
                            'Tap on the boxes below to add your photos. You can add up to $_maxAllowedPhotos photos.',
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                          _buildDragPhotoNotificationWidget(),
                          Expanded(child: _buildProfilePhotosGrid()),
                        ],
                        height: 8.0,
                      ),
                    ),
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

  List<Container> generateChildren() {
    return List.generate(
      _userPhotosEdit.length,
      (index) => Container(
        key: Key(_userPhotosEdit.elementAt(index).uuid),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Stack(
          children: [
            ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(8.0),
                ),
                child: _buildPhotoWidget(_userPhotosEdit.elementAt(index))),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotosGrid() {
    return ReorderableBuilder(
      scrollController: _scrollController,
      lockedIndices: _placeholderIndices,
      onReorder: (ReorderedListFunction reorderedListFunction) {
        _userPhotosEdit =
            reorderedListFunction(_userPhotosEdit) as List<MemberPhotoEdit>;
        // Set the first photo to be the avatar.
        for (int i = 0; i < _userPhotosEdit.length; i++) {
          if (i == 0) {
            _userPhotosEdit[i].type = MemberPhotoType.avatar;
          } else {
            _userPhotosEdit[i].type = MemberPhotoType.gallery;
          }
        }
        if (mounted) {
          setState(() {});
        }
      },
      builder: (children) {
        return GridView(
          key: _gridViewKey,
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
          ),
          children: children,
        );
      },
      children: generateChildren(),
    );
  }

  Future<void> _getUserPhotos() async {
    final userPhotos = await _connectionService.getUserPhotos();

    for (final userPhoto in userPhotos) {
      _userPhotosEdit.add(MemberPhotoEdit(
        uuid: _uuid.v1(),
        sequence: userPhoto.sequence,
        mediaId: userPhoto.mediaId,
        mediaUrl: userPhoto.urls.full,
        type: userPhoto.type,
        status: userPhoto.status,
      ));
    }

    _userPhotosEdit.sort((a, b) => a.sequence.compareTo(b.sequence));

    // Add placeholders.
    final placeholderCount = _maxAllowedPhotos! - _userPhotosEdit.length;
    for (int i = 0; i < placeholderCount; i++) {
      _userPhotosEdit.add(
        MemberPhotoEdit(
          uuid: _uuid.v1(),
          sequence: _maxAllowedPhotos!,
        ),
      );
    }

    for (final userPhotoEdit in _userPhotosEdit) {
      _userPhotosOriginal.add(MemberPhotoEdit.clone(userPhotoEdit));
    }

    // Assign an avatar if none exists.
    if (_userPhotosEdit
        .where((userPhoto) => userPhoto.type == MemberPhotoType.avatar)
        .isEmpty) {
      if (!_userPhotosEdit.first.isPlaceholder) {
        _userPhotosEdit.first.type = MemberPhotoType.avatar;
      }
    }
  }

  Widget _buildPhotoWidget(MemberPhotoEdit memberPhotoEdit) {
    return Stack(
      children: [
        (memberPhotoEdit.mediaId != null && memberPhotoEdit.mediaUrl != null)
            ? Image(
                image: CachedNetworkImageProvider(memberPhotoEdit.mediaUrl!))
            : memberPhotoEdit.croppedFile != null
                ? Image(
                    image: FileImage(File(memberPhotoEdit.croppedFile!.path)))
                : GestureDetector(
                    onTap: () => {
                      _showSelectPhotoModalSheet(memberPhotoEdit),
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _showSelectPhotoModalSheet(memberPhotoEdit);
                        },
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              _showSelectPhotoModalSheet(memberPhotoEdit);
                            },
                            child: Icon(
                              Platform.isIOS
                                  ? CupertinoIcons.add
                                  : Icons.add_rounded,
                              size: 48.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
        if (memberPhotoEdit.type == MemberPhotoType.avatar)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildMainPhotoWidget(memberPhotoEdit),
            ),
          ),
        if (!memberPhotoEdit.isPlaceholder)
          Align(
            alignment: Alignment.topRight,
            child: FloatingActionButton.small(
              heroTag: null,
              shape: const CircleBorder(),
              onPressed: () {
                _deletePhoto(memberPhotoEdit);
              },
              child: Icon(
                Platform.isIOS ? CupertinoIcons.delete : Icons.delete_rounded,
                size: 24.0,
              ),
            ),
          ),
      ],
    );
  }

  void _showSelectPhotoModalSheet(MemberPhotoEdit memberPhotoEdit) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 210.0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildSelectPhotoWidget(memberPhotoEdit),
          ),
        );
      },
    );
  }

  Widget _buildSelectPhotoWidget(MemberPhotoEdit memberPhotoEdit) {
    return Column(
      children: setHeightBetweenWidgets(
        [
          Expanded(
            child: FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _pickImage(
                    ImageSource.camera,
                    _userPhotosEdit
                        .where((userPhoto) => userPhoto.isPlaceholder)
                        .first);
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
                Navigator.pop(context);
                await _pickImage(
                    ImageSource.gallery,
                    _userPhotosEdit
                        .where((userPhoto) => userPhoto.isPlaceholder)
                        .first);
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
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Close',
              ),
            ),
          ),
        ],
        height: 16.0,
      ),
    );
  }

  Widget _buildMainPhotoWidget(MemberPhotoEdit memberPhotoEdit) {
    return GestureDetector(
      onTap: () async {
        showWidgetInformationDialog(
          context: context,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: setHeightBetweenWidgets(
              height: 16.0,
              header: true,
              [
                SizedBox(
                  width: 160.0,
                  height: 296.0,
                  child: buildMemberItemWidget(
                    context: context,
                    member: _currentUser,
                    lastItem: false,
                    showStatus: _featureService.featureMemberOnlineIndicator,
                    onlineColour: kBaseOnlineColour,
                    recentlyOnlineColour: kBaseRecentlyOnlineColour,
                    matchWeightColour: getMatchPercentageColour(
                        _currentUser.matchWeight,
                        _featureService.featureMatchInsight),
                    verifiedMemberIndicatorColour: kBaseVerifiedIndicatorColour,
                    avatarHeight: 216.0,
                    avatarUrl: memberPhotoEdit.mediaUrl,
                    imageFilePath: memberPhotoEdit.croppedFile?.path,
                  ),
                ),
                Text(
                  'Your main photo is the first picture that other users will see.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          buttonText: 'Close',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            color: kBaseColour,
            borderRadius: BorderRadius.circular(8.0)),
        child: const Text(
          'Main photo',
          style: TextStyle(color: Colors.white, fontSize: 12.0),
        ),
      ),
    );
  }

  Future _pickImage(
      ImageSource imageSource, MemberPhotoEdit memberPhotoEdit) async {
    if (_showPhotoPrompt) {
      _showPhotoPrompt = false;
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
    }
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
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
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
          memberPhotoEdit.croppedFile = croppedImageFile;
          memberPhotoEdit.mediaId = null;
          memberPhotoEdit.mediaUrl = null;
          if (_userPhotosEdit
              .where((userPhoto) => userPhoto.type == MemberPhotoType.avatar)
              .isEmpty) {
            memberPhotoEdit.type = MemberPhotoType.avatar;
          } else {
            memberPhotoEdit.type = MemberPhotoType.gallery;
          }
        });
      }
    }
  }

  void _deletePhoto(MemberPhotoEdit memberPhotoEdit) {
    final placeholder = MemberPhotoEdit(
      uuid: _uuid.v1(),
      sequence: _maxAllowedPhotos!,
    );
    final index = _userPhotosEdit.indexOf(memberPhotoEdit);
    if (_userPhotosEdit.last == memberPhotoEdit ||
        _userPhotosEdit[index + 1].isPlaceholder) {
      _userPhotosEdit[index] = placeholder;
    } else {
      _userPhotosEdit.removeAt(_userPhotosEdit.indexOf(memberPhotoEdit));
      _userPhotosEdit.add(placeholder);
    }
    // Assign new avatar if required.
    if (_userPhotosEdit
        .where((userPhoto) => userPhoto.type == MemberPhotoType.avatar)
        .isEmpty) {
      if (!_userPhotosEdit.first.isPlaceholder) {
        _userPhotosEdit.first.type = MemberPhotoType.avatar;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  List<MemberPhotoUpdate> _generateUpdateRequests() {
    List<MemberPhotoUpdate> updateRequests = [];

    // If no changes were made then return empty list.
    Function listEquality = const ListEquality().equals;

    if (listEquality(_userPhotosEdit, _userPhotosOriginal)) {
      return updateRequests;
    }

    // Set the new sequence numbers.
    for (int i = 0; i < _userPhotosEdit.length; i++) {
      _userPhotosEdit[i].sequence = i;
    }
    // Set an avatar in case there is none assigned.
    if ((_userPhotosEdit
            .where((userPhoto) => !userPhoto.isPlaceholder)
            .isNotEmpty) &&
        (_userPhotosEdit
            .where((userPhoto) => userPhoto.type == MemberPhotoType.avatar)
            .isEmpty)) {
      _userPhotosEdit
          .where((userPhoto) => !userPhoto.isPlaceholder)
          .first
          .type = MemberPhotoType.avatar;
    }

    for (final userPhotoEdit in _userPhotosEdit) {
      if (userPhotoEdit.isPlaceholder) {
        continue;
      }
      final file = userPhotoEdit.croppedFile?.path;
      updateRequests.add(MemberPhotoUpdate(
        file: file,
        mediaId: userPhotoEdit.mediaId,
        sequence: userPhotoEdit.sequence,
        type: userPhotoEdit.type,
      ));
    }
    return updateRequests;
  }

  Future<void> _save({bool prompt = false}) async {
    try {
      bool canPop = true;
      // Build list of changes.
      final updateRequests = _generateUpdateRequests();
      // Determine if uploading new photos.
      final isUploading = _userPhotosEdit
          .where((userPhoto) => userPhoto.isUploading)
          .isNotEmpty;
      // Determine if deleting all existing photos.
      final isDeleting = (_userPhotosOriginal
              .where((userPhoto) => !userPhoto.isPlaceholder)
              .isNotEmpty &&
          _userPhotosEdit
              .where((userPhoto) => !userPhoto.isPlaceholder)
              .isEmpty);

      // POST any changes.
      if (updateRequests.isNotEmpty || isDeleting) {
        bool canSave = true;

        if (prompt && mounted && canSave) {
          canSave = await showConfirmDialog(
              context: context,
              content: 'Would you like to save your changes?');
        }

        if (canSave) {
          if (mounted) {
            LoadingScreen().show(
              context: context,
              text: 'Updating...',
            );
          }

          if (isDeleting) {
            await _connectionService.deleteUserPhotos();
          } else {
            await _connectionService.updateUserPhotos(updateRequests);
          }
          // Refresh the current user.
          await _connectionService.refreshCurrentUser();
          if (mounted) {
            LoadingScreen().hide();
            if (isUploading) {
              await showSuccessDialog(context,
                  "Your profile photos have been updated and are now awaiting moderation.\n\nDon't worry, it won't take long!");
            } else {
              const snackBar = SnackBar(
                content: Text("Your photos have been updated."),
                duration: Duration(seconds: 2),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          }
          canPop = true;
        } else {
          canPop = true;
        }
      }

      if (canPop) {
        // Pop the page.
        if (mounted) {
          Navigator.of(context).pop();
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

  Widget _buildDragPhotoNotificationWidget() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
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
      ),
      child: Row(
        children: setWidthBetweenWidgets(
          width: 8.0,
          [
            Icon(
              Platform.isIOS ? CupertinoIcons.info : Icons.info_rounded,
              size: 32.0,
            ),
            const Expanded(
              child: Text(
                'To reposition, hold down then drag on a photo.',
              ),
            )
          ],
        ),
      ),
    );
  }
}

class MemberPhotoEdit {
  String uuid;
  int? mediaId;
  String? mediaUrl;
  CroppedFile? croppedFile;
  int sequence;
  MemberPhotoType? type;
  MemberPhotoModerationStatusType? status;
  MemberPhotoEdit({
    required this.uuid,
    required this.sequence,
    this.mediaId,
    this.mediaUrl,
    this.croppedFile,
    this.type,
    this.status,
  });

  bool get isPlaceholder =>
      mediaId == null && mediaUrl == null && croppedFile == null;

  bool get isUploading => croppedFile != null;

  MemberPhotoEdit.clone(MemberPhotoEdit memberPhotoEdit)
      : this(
          uuid: memberPhotoEdit.uuid,
          mediaId: memberPhotoEdit.mediaId,
          mediaUrl: memberPhotoEdit.mediaUrl,
          croppedFile: memberPhotoEdit.croppedFile,
          sequence: memberPhotoEdit.sequence,
          type: memberPhotoEdit.type,
          status: memberPhotoEdit.status,
        );

  @override
  bool operator ==(covariant MemberPhotoEdit other) =>
      other.uuid == uuid &&
      other.sequence == sequence &&
      other.mediaId == mediaId &&
      other.mediaUrl == mediaUrl &&
      other.croppedFile == croppedFile &&
      other.type == type &&
      other.status == status;

  @override
  int get hashCode => uuid.hashCode;
}
