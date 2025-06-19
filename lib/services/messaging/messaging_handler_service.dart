import 'package:flutter/material.dart';
import 'package:arvo/services/caching/member_directory_provider.dart';
import 'package:arvo/services/connection/connection_provider.dart';
import 'package:nifty_three_bp_app_base/api/member.dart';
import 'package:arvo/services/crud/local_storage_provider.dart';
import 'package:arvo/services/messaging/arvo_messaging_handler_provider.dart';
import 'package:arvo/services/messaging/messaging_handler_provider.dart';
import 'package:arvo/services/push_notifications/push_notification_provider.dart';

class MessagingHandlerService implements MessagingHandlerProvider {
  final MessagingHandlerProvider provider;
  const MessagingHandlerService(this.provider);

  factory MessagingHandlerService.arvo() =>
      MessagingHandlerService(ArvoMessagingHandlerProvider());

  @override
  int get unreadMessageCount => provider.unreadMessageCount;

  @override
  set unreadMessageCount(int value) => provider.unreadMessageCount = value;

  @override
  ValueNotifier<int> get unreadMessageCountUpdatedNotifier =>
      provider.unreadMessageCountUpdatedNotifier;

  @override
  set unreadMessageCountUpdatedNotifier(ValueNotifier<int> value) =>
      provider.unreadMessageCountUpdatedNotifier = value;

  @override
  Future<void> initalise(
          ConnectionProvider connectionProvider,
          LocalStorageProvider localStorageProvider,
          MemberDirectoryProvider memberDirectoryProvider,
          PushNotificationProvider pushNotificationProvider) =>
      provider.initalise(connectionProvider, localStorageProvider,
          memberDirectoryProvider, pushNotificationProvider);

  @override
  Future<void> loadSystemParameters() => provider.loadSystemParameters();

  @override
  Future<bool> checkRecipientIsReachable(Member member) =>
      provider.checkRecipientIsReachable(member);

  @override
  Future<bool> checkUserCanSendNewMessage() =>
      provider.checkUserCanSendNewMessage();

  @override
  Future<Member> findOrFetchRecipient(int memberId) =>
      provider.findOrFetchRecipient(memberId);

  @override
  Future<void> updateNewMessageSentTimestamp() =>
      provider.updateNewMessageSentTimestamp();

  @override
  Future<int> refreshUnreadMessageCount() =>
      provider.refreshUnreadMessageCount();

  @override
  Future<void> toggleBlocked(Member member) => provider.toggleBlocked(member);

  @override
  Future<int> getLastMessageThreadId(int memberId) =>
      provider.getLastMessageThreadId(memberId);

  @override
  int get messageCountLimitPerThread => provider.messageCountLimitPerThread;

  @override
  set messageCountLimitPerThread(int value) =>
      provider.messageCountLimitPerThread = value;

  @override
  int get maxPendingMessageReplies => provider.maxPendingMessageReplies;

  @override
  set maxPendingMessageReplies(int value) =>
      provider.maxPendingMessageReplies = value;
}
