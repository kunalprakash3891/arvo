import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/views/shared/navigate_to_edit_profile_pictures.dart';
import 'package:nifty_three_bp_app_base/constants/reporting.dart';
import 'package:arvo/constants/routes.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:nifty_three_bp_app_base/enums/menu_action.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/development/development_service.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/services/messaging/messaging_handler_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/member_reporting/report_member_view.dart';
import 'package:arvo/views/messages/message_thread_view.dart';
import 'package:arvo/views/messages/new_message_thread_view.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:nifty_three_bp_app_base/views/exceptions/favourites_exceptions.dart';
import 'package:arvo/views/shared/member_profile_widget.dart';
import 'package:nifty_three_bp_app_base/views/exceptions/messaging_exceptions.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/generics/get_arguments.dart';
import 'package:app_base/loading/loading_indicator.dart';

class MemberProfileView extends StatefulWidget {
  const MemberProfileView({super.key});

  @override
  State<MemberProfileView> createState() => _MemberProfileViewState();
}

class _MemberProfileViewState extends State<MemberProfileView> {
  late final ConnectionService _connectionService;
  late final MemberDirectoryService _memberDirectoryService;
  late final MessagingHandlerService _messagingHandlerService;
  late final FeatureService _featureService;
  Member? _member;
  late Member _currentUser;
  late final ValueNotifier<bool> _favouriteLoaded;
  late final ValueNotifier<bool> _isBlockedLoaded;
  late final ValueNotifier<bool> _matchInsightEnabled;
  bool _isProcessingBlock = false;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _currentUser = _connectionService.currentUser!;
    _memberDirectoryService = MemberDirectoryService.arvo();
    _messagingHandlerService = MessagingHandlerService.arvo();
    _featureService = FeatureService.arvo();
    _favouriteLoaded = ValueNotifier(false);
    _isBlockedLoaded = ValueNotifier(false);
    _matchInsightEnabled = ValueNotifier(false);
  }

  @override
  void dispose() {
    _favouriteLoaded.dispose();
    _isBlockedLoaded.dispose();
    _matchInsightEnabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Assign member if not already assigned otherwise any changes won't be
    // reflected when returning from the group edit view.
    _member = _member ?? context.getArgument<Member>();

    if (_member == null) throw Exception('Invalid member.');

    final title = Text(
      _member!.name!,
      overflow: TextOverflow.ellipsis,
    );

    return FutureBuilder(
      // Note: CircularProgressIndicator is not needed here because buttons
      // are updated by values notifiers.
      future: _getMemberStatus(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildErrorScaffold(
            title: title,
            error: snapshot.error,
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: title,
            actions: [
              _buildPopupMenuWidget(),
            ],
          ),
          // Nested scaffold to allow snackbars to overlap floating buttons.
          body: Scaffold(
            floatingActionButton: _buildFloatingButtonWidget(),
            body: ValueListenableBuilder(
              valueListenable: _matchInsightEnabled,
              builder: (context, value, child) {
                return MemberProfileWidget(
                  member: _member!,
                  currentUser: _currentUser,
                  editProfilePictures: _awaitReturnFromEditProfilePicturesView,
                  editProfileGroup: _awaitReturnFromEditProfileGroupView,
                  verify: _awaitReturnFromPhotoVerificationView,
                  // TODO: Implement premium promotion for Match Insight
                  //toggleMatchInsight: _toggleMatchInsight,
                  matchInsight: value,
                  hasFeatureMemberOnlineIndicator:
                      _featureService.featureMemberOnlineIndicator,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupMenuWidget() {
    return _member!.id == _currentUser.id
        ? const SizedBox.shrink()
        : PopupMenuButton<MemberProfileMenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MemberProfileMenuAction.block:
                  _toggleBlocked();
                  break;
                case MemberProfileMenuAction.report:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportMemberView(
                        member: _member!,
                        category: reportCategoryProfileContent,
                      ),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<MemberProfileMenuAction>(
                  value: MemberProfileMenuAction.block,
                  child: _member!.isBlocked!
                      ? const Text('Unbock')
                      : const Text('Block'),
                ),
                const PopupMenuItem<MemberProfileMenuAction>(
                  value: MemberProfileMenuAction.report,
                  child: Text('Report'),
                ),
              ];
            },
          );
  }

  Widget? _buildFloatingButtonWidget() {
    return _member == null
        ? null
        : ValueListenableBuilder(
            valueListenable: _isBlockedLoaded,
            builder: (context, value, child) {
              if (!value) {
                return _buildStatusPendingFloatingButtonsWidget();
              } else {
                return _member!.isBlocked != null && _member!.isBlocked!
                    ? _buildBlockedFloatingButtonWidget()
                    : _buildFavouriteFloatingButtonsWidget();
              }
            },
          );
  }

  Widget _buildStatusPendingFloatingButtonsWidget() {
    return _member!.isBlocked == null
        ? const SizedBox.shrink()
        : Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _member!.isBlocked!
                ? [
                    _buildLoadingFloatingButtonWidget(kBaseColour),
                  ]
                : setHeightBetweenWidgets(
                    [
                      _buildLoadingFloatingButtonWidget(kBaseColour),
                      _buildLoadingFloatingButtonWidget(kBaseColour),
                    ],
                    height: 8.0,
                  ),
          );
  }

  Widget _buildLoadingFloatingButtonWidget(Color colour) {
    return FloatingActionButton(
      heroTag: null,
      shape: const CircleBorder(),
      onPressed: () {},
      child: Center(
        child: CircularProgressIndicator(
          color: colour,
        ),
      ),
    );
  }

  Widget _buildBlockedFloatingButtonWidget() {
    return ValueListenableBuilder(
      valueListenable: _isBlockedLoaded,
      builder: (context, value, child) {
        if (!value) {
          return _buildLoadingFloatingButtonWidget(kBaseColour);
        } else {
          return FloatingActionButton(
            heroTag: null,
            shape: const CircleBorder(),
            onPressed: () async {
              _toggleBlocked();
            },
            child: _member!.isBlocked != null && _member!.isBlocked!
                ? Icon(
                    Platform.isIOS
                        ? CupertinoIcons.lock_open_fill
                        : Icons.lock_open_rounded,
                    color: kBaseColour,
                    size: 32.0,
                  )
                : const SizedBox.shrink(),
          );
        }
      },
    );
  }

  Widget _buildFavouriteFloatingButtonsWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: setHeightBetweenWidgets(
        [
          ValueListenableBuilder(
            valueListenable: _favouriteLoaded,
            builder: (context, value, child) {
              if (!value) {
                return _buildLoadingFloatingButtonWidget(kBaseFavouriteColour);
              } else {
                return FloatingActionButton(
                  heroTag: null,
                  shape: const CircleBorder(),
                  onPressed: () async {
                    _toggleFavourite();
                  },
                  child: _member!.isFavourite != null && _member!.isFavourite!
                      ? Icon(
                          Platform.isIOS
                              ? CupertinoIcons.heart_fill
                              : Icons.favorite_rounded,
                          color: kBaseFavouriteColour,
                          size: 32.0,
                        )
                      : Icon(
                          Platform.isIOS
                              ? CupertinoIcons.heart
                              : Icons.favorite_border_rounded,
                          color: kBaseFavouriteColour,
                          size: 32.0,
                        ),
                );
              }
            },
          ),
          FloatingActionButton(
            heroTag: null,
            shape: const CircleBorder(),
            onPressed: () async {
              _sendMessage();
            },
            child: Icon(
              Platform.isIOS
                  ? CupertinoIcons.text_bubble
                  : Icons.chat_bubble_outline_rounded,
              size: 32.0,
            ),
          ),
        ],
        height: 8.0,
      ),
    );
  }

  Future<void> _getMemberStatus() async {
    if (_isProcessingBlock) return;

    if (_member == null) return;

    if (_member!.id == _currentUser.id) return;

    if (_member!.isFavourite == null) {
      _member!.isFavourite =
          await _connectionService.getMemberFavouriteStatus(_member!.id);
    }
    if (mounted) _favouriteLoaded.value = true;

    if (_member!.isBlocked == null) {
      _member!.isBlocked = await _connectionService.getMemberBlockedStatus(
          _currentUser.id, _member!.id);
    }
    if (mounted) _isBlockedLoaded.value = true;

    if (mounted) {
      _matchInsightEnabled.value = _featureService.featureMatchInsight;
    }
  }

  Future<void> _sendMessage() async {
    try {
      if (await _messagingHandlerService.checkUserCanSendNewMessage()) {
        if (mounted &&
            restrictedMessagingUsersMap[_connectionService.serverUrl]!
                .contains(_currentUser.id)) {
          final createNewThread = await showConfirmDialog(
            context: context,
            title: 'Restricted User',
            content:
                'Your account can only send messages to an administrator.\n\nWould you like to proceed to message an administrator?',
            cancelText: 'Cancel',
            confirmText: 'Yes',
          );

          if (createNewThread) {
            final administratorUser =
                await _connectionService.getMember(userIdKunal);
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      NewMessageThreadView(recipient: administratorUser),
                ),
              );
            }
          }
        } else {
          // Check if a message thread already exists with this member, navigate
          // to it if it does otherwise create a new message thread.
          if (mounted) {
            LoadingIndicator().show(
              context: context,
            );
          }
          final currentMessageTheadId = await _messagingHandlerService
              .getLastMessageThreadId(_member!.id);
          if (mounted) {
            LoadingIndicator().hide();
          }

          bool createNewThread = false;

          if (currentMessageTheadId > 0) {
            if (mounted && DevelopmentService.arvo().isDevelopment) {
              createNewThread = await showConfirmDialog(
                context: context,
                title: 'Development',
                content:
                    'You already have an existing message thread with this member.\n\nWhat would you like to do?',
                cancelText: 'Use Existing',
                confirmText: 'Create New',
              );
            }
            if (mounted && !createNewThread) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MessageThreadView(messageThreadId: currentMessageTheadId),
                ),
              );
            }
          } else {
            createNewThread = true;
          }

          if (mounted && createNewThread) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewMessageThreadView(recipient: _member!),
              ),
            );
          }
        }
      } else {
        throw TooManyNewMessagesException(localisedErrorTooManyNewMessages);
      }
    } on Exception catch (e) {
      if (mounted) {
        LoadingIndicator().hide();
      }
      if (e is TooManyNewMessagesException) {
        if (mounted) {
          await showErrorDialog(context, title: e.title, text: e.message);
        }
      } else if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  Future<void> _toggleFavourite() async {
    if (mounted) _favouriteLoaded.value = false;

    try {
      var isFavourite = _member!.isFavourite!;
      if (isFavourite) {
        await _connectionService.removeFavouriteMember(_member!.id);
      } else {
        if (await _memberDirectoryService.checkUserCanAddFavourite()) {
          await _connectionService.addFavouriteMember(_member!.id);
          await _memberDirectoryService.updateFavouriteAddedTimestamp();
        } else {
          throw TooManyNewFavouritesException(
              localisedErrorTooManyNewFavourites);
        }
      }
      _member!.isFavourite = !isFavourite;
      _memberDirectoryService.updateMemberStatus(_member!);
      // Show snackbar.
      final snackBar = SnackBar(
          content: Text(_member!.isFavourite!
              ? "${_member!.name!} added to your favourites."
              : "${_member!.name!} removed from your favourites."),
          duration: const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } on Exception catch (e) {
      if (e is TooManyNewFavouritesException) {
        if (mounted) {
          await showErrorDialog(context, title: e.title, text: e.message);
        }
      } else if (mounted) {
        await processException(context: context, exception: e);
      }
    }

    if (mounted) _favouriteLoaded.value = true;
  }

  Future<void> _toggleBlocked() async {
    _isProcessingBlock = true;

    try {
      var isBlocked = _member!.isBlocked!;
      bool canContinue = false;

      if (!isBlocked) {
        if (await showConfirmDialog(
          context: context,
          content:
              'Block ${_member!.name}?\n\nYou can manage blocked members from the Settings page.',
          title: 'Confirm Block',
          confirmText: 'Yes',
          cancelText: 'Cancel',
        )) {
          canContinue = true;
        }
      } else {
        canContinue = true;
      }

      if (canContinue) {
        if (mounted) _isBlockedLoaded.value = false;
        isBlocked
            ? await _connectionService.unblockMember(_member!.id)
            : await _connectionService.blockMember(_member!.id);
        _member!.isBlocked = !isBlocked;
        _memberDirectoryService.updateMemberStatus(_member!);
        if (mounted) _isBlockedLoaded.value = true;
        // Show snackbar.
        final snackBar = SnackBar(
          content: Text(_member!.isBlocked!
              ? 'You have blocked ${_member!.name!}.'
              : 'You have unblocked ${_member!.name!}.'),
          duration: const Duration(seconds: 2),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }

    _isProcessingBlock = false;
  }

  Future _awaitReturnFromEditProfilePicturesView(BuildContext context) async {
    await navigateToEditProfilePicturesView(context, _connectionService,
        callback: () {
      if (mounted) {
        setState(
          () {
            _member = _connectionService.currentUser;
            _currentUser = _member!;
          },
        );
      }
    });
  }

  Future _awaitReturnFromEditProfileGroupView(
      BuildContext context, int groupId) async {
    // Navigate to view and wait for it to return.
    groupId == xProfileGroupPerfectMatchQuiz
        ? await Navigator.of(context).pushNamed(perfectMatchQuizRoute)
        : await Navigator.of(context)
            .pushNamed(editProfileGroupViewRoute, arguments: groupId);
    // Update this page on return.
    // Assign to _member (which is passed in via context) and _currentUser.
    if (context.mounted) {
      setState(
        () {
          _member = _connectionService.currentUser;
          _currentUser = _member!;
        },
      );
    }
  }

  Future _awaitReturnFromPhotoVerificationView(BuildContext context) async {
    // Navigate to view and wait for it to return.
    await Navigator.of(context).pushNamed(photoVerificationViewRoute);
    // Update this page on return.
    // Assign to _member (which is passed in via context) and _currentUser.
    if (context.mounted) {
      setState(
        () {
          _member = _connectionService.currentUser;
          _currentUser = _member!;
        },
      );
    }
  }

  /*void _toggleMatchInsight() {
    if (mounted) _matchInsightEnabled.value = !_matchInsightEnabled.value;
  }*/
}
