import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:arvo/constants/localised_text.dart';
import 'package:nifty_three_bp_app_base/enums/menu_action.dart';
import 'package:nifty_three_bp_app_base/enums/message_filter_type.dart';
import 'package:nifty_three_bp_app_base/extensions/string.dart';
import 'package:arvo/helpers/error_handling/exception_processing.dart';
import 'package:arvo/services/ads/ad_service.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_service.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/message_delete_thread_request.dart';
import 'package:nifty_three_bp_app_base/api/message_mark_read_unread_request.dart';
import 'package:nifty_three_bp_app_base/api/message_star_unstar_request.dart';
import 'package:nifty_three_bp_app_base/api/message_thread.dart';
import 'package:nifty_three_bp_app_base/api/messages_get_request.dart';
import 'package:arvo/services/messaging/messaging_handler_service.dart';
import 'package:arvo/services/push_notifications/push_notification_service.dart';
import 'package:arvo/theme/palette.dart';
import 'package:app_base/utilities/widget_utilities.dart';
import 'package:arvo/views/messages/message_thread_view.dart';
import 'package:intl/intl.dart';
import 'package:app_base/dialogs/confirm_dialog.dart';
import 'package:app_base/dialogs/error_dialog.dart';
import 'package:app_base/extensions/string_extensions.dart';
import 'package:app_base/loading/loading_indicator.dart';
import 'package:app_base/widgets/back_to_top_widget.dart';
import 'package:uuid/uuid.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  late final ConnectionService _connectionService;
  late final MessagingHandlerService _messagingHandlerService;
  late final PushNotificationService _pushNotificationService;
  late final Member _currentUser;
  late final List<MessageThread> _messageThreads;
  final int _messageThreadsPerMessageBoxPage = 25;
  int _currentMessageBoxPage = 1;
  bool _isLastPage = false;
  bool _isShowingFilter = false;
  late final List<MessageThread> _selectedMessageThreads;
  bool _selectionMode = false;
  late bool _isLoading;
  late bool _hasError;
  Object? _error;
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _backToTopButtonVisible;
  late final ValueNotifier<int> _messageStarred;
  late final TextEditingController _textSearchKeyController;
  MessageBoxMenuAction _currentMessageBox = MessageBoxMenuAction.inbox;
  final Map<MessageBoxMenuAction, String> messageBoxMap = {
    MessageBoxMenuAction.inbox: "Inbox",
    MessageBoxMenuAction.starred: "Starred",
    MessageBoxMenuAction.sent: "Sent",
  };
  MessageFilterType _currentMessageFilterType = MessageFilterType.all;
  final Map<MessageFilterType, String> messageFilterTypeMap = {
    MessageFilterType.all: "All",
    MessageFilterType.read: "Read",
    MessageFilterType.unread: "Unread",
  };
  late String _uuid;
  late final AppLifecycleListener _listener;
  bool _refreshOnScrollTopTop = false;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionService.arvo();
    _currentUser = _connectionService.currentUser!;
    _messagingHandlerService = MessagingHandlerService.arvo();
    _pushNotificationService = PushNotificationService.firebase();
    _uuid = const Uuid().v1();
    _pushNotificationService.registerFunctionForUpdate(
        _uuid, _refreshOnNotification);
    _messageThreads = [];
    _selectedMessageThreads = [];
    _scrollController = ScrollController();
    _backToTopButtonVisible = ValueNotifier(false);
    _messageStarred = ValueNotifier(-1);
    _textSearchKeyController = TextEditingController();
    // Initialize the AppLifecycleListener class and pass callbacks.
    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );
    _getMessages();
  }

  @override
  void dispose() {
    _pushNotificationService.unregisterFunction(_uuid);
    _scrollController.dispose();
    _backToTopButtonVisible.dispose();
    _messageStarred.dispose();
    _textSearchKeyController.dispose();
    _listener.dispose();
    super.dispose();
  }

  // Listen to the app lifecycle state changes.
  void _onStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.resumed:
        _refreshOnNotification();
      case AppLifecycleState.inactive:
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
        _backToTopButtonVisible.value = _scrollController.offset > 10.0;
      }

      if (_isLoading || _isLastPage) return;
      // nextPageTrigger will have a value equivalent to 80% of the list size.
      var nextPageTrigger = 0.8 * _scrollController.position.maxScrollExtent;

      // _scrollController fetches the next paginated data when the current postion of the user on the screen has surpassed
      if (_scrollController.position.pixels > nextPageTrigger) {
        _getMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitleWidget(),
        actions: _buildAppBarActionWidget(),
        leading: _buildAppBarLeadingWidget(),
        // 56.0 is the default leadingWidth.
        leadingWidth: _isShowingFilter || _selectionMode ? 56.0 : 0.0,
        // 56.0 is the default toolbarHeight.
        toolbarHeight: 72.0,
      ),
      body: _buildMessageThreadsWidget(),
      floatingActionButton: buildBackToTopFloatingButtonWidget(
        _backToTopButtonVisible,
        _scrollController,
        scrollToTopCompletedCallback: _onScrollToTopCompleted,
      ),
    );
  }

  Widget _buildAppBarTitleWidget() {
    if (_selectionMode) {
      return Text('${_selectedMessageThreads.length} selected');
    } else if (_isShowingFilter) {
      return const Text('Filter');
    } else {
      return _buildMessageBoxDropdownWidget();
    }
  }

  bool _hasFilterApplied() {
    return _currentMessageFilterType != MessageFilterType.all ||
        _textSearchKeyController.text.isNotEmpty;
  }

  void _clearFilter() {
    if (_hasFilterApplied()) {
      if (mounted) {
        setState(
          () {
            _currentMessageFilterType = MessageFilterType.all;
            _textSearchKeyController.clear();
          },
        );
      }
      _onRefresh();
    }
  }

  List<Widget> _buildAppBarActionWidget() {
    List<Widget> widgets = [];
    if (_selectionMode) {
      widgets.add(
        IconButton(
          onPressed: () async {
            _deleteSelectedMessageThreads();
          },
          icon: Icon(Platform.isIOS
              ? CupertinoIcons.delete_solid
              : Icons.delete_rounded),
        ),
      );
      widgets.add(_buildSelectedMessagesPopupMenuWidget());
    } else if (_isShowingFilter) {
      widgets.add(
        TextButton(
          onPressed: () {
            _clearFilter();
          },
          child: const Text(
            'Clear',
          ),
        ),
      );
    } else {
      widgets.add(
        IconButton(
          onPressed: () {
            if (mounted) {
              setState(() {
                _isShowingFilter = true;
              });
            }
          },
          icon: Icon(Platform.isIOS
              ? CupertinoIcons.slider_horizontal_3
              : Icons.tune_rounded),
        ),
      );
    }
    return widgets;
  }

  Widget _buildAppBarLeadingWidget() {
    if (_selectionMode) {
      return IconButton(
        onPressed: () {
          if (mounted) {
            setState(() {
              _selectionMode = false;
              _clearSelection();
            });
          }
        },
        icon: Icon(
          Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
        ),
      );
    } else if (_isShowingFilter) {
      return IconButton(
        onPressed: () {
          _clearFilter();
          if (mounted) {
            setState(() {
              _isShowingFilter = false;
            });
          }
        },
        icon: Icon(
          Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMessageBoxDropdownWidget() {
    return DropdownButtonFormField<MessageBoxMenuAction>(
      items: messageBoxMap
          .map((value, description) {
            return MapEntry(
              description,
              DropdownMenuItem<MessageBoxMenuAction>(
                value: value,
                child: Text(description),
              ),
            );
          })
          .values
          .toList(),
      value: _currentMessageBox,
      onChanged: (MessageBoxMenuAction? newValue) {
        if (newValue != null) {
          _onMessageBoxMenuItemTapped(newValue);
        }
      },
    );
  }

  Widget _buildFilterWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: setHeightBetweenWidgets(
          [
            DropdownButtonFormField<MessageFilterType>(
              items: messageFilterTypeMap
                  .map((value, description) {
                    return MapEntry(
                      description,
                      DropdownMenuItem<MessageFilterType>(
                        value: value,
                        child: Text(description),
                      ),
                    );
                  })
                  .values
                  .toList(),
              value: _currentMessageFilterType,
              onChanged: (MessageFilterType? newValue) {
                if (newValue != null) {
                  if (mounted) {
                    setState(() {
                      _currentMessageFilterType = newValue;
                    });
                  }
                }
              },
            ),
            TextFormField(
              style: Theme.of(context).textTheme.titleMedium,
              controller: _textSearchKeyController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: 'Keywords',
              ),
              onFieldSubmitted: (value) async {
                FocusScope.of(context).unfocus();
                _onRefresh();
              },
            ),
            ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus();
                _onRefresh();
              },
              child: const Text(
                'Apply',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          height: 8.0,
        ),
      ),
    );
  }

  Widget _buildSelectedMessagesPopupMenuWidget() {
    return PopupMenuButton<MessageSelectionMenuAction>(
      onSelected: (value) async {
        switch (value) {
          case MessageSelectionMenuAction.markRead:
            _markSelectedMessageThreadsAsReadUnread(true, false);
            break;
          case MessageSelectionMenuAction.markUnread:
            _markSelectedMessageThreadsAsReadUnread(false, true);
            break;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem<MessageSelectionMenuAction>(
            value: MessageSelectionMenuAction.markRead,
            child: Text('Mark as read'),
          ),
          const PopupMenuItem<MessageSelectionMenuAction>(
            value: MessageSelectionMenuAction.markUnread,
            child: Text('Mark as unread'),
          ),
        ];
      },
    );
  }

  // Refresh when new message notification is received, but
  // only if the user is in the inbox, is not filtering or in selection mode and
  // is at the top of the list.
  Future<void> _refreshOnNotification() async {
    if (mounted) {
      if (_currentMessageBox == MessageBoxMenuAction.inbox &&
          !_isShowingFilter &&
          !_selectionMode &&
          _scrollController.offset == 0.0) {
        await _onRefresh();
      } else {
        _refreshOnScrollTopTop = true;
      }
    }
  }

  Future<void> _onScrollToTopCompleted() async {
    if (_refreshOnScrollTopTop) {
      await _refreshOnNotification();
    }
  }

  Future<void> _onRefresh() async {
    _refreshOnScrollTopTop = false;
    _messageThreads.clear();
    _currentMessageBoxPage = 1;
    if (mounted) _backToTopButtonVisible.value = false;
    await _getMessages();
  }

  Future<void> _getMessages() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _error = null;
        });
      }

      String box;

      switch (_currentMessageBox) {
        case MessageBoxMenuAction.inbox:
          {
            box = 'inbox';
          }
        case MessageBoxMenuAction.starred:
          {
            box = 'starred';
          }
        case MessageBoxMenuAction.sent:
          {
            box = 'sentbox';
          }
      }

      int messagesPageNumber = 1;

      var messagesGetRequest = MessagesGetRequest(
          userId: _currentUser.id,
          page: _currentMessageBoxPage,
          perPage: _messageThreadsPerMessageBoxPage,
          box: box,
          // Note: The API does not return correctly when searching using
          // a member's name.
          messagesPage: messagesPageNumber,
          messagesPerPage: 10,
          type: _isShowingFilter ? _currentMessageFilterType.name : 'all',
          searchKey: _isShowingFilter ? _textSearchKeyController.text : '');

      var messageThreads =
          await ConnectionService.arvo().getMessages(messagesGetRequest);

      // Update unread messages badge count.
      _messagingHandlerService.refreshUnreadMessageCount();
      if (mounted) {
        setState(
          () {
            _isLastPage =
                messageThreads.length < _messageThreadsPerMessageBoxPage;
            _isLoading = false;
            _currentMessageBoxPage++;
            if (_currentMessageBox == MessageBoxMenuAction.starred) {
              messageThreads.removeWhere(
                  (messageThread) => messageThread.starredMessageIds.isEmpty);
            }
            for (final messageThread in messageThreads) {
              // Add the message thread if it doesn't already exist. This is here
              // because the API may return a message thread already exists locally
              // after a delete operation.
              if (!_messageThreads.any((existingMessageThread) =>
                  existingMessageThread.id == messageThread.id)) {
                _messageThreads.add(messageThread);
              }
            }
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
      // Process GenericUserAccessException in case a forced log out is required.
      if (_error is GenericUserAccessException && mounted) {
        await processException(
            context: context, exception: _error as GenericUserAccessException);
      }
    }
  }

  Widget _buildMessageThreadsWidget() {
    if (_messageThreads.isEmpty) {
      if (_isLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        );
      } else if (_hasError) {
        return Center(
          child: _errorNotificationWidget(error: _error, size: 24.0),
        );
      }
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      notificationPredicate:
          (!_isShowingFilter && !_selectionMode) ? (_) => true : (_) => false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _isShowingFilter ? _buildFilterWidget() : const SizedBox.shrink(),
            _messageThreads.isEmpty
                ? Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: setHeightBetweenWidgets(
                            [
                              Text(
                                _isShowingFilter
                                    ? noResults
                                    : 'No messages to display...yet.',
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              _isShowingFilter
                                  ? const SizedBox.shrink()
                                  : OutlinedButton(
                                      onPressed: _onRefresh,
                                      child: const Text(
                                        'Refresh',
                                      ),
                                    ),
                            ],
                            height: 16.0,
                          ),
                        ),
                      ),
                    ),
                  )
                : Expanded(
                    child: MasonryGridView.count(
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      physics: const AlwaysScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 1,
                      mainAxisSpacing: 8.0,
                      // Add padding to bottom to prevent back top top button from
                      // covering the last item.
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        top: 8.0,
                        right: 8.0,
                        bottom: 96.0,
                      ),
                      itemCount: _messageThreads.length + (_isLastPage ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index == _messageThreads.length) {
                          if (_hasError) {
                            return Center(
                              child: _errorNotificationWidget(
                                  error: _error, size: 16.0),
                            );
                          } else {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                        }
                        return GestureDetector(
                          onLongPress: () {
                            _toggleSelection(_messageThreads.elementAt(index));
                          },
                          child: _messageThreads.isNotEmpty
                              ? _buildMessageThreadGridWidget(
                                  messageThread:
                                      _messageThreads.elementAt(index),
                                  lastItem: index == _messageThreads.length - 1
                                      ? true
                                      : false,
                                )
                              : const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(MessageThread messageThread) {
    if (mounted) {
      setState(() {
        _selectionMode = !_selectionMode;
        if (_selectionMode) {
          messageThread.selected = true;
          _addRemoveMessageThreadToSelection(messageThread);
        } else {
          _clearSelection();
        }
      });
    }
  }

  Widget _errorNotificationWidget({Object? error, required double size}) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: setHeightBetweenWidgets(
          [
            Text(
              'An error occurred while fetching results.',
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            error == null
                ? const SizedBox.shrink()
                : Text(
                    processExceptionMessage(error),
                    textAlign: TextAlign.center,
                  ),
            TextButton(
              onPressed: () {
                if (mounted) {
                  setState(
                    () {
                      _getMessages();
                    },
                  );
                }
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

  Widget _buildMessageThreadGridWidget(
      {required MessageThread messageThread, required bool lastItem}) {
    final mediaSize = MediaQuery.of(context).size;
    final recipient = messageThread.recipients
        .where((recipient) => recipient.userId != _currentUser.id)
        .firstOrNull;
    return GestureDetector(
      onTap: () async {
        _selectionMode
            ? {
                if (mounted)
                  {
                    setState(() {
                      messageThread.selected = !messageThread.selected;
                      _addRemoveMessageThreadToSelection(messageThread);
                    })
                  }
              }
            : _awaitReturnMessageThreadView(context, messageThread.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          border: _selectionMode
              ? Border.all(
                  width: 3.0,
                  color: messageThread.selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface)
              : Border.all(
                  width: 3.0,
                  color: messageThread.unreadCount > 0
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.circular(8.0),
          color: messageThread.unreadCount > 0
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5.0,
              spreadRadius: 1.0,
              offset: const Offset(1.0, 1.0),
            ),
          ],
        ),
        child: recipient == null
            ? Center(
                child: Column(
                children: [
                  Icon(
                    Platform.isIOS
                        ? CupertinoIcons.exclamationmark_circle_fill
                        : Icons.error,
                    size: 32.0,
                  ),
                  const Text('This message thread has an invalid recipient.'),
                ],
              ))
            : Column(
                children: setHeightBetweenWidgets(
                  [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: setWidthBetweenWidgets(
                            [
                              CircleAvatar(
                                radius: 32.0,
                                backgroundImage: CachedNetworkImageProvider(
                                    recipient.avatar.thumb!),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: setHeightBetweenWidgets(
                                  [
                                    SizedBox(
                                      width: mediaSize.width * 0.45,
                                      child: Text(
                                        // NOTE: Is it correct to assume that
                                        // an empty name indicates a deleted user?
                                        recipient.name.trim().isEmpty
                                            ? 'Deleted User'
                                            : recipient.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: mediaSize.width * 0.45,
                                      child: Text(
                                        messageThread.subject.raw!
                                            .removeEscapeCharacters()
                                            .parseHTML(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                        maxLines: 5,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  height: 8.0,
                                ),
                              )
                            ],
                            width: 8.0,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatUtcMessageDateTimeForDisplay(
                                  messageThread.dateGmt),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(
                              height: 8.0,
                            ),
                            messageThread.unreadCount > 0
                                ? Container(
                                    width: 72.0,
                                    height: 20.0,
                                    decoration: BoxDecoration(
                                        color: kBaseLightColour,
                                        borderRadius:
                                            BorderRadius.circular(8.0)),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'NEW (${messageThread.unreadCount})',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold),
                                    ))
                                : const Text(''), // SizedBox.shrink(),
                          ],
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              messageThread.lastSenderId == _currentUser.id
                                  ? 'You: '
                                  : '${
                                  // NOTE: Is it correct to assume that
                                  // an empty name indicates a deleted user?
                                  recipient.name.trim().isEmpty ? 'Deleted User' : recipient.name}: ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(
                              width: mediaSize.width * 0.4,
                              child: Text(
                                messageThread.excerpt.raw!
                                    .removeEscapeCharacters()
                                    .parseHTML(),
                                style: Theme.of(context).textTheme.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        _selectionMode
                            ? SizedBox(
                                height: 32.0,
                                width: 32.0,
                                child: Checkbox(
                                  value: messageThread.selected,
                                  onChanged: (value) {
                                    if (mounted) {
                                      setState(() {
                                        messageThread.selected = value!;
                                        _addRemoveMessageThreadToSelection(
                                            messageThread);
                                      });
                                    }
                                  },
                                ),
                              )
                            : ValueListenableBuilder(
                                valueListenable: _messageStarred,
                                builder: (context, value, child) {
                                  return SizedBox(
                                    height: 32.0,
                                    width: 32.0,
                                    child: Center(
                                      child: value == messageThread.id
                                          ? const CircularProgressIndicator(
                                              color: kBaseStarredMessageColour,
                                            )
                                          : IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                _starOrUnstarMessageThread(
                                                    messageThread);
                                              },
                                              icon: messageThread
                                                      .starredMessageIds
                                                      .isNotEmpty
                                                  ? Icon(
                                                      Platform.isIOS
                                                          ? CupertinoIcons
                                                              .star_fill
                                                          : Icons.star_rounded,
                                                      color:
                                                          kBaseStarredMessageColour,
                                                      size: 32.0,
                                                    )
                                                  : Icon(
                                                      Platform.isIOS
                                                          ? CupertinoIcons.star
                                                          : Icons
                                                              .star_border_rounded,
                                                      color:
                                                          kBaseStarredMessageColour,
                                                      size: 32.0,
                                                    ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ],
                  height: 8.0,
                ),
              ),
      ),
    );
  }

  void _awaitReturnMessageThreadView(
      BuildContext context, int messageThreadId) async {
    AdService.arvo().showAd(context);
    // Navigate to view and wait for it to return.
    await Navigator.push(
      context,
      MaterialPageRoute(
        // NOTE: Not passing the thread here directly because it may not contain
        // all of the messages for the entire thread.
        builder: (_) => MessageThreadView(
          messageThreadId: messageThreadId,
        ),
      ),
    ).then(
      // Update the message thread if it exists in the list.
      (returnedMessageThread) {
        if (returnedMessageThread is MessageThread) {
          final existingMessageThreadIndex = _messageThreads.indexWhere(
              (messageThread) => messageThread.id == returnedMessageThread.id);

          if (existingMessageThreadIndex > -1) {
            _messageThreads[existingMessageThreadIndex] = returnedMessageThread;
          }
        }
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _addRemoveMessageThreadToSelection(MessageThread messageThread) {
    if (messageThread.selected) {
      if (!_selectedMessageThreads.contains(messageThread)) {
        _selectedMessageThreads.add(messageThread);
      }
    } else {
      if (_selectedMessageThreads.contains(messageThread)) {
        _selectedMessageThreads.remove(messageThread);
      }
    }
  }

  void _clearSelection() {
    for (final selectedMessageThread in _selectedMessageThreads) {
      selectedMessageThread.selected = false;
    }
    _selectedMessageThreads.clear();
  }

  String _formatUtcMessageDateTimeForDisplay(String dateUtc) {
    final dateTimeLocal = DateTime.parse('${dateUtc}Z').toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTimeLocal).inDays;
    switch (difference) {
      case < 1:
        return DateFormat.jm().format(dateTimeLocal);
      case < 7:
        return DateFormat('EEEE').format(dateTimeLocal);
      case < 365:
        return DateFormat('d MMM').format(dateTimeLocal);
      default:
        return DateFormat('dd/MM/yy').format(dateTimeLocal);
    }
  }

  Future<void> _starOrUnstarMessageThread(MessageThread messageThread) async {
    // If no messages are starred, star the first one, otherwise unstar all
    // starred messages.
    bool success = false;

    try {
      if (mounted) _messageStarred.value = messageThread.id;

      if (messageThread.starredMessageIds.isEmpty) {
        final messageId = messageThread.messages.first.id;
        final messageStarUnstarRequest =
            MessageStarUnstarRequest(id: messageId);
        final result = await _connectionService
            .starOrUnstarMessage(messageStarUnstarRequest);
        if (result.first.isStarred) {
          messageThread.messages.first.isStarred = true;
          messageThread.starredMessageIds.add(messageId);
        }
        success = true;
      } else {
        for (int i = messageThread.starredMessageIds.length - 1; i >= 0; i--) {
          final messageId = messageThread.starredMessageIds[i];
          final messageStarUnstarRequest =
              MessageStarUnstarRequest(id: messageId);
          final result = await _connectionService
              .starOrUnstarMessage(messageStarUnstarRequest);
          success = !result.first.isStarred;
          if (success) {
            final message = messageThread.messages
                .where((message) => message.id == messageId)
                .firstOrNull;
            if (message != null) {
              message.isStarred = false;
            }
            messageThread.starredMessageIds.removeAt(i);
          } else {
            break;
          }
        }
      }

      if (success) {
        if (mounted) {
          setState(() {});
        }
      } else {
        if (mounted) {
          await showErrorDialog(context);
        }
      }
      if (mounted) _messageStarred.value = -1;
    } on Exception catch (e) {
      if (mounted) _messageStarred.value = -1;
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  Future<void> _deleteSelectedMessageThreads() async {
    bool success = false;

    try {
      final shouldDelete = await showConfirmDialog(
        context: context,
        content: 'Delete selected message threads?',
      );
      if (shouldDelete) {
        if (mounted) {
          LoadingIndicator().show(
            context: context,
          );
        }
        for (int i = _selectedMessageThreads.length - 1; i >= 0; i--) {
          final messageDeleteThreadRequest = MessageDeleteThreadRequest(
              id: _selectedMessageThreads[i].id, userId: _currentUser.id);
          final result = await _connectionService
              .deleteMessageThread(messageDeleteThreadRequest);
          success = result.deleted;
          if (success) {
            _selectedMessageThreads[i].selected = false;
            _messageThreads.remove(_selectedMessageThreads[i]);
            _selectedMessageThreads.removeAt(i);
          } else {
            break;
          }
        }
        // Update unread messages badge count.
        _messagingHandlerService.refreshUnreadMessageCount();
        if (mounted) {
          LoadingIndicator().hide();
        }
        if (success) {
          if (mounted) {
            setState(() {
              _selectionMode = false;
            });
          }
        } else {
          _clearSelection();
          if (mounted) {
            await showErrorDialog(context);
          }
        }
      }
    } on Exception catch (e) {
      _clearSelection();
      if (mounted) {
        LoadingIndicator().hide();
      }
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  Future<void> _markSelectedMessageThreadsAsReadUnread(
      bool read, bool unread) async {
    bool success = false;

    try {
      if (mounted) {
        LoadingIndicator().show(
          context: context,
        );
      }
      for (int i = _selectedMessageThreads.length - 1; i >= 0; i--) {
        final messageMarkReadUnreadRequest = MessageMarkReadUnreadRequest(
          threadId: _selectedMessageThreads[i].id,
          userId: _currentUser.id,
          read: read,
          unread: unread,
        );
        final result = await _connectionService
            .markMessageThreadReadOrUnread(messageMarkReadUnreadRequest);

        read
            ? success = result.first.unreadCount == 0
            : success = result.first.unreadCount == 1;

        if (success) {
          read
              ? _selectedMessageThreads[i].unreadCount = 0
              : _selectedMessageThreads[i].unreadCount = 1;
          _selectedMessageThreads[i].selected = false;
          _selectedMessageThreads.removeAt(i);
        } else {
          break;
        }
      }
      // Update unread messages badge count.
      _messagingHandlerService.refreshUnreadMessageCount();
      if (mounted) {
        LoadingIndicator().hide();
      }
      if (success) {
        if (mounted) {
          setState(() {
            _selectionMode = false;
          });
        }
      } else {
        _clearSelection();
        if (mounted) {
          await showErrorDialog(context);
        }
      }
    } on Exception catch (e) {
      _clearSelection();
      if (mounted) {
        LoadingIndicator().hide();
      }
      if (mounted) {
        await processException(context: context, exception: e);
      }
    }
  }

  void _onMessageBoxMenuItemTapped(MessageBoxMenuAction messageBoxMenuAction) {
    if (mounted) {
      setState(() {
        _currentMessageBox = messageBoxMenuAction;
        _onRefresh();
      });
    }
  }
}
