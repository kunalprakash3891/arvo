import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:nifty_three_bp_app_base/constants/reporting.dart';
import 'package:arvo/constants/server.dart';
import 'package:nifty_three_bp_app_base/enums/menu_action.dart';
import 'package:nifty_three_bp_app_base/enums/member_directory_category.dart';
import 'package:arvo/enums/tip_type.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/ads/ad_service.dart';
import 'package:arvo/services/caching/member_directory_service.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/development/development_service.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/services/messaging/messaging_handler_service.dart';
import 'package:arvo/services/tips/tip_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/member_reporting/report_member_view.dart';
import 'package:arvo/views/messages/message_thread_view.dart';
import 'package:arvo/views/messages/new_message_thread_view.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:nifty_three_bp_app_base/views/arguments/member_swipe_args.dart';
import 'package:nifty_three_bp_app_base/views/exceptions/favourites_exceptions.dart';
import 'package:arvo/views/shared/member_profile_widget.dart';
import 'package:nifty_three_bp_app_base/views/exceptions/messaging_exceptions.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/generics/get_arguments.dart';
import 'package:app_base/loading/loading_indicator.dart';

class MemberSwipeView extends StatefulWidget {
  const MemberSwipeView({super.key});

  @override
  State<MemberSwipeView> createState() => _MemberSwipeViewState();
}

class _MemberSwipeViewState extends State<MemberSwipeView> {
  late final ConnectionService _connectionService;
  late final MemberDirectoryService _memberDirectoryService;
  late final MessagingHandlerService _messagingHandlerService;
  late final FeatureService _featureService;
  late final AdService _adService;
  Member? _member;
  late final Member _currentUser;
  MemberDirectoryCategory? _category;
  late List<Member> _members;
  late PageController _pageController;
  bool _isLastPage = false;
  int _currentPage = 1;
  late bool _isLoading = false;
  late bool _hasError = false;
  late final ValueNotifier<bool> _memberLoaded;
  late final ValueNotifier<bool> _favouriteLoaded;
  late final ValueNotifier<bool> _isBlockedLoaded;
  late final ValueNotifier<bool> _matchInsightEnabled;
  bool _isProcessingBlock = false;
  Member? _memberBeingProcessedForBlock;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _currentUser = _connectionService.currentUser!;
    _memberDirectoryService = MemberDirectoryService.arvo();
    _messagingHandlerService = MessagingHandlerService.arvo();
    _featureService = FeatureService.arvo();
    _adService = AdService.arvo();
    _memberLoaded = ValueNotifier(false);
    _favouriteLoaded = ValueNotifier(false);
    _isBlockedLoaded = ValueNotifier(false);
    _matchInsightEnabled = ValueNotifier(false);
    // addPostFrameCallback runs after the page has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Show tip.
      TipService.arvo().showTipOverlay(context, TipType.tipSwipe);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _memberLoaded.dispose();
    _favouriteLoaded.dispose();
    _isBlockedLoaded.dispose();
    _matchInsightEnabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Assign member if not already assigned otherwise member assignment by
    // setState will be lost.
    if (_member == null) {
      final memberSwipeArgs = context.getArgument<MemberSwipeArgs>();

      _member = memberSwipeArgs!.member;

      if (_member == null) throw Exception('Invalid member.');

      _category = memberSwipeArgs.category;

      if (_category == null) throw Exception('Invalid category.');

      switch (_category) {
        case MemberDirectoryCategory.myFavourites:
          {
            _members = _memberDirectoryService.favouriteMembers;
            _currentPage =
                _memberDirectoryService.favouriteMembersDirectory.keys.last + 1;
          }
        case MemberDirectoryCategory.favouritedMe:
          {
            _members = _memberDirectoryService.favouritedByMembers;
            _currentPage =
                _memberDirectoryService.favouritedByMembersDirectory.keys.last +
                    1;
          }
        case MemberDirectoryCategory.newest:
          {
            _members = _memberDirectoryService.newestMembers;
            _currentPage =
                _memberDirectoryService.newestMembersDirectory.keys.last + 1;
          }
        default:
          {
            _members = _memberDirectoryService.members;
            _currentPage =
                _memberDirectoryService.membersDirectory.keys.last + 1;
          }
      }

      _pageController = PageController(initialPage: _members.indexOf(_member!));
    }

    return FutureBuilder(
      // Note: CircularProgressIndicator is not needed here because buttons
      // are updated by values notifiers.
      future: _getMemberStatus(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildErrorScaffold(
            title: _member == null
                ? const SizedBox.shrink()
                : Text(
                    _member!.name!,
                    overflow: TextOverflow.ellipsis,
                  ),
            error: snapshot.error,
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: ValueListenableBuilder(
              valueListenable: _memberLoaded,
              builder: (context, value, child) {
                if (value) {
                  return _member == null
                      ? const SizedBox.shrink()
                      : Text(
                          _member!.name!,
                          overflow: TextOverflow.ellipsis,
                        );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            actions: [
              _buildPopupMenuWidget(),
            ],
          ),
          // Nested scaffold to allow snackbars to overlap floating buttons.
          body: Scaffold(
            floatingActionButton: _buildFloatingButtonWidget(),
            body: _buildSwipeWidget(),
          ),
        );
      },
    );
  }

  Widget _buildPopupMenuWidget() {
    return PopupMenuButton<MemberProfileMenuAction>(
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
    return Column(
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
                return _buildLoadingFloatingButtonWidget(kBaseColour);
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
                          color: kBaseColour,
                          size: 32.0,
                        )
                      : Icon(
                          Platform.isIOS
                              ? CupertinoIcons.heart
                              : Icons.favorite_border_rounded,
                          color: kBaseColour,
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
              color: kBaseColour,
              size: 32.0,
            ),
          ),
        ],
        height: 8.0,
      ),
    );
  }

  Future<void> _getMemberStatus() async {
    // Execute only if block is not in process or if the member in context has changed.
    if (_isProcessingBlock && _memberBeingProcessedForBlock == _member) return;

    if (_member == null) return;

    final member = _member!;

    if (mounted) _memberLoaded.value = true;

    member.isFavourite ??=
        await _connectionService.getMemberFavouriteStatus(member.id);
    // Set the value only if the member in context hasn't changed.
    if (mounted && member == _member) _favouriteLoaded.value = true;

    member.isBlocked ??= await _connectionService.getMemberBlockedStatus(
        _currentUser.id, member.id);
    // Set the value only if the member in context hasn't changed.
    if (mounted && member == _member) _isBlockedLoaded.value = true;

    if (mounted) {
      _matchInsightEnabled.value = _featureService.featureMatchInsight;
    }
  }

  Future<void> _toggleFavourite() async {
    final member = _member!;

    if (mounted) _favouriteLoaded.value = false;

    try {
      var isFavourite = member.isFavourite!;
      if (isFavourite) {
        await _connectionService.removeFavouriteMember(member.id);
      } else {
        if (await _memberDirectoryService.checkUserCanAddFavourite()) {
          await _connectionService.addFavouriteMember(member.id);
          await _memberDirectoryService.updateFavouriteAddedTimestamp();
        } else {
          throw TooManyNewFavouritesException(
              localisedErrorTooManyNewFavourites);
        }
      }
      member.isFavourite = !isFavourite;
      _memberDirectoryService.updateMemberStatus(member);
      // Show snackbar.
      final snackBar = SnackBar(
          content: Text(member.isFavourite!
              ? "${member.name!} added to your favourites."
              : "${member.name!} removed from your favourites."),
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
    // Set the value only if the member in context hasn't changed.
    if (mounted && member == _member) _favouriteLoaded.value = true;
  }

  Future<void> _toggleBlocked() async {
    // NOTE: _isProcessingBlock is used to prevent _getMemberStatus from
    // executing since the pop-up menu will cause a setState.
    _isProcessingBlock = true;

    final member = _member!;

    try {
      var isBlocked = member.isBlocked!;
      bool canContinue = false;

      if (!isBlocked) {
        if (await showConfirmDialog(
          context: context,
          content:
              'Block ${member.name}?\n\nYou can manage blocked members from the Settings page.',
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
        _memberBeingProcessedForBlock = member;
        if (mounted) _isBlockedLoaded.value = false;
        isBlocked
            ? await _connectionService.unblockMember(member.id)
            : await _connectionService.blockMember(member.id);
        member.isBlocked = !isBlocked;
        _memberDirectoryService.updateMemberStatus(member);
        if (mounted && member == _member) _isBlockedLoaded.value = true;
        // Show snackbar.
        final snackBar = SnackBar(
          content: Text(member.isBlocked!
              ? 'You have blocked ${member.name!}.'
              : 'You have unblocked ${member.name!}.'),
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

  Future<void> _getMembers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _error = null;
        });
      }

      List<Member> members = [];
      switch (_category) {
        case MemberDirectoryCategory.myFavourites:
          {
            members =
                await _memberDirectoryService.getFavouriteMembers(_currentPage);
          }
        case MemberDirectoryCategory.favouritedMe:
          {
            members = await _memberDirectoryService
                .getFavouritedByMembers(_currentPage);
          }
        case MemberDirectoryCategory.newest:
          {
            members =
                await _memberDirectoryService.getNewestMembers(_currentPage);
          }
        default:
          {
            members = await _memberDirectoryService.getMembers(_currentPage);
          }
      }
      if (mounted) {
        setState(
          () {
            _isLastPage =
                members.length < _memberDirectoryService.membersPerPage;
            _isLoading = false;
            _currentPage++;
            _members.addAll(members);
          },
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(
          () {
            _isLoading = false;
            _hasError = true;
            _error = e;
          },
        );
      }
    }
  }

  Widget _buildSwipeWidget() {
    if (_hasError) {
      return Center(
        child: _errorNotificationWidget(error: _error, size: 24.0),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) async {
            try {
              _adService.showAd(context);
              _member = _members[index];
              // Clear value notifiers so they get loaded again.
              if (mounted) _memberLoaded.value = false;
              if (mounted) _favouriteLoaded.value = false;
              if (mounted) _isBlockedLoaded.value = false;
              // NOTE: _getMemberStatus is not awaited because it needs
              // to execute on every swipe for the member in context.
              _getMemberStatus(); // Don't await.
              // Fetch the next page.
              if (index + 1 == _members.length && !_isLastPage) {
                _getMembers();
              }
            } on Exception catch (e) {
              if (mounted) {
                await processException(context: context, exception: e);
              }
            }
          },
          itemBuilder: (context, index) {
            return ValueListenableBuilder(
              valueListenable: _matchInsightEnabled,
              builder: (context, value, child) {
                return MemberProfileWidget(
                  member: _members[index],
                  currentUser: _currentUser,
                  // TODO: Implement premium promotion for Match Insight
                  //toggleMatchInsight: _toggleMatchInsight,
                  matchInsight: value,
                  hasFeatureMemberOnlineIndicator:
                      _featureService.featureMemberOnlineIndicator,
                );
              },
            );
          },
          itemCount: _members.length,
        ),
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : const SizedBox.shrink()
      ],
    );
  }

  Widget _errorNotificationWidget({Object? error, required double size}) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: setHeightBetweenWidgets(
          [
            Text(
              'An error occurred while fetching results.',
              style: TextStyle(fontSize: size, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            error == null
                ? const SizedBox.shrink()
                : Text(
                    processExceptionMessage(error),
                    textAlign: TextAlign.center,
                  ),
            TextButton(
              onPressed: () async {
                _getMembers();
              },
              child: const Text(
                "Retry",
                style: TextStyle(fontSize: 24.0, color: kBaseColour),
              ),
            ),
          ],
          height: 8.0,
        ),
      ),
    );
  }

  /*void _toggleMatchInsight() {
    if (mounted) _matchInsightEnabled.value = !_matchInsightEnabled.value;
  }*/
}
