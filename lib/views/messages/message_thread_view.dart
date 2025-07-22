import 'dart:async';
import 'dart:io';

import 'package:app_base/dialogs/widget_information_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:arvo/views/shared/confirm_share_contact_information_dialog.dart';
import 'package:nifty_three_bp_app_base/constants/reporting.dart';
import 'package:arvo/constants/server.dart';
import 'package:arvo/constants/x_profile.dart';
import 'package:nifty_three_bp_app_base/enums/menu_action.dart';
import 'package:arvo/enums/tip_type.dart';
import 'package:nifty_three_bp_app_base/extensions/string.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/message_mark_read_unread_request.dart';
import 'package:nifty_three_bp_app_base/api/message_send_new_message_request.dart';
import 'package:nifty_three_bp_app_base/api/message_thread.dart';
import 'package:arvo/services/development/development_service.dart';
import 'package:arvo/services/features/feature_service.dart';
import 'package:arvo/services/messaging/messaging_handler_service.dart';
import 'package:arvo/services/push_notifications/push_notification_service.dart';
import 'package:arvo/services/tips/tip_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/member_reporting/report_member_view.dart';
import 'package:nifty_three_bp_app_base/views/widgets/circle_avatar.dart';
import 'package:arvo/views/shared/error_widget.dart';
import 'package:arvo/views/shared/member_profile_overlay.dart';
import 'package:nifty_three_bp_app_base/views/exceptions/messaging_exceptions.dart';
import 'package:intl/intl.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/extensions/string_extensions.dart';
import 'package:app_base/loading/loading_indicator.dart';
import 'package:app_base/loading/loading_screen.dart';
import 'package:percent_indicator/percent_indicator.dart';

class MessageThreadView extends StatefulWidget {
  final int? messageThreadId;
  final MessageThread? messageThread;
  final String? draft;

  const MessageThreadView(
      {this.messageThreadId, this.messageThread, this.draft, super.key});

  @override
  State<MessageThreadView> createState() => _MessageThreadViewState();
}

class _MessageThreadViewState extends State<MessageThreadView> {
  late final ConnectionService _connectionService;
  late final MessagingHandlerService _messagingHandlerService;
  late final PushNotificationService _pushNotificationService;
  late final FeatureService _featureService;
  late final DevelopmentService _developmentService;
  late int? _messageThreadId;
  late MessageThread? _messageThread;
  Member? _recipient;
  late final Member _currentUser;
  late final ScrollController _scrollController;
  late final TextEditingController _textMessageEditingController;
  late final FocusNode _messageFocusNode;
  late final GlobalKey<FormState> _formKey;
  bool _autoValidate = false;
  late final ValueNotifier<bool> _messageThreadLoaded;
  late final ValueNotifier<bool> _recipientLoaded;
  late final ValueNotifier<bool> _isBlockedLoaded;
  late final ValueNotifier<bool> _backToBottomButtonVisible;
  late final Future _future;
  bool _isProcessingMessageThread = false;
  int _latestMessageThreadId = 0;
  bool _latestMessageThreadOverride = false;
  Exception? _error;
  late final AppLifecycleListener _listener;
  bool _tooManyMessageRepliesInQueue = false;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _currentUser = _connectionService.currentUser!;
    _messageThreadId = widget.messageThreadId;
    _messageThread = widget.messageThread;
    _messagingHandlerService = MessagingHandlerService.arvo();
    _pushNotificationService = PushNotificationService.firebase();
    _featureService = FeatureService.arvo();
    _developmentService = DevelopmentService.arvo();
    _scrollController = ScrollController();
    _textMessageEditingController = TextEditingController();
    _messageFocusNode = FocusNode();
    if (widget.draft != null) {
      _textMessageEditingController.text = widget.draft!;
    }
    _formKey = GlobalKey<FormState>();
    _messageThreadLoaded = ValueNotifier(false);
    _recipientLoaded = ValueNotifier(false);
    _isBlockedLoaded = ValueNotifier(false);
    _backToBottomButtonVisible = ValueNotifier(false);
    // addPostFrameCallback runs after the page has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Show tip.
      TipService.arvo().showTipOverlay(context, TipType.tipMessageGuidelines);
    });
    // Initialize the AppLifecycleListener class and pass callbacks.
    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );
    _future = _getMessageThread();
  }

  @override
  void dispose() {
    // Unregister from push notification service.
    if (_messageThreadId != null) {
      _pushNotificationService.unregisterMessageThread(_messageThreadId!);
    }
    _scrollController.dispose();
    _textMessageEditingController.dispose();
    _messageFocusNode.dispose();
    _messageThreadLoaded.dispose();
    _recipientLoaded.dispose();
    _isBlockedLoaded.dispose();
    _backToBottomButtonVisible.dispose();
    _listener.dispose();
    super.dispose();
  }

  // Listen to the app lifecycle state changes.
  void _onStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.resumed:
        _processMessageThread(markRecipientActive: false);
        if (_recipient != null &&
            _recipient!.isBlocked != null &&
            !_recipient!.isBlocked!) {
          _messageFocusNode.requestFocus();
        }
      case AppLifecycleState.inactive:
        _messageFocusNode.unfocus();
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      //Back to top botton will show on scroll offset.
      if (mounted) {
        _backToBottomButtonVisible.value = _scrollController.offset > 10.0;
      }
    });

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
                Navigator.of(context).pop(_messageThread);
              },
              child: Scaffold(
                appBar: AppBar(
                  title: _buildAppBarWidget(),
                  titleSpacing: 0.0,
                  leadingWidth: 48.0,
                  leading: IconButton(
                    onPressed: () async {
                      Navigator.of(context).pop(_messageThread);
                    },
                    icon: Icon(
                      Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
                    ),
                  ),
                  actions: [
                    _buildPopUpMenuWidget(),
                  ],
                  toolbarHeight: 72.0,
                ),
                body: _messageThread != null
                    ? GestureDetector(
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: Column(
                          children: [
                            _buildMessagesListViewWidget(),
                            _buildMessageComposerWidget(),
                          ],
                        ),
                      )
                    : buildCenteredErrorWidget(
                        message:
                            'Sorry, this message thread could not be loaded.\n\nPress the back button to exit this page.'),
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

  Future<void> _getMessageThread() async {
    if (_recipient != null) return;

    if (_messageThreadId == null && _messageThread == null) {
      throw Exception('Invalid parameters.');
    }

    _messageThread ??=
        (await _connectionService.getMessageThread(_messageThreadId!))
            .firstOrNull;

    if (_messageThread == null) {
      throw Exception('Unable to load message thread.');
    }

    _messageThreadId ??= _messageThread!.id;

    _setMessageDateTimeVisibility(_messageThread!.messages);

    if (mounted) _messageThreadLoaded.value = true;

    // Don't await the next function so that this future returns and the message
    // thread is displayed to the user, while the rest of the data loads.
    _getMessageThreadStatus();
  }

  Future<void> _getMessageThreadStatus() async {
    try {
      // Register with push notification service for updates.
      _pushNotificationService.registerMessageThreadForUpdate(
          _messageThreadId!, _processMessageThread);

      // Mark this message thread as read and dismiss any notifications.
      if (_messageThread!.unreadCount > 0) {
        final messageMarkReadUnreadRequest = MessageMarkReadUnreadRequest(
          threadId: _messageThread!.id,
          userId: _currentUser.id,
          read: true,
          unread: false,
        );
        await _connectionService
            .markMessageThreadReadOrUnread(messageMarkReadUnreadRequest);
        _messageThread!.unreadCount = 0;
        _messagingHandlerService.refreshUnreadMessageCount();
      }

      // Note: The following will cause an exception if the recipient has blocked
      // the user (and if the user has not already been loaded into the member directory).
      final userId = _messageThread!.recipients
          .where((recipient) => recipient.userId != _currentUser.id)
          .first
          .userId;
      _recipient = await _messagingHandlerService.findOrFetchRecipient(userId);

      // If we are able to retrieve the recipient (which may happen if the
      // recipient already exists in the member directory even if they
      // have already blocked the user), then check for blocked by and
      // suspended and accordingly set the recipient to null if required.
      final isRecipientReachable =
          await _messagingHandlerService.checkRecipientIsReachable(_recipient!);

      if (!isRecipientReachable) {
        _recipient = null;
        throw InvalidUserException();
      }

      _latestMessageThreadId =
          await _messagingHandlerService.getLastMessageThreadId(_recipient!.id);

      if (mounted) _recipientLoaded.value = true;
      if (mounted) _isBlockedLoaded.value = true;
    } on Exception catch (e) {
      _error = e;
      if (mounted) {
        await processException(context: context, exception: e);
      }
      // Recipient is not reachable, but we can still display the message thread.
      if (e is InvalidUserException || e is DeletedUserException) {
        if (mounted) _recipientLoaded.value = true;
        if (mounted) _isBlockedLoaded.value = true;
      } else {
        // Clear the message thread since we could not load all the necessary data.
        if (mounted) _messageThreadLoaded.value = false;
        if (mounted) {
          setState(() {
            _messageThread = null;
          });
        }
      }
    }
  }

  Widget _buildFloatingButtonsWidget() {
    return ValueListenableBuilder(
      valueListenable: _backToBottomButtonVisible,
      builder: (context, value, child) {
        if (!value) {
          return const SizedBox.shrink();
        } else {
          return FloatingActionButton(
            heroTag: null,
            shape: const CircleBorder(),
            onPressed: () {
              _scrollController.animateTo(
                _scrollController.initialScrollOffset,
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn,
              );
            },
            child: Icon(
              Platform.isIOS
                  ? CupertinoIcons.arrow_down
                  : Icons.arrow_downward_rounded,
              size: 32.0,
            ),
          );
        }
      },
    );
  }

  Widget _buildAppBarWidget() {
    final mediaSize = MediaQuery.of(context).size;
    return ValueListenableBuilder(
      valueListenable: _recipientLoaded,
      builder: (context, value, child) {
        if (value) {
          return _recipient == null
              ? Text(
                  _processErrorRecipientTitle(),
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: setWidthBetweenWidgets(
                        [
                          buildCircleAvatarWithOnlineStatus(
                            _recipient!,
                            kBaseColour,
                            kBaseColour,
                            Theme.of(context).colorScheme.surface,
                            kBaseOnlineColour,
                            kBaseRecentlyOnlineColour,
                            kBaseVerifiedIndicatorColour,
                            showOnlineStatus:
                                _featureService.featureMemberOnlineIndicator,
                            callback: viewRecipientProfile,
                          ),
                          SizedBox(
                            width: mediaSize.width * 0.45,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _recipient!.name!,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _messageThread!.subject.raw!
                                      .removeEscapeCharacters()
                                      .parseHTML(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                )
                              ],
                            ),
                          ),
                        ],
                        width: 8.0,
                      ),
                    ),
                    SizedBox(
                      width: 32.0,
                      child: CircularPercentIndicator(
                        radius: 16.0,
                        lineWidth: 3.0,
                        backgroundColor: Colors.transparent,
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: getMatchPercentageColour(
                            _recipient!.matchWeight,
                            _featureService.featureMatchInsight),
                        animation: true,
                        animationDuration: 800,
                        percent: (_recipient!.matchWeight / 100).toDouble(),
                        center: Text(
                          '${_recipient!.matchWeight}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ],
                );
        } else {
          return ValueListenableBuilder(
            valueListenable: _messageThreadLoaded,
            builder: (context, value, child) {
              if (value) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: setWidthBetweenWidgets(
                        [
                          CircleAvatar(
                            backgroundColor: kBaseColour,
                            radius: 24.0,
                            backgroundImage: CachedNetworkImageProvider(
                                _connectionService.serverUrl! +
                                    defaultAvatarURL),
                          ),
                          SizedBox(
                            width: mediaSize.width * 0.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _messageThread!.recipients
                                          .where((recipient) =>
                                              recipient.userId !=
                                              _currentUser.id)
                                          .firstOrNull
                                          ?.name ??
                                      'User not available',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _messageThread!.subject.raw!
                                      .removeEscapeCharacters()
                                      .parseHTML(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                )
                              ],
                            ),
                          ),
                        ],
                        width: 8.0,
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          );
        }
      },
    );
  }

  String _processErrorRecipientTitle() {
    if (_error is InvalidUserException) {
      return (_error as InvalidUserException).title;
    }

    if (_error is DeletedUserException) {
      return (_error as DeletedUserException).title;
    }

    return 'Unable to load user';
  }

  Widget _buildPopUpMenuWidget() {
    return ValueListenableBuilder(
      valueListenable: _recipientLoaded,
      builder: (context, value, child) {
        if (value) {
          return _recipient == null
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
                              member: _recipient!,
                              category: reportCategoryMessageContent,
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
                        child: _recipient!.isBlocked!
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
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _toggleBlocked() async {
    if (mounted) _isBlockedLoaded.value = false;

    try {
      if (mounted) {
        LoadingIndicator().show(
          context: context,
        );
      }
      await _messagingHandlerService.toggleBlocked(_recipient!);
      if (mounted) {
        LoadingIndicator().hide();
      }
    } on Exception catch (e) {
      if (mounted) {
        LoadingIndicator().hide();
      }
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }

    if (mounted) _isBlockedLoaded.value = true;
  }

  Widget _buildMessagesListViewWidget() {
    return Expanded(
      child: Stack(
        children: [
          ListView.builder(
            reverse: true,
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 16.0),
            itemCount: _messageThread!.messages.length,
            itemBuilder: (context, index) {
              final reversedIndex = _messageThread!.messages.length - 1 - index;
              final Message message = _messageThread!.messages[reversedIndex];
              final bool isMe = message.senderId == _currentUser.id;
              return _buildMessageWidget(message, isMe);
            },
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: _buildFloatingButtonsWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWidget(Message message, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 4.0,
              bottom: 4.0,
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: setWidthBetweenWidgets(
                    width: 4.0,
                    [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            top: 8.0,
                            right: 16.0,
                            bottom: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Theme.of(context).colorScheme.primaryContainer
                                : kBaseMessageThreadRecievedMessageBackgroundColour,
                            borderRadius: isMe
                                ? const BorderRadius.only(
                                    topLeft: Radius.circular(16.0),
                                    bottomLeft: Radius.circular(16.0),
                                  )
                                : const BorderRadius.only(
                                    topRight: Radius.circular(16.0),
                                    bottomRight: Radius.circular(16.0),
                                  ),
                          ),
                          child: Text(
                            message.message.raw
                                .removeEscapeCharacters()
                                .parseHTML(),
                            style: isMe
                                ? Theme.of(context).textTheme.bodyLarge!
                                : Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      color: Colors.white,
                                    ),
                          ),
                        ),
                      ),
                      if (!isMe &&
                          message.message.raw
                              .removeEscapeCharacters()
                              .parseHTML()
                              .containsContactDetails()
                              .isNotEmpty)
                        SizedBox(
                          height: 32.0,
                          width: 32.0,
                          child: FloatingActionButton(
                            heroTag: null,
                            shape: const CircleBorder(),
                            onPressed: () async {
                              _confirmReportSharingContactInformation();
                            },
                            child: Icon(
                              Platform.isIOS
                                  ? CupertinoIcons.exclamationmark_triangle_fill
                                  : Icons.warning_rounded,
                              size: 18.0,
                            ),
                          ),
                        ),
                      if (!isMe &&
                          message.message.raw
                              .removeEscapeCharacters()
                              .parseHTML()
                              .containsUrlText()
                              .isNotEmpty)
                        SizedBox(
                          height: 32.0,
                          width: 32.0,
                          child: FloatingActionButton(
                            heroTag: null,
                            shape: const CircleBorder(),
                            onPressed: () async {
                              _notifySharingUrl();
                            },
                            child: Icon(
                              Platform.isIOS
                                  ? CupertinoIcons.info_circle_fill
                                  : Icons.info_rounded,
                              size: 18.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                message.isDateTimeVisible && message.dateSent != null
                    ? Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          _formatUtcMessageDateTimeForDisplay(
                              message.dateSent)!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: isMe ? TextAlign.end : TextAlign.start,
                        ),
                      )
                    : const SizedBox.shrink(),
                message.isSending
                    ? Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          'Sending...',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.end,
                        ),
                      )
                    : const SizedBox.shrink(),
                message.errorStatus != null
                    ? Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          // No need to check for IsMe because this section only applies
                          // to the user.
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              message.errorStatus!,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.end,
                            ),
                            _recipient == null
                                ? const SizedBox.shrink()
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: setWidthBetweenWidgets([
                                      FilledButton(
                                        onPressed: _isProcessingMessageThread
                                            ? null
                                            : () async {
                                                _processMessageThread(
                                                  markRecipientActive: false,
                                                  retryMessage: message,
                                                );
                                              },
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(64.0, 30.0),
                                        ),
                                        child: const Text(
                                          'Retry',
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: () async {
                                          _deleteUnsentMessage(message);
                                        },
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(64.0, 30.0),
                                          backgroundColor: kRedColour,
                                        ),
                                        child: const Text(
                                          'Delete',
                                        ),
                                      ),
                                    ], width: 4.0),
                                  ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageComposerWidget() {
    return ValueListenableBuilder(
      valueListenable: _messageThreadLoaded,
      builder: (context, value, child) {
        return ValueListenableBuilder(
          valueListenable: _isBlockedLoaded,
          builder: (context, value, child) {
            if (value) {
              return _recipient == null
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildMessageFormWidget(),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _recipient!.isBlocked!
                          ? Container(
                              padding: const EdgeInsets.all(8.0),
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
                              ),
                              child: Column(
                                children: setHeightBetweenWidgets(
                                  [
                                    Text(
                                      'You have blocked ${_recipient!.name}.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        _toggleBlocked();
                                      },
                                      child: Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: setWidthBetweenWidgets(
                                          [
                                            Icon(
                                              Platform.isIOS
                                                  ? CupertinoIcons
                                                      .lock_open_fill
                                                  : Icons.lock_open_rounded,
                                            ),
                                            const Text(
                                              'Unblock',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                          width: 8.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                  height: 8.0,
                                ),
                              ),
                            )
                          : _buildMessageFormWidget(),
                    );
            } else {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildMessageFormWidget(),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildMessageFormWidget() {
    return Form(
      key: _formKey,
      autovalidateMode: _autoValidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Container(
        padding: const EdgeInsets.all(8.0),
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
        ),
        child: TextFormField(
          style: Theme.of(context).textTheme.titleMedium,
          controller: _textMessageEditingController,
          focusNode: _messageFocusNode,
          keyboardType: TextInputType.multiline,
          maxLines: null, //Make the editor expand as lines are entered.
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
              labelText: 'Message',
              hintText: 'Type a message...',
              suffixIcon: _recipientLoaded.value
                  ? _recipient != null
                      ? IconButton(
                          icon: Icon(
                            Platform.isIOS
                                ? CupertinoIcons.paperplane_fill
                                : Icons.send_rounded,
                          ),
                          onPressed: () async {
                            _sendMessage();
                          },
                        )
                      : IconButton(
                          icon: Icon(
                            Platform.isIOS
                                ? CupertinoIcons.slash_circle
                                : Icons.block_rounded,
                          ),
                          onPressed: null,
                        )
                  : IconButton(
                      icon: Icon(
                        Platform.isIOS
                            ? CupertinoIcons.paperplane_fill
                            : Icons.send_rounded,
                      ),
                      onPressed: null,
                    )),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please type a message.';
            }
            return null;
          },
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    try {
      int outgoingMessageQueueCount = _messageThread!.messages
          .where((message) => message.uuid != null)
          .length;

      if (outgoingMessageQueueCount == 0) _tooManyMessageRepliesInQueue = false;

      if ((outgoingMessageQueueCount >=
              _messagingHandlerService.maxPendingMessageReplies) ||
          _tooManyMessageRepliesInQueue) {
        _tooManyMessageRepliesInQueue = true;
        throw TooManyMessageRepliesException(
            localisedErrorTooManyMessageReplies);
      }

      if (_formKey.currentState!.validate()) {
        bool redirectToLatestThread = false;
        if (_latestMessageThreadId != _messageThreadId &&
            !_latestMessageThreadOverride) {
          _developmentService.isDevelopment
              ? {
                  if (mounted)
                    {
                      redirectToLatestThread = await showConfirmDialog(
                        context: context,
                        title: 'Development',
                        content:
                            "A newer message thread exists.\n\nWould you like to switch to the latest thread?",
                        cancelText: 'No',
                        confirmText: 'Yes',
                      )
                    }
                }
              : {
                  if (mounted)
                    {
                      redirectToLatestThread = await showConfirmDialog(
                        context: context,
                        title: 'Newer Message Thread Exists',
                        content:
                            "You can't reply to this message thread because a newer message thread exists.\n\nWould you like to switch to the latest thread?",
                        cancelText: 'Cancel',
                        confirmText: 'Yes',
                      )
                    }
                };
        }

        if (redirectToLatestThread) {
          await _redirectToLatestThread();
        } else {
          // Return if not development and this is not the latest thread.
          if (!_developmentService.isDevelopment &&
              _latestMessageThreadId != _messageThreadId) {
            return;
          }
          // If development and we've reached this point, it means we
          // are overriding the latest message thread prompt.
          if (_developmentService.isDevelopment) {
            _latestMessageThreadOverride = true;
          }

          final contactDetails =
              _textMessageEditingController.text.containsContactDetails();
          if (contactDetails.isNotEmpty) {
            if (mounted &&
                !await confirmShareContactInformationDialog(context)) {
              return;
            }
          }

          if (_messageThread!.messages.length >=
                  _messagingHandlerService.messageCountLimitPerThread &&
              mounted) {
            final createNewThread = await showConfirmDialog(
              context: context,
              title: 'Message Limit Reached',
              content:
                  "You've reached the maximum number of messages allowed per message thread.\n\nWould you like to create a new message thread to continue messaging?",
              cancelText: 'Cancel',
              confirmText: 'Yes',
            );

            if (createNewThread) {
              await _createNewThreadAndRedirect();
            }
          } else {
            _messageThread!.messages.add(
              Message(
                id: -1,
                threadId: _messageThread!.id,
                senderId: _currentUser.id,
                subject: MessageContent(
                  raw: _messageThread!.subject.raw!,
                  rendered: _messageThread!.subject.rendered!,
                ),
                message: MessageContent(
                    raw: _textMessageEditingController.text == '0'
                        ? '0 '
                        : _textMessageEditingController.text,
                    rendered: _textMessageEditingController.text == '0'
                        ? '0 '
                        : _textMessageEditingController.text),
                // Generate a (time-based) unique id
                uuid: DateTime.now().microsecondsSinceEpoch,
              ),
            );
            if (mounted) {
              setState(() {
                _textMessageEditingController.clear();
                _autoValidate = false;
              });
            }
            // Check first if the user is still accessible.
            final isRecipientReachable = await _messagingHandlerService
                .checkRecipientIsReachable(_recipient!);

            if (!isRecipientReachable) {
              if (mounted) {
                await showErrorDialog(context,
                    title: 'Unable to send',
                    text:
                        '${_recipient!.name!} is not accepting messages right now, please try again later.');
                _recipient = null;
                if (mounted) _recipientLoaded.value = true;

                // Mark unsent messages as undelivered.
                List<Message> outgoingMessageQueue = _messageThread!.messages
                    .where((message) => message.uuid != null)
                    .toList();

                if (outgoingMessageQueue.isNotEmpty) {
                  for (final outgoingMessage in outgoingMessageQueue) {
                    outgoingMessage.errorStatus = 'Undelivered.';
                  }
                }
              }
            } else {
              await _processMessageThread(markRecipientActive: false);
            }
          }
        }
      } else {
        if (mounted) {
          setState(
            () {
              _autoValidate = true;
            },
          );
        }
      }
    } on Exception catch (e) {
      if (e is TooManyMessageRepliesException) {
        if (mounted) {
          await showErrorDialog(context, title: e.title, text: e.message);
        }
      } else if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  Future<void> _processMessageThread(
      {bool markRecipientActive = true, Message? retryMessage}) async {
    if (!mounted ||
        _messageThread == null ||
        _recipient == null ||
        _isProcessingMessageThread) return;

    _isProcessingMessageThread = true;

    bool sendError = false;

    // Extract list of messages that are waiting to be sent using the uuid property.
    List<Message> outgoingMessageQueue = _messageThread!.messages
        .where((message) => message.uuid != null)
        .toList();

    if (outgoingMessageQueue.isNotEmpty) {
      // There are messages to send.

      // Sort outgoing  messages based on uuid (i.e. time created).
      outgoingMessageQueue.sort((a, b) => b.uuid!.compareTo(a.uuid!));

      // Update message statuses.
      if (mounted) {
        setState(() {
          // When retrying an existing message, set error status to null so it's picked up
          // by the send process below.
          retryMessage?.errorStatus = null;
          for (final outgoingMessage in outgoingMessageQueue) {
            if (outgoingMessage.errorStatus == null) {
              outgoingMessage.isSending = true;
            }
          }
        });
      }

      // Send queued outgoing messages.
      for (int i = outgoingMessageQueue.length - 1; i >= 0; i--) {
        try {
          // Skip if message has not being marked for sending or has an error.
          if (!outgoingMessageQueue[i].isSending &&
              outgoingMessageQueue[i].errorStatus != null) continue;
          var newMessageRequest = MessageSendNewMessageRequest(
            id: _messageThread!.id,
            message: outgoingMessageQueue[i].message.raw,
            recipients: [_recipient!.id],
            senderId: _currentUser.id,
          );
          var sendResult =
              await _connectionService.sendNewMessage(newMessageRequest);
          if (sendResult.isNotEmpty) {
            // Update the sent message.
            var sentMessage = _messageThread!.messages
                .where(
                    (message) => message.uuid == outgoingMessageQueue[i].uuid)
                .firstOrNull;
            // Remove from the outgoing queue.
            outgoingMessageQueue.removeAt(i);
            // Extract any messages that are not in the local messages list.
            sendResult[0].messages.removeWhere((incomingMessage) =>
                _messageThread!.messages
                    .any((message) => message.id == incomingMessage.id));
            // Find sender's updated messages.
            var updatedMessages = sendResult[0]
                .messages
                .where((message) => message.senderId == _currentUser.id);
            if (sentMessage != null) {
              var replacementIndex =
                  _messageThread!.messages.indexOf(sentMessage);
              _messageThread!.messages.removeAt(replacementIndex);
              _messageThread!.messages.replaceRange(
                  replacementIndex, replacementIndex, updatedMessages);
            }
            // Find any new messages from the recipient.
            var incomingMessages = sendResult[0]
                .messages
                .where((message) => message.senderId != _currentUser.id);
            if (incomingMessages.isNotEmpty) {
              _messageThread!.messages.addAll(incomingMessages);
              // Mark the message thread as read, this will dismiss any notifications.
              final messageMarkReadUnreadRequest = MessageMarkReadUnreadRequest(
                threadId: _messageThread!.id,
                userId: _currentUser.id,
                read: true,
                unread: false,
              );
              await _connectionService
                  .markMessageThreadReadOrUnread(messageMarkReadUnreadRequest);
              _messageThread!.unreadCount = 0;
            }
            _messageThread!.lastSenderId = sendResult[0].lastSenderId;
            _messageThread!.excerpt = sendResult[0].excerpt;
            _messageThread!.dateGmt = sendResult[0].dateGmt;
          } else {
            sendError = true;
          }
        } on Exception catch (_) {
          sendError = true;
        }
      }
      // If there is a send error, update the status.
      if (sendError) {
        // Stop the message process timer since sending has failed.
        //_messageThreadRefreshTimer.cancel();

        for (final outgoingMessage in outgoingMessageQueue) {
          outgoingMessage.errorStatus = 'Unable to send.';
          outgoingMessage.isSending = false;
        }
      }
      // Set recipient loaded to refresh activity status.
      if (mounted) {
        _recipientLoaded.value = true;
        if (mounted) {
          setState(() {
            _setMessageDateTimeVisibility(_messageThread!.messages);
          });
        }
      }
    } else {
      // There are no messages to send, so just refresh the thread.
      final messageThread =
          (await _connectionService.getMessageThread(_messageThread!.id))[0];
      // Find any messages that are not in the local messages list.
      final List<Message> newMessages = [];
      for (final incomingMessage in messageThread.messages) {
        if (_messageThread!.messages
            .none((message) => message.id == incomingMessage.id)) {
          newMessages.add(incomingMessage);
        }
      }
      // Find any new messages from the recipient.
      var incomingMessages =
          newMessages.where((message) => message.senderId != _currentUser.id);
      if (incomingMessages.isNotEmpty) {
        // Mark the message thread as read, this will dismiss any notifications.
        final messageMarkReadUnreadRequest = MessageMarkReadUnreadRequest(
          threadId: _messageThread!.id,
          userId: _currentUser.id,
          read: true,
          unread: false,
        );
        await _connectionService
            .markMessageThreadReadOrUnread(messageMarkReadUnreadRequest);
        // Mark recipient as being active since they have just sent us a message.
        if (markRecipientActive) {
          _recipient!.lastActivityTimestamp = DateTime.now();
          if (mounted) _recipientLoaded.value = true;
        }
      }
      if (mounted) {
        // Extract any messages that may have been queued while this process was
        // running so they don't get erased by message thread assignment.
        final queued =
            _messageThread!.messages.where((message) => message.uuid != null);
        _messageThread = messageThread;
        // Re-add any queued messages.
        _messageThread!.messages.addAll(queued);
        if (mounted) {
          setState(() {
            _setMessageDateTimeVisibility(_messageThread!.messages);
          });
        }
      }
    }

    _isProcessingMessageThread = false;

    // Process again if there are still messages waiting in the queue.
    if (!sendError &&
        _messageThread!.messages
            .where((message) => message.uuid != null)
            .isNotEmpty) {
      _processMessageThread();
    }
  }

  void _deleteUnsentMessage(Message message) {
    if (mounted) {
      setState(() {
        _messageThread!.messages.remove(message);
      });
    }
  }

  String? _formatUtcMessageDateTimeForDisplay(String? dateUtc) {
    if (dateUtc == null) return null;

    final dateTimeLocal = DateTime.parse('${dateUtc}Z').toLocal();
    final now = DateTime.now();

    final dateToday = DateTime(now.year, now.month, now.day);
    final dateUtcDate =
        DateTime(dateTimeLocal.year, dateTimeLocal.month, dateTimeLocal.day);

    if (dateUtcDate == dateToday) {
      return DateFormat.jm().format(dateTimeLocal);
    }

    final difference = now.difference(dateTimeLocal).inDays;
    switch (difference) {
      case < 7:
        return '${DateFormat('EEEE').format(dateTimeLocal)} at ${DateFormat.jm().format(dateTimeLocal)}';
      default:
        return '${DateFormat('dd/MM/yy').format(dateTimeLocal)} at ${DateFormat.jm().format(dateTimeLocal)}';
    }
  }

  // Sets message date time visibility, if the next message is less than 5 minutes
  // old then set visibility to false.
  void _setMessageDateTimeVisibility(List<Message> messages) {
    void setDateTimeVisibility(List<Message> messages) {
      messages.sort((a, b) => a.id.compareTo(b.id));
      for (int i = 0; i < messages.length; i++) {
        final message = messages[i];

        // No need to process the last message.
        if (message == messages.last) return;

        final nextMessage = messages[i + 1];

        if (message.dateSent == null || nextMessage.dateSent == null) return;

        final dateTime =
            DateFormat("yyyy-MM-ddTHH:mm:ssZ").parse(message.dateSent!, true);
        final dateTimeNext = DateFormat("yyyy-MM-ddTHH:mm:ssZ")
            .parse(nextMessage.dateSent!, true);
        final difference = dateTimeNext.difference(dateTime).inMinutes;
        message.isDateTimeVisible = difference > 5;
      }
    }

    final incomingMessages = messages
        .where((message) => message.senderId != _currentUser.id)
        .toList();

    final outgoingMessages = messages
        .where((message) => message.senderId == _currentUser.id)
        .toList();

    setDateTimeVisibility(incomingMessages);
    setDateTimeVisibility(outgoingMessages);
  }

  void viewRecipientProfile() {
    MemberProfileOverlay().show(
      context: context,
      member: _recipient!,
      currentUser: _currentUser,
      matchInsight: _featureService.featureMatchInsight,
      hasFeatureMemberOnlineIndicator:
          _featureService.featureMemberOnlineIndicator,
    );
  }

  // Navigates to the latest thread.
  Future<void> _redirectToLatestThread() async {
    if (mounted) {
      LoadingScreen().show(
        context: context,
        text: 'Redirecting...',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MessageThreadView(
            messageThreadId: _latestMessageThreadId,
            draft: _textMessageEditingController.text,
          ),
        ),
      );
    }

    if (mounted) {
      LoadingScreen().hide();
    }
  }

  // Creates a new message thread using the parameters of the current thread,
  // and then navigates to it.
  Future<void> _createNewThreadAndRedirect() async {
    try {
      if (mounted) {
        LoadingScreen().show(
          context: context,
          text: 'Creating new thread...',
        );
      }
      var newMessageRequest = MessageSendNewMessageRequest(
        subject: _messageThread!.subject.raw!,
        // NOTE: The API is not being able to process messages which only contain a 0.
        message: _textMessageEditingController.text == '0'
            ? '0 '
            : _textMessageEditingController.text,
        recipients: [_recipient!.id],
        senderId: _currentUser.id,
      );
      var result = await _connectionService.sendNewMessage(newMessageRequest);
      if (mounted) {
        LoadingScreen().hide();
      }
      if (result.isNotEmpty) {
        // Message was sent successfully, navigate to message thread view.
        var messageThread = result[0];
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MessageThreadView(
                messageThread: messageThread,
              ),
            ),
          );
        }
      } else {
        // Couldn't send, ask user to try again later.
        if (mounted) {
          await showErrorDialog(context);
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

  Future<void> _confirmReportSharingContactInformation() async {
    if (await reportContactInformationDialog(context, _recipient!)) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportMemberView(
              member: _recipient!,
              category: reportCategoryMessageContent,
              description:
                  '${_recipient!.name} has messaged me unsolicited contact information.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _notifySharingUrl() async {
    await showWidgetInformationDialog(
      context: context,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: setHeightBetweenWidgets(
          height: 8.0,
          header: true,
          [
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.info_circle_fill
                  : Icons.info_rounded,
              size: 64.0,
            ),
            Text(
              '${_recipient!.name} may be trying to share a link with you.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Text(
              "Exercise caution when accessing unfamiliar external links.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
