import 'package:flutter/material.dart';
import 'package:arvo/services/caching/member_directory_provider.dart';
import 'package:nifty_three_bp_app_base/api/api_exceptions.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:nifty_three_bp_app_base/api/messages_get_request.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/messaging/messaging_handler_provider.dart';
import 'package:arvo/services/push_notifications/push_notification_provider.dart';
import 'package:uuid/uuid.dart';

class ArvoMessagingHandlerProvider implements MessagingHandlerProvider {
  // create as singleton
  static final _shared = ArvoMessagingHandlerProvider._sharedInstance();
  ArvoMessagingHandlerProvider._sharedInstance();
  factory ArvoMessagingHandlerProvider() => _shared;

  late ConnectionProvider _connectionProvider;
  late LocalStorageProvider _localStorageProvider;
  late MemberDirectoryProvider _memberDirectoryProvider;
  late PushNotificationProvider _pushNotificationProvider;
  // Needs to be assigned outside initialise() because a user has to be logged in.
  late Member? _currentUser;
  late Uuid _uuid;

  final int _maximumNewMessagesPerInterval = 5;

  int _unreadMessageCount = 0;
  int _messageCountLimitPerThread = 500;
  int _maxPendingMessageReplies = 10;
  // NOTE: This notifier is not disposed of and will persist for the lifetime of the app.
  ValueNotifier<int> _unreadMessageCountUpdatedNotifier = ValueNotifier(0);

  Member _getCurrentUserOrThrow() {
    if (_currentUser != null) {
      return _currentUser!;
    } else {
      throw GenericUserAccessException(message: 'Invalid user.');
    }
  }

  @override
  int get unreadMessageCount => _unreadMessageCount;

  @override
  set unreadMessageCount(value) {
    _unreadMessageCount = value;
  }

  @override
  ValueNotifier<int> get unreadMessageCountUpdatedNotifier =>
      _unreadMessageCountUpdatedNotifier;

  @override
  set unreadMessageCountUpdatedNotifier(value) {
    _unreadMessageCountUpdatedNotifier = value;
  }

  @override
  Future<void> initalise(
    ConnectionProvider connectionProvider,
    LocalStorageProvider localStorageProvider,
    MemberDirectoryProvider memberDirectoryProvider,
    PushNotificationProvider pushNotificationProvider,
  ) async {
    _connectionProvider = connectionProvider;
    _localStorageProvider = localStorageProvider;
    _memberDirectoryProvider = memberDirectoryProvider;
    _pushNotificationProvider = pushNotificationProvider;
    _uuid = const Uuid();
    _pushNotificationProvider.registerFunctionForUpdate(
        _uuid.v1(), refreshUnreadMessageCount);
  }

  @override
  Future<void> loadSystemParameters() async {
    _currentUser = _connectionProvider.currentUser;
    final databaseSystemSettings =
        await _localStorageProvider.getSystemSetting();
    messageCountLimitPerThread =
        databaseSystemSettings.messageCountLimitPerThread;
    maxPendingMessageReplies = databaseSystemSettings.maxPendingMessageReplies;
    _getCurrentUserOrThrow();
  }

  @override
  Future<bool> checkRecipientIsReachable(Member member) async {
    if (member.id == 0) return false;

    final isBlockedByRecipient = await _connectionProvider
        .getMemberBlockedStatus(member.id, _currentUser!.id);

    if (isBlockedByRecipient) return false;

    member.isSuspended =
        await _connectionProvider.getMemberSuspendedStatus(member.id);

    // IsSuspended cannot be null since it's explicitly assigned by getMemberSuspendedStatus.
    if (member.isSuspended!) return false;

    return true;
  }

  @override
  Future<bool> checkUserCanSendNewMessage() async {
    var databaseUserSetting =
        await _localStorageProvider.getUserSetting(_currentUser!.id);
    var lastNewMessageSentTimestamp = DateTime.fromMillisecondsSinceEpoch(
        databaseUserSetting.lastNewMessageSentTimestamp);
    var timeDiff =
        DateTime.now().difference(lastNewMessageSentTimestamp).inMinutes;
    if (timeDiff > 5) {
      databaseUserSetting.newMessagesSentCount = 0;
      await _localStorageProvider.updateUserSetting(databaseUserSetting);
      return true;
    }
    return !(databaseUserSetting.newMessagesSentCount ==
            _maximumNewMessagesPerInterval &&
        timeDiff < 5);
  }

  @override
  Future<Member> findOrFetchRecipient(int memberId) async {
    final member = _memberDirectoryProvider.members
            .where((member) => member.id == memberId)
            .firstOrNull ??
        _memberDirectoryProvider.favouriteMembers
            .where((member) => member.id == memberId)
            .firstOrNull ??
        _memberDirectoryProvider.members
            .where((member) => member.id == memberId)
            .firstOrNull ??
        (await _connectionProvider.getMember(memberId));

    member.isBlocked ??= await _connectionProvider.getMemberBlockedStatus(
        _currentUser!.id, member.id);

    return member;
  }

  @override
  Future<void> updateNewMessageSentTimestamp() async {
    var databaseUserSetting =
        await _localStorageProvider.getUserSetting(_currentUser!.id);
    databaseUserSetting.newMessagesSentCount =
        databaseUserSetting.newMessagesSentCount + 1;
    if (databaseUserSetting.newMessagesSentCount == 1) {
      databaseUserSetting.lastNewMessageSentTimestamp =
          DateTime.now().millisecondsSinceEpoch;
    }
    await _localStorageProvider.updateUserSetting(databaseUserSetting);
  }

  @override
  Future<int> refreshUnreadMessageCount() async {
    if (_currentUser == null) return 0;

    try {
      int perPage = 100;

      int unreadMessageCount = 0;
      int currentMessageBoxPage = 1;
      bool messagesLoaded = false;

      while (!messagesLoaded) {
        var messagesGetRequest = MessagesGetRequest(
          userId: _currentUser!.id,
          page: currentMessageBoxPage,
          perPage: perPage,
          box: 'inbox',
          messagesPage: 1,
          messagesPerPage: 1,
          type: 'unread',
        );

        var messageThreads =
            await _connectionProvider.getMessages(messagesGetRequest);

        for (final messageThread in messageThreads) {
          unreadMessageCount += messageThread.unreadCount;
        }

        _unreadMessageCount = unreadMessageCount;

        if (messageThreads.length < perPage) {
          messagesLoaded = true;
        }
      }
      unreadMessageCountUpdatedNotifier.value = _unreadMessageCount;
      return _unreadMessageCount;
    } on Exception catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> toggleBlocked(Member member) async {
    try {
      var isBlocked = member.isBlocked!;
      isBlocked
          ? await _connectionProvider.unblockMember(member.id)
          : await _connectionProvider.blockMember(member.id);
      member.isBlocked = !isBlocked;
      _memberDirectoryProvider.updateMemberStatus(member);
    } on Exception catch (_) {
      rethrow;
    }
  }

  @override
  Future<int> getLastMessageThreadId(int memberId) async {
    try {
      return await _connectionProvider.getLastMessageThreadId(memberId);
    } on Exception catch (_) {
      rethrow;
    }
  }

  @override
  int get messageCountLimitPerThread => _messageCountLimitPerThread;

  @override
  set messageCountLimitPerThread(value) {
    _messageCountLimitPerThread = value;
  }

  @override
  int get maxPendingMessageReplies => _maxPendingMessageReplies;

  @override
  set maxPendingMessageReplies(value) {
    _maxPendingMessageReplies = value;
  }
}
